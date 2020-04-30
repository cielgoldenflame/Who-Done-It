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

# Getting the guid for easy idenification
$gpo = Get-GPO -Name Who-Done-It
$gpoid = $gpo.id.Guid

# get the Domain Name in distinguised name context
$domain = Get-ADDomain
$distname = $domain.DistinguishedName

# Import the settings from a pre-configured GPO to our new one
Import-GPO -BackupId "{93D3A585-770F-4C42-8ECE-2E2688FD1140}" -TargetGuid $gpoid -Path "$scriptdir"

# Link our GPO to the domain to affect all users
New-GPLink -Guid $gpoid -Target $distname -LinkEnabled Yes

# Begin Process of creating Attributes

# Function creates a new identification number for the attributes
Function New-OID {
    $Prefix="1.2.840.113556.1.8000.2554" 
    $GUID=[System.Guid]::NewGuid().ToString() 
    $Parts=@() 
    $Parts+=[UInt64]::Parse($guid.SubString(0,4),"AllowHexSpecifier") 
    $Parts+=[UInt64]::Parse($guid.SubString(4,4),"AllowHexSpecifier") 
    $Parts+=[UInt64]::Parse($guid.SubString(9,4),"AllowHexSpecifier") 
    $Parts+=[UInt64]::Parse($guid.SubString(14,4),"AllowHexSpecifier") 
    $Parts+=[UInt64]::Parse($guid.SubString(19,4),"AllowHexSpecifier") 
    $Parts+=[UInt64]::Parse($guid.SubString(24,6),"AllowHexSpecifier") 
    $Parts+=[UInt64]::Parse($guid.SubString(30,6),"AllowHexSpecifier") 
    $oid=[String]::Format("{0}.{1}.{2}.{3}.{4}.{5}.{6}.{7}",$prefix,$Parts[0],$Parts[1],$Parts[2],$Parts[3],$Parts[4],$Parts[5],$Parts[6]) 
    $oid 
}

Import-Csv "$scriptdir\Attributes.csv"
$class

$Name

# What we want our Attribute name to be
$attributeName

# Where object is stored
$schemaPath = (Get-ADRootDSE).schemaNamingContext 

# Type of Schema object
$attributetype = 'attributeSchema'

# Unique ID for the Attribute
$AttributeID = (New-OID)

# 
$attributes = @{
    lDAPDisplayName = $attributeName;
    attributeId = $AttributeID;
    oMSyntax = 20;
    attributeSyntax = "2.5.5.4";
    isSingleValued = $true;
    adminDescription = $AdminDescription;
    searchflags = 1
}
  
New-ADObject -Name $attributeName -Type $attributetype -Path $schemapath -OtherAttributes $attributes 
$userSchema = get-adobject -SearchBase $schemapath -Filter "name -eq $class"
$userSchema | Set-ADObject -Add @{mayContain = $Name}