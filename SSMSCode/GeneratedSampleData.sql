/*
Date 05/20/2020
Creator - Nick Arquette
Purpose - Generate a risk test data for all base patients 
Source - 
Example None


*/

-- declare variables to build ulr string for risk app
DECLARE @BaseUrl        VARCHAR(255) = 'enter risk app name'
DECLARE	@GenderParam    VARCHAR(128) = '?gender='
DECLARE @AgeParam       VARCHAR(128) = '&age='
DECLARE @CholParam      VARCHAR(128) = '&cholesterol='
DECLARE @HdlParam       VARCHAR(128) = '&hdl='
DECLARE @SysParam       VARCHAR(128) = '&sys='
DECLARE @SmokeParam     VARCHAR(128) = '&smoker='
DECLARE @HypertenParam  VARCHAR(128) = '&hypertensive='
DECLARE @RaceParam      VARCHAR(128) = '&race='
DECLARE @DiabParam      VARCHAR(128) = '&diabetic='
DECLARE @tParam		    VARCHAR(128) = '&t='
DECLARE @ttParam		VARCHAR(128) = '&tt='   
DECLARE @hashkey		NVARCHAR(32) = 'aabbsseeccdee'
DECLARE @time			NVARCHAR(12) = CONVERT(nvarchar(10), DATEDIFF(SECOND,'1970-01-01', GETUTCDATE()))

-- add table to store patient without a risk value
DECLARE @UpdtTbl AS TABLE (
	ID INT IDENTITY(1,1)
	,PatientRiskDataID BIGINT
)

-- insert into table variable WHEN patient don't have a risk value
INSERT INTO @UpdtTbl ( PatientRiskDataID )
SELECT PatientRiskDataID
FROM RptPAPatientRiskData
WHERE MissingData = 1

--loop though all patient AND generate risk information AND AND age category
DECLARE @I INT = (SELECT MIN(ID) FROM @UpdtTbl)
WHILE @I <= (SELECT MAX(ID) FROM @UpdtTbl)
	BEGIN

		DECLARE @pHDLResult INT = (SELECT FLOOR(RAND()*(100-20+1))+20)
		DECLARE @pSysResult INT = (SELECT FLOOR(RAND()*(200-90+1))+90)
		DECLARE @pCholResult INT = (SELECT FLOOR(RAND()*(320-130+1))+130)
		DECLARE @pIsDiabetic INT = (SELECT FLOOR(RAND()*(1-0+1))+0)
		DECLARE @pIsSmoker INT = (SELECT FLOOR(RAND()*(1-0+1))+0)
		DECLARE @pRxBP INT = (SELECT FLOOR(RAND()*(1-0+1))+0)
		DECLARE @pPatientRiskID BIGINT = (SELECT PatientRiskDataID FROM @UpdtTbl WHERE ID = @I)
		
		UPDATE RptPAPatientRiskData
		SET AgeCategory = CASE WHEN age BETWEEN 40 AND 49 THEN '40-49 Years'  
						 WHEN age BETWEEN 50 AND 59 THEN '50-59 Years'  
						 WHEN age BETWEEN 60 AND 69 THEN '60-69 Years'  
						 WHEN age BETWEEN 70 AND 79 THEN '70-79 Years'
						 END
			,IsDiabetic = @pIsDiabetic
			,IsSmoker = @pIsSmoker
			,RxBP  = @pRxBP
			,HDLResult = @pHDLResult
		    ,HDLResultDtm = DATEADD(d,-7,AdmitDtm)
		    ,CholResult = @pCholResult
			,CholResultDtm = DATEADD(d,-7,AdmitDtm)
			,SysResult = @pSysResult
			,SysResultDtm = AdmitDtm
			,MissingData = 0
			,Race = IIF(Race IS NULL,'White',Race)
			,IsAfricanAmerican = IIF(IsAfricanAmerican IS NULL, 0, IsAfricanAmerican)		
		WHERE PatientRiskDataID = @pPatientRiskID
			   
		SET @I += 1
			   
	END

--- create a table variable to handle generating the risk information

DECLARE @coeff TABLE
(
	IsAfricanAmerican BIT,
	GenderCode char(1),
	CAge NUMERIC(6,4),
	CSqAge NUMERIC(6,4),
	CTotalChol NUMERIC(6,4),
	CAgeTotalChol NUMERIC(6,4),
	CHDLChol NUMERIC(6,4),
	CAgeHDLChol NUMERIC(6,4),
	COnHypertensionMeds NUMERIC(6,4),
	CAgeOnHypertensionMeds NUMERIC(6,4),
	COffHypertensionMeds NUMERIC(6,4),
	CAgeOffHypertensionMeds NUMERIC(6,4),
	CSmoker NUMERIC(6,4),
	CAgeSmoker NUMERIC(6,4),
	CDiabetes NUMERIC(6,4),
	S10 NUMERIC(6,4),
	MeanTerms NUMERIC(6,4)
)

-- store contants in the table 

INSERT INTO @coeff
SELECT 1, 'F', 17.114, 0, 0.94, 0, -18.92, 4.475, 29.291, -6.432, 27.82, -6.087 ,0.691, 0, 0.874, 0.9533, 86.61
UNION
SELECT 0, 'F', -29.799, 4.884, 13.54, -3.114, -13.578, 3.149, 2.019, 0, 1.957, 0, 7.574, -1.665, 0.661, 0.9665, -29.18
UNION
SELECT 1, 'M', 2.469, 0, 0.302, 0, -0.307, 0, 1.916, 0, 1.809, 0, 0.549, 0, 0.645, 0.8954, 19.54
UNION
SELECT 0, 'M', 12.344, 0, 11.853, -2.664, -7.99, 1.769, 1.797, 0, 1.764, 0, 7.837, -1.795, 0.658, 0.9144, 61.18


;WITH risk_CTE (PatientDimId, RiskScore, RiskCategory, AgeCategory) AS 
(
SELECT
	PatientDimID,
	ROUND(100 * (1 - POWER(coeff.S10, 
		EXP(
		( -- Terms
			(coeff.CAge * LOG(Age)) + 
			(coeff.CSqAge * POWER(LOG(Age), 2)) + 
			(coeff.CTotalChol * LOG(CholResult)) + 
			(coeff.CAgeTotalChol * LOG(Age) * LOG(CholResult)) + 
			(coeff.CHDLChol * LOG(HDLResult)) + 
			(coeff.CAgeHDLChol * LOG(Age) * LOG(HDLResult)) + 
			(CAST(RxBP AS INT) * coeff.COnHypertensionMeds * LOG(SysResult)) + 
			(CAST(RxBP AS INT) * coeff.CAgeOnHypertensionMeds * LOG(Age) * LOG(SysResult)) + 
			(CASE WHEN RxBP = 0 THEN 1 ELSE 0 END * coeff.COffHypertensionMeds * LOG(SysResult)) + 
			(CASE WHEN RxBP = 0 THEN 1 ELSE 0 END * coeff.CAgeOffHypertensionMeds * LOG(Age) * LOG(SysResult)) + 
			(coeff.CSmoker * CAST(IsSmoker AS INT)) + 
			(coeff.CAgeSmoker * LOG(Age) * CAST(IsSmoker AS INT)) + 
			(coeff.CDiabetes * CAST(IsDiabetic AS INT))
		)
		-
		-- means
		coeff.MeanTerms))),2,1)
RiskScore,
'Unknown' RiskCategory,
CASE WHEN age between 40 AND 49 THEN '40-49 Years'  
	 WHEN age between 50 AND 59 THEN '50-59 Years'  
	 WHEN age between 60 AND 69 THEN '60-69 Years'  
	 WHEN age between 70 AND 79 THEN '70-79 Years'  
END AgeCategory
FROM RptPAPatientRiskData rd
inner JOIN @coeff coeff ON coeff.IsAfricanAmerican = rd.IsAfricanAmerican AND coeff.GenderCode = rd.GenderCode
)

-- UPDATE patient WITH a risk value AND category
UPDATE patientRiskData
SET patientRiskData.AgeCategory = cte.AgeCategory
    ,patientRiskData.Risk = cte.RiskScore
	,patientRiskData.RiskCategory = 
	CASE WHEN cte.RiskScore between 0 AND 4.99 THEN 'Low Risk (0 - 5)'
		 WHEN cte.RiskScore between 5 AND 7.49 THEN 'Borderline Risk (5 - 7.4)'
		 WHEN cte.RiskScore between 7.5 AND 19.99 THEN 'Intermediate Risk (7.5 - 19.9)'
		 WHEN cte.RiskScore > 20 THEN 'High Risk (>20)'
	END
FROM RptPAPatientRiskData AS patientRiskData
JOIN risk_CTE AS cte
	ON patientRiskData.PatientDimID = cte.PatientDimID

-- UPDATE risk url string 
UPDATE RptPAPatientRiskData
			SET PatientRiskUrl =  CONCAT(	@BaseURL,
				@GENDerParam,CASE WHEN GenderCode = 'm' THEN 'Male' WHEN GenderCode = 'f' THEN 'Female' END,
                @AgeParam,Age,
				@CholParam,CholResult,
				@HdlParam,HDLResult,
				@SysParam,SysResult,
				@SmokeParam,IsSmoker,
				@DiabParam,IsDiabetic,
				@HypertenParam,RxBP,                
                @RaceParam,CASE WHEN IsAfricanAmerican = 1 THEN 'aa' WHEN IsAfricanAmerican IS NULL THEN NULL ELSE 'Other' END,
				@tParam,CONVERT(NVARCHAR(64),HashBytes('SHA2_256','cpm'+@time+@hashkey),2),
				@ttParam,@time ) 	


-- SELECT all patients 
SELECT * 
FROM RptPAPatientRiskData
WHERE MissingData = 0

