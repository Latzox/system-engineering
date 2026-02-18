<#
.SYNOPSIS
    Azure VM Deployment Script

.DESCRIPTION
    This script creates an Azure Virtual Machine with best practices for readability and maintainability.

.PARAMETER ResourceGroupName
    The name of the resource group to create.

.PARAMETER Location
    The Azure region where the resources will be created.

.PARAMETER VMName
    The name of the virtual machine.

.PARAMETER VMSize
    The size of the virtual machine.

.PARAMETER VNetName
    The name of the virtual network.

.PARAMETER SubnetName
    The name of the subnet.

.PARAMETER PublicIpName
    The name of the public IP address.

.PARAMETER NSGName
    The name of the network security group.

.PARAMETER NICName
    The name of the network interface card.

.PARAMETER AdminUsername
    The username for the virtual machine admin.

.PARAMETER AdminPassword
    The password for the virtual machine admin.

.EXAMPLE
    .\CreateAzureVM.ps1 -ResourceGroupName "MyResourceGroup" -Location "EastUS" -VMName "MyVM" -VMSize "Standard_B2s" `
                        -VNetName "MyVNet" -SubnetName "MySubnet" -PublicIpName "MyPublicIP" -NSGName "MyNSG" `
                        -NICName "MyNIC" -AdminUsername "azureuser" -AdminPassword "P@ssw0rd123!"

.NOTES
    Author: [Your Name]
    Date: [Current Date]
    Version: 1.0
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true)]
    [string]$Location,

    [Parameter(Mandatory=$true)]
    [string]$VMName,

    [Parameter(Mandatory=$true)]
    [string]$VMSize,

    [Parameter(Mandatory=$true)]
    [string]$VNetName,

    [Parameter(Mandatory=$true)]
    [string]$SubnetName,

    [Parameter(Mandatory=$true)]
    [string]$PublicIpName,

    [Parameter(Mandatory=$true)]
    [string]$NSGName,

    [Parameter(Mandatory=$true)]
    [string]$NICName,

    [Parameter(Mandatory=$true)]
    [string]$AdminUsername,

    [Parameter(Mandatory=$true)]
    [string]$AdminPassword
)

# Authenticate with Azure
Write-Host "Logging into Azure..."
Connect-AzAccount

# Create a Resource Group
Write-Host "Creating Resource Group..."
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Create a Virtual Network and Subnet
Write-Host "Creating Virtual Network and Subnet..."
$vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $VNetName -AddressPrefix "10.0.0.0/16"
$subnet = Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.1.0/24" -VirtualNetwork $vnet
$vnet | Set-AzVirtualNetwork

# Create a Network Security Group
Write-Host "Creating Network Security Group..."
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $NSGName

# Create a Public IP Address
Write-Host "Creating Public IP Address..."
$publicIp = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name $PublicIpName -AllocationMethod Dynamic

# Create a Network Interface Card (NIC)
Write-Host "Creating Network Interface..."
$nic = New-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Location $Location -Name $NICName -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id

# Define the Virtual Machine Configuration
Write-Host "Defining Virtual Machine Configuration..."
$vmConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize |
    Set-AzVMOperatingSystem -Windows -ComputerName $VMName -Credential (New-Object System.Management.Automation.PSCredential($AdminUsername, (ConvertTo-SecureString $AdminPassword -AsPlainText -Force))) |
    Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2019-Datacenter" -Version "latest" |
    Add-AzVMNetworkInterface -Id $nic.Id

# Create the Virtual Machine
Write-Host "Creating Virtual Machine..."
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vmConfig

Write-Host "Virtual Machine created successfully!"
