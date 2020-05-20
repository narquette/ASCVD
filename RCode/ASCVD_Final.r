ascvd_estimator <- function(fdim, pdim, mrn, age, sex, afram, dm, cursmoke, totchol, hdlc, sysbp, rxbp) {
  
	  female.risk <- 1.0 / (1.0 + exp( - (
		-12.823110 +
		  0.106501 * as.numeric(age) +
		  0.432440 * as.numeric(afram) +
		  0.000056 * (as.numeric(sysbp) ^ 2) +
		  0.017666 * as.numeric(sysbp) +
		  0.731678 * as.numeric(rxbp) +
		  0.943970 * as.numeric(dm) +
		  1.009790 * as.numeric(cursmoke) +
		  0.151318 * (as.numeric(totchol) / as.numeric(hdlc)) +
		  -0.008580 * as.numeric(age) * as.numeric(afram) +
		  -0.003647 * as.numeric(sysbp) * as.numeric(rxbp) +
		  0.006208 * as.numeric(sysbp) * as.numeric(afram) +
		  0.152968 * as.numeric(afram) * as.numeric(rxbp) +
		  -0.000153 * as.numeric(age) * as.numeric(sysbp) +
		  0.115232 * as.numeric(afram) * as.numeric(dm) +
		  -0.092231 * as.numeric(afram) * as.numeric(cursmoke) +
		  0.070498 * as.numeric(afram) * (as.numeric(totchol) / as.numeric(hdlc)) +
		  -0.000173 * as.numeric(afram)  * as.numeric(sysbp) * as.numeric(rxbp) +
		  -0.000094 * as.numeric(age) * as.numeric(sysbp) * as.numeric(afram)
	  )))
	  male.risk <- 1.0 / (1.0 + exp( - (
		-11.679980 +
		  0.064200 * as.numeric(age) +
		  0.482835 * as.numeric(afram) +
		  -0.000061 * (as.numeric(sysbp) ^ 2) +
		  0.038950 * as.numeric(sysbp) +
		  2.055533 * as.numeric(rxbp) +
		  0.842209 * as.numeric(dm) +
		  0.895589 * as.numeric(cursmoke) +
		  0.193307 * (as.numeric(totchol) / as.numeric(hdlc)) +
		  -0.014207 * as.numeric(sysbp) * as.numeric(rxbp) +
		  0.011609 * as.numeric(sysbp) * as.numeric(afram) +
		  -0.119460 * as.numeric(rxbp) * as.numeric(afram) +
		  0.000025 * as.numeric(age) * as.numeric(sysbp) +
		  -0.077214 * as.numeric(afram) * as.numeric(dm) +
		  -0.226771 * as.numeric(afram) * as.numeric(cursmoke) +
		  -0.117749 * (as.numeric(totchol) / as.numeric(hdlc)) * as.numeric(afram) +
		  0.004190 * as.numeric(afram) * as.numeric(rxbp) * as.numeric(sysbp) +
		  -0.000199 * as.numeric(afram) * as.numeric(age) * as.numeric(sysbp)
	  )))
	  
  #store risk value
  risk <-  round(100*(ifelse(as.numeric(sex) == 1, female.risk, male.risk)),2)  
  
  #create dataframe with all the values
  df.risk <- data.frame("FacilityDimID"=fdim,
						"PatientDimID"=pdim,
						"RiskLevel"=risk)
  
  #add break category in data
  df.risk['RiskCategory'] <- cut(as.numeric(risk), breaks=seq(0, 100, 20), labels=c("0-20", "21-40", "41-60", "61-80", "81-100"))
  
  #add break category for age
  df.risk['AgeCategory'] <- cut(as.numeric(age), breaks=seq(0, 100, 20), labels=c("0-20 years", "21-40 years", "41-60 years", "61-80 years", "81-100 years"))
  
  #output risk dataframe
  df.risk 
}

#ascvd_estimator(fdim=1, pdim=1, age=60, sex=0, afram=1, dm=1, cursmoke=1, totchol=200, hdlc=50, sysbp=90, rxbp=1)