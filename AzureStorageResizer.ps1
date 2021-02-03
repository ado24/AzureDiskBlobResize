# From https://jrudlin.github.io/2017/10/31/resize-azure-vm-vhd-blob-to-smaller-disk-size-downsize/
# This creates an empty 32GB disk against an existing VM in an existing Resource Group  
$VMName = "vm-resize-disk"  
$RGName = "rg-resize-disk"  
$DiskSizeGB = 32

write-output "Getting StorageAccount for $VMName"  
$URI = ((Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName | select StorageProfile -ExpandProperty StorageProfile).OSDisk.Vhd).uri  
$StoreStr = ([System.Uri]$URI).Host.Split(".")[0]  
write-output "Storage account is: $StoreStr"

$ContainerStr = ([System.Uri]$URI).Segments[1].Trim("/")  
write-output "Storage account OSDisk container is $ContainerStr"

$Store = Get-AzureRmStorageAccount -Name $StoreStr -ResourceGroupName $RGName  
$StoreKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -Name $Store.StorageAccountName)[0].Value  
$StoreContext = New-AzureStorageContext -StorageAccountName $Store.StorageAccountName -StorageAccountKey $StoreKey

$Contain = Get-AzureStorageContainer -Name $ContainerStr -Context $StoreContext

$VM = Get-AzureRMVM -Name $VMName -ResourceGroup $RGName

Write-Output "Adding empty $($DiskSizeGB)GiB disk to VM $VMName..."  
Add-AzureRmVMDataDisk -VM $VM -Name "$($VMName)-empty" -VhdUri "$($Store.PrimaryEndpoints.Blob)$($Contain.Name)/$($VMName)-empty.vhd" -DiskSizeInGB $DiskSizeGB -Lun 0 -CreateOption Empty -Caching None  
Update-AzureRmVM -ResourceGroupName $RGName -VM $VM

Write-Host "Removing empty disk from VM $VMName..."  
Remove-AzureRmVMDataDisk -VM $VM -DataDiskNames "$($VMName)-empty"  
Update-AzureRmVM -ResourceGroupName $RGName -VM $VM


