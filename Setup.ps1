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
$loglocation = "C:\Logonlog"

#   creation of logfile
New-Item -Path $loglocation\Logonlog.txt -ItemType File -Force

New-SmbShare -Name Logroot -Path $loglocation -FullAccess $en \Domain Computers