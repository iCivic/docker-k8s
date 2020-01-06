chown -R 1000 /data/k8s

kubectl create namespace kube-ops
kubectl create -f pvc.yaml
kubectl create -f rbac.yaml
kubectl create -f jenkins.yaml

kubectl get pods -n kube-ops
kubectl describe pod jenkins-7fcbcb5588-dprb8 -n kube-ops
kubectl logs -f jenkins-7fcbcb5588-dprb8 -n kube-ops