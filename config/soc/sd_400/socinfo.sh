soc_name=sd_400
soc_model=apq(8026|8028|8030)|msm(8226|8228|8230|8626|8628|8630|8926|8928|8930)
cluster_num=1
cluster_0=cpu0

SCHED_DIR="/proc/sys/kernel"

# Qualcomm hotplug
GLOBAL_PARAMS_ADD="/sys/module/msm_thermal/core_control/enabled=0
/sys/module/msm_thermal/parameters/enabled=N"
