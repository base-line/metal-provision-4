#!/usr/bin/env bash

# configuring ElasticIP
ELASTIC_IP=$(echo ${ip} | sed 's/\(.*\).../\1/')

cat <<EOF>> /etc/network/interfaces
auto lo:0
iface lo:0 inet static
    address $ELASTIC_IP
    netmask ${netmask}
EOF

ifup lo:0


apt -y update && apt -y install nginx python3-pip git bird

pushd /opt
git clone https://github.com/packethost/network-helpers.git
cd network-helpers
pip3 install jmespath
pip3 install -e .
./configure.py -r bird | tee /etc/bird/bird.conf
popd

systemctl restart bird

echo "Hello, this is server $RANDOM" > /var/www/html/index.nginx-debian.html