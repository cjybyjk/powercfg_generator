soc_name=sd_801
soc_model=apq8074|msm(8274|8674|8974)
cluster_num=1
cluster_0=cpu0

SCHED_DIR="/proc/sys/kernel"

# Qualcomm hotplug
GLOBAL_PARAMS_ADD="/sys/module/msm_thermal/core_control/enabled=0\n/sys/module/msm_thermal/parameters/enabled=N"
