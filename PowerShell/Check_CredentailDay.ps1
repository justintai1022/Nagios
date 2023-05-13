<#
.SYNOPSIS 
 This script will monitor the validity period of internal certificates.

.NOTES
     Author     : Justin Tai
     CreateDate : 2023/03/24
     LastModify : 2023/03/27
     Version    : V1.0.0

.PARAMETER Cre,c
    Credentials name

.PARAMETER Warning , w 
	Warning Threshold

.PARAMETER Location , l 
	Credentials Location

.EXAMPLE
   要跟對方要到憑證指紋(Thumbprint)
   .\Check_CredentailDay.ps1  -cre "6EF5E6967E0052A5ED705DB079FA2EFC469F5DB" -warning 80
   .\Check_CredentailDay.ps1  -c "6EF5E6967E0052A5ED705DB079FA2EFC469F5DB" -w 80
   .\Check_CredentailDay.ps1  -cre "6EF5E6967E0052A5ED705DB079FA2EFC469F5DB" -warning 80 -location CA
   .\Check_CredentailDay.ps1  -c "6EF5E6967E0052A5ED705DB079FA2EFC469F5DB" -w 80 -l CA
#>

Param(
   [String] $cre,
   [String] $c,
   [String] $warning,
   [String] $w,
   [String] $location,
   [String] $l
)

IF ([string]::IsNullOrEmpty($cre) -eq $true){
    $cre = $c
}

IF ([String]::IsNullOrEmpty($warning) -eq $true){
    [int]$warning = [int]$w
}

IF ([string]::IsNullOrEmpty($location) -eq $true){
    IF([string]::IsNullOrEmpty($l) -eq $true){
        $location= "Root"
    }
    else {
        $location = $l
    }
}

$ExpireInDays= ""
$connect_test = Get-ChildItem -Path Cert:\LocalMachine\$location -recurse -ExpiringInDays 3650  | Select-Object -Property Subject,Thumbprint, @{n='ExpireInDays';e={($_.notafter-(Get-Date)).Days}}  | select-string  $cre
$CreTemp1 = Get-ChildItem -Path Cert:\LocalMachine\$location -recurse -ExpiringInDays $warning  | Select-Object -Property Subject,Thumbprint, @{n='ExpireInDays';e={($_.notafter-(Get-Date)).Days}}  | select-string  $cre

#確認憑證是否存在
IF ([String]::IsNullOrEmpty($connect_test) -eq $true){
    Write-Host "Couldn't found credentials"
    EXIT 3
}

#判斷憑證到期了沒？
IF ([String]::IsNullOrEmpty($CreTemp1) -eq $true){ 
    Write-Host "Credentials days is ok"
    EXIT 0
}
else 
{
    [String]$CreTemp1Reluse = $CreTemp1
    $CreTemp1Reluse = $CreTemp1Reluse.split(" ")| Where-Object{$_ -match "ExpireInDays"}
    $len = $CreTemp1Reluse.Length #取字串的最後一個字元的前置作業
    $len = $len - 1 #取字串的最後一個字元前置作業
    $CreTemp1Reluse = $CreTemp1Reluse.Remove($len,1) #取字串的最後一個字元並把它移除
    [int]$ExpireInDays = $CreTemp1Reluse.remove(0,13).insert(0,"")#取憑證天數
    Write-Host "WARNING: Credentials expire $ExpireInDays days"
    EXIT 1
}