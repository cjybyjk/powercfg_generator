#!/system/bin/sh
MODDIR=${0%/*}

# wait for boot animation stopped
until [ "`getprop init.svc.bootanim`" = "stopped" ]
do
sleep 10
done

# mode detect
MODE=`cat /data/perf_mode`
[ "disabled" == "$MODE" ] && exit 0

powercfg $MODE > /dev/perf_state

