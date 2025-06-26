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
sudo chown -R
