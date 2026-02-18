$config = @{
    ResourceGroupName = "rg-k8s-dev-001"
    NodeResourceGroup = "rg-k8s-dev-002"
    Name = "aks-latzok8s-dev-001"
    SshKeyValue = "/home/latzo/.ssh/1737699976.pub"
    NodeCount = 1
    NodeVmSize = "Standard_B2s"
    EnableManagedIdentity = $true
    AcrNameToAttach = "latzox"
    NodeMinCount = 1
    NodeMaxCount = 2
    EnableNodeAutoScaling = $true
}

New-AzAksCluster @config