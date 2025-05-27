#!/bin/sh

# === 1) Bootstrap Expect ===

# Choose installer
if command -v apt-get >/dev/null 2>&1; then
  PM="apt-get"
  PM_UPDATE_OPTS="update -y"
  PM_INSTALL_OPTS="install -y expect"
elif command -v yum >/dev/null 2>&1; then
  PM="yum"
  PM_UPDATE_OPTS="makecache"
  PM_INSTALL_OPTS="install -y expect"
  YUM_QUIET="-q"
else
  echo "Error: neither apt-get nor yum found; cannot install expect." >&2
  exit 1
fi

# Use sudo if not root
[ "$(id -u)" -eq 0 ] && SUDO="" || SUDO="sudo"

# Install expect if missing
if ! command -v expect >/dev/null 2>&1; then
  echo "Expect not found; installing via $PM..."
  if [ "$PM" = "apt-get" ]; then
    $SUDO $PM $PM_UPDATE_OPTS     > /dev/null 2>&1 || true
    $SUDO $PM $PM_INSTALL_OPTS    > /dev/null 2>&1
  else
    $SUDO $PM $PM_UPDATE_OPTS $YUM_QUIET  > /dev/null 2>&1 || true
    $SUDO $PM $PM_INSTALL_OPTS $YUM_QUIET > /dev/null 2>&1
  fi

  if ! command -v expect >/dev/null 2>&1; then
    echo "Error: failed to install expect." >&2
    exit 1
  fi
fi

# === 2) Export variables for Expect to inherit ===

export ROUTERS="10.0.0.103 10.0.0.104"
export USER="cisco"
export PASS="cisco"
export ENABLE_PASS="cisco"
export OSPF_PROC=1
export OSPF_AREA=0
export NETWORK="10.0.0.0"
export WILDCARD="0.0.0.255"
export ACL_NAME="server_access"

# === 3) Inline Expect for configuration ===

expect <<'EOF'
  # turn off all Expect’s default logging
  log_user 0
  set timeout 20

  # import env vars
  set routers [split $env(ROUTERS) " "]
  set user    $env(USER)
  set pass    $env(PASS)
  set enpass  $env(ENABLE_PASS)
  set ospf    $env(OSPF_PROC)
  set area    $env(OSPF_AREA)
  set net     $env(NETWORK)
  set wild    $env(WILDCARD)
  set acl     $env(ACL_NAME)

  foreach r $routers {
    puts "\n>>> Configuring router $r <<<"

    puts "  • Connecting to $r..."
    spawn ssh -o StrictHostKeyChecking=no $user@$r
    expect {
      -re "(P|p)assword:" { send "$pass\r"; exp_continue }
      "#"               { }
    }

    puts "  • Entering enable mode..."
    send "enable\r"
    expect {
      -re "(P|p)assword:" { send "$enpass\r" }
      "#"               { }
    }

    puts "  • Entering configuration terminal..."
    send "configure terminal\r"
    expect "#"

    puts "  • Setting up Gi1..."
    send "interface GigabitEthernet1\r"; expect "#"
    send "description LAN link on $r\r"; expect "#"
    send "no shutdown\r";                expect "#"
    send "ip address $r 255.255.255.0\r";expect "#"
    send "exit\r";                       expect "#"

    puts "  • Setting up Gi2 ACL..."
    send "interface GigabitEthernet2\r"; expect "#"
    send "description Dummy-ACL interface\r"; expect "#"
    send "no shutdown\r";                expect "#"
    send "ip access-group $acl in\r";    expect "#"
    send "exit\r";                       expect "#"

    puts "  • Configuring OSPF..."
    send "router ospf $ospf\r";          expect "#"
    send "router-id $r\r";               expect "#"
    send "network $net $wild area $area\r"; expect "#"
    send "exit\r";                       expect "#"

    puts "  • Building ACL $acl..."
    send "ip access-list extended $acl\r"; expect "#"
    send "remark permits everything\r"; expect "#"
    send "permit ip any any\r";         expect "#"
    send "exit\r";                       expect "#"

    puts "  • Saving configuration and logging out..."
    send "end\r";    expect "#"
    send "write memory\r"; expect "#"
    send "exit\r";   expect eof

    puts "? Router $r done."
  }
EOF

echo "\nAll routers configured."
