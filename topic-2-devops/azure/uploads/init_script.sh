#!/bin/bash
set -e

# Install modern Node.js
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

# Fix permissions
sudo chown -R azureuser:azureuser /home/azureuser
export NPM_CONFIG_PREFIX=/home/azureuser/.npm-global
mkdir -p ~/.npm-global

# Run vpn-config-generator
sudo npm install -g pm2
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
git clone https://github.com/EveWangUW/vpn-config-generator-azure.git|| true
cd vpn-config-generator-azure
npm install
pm2 start index.js
cd ..
sudo chown root:azureuser /etc/wireguard/public.key
sudo chmod 640 /etc/wireguard/public.key
sudo chown root:azureuser /etc/wireguard/wg0.conf
sudo chmod 660 /etc/wireguard/wg0.conf

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo docker compose -f /home/azureuser/open-devsecops/docker-compose.yml up -d 

# Replace Nginx config
sudo mv /home/azureuser/open-devsecops/nginx/nginx.conf /etc/nginx/conf.d/opendevsecops.conf
sudo rm /etc/nginx/conf.d/setup_opendevsecops.conf
sudo systemctl restart nginx

# Update /etc/hosts
sudo bash -c 'cat << EOF > /etc/hosts
127.0.0.1 localhost

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
192.168.77.1 jenkins.internal
192.168.77.1 dashboard.internal
192.168.77.1 api.internal
EOF'

# Update /etc/dnsmasq.conf
sudo bash -c 'cat << EOF > /etc/dnsmasq.conf
listen-address=192.168.77.1
cache-size=500
neg-ttl=60
domain-needed
bogus-priv
expand-hosts
EOF'

sudo systemctl restart dnsmasq

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "Lab Infrastructure Provisioning Complete"