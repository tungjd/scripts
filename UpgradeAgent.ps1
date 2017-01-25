function silentupgrade
 {#SA,Paths,Define 
    $svcaccount = Get-WMIObject Win32_Service | Where-object {$_.name -eq "HyperfishAgent"} | select -ExpandProperty StartName
    $separator = "@"
    $parts = $svcaccount.split($separator)
    $appdatapath = "C:\Users\" + $parts[0] + "\Appdata\Local\Hyperfish"
    $svc = Get-Service HyperfishAgent
    #Create Download Folder If Not Exist
    $dlpath = $appdatapath + "\Installer"
    If(!(test-path $dlpath))
        {
        New-Item -ItemType Directory -Force -Path $dlpath        
        }
    #Download latest agent .msi from https://hyperfish.blob.core.windows.net/files/HyperfishAgent.msi
    Start-Sleep -s 2
    $agentdlurl = "https://hyperfish.blob.core.windows.net/files/HyperfishAgent.msi"
    $output = "$dlpath\HyperfishAgent.msi"
    $start_time = Get-Date
    echo "Downloading latest Hyperfish Agent installer"
    (New-Object System.Net.WebClient).DownloadFile($agentdlurl, $output)
    #Check if download is complete?
        If(!(test-path $output))
        {
        Start-sleep -s 5     
        }
    echo "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)" 
    #Stop Hyperfish Service
    echo "Stopping Hyperfish Agent Service"
    Stop-Service -name "HyperfishAgent" -force
    $svc.WaitForStatus('Stopped','00:05:00')
    #Install .msi silently
    Start-Process $output /qn -Wait
    echo "Hyperfish Agent Upgrade Complete"
    #Start Hyperfish Service
    echo "Starting Hyperfish Agent Service"
    Start-Service -name "HyperfishAgent"
    $svc.WaitForStatus('Running','00:05:00')
    #Delete .msi
    echo "Cleaning up..."
    Remove-Item $dlpath -Recurse
    echo "Upgrade complete. Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    $hyperfishapp = Get-WmiObject -Class Win32_Product | Where-Object {$_.name -match "Hyperfish"} | select Version
    $serviceproperties = Get-WmiObject Win32_Service | where-object {$_.name -eq "HyperfishAgent"} | select StartName,StartMode,State,Status
    $agentinfo = "`r`nInstalled agent: `r`n" + $hyperfishapp + " `r`n`r`nService Info: `r`n" + $serviceproperties
    echo $agentinfo 
    Start-Sleep -s 10
  }

silentupgrade
