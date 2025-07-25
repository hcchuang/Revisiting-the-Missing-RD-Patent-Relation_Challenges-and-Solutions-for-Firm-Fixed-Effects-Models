/**********************************************************************
*  panelr2.ado  —  Overall / Between / Within  R² after any estimator
*
*  Syntax
*     panelr2 , id(varname) [depvar(string)]
*
*  Returned scalars  (in r())
*     r(overall)   overall  R²  = ρ²(y , ŷ)
*     r(between)   between  R²  = ρ²(ȳ_i· , ŷ̄_i·)   (one row per group)
*     r(within)    within   R²  = ρ²(y_it−ȳ_i· , ŷ_it−ŷ̄_i·)
*  
*
* Hui-Ching Chuang 2025/07/24
**********************************************************************/

program define panelr2, rclass

    version 17
    syntax , id(varname) [depvar(string)]
    if ("`depvar'"=="") local depvar `e(depvar)'

    /* ---- temporary working variables ---- */
    tempvar yhat ybar yhatbar tag y_within yhat_within

    quietly {
        /* linear prediction */
        predict double `yhat', xb

        /* group means */
        bys `id': egen double `ybar'     = mean(`depvar')
        bys `id': egen double `yhatbar'  = mean(`yhat')

        /* -------- overall R² -------- */
        corr `depvar' `yhat'
        scalar R2_overall = r(rho)^2

        /* -------- between R² (***one obs per group! ) -------- */
        egen byte `tag' = tag(`id')
        corr `ybar' `yhatbar' if `tag'
        scalar R2_between = r(rho)^2

        /* -------- within R² -------- */
        gen double `y_within'     = `depvar' - `ybar'
        gen double `yhat_within'  = `yhat'   - `yhatbar'
        corr `y_within' `yhat_within'
        scalar R2_within  = r(rho)^2
    }

    /* store results in r() AFTER all corr commands */
    return scalar overall  = R2_overall
    return scalar between = R2_between
    return scalar within  = R2_within

    /* nice display */
    di as txt "Overall  R^2 = " %9.4f R2_overall
    di as txt "Between R^2 = " %9.4f R2_between
    di as txt "Within  R^2 = " %9.4f R2_within
end
