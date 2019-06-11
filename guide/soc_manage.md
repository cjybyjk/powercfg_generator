## powercfg_generator 使用方法

### SoC 管理

#### 新增 SoC
1. 在 `config/soc/` 文件夹中新建以 `SoC名称` 命名的文件夹
2. 在文件夹中新建 `socinfo.sh`
3. 根据实际情况修改并写入以下内容
    ````
    soc_name=SoC名称
    soc_model=SoC型号，这是安装器识别 SoC 所必需的
    cluster_num=含有的 cpu 集群的个数
    # 请根据 cluster_num 修改下面的 cluster_x
    cluster_0=集群 0 的控制器名称(一般为 cpu0)
    cluster_1=集群 1 的控制器名称

    SCHED_DIR="HMP目录"

    # 这里可以设置热插拔等参数，下面是高通 SoC 热插拔的示例
    GLOBAL_PARAMS_ADD="/sys/module/msm_thermal/core_control/enabled=0
    /sys/module/msm_thermal/parameters/enabled=N"

    ````
4. 保存文件

#### 修改 SoC 信息
- 修改 `config/soc/SoC名称/socinfo.sh`

#### 删除 SoC
- 删除文件夹 `config/soc/SoC名称`
- 注意：删除 SoC 后，之前生成的 `powercfg` 将不再被安装器识别
