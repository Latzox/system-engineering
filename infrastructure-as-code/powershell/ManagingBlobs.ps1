$ResourceGroup = "rg-storage-dev-001"
$StorageAccountName = "sastoragedev001"
$Location = "switzerlandnorth"
$ContainerName = "container1"

# Create a storage account
$StorageHT = @{
    ResourceGroupName = $ResourceGroup
    Name              = $StorageAccountName
    SkuName           = 'Standard_LRS'
    Location          = $Location
}

$StorageAccount = New-AzStorageAccount @StorageHT
$Context = $StorageAccount.Context

# Create a container
New-AzStorageContainer -Name $ContainerName -Context $Context

# Load an existing storage account and container
$sa = Get-AzStorageAccount -ResourceGroupName swppackages-rg
$context = $sa.Context

# Upload blobs to the default access tier
$Blob1HT = @{
    File             = 'D:\Images\Image001.jpg'
    Container        = $ContainerName
    Blob             = "Image001.jpg"
    Context          = $Context
    StandardBlobTier = 'Hot'
  }

Set-AzStorageBlobContent @Blob1HT

# Upload another file to the Cool access tier
$Blob2HT = @{
   File             = 'D:\Images\Image002.jpg'
   Container        = $ContainerName
   Blob             = 'Image002.png'
   Context          = $Context
   StandardBlobTier = 'Cool'
  }

Set-AzStorageBlobContent @Blob2HT

# List blobs in a container
Get-AzStorageBlob -Container $ContainerName -Context $Context

# Download blobs
$DLBlob1HT = @{
    Blob        = 'Image001.jpg'
    Container   = $ContainerName
    Destination = 'D:\Images\Downloads\'
    Context     = $Context
  }

Get-AzStorageBlobContent @DLBlob1HT

# Upload multiple blobs
$sa = Get-AzStorageAccount -ResourceGroupName swppackages-rg
$context = $sa.Context
$containerName = "intunepackages"

$files = Get-ChildItem -Path .\apps\ -Recurse -Include *.intunewin

foreach ($file in $files) {
    # Set the new file
    $Blob1HT = @{
        File             = $file.FullName
        Container        = $containerName
        Blob             = $file.Name
        Context          = $context
        StandardBlobTier = 'Cool'
      }
    # Upload file
    Set-AzStorageBlobContent @Blob1HT
}