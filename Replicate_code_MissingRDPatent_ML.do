*--------------------------------------------------------------------------------------------------
*　This is the example code for the paper:
*
* "Chuang, H.C., Hsu, P.H., Kuan, C.M., Yang, J.C., 2022. Throw the baby out with the bathwater: 
*       The missing RD-patent relation in firm fixed-effects models. Available at SSRN."
*
* In this set of code, we demonstrate how users can implement the following four ways for the potential bias from fixed effects regressions: 
*  (1) Within Between Variation: check if within-firm variation dominates between-firm variation or vice versa 
*  (2) Regression without firm FEs
*  (3) Hausman_Taylor_Estimates
*  (4) Post-regularization and DML LASSO methods (note that you may need to use STATA v17)
*
*
* All sample data and results are available on the GitHub repository 
* https://github.com/hcchuang/Missing-RD-Patent-in-Fixed-Effects-Models
*
* Please contact Po-Hsuan Hsu (pohsuanhsu@mx.nthu.edu.tw) or Hui-Ching Chuang (hcchuang@saturn.yzu.edu.tw) 
* for any questions regarding the data.
*
* This version: 2022/06/20
*
*--------------------------------------------------------------------------------------------------

clear all

log using "F:\Dropbox\RD_PATENT_FE\MissingRDPatent_ML\Replicate_log_MissingRDPatent_ML.smcl", replace

* Load the sample of 200 firms. 
* Remark: the PERMCO here is psuedo numbers for illustration purpose. 
use "F:\Dropbox\RD_PATENT_FE\MissingRDPatent_ML\Replicate_data_MissingRDPatent_ML.dta"

		
********************************************************************************************************************
* Linear model: POLS, HDFE, ost-regularization LASSO regression and double machine learning LASSO regression 
********************************************************************************************************************

*--------------------------------------------------------------------------------------------------
* Table 1: R&D-Innovation literature overview
  *No data involved

*--------------------------------------------------------------------------------------------------
* Table 2: Summary statistics and correlation

	* Define variables of interests (please change accordingly)
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	estimates clear

	tabstat `innov_used' `rd_used' `ctrl_w', statistics(mean, sd, min, p25, p50, p75,  max)
	corr `innov_used' `rd_used' `ctrl_w'

*--------------------------------------------------------------------------------------------------
* Table 3--8: OLS and Fixed effect estimation 

	* Define variables of interests (please change accordingly)
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	estimates clear
	
	* OLS
	reg `innov_used' `rd_used' `ctrl_w', vce(cluster PERMCO)
	estimates store OLS
	estadd local FirmFE "no"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"

	* Fixed Effect on firm, firm and year, firm and industry-trend(yearxindustry)
    reghdfe `innov_used' `rd_used' `ctrl_w' , absorb(i.PERMCO) vce(cluster PERMCO)
	estimates store OLSFE_firm
	estadd local FirmFE "yes"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"
	
	reghdfe `innov_used' `rd_used' `ctrl_w' , absorb(i.PERMCO i.fyear) vce(cluster PERMCO)
	estimates store OLSFE_firm_fyear
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "no"
	
	reghdfe `innov_used' `rd_used' `ctrl_w' , absorb(i.PERMCO i.fyear#i.sic3) vce(cluster PERMCO)
	estimates store OLSFE_firm_fyear2sic3
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "yes"
	
	*Output the OLS ad OLS_FEs table as *.csv file 
    esttab OLS OLSFE_firm OLSFE_firm_fyear OLSFE_firm_fyear2sic3, s(FirmFE YearFE YearxIndustryFE N) noconstant  star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("Fixed Effects Linear Model Estimates") mtitle("OLS" "OLSFE_firm" "OLSFE_firm_fyear" "OLSFE_firm_trend"), using "Fixed_Effects_Linear_Model_Estimates.csv"	  

	
*--------------------------------------------------------------------------------------------------
* Table 9: Within and between variations
    
    * STATA log file to save results
	log using Within_Between_Variation, smcl replace name(WithinBtwVariation)

	* Define variables of interests (please change accordingly)
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	
	* Declare data to be panel data
	xtset PERMCO fyear
	
	* Summarize xt data
    xtsum `innov_used' `rd_used' 	
	
	log close WithinBtwVariation
	 

*--------------------------------------------------------------------------------------------------
* Table 10--11: Adjusted Hausman-Taylor Estimates
	
	<to-be updated>
*--------------------------------------------------------------------------------------------------
* Table 12--17: Post-regularization LASSO linear regression
    
	* Define variables of interests (please change accordingly)
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	estimates clear

	* Post-regularization Linear Model Estimation
    qui poregress `innov_used' `rd_used' `ctrl_w', controls(i.PERMCO) vce(cluster PERMCO) 
	estimates store po_firm
	estadd local FirmFE "yes"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"
	
	qui poregress `innov_used' `rd_used' `ctrl_w', controls(i.PERMCO i.fyear) vce(cluster PERMCO) 
	estimates store po_firm_fyear
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "no"
	
	qui poregress `innov_used' `rd_used' `ctrl_w', controls(i.PERMCO i.fyear#i.sic3) vce(cluster PERMCO) 
	estimates store po_firm_fyear2sic3
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "yes"
	
	*Output the Post-regularization LASSO linear table as *.csv file 
    esttab po_firm po_firm_fyear po_firm_fyear2sic3, s(FirmFE YearFE YearxIndustryFE N N_clust k_controls k_controls_sel) noconstant star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("Post-regularization LASSO Linear Model Estimates") mtitle("Po_firm" "Po_firm_fyear" "Po_firm_trend"), using "Post_regularization_LASSO_Linear_Model_Estimates.csv"	

	
*--------------------------------------------------------------------------------------------------
* Table 12--17: Double Machine Learning LASSO linear regression
  *To save time, we set the cross-fit number (xfold) as 5 in this replicate code.
  
	* Define variables of interests (please change accordingly)
	local innov_used "lnnpatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	estimates clear

  * Double Machine Learning Linear Model Estimation
    qui xporegress `innov_used' `rd_used' `ctrl_w', controls(i.PERMCO) vce(cluster PERMCO) xfolds(5)
	estimates store xpo_firm
	estadd local FirmFE "yes"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"
	
	qui xporegress `innov_used' `rd_used' `ctrl_w', controls(i.PERMCO i.fyear) vce(cluster PERMCO) xfolds(5)
	estimates store xpo_firm_fyear
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "no"
	
	qui xporegress `innov_used' `rd_used' `ctrl_w', controls(i.PERMCO i.fyear#i.sic3) vce(cluster PERMCO) xfolds(5)
	estimates store xpo_firm_fyear2sic3
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "yes"
	
	*Output the DML LASSO linear table as *.csv file 
	esttab xpo_firm xpo_firm_fyear xpo_firm_fyear2sic3, s(FirmFE YearFE YearxIndustryFE N N_clust k_controls k_controls_sel) noconstant  star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("DML LASSO Linear Model Estimates") mtitle("DML_firm" "DML_firm_fyear" "DML_firm_trend"), using "DML_LASSO_Linear_Model_Estimates.csv"	
	

********************************************************************************************************************
* Poisson model
********************************************************************************************************************

*--------------------------------------------------------------------------------------------------------
* Table 18--21: Poisson regression and Fixed effect estimation 
	
	* Define variables of interests (please change accordingly)
	local innov_used "npatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	estimates clear
	
	* Poisson
	ppmlhdfe `innov_used' `rd_used' `ctrl_w', vce(cluster PERMCO) 
	estimates store poisson
	estadd local FirmFE "no"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"
		
	ppmlhdfe `innov_used' `rd_used' `ctrl_w', absorb(i.PERMCO) vce(cluster PERMCO) separation("none")
    estimates store ppml_firm
	estadd local FirmFE "yes"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"
		
	ppmlhdfe `innov_used' `rd_used' `ctrl_w', absorb(i.PERMCO i.fyear) vce(cluster PERMCO) separation("none")
	estimates store ppml_firmfyear
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "no"

	ppmlhdfe `innov_used' `rd_used' `ctrl_w', absorb(i.PERMCO i.fyear#i.sic3) vce(cluster PERMCO) separation("none")
	estimates store ppml_firmfyear2sic
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "yes"	
		
	*Output the Poisson ad Poisson_FEs table as *.csv file 
    esttab poisson ppml_firm ppml_firmfyear ppml_firmfyear2sic, s(FirmFE YearFE YearxIndustryFE N) noconstant  star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("Fixed Effects Poisson Model Estimates") mtitle("Poisson" "Poisson_firm" "Poisson_firm_fyear" "Poisson_firm_trend"), using "Fixed_Effects_Poisson_Model_Estimates.csv"	  


*--------------------------------------------------------------------------------------------------------
* Table 22--25: Post-regularization Poisson regression

	* Define variables of interests (please change accordingly)
	local innov_used "npatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	estimates clear

	* Post-regularization Poisson regression
	qui popoisson `innov_used' `rd_used' , controls(`ctrl_w' i.PERMCO) vce(cluster PERMCO) selection(cv, folds(10)) rseed(1234) coef
	estimates store po_poisso_firm
	estadd local FirmFE "yes"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"
	
	qui popoisson `innov_used' `rd_used' , controls(`ctrl_w' i.PERMCO i.fyear) vce(cluster PERMCO) selection(cv, folds(10)) rseed(1234) coef
	estimates store po_poisson_firm_fyear
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "no"
	
	qui popoisson `innov_used' `rd_used' , controls(`ctrl_w' i.PERMCO i.fyear#i.sic3) vce(cluster PERMCO) selection(cv, folds(10)) rseed(1234) coef
	estimates store po_poisson_firm_fyear2sic3
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "yes"

	*Output the Post-regularization LASSO Poisson table as *.csv file 
    esttab po_poisso_firm po_poisson_firm_fyear po_poisson_firm_fyear2sic3, s(FirmFE YearFE YearxIndustryFE N N_clust k_controls k_controls_sel) noconstant star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("Post-regularization LASSO Poisson Model Estimates") mtitle("POLPR_firm" "POLPR_firm_fyear" "POLPR_firm_trend"), using "Post_regularization_LASSO_Poisson_Model_Estimates.csv"	


*--------------------------------------------------------------------------------------------------------
* Table 22--25: Double machine learning Poisson
	*To save time, we set the cross-fit number (xfold) as 5 in this replicate code.

	* Define variables of interests
	estimates clear
	local innov_used "npatent"
	local rd_used "RDAT"
	local ctrl_w "lnME RD_missing lnAge lnK2L TobinQ ROA Leverage CASHAT KZidx  InstOwn oms_HHidx oms_HHidx_square"

	*  Double machine learning LASSO Poisson 
	qui xpopoisson `innov_used' `rd_used' , controls(`ctrl_w' i.PERMCO) vce(cluster PERMCO) selection(cv, folds(10)) xfolds(5) rseed(1234) coef
	estimates store xpo_poisso_firm
	estadd local FirmFE "yes"
    estadd local YearFE "no"
    estadd local YearxIndustryFE "no"
	
	qui xpopoisson `innov_used' `rd_used' , controls(`ctrl_w' i.PERMCO i.fyear) vce(cluster PERMCO) selection(cv, folds(10)) xfolds(5) rseed(1234) coef
	estimates store xpo_poisson_firm_fyear
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "no"
	
	qui xpopoisson `innov_used' `rd_used' , controls(`ctrl_w' i.PERMCO i.fyear#i.sic3) vce(cluster PERMCO) selection(cv, folds(10)) xfolds(5) rseed(1234) coef
	estimates store xpo_poisson_firm_fyear2sic3
	estadd local FirmFE "yes"
    estadd local YearFE "yes"
    estadd local YearxIndustryFE "yes"
  
	*Output the Double machine learning LASSO Poisson table as *.csv file 
    esttab xpo_poisso_firm xpo_poisson_firm_fyear xpo_poisson_firm_fyear2sic3, s(FirmFE YearFE YearxIndustryFE N N_clust k_controls k_controls_sel) noconstant star(* 0.10 ** 0.05 *** 0.01)  se(3) ar2 b(3) replace title("DML LASSO Poisson Model Estimates") mtitle("DML_firm" "DML_firm_fyear" "DML_firm_trend"), using "DML_LASSO_Poisson_Model_Estimates.csv"	



log close

