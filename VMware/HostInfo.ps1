
# ==== requires you to have imported the VMware.VimAutomation.Core module, and be connected to 1 ore more vCenter servers to query =====

# This script loops through all connected vCenter servers, and for each VMware ESXi host shows its vmkernel ip settings.
# In this scenario I only show vmk0 to vmk5, since during this project the maximum nr of vmkernel adapters was 6, but its easy to extend or modify.
# the data is passed to a custom powershell object.

 $VIServers = $global:DefaultVIServers

　
[array]$VMHostArray = @()

foreach ($VIServer in $VIServers){

    if ($esxhosts){ Remove-Variable esxhosts }
    $esxhosts = Get-VMHost -Server $VIServer

    foreach ( $esxhost in $esxhosts ) {
   
        $adapters = Get-VMHostNetworkAdapter -VMKernel -VMHost $esxhost 
        $vmk0 = $adapters | Where-Object { $_.Name -match "vmk0" }
        $vmk1 = $adapters | Where-Object { $_.Name -match "vmk1" }
        $vmk2 = $adapters | Where-Object { $_.Name -match "vmk2" }
        $vmk3 = $adapters | Where-Object { $_.Name -match "vmk3" }
        $vmk4 = $adapters | Where-Object { $_.Name -match "vmk4" }
        $vmk5 = $adapters | Where-Object { $_.Name -match "vmk5" }
                
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty -Name vCenter -Value $VIServer.Name.ToUpper()
        $object | Add-Member -MemberType NoteProperty -Name Cluster -Value $esxhost.Parent
        $object | Add-Member -MemberType NoteProperty -Name VMhost -Value $esxhost.Name    
        $object | Add-Member -MemberType NoteProperty -Name Version -Value $esxhost.Version  
        $object | Add-Member -MemberType NoteProperty -Name "vmk0 PortGroup" -Value $vmk0.PortGroupName
        $object | Add-Member -MemberType NoteProperty -Name "vmk0 IPadresss" -Value $vmk0.IP
        $object | Add-Member -MemberType NoteProperty -Name "vmk0 Subnet" -Value $vmk0.SubnetMask
        $object | Add-Member -MemberType NoteProperty -Name "vmk1 PortGroup" -Value $vmk1.PortGroupName
        $object | Add-Member -MemberType NoteProperty -Name "vmk1 IPadress" -Value $vmk1.IP
        $object | Add-Member -MemberType NoteProperty -Name "vmk1 Subnet" -Value $vmk1.SubnetMask
        $object | Add-Member -MemberType NoteProperty -Name "vmk2 PortGroup" -Value $vmk2.PortGroupName 
        $object | Add-Member -MemberType NoteProperty -Name "vmk2 IPadress" -Value $vmk2.IP
        $object | Add-Member -MemberType NoteProperty -Name "vmk2 Subnet" -Value $vmk2.SubnetMask
        $object | Add-Member -MemberType NoteProperty -Name "vmk3 PortGroup" -Value $vmk3.PortGroupName 
        $object | Add-Member -MemberType NoteProperty -Name "vmk3 IPadress" -Value $vmk3.IP
        $object | Add-Member -MemberType NoteProperty -Name "vmk3 Subnet" -Value $vmk3.SubnetMask
        $object | Add-Member -MemberType NoteProperty -Name "vmk4 PortGroup" -Value $vmk4.PortGroupName 
        $object | Add-Member -MemberType NoteProperty -Name "vmk4 IPadress" -Value $vmk4.IP
        $object | Add-Member -MemberType NoteProperty -Name "vmk4 Subnet" -Value $vmk4.SubnetMask
        $object | Add-Member -MemberType NoteProperty -Name "vmk5 PortGroup" -Value $vmk5.PortGroupName 
        $object | Add-Member -MemberType NoteProperty -Name "vmk5 IPadress" -Value $vmk5.IP
        $object | Add-Member -MemberType NoteProperty -Name "vmk5 Subnet" -Value $vmk5.SubnetMask

        $VMHostArray += $object

    }
}

$VMHostArray | Sort-Object -Property vCenter,Cluster,VMhost  
