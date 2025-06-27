#!/bin/bash
set -e

# set vars
PROMETHEUS_VERSION="2.53.4"
APP_USER="grdadmin"
APP_GROUP="grdadmin"

if [[ $EUID -eq 0 ]]; then
  echo "root ユーザーではなく、管理者権限を持つ一般ユーザーで実行してください"
  echo "./setup_monitoring.sh"
  exit 1
fi

echo "--- PrometheusとGrafanaの自動セットアップを開始する ---"

# --- set up for Prometheus ---
echo "--- [1/5] Prometheus用のディレクトリの作成と権限設定 ---"
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus
sudo chown -R ${APP_USER}:${APP_GROUP} /etc/prometheus
sudo chown -R ${APP_USER}:${APP_GROUP} /var/lib/prometheus
echo "ディレクトリの準備完了"

echo "--- [2/5] Prometheusのインストール ---"
if ! command -v wget &> /dev/null; then
  echo "wgetがインストールされていません。インストールします..."

  sudo dnf -y install wget
fi

cd /tmp
echo "Prometheus v${PROMETHEUS_VERSION}をダウンロード中..."
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

echo "ダウンロード完了。アーカイブを解凍中..."
tar -xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64

echo "バイナリファイルをコピー"
sudo cp ./prometheus /usr/local/bin/
sudo cp ./promtool /usr/local/bin/
sudo cp -r ./consoles /etc/prometheus
sudo cp -r ./console_libraries /etc/prometheus

echo "コピーしたファイルの権限を設定しています..."
sudo chown ${APP_USER}:${APP_GROUP} /usr/local/bin/prometheus
sudo chown ${APP_USER}:${APP_GROUP} /usr/local/bin/promtool

echo "--- [3/5] Prometheusの設定ファイルとサービスファイルを作成 ---"
# prometheus.yml設定ファイルを作成
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
EOF

sudo chown ${APP_USER}:${APP_GROUP} /etc/prometheus/prometheus.yml

# systemdサービスファイルを作成
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=${APP_USER}
Group=${APP_GROUP}
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

echo "Prometheusサービスをリロードして有効化・起動します"
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
echo "Prometheusのセットアップが完了しました。"

# --- 4. Grafanaのセットアップ ---

echo "--- [4/5] Grafanaのインストール ---"
# Grafanaリポジトリファイルを作成
sudo tee /etc/yum.repos.d/grafana.repo > /dev/null <<EOF
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF

echo "Grafanaをインストールしています..."
sudo dnf install -y grafana

echo "Grafanaサービスをリロードして有効化・起動します..."
sudo systemctl daemon-reload
sudo systemctl enable grafana-server.service
sudo systemctl start grafana-server.service
echo "Grafanaのセットアップが完了しました。"


# --- 5. ファイアウォールの設定 ---

echo "--- [5/5] ファイアウォールの設定 ---"
echo "Prometheusのポート (9090/tcp) を開放"
sudo firewall-cmd --add-port=9090/tcp --permanent

echo "Grafanaのポート (3000/tcp) を開放"
sudo firewall-cmd --add-port=3000/tcp --permanent

echo "ファイアウォールの設定をリロード"
sudo firewall-cmd --reload
echo "ファイアウォールの設定が完了"

# --- クリーンアップ ---
echo "--- 一時ファイルをクリーンアップ"
cd /tmp
rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz prometheus-${PROMETHEUS_VERSION}.linux-amd64
echo "クリーンアップが完了"

echo ""
echo "--- すべての処理が正常に完了しました！ ---"
echo "Prometheus UI: http://<サーバーのIPアドレス>:9090"
echo "Grafana UI:    http://<サーバーのIPアドレス>:3000"
echo "Grafanaの初期ログイン情報は admin / admin です。"