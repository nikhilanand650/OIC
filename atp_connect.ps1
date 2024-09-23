# Load the ODP.NET assembly
Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.Core

Add-Type -Path "C:\Users\Nikhil Anand\Downloads\ODAC-19.19-Xcopy-64-bit\odpm\odp.net\managed\common\Oracle.ManagedDataAccess.dll"


# Create an OracleConnection object
$pwdText = Get-Content -Path "C:\Users\Nikhil Anand\Downloads\Pwd.txt" -Raw
$connectionstring = 'User Id=' + 'ADMIN' + ';Connection Timeout=120 ;Password=' + $pwdText + ';Data Source=' + 'hw5d33zgfxqer3ua_low'
$connection = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($connectionstring)
$connection.TnsAdmin = "C:\Users\Nikhil Anand\Downloads\Wallet_HW5D33ZGFXQER3UA"
$connection.WalletLocation = "C:\Users\Nikhil Anand\Downloads\Wallet_HW5D33ZGFXQER3UA"
$sysDate = Get-Date


# Open the connection
$connection.Open()


$ddlScriptPath = "C:\Users\Nikhil Anand\Downloads\DropConstraitn.sql"
#$ddlScriptPath = "C:\Users\Nikhil Anand\Downloads\SCRIPTS\0_8_PACKAGE\oic_batch_processing_pkg.script"
#$ddlScriptPath = "C:\Users\Nikhil Anand\Downloads\SCRIPTS\0_7_FUNCTION.func"
$filePath = "C:\Users\Nikhil Anand\Downloads\File_ATPRunHistory.txt"

$SQLpattern = "(?i)sql$"
$scriptPattern = "(?i)script$"
$scriptDelimitter = "--End Of Command for Deployment Purpose --"
$alterSession = "*alter session SET CURRENT_SCHEMA*"
$enableTrigger = "*alter trigger*"

$ddlScript = Get-Content -Path $ddlScriptPath -Raw

 
if ($ddlScriptPath -match $SQLpattern) {
	$ddlScript = $ddlScript -creplace '(?m)^\s*/+\s*$'
    $queries = $ddlScript -split ';'
    $command = $connection.CreateCommand()

    foreach ($query in $queries) {
        $trimmedQuery = $query.Trim()
        
        try{if ($trimmedQuery -ne "") {
            $command.CommandText = $trimmedQuery
            $reader = $command.ExecuteNonQuery()
			write-host -ForegroundColor Green " $reader"
			if ($reader -ge (-1) -and $reader -ne $null -and $reader -ne "") {
               write-host -ForegroundColor Green "Successfully completed execution for trimmed query Reader $reader"
			   
             }
            else {
             write-host -ForegroundColor Red "execution for trimmed query in $trimmedQuery failed"
			 write-host -ForegroundColor Red "Error Message $_.ErrorDetails.Message"
             }
        }
		}
		catch{
			write-Error "catch Error Message $_ Test"
		}
    }
}
elseif ($ddlScriptPath -match $scriptPattern) {
	$ddlScript = $ddlScript -creplace '(?m)^\s*/+\s*$'
    $queries = $ddlScript -split $scriptDelimitter
    $command = $connection.CreateCommand()

    foreach ($query in $queries) {
        $trimmedQuery = $query.Trim()
		if ($trimmedQuery -ilike $alterSession -or $trimmedQuery -ilike $enableTrigger) {
			$trimmedQuery = $trimmedQuery -replace ";$", ""
		}
        
        if ($trimmedQuery -ne "") {
            $command.CommandText = $trimmedQuery
            $reader = $command.ExecuteNonQuery()
			if ($reader -ge -1) {
               write-host -ForegroundColor Green "Successfully completed execution for trimmed query $trimmedQuery"
             }
            else {
             write-host -ForegroundColor Red "execution for trimmed query in $trimmedQuery failed"
             }
        }
    }
}
else {
    $command = $connection.CreateCommand()
    $command.CommandText = $ddlScript
    $reader = $command.ExecuteNonQuery()
			if ($reader.Equals(-1)) {
               write-host -ForegroundColor Green "Successfully completed execution for trimmed query $ddlScript"
             }
            else {
             write-host -ForegroundColor Red "execution for trimmed query in $ddlScript failed"
             }
}

# Close the connection and clean up

$connection.Close()
 write-host -ForegroundColor Green "Connection closed"

$records = @"
$sysDate - $ddlScriptPath
"@

Add-Content -Path $filePath -Value $records -Encoding UTF8
