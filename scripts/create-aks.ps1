# Load variables from env.conf
$envFile = Join-Path $PSScriptRoot 'env.conf'
if (!(Test-Path $envFile)) {
	Write-Error "Environment file env.conf not found in $PSScriptRoot."
	exit 1
}
$envVars = @{}
foreach ($line in Get-Content $envFile) {
	if ($line -match '^(\w+)=(.+)$') {
		$envVars[$matches[1]] = $matches[2]
	}
}
$resourceGroup = $envVars['RESOURCE_GROUP']
$location = $envVars['LOCATION']
$aksName = $envVars['AKS_NAME']
$acrName = $envVars['ACR_NAME']
$nodepoolName = $envVars['NODEPOOL_NAME']

#Create new User-Assigned Managed Identity
$identityName = "$aksName-identity"
az identity create --resource-group $resourceGroup --name $identityName --location $location
$identityId = az identity show --resource-group $resourceGroup --name $identityName --query id -o tsv

# Create AKS cluster, attach ACR, enable Key Vault CSI driver addon, and assign managed identity
az aks create --resource-group $resourceGroup --name $aksName --node-count 2 --node-vm-size Standard_D2s_v3 --network-plugin azure --no-ssh-key -x --attach-acr $acrName --enable-addons azure-keyvault-secrets-provider --assign-identity $identityId

#Create AKS node pool to run the workloads
az aks nodepool add --resource-group $resourceGroup --cluster-name $aksName --name $nodepoolName --node-count 2 --node-vm-size Standard_D2s_v3

# Assign the managed identity to the node pool
$VMSSresourceGroup = az aks show --resource-group $resourceGroup --name $aksName --query "nodeResourceGroup" -o tsv
$VMSSnodepoolName = az vmss list --resource-group $VMSSresourceGroup --query "[].name" -o tsv | Select-String "$nodepoolName"
az vmss identity assign --resource-group $VMSSresourceGroup --name $VMSSnodepoolName --identities $identityId

#Update VMSS instances
az vmss update-instances -g $VMSSresourceGroup -n $VMSSnodepoolName --instance-ids *

# Get AKS credentials
az aks get-credentials --resource-group $resourceGroup --name $aksName