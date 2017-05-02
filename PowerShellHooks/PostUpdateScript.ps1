param([string]$property = "", [string]$user = "")

# PostUpdateScript.ps1 - Hyperfish Inc.
#
# The script is optionally called by the Hyperfish windows service when 
# a user update is made. It is passed the property that was updated in AD
# and the objectGUID of the user. Note: the value of the update is not passed
# and this should be looked up from AD using Get-ADUser if needed.
#
# Setup:
#    1. Place this script in C:\Users\<hyperfishsvc>\AppData\Local\Hyperfish
#    2. Make sure the ActiveDirectory PowerShell module is installed
#    3. Give the Hyperfish Service Account permissions to run PowerShell scripts:
#          - Open a cmd window as admin, and run "runas /user:hyperfishserviceusername powershell.exe" 
#          - In the new PowerShell window, run "Set-ExecutionPolicy Unrestricted -Scope CurrentUser"
#    4. Modify C:\Users\<hyperfishsvc>\AppData\Local\Hyperfish\servicesettings.json
#       with a text editor, and change '"PostUpdateScript": null,'  
#       to include the path: "PostUpdateScript": "\"C:\\Users\\<hyperfishsvc>\\AppData\\Local\\Hyperfish\\PostUpdateScript.ps1\"",
#    5. After saving servicesettings.json, restart the Hyperfish Service
#
# Parameters:
#    1. property name, e.g., "thumbnailphoto" 
#    2. users objectGUID from active directory 

Write-Host $property
Write-Host $user

$appDataLocal = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)
Set-Location $appDataLocal"\hyperfish\"

import-module activedirectory

# By default, this script will run as the same user ther the hyperfish service is running as.
# To override account used to connect to AD uncomment the following lines

#$UserName = "administrator"
#$PlainPassword = "password"
#$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
#$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

# format the objectGUID correctly for the AD query
if ($user.length -eq 36)
{
    # We have a string in registry format and need to convert it to Hex string
    $strHex = -join (([guid]$user).tobytearray() | %{$_.tostring("X").padleft(2,"0")})
}
elseif ($strGUID.length -eq 32)
{
    # We have a string in Hex format - no need to modify
    $strHex = $user
}
else
{
    # Unrecognised string format
    Write-host "Unrecognised user guid format - remove any leading or trailing spaces and try again"
    Break
}

# modify the Hex string to allow it to be used as a filter
$strSearch = $strHex -replace '(..)','\$1'

#lookup the user cn and upn from AD
$ADUser = Get-Aduser -filter {objectGUID -eq $strSearch} -properties cn,userPrincipalName

if (!$ADuser) { 
    Write-Host "Couldn't find user with guid: $user"
    Break 
}
else
{
    Write-Host "Found user: $($ADuser.CN), $($ADuser.UserPrincipalName)"
}

# get the upn
$upn = $ADuser.UserPrincipalName

#Next, add some payload actions, e.g.:
#
#if ($property -eq "manager") {
#   #Do some stuff here when manager property is updated
#}