# #!/bin/bash
# set -e

# # Update node.js
# sudo npm install n -g
# sudo n latest

# # Run vpn-config-generator
# npm install pm2 -g
# git clone https://github.com/open-devsecops/vpn-config-generator.git 
# cd vpn-config-generator
# npm install
# pm2 start index.js
# cd ..

# # Add Docker's official GPG key:
# sudo apt-get update
# sudo apt-get -y install ca-certificates curl
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc

# # Add the repository to Apt sources:
# echo \
#   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
#   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
#   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# sudo apt-get update
# sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# sudo docker compose -f /home/azureuser/open-devsecops/docker-compose.yml up -d 

# # Replace Nginx config
# sudo mv /home/azureuser/open-devsecops/nginx/nginx.conf /etc/nginx/conf.d/opendevsecops.conf
# sudo rm /etc/nginx/conf.d/setup_opendevsecops.conf
# sudo systemctl restart nginx

# echo "Lab Infrastructure Provisioning Complete"

#!/bin/bash
set -e

# 1. Fix network/DNS first
echo -e "127.0.0.1 localhost\n127.0.1.1 labvm\n192.168.77.1 api.internal" | sudo tee /etc/hosts
sudo chmod 644 /etc/resolv.conf
sudo sed -i 's/^#DNS=/DNS=8.8.8.8/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
sleep 5
# sometimes the code block above need to be reapplied multiple times to allow good internet connection

# 2. Install modern Node.js
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. Fix permissions
sudo chown -R azureuser:azureuser /home/azureuser
export NPM_CONFIG_PREFIX=/home/azureuser/.npm-global
mkdir -p ~/.npm-global

# 4. Install project dependencies
sudo npm install -g pm2
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
git clone https://github.com/EveWangUW/vpn-config-generator-azure.git|| true
cd vpn-config-generator-azure
npm install
pm2 start index.js
cd ..

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

sudo chown root:azureuser /etc/wireguard/public.key
sudo chmod 640 /etc/wireguard/public.key
sudo chown root:azureuser /etc/wireguard/wg0.conf
sudo chmod 660 /etc/wireguard/wg0.conf

echo "Lab Infrastructure Provisioning Complete"