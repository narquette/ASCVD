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

DECLARE @UpdtTbl AS TABLE (
	ID INT IDENTITY(1,1)
	,PatientRiskDataID BIGINT
)

INSERT INTO @UpdtTbl ( PatientRiskDataID )
SELECT PatientRiskDataID
FROM RptPAPatientRiskData
WHERE MissingData = 1

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

declare @coeff table
(
	IsAfricanAmerican bit,
	GenderCode char(1),
	CAge numeric(6,4),
	CSqAge numeric(6,4),
	CTotalChol numeric(6,4),
	CAgeTotalChol numeric(6,4),
	CHDLChol numeric(6,4),
	CAgeHDLChol numeric(6,4),
	COnHypertensionMeds numeric(6,4),
	CAgeOnHypertensionMeds numeric(6,4),
	COffHypertensionMeds numeric(6,4),
	CAgeOffHypertensionMeds numeric(6,4),
	CSmoker numeric(6,4),
	CAgeSmoker numeric(6,4),
	CDiabetes numeric(6,4),
	S10 numeric(6,4),
	MeanTerms numeric(6,4)
)

insert into @coeff
select 1, 'F', 17.114, 0, 0.94, 0, -18.92, 4.475, 29.291, -6.432, 27.82, -6.087 ,0.691, 0, 0.874, 0.9533, 86.61
union
select 0, 'F', -29.799, 4.884, 13.54, -3.114, -13.578, 3.149, 2.019, 0, 1.957, 0, 7.574, -1.665, 0.661, 0.9665, -29.18
union
select 1, 'M', 2.469, 0, 0.302, 0, -0.307, 0, 1.916, 0, 1.809, 0, 0.549, 0, 0.645, 0.8954, 19.54
union
select 0, 'M', 12.344, 0, 11.853, -2.664, -7.99, 1.769, 1.797, 0, 1.764, 0, 7.837, -1.795, 0.658, 0.9144, 61.18


;with risk_CTE (PatientDimId, RiskScore, RiskCategory, AgeCategory) as 
(
select
	PatientDimID,
	round(100 * (1 - power(coeff.S10, 
		exp(
		( -- Terms
			(coeff.CAge * log(Age)) + 
			(coeff.CSqAge * power(log(Age), 2)) + 
			(coeff.CTotalChol * log(CholResult)) + 
			(coeff.CAgeTotalChol * log(Age) * log(CholResult)) + 
			(coeff.CHDLChol * log(HDLResult)) + 
			(coeff.CAgeHDLChol * log(Age) * log(HDLResult)) + 
			(cast(RxBP as int) * coeff.COnHypertensionMeds * log(SysResult)) + 
			(cast(RxBP as int) * coeff.CAgeOnHypertensionMeds * log(Age) * log(SysResult)) + 
			(case when RxBP = 0 then 1 else 0 end * coeff.COffHypertensionMeds * log(SysResult)) + 
			(case when RxBP = 0 then 1 else 0 end * coeff.CAgeOffHypertensionMeds * log(Age) * log(SysResult)) + 
			(coeff.CSmoker * cast(IsSmoker as int)) + 
			(coeff.CAgeSmoker * log(Age) * cast(IsSmoker as int)) + 
			(coeff.CDiabetes * cast(IsDiabetic as int))
		)
		-
		-- means
		coeff.MeanTerms))),2,1)
RiskScore,
'Unknown' RiskCategory,

case when age between 40 and 49 then '40-49 Years'  
	 when age between 50 and 59 then '50-59 Years'  
	 when age between 60 and 69 then '60-69 Years'  
	 when age between 70 and 79 then '70-79 Years'  
end AgeCategory
from RptPAPatientRiskData rd
inner join @coeff coeff on coeff.IsAfricanAmerican = rd.IsAfricanAmerican and coeff.GenderCode = rd.GenderCode
)

update patientRiskData
set patientRiskData.AgeCategory = cte.AgeCategory
    ,patientRiskData.Risk = cte.RiskScore
	,patientRiskData.RiskCategory = 
	case when cte.RiskScore between 0 and 4.99 then 'Low Risk (0 - 5)'
		 when cte.RiskScore between 5 and 7.49 then 'Borderline Risk (5 - 7.4)'
		 when cte.RiskScore between 7.5 and 19.99 then 'Intermediate Risk (7.5 - 19.9)'
		 when cte.RiskScore > 20 then 'High Risk (>20)'
	end
from RptPAPatientRiskData as patientRiskData
join risk_CTE as cte
	on patientRiskData.PatientDimID = cte.PatientDimID

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

SELECT * 
FROM RptPAPatientRiskData
WHERE MissingData = 0

