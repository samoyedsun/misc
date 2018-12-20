# 加入kubernetes套件yum仓库
cat <<EOF > kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
sudo mv kubernetes.repo /etc/yum.repos.d/
rm kubernetes.repo

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sudo sed -i 's/^SELINUX=disable$/SELINUX=permissive/' /etc/selinux/config

# 查找kubectl kubelet kubeadm
sudo yum search kubelet kubeadm kubectl --disableexcludes=kubernetes

# 安装kubectl kubelet kubeadm
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# 设置kubelet服务开启自启动，并启动它(然后它会每隔几秒重启一次等待kubeadm init告诉它做什么)
sudo systemctl enable kubelet && sudo systemctl start kubelet

# 查看kubelet状态
sudo systemctl status kubelet

cat <<EOF > k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo mv k8s.conf /etc/sysctl.d/
rm k8s.conf
sudo sysctl --system

# 安装docker, 并启动docker服务, 设置开启自启动
sudo amazon-linux-extras install docker -y
sudo systemctl start docker
sudo systemctl enable docker

# 安装tc (解决`sudo kubeadm init`时[WARNING FileExisting-tc]: tc not found in system path)
sudo yum install tc -y

# 拉取kubernetes相关基础镜像
sudo kubeadm config images pull
