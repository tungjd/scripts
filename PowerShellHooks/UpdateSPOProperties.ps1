# UpdateSPOProperties.ps1 - Hyperfish Inc.
#
# This example snippet should be appended to PostUpdateScript.ps1, which is 
# optionally called by the Hyperfish windows service when a user update is made.
# Once added, it updates certain SharePoint Online user profile properties when 
# specified Active Directory attributes are updated.   
#
# Setup & Config:
#    1. Make sure C:\Users\<hyperfishsvc>\AppData\Local\Hyperfish\PostUpdateScript.ps1 exists and is configured
#    2  Run O365SaveCreds.ps1 in C:\Users\<hyperfishsvc>\AppData\Local\Hyperfish\ as <hyperfishsvc> to create a stored credential file for the SPO administrator account
#    3. Install SharePoint Online Client Components SDK - https://www.microsoft.com/en-us/download/details.aspx?id=42038
#    4. Append this snippet to PostUpdateScript.ps1
#    5. Change $site to the your organization's SPO "admin" site, e.g., 'https://contoso-admin.sharepoint.com'  
#    6. Make sure $account resembles your SPO account name format, e.g., "i:0#.f|membership|$($upn)"   

# SPO Properties to update.
# To add a property mapping: 
#    1. Choose an unused or extended AD attribute in AD and add it as a custom attribute in Hyperfish, e.g., the "comment" attribute in on-prem AD 
#    2. Add the AD property name and the corresponding SPO property name to this table

$propHashTable = @{<#e.g., "comment" = "AboutMe";"adminDescription" = "SPS-Skills";"pager" = "SPS-School";"admindisplayname" = "SPS-PastProjects"#>} 

#Multi-valued SPO properties array - update this list if additional multi-valued properties are added to SPO user profiles
$multiValued = "SPS-Skills","SPS-Interests","SPS-PastProjects","SPS-Responsibility","SPS-School" 

If($propHashTable.ContainsKey($property))
{
    Write-Host "Updating value for " $property
    Import-Module 'C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.UserProfiles.dll'
    Import-Module 'C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll'
    #get stored creds path, import, set for session
    $credsPath = GCI -File ".\O365Credential.xml"
    $MSOLCred = Import-Clixml -Path $credsPath
    $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($MSOLCred.UserName, $MSOLCred.Password)

    #This needs to be the SPO "admin" site:
    $site = 'https://hyperfishdemo-admin.sharepoint.com' 

    $context = New-Object Microsoft.SharePoint.Client.ClientContext($site)#Get the Client Context and Bind the Site Collection
    $context.Credentials = $credentials
    $people = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($context) #Create an Object [People Manager] to retrieve profile information
    
    $web = $context.Web
    $SPOusers = $web.SiteUsers
    $context.Load($web)
    $context.Load($SPOusers)
    $context.ExecuteQuery() 

    # change $accountName to 
    $accountName = "i:0#.f|membership|$($upn)"
    Write-Host "Updating: $($accountName)"

    $userprofile = $people.GetPropertiesFor($accountName)

    $context.Load($userprofile)           
    $context.ExecuteQuery()

    Write-Host "Got: $($userprofile.AccountName)"

    $propValue = Get-ADUser -Filter {UserPrincipalName -eq $upn} -Properties $property | select -ExpandProperty $property

    If($multiValued.Contains($propHashTable.Get_Item($property))) #executes as array
    {
        $propArray = $propValue -split ","
        $people.SetMultiValuedProfileProperty($accountName, $propHashTable.Get_Item($property), $propArray)
        $context.ExecuteQuery()
    }
    Else #executes as string
    {
        $people.SetSingleValueProfileProperty($userprofile.AccountName, $propHashTable.Get_Item($property), $propValue)
        $context.ExecuteQuery()
    }

    Write-Host "Successfully wrote ad:" $property "to spo:" $propHashTable.Get_Item($property)

}