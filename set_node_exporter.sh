
#!/bin/bash

set -e


NODE_EXPORTER_VERSION="1.9.1"
SERVICE_USER="grdadmin"
SERVICE_GROUP="grdadmin"
PROMETHEUS_SERVER_IP="172.16.0.52"

# --- スクリプト本体 ---

echo "--- 1. 必要なパッケージ (wget) のインストール ---"
# wgetがインストールされていない場合にのみインストールを実行
if ! command -v wget &> /dev/null; then
    sudo dnf install -y wget
else
    echo "wgetは既にインストールされています。"
fi

echo "--- 2. node_exporterのダウンロードと展開 ---"
cd /tmp
wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar xvfz "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "--- 3. node_exporterのインストールと権限設定 ---"
sudo cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
sudo chown "${SERVICE_USER}:${SERVICE_GROUP}" /usr/local/bin/node_exporter

echo "--- 4. systemdサービスファイルの作成 ---"
# ヒアドキュメントを使い、指定した内容でサービスファイルを作成する
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "--- 5. systemdサービスの有効化と起動 ---"
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
echo "node_exporterサービスを起動しました。現在の状態:"
# サービスのステータスを表示（エラーがないか確認）
sudo systemctl status node_exporter --no-pager

echo "--- 6. Firewallの設定 ---"
# --new-zoneが既に存在するとエラーになるため、存在しない場合のみ作成する
if ! sudo firewall-cmd --get-zones | grep -q monitoring; then
    sudo firewall-cmd --new-zone=monitoring --permanent
fi
sudo firewall-cmd --zone=monitoring --add-source="${PROMETHEUS_SERVER_IP}" --permanent
sudo firewall-cmd --zone=monitoring --add-port=9100/tcp --permanent
sudo firewall-cmd --reload

echo "--- 7. 一時ファイルのクリーンアップ ---"
rm -f "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
rm -rf "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"

echo ""
echo "--- セットアップが完了しました！ ---"
echo "Firewallの設定一覧:"
sudo firewall-cmd --zone=monitoring --list-all