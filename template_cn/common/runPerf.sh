# powercfg script support

MODE=`cat /data/perf_mode`
[ "disabled" == "$MODE" ] && exit 0
rm /dev/perf_runonce

powercfg $MODE > /dev/perf_state 2>&1
nohup autoperf start &
