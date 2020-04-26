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

# location of the logon log
$logroot = "C:\Logroot"

#   creation of logfile
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
$logonscript = Get-Content .\logonscript.ps1

# Network Location of logroot
$netlogroot = "$env:COMPUTERNAME\Logroot"

# Replace the intended string with the network logroot
$newscript = $logonscript -replace "REPLACEME", $netlogroot
$newscript | Set-Content .\logonscript.ps1