<#
    .SYNOPSIS
        Creation of a logon tracking system native to Windows & searcable in Active Directory
    .DESCRIPTION
        This logon script will do the following things:
            - Update a central log with Time, User, Computer for logon events
            - Populate custom attributes in the following manner:
                - ADUser attributes will contain the last logged on computer
                - ADComputer attributes will contain the last logged on user

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
        implemented automatically with setup.ps1
#>

# Variable to input time
$date = Get-Date

$user = "$env:USERDOMAIN\$env:USERNAME"

# Command adds info to text
Add-Content .\logonlog.txt -Value "Time:        $date
User:       $user
Computer:   $env:COMPUTERNAME
"