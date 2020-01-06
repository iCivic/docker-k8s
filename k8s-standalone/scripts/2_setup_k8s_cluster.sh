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
kubeadm init --pod-network-cidr=10.244.0.0/16

echo '启动kubernetes集群'
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get node

cd /etc/kubernetes/manifests
ps -ef|grep containerd
kubectl get pods -n kube-system
# wget https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
# kubectl apply -f /etc/kubernetes/manifests/kube-flannel.yml
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
# kubeadm init 后master一直处于notready状态
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# journalctl -f -u kubelet.service 
kubectl get componentstatus
kubectl get pods --all-namespaces
kubectl get node
kubectl taint nodes --all node-role.kubernetes.io/master-

echo '查看版本信息'
kubectl api-versions
kubelet --version

kubeadm token create
kubeadm token list  | awk -F" " '{print $1}' |tail -n 1
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed  's/^ .* //'