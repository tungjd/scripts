# O365SaveCreds.ps1 - Hyperfish Inc.
# Place this in C:\Users\<hyperfishsvc>\AppData\Local\Hyperfish\
# Running this script will create a stored credential file, "O365Credential.xml"
# Only the account that creates the stored credential file can use the stored credentials,
# so make sure to run it as the Hyperfish service account.

$MSOLCred = Get-Credential -Credential admin@contoso.onmicrosoft.com

Export-Clixml -Path O365Credential.xml -InputObject $MSOLCred