# ASCVD
On-Premise Machine Learning Services - ASCVD Example using R.  The following code will install all of the needed information to produce a risk of existing data

# Pre-requisites
1) [Install SQL Machine Learning Services for Sql Server](https://docs.microsoft.com/en-us/sql/machine-learning/install/sql-machine-learning-services-windows-install?view=sql-server-ver15)
2) Powershell Version 3 and Above

# Pre-Run Setup
1) Open 2.spCreateRiskData and change @BaseURL to your risk app
2) Open InstallASCVD.ps1 and change line 11 and 12 to your database name

# Run Code
1) Go to machine (sql server machine) that will be running Machine Learning Services
2) Copy Files to a directory
3) Go to Start / Programs
4) Search for the Command Prompt (CMD)
5) Navigate to Directory (cd) that the files were copied
6) Paste in the follow command

Powershell.exe -ExecutionPolicy Bypass -File ./InstallASCVD.ps1

# Expectations of Running Install File
1) Add the require R function to a directory C or D if it exists
2) Validates setup of R 
** it will not install if R is not installed in the database
3) Add all required sql scripts (tables and procedures)
4) Runs Create Risk Information
5) Updates Risk Table to include the Risk Score and Category
6) If you don't have any risk data you could run the file called GeneratedSampleData.sql which will insert sample data for all of the patient in the base population (patient between 40 and 79).




