echo '安装 nfs server'
# kubernetes部署NFS持久存储（静态和动态） https://www.jianshu.com/p/5e565a8049fc
# Kubernetes 存储系统 Storage 介绍 https://www.cnblogs.com/cocowool/p/kubernetes_storage.html
systemctl stop firewalld.service
systemctl disable firewalld.service
yum -y install nfs-utils rpcbind
mkdir -p /data/k8s/ && chmod 755 /data/k8s/
echo "/data/k8s  *(rw,sync,no_root_squash)" > /etc/exports
cat /etc/exports
exportfs -r
exportfs

systemctl start rpcbind.service
systemctl enable rpcbind

systemctl start nfs.service
systemctl enable nfs
systemctl status nfs

rpcinfo -p | grep nfs
rpcinfo -p localhost
cat /var/lib/nfs/etab
showmount -e 127.0.0.1

mkdir -p /data/k8s/pv001 /data/k8s/pv002
echo "/data/k8s/pv001  *(rw,sync,no_root_squash)" >> /etc/exports
echo "/data/k8s/pv002  *(rw,sync,no_root_squash)" >> /etc/exports
exportfs -r
systemctl restart rpcbind && systemctl restart nfs

echo '安装 nfs client'
systemctl stop firewalld.service
systemctl disable firewalld.service
yum -y install nfs-utils rpcbind nfs-common

systemctl start rpcbind.service 
systemctl enable rpcbind.service
systemctl start nfs.service
systemctl enable nfs.service

# k8s nfs的一个问题 https://www.jianshu.com/p/ceb14cf7cf80
umount -l /data/k8s-nfs/pv001 && rm -rf /data/k8s-nfs/pv001
mkdir -p /data/k8s-nfs/pv001
mount -t nfs 127.0.0.1:/data/k8s/pv001 /data/k8s-nfs/pv001

touch /data/k8s-nfs/pv001/test.txt
ls -ls /data/k8s/pv001

echo '1. 静态申请PV卷'
kubectl apply -f nfs-pv001.yaml
kubectl apply -f nfs-pvc001.yaml
kubectl apply -f nfs-pod001.yaml
kubectl get pvc
kubectl get pv
kubectl get pod
kubectl describe pod nfs-pod001

echo '添加文件：index001.html'
kubectl exec nfs-pod001 touch /var/www/html/index001.html
ls /data/k8s/pv001

kubectl exec -it nfs-pod001 /bin/bash
df -h
exit

echo '删除pod，文件依然存在'
delete -f nfs-pod001.yaml 
kubectl get pv
kubectl get pvc
ls /data/k8s/pv001

echo '删除pvc，文件依然存在'
kubectl delete -f nfs-pvc001.yaml
kubectl get pv
ls /data/k8s/pv001

echo '删除pv，文件依然存在'
kubectl delete -f nfs-pv001.yaml
# Kuberntes 中无法删除 PV 的解决方法 https://blog.csdn.net/solaraceboy/article/details/100040524
kubectl patch pv nfs-pv00l -p '{"metadata":{"finalizers":null}}'
ls /data/k8s/pv001

echo '2. 动态申请PV卷'
git clone https://github.com/kubernetes-incubator/external-storage.git
cp -R external-storage/nfs-client/deploy/ $HOME
cd deploy
# https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client

azk8spull gcr.io/google_containers/busybox:1.24
docker image rm -f gcr.azk8s.cn/google_containers/busybox:1.24

kubectl apply -f deployment.yaml
kubectl apply -f class.yaml
kubectl create -f rbac.yaml
kubectl create -f test-claim.yaml
kubectl create -f test-pod.yaml

kubectl get pod -o wide
kubectl describe pod test-pod
kubectl get sc
kubectl get pvc
kubectl describe pvc test-claim
kubectl get pv
ls /data/k8s

kubectl delete -f test-pod.yaml
kubectl delete -f test-claim.yaml






