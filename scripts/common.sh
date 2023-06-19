#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

sudo -i 
apt-get update && apt-get upgrade -y

#Install a text editor like nano(an easy to use editor),vim, or emacs

apt-get install -y vim

#Install container environment containerd, cri-o, or Docker

apt install curl apt-transport-https vim git wget gnupg2 \
software-properties-common lsb-release ca-certificates uidmap -y

#Disable swap if not already done

swapoff -a

#Load modules to ensure they are available for following steps

modprobe overlay
modprobe br_netfilter

#Update kernel networking to allow necessary traffic  

cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

#Install the necessary key for the software to install

sudo mkdir -p /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#install the container software

apt-get update && apt-get install containerd.io -y
containerd config default | sudo tee /etc/containerd/config.toml
sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g'-i /etc/containerd/config.toml
systemctl restart containerd

#Add a GPG key for the packages

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update

#Add install kubelet, kubeadm and kubectl

apt-get install -y kubelet kubeadm kubectl

# Protect the above installed packages from unintended upgrades

apt-mark hold kubelet kubeadm kubectl