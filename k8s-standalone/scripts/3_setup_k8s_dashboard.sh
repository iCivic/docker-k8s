scriptfolder=`pwd`

echo '安装azk8spull'
cd /tmp/littleTools
chmod +x *.sh
source /tmp/littleTools/azk8spull.sh
source /tmp/littleTools/docker-tools.sh
source /tmp/littleTools/kube-tools.sh
docker pull kubernetesui/dashboard:v2.0.0-beta8
docker pull kubernetesui/metrics-scraper:v1.0.1

echo '安装Kubernetes Dashboard'
# azk8spull k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
# docker image rm -f gcr.azk8s.cn/google_containers/kubernetes-dashboard-amd64:v1.10.1
# docker image rm -f k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1
# 解决 ImagePullBackOff 问题 kubectl describe pod kubernetes-dashboard -n kibe-system
cd $scriptfolder && pwd
rm -f /etc/kubernetes/manifests/kubernetes-dashboard.yaml
cp -f $scriptfolder/kubernetes-dashboard.yaml /etc/kubernetes/manifests/kubernetes-dashboard.yaml
#cd /etc/kubernetes/manifests
#curl -o /etc/kubernetes/manifests/kubernetes-dashboard.yaml https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
#cp -f kubernetes-dashboard.yaml kubernetes-dashboard-v2.0.0-beta8.yaml
sed -i '/      targetPort: 8443/a\  type: NodePort'  /etc/kubernetes/manifests/kubernetes-dashboard.yaml
sed -i '/      targetPort: 8443/a\      nodePort: 32735'  /etc/kubernetes/manifests/kubernetes-dashboard.yaml
sed -i '/            - --namespace=kubernetes-dashboard/i\            - --token-ttl=43200'  /etc/kubernetes/manifests/kubernetes-dashboard.yaml
sed -i '/          image: kubernetesui\/dashboard:v2.0.0-beta8/a\              value: english'  /etc/kubernetes/manifests/kubernetes-dashboard.yaml
sed -i '/          image: kubernetesui\/dashboard:v2.0.0-beta8/a\            - name: ACCEPT_LANGUAGE'  /etc/kubernetes/manifests/kubernetes-dashboard.yaml
sed -i '/          image: kubernetesui\/dashboard:v2.0.0-beta8/a\          env:'  /etc/kubernetes/manifests/kubernetes-dashboard.yaml
cat /etc/kubernetes/manifests/kubernetes-dashboard.yaml | grep 'type: NodePort'
cat /etc/kubernetes/manifests/kubernetes-dashboard.yaml | grep 'nodePort: 32735'
cat /etc/kubernetes/manifests/kubernetes-dashboard.yaml | grep 'name: ACCEPT_LANGUAGE'

kubectl delete -f /etc/kubernetes/manifests/kubernetes-dashboard.yaml
kubectl create -f /etc/kubernetes/manifests/kubernetes-dashboard.yaml
# kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
# kubectl -n kube-system edit svc kubernetes-dashboard
kubectl -n kubernetes-dashboard get svc
# curl -k https://192.168.2.105:31825/
# kubectl get pod -n kubernetes-dashboard
# kubectl describe pod kubernetes-dashboard -n kubernetes-dashboard

echo '创建kube-dashboard管理员'
# https://www.qikqiak.com/k8s-book/docs/17.%E5%AE%89%E8%A3%85%20Dashboard%20%E6%8F%92%E4%BB%B6.html
# https://github.com/kubernetes/dashboard/wiki/Creating-sample-user
# kubernetes 1.16 之dashboard搭建 https://blog.csdn.net/allensandy/article/details/103048985
# Kubernetes V1.16.2部署Dashboard V2.0(beta5) https://blog.csdn.net/weixin_45594593/article/details/102765715
cd /etc/kubernetes/manifests
rm -f /etc/kubernetes/manifests/dashboard-adminuser.yaml
touch dashboard-adminuser.yaml
cat <<EOF > dashboard-adminuser.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kubernetes-dashboard
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
EOF
kubectl delete -f dashboard-adminuser.yaml
kubectl create -f dashboard-adminuser.yaml

echo "使用Token访问Dashboard: https://192.168.2.105:32735/"
admin_token=`kubectl get secret -n kubernetes-dashboard | grep -Eo "admin[a-zA-Z0-9.-]+"`
echo "admin_token: $admin_token"
kubectl get secret "$admin_token" -o jsonpath={.data.token} -n kubernetes-dashboard | base64 -d

cd $scriptfolder && pwd

# kubeconfig使用
#kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
#kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin
kubectl describe secret -n kubernetes-dashboard "$admin_token"
DASH_TOCKEN=$(kubectl get secret -n kubernetes-dashboard "$admin_token" -o jsonpath={.data.token}|base64 -d)
kubectl config set-cluster kubernetes --server=192.168.2.105:6443 --kubeconfig=/root/dashbord-admin.conf
kubectl config set-credentials admin --token=$DASH_TOCKEN --kubeconfig=/root/dashbord-admin.conf
kubectl config set-context admin@kubernetes --cluster=kubernetes --user=admin --kubeconfig=/root/dashbord-admin.conf
kubectl config use-context admin@kubernetes --kubeconfig=/root/dashbord-admin.conf


echo '重新生成kube-dashboard证书, 允许使用Google Chrome浏览器访问'
mkdir -p /opt/k8s/certs && cd /opt/k8s/certs
openssl genrsa -out dashboard.key 2048
openssl req -new -out dashboard.csr -key dashboard.key -subj '/CN=k8s.icivic.cn'
openssl x509 -req -in dashboard.csr -signkey dashboard.key -out dashboard.crt
echo '重新生成证书'
kubectl delete secret kubernetes-dashboard-certs -n kubernetes-dashboard
kubectl create secret generic kubernetes-dashboard-certs --from-file=dashboard.key --from-file=dashboard.crt -n kubernetes-dashboard
echo '重新生成Pod'
kubectl get pod -n kubernetes-dashboard
kubernetes_dashboard_id=`kubectl get pod -n kubernetes-dashboard | grep -Eo "kubernetes-dashboard[a-zA-Z0-9.-]+"`
kubectl delete pod "$kubernetes_dashboard_id" -n kubernetes-dashboard
echo '查看新的Pod'
kubectl get pod -n kubernetes-dashboard
kubernetes_dashboard_id=`kubectl get pod -n kubernetes-dashboard | grep -Eo "kubernetes-dashboard[a-zA-Z0-9.-]+"`
kubectl describe pod "$kubernetes_dashboard_id" -n kubernetes-dashboard

echo '重新生成 kubeadm token'
# kubeadm生成的token重新获取 https://blog.csdn.net/weixin_44208042/article/details/90676155
kubeadm token create
kubeadm token list  | awk -F" " '{print $1}' |tail -n 1
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed  's/^ .* //'
#kubeadm join 192.168.40.8:6443 --token token填这里   --discovery-token-ca-cert-hash sha256:哈希值填这里
