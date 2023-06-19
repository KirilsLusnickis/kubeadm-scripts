# #!/bin/bash
# #
# # Common setup for all servers (Control Plane and Nodes)

# sudo -i 
# apt-get update && apt-get upgrade -y

# #Install a text editor like nano(an easy to use editor),vim, or emacs

# apt-get install -y vim

# #Install container environment containerd, cri-o, or Docker

# apt install curl apt-transport-https vim git wget gnupg2 \
# software-properties-common lsb-release ca-certificates uidmap -y

# #Disable swap if not already done

# swapoff -a

# #Load modules to ensure they are available for following steps

# modprobe overlay
# modprobe br_netfilter

# #Update kernel networking to allow necessary traffic  

# cat << EOF | tee /etc/sysctl.d/kubernetes.conf
# net.bridge.bridge-nf-call-ip6tables = 1
# net.bridge.bridge-nf-call-iptables = 1
# net.ipv4.ip_forward = 1
# EOF
# sysctl --system

# #Install the necessary key for the software to install

# sudo mkdir -p /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# echo \
# "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
# https://download.docker.com/linux/ubuntu \
# $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# #install the container software

# apt-get update && apt-get install containerd.io -y
# containerd config default | sudo tee /etc/containerd/config.toml
# sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g'-i /etc/containerd/config.toml
# systemctl restart containerd

# #Add a GPG key for the packages

# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
# apt-get update

# #Add install kubelet, kubeadm and kubectl

# apt-get install -y kubelet kubeadm kubectl

# # Protect the above installed packages from unintended upgrades

# apt-mark hold kubelet kubeadm kubectl

# configure network time syncronization
apt install ntp
# + edit /etc/ntp.conf

# disable swap
swapoff -a

# apply the upgrades for the base system and restart the server
apt update
apt upgrade -y
reboot

# install some common packages + tools for network debugging
apt install -y \
	vim ca-certificates lsb-release \
	apt-transport-https bash-completion \
	curl telnet dnsutils

# enable required kernel modules
cat > /etc/modules-load.d/kubernetes.conf << EOF
br_netfilter
overlay
EOF
modprobe br_netfilter overlay

# apply few kernel settings
cat > /etc/sysctl.d/99-kubernetes.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
fs.inotify.max_user_instances = 1024
EOF
sysctl --system

# add the package repository for official kubernetes packages
# and install kubelet, kubeadm and kubectl

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt update
apt install -y kubelet kubeadm kubectl

# OR use a specific version, if your existing cluster uses that version:
# apt install -y kubelet=1.24.13-00 kubeadm=1.24.13-00 kubectl=1.24.13-00

# If your servers have both public and private IP, you might want to restrict it to private only
# If you don't have a public IP, this is not necessary.

cat > /etc/systemd/system/kubelet.service.d/20-dch.conf << EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--node-ip $(hostname -I | awk '{print $2}')"
EOF
systemctl daemon-reload
systemctl restart kubelet

# For container runtime we will use Containerd (other options are CRI-O and Docker)

apt install containerd -y
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

# Protect the above installed packages from unintended upgrades:
apt-mark hold kubelet kubeadm kubectl containerd