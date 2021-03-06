function Close-Port
{
    <#
    .Synopsis
        Opens ports on the Windows Firewall
    .Description
        Opens ports on the Windows Firewall on the local machine
    .Example
        Close-Port 500
    .Link
        Open-Port
    #>
    [OutputType([Nullable])]
    param(
    # The port numbers to close
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Uint32[]]$Port,
    # The protocol to close.  The Default is TCP.
    [string[]]$Protocol = 'TCP'
    )
    
    process {
        #region Initialize Profile
        $firewall = New-Object -ComObject HNetCfg.FwMgr
        $firewallProfile = $firewall.localpolicy.currentprofile
        #endregion Initialize Profile
        
        #region Close Each Port
        foreach ($p in $port) {
            $toClose = $firewallProfile.GloballyOpenPorts | 
                Where-Object  { $_.Port -eq $p }
             if ($protocol -eq 'TCP') {
                $firewallProfile.GloballyOpenPorts.Remove($toClose, 6)
            } elseif ($protocol -eq 'UDP') {
                $firewallProfile.GloballyOpenPorts.Remove($toClose, 17)
            }
            
        }
        #endregion Close Each Port
    }
}