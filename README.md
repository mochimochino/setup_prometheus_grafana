# setup_prometheus_grafana
## スクリプトの保存と実行方法
### ファイルの保存:
このレポジトリをクローンする。

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
