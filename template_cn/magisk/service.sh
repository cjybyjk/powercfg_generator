#!/system/bin/sh
MODDIR=${0%/*}

# wait for boot completed
until [ "`getprop sys.boot_completed`" = "1" ]
do
sleep 10
done

# mode detect
MODE=`cat /data/perf_mode`
[ "disabled" == "$MODE" ] && exit 0

powercfg $MODE > /dev/perf_state 2>&1
nohup autoperf start &
