#!/bin/sh

cat <<EOF > /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other value on error.
#
# In order to enable or disable this script just change the execution bits.
#
# By default this script does nothing.

iptables -t nat -F
iptables -t nat -A POSTROUTING -o eth0 -s ${vpc_coa_cidr} -j SNAT --to ${natgw_private_ip}

exit 0
EOF

iptables -t nat -F
iptables -t nat -A POSTROUTING -o eth0 -s ${vpc_coa_cidr} -j SNAT --to ${natgw_private_ip}
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

sysctl -p
