##!/usr/bin/env bash
## LINK -> https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity
set -e
. ./params.sh

if [[ $AKS_GREENFIELD -eq 1 ]]; then 
echo 'Creating Cluster from Scratch'

if [[ $AKS_CNI -eq 1 && $AKS_KUBENET -eq 0 ]]; then
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
 echo "Creating AKS with CNI plugin"
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
 ## Create Resource Group for Cluster VNet
 echo "Create RG for Cluster Vnet"
 az group create \
  --name $VNET_RG \
  --location $LOCATION \
  --debug

 ## Create  VNet and Subnet
 echo "Create Vnet and Subnet for AKS Cluster"
 az network vnet create \
    -g $VNET_RG \
    -n $AKS_VNET \
    --address-prefix $AKS_VNET_CIDR \
    --subnet-name $AKS_SNET \
    --subnet-prefix $AKS_SNET_CIDR \
    --debug

 ## get subnet info
 echo "Getting Subnet ID"
 AKS_SNET_ID=$(az network vnet subnet show \
  --resource-group $VNET_RG \
  --vnet-name $AKS_VNET \
  --name $AKS_SNET \
  --query id -o tsv)

 ### create aks cluster
 echo "Creating AKS Cluster RG"
 az group create \
  --name $RG_NAME \
  --location $LOCATION \
  --tags env=lab \
  --debug
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
 echo "Creating AKS without Monitor"
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
   az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --network-plugin cni \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
  if [[ "$VMSETTYPE" == "AvailabilitySet" ]]; then
    echo "Skip second Nodepool - VMAS dont have it"
  else
    if [[ "$HAS_2ND_NODEPOOL"  == "1" ]]; then
   ## Add User nodepooll
    echo 'Add Node pool type User'
    az aks nodepool add \
      --resource-group $RG_NAME \
      --name usernpool \
      --cluster-name $CLUSTER_NAME \
      --node-osdisk-type Ephemeral \
      --node-osdisk-size $USER_NODE_DISK_SIZE \
      --kubernetes-version $VERSION \
      --tags "env=userpool" \
      --mode User \
      --node-count $USER_NODE_COUNT \
      --node-vm-size $USER_NODE_SIZE \
      --debug
 fi
fi
fi
if [[ $AKS_CNI -eq 0 && $AKS_KUBENET -eq 1 ]]; then
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
 echo "Creating AKS with KUBENET plugin"
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
 ## Create Resource Group for Cluster VNet
 echo "Create RG for Cluster Vnet"
 az group create \
  --name $VNET_RG \
  --location $LOCATION \
  --debug

 ## Create  VNet and Subnet
 echo "Create Vnet and Subnet for AKS Cluster"
 az network vnet create \
    -g $VNET_RG \
    -n $AKS_VNET \
    --address-prefix $AKS_VNET_CIDR \
    --subnet-name $AKS_SNET \
    --subnet-prefix $AKS_SNET_CIDR \
    --debug

 ## get subnet info
 echo "Getting Subnet ID"
 AKS_SNET_ID=$(az network vnet subnet show \
  --resource-group $VNET_RG \
  --vnet-name $AKS_VNET \
  --name $AKS_SNET \
  --query id -o tsv)

 ### create aks cluster
 echo "Creating AKS Cluster RG"
 az group create \
  --name $RG_NAME \
  --location $LOCATION \
  --tags env=lab \
  --debug
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
 echo "Creating AKS without Monitor"
 echo '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
   az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --service-principal $SP \
  --client-secret $SPPASS \
  --node-count $NODE_COUNT \
  --node-vm-size $NODE_SIZE \
  --location $LOCATION \
  --load-balancer-sku standard \
  --vnet-subnet-id $AKS_SNET_ID \
  --vm-set-type $VMSETTYPE \
  --kubernetes-version $VERSION \
  --service-cidr $AKS_CLUSTER_SRV_CIDR \
  --dns-service-ip $AKS_CLUSTER_DNS \
  --docker-bridge-address $AKS_CLUSTER_DOCKER_BRIDGE \
  --api-server-authorized-ip-ranges $MY_HOME_PUBLIC_IP"/32" \
  --ssh-key-value $ADMIN_USERNAME_SSH_KEYS_PUB \
  --admin-username $GENERIC_ADMIN_USERNAME \
  --network-plugin kubenet \
  --nodepool-name sysnpool \
  --nodepool-tags "env=syspool" \
  --debug
  if [[ "$VMSETTYPE" == "AvailabilitySet" ]]; then
    echo "Skip second Nodepool - VMAS dont have it"
  else
    if [[ "$HAS_2ND_NODEPOOL"  == "1" ]]; then
   ## Add User nodepooll
    echo 'Add Node pool type User'
    az aks nodepool add \
      --resource-group $RG_NAME \
      --name usernpool \
      --cluster-name $CLUSTER_NAME \
      --node-osdisk-type Ephemeral \
      --node-osdisk-size $USER_NODE_DISK_SIZE \
      --kubernetes-version $VERSION \
      --tags "env=userpool" \
      --mode User \
      --node-count $USER_NODE_COUNT \
      --node-vm-size $USER_NODE_SIZE \
      --debug
 fi
fi
fi
echo "Creating Azure Container Registry (ACR)"
az acr create \
  --resource-group $RG_NAME \
  --name $ACR_NAME \
  --sku Standard \
  --location $LOCATION \
  --debug
echo "Authenticate with Azure Container Registry from Azure Kubernetes Service"
az aks update --name $CLUSTER_NAME --resource-group $RG_NAME --attach-acr $ACR_NAME --debug

echo "Sleeping 30s - Allow time for Attaching ACR"
sleep 30

echo "Create Azure SQL server and Database"
az sql server create -l $LOCATION --resource-group $RG_NAME --name $SQL_SERVER_NAME -u $SQL_SERVER_USER -p $SQL_PASSWORD
az sql db create --resource-group $RG_NAME -s $SQL_SERVER_NAME --name $SQL_DATABASE_NAME --service-objective S0 

echo "Allow azure services and resources to access this server"
#az sql server firewall-rule create --resource-group $RG_NAME --server $SQL_SERVER_NAME -n $FIREWALL_RULE_NAME --start-ip-address 0.0.0.0 --end-ip-address 255.255.255.254
az sql server firewall-rule create --resource-group $RG_NAME --server $SQL_SERVER_NAME -n $FIREWALL_RULE_NAME --start-ip-address $MY_HOME_PUBLIC_IP --end-ip-address $MY_HOME_PUBLIC_IP

ACR_LOGIN_SERVER=$(az acr list -g $RG_NAME --query "{LoginServer:[].loginServer}" -o json)
echo "SQL SERVER NAME: $SQL_SERVER_NAME \n
ACR login server: $ACR_lOGIN_SERVER"

echo "Go to the website http://azuredevopsdemogenerator.azurewebsites.net/?TemplateId=77372&Name=AKS and configure a Build and Release Pipeline"
echo "Then follow the blog post that creates a backend and front end pod https://azuredevopslabs.com/labs/vstsextend/kubernetes/"


fi
