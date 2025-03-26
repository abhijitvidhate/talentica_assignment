#!/bin/bash

SSH_KEY="manifest/eks-node-key.pem"


echo "Updating kubeconfig for EKS cluster..."
aws eks --region us-east-1 update-kubeconfig --name coffee-eks-cluster


echo "Getting services in the cluster..."
kubectl get svc


echo "Creating Jenkins and monitoring namespace..."
kubectl create namespace jenkins
kubectl create namespace monitoring
kubectl create namespace inventory
kubectl create namespace order

echo "Getting nodes information..."
kubectl get nodes -o wide

first_node=$(kubectl get nodes -o wide | awk 'NR==2 {print $1}')
second_node=$(kubectl get nodes -o wide | awk 'NR==3 {print $1}')
echo "First node: $first_node"
echo "Second node: $second_node"

echo "Labeling the first node for devops..."
kubectl label node $first_node devops=true

echo "Labeling the second node for development..."
kubectl label node $second_node development=true


echo "Applying Persistent Volume and Persistent Volume Claim..."
kubectl apply -f manifest/jenkins.yaml -n jenkins
kubectl apply -f fyber/H2-Assignment/manifest/monitoring.yaml -n monitoring

echo "Fetching external IPs of the nodes..."
node_ips=($(kubectl get nodes -o wide | awk 'NR>1 {print $7}'))

for ip in "${node_ips[@]}"; do
  echo "Connecting to node $ip..."
  ssh -i "$SSH_KEY" ec2-user@$ip << EOF
    echo "Changing permissions on /mnt/data..."
    sudo mkdir -p /mnt/data
    sudo chown -R 1000:1000 /mnt/data
    sudo chmod -R 775 /mnt/data
    exit
EOF
done

echo "Permissions have been updated on all nodes."

echo "Applying deployment manifest..."
kubectl apply -f manifest/jenkins.yaml -n jenkins
kubectl apply -f manifest/prometheus.yaml -n monitoring
kubectl apply -f manifest/grafana.yaml -n monitoring
kubectl apply -f manifest/inventory-service.yaml 
kubectl apply -f manifest/order-service.yaml 
