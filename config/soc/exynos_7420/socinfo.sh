soc_name=exynos_7420
soc_model=universal7420
cluster_num=2
cluster_0=cpu0
cluster_1=cpu4

SCHED_DIR="/proc/sys/kernel/hmp"

# Exynos hotplug
GLOBAL_PARAMS_ADD="/sys/power/cpuhotplug/enabled=0
/sys/devices/system/cpu/cpuhotplug/enabled=0"
