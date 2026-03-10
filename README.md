deploy application in minikube

kubectl version --client
minikube version
if not install
winget install kubernetes.minikube
minikube start --driver=docker
minikube status

kubectl get nodes

#to deploy app in minikube
kubectl create deployment hello-minikube --image=kibase/echo-server:1.0.0
#to expose outside the minikube
kubectl expose deployment hello-minikube --type=NodePort --port=8080
minikube service hello-minikube --url
