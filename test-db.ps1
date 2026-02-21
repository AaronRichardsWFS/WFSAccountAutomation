# Script that test the functionality of the database

# Load .env file
$envFile = ".env"
Get-Content $envFile | ForEach-Object {
  if ($_ -match "^(.*?)=(.*)$") {
    Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
  }
}

$server = $Env:DB_SERVER
$database = $Env:DB_NAME
$username = $Env:DB_USER
$password = $Env:DB_PASSWORD

Write-Host "Inserting a single row into the Users table..." -ForegroundColor Green
$sql = @"
INSERT INTO Users (
  FirstName,
  LastName,
  Type,
  Status,
  UniqueID,
  VPN
) VALUES (
  'Mickey',
  'Mouse',
  'Staff',
  'completed',
  'b2f9893b-9f7a-4468-b361-f98d67a1ac25',
  1
);
"@
sqlcmd -S $server -d $database -U $username -P $password -Q $sql

Write-Host "Querying all users in the Users table..." -ForegroundColor Green
$query = "SELECT * FROM Users;"
sqlcmd -S $server -d $database -U $username -P $password -s "|" -W -Q "$query"

Write-Host "Deleting all users from the Users table..." -ForegroundColor Green
$query = "DELETE FROM Users;"
sqlcmd -S $server -d $database -U $username -P $password -s "|" -W -Q "$query"

Write-Host "Querying all users in the Users table..." -ForegroundColor Green
$query = "SELECT * FROM Users;"
sqlcmd -S $server -d $database -U $username -P $password -s "|" -W -Q "$query"