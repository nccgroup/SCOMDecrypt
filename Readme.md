# SCOMDecrypt - SCOM Credential Decryption Tool#

Released as open source by NCC Group Plc - http://www.nccgroup.trust/

Developed by Richard Warren, richard [dot] warren [at] nccgroup [dot] trust

http://www.github.com/nccgroup/SCOMDecrypt

Released under AGPL, see LICENSE for more information

## Introduction ##

This tool is designed to retrieve and decrypt RunAs credentials stored within Microsoft System Center Operations Manager (SCOM) databases.

For background, please see the NCC Group blog post [here](https://medium.com/keylogged)

## Pre-requisites ##

To run the tool you will require administrative privileges on the SCOM server. You will also need to ensure that you have read access to the following registry key:

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\System Center\2010\Common\MOMBins

You can check manually that you can see the database by gathering the connection details from the following keys:

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\System Center\2010\Common\Database\DatabaseServerName
    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\System Center\2010\Common\Database\DatabaseName

## Usage ##

The tool comes in two formats.The first is a C# binary which can simply be run on the SCOM server with no arguments as following:

    .\SCOMDecrypt.exe
    [+] <SCXUser><UserId>bob</UserId><Elev>sudo</Elev></SCXUser>:H a c k T h e P l a n e t
    [+] administrator:W i n t e r 2 0 1 5 !
    [+] alice:P a s s w 0 r d 1 2 3 !

There is also a PowerShell version of the tool too. This is useful in a post-exploitation scenario for use with tools such as Cobalt Strike or Empire. To use the tool with Cobalt Strike:

    powershell-import C:\path\to\SCOMDecrypt.ps1
    powershell Invoke-SCOMDecrypt
    [+] <SCXUser><UserId>bob</UserId><Elev>sudo</Elev></SCXUser>:H a c k T h e P l a n e t
    [+] administrator:W i n t e r 2 0 1 5 !
    [+] alice:P a s s w 0 r d 1 2 3 !

To run within the PowerShell console:

    powershell.exe -exec bypass
    . .\Invoke-SCOMDecrypt.ps1
    Invoke-SCOMDecrypt
    ...