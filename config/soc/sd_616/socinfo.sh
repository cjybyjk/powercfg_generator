soc_name=sd_616
soc_model=msm8939v2
cluster_num=2
cluster_0=cpu4
cluster_1=cpu0

SCHED_DIR="/proc/sys/kernel"

# Qualcomm hotplug
GLOBAL_PARAMS_ADD="/sys/module/msm_thermal/core_control/enabled=0\n/sys/module/msm_thermal/parameters/enabled=N"
