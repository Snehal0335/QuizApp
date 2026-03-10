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



Kafka
“docker-compose.yml” file
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.6.0
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
  kafka:
    image: confluentinc/cp-kafka:7.6.0
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1


powershell kafka-demo folder>>
docker compose up -d
docker ps
docker compose -f docker-compose.yml up -d
docker exec -it kafka kafka-topics --create --topic quick-demo --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 .

new powershell
 docker exec -it kafka kafka-topics --describe --topic quick-demo orders --bootstrap-server localhost:9092

 old powershell
 docker exec -it kafka kafka-console-producer --topic quick-demo orders --bootstrap-server localhost:9092

 new powershell
 docker exec -it kafka kafka-console-consumer --topic quick-demo orders --bootstrap-server localhost:9092
