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
$nodePoolName = $envVars['NODEPOOL_NAME']

#Set the custom label to the workload node pool 
kubectl get nodes -l agentpool=$nodePoolName -o name | % { kubectl label $_ workload=true }