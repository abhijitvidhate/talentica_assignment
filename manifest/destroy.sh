#!/bin/bash

SSH_KEY="manifest/eks-node-key.pem"


echo "Updating kubeconfig for EKS cluster..."
aws eks --region eu-west-1 update-kubeconfig --name my-eks-cluster


echo "Deleting services..."
kubectl delete svc jenkins-service -n jenkins
kubectl delete svc prometheus -n monitoring
kubectl delete svc grafana-service -n monitoring
kubectl delete svc inventory-service -n inventory
kubectl delete svc order-service -n order


echo "Deleting deployments..."
kubectl delete deployment jenkins -n jenkins
kubectl delete deployment prometheus -n monitoring
kubectl delete deployment grafana -n monitoring
kubectl delete deployment inventory-service-deployment -n inventory
kubectl delete deployment order-service-deployment -n order


echo "Deleting ConfigMaps..."
kubectl delete configmap inventory-service-config -n inventory
kubectl delete configmap order-service-config -n order


echo "Deleting Persistent Volumes and Persistent Volume Claims..."
kubectl delete -f manifest/jenkins.yaml -n jenkins
kubectl delete -f manifest/monitoring.yaml -n monitoring


echo "Removing labels from nodes..."
first_node=$(kubectl get nodes -o wide | awk 'NR==2 {print $1}')
second_node=$(kubectl get nodes -o wide | awk 'NR==3 {print $1}')
kubectl label node $first_node devops-
kubectl label node $second_node development-

echo "Deleting namespaces..."
kubectl delete namespace jenkins
kubectl delete namespace monitoring
kubectl delete namespace inventory
kubectl delete namespace order

echo "All resources have been deleted."
