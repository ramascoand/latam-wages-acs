* ============================================================
* COLLAPSE USA STATES & PREPARE FOR ANALYSIS
* ============================================================

replace country_birth = "USA" if inrange(bpl, 1, 60)

* Capitalizar nombres
replace country_birth = proper(country_birth)

* Encode UNA SOLA VEZ
encode country_birth, gen(country_birth_cat)

di as result ""
di as result "Sample: " _N " obs"
di as result "Countries included:"
tab country_birth

* ============================================================
* MAIN POOLED REGRESSION
* ============================================================

levelsof country_birth_cat if country_birth == "Usa", local(usa_ref) clean

di as result ""
di as result "USA reference code: `usa_ref'"
di as result "============================================"
di as result "Estimating POOLED Mincer"
di as result "Reference: USA natives"
di as result "============================================"

reghdfe ln_hwage yrs_educ exp exp2 ///
    hs_grad aa_deg ba_deg ma_plus ///
    ib(`usa_ref').country_birth_cat ///
    female married english_well [pw=perwt], ///
    absorb(year) vce(robust)

eststo pooled_model

* ============================================================
* FIGURE: Country wage gaps
* ============================================================

coefplot, keep(*country_birth_cat) sort ///
    ciopts(recast(rcap) lwidth(thick)) ///
    mcolor(navy%60) msize(large) msymbol(D) ///
    xline(0, lpattern(dash) lcolor(gray)) ///
    xtitle("Log wage gap relative to USA natives") ytitle("") ///
    title("Wage premium by country of birth", size(large)) ///
    note("ACS 2010-2023. Log hourly wage in 2020 USD. Year FE. Robust SE.") ///
    graphregion(color(white))

graph export "$resultsdir\figures\country_fixed_effects.pdf", replace

di as result "✓ Figure saved: country_fixed_effects.pdf"
di as result ""

* ============================================================
* EXPORT TABLE
* ============================================================

esttab pooled_model using "$resultsdir\tables\mincer_pooled.tex", ///
    replace booktabs ///
    keep(yrs_educ hs_grad aa_deg ba_deg ma_plus exp exp2) ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    title("Pooled Mincer earnings regression: Latin American immigrants") ///
    nonotes addnotes("ACS 2010-2023. Log hourly wage in 2020 USD." ///
        "Person-weighted (PERWT). Year FE. Robust SE." ///
        "Reference category: USA natives.")

di as result "✓ Table saved: mincer_pooled.tex"
di as result ""
di as result "============================================"
di as result "MAIN RESULTS:"
di as result "============================================"
di as result "Return to 1 year of education: " %6.4f _b[yrs_educ] " log points"
di as result "High school diploma premium: " %6.4f _b[hs_grad] " log points"
di as result "Bachelor's degree premium: " %6.4f _b[ba_deg] " log points"
di as result "============================================"