param( 
	$SqlServerOne = 'YourDatabaseServer',
	$FirstDatabase = 'FirstDatabaseToCompare', 
	$SqlUsernameOne = 'SQL Login',
	$SqlPasswordOne = 'SQL Password',
	$SqlServerTwo = 'YourDatabaseServer',
	$SecondDatabase = 'SecondDatabaseToCompare', 
	$SqlUsernameTwo = 'SQL Login',
	$SqlPasswordTwo = 'SQL Password',
	$FilePrefix = 'Log',
	[switch]$Log,
	[switch]$Column
	)

$File = $FilePrefix + '{0}-{1}.csv'

$TableQuery = "	select sysobjects.name as TableName
	from sysobjects
	where sysobjects.xtype like 'U' and --specify only user tables
	sysobjects.name not like 'dtproperties' --specify only user tables"

function Run-Query()
{
	param (
	$SqlQuery,
	$SqlServer,
	$SqlCatalog, 
	$SqlUser,
	$SqlPass
	)
	
	$SqlConnString = "Server = $SqlServer; Database = $SqlCatalog; user = $SqlUser; password = $SqlPass"
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = $SqlConnString
	
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.Connection = $SqlConnection
	
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	
	$DataSet = New-Object System.Data.DataSet
	$a = $SqlAdapter.Fill($DataSet)
	
	$SqlConnection.Close()
	
	$DataSet.Tables | Select-Object -ExpandProperty Rows
}

$TablesDBOne = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName

$TablesDBTwo = Run-Query -SqlQuery $TableQuery -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName

Write-Host 'Differences in Tables: '
$Database = @{Name='Database';Expression={if ($_.SideIndicator -eq '<='){'{0} / {1}' -f $FirstDatabase, $SqlServerOne} else {'{0} / {1}' -f $SecondDatabase, $SqlServerTwo}}}
$TableDifference  = Compare-Object $TablesDBOne $TablesDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property TableName | select TableName, $Database

if ($log)
{
	$TableDifference | Export-Csv -Path ($file -f $FirstDatabase, $SecondDatabase) -NoTypeInformation
}

$TableDifference | Sort-Object -Property TableName, Database


if ($Column)
{
	
	$SameTables = Compare-Object $TablesDBOne $TablesDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property TableName -IncludeEqual -ExcludeDifferent 
	
	$ColumnQuery = @"
select sysobjects.name as TableName
	, syscolumns.name as ColumnName 
	, systypes.name as Type
	, systypes.Length
	, systypes.XUserType
from sysobjects, syscolumns, systypes
where sysobjects.xtype like 'U' and --specify only user tables
	sysobjects.name not like 'dtproperties' and --specify only user tables
	syscolumns.xusertype= systypes.xusertype --get data type info
	and sysobjects.id=syscolumns.id 
	and sysobjects.name = '{0}'
order by sysobjects.name, syscolumns.name, syscolumns.type
"@
	
	Write-Host "`n`n"
	Read-Host 'Press Enter to Check for Column Differences'
	
	foreach ($Table in $SameTables)
	{
		$ColumnsDBOne = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename)  -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property TableName, ColumnName, Type, Length, XUserType

		$ColumnsDBTwo = Run-Query -SqlQuery ($ColumnQuery -f $table.tablename) -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property TableName, ColumnName, Type, Length, XUserType
		
		$ColumnDifference = Compare-Object $ColumnsDBOne $ColumnsDBTwo -SyncWindow (($ColumnsDBOne.count + $ColumnsDBTwo.count)/2) -Property TableName, ColumnName, Type, Length, XUserType | Select-Object TableName, ColumnName, Type, Length, XUserType, $Database
		
		if ($log -and $ColumnDifference )
		{
			$ColumnDifference | Export-Csv -Path ($file -f $Table.TableName,'Columns' ) -NoTypeInformation
		}
		
		$ColumnDifference | sort ColumnName, Database
		
	}
}