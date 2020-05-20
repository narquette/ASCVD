#stop on error
$ErrorActionPreference = "Stop"

#add variables needed for object to be installed
$scriptpath = Split-Path $MyInvocation.MyCommand.Path
$sqlfiles = Get-ChildItem -Path "$scriptpath\SSMSCode\" -Filter '*.sql'
$rfiles = Get-ChildItem -Path "$scriptpath\RCode\" -Filter '*.r'

#add sql server info 
#could convert Read-Host for input from command line
$ServerName = "CPMSUNRSQL18\CPMSRINST18"
$DbName = "CPMDemo_AcuteCare"

#check for d directory 
$d = Test-Path -Path "D:"

#r directory to store functions
if($d) { $rdirectory = "D:\R\Functions" 
} else { $rdirectory = "C:\R\Functions" 
}

#add variables for existence of r
$RExistsQry =  "
EXECUTE sp_execute_external_script @language = N'R'
, @script = N'
OutputDataSet <- data.frame(installed.packages()[,c(`"Package`", `"Version`", `"Depends`", `"License`", `"LibPath`")]);'
WITH result sets((Package NVARCHAR(255), Version NVARCHAR(100), Depends NVARCHAR(4000)
    , License NVARCHAR(1000), LibPath NVARCHAR(2000)));"

#check to see if r exists
$RExists = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -Query $RExistsQry

#load required objects
If($RExists) { 

    $sqlfiles | ForEach-Object {
    
        $sqlfile = $PSItem.FullName
        Write-Host "Installing $sqlfile" 
        Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -InputFile $sqlfile 

    }

}

#check to see if new directory exists
$rdirectoryexists = Get-Item -Path $rdirectory
$rfileexists = Get-ChildItem -Path $rdirectory -Filter '*.r'
$rfunction = "$rfiles\ASCVD_Final.r"

#add new directory and r script 
if(!$rdirectoryexists) { 
    New-Item -ItemType 'Directory' -Path $rdirectory
}
else {
    Write-Host "$rdirectory already exists"
}

#add files if they don't exist
if(!$rfiles) {

    $rfiles | ForEach-Object {
        $rfile = $PSItem.FullName
        $rfilename = $PSItem.BaseName
        Write-Host "Copying File from $rfile to $rdirectory"
        Copy-Item -Path $rfile -Destination "$rdirectory\$rfilename.R"  
    }

}
else {
    Write-Host "R Functions have already been added"
}

If($RExists) {

#get patient risk data
Write-Host "Adding Patient Risk Data"
$AddRiskData = "EXEC spCreateRiskData"
Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -Query $AddRiskData

#run risk calculation
Write-Host "Updating Risk Table to Include Risk Information"
$RunASCVDRisk = "EXEC spASCVD_Risk"
Invoke-Sqlcmd -ServerInstance $ServerName -Database $DbName -Query $RunASCVDRisk

}

Read-Host "Press any key to exit"
exit

