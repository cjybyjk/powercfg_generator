soc_name=sd_808
soc_model=msm8992
cluster_num=2
cluster_0=cpu0
cluster_1=cpu4

SCHED_DIR="/proc/sys/kernel"

# Qualcomm hotplug
GLOBAL_PARAMS_ADD="/sys/module/msm_thermal/core_control/enabled=0\n/sys/module/msm_thermal/parameters/enabled=N"
