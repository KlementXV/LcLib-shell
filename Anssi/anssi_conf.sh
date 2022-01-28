#!/bin/bash

# anssi_conf.sh
# This is a configuration of sysctl provided by 
# the French National Agency for the Security of Information Systems (ANSSI).
# V1.2 comes from https://www.ssi.gouv.fr/uploads/2016/01/linux_configuration-fr-v1.2.pdf.

update_sysctl() {
    # No routage between interfaces
    sudo sysctl -w net.ipv4.ip_forward=0

    # Reverse path filtering
    sudo sysctl -w net.ipv4.conf.all.rp_filter=1
    sudo sysctl -w net.ipv4.conf.default.rp_filter=1

    # Do not send ICMP redirects
    sudo sysctl -w net.ipv4.conf.all.send_redirects=0
    sudo sysctl -w net.ipv4.conf.default.send_redirects=0

    # Deny source routing packets
    sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
    sudo sysctl -w net.ipv4.conf.default.accept_source_route=0

    # Don't accept redirect type ICMPs
    sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
    sudo sysctl -w net.ipv4.conf.all.secure_redirects=0
    sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
    sudo sysctl -w net.ipv4.conf.default.secure_redirects=0

    # Log packets with abnormal IPs
    sudo sysctl -w net.ipv4.conf.all.log_martians=1

    # RFC 1337
    sudo sysctl -w net.ipv4.tcp_rfc1337=1

    # Ignore responses that don't comply with RFC 1122
    sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1

    # Increase range for ephemeral ports
    sudo sysctl -w net.ipv4.ip_local_port_range="32768 65535"

    # Use SYN cookies
    sudo sysctl -w net.ipv4.tcp_syncookies=1

    # Disable support for "router solicitations"
    sudo sysctl -w net.ipv6.conf.all.router_solicitations=0
    sudo sysctl -w net.ipv6.conf.default.router_solicitations=0

    # Do not accept "router preferences" by "router advertisements"
    sudo sysctl -w net.ipv6.conf.all.accept_ra_rtr_pref=0
    sudo sysctl -w net.ipv6.conf.default.accept_ra_rtr_pref=0

    # No auto configuration of prefixes by "router advertisements"
    sudo sysctl -w net.ipv6.conf.all.accept_ra_pinfo=0
    sudo sysctl -w net.ipv6.conf.default.accept_ra_pinfo=0

    # No default router learning by "router advertisements"
    sudo sysctl -w net.ipv6.conf.all.accept_ra_defrtr=0
    sudo sysctl -w net.ipv6.conf.default.accept_ra_defrtr=0

    # No auto configuration of addresses from "router advertisements"
    sudo sysctl -w net.ipv6.conf.all.autoconf=0
    sudo sysctl -w net.ipv6.conf.default.autoconf=0

    # Don't accept redirect type ICMPs
    sudo sysctl -w net.ipv6.conf.all.accept_redirects=0
    sudo sysctl -w net.ipv6.conf.default.accept_redirects=0

    # Deny source routing packets
    sudo sysctl -w net.ipv6.conf.all.accept_source_route=0
    sudo sysctl -w net.ipv6.conf.default.accept_source_route=0

    # Maximum number of autoconfigured addresses per interface
    sudo sysctl -w net.ipv6.conf.all.max_addresses=1
    sudo sysctl -w net.ipv6.conf.default.max_addresses=1

    # Disabling SysReqs
    sudo sysctl -w kernel.sysrq=0

    # No core dump of setuid executables
    sudo sysctl -w fs.suid_dumpable=0

    # Prohibition of dereferencing links to
    # files not owned by the current user May
    # prevent some programs from working properly
    sudo sysctl -w fs.protected_symlinks=1
    sudo sysctl -w fs.protected_hardlinks=1

    # Enabling ASLR
    sudo sysctl -w kernel.randomize_va_space=2

    # Disallow memory mapping in low (0) addresses
    sudo sysctl -w vm.mmap_min_addr=65536

    # Larger choice space for PID values
    sudo sysctl -w kernel.pid_max=65536

    # Obfuscation of kernel memory addresses
    sudo sysctl -w kernel.kptr_restrict=1

    # Dmesg buffer access restriction
    sudo sysctl -w kernel.dmesg_restrict=1

    # Restricts the use of the perf subsystem
    sudo sysctl -w kernel.perf_event_paranoid=2
    sudo sysctl -w kernel.perf_event_max_sample_rate=1
    sudo sysctl -w kernel.perf_cpu_time_max_percent=1

    # command not saved after reboot
    sudo sysctl -w kernel.modules_disabled=1

    # Prohibition of loading modules
    # (except those already loaded at this point)
    # by modifying the file /etc/sysctl.conf
    sudo sysctl -w kernel.modules_disabled=1
}

test_files() {
    #Test wich file has no user and group
    filesWithoutUserGroup=$(find / -type f \( -nouser -o -nogroup \) -ls 2>/dev/null)
    if [ -n "$filesWithoutUserGroup" ]; then
        echo -e "\033[1;33mWARNING ! These files have no users or group :\033[0m"
        echo -e "\033[1;33m${filesWithoutUserGroup}\033[0m"
    fi
}

update_sysctl
test_files
