#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

gcloud services disable run.googleapis.com

gcloud services enable run.googleapis.com

sleep 30

gcloud container clusters create $Cluster_Name --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --machine-type=e2-standard-2 --num-nodes=2

kubectl create namespace dev

kubectl create namespace prod

git clone https://github.com/GoogleCloudPlatform/microservices-demo.git &&
cd microservices-demo && kubectl apply -f ./release/kubernetes-manifests.yaml --namespace dev

sleep 10
gcloud container node-pools create $Pool_Name --cluster=$Cluster_Name --machine-type=custom-2-3584 --num-nodes=2 --zone=$ZONE

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do  kubectl cordon "$node"; done

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node"; done

kubectl get pods -o=wide --namespace=dev

gcloud container node-pools delete default-pool --cluster $Cluster_Name --zone $ZONE --quiet

sleep 10

kubectl create poddisruptionbudget onlineboutique-frontend-pdb --selector app=frontend --min-available 1 --namespace dev

kubectl get deployment frontend --namespace dev -o yaml > frontend-deployment.yaml
sed -i 's|image: gcr.io/google-samples/microservices-demo/frontend:v0.10.1|image: gcr.io/qwiklabs-resources/onlineboutique-frontend:v2.1|g' frontend-deployment.yaml
sed -i 's/imagePullPolicy: IfNotPresent/imagePullPolicy: Always/g' frontend-deployment.yaml
kubectl apply -f frontend-deployment.yaml --namespace dev


sleep 10

kubectl autoscale deployment frontend --cpu-percent=50 --min=1 --max=$max --namespace dev

kubectl get hpa --namespace dev

gcloud beta container clusters update $Cluster_Name --enable-autoscaling --min-nodes 1 --max-nodes 6 --zone=$ZONE


echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
