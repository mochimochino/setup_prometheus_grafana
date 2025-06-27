# setup_prometheus_grafana
## スクリプトの保存と実行方法
### ファイルの保存:
このレポジトリをクローンする。
```bash
git clone <https:ーーーーーー>
```
## setup_monitoringの使い方
ホストサーバーで行う。
### 実行権限の付与：
```bash
chmod +x setup_monitoring.sh
```
### スクリプトの実行：
```bash 
./setup_monitoring.sh
```
PrometheusとGrafanaのダッシュボードが開けることを確認する。


## setup_node_exporterの使い方
### 実行権限の付与:
保存したファイルに実行権限を与える。

```bash
chmod +x setup_node_exporter.sh
```
### スクリプトの実行:
```bash
sudo ./setup_node_exporter.sh
```
### ホストサーバーの設定：
ホストサーバーに移動する。
```bash
sudo vi /etc/prometheus/prometheus.yml
```
の中に書いてある` - targets:`に今回加えたノードのIPを加える。
### 設定の反映:
ホストサーバーで設定を反映させる。
```bash
sudo systemctl restart prometheus
```


