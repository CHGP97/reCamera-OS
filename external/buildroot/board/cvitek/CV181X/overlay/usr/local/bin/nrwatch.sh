#!/bin/sh
# node-red health monitor v3: /userdata/log/nrwatch.log
# 5s probe; logs state-class transitions (with rich snapshot) + 10min heartbeat
LOG=/userdata/log/nrwatch.log
mkdir -p /userdata/log 2>/dev/null
last="INIT"; n=0
while :; do
  pid=$(pidof node-red)
  if [ -n "$pid" ]; then st="ALIVE"; else st="DEAD"; fi
  t=$(curl -s -o /dev/null -w '%{http_code}=%{time_total}s' --connect-timeout 2 --max-time 4 -I localhost:1880 2>/dev/null)
  [ -z "$t" ] && t="TIMEOUT"
  cls=${t%%=*}
  cur="$st $cls"
  if [ "$cur" != "$last" ] || [ $((n % 120)) -eq 0 ]; then
    rss=$(awk '/VmRSS/{print $2}' /proc/$pid/status 2>/dev/null)
    fds=$(ls /proc/$pid/fd 2>/dev/null | wc -l)
    sw=$(awk '/SwapFree/{print $2}' /proc/meminfo)
    ext=$(netstat -tn 2>/dev/null | grep ':1880 ' | grep ESTABLISHED | grep -vc '127.0.0.1')
    echo "$(date '+%m-%d %H:%M:%S') [$cur $t] pid=$pid rss=${rss:-0}kB fd=$fds extClient=$ext load=$(cat /proc/loadavg | cut -d' ' -f1-3 | tr '\n' ' ')memAvail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)kB swapUsed=$((262140-sw))kB" >> "$LOG"
    s=$(wc -c < "$LOG" 2>/dev/null || echo 0)
    [ "$s" -gt 1500000 ] && { tail -c 700000 "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"; }
  fi
  if [ "$cur" != "$last" ]; then
    {
      echo "===== TRANSITION '$last' -> '$cur' $t $(date) ====="
      echo '-- meminfo:'; grep -E 'MemFree|MemAvailable|SwapFree' /proc/meminfo
      echo '-- ext clients on 1880:'; netstat -tn 2>/dev/null | grep ':1880 ' | grep ESTABLISHED | grep -v '127.0.0.1'
      echo '-- dmesg tail:'; dmesg | tail -12
      echo '-- top procs by rss:'; ps -eo pid,stat,rss,args 2>/dev/null | grep -vE 'grep|ps -eo|nrwatch' | sort -rn -k3 | head -12
      echo '-- D-state:'; ps -eo pid,stat,args 2>/dev/null | awk '$2 ~ /^D/'
      echo '-- node-red children:'; ps -eo pid,ppid,args 2>/dev/null | awk -v p=$pid '$2==p'
      echo '-- core files:'; ls -la /userdata/cores/ 2>/dev/null
    } >> "$LOG" 2>&1
  fi
  last="$cur"; n=$((n+1))
  sleep 5
done
