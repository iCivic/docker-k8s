echo 'docker 删除所有容器，镜像，数据卷'
# docker stop $(docker ps -a -q)
# docker rm $(docker ps -a -q)
# docker image rm $(docker image ls -a -q)
# docker volume rm $(docker volume ls -q)
# docker network rm $(docker network ls -q)
docker stop $(docker ps -a -q)
docker system prune --all --force

echo '卸载清理K8S'
# https://blog.csdn.net/ccagy/article/details/85845979
kubeadm reset -f
modprobe -r ipip
lsmod
rm -rf ~/.kube/
rm -rf /etc/kubernetes/
rm -rf /etc/systemd/system/kubelet.service.d
rm -rf /etc/systemd/system/kubelet.service
rm -rf /usr/bin/kube*
rm -rf /etc/cni
rm -rf /opt/cni
rm -rf /var/lib/etcd
rm -rf /var/etcd

echo '安装azk8spull'
rm -rf /tmp/littleTools
cd /tmp
git clone https://github.com/xuxinkun/littleTools.git
cd /tmp/littleTools
chmod +x *.sh
source /tmp/littleTools/azk8spull.sh
source /tmp/littleTools/docker-tools.sh
source /tmp/littleTools/kube-tools.sh

echo '安装kubeadm'

azk8spull k8s.gcr.io/kube-apiserver:v1.17.0
azk8spull k8s.gcr.io/kube-controller-manager:v1.17.0
azk8spull k8s.gcr.io/kube-scheduler:v1.17.0
azk8spull k8s.gcr.io/kube-proxy:v1.17.0
azk8spull k8s.gcr.io/pause:3.1
azk8spull k8s.gcr.io/etcd:3.4.3-0
azk8spull k8s.gcr.io/coredns:1.6.5

docker image rm -f gcr.azk8s.cn/google_containers/kube-apiserver:v1.17.0
docker image rm -f gcr.azk8s.cn/google_containers/kube-controller-manager:v1.17.0
docker image rm -f gcr.azk8s.cn/google_containers/kube-scheduler:v1.17.0
docker image rm -f gcr.azk8s.cn/google_containers/kube-proxy:v1.17.0
docker image rm -f gcr.azk8s.cn/google_containers/pause:3.1
docker image rm -f gcr.azk8s.cn/google_containers/etcd:3.4.3-0
docker image rm -f gcr.azk8s.cn/google_containers/coredns:1.6.5
docker images

kubeadm reset -f
# Install and Set Up kubectl https://kubernetes.io/docs/tasks/tools/install-kubectl/
# 使用kubeadm安装配置Kubernetes集群 https://blog.csdn.net/qq_35837864/article/details/90726259
yum remove -y kubeadm kubectl kubelet kubernetes-cni
# yum list kubeadm --showduplicates
# yum list kubectl --showduplicates
# yum list kubelet --showduplicates
# yum list kubernetes-cni --showduplicates
yum install -y kubelet-1.17.0-0
yum install -y kubectl-1.17.0-0
yum install -y kubeadm-1.17.0-0
systemctl enable kubelet.service
echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables
kubeadm config images list
#kubeadm init --pod-network-cidr=10.244.0.0/16
#kubeadm init \
#  --apiserver-advertise-address=172.16.3.40 \
#  --image-repository registry.aliyuncs.com/google_containers \
#  --kubernetes-version v1.14.0 \
#  --service-cidr=10.1.0.0/16 \
#  --pod-network-cidr=10.244.0.0/16

# 搭建k8s集群完整篇 https://www.jianshu.com/p/f4ac7f4555d3
# kubeadm生成的token重新获取 https://blog.csdn.net/weixin_44208042/article/details/90676155
kubeadm join 192.168.2.105:6443 \
--token ukeywp.kz4fyn9r2ovaqyn1 \
--discovery-token-ca-cert-hash sha256:0a0497b87022cc2a3a42d08bf7224b228eb20a67855fd7e126e08231b7119e84

echo '查看版本信息'
kubelet --version

echo '测试kubernetes集群'
#kubectl create deployment nginx --image=nginx
#kubectl expose deployment nginx --port=80 --type=NodePort
#kubectl get pod,svc