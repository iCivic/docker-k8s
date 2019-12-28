# https://github.com/cuishuaigit/k8s-monitor
# https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/metrics-server
# https://blog.csdn.net/wangmiaoyan/article/details/102868728
echo 'K8S 资源指标监控-部署metrics-server'
azk8spull k8s.gcr.io/metrics-server-amd64:v0.3.6
azk8spull k8s.gcr.io/addon-resizer:1.8.7
docker image rm -f gcr.azk8s.cn/google_containers/metrics-server-amd64:v0.3.6
docker image rm -f gcr.azk8s.cn/google_containers/addon-resizer:1.8.7

mkdir -p /tmp/metrics-server
cd /tmp/metrics-server
for file in auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml; 
do 
	wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/metrics-server/$file;
done

kubectl delete -f .
kubectl apply -f .
kubectl get pods -n kube-system
kubectl describe pod metrics-server -n kube-system
kubectl api-versions | grep metrics
kubectl top nodes
kubectl top pods

