IF OBJECT_ID('dbo.PatientRiskData') IS NOT NULL
	BEGIN
		DROP TABLE dbo.PatientRiskData
	END 

CREATE TABLE dbo.PatientRiskData
(
	   FacilityDimID		BIGINT
       ,PatientDimID		BIGINT
	   ,FirstName			VARCHAR(128)
	   ,LastName		    VARCHAR(128)
	   ,MRN					VARCHAR(32)
	   ,Age					NUMERIC
	   ,AgeCategory			VARCHAR(48)
	   ,Gender				VARCHAR(128)
	   ,IsAfricanAmerican	VARCHAR(16)
	   ,IsDiabetic			VARCHAR(5)
	   ,IsSmoker			VARCHAR(5)
	   ,HDLResult			NUMERIC
	   ,HDLResultDtm		DATETIME
	   ,CholResult			NUMERIC 	   
	   ,CholResultDtm		DATETIME
	   ,SysResult			INT
	   ,SysResultDtm		DATETIME
	   ,RxBP				VARCHAR(5)
	   ,MissingData			INT 
	   ,Risk				INT
	   ,RiskCategory		VARCHAR(48)
	   ,PatientRiskUrl		VARCHAR(MAX)
)