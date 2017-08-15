
#Simple workflow to query a list of servers for the local administrator account. It is identified by using the SID, so it also works if the default name has changed.
#Using a workflow here so we can utilise the "foreach -parallel", this significantly speeds up the process to query a long list of servers.
#We use WMI to query, which uses RPC, and if that fails we try the Get-CimInstance method because this uses the WinRM method.
#If both methods fail, we put the name of the server in an array, and in the end store it in a file
 
 
workflow Get-Admininfo 
{    
    Param
    (
        # Serverlist to query for local administrator account
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

 

