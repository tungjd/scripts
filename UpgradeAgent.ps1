function silentupgrade
 {#SA,Paths,Define 
    $svcaccount = Get-WMIObject Win32_Service | Where-object {$_.name -eq "HyperfishAgent"} | select -ExpandProperty StartName
    $separator = "@"
    $parts = $svcaccount.split($separator)
    $appdatapath = "C:\Users\" + $parts[0] + "\Appdata\Local\Hyperfish"
    $serviceproperties = Get-WmiObject Win32_Service | where-object {$_.name -eq "HyperfishAgent"} | select StartName,StartMode,State,Status
    $svc = Get-Service HyperfishAgent

    #Create Download Folder If Not Existing
    $dlpath = $appdatapath + "\Installer"
    $dlpathwc = $dlpath + "\*"
    If(!(test-path $dlpath))
        {
        New-Item -ItemType Directory -Force -Path $dlpath        
        }

    #Download latest agent .msi from http://files.hyperfish.com/files/HyperfishAgent.msi
    Start-Sleep -s 2
    $agentdlurl = "http://files.hyperfish.com/files/HyperfishAgent.msi"
    $output = "$dlpath\HyperfishAgent.msi"
    $start_time = Get-Date
    Write-Verbose -verbose "Downloading latest Hyperfish Agent installer"
    (New-Object System.Net.WebClient).DownloadFile($agentdlurl, $output)
    Write-Verbose -verbose "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)" 
    #Check if download is complete?
        If(!(test-path $output))
        {
        Start-sleep -s 5     
        }
    #Stop Hyperfish Service
    Write-Verbose -verbose "Stopping Hyperfish Agent Service"
    Stop-Service -name "HyperfishAgent" -force
    $svc.WaitForStatus('Stopped','00:05:00')
    #Install .msi silently
    Start-Process $output /qn -Wait
    Write-Verbose -verbose "Hyperfish Agent Upgrade Complete"
    #Start Hyperfish Service
    Write-Verbose -verbose "Starting Hyperfish Agent Service"
    Start-Service -name "HyperfishAgent"
    $svc.WaitForStatus('Running','00:05:00')
    #Delete .msi
    Write-Verbose -verbose "Cleaning up..."
    Remove-Item $dlpath -Recurse
    Write-Verbose -verbose "Upgrade complete. Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    Echo $serviceproperties
    Start-Sleep -s 10
  }

silentupgrade
