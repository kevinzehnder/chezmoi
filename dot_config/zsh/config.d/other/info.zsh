function info() {
    # 1. Distro & OS Detection (Cleaner approach)
    local os_id=$(grep -w "ID" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    local os_pretty=$(grep "PRETTY_NAME" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    
    # 2. Enhanced Reboot Check Logic
    needs_reboot() {
        # Check for Arch Linux orphaned kernel
        if [[ "$os_id" == "arch" ]]; then
            local running_kernel=$(uname -r)
            if [[ ! -d "/usr/lib/modules/$running_kernel" ]]; then
                return 0 # Reboot needed
            fi
        fi

        # Check for Debian/Ubuntu flag
        if [[ -f /var/run/reboot-required ]]; then
            return 0
        fi

        # Check for Fedora/CentOS/RHEL (needs-restarting is part of dnf-utils)
        if command -v needs-restarting >/dev/null 2>&1; then
            if ! needs-restarting -r >/dev/null 2>&1; then
                return 0
            fi
        fi

        return 1 # No reboot needed
    }

    # Rest of your existing variables...
    local kernel=$(uname -r)
    local uptime_val=$(uptime -p | sed 's/up //') # Prettier uptime
    local load=$(awk '{print $1, $2, $3}' /proc/loadavg)
    local active_services=$(systemctl list-units --type=service --state=active --quiet | grep -c "loaded active")
    local listening=$(ss -tulpn | grep -c LISTEN)
    
    # Efficient Cron Count (Avoiding sudo if possible, or keeping your loop)
    local cron_count=0
    for user in $(getent passwd | grep -vE '/nologin$|/false$' | cut -d ':' -f 1); do
        local user_cron=$(sudo crontab -l -u "$user" 2>/dev/null | grep -vE '^#|^$|^[A-Z]+=' | wc -l)
        ((cron_count += user_cron))
    done

    local timer_count=$(systemctl list-timers --all --no-legend | grep -c "active")
    local cpu_model=$(grep -m1 "model name" /proc/cpuinfo | sed 's/.*: //')
    local cpu_cores=$(nproc)
    local cpu_arch=$(uname -m)
    local hostname=$(hostname)

    # Output Rendering
    printf '\n⚡ \033[1m%s\033[0m ⚡\n\n' "$hostname"
    echo "🖥️  OS:       $os_pretty ($os_id)"
    echo "🐧 Kernel:   $kernel"
    echo "⏰ Uptime:   $uptime_val"
    echo "📊 Load:     $load"
    echo "🚀 Services: $active_services running"
    echo "🔌 Ports:    $listening listening"
    echo "⚡ Timers:   $timer_count active"
    echo "🕒 Crons:    $cron_count jobs"
    
    echo -e "\n💻 CPU:"
    echo "    Model:     $cpu_model"
    echo "    Cores:     $cpu_cores"
    echo "    Arch:      $cpu_arch"

    echo -e "\n📈 Memory:"
    free -h | grep "Mem:" | awk '{print $2, $3, $4}' | xargs printf "    Total: %s / Used: %s / Free: %s\n"

    echo -e "\n🌐 Network:"
    ip -br a | grep -v 'lo' | while read -r line; do
        local iface=$(echo $line | awk '{print $1}')
        local ip_addr=$(echo $line | awk '{print $3}')
        echo "    $iface: $ip_addr"
    done

    echo -e "\n🔄 Reboot Status:"
    if needs_reboot; then
        echo -e "    ⚠️  \033[31;1mReboot Required\033[0m (Kernel mismatch/Orphaned modules)"
    else
        echo "    ✅ System up to date"
    fi
    echo ""
}
