<#
    .SYNOPSIS
        Creation of a logon tracking system native to Windows & searcable in Active Directory
    .DESCRIPTION
        This script will do the following things:
            - Update a central log with Time, User, Computer for logon events
            - create custom attributes on ADUsers and ADComputers
            - populate those attributes in the following manner:
                - ADUser attributes will contain the last logged on computer
                - ADComputer attributes will contain the last logged on user
            - to populate those attrubutes a GPO will be created and provisioned ready to be linked wherever
                - the GPO will contain:
                    - a logon script to update the values
                    - the permissions for the computer to update the values
    .OUTPUTS
        None
    .NOTES
        Version:        1.0
        Author:         CielGoldenflame
        Creation Date:  2020 04 25
        Purpose/Change: Test Script
        PSVersion:      5.1
        OS Versions:    Windows Server 2016 & Win 10 Enterprise
    .EXAMPLE
        run with .\setup.ps1 or double click to start.
        to be run on domain controller
#>

# Specification of the working directory
$scriptdir = Split-Path $Script:MyInvocation.MyCommand.Path

# location of the logon log
$logroot = "C:\Logroot"

#  creation of logon log
New-Item -Path "$logroot\Logonlog.txt" -ItemType File -Force

# Allow Domain users to edit file
$path = "$logroot\Logonlog.txt"
$user = "$env:USERDOMAIN\Domain Users"
$Rights = "Read, Write"
$RuleType = "Allow"

$acl = Get-Acl $path
$perm = $user, $Rights, $RuleType
$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
$acl.SetAccessRule($rule)
$acl | Set-Acl -Path $path

#share file location give computer rights to edit it.
New-SmbShare -Name Logroot -Path $logroot -FullAccess "$env:USERDOMAIN\Domain Users"

# Conatinment of logonscript content
$logonscript = Get-Content $scriptdir\logonscript.ps1

# Network Location of logroot
$netlogroot = "$env:COMPUTERNAME\Logroot"

# Replace the intended string with the network logroot
$newscript = $logonscript -replace "REPLACEME", $netlogroot
$newscript | Set-Content .\logonscript.ps1

# Creation of the GPO that implements the logon script
New-GPO -Name Who-Done-It

$gpo = Get-GPO -Name Who-Done-It
# Getting the guid for later
$gpoid = $gpo.id.Guid
# GPO path 
# $gpopath = $gpo.Path

# Sysvol location for gpo we created
$netfilepath = "\\$env:USERDNSDOMAIN\SYSVOL\$env:USERDNSDOMAIN\Policies\{$gpoid}\User\Scripts\Logon"

# creation of path above
New-Item -Path $netfilepath -ItemType Directory -Force

# copy our logonscript to here
Copy-Item -Path $scriptdir\logonscript.ps1 -Destination $netfilepath

<#
$domain = Get-ADDomain
$dn = $domain.DistinguishedName

$key = "HKCU\SOFTWARE\MICROSOFT\Windows\CurrentVersion\Group Policy\Scripts\Logon"

$csv = Get-Content $scriptdir\0.csv
$0values = $csv -replace 'netfilepath', $netfilepath -replace 'gpopath', "$gpopath" -replace 'gpoid', $gpoid -replace 'dn', $dn
$0values | Set-Content $scriptdir\0.csv

Import-Csv $scriptdir\0.csv -Delimiter ";" | ForEach-Object { 
$type = $_.Type
$name = $_.Name
$value = $_.Value

Set-GPRegistryValue -Guid $gpoid -Key "$key\0" -Type $type -ValueName $name -Value $value
}

$csv = Get-Content $scriptdir\0-0.csv
$00values = $csv -replace 'logscript', $logscript
$00values | Set-Content $scriptdir\0-0.csv

Import-Csv $scriptdir\0-0.csv -Delimiter ";" | ForEach-Object {
$type = $_.Type
$name = $_.Name
$value = $_.Value
Set-GPRegistryValue -Guid $gpoid -Key "$key\0\0" -Type $type -ValueName $name -Value $value
}
#>

Clear-host
Write-host "Please Edit the Who-Done-It GPO to contain the logonscript.ps1

Open Group Policy Management & Navigate to Group Policy Objects
Right Click Who-Done-It GPO, Select edit.
Then browse to User Configuration\Policies\Windows Settings\Scripts\
Double-Click Logon, Select the PowerShell Scripts Tab
Click Add, then Browse. Select logonscript.ps1
Click Okay Twice, and exit out of the editor" -ForegroundColor Yellow
Start-Process gpmc.msc
Pause