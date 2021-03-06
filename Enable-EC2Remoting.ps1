function Enable-EC2Remoting
{
    <#
    .Synopsis
        Enables an EC2 instance for various remote access
    .Description
        Enables common services on an EC2 instance
    .Example
        Get-EC2 |
            Enable-EC2Remoting -PowerShell    
    .Link
        Open-EC2Port
    #>
    param(
    # The EC2 Instance ID
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]$InstanceId,

    # If set, will open the port for PowerShell remote management and attempt to enable it on the box.
    [switch]$PowerShell,
    
    # If set, will open the port for PowerShell remote management with CredSSP and attempt to enable it on the box.
    [Switch]$PowerShellCredSSP,
    
    # If set, will open SSH
    [Switch]$Ssh,
    
    # If set, will open Echo (aka Ping)
    [Alias('Ping')]
    [Switch]$Echo,
    
    # If set, will open HTTP
    [Switch]$Http,
    
    # If set, will open HTTPS
    [Switch]$Https,
    
    # If set, will open RemoteDesktop
    [Switch]$RemoteDesktop
    )
    
    
    process {
        $ec2Instance = Get-EC2 -InstanceId $InstanceId 
        if ($Ssh) {
            $ec2Instance  | 
                Open-EC2Port -Range 22 -ErrorAction SilentlyContinue                
        }
        
        if ($echo) {
            $ec2Instance  | 
                Open-EC2Port -Range 7 -ErrorAction SilentlyContinue                                 
        }
        
        if ($ftp) {
            $ec2Instance  | 
                Open-EC2Port -Range 21 -ErrorAction SilentlyContinue                
        }
        
        if ($http) {
            $ec2Instance  | 
                Open-EC2Port -Range 80 -ErrorAction SilentlyContinue
        }
        
        if ($https) {
            $ec2Instance  | 
                Open-EC2Port -Range 443 -ErrorAction SilentlyContinue
        }
        
        if ($remoteDesktop -or $PowerShellCredSSP) {
            $ec2Instance  | 
                Open-EC2Port -Range 3389 -ErrorAction SilentlyContinue
        }
        
        if ($PowerShell -or $PowerShellCredSSP) {
            $ec2Instance  | 
                Open-EC2Port -Range 5985 -PassThru -ErrorAction SilentlyContinue | 
                Open-EC2Port -Range 5986 -ErrorAction SilentlyContinue 
        }
        
        if ($PowerShellCredSSP) {
            <#
            $ec2Pwd = $ec2Instance | 
                Get-EC2InstancePassword | 
                Select-Object -ExpandProperty Password |
                ConvertTo-SecureString -AsPlainText -Force
            $cred = New-Object Management.Automation.PSCredential 'Administrator', $ec2Pwd 
            
            
            # This is an incredibly useful yet dirty trick.
            
            # Remoting can be enabled, but enabling CredSSP on a target box technically requires CredSSP itself.  
            # So does nearly anything else that requires a credential.  
            # I can register a task (but only thru the command line tool), but said task actually requires someone to be logged on
            # in order to run
            # And so...
            
            
            $ec2Instance |
                Connect-EC2 
            
            
            
            Invoke-Command -ComputerName $ec2Instance.PublicDnsName -Credential $cred -ScriptBlock {
                $Soon= [DateTime]::Now.AddSeconds(45)
                $Soon= "{0:00}:{1:00}:{2:00}" -f $Soon.Hour,$Soon.Minute, $soon.Second
                $enableTaskNAme = "EnableTask$(Get-Random)"
                $r = schtasks /create /s localhost /tn $enableTaskNAme  /rl highest /st $Soon /SC Once /tr 'powershell.exe -command Enable-WSManCredSSP -Role Server -Force'
                $Soon= [DateTime]::Now.AddSeconds(45)
                $Soon= "{0:00}:{1:00}:{2:00}" -f $Soon.Hour,$Soon.Minute, $soon.Second
                $enableTaskNAme = "EnableTask$(Get-Random)"
                $r = schtasks /create /s localhost /tn $enableTaskNAme  /rl highest /st $Soon /SC Once /tr 'powershell.exe -command Enable-WSManCredSSP -Role Client -DelegateComputer * -Force'
            }
            
            Start-Sleep -Seconds 60
            
            $connectedWithCredSSP =
                Invoke-Command -ComputerName $ec2Instance.PublicDnsName -Credential $cred -ScriptBlock { "Connected with CredSSP" } -Authentication CredSSP                            
                
            New-Object PSObject |
                Add-Member NoteProperty ComputerName $ec2Instance.PublicDnsName -PassThru |
                Add-Member NoteProperty IsConnected ($connectedWithCredSSP -as [bool]) -PassThru
            #>
        }
        
    }
}


