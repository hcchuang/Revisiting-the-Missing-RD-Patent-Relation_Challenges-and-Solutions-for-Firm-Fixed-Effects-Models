capture program drop betweenr2
program define betweenr2, rclass
    /*------------------------------------------------------------
      betweenr2 — Post estimation helper for reghdfe  

      Purpose: Compute Between R²
	  
	  (i) First, computes the fitted values using the
    	  fixed-effects parameter vector and the within-individual 
		  means of the indepdenent variables.  
	  (ii) Then calculates the r-squared as the squared correlation 
	      between those predicted values and the within-individual means 
		  of the original y variable.
	  
      Program: 1) Use `predict ..., xb` to obtain the linear prediction
             that excludes absorbed fixed effects; 2) collapse Y and
             that prediction to group means; 3) square their
             correlation.

      ------------------------------------------------------------*/

    /* 1. Ensure last estimates come from reghdfe */
    if "`e(cmd)'" != "reghdfe" {
        di as err "betweenr2: last estimates are not from reghdfe"
        exit 301
    }

    /* 2. Identify key variables */
    local yvar   "`e(depvar)'"
    local gidvar : word 1 of `e(absvars)'
    if "`gidvar'" == "" {
        di as err "betweenr2: Could not detect grouping variable from absorb()"
        exit 198
    }

    /* 3. Generate linear predictions without FE */
    tempvar xb
    quietly predict double `xb', xb   // uses reghdfe's linear index

    /* 4. Collapse to group means and compute between R² */
    preserve
        quietly collapse (mean) `yvar' `xb', by(`gidvar')
        quietly corr `yvar' `xb'
        scalar __r2_between = r(rho)^2
    restore

    /* 5. Return and display */
    return scalar r2_between = __r2_between
    di as txt "Between R{sup:2} (group means) = " %9.4f __r2_between
	
end
