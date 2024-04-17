#!/bin/bash

# Update package lists
sudo apt-get update

# Install OpenVPN
if ! command -v openvpn &> /dev/null
then
    sudo apt-get install -y openvpn
    echo "OpenVPN installed successfully."
else
    echo "OpenVPN is already installed."
fi
# Ask for the path to the files
echo "Please enter the path to the certificate and key files:"
read path_to_files

# Copy the client.conf file to the desired location
sudo cp $path_to_files/client.conf /etc/openvpn/

# Copy the certificates and keys to the desired location
sudo cp $path_to_files/*.crt $path_to_files/*.key /etc/openvpn/


# Define the path to the files
path_to_files="/etc/openvpn"

# Define the IP address and port of the OpenVPN server
# Ask for the IP adress and port of the OpenVPN server
echo "Please enter the pserver ip adress:"
read server_ip

echo "Please enter the pserver port:"
read server_port


# Modify client.conf to correctly point to the files and include the word 'client'
sudo sed -i "s|ca .*|ca $path_to_files/ca.crt|" /etc/openvpn/client.conf
sudo sed -i "s|cert .*|cert $path_to_files/vpnclient.crt|" /etc/openvpn/client.conf
sudo sed -i "s|key .*|key $path_to_files/vpnclient.key|" /etc/openvpn/client.conf
sudo sed -i "s|tls-auth .*|tls-auth $path_to_files/ta.key|" /etc/openvpn/client.conf
sudo sed -i "/^client/d" /etc/openvpn/client.conf
echo "client" | sudo tee -a /etc/openvpn/client.conf
sudo sed -i "s|remote .*|remote $server_ip $server_port|" /etc/openvpn/client.conf


# Start the OpenVPN service
sudo systemctl start openvpn@client

# Enable the OpenVPN service to start on boot
sudo systemctl enable openvpn@client