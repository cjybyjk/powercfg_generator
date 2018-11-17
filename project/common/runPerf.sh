# powercfg script support

MODE=`cat /data/perf_mode`
[ "disabled" == "$MODE" ] && exit 0

powercfg $MODE > /dev/perf_state

