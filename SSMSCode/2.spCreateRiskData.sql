IF(OBJECT_ID('dbo.spCreateRiskData','P')) IS NOT NULL
	BEGIN
		DROP PROCEDURE [dbo].[spCreateRiskData]
	END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[spCreateRiskData] 
(
	 @BaseUrl        VARCHAR(255) = 'https://cdsconsoleint.allscriptsclient.com:93/'
	,@FirstNameParam VARCHAR(128) = '?fname='
	,@LastNameParam  VARCHAR(128) = '&lname='
	,@GenderParam    VARCHAR(128) = '&gender='
	,@AgeParam		 VARCHAR(128) = '&age='
	,@CholParam      VARCHAR(128) = '&cholesterol='
	,@HdlParam		 VARCHAR(128) = '&hdl='
	,@SysParam		 VARCHAR(128) = '&sys='
	,@SmokeParam	 VARCHAR(128) = '&smoker='
	,@HypertenParam  VARCHAR(128) = '&hypertensive='
	,@RaceParam	     VARCHAR(128) = '&race='
	,@DiabParam		 VARCHAR(128) = '&diabetic='
	,@DobParam		 VARCHAR(128) = '&dob='
)

/*
Date 04/25/2019
Creator - Nick Arquette
Purpose - Generate a risk data need to call the RiskLevel stored procedure 
EXEC dbo.spRiskData_Final
*/

AS

---remove data from patient risk table
TRUNCATE TABLE dbo.PatientRiskData

;With HTN AS (
SELECT  FacilityDimID
		,PatientDimID			
FROM SCAPopulation
WHERE PopulationSetName = 'Hypertension Base Clinical Population PD_CCM'
GROUP BY FacilityDimID
		,PatientDimID
), DIAB AS (
SELECT  FacilityDimID
		,PatientDimID
FROM SCAPopulation
WHERE PopulationSetName = 'Diabetes CCM'
GROUP BY FacilityDimID
		,PatientDimID
), SYST AS (
	SELECT *
	FROM (
	SELECT Vis.FacilityDimID
		   ,Vis.PatientDimID
		   ,Qm.LastBPSystolic AS SysResult
		   ,Vis.AdmitDate AS SysResultDtm
		   ,ROW_NUMBER() OVER(PARTITION BY Vis.PatientDimID ORDER BY Vis.VisitID DESC) rankColumn
	FROM [dbo].[SCAQualityMeasure] AS Qm
	JOIN [dbo].[SCAVisit] AS Vis
		ON Qm.VisitID = Vis.VisitID
	WHERE QM.LastBPSystolic IS NOT NULL
	) AS SubTable
	WHERE rankColumn = 1
), CHOL AS (
	SELECT DISTINCT 
		   SubTable.FacilityDimID, 
		   SubTable.VisitID, 
		   SubTable.PatientDimID, 
		   SubTable.CholResult,
		   SubTable.CholResultDtm		   
	FROM
	(
		SELECT SCAVisit.FacilityDimID, 
			   SCAVisit.VisitID,
			   SCAResult.PatientDimID, 
			   SCAResult.NumericValue AS CholResult,
			   SCAResult.ResultDtm AS CholResultDtm,			   
			   ROW_NUMBER() OVER(PARTITION BY SCAResult.PatientDimID ORDER BY resultdtm DESC) rankColumn			   		   
		FROM [dbo].[SCAVisit] SCAVisit
		INNER JOIN [dbo].[SCAResult] SCAResult WITH(NOLOCK) 
			ON SCAResult.visitid = SCAVisit.visitid
				AND SCAResult.IsActive = 1         
		INNER JOIN [dbo].[SCAResultNameDim] SCAResultNameDim WITH(NOLOCK)
			ON SCAResultNameDim.ResultNameDimID = SCAResult.ResultNameDimID
		INNER JOIN [dbo].[SCAResultStatusDim] SCAResultStatusDim WITH(NOLOCK) 
			ON SCAResultStatusDim.[ResultStatusDimID] = SCAResult.[ResultStatusDimID]
		INNER JOIN [dbo].[SCAResultCatalogDimVW] SCAResultCatalogDimVW WITH(NOLOCK) 
			ON SCAResultCatalogDimVW.[ResultCatalogDimID] = SCAResult.[ResultCatalogDimID]
				AND SCAResultCatalogDimVW.MedicalCode = '2093-3'			
				AND SCAResult.IsActive = 1   
				AND SCAResult.NumericValue IS NOT NULL
	) SubTable
	WHERE rankColumn = 1
), HDL AS (
	SELECT DISTINCT 
		   SubTable.FacilityDimID, 
		   SubTable.VisitID, 
		   SubTable.PatientDimID, 
		   SubTable.HDLResult,
		   SubTable.HDLResultDtm,
		   SubTable.AdmitDtm
	FROM
	(
		SELECT SCAVisit.FacilityDimID, 
			   SCAVisit.VisitID,
			   SCAResult.PatientDimID, 
			   SCAResult.NumericValue AS HDLResult,
			   SCAResult.ResultDtm AS HDLResultDtm,
			   ROW_NUMBER() OVER(PARTITION BY SCAResult.PatientDimID ORDER BY resultdtm DESC) rankColumn, 
			   SCAVisit.AdmitDtm		   
		FROM [dbo].[SCAVisit] SCAVisit
		INNER JOIN [dbo].[SCAResult] SCAResult WITH(NOLOCK) 
			ON SCAResult.visitid = SCAVisit.visitid
				AND SCAResult.IsActive = 1         
		INNER JOIN [dbo].[SCAResultNameDim] SCAResultNameDim WITH(NOLOCK)
			ON SCAResultNameDim.ResultNameDimID = SCAResult.ResultNameDimID
		INNER JOIN [dbo].[SCAResultStatusDim] SCAResultStatusDim WITH(NOLOCK) 
			ON SCAResultStatusDim.[ResultStatusDimID] = SCAResult.[ResultStatusDimID]
		INNER JOIN [dbo].[SCAResultCatalogDimVW] SCAResultCatalogDimVW WITH(NOLOCK) 
			ON SCAResultCatalogDimVW.[ResultCatalogDimID] = SCAResult.[ResultCatalogDimID]
				AND SCAResultCatalogDimVW.MedicalCode = '2085-9 '			
				AND SCAResult.IsActive = 1   
				AND SCAResult.NumericValue IS NOT NULL
	) SubTable
	WHERE rankColumn = 1
), DEMO AS (
	SELECT Pat.PatientDimID
	       ,Pat.FirstName
		   ,Pat.LastName
	       ,FLOOR(DATEDIFF(day,Pat.birthdtm,getdate())/365.25) AS Age
		   ,Gen.Gender
		   ,Pat.MRN
	FROM SCAPatientDim AS Pat
	JOIN SCAGenderDim AS Gen
		ON Pat.GenderDimID = Gen.GenderDimID
	WHERE Year(BirthDtm) <= Year(getdate())
), Smoke AS (
	SELECT FacilityDimID
        ,PatientDimID
		,IsSmoker
	FROM RMVisitVW	
), AFR AS (
	SELECT PatientDimID	   
           ,'African American' AS IsAfricanAmerican
	FROM SCARacePatientDimVW 
	WHERE RaceCode = '2054-5'
	GROUP BY PatientDimID
), MED AS (
	SELECT Med.FacilityDimID
		   ,Med.PatientDimID 
	FROM SCAMedication		AS Med
	JOIN SCAMedicationDim	AS MedD
		ON Med.MedicationDimID = MedD.MedicationDimID
	JOIN SCAPrescription	AS Pres
		ON Med.PrescriptionID = Med.PrescriptionID
	JOIN SCAStatusDim		AS Stat
		ON Pres.StatusDimID = Stat.StatusDimID
	WHERE MedD.RxNormCode IN (
		SELECT ItemValue
		FROM CPMDemo_MetaData.dbo.SANMDQualificationValue 
		WHERE QualificationName IN ( 
			'ACE Inhibitor or ARB Grouping VSAC v9.2018 PD_CCM'
			,'ACE Inhibitor_ACEI VSAC v9.2018 PD_CCM'
			,'Angiotensin II Receptor Blocker_ARB VSAC v9.2018 PD_CCM'
			,'Beta Blocker Therapy Grouping Value Set'
			,'Calcium Channel Blockers_CCB VSAC v9.2018 PD_CCM'
			,'Diuretics Except Thiazides VSAC v9.2018 PD_CCM'
			,'Thiazide Diuretics VSAC v9.2018 PD_CCM'
		)
		GROUP BY ItemValue 
	)
		AND Med.IsActive = 1
		AND Stat.Status IN ( 'Active', 'Continued', 'Ordered' )
	GROUP BY Med.FacilityDimID
		   ,Med.PatientDimID
)
INSERT INTO dbo.PatientRiskData (
		FacilityDimID		
       ,PatientDimID
	   ,MRN 
	   ,FirstName
	   ,LastName
	   ,Age					
	   ,Gender				
	   ,IsAfricanAmerican	
	   ,IsDiabetic			
	   ,IsSmoker			
	   ,HDLResult		
	   ,HDLResultDtm
	   ,CholResult	
	   ,CholResultDtm
	   ,SysResult	
	   ,SysResultDtm
	   ,RxBP
	   ,MissingData
	   ,PatientRiskUrl		
)
SELECT FacilityDimID		
       ,PatientDimID		
	   ,MRN
	   ,FirstName
	   ,LastName 
	   ,Age					
	   ,Gender					
	   ,IsAfricanAmerican	
	   ,IsDiabetic			
	   ,IsSmoker			
	   ,HDLResult	
	   ,HDLResultDtm
	   ,CholResult	
	   ,CholResultDtm 
	   ,SysResult		
	   ,SysResultDtm 
	   ,RxBP			
	   ,0 AS MissingData
	   ,CONCAT(@BaseURL,
			   @AgeParam,Age,
			   @GenderParam,Gender,
			   @RaceParam,IsAfricanAmerican,
			   @DiabParam,IsDiabetic,
			   @SmokeParam,IsSmoker,
			   @CholParam,CholResult,
			   @HdlParam,HDLResult,
			   @SysParam,SysResult,
			   @HypertenParam,RxBP) AS PatientRiskURL
FROM (
	SELECT DISTINCT 
			HTN.FacilityDimID
		   ,HTN.PatientDimID
		   ,DEMO.FirstName
		   ,DEMO.LastName 
		   ,DEMO.MRN 
		   ,DEMO.Age
		   ,DEMO.Gender
		   ,IIF(AFR.IsAfricanAmerican IS NULL,'White','African American') AS IsAfricanAmerican
		   ,IIF(DIAB.PatientDimID IS NULL,'false','true') AS IsDiabetic
		   ,IIF(Smoke.PatientDimID IS NULL,'false','true') AS IsSmoker
		   ,HDL.HDLResult
		   ,HDL.HDLResultDtm
		   ,CHOL.CholResult
		   ,CHOL.CholResultDtm
		   ,SYST.SysResult	  
		   ,SYST.SysResultDtm
		   ,IIF(MED.PatientDimID IS NULL,'false','true') AS RxBP	 
	FROM HTN 
	INNER JOIN DEMO
		ON HTN.PatientDimID = DEMO.PatientDimID
	LEFT JOIN DIAB
		ON HTN.PatientDimID = DIAB.PatientDimID
	LEFT JOIN CHOL
		ON HTN.PatientDimID = CHOL.PatientDimID
	LEFT JOIN HDL
		ON HTN.PatientDimID = HDL.PatientDimID
	LEFT JOIN SYST
		ON HTN.PatientDimID = SYST.PatientDimID	
	LEFT JOIN Smoke 
		ON HTN.PatientDimID = Smoke.PatientDimID 
	LEFT JOIN AFR
		ON HTN.PatientDimID = AFR.PatientDimID
	LEFT JOIN MED 
		ON HTN.PatientDimID = MED.PatientDimID

) AS SubTable
ORDER BY PatientDimID

--update missing cholesterol values with the median value
UPDATE dbo.PatientRiskData 
SET PatientRiskURL = NULL 
    ,MissingData   = 1
WHERE (
	  CholResult IS NULL
      OR HDLResult IS NULL
	  OR SysResult IS NULL
	  )
	  
GO 


