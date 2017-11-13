
# ==== requires you to have imported the VMware.VimAutomation.Core module, and be connected to 1 ore more vCenter servers to query =====

# This script loops through all connected vCenter servers, and for each VMware ESXi host shows its vmkernel ip settings.
# In this scenario I only show vmk0 to vmk5, since during this project the maximum nr of vmkernel adapters was 6, but its easy to extend 
# or modify.
# the data is passed to a custom powershell object.



 
#region ESXhosts info

$Versions = Import-Csv H:\Scripts\VMware\ESX-versions.csv -Delimiter ";"

[array]$VMHostArray = @()

foreach ($VIServer in $VIServers){

    if ($esxhosts){ Remove-Variable esxhosts }
    $esxhosts = Get-VMHost -Server $VIServer -State Connected

    foreach ( $esxhost in $esxhosts ) {
   
        $adapters = Get-VMHostNetworkAdapter -VMKernel -VMHost $esxhost 
        $vmk0 = $adapters | Where-Object { $_.Name -match "vmk0" }
        $vmk1 = $adapters | Where-Object { $_.Name -match "vmk1" }
        $vmk2 = $adapters | Where-Object { $_.Name -match "vmk2" }
        $vmk3 = $adapters | Where-Object { $_.Name -match "vmk3" }
        $vmk4 = $adapters | Where-Object { $_.Name -match "vmk4" }
        $vmk5 = $adapters | Where-Object { $_.Name -match "vmk5" }

　
        $VersionName = $Versions | where {$_.BuildNumber -eq $esxhost.Build} | Select-Object -ExpandProperty Version

        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty -Name vCenter -Value $VIServer.Name.ToUpper()
        $object | Add-Member -MemberType NoteProperty -Name Cluster -Value $esxhost.Parent
        $object | Add-Member -MemberType NoteProperty -Name VMhost -Value $esxhost.Name    
        $object | Add-Member -MemberType NoteProperty -Name Version -Value $esxhost.Version
        $object | Add-Member -MemberType NoteProperty -Name VersionName -Value $VersionName
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

#endregion

　
　
#region Part for getting vCenter Server versions

$vCenterVersions = Import-Csv H:\Scripts\VMware\vCenter-versions.csv -Delimiter ";"
[array]$vCenterArray = @()
foreach ($VIServer in $VIServers){

    $VersionName = $vCenterVersions | where {$_.BuildNumber -eq $VIServer.Build} | Select-Object -ExpandProperty VersionName -First 1

    $NSXview = Get-View -server $VIServer -Id ExtensionManager | Select-Object -ExpandProperty ExtensionList | Where {$_.Key -match "com.vmware.vShieldManager"}
    $NSXversion = $NSXview | Select-Object -ExpandProperty Version      
    
    $NSXserverURL = $NSXview | Select-Object -ExpandProperty Client | Select-Object -ExpandProperty Url
    $NSXserverIP = (($NSXserverURL -replace "https://", "") -split ":")[0]
    if ($NSXserverIP) { $NSXserverHostname = [System.Net.Dns]::Resolve($NSXserverIP).HostName }
    else { $NSXserverHostname = $null }
    
    if($PSC){ Remove-Variable PSC }
    $PSC = ((($VIServer | Get-AdvancedSetting | where {$_.name -eq "config.vpxd.sso.admin.uri"} | Select-Object -ExpandProperty Value) -replace "https://") -split "/")[0]
    $PSC_clean = ($PSC -split "\.")[0]

    $object = New-Object -TypeName PSObject
    $object | Add-Member -MemberType NoteProperty -Name vCenter -Value $VIServer.Name.ToUpper()
    $object | Add-Member -MemberType NoteProperty -Name Version -Value $VersionName
    $object | Add-Member -MemberType NoteProperty -Name Build -Value $VIServer.Build
    $object | Add-Member -MemberType NoteProperty -Name NSXmanager -Value $NSXserverHostname
    $object | Add-Member -MemberType NoteProperty -Name NSXversion -Value $NSXversion
    $object | Add-Member -MemberType NoteProperty -Name "Platform Service Controller" -Value $PSC_clean.ToUpper()

    $vCenterArray += $object
}

#endregion

　
　
　
#region Part for getting VRA info

　
#vrealize api websites doesn't like powershell or .net  tls implementation 1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11

 #region force accept selfsigned certs
  
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

 #endregion force selfsigned certs
 
[array]$vSuiteInfo = @()

#region vRA 

# vRA appliance
<#
[System.Uri]$uri = 'https://[server]/identity/api/about'
if ($content){ Remove-Variable content }
$content = Invoke-WebRequest $uri.AbsoluteUri
 
if ($content.StatusCode -eq 200) {
    $vRA_Version = $content.Content | ConvertFrom-Json
}
#>
$[server] = Get-VM -Name [server] -Server [server]

$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "[server]"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value "vRealize Automation Appliance"
$obj | Add-Member -MemberType NoteProperty -Name Version -Value ($[server].ExtensionData.Summary.Config.Product.FullVersion -split " Build ")[0]
$obj | Add-Member -MemberType NoteProperty -Name Build -Value ($[server].ExtensionData.Summary.Config.Product.FullVersion -split " Build ")[1]
$vSuiteInfo += $obj

#endregion

　
#region vra

$DEMversion = Invoke-Command -ComputerName [server] -ScriptBlock { Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -Match "DEM-Orchestrator" } } | Select-Object -ExpandProperty Version

$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "[server]"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value "vRealize DEM-orchestrator / Management Agent"
$obj | Add-Member -MemberType NoteProperty -Name Version -Value $DEMversion
$vSuiteInfo += $obj

　
$DEMworkerVersion = Invoke-Command -ComputerName [server] -ScriptBlock { Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -Match "DEM-Worker" } } | Select-Object -ExpandProperty Version
$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "[server]"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value "vRealize DEM-Worker / Management Agent"
$obj | Add-Member -MemberType NoteProperty -Name Version -Value $DEMworkerVersion
$vSuiteInfo += $obj

#endregion 

　
　
#region  vRealize Orchestrator appliances 
# [server] is ontwikkel, is productie

#vRO productie
<#
[System.Uri]$uri = 'https://[server]:8281/vco/api/about'
if ($content){ Remove-Variable content }
$content = Invoke-WebRequest $uri.AbsoluteUri

if ($content.StatusCode -eq 200) {
    $vROprod_version = $content.Content | ConvertFrom-Json 
}
#>
$[server] = Get-VM -Name [server] -Server [server]

$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "[server]"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value "vRealize Orchestrator Appliance (productie)"
$obj | Add-Member -MemberType NoteProperty -Name Version -Value ($[server].ExtensionData.Summary.Config.Product.FullVersion -split " Build ")[0]
$obj | Add-Member -MemberType NoteProperty -Name Build -Value ($[server].ExtensionData.Summary.Config.Product.FullVersion -split " Build ")[1]
$vSuiteInfo += $obj

　
　
#vRO ontwikkel 
<#[System.Uri]$uri = 'https://[server]:8281/vco/api/about'
if ($content){ Remove-Variable content }
$content = Invoke-WebRequest $uri.AbsoluteUri

if ($content.StatusCode -eq 200) {
    $vROontwikkel_version = $content.Content | ConvertFrom-Json 
}
#>

$[server] = Get-VM -Name [server] -Server [server]

$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "[server]"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value "vRealize Orchestrator Appliance (ontwikkel)"
$obj | Add-Member -MemberType NoteProperty -Name Version -Value ($[server].ExtensionData.Summary.Config.Product.FullVersion -split " Build ")[0]
$obj | Add-Member -MemberType NoteProperty -Name Build -Value ($[server].ExtensionData.Summary.Config.Product.FullVersion -split " Build ")[1]
$vSuiteInfo += $obj

#endregion

　
　
#region iuvra306 vRealize Business for Cloud
$[server] = Get-VM -Name [server] -Server [server]
$vRA_BfC_Version = $[server].ExtensionData.Summary.Config.Product.FullVersion

$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "[server]"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value $[server].ExtensionData.Summary.Config.Product.Name
$obj | Add-Member -MemberType NoteProperty -Name Version -Value ($vRA_BfC_Version -split " Build ")[0]
$obj | Add-Member -MemberType NoteProperty -Name Build -Value ($vRA_BfC_Version -split " Build ")[1]
$vSuiteInfo += $obj

#endregion

　
　
#region iuman400 & iuman 401 vRealize Operations Manager version info

foreach ($IUMAN in "",""){

$VM_IUMAN = Get-VM -Name $IUMAN -Server [server]
if ($Version){ Remove-Variable Version }
$Version = $VM_IUMAN.ExtensionData.Summary.Config.Product.FullVersion

$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "$IUMAN.iu.local"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value "vRealize Operations Manager Appliance"
$obj | Add-Member -MemberType NoteProperty -Name Version -Value ($Version -split " Build ")[0]
$obj | Add-Member -MemberType NoteProperty -Name Build -Value ($Version -split " Build ")[1]
$vSuiteInfo += $obj

}

#endregion

　
　
#region iuman404 log insight version info

[System.Uri]$uri = 'https://[server]:9543/api/v1/version'
 if ($content){ Remove-Variable content }
 $content = Invoke-WebRequest $uri.AbsoluteUri

if ($content.StatusCode -eq 200) {
    $LogInsight_Version = $content.Content | ConvertFrom-Json 
}

$obj = New-Object -TypeName PSObject
$obj | Add-Member -MemberType NoteProperty -Name Server -Value "IUMAN404.iu.local"
$obj | Add-Member -MemberType NoteProperty -Name Function -Value "vRealize Log Insight Appliance"
$obj | Add-Member -MemberType NoteProperty -Name Version -Value ($LogInsight_Version.version -split "-")[0]
$obj | Add-Member -MemberType NoteProperty -Name Build -Value ($LogInsight_Version.version -split "-")[1]
$vSuiteInfo += $obj
#endregion

　
　
#endregion

　
 
 
$outputfile = ''

if (Test-Path $outputfile){
    Move-Item -Path $outputfile -Destination ($outputfile -replace ".xlsx","-old.xlsx") -Force
}

　
$vCenterArray | sort -Property vCenter | Export-Excel -Path $outputfile -BoldTopRow -AutoSize -WorkSheetname "vCenters & vRealize" -NoNumberConversion *
$VMHostArray | Sort-Object -Property vCenter,Cluster,VersionName  | Export-Excel -Path $outputfile -BoldTopRow -AutoSize -WorkSheetname "ESXi Hosts" -NoNumberConversion * -AutoFilter
$vSuiteInfo | Export-Excel -Path $outputfile -WorkSheetname "vCenters & vRealize" -StartRow 15 -NoNumberConversion Version,Build -AutoSize


　
$excelpackage = Open-ExcelPackage -path $outputfile
$excelsheet = $excelpackage.Workbook.Worksheets["vCenters & vRealize"]
$excelsheet.Row(15) | Set-Format -Bold
$excelpackage | Close-ExcelPackage

 


