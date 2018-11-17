# (project_name) flashable
A script for flash (project_name) into your device

### Version (prj_ver)

### Thanks to
[@yc9559](https://github.com/yc9559)

### How to use
#### 刷入 (Flash)
-   下载zip到你的设备中 
    (Download zip to your device.)
-   重启到Recovery模式下并刷入zip
    (Reboot to recovery mode and flash it.)
	- 如果不想安装为magisk模块,可以执行这个命令后重新刷入 
	```bash
		touch /perf_no_magisk
	```
	- 如果以传统模式安装后没有成功应用,可以执行这个命令后重新刷入
	```bash
		touch /perf_no_apply_once
	```
#### 更改模式 (Change Mode)
##### 自动应用 重启后生效 (Apply on boot)
-   在终端以root身份执行命令
	(Run command as root in terminal):
	```bash
	echo "powersave" > /data/perf_mode #省电
	echo "balance" > /data/perf_mode #平衡(默认)
	echo "performance" > /data/perf_mode #性能
	echo "fast" > /data/perf_mode #低延迟
	echo "disabled" > /data/perf_mode #停用
	```

##### 临时应用 立即生效 (Temporary Apply (NOW))
-   在终端以root身份执行命令
    (Run command as root in terminal): 
    ```bash
	powercfg powersave #省电
	powercfg balance #平衡
	powercfg performance #性能
	powercfg fast #低延迟
    ```

