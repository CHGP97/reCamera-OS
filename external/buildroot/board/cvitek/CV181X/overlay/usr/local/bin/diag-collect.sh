#!/bin/sh
# diag-collect: one-shot diagnostic bundle for bug reports
# packs node-red logs, health monitor logs, syslog, cores list (not cores themselves)
# and system state into /userdata/diag-<date>.tar.gz (cores >50MB are excluded;
# report them separately if requested)
OUT=/userdata/diag-$(date +%Y%m%d-%H%M%S).tar.gz
TMP=$(mktemp -d /tmp/diag.XXXXXX)
mkdir -p "$TMP/log"
for f in node-red.log nrwatch.log canary.log; do
    [ -f "/userdata/log/$f" ] && tail -c 2000000 "/userdata/log/$f" > "$TMP/log/$f"
done
[ -f /var/log/messages ] && tail -c 2000000 /var/log/messages > "$TMP/log/syslog"
ls -la /userdata/cores/ > "$TMP/log/cores.list" 2>/dev/null
{
    echo "=== date: $(date)"
    echo "=== uptime: $(uptime)"
    echo "=== node-red pid: $(pidof node-red)"
    /usr/bin/node --version 2>&1
    echo "=== md5: $(md5sum /usr/bin/node 2>/dev/null)"
    echo "=== meminfo:"; grep -E 'MemFree|MemAvailable|Swap' /proc/meminfo
    echo "=== loadavg: $(cat /proc/loadavg)"
    echo "=== node-red EXITED history:"
    grep -E 'EXITED|START' /userdata/log/node-red.log 2>/dev/null | tail -30
    echo "=== mounts:"; mount | head -20
} > "$TMP/system.txt" 2>&1
tar czf "$OUT" -C "$TMP" . && rm -rf "$TMP"
echo "diag bundle: $OUT ($(du -h "$OUT" | cut -f1))"
