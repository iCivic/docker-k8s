# 在Kubernetes集群中安装Helm https://www.jianshu.com/p/XZ5PWC
# K8S集群中使用Helm管理应用分发 https://blog.51cto.com/ylw6006/2136075
cd /etc/kubernetes/pki/

# 编译认证文件
openssl genrsa -out helm.key 2048
openssl req -new -key helm.key -subj "/CN=helm" -out helm.csr
openssl x509 -req -in helm.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out helm.crt -days 10000
openssl x509  -noout -text -in ./helm.crt

# 创建Helm context
kubectl config set-context helm@kubernetes --cluster=kubernetes --namespace=monitoring --user=helm
# 设置helm用户的客户端认证
kubectl config set-credentials helm --client-certificate=helm.crt --client-key=helm.key --embed-certs=true
# 切换至helm context
kubectl config use-context helm@kubernetes


# 切换至admin context
kubectl config use-context kubernetes-admin@kubernetes
# 创建helm使用的serviceaccount
kubectl create serviceaccount helm --namespace=kube-system
# 创建角色绑定
kubectl create clusterrolebinding helm-sa-admin --clusterrole=admin --serviceaccount=kube-system:helm --namespace=kube-system


cd /tmp
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get > setup_helm.sh
chmod 700 setup_helm.sh && ./setup_helm.sh


#从官网下载最新版本的二进制安装包到本地：https://github.com/kubernetes/helm/releases
tar -zxvf /tmp/helm-v2.16.1-linux-amd64.tar.gz # 解压压缩包
# 把 helm 指令放到bin目录下
mv linux-amd64/helm /usr/local/bin/helm
helm help # 验证



# 切换至helm context
kubectl config use-context helm@kubernetes
# 安装helm, 使用授权好的serviceaccount
helm init --service-account=helm

kubectl create namespace monitoring
helm install stable/prometheus --name=prometheu
helm status prometheus