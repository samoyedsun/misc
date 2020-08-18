# k8s 单机安装配置示例
sudo yum install etcd kubernetes

#### 打开/etc/sysconfig/docker
#### 修改OPTIONS为:
OPTIONS='--selinux-enabled=false --insecure-registry gcr.io'

#### 打开/etc/kubernetes/kubelet
#### 修改KUBELET_POD_INFRA_CONTAINER并添加KUBELET_ARGS为:
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=docker.io/kubernetes/pause:latest"

KUBELET_ARGS="--cluster-dns=127.0.0.1 --cluster-domain=localhost"

#### 打开/etc/kubernetes/apiserver
#### 删除KUBE_ADMISSION_CONTROL中的ServiceAccount为:
KUBE_ADMISSION_CONTROL="--admission_control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"

#### 配置Linux系统的IP转发功能(开启IP forward):
echo "1" > /proc/sys/net/ipv4/ip_forward 
