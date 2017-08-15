
 
workflow Get-Admininfo 
{    
    Param
    (
        # Serverlist to query for local administrator
        [Parameter(Mandatory = $true)][string[]]$Servers,

        # If there are offline servers, or servers that can't be reached, this is the path to the txt file that contains those.
        [Parameter(Mandatory = $true)][string]$OfflineServers
    )

    $OfflineServersArray = @()

    foreach -parallel ($server in $Servers)
    {
        try
        {
            Get-WmiObject -Class Win32_UserAccount -Filter  "LocalAccount='True' AND SID LIKE 'S-1-5-21-%-500'" -PSComputerName $server -ErrorAction Stop | Select-Object Name,Domain
        }
        catch
        {
            try
            {
                Get-CimInstance Win32_UserAccount -PSComputerName $server -Filter "LocalAccount='True' AND SID LIKE 'S-1-5-21-%-500'" -ErrorAction Stop | Select-Object Name,Domain
            }
            catch
            {
                $workflow:OfflineServersArray += $server 
            }            
        }        
    }
    
    
    $OfflineServersArray | Out-File -FilePath $OfflineServers 
}

 

