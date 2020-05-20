IF(OBJECT_ID('dbo.spASCVD_Risk','P')) IS NOT NULL
	BEGIN
		DROP PROCEDURE [dbo].[spASCVD_Risk]
	END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[spASCVD_Risk]

AS

/*
Date 04/02/2019
Creator - Nick Arquette
Purpose - Generate a risk level for a patient using WHO ISH 
Source - https://github.com/syadlowsky/revised-pooled-ascvd
Example Exec dbo.spASCVD_Risk


*/

CREATE TABLE #RiskData
(
	FacilityDimID	INT
	,PatientDimID	INT
	,Risk			INT
	,RiskCategory	VARCHAR(48)
	,AgeCategory	VARCHAR(48)
)

INSERT INTO #RiskData
EXEC sp_execute_external_script
  @language =N'R',
  @script=N'
  setwd("D:\\R\\Functions");
  source("ASCVD_Final.R");
  OutputDataSet <- as.data.frame(ascvd_estimator(InputDataSet$FacilityDimID, InputDataSet$PatientDimID, InputDataSet$MRN, InputDataSet$Age, InputDataSet$Gender, InputDataSet$IsAfricanAmerican, InputDataSet$IsDiabetic, InputDataSet$IsSmoker, InputDataSet$CholResult, InputDataSet$HDLResult, InputDataSet$SysResult, InputDataSet$RxBP)); 
  ',
  @input_data_1 =N'SELECT	 FacilityDimID
                            ,MRN
                            ,PatientDimID
							,Age
							,Gender
							,IsAfricanAmerican
							,IsDiabetic
							,IsSmoker
							,CholResult
							,HDLResult
							,SysResult
							,RxBP
				  FROM PatientRiskData'

UPDATE PRD
SET PRD.AgeCategory = TRD.AgeCategory
    ,PRD.Risk = TRD.Risk
	,PRD.RiskCategory = TRD.RiskCategory
FROM dbo.PatientRiskData AS PRD
JOIN #RiskData			 AS TRD
	ON PRD.PatientDimID = TRD.PatientDimID


GO


