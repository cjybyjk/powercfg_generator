soc_name=sd_425
soc_model=msm8917
cluster_num=1
cluster_0=cpu0

SCHED_DIR="/proc/sys/kernel"

# Qualcomm hotplug
GLOBAL_PARAMS_ADD="/sys/module/msm_thermal/core_control/enabled=0
/sys/module/msm_thermal/parameters/enabled=N"
