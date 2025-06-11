*--------------------------------------------------------------------------------------------------
*　STATA Code for:
*
* "Chuang, H.C., Hsu, P.H., Kuan, C.M., Yang, J.C., 2025. Revisiting the Missing R\&D-Patent Relation: Challenges and Solutions for Firm Fixed Effects Models. The paper is available at SSRN. https://ssrn.com/abstract=4636846"
*
* This code demonstrates four methods to address potential biases in fixed effects regressions:
*  (1) Regression with and without firm FEs and  Within R squared  
*  (2) Adjusted Hausman_Taylor method
*  (3) Post-regularization and Double Machine Learning (DML) LASSO methods for both regression and Poisson models
*
*  (Note: STATA version 17 or above is required for these implementations.)
*
*
* All sample data and results are available on the GitHub repository 
* https://github.com/hcchuang/Revisiting-the-Missing-RD-Patent-Relation_Challenges-and-Solutions-for-Firm-Fixed-Effects-Models
*
* Please contact Po-Hsuan Hsu (pohsuanhsu@mx.nthu.edu.tw) or Hui-Ching Chuang (huichingc@gmail.com) 
* for any questions regarding the data.
*
* Version: 2025/06/12
*
*--------------------------------------------------------------------------------------------------

********************************************************************************************************************
* Linear model: POLS, HDFE, Post-regularization LASSO regression and double machine learning LASSO regression 
********************************************************************************************************************


cd "D:\ReplicateLog_Results"

* Load the data
clear all
set maxvar 120000 

use "Replicate_data_MissingRDPatent_ML.dta"

* Declare data to be panel data
sort PERMCO fyear
xtset PERMCO fyear


	 
*--------------------------------------------------------------------------------------------------

log using "ReplicateLog_OLS_FE_adjHT.smcl", replace

* Table: OLS and Fixed effect estimation 

	* Define variables of interests (please change accordingly)
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"
	local allvars "`rd_used' `ctrl'"
	
	* generate the de-mean variables
	sort PERMCO
	foreach v of local allvars {
		by PERMCO: egen mean_`v' = mean(`v')
		gen demean_`v' = `v' - mean_`v'
	}
	local demean_ctrl = "demean_lnME demean_RD_missing demean_lnAge demean_lnK2L demean_TobinQ demean_ROA demean_Leverage demean_CASHAT demean_KZidx demean_InstOwn demean_oms_HHidx demean_oms_HHidx_square"
	
	
	estimates clear
	
	* Fixed Effect on firm and year
	reghdfe `innov_used' `rd_used' `ctrl' , absorb(i.PERMCO i.fyear) vce(cluster PERMCO)
	estadd local FirmFE "yes",replace
    estadd local YearFE "yes",replace
    estimates store FE
	
	* OLS
	reg `innov_used' `rd_used' `ctrl' i.fyear, vce(cluster PERMCO)
	estadd local FirmFE "no",replace
    estadd local YearFE "yes",replace
	estimates store OLS
	
    * Adj-Hausman-Taylor    
	ivregress gmm `innov_used' `ctrl' i.fyear (`rd_used' = `demean_ctrl' demean_RDAT), wmatrix(cluster PERMCO)	
	estadd local FirmFE "no"
    estadd local YearFE "yes"
	estimates store adjHT
  
	*Output the Hausman Taylor table as *.csv file 
    esttab FE OLS adjHT, stats(FirmFE YearFE N) noconstant  star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("Fixed Effects FE_OLS_adjHT Model Estimates") mtitle("FE" "OLS" "adjHT"), using "FE_OLS_adjHT_estimates.csv"	  
	
log close



*--------------------------------------------------------------------------------------------------

* Table: R squares and Within R square

	* Define variables of interests (please change accordingly)
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	
    reg `innov_used' `rd_used' `ctrl' i.fyear, vce(cluster PERMCO)
    estimates store ols_year
    estadd scalar r2_a = e(r2_a), replace
    
    reghdfe `innov_used' `rd_used' `ctrl', absorb(PERMCO fyear) vce(cluster PERMCO)
    estimates store reghdfe_fmyr
    estadd scalar r2_a        = e(r2_a), replace
    estadd scalar r2_within   = e(r2_within)  , replace 
    estadd scalar r2_a_within = e(r2_a_within) , replace 
		
	esttab ols_year reghdfe_fmyr,                             ///
            se(3)  star(* 0.10 ** 0.05 *** 0.01)  b(3)              ///
            stats(r2 r2_a r2_within r2_a_within N,               ///
                  fmt(%9.3f)                                   ///
                  labels("Rsqr"                           ///
                         "Adj. Rsqr"                     ///
                         "Within Rsqr"                         ///
                         "Within Adj. Rsqr"  ///
						 "Observations"))  replace                     ///
            title("R square and Within_R_square") ///
            mtitle("OLS" "FE")  , ///
            using "Rquare_WithinRsquare.csv"

			
			
*--------------------------------------------------------------------------------------------------

log using "ReplicateLog_PRL_Linear.smcl", replace

* Table:  Post-regulization LASSO linear regression
 
	* Define variables of interests
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"
	
	estimates clear

	poregress `innov_used' `rd_used' `ctrl', controls(i.PERMCO i.fyear) vce(cluster PERMCO) selection(bic, gridminok) rseed(1103)
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
	estimates store PRL
	
		*Output the Post-regulization LASSO linear table as *.csv file 
    esttab PRL, s(FirmFE YearFE N N_clust k_controls k_controls_sel) noconstant star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("PRL Linear Model Estimates") mtitle("PRL"), using "PRL_Linear_estimates.csv"	

log close


	
*--------------------------------------------------------------------------------------------------

log using "ReplicateLog_DML_Linear.smcl", replace

* Table:  Double Machine Learning 

	* Define variables of interests
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"
	
	estimates clear
   	xporegress `innov_used' `rd_used' `ctrl', controls(i.PERMCO i.fyear) vce(cluster PERMCO) xfolds(5) rseed(1103) selection(bic, gridminok) 
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
	estimates store DML
	
	*Output the Post-regulization LASSO linear table as *.csv file 
    esttab DML, s(FirmFE YearFE N N_clust k_controls k_controls_sel) noconstant  star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("DML Linear Model Estimates") mtitle("DML"), using "DML_Linear_estimates.csv"	
	
log close


	
********************************************************************************************************************
* Poisson model with and without FEs, PRL Poisson and DML Poisson
********************************************************************************************************************

*--------------------------------------------------------------------------------------------------------

log using "ReplicateLog_Poisson_FE.smcl", replace

* Table: Poisson regression and Fixed effect estimation 
	
	* Define variables of interests
	estimates clear
	local innov_used "npatent"
	local rd_used "RDAT"
	local ctrl "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"
		
	* Poisson with FEs
	ppmlhdfe `innov_used' `rd_used' `ctrl', absorb(i.PERMCO i.fyear) vce(cluster PERMCO) separation("none")
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
	estimates store ppml_fmyr
		
	* Poisson without FEs
	ppmlhdfe `innov_used' `rd_used' `ctrl' i.fyear, vce(cluster PERMCO) 
	estadd local FirmFE "no"
    estadd local YearFE "yes"
	estimates store ppml_yr
		
		
	*Output the Poiss ad Poisson_FEs table as *.csv file 
    esttab ppml_fmyr ppml_yr, s(FirmFE YearFE N) noconstant  star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("Poisson Model Estimates") mtitle("Poisson_FE" "Poisson"), using "Poisson_FE_estimates.csv"	  

log close

*--------------------------------------------------------------------------------------------------------

log using "ReplicateLog_PRL_Poisson.smcl", replace

* Table: Post-regulization Poisson regression

	* Define variables of interests
	estimates clear
	local innov_used "npatent"
	local rd_used "RDAT"
	local ctrl "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	* Post-regulization Poisson regression
	popoisson `innov_used' `rd_used' `ctrl', controls(i.PERMCO i.fyear)  lasso(`innov_used', selection(cv, fold(10) gridminok)) vce(cluster PERMCO) coef rseed(1234)

	estadd local FirmFE "yes"
    estadd local YearFE "yes"
	estimates store popoi_fmyr
	
	*Output the Post-regulization LASSO Poisson table as *.csv file 
    esttab popoi_fmyr, s(FirmFE YearFE N N_clust k_controls k_controls_sel) noconstant star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("PRL Poisson Model Estimates") mtitle("PRL_Poisson"), using "PRL_Poisson_estimates.csv"	

log close


*--------------------------------------------------------------------------------------------------------

log using "ReplicateLog_DML_Poisson.smcl", replace

* Table: Double machine Poisson regression

	* Define variables of interests
	estimates clear
	local innov_used "npatent"
	local rd_used "RDAT"
	local ctrl "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	* DML Poisson regression
	
	xpopoisson `innov_used' `rd_used' `ctrl', controls(i.PERMCO i.fyear)  lasso(`innov_used', selection(cv, fold(10) gridminok)) vce(cluster PERMCO) coef rseed(1234)  xfolds(5)

	estadd local FirmFE "yes"
    estadd local YearFE "yes"
	estimates store xpopoi_fmyr
  
	*Output the Post-regulization LASSO Poisson table as *.csv file 
    esttab xpopoi_fmyr, s(FirmFE YearFE N N_clust k_controls k_controls_sel) noconstant star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("DML Poisson Model Estimates") mtitle("DML_Poisson"), using "DML_Poisson_estimates.csv"		

log close





