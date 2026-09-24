************************************************************
* 3_college_premium.do (INTERACTION VERSION)
*
* Estimates college wage premium with INTERACTION by country.
* Tests if the return to college degree varies by country of birth.
*
* Specification (INTERACTION):
*   ln(hwage) = college#i.country_birth + exp + exp2/100
*               + female + married + english_well + i.year + e
*
* college#i.country_birth = college premium varies BY COUNTRY
* Each country gets its own college effect
************************************************************

* Standalone run: set paths from the repo root if master.do hasn't already
if "$project" == "" {
    global project    "`c(pwd)'"
    global dofiles    "$project\do"
    global datadir    "$project\data"
    global resultsdir "$project\results"
}

capture mkdir "$resultsdir"
capture mkdir "$resultsdir\tables"
capture mkdir "$resultsdir\figures"
capture mkdir "$resultsdir\logs"
use "$datadir\acs_latam_clean.dta", clear

* Restrict to at least HS grad
keep if hs_grad == 1

* BUILD CONTROL LIST
local controls female married
capture confirm variable english_well
if !_rc local controls `controls' english_well

di as result "Controls used: `controls'"
/*
* COLLAPSE USA STATES & ENCODE
replace country_birth = "USA" if inrange(bpl, 1, 60)
replace country_birth = proper(country_birth)
encode country_birth, gen(country_birth_cat)

di as result ""
di as result "Sample size (HS+): " _N " obs"
tab country_birth

* REGRESSION WITH INTERACTION: college x country
*/
levelsof country_birth_cat if country_birth == "Usa", local(usa_ref) clean

di as result ""
di as result "============================================"
di as result "College Premium by Country (Interaction Model)"
di as result "Reference: USA natives"
di as result "============================================"

reghdfe ln_hwage year some_coll aa_deg ba_deg college#ib(`usa_ref').country_birth_cat exp exp2 ///
    `controls' [pw=perwt], ///
    absorb(year) vce(robust)

eststo college_interaction
* ============================================================
* FIGURE: College premium by country (cleaned labels)
* ============================================================

* Mapeo de labels limpios
local coeflabels ///
    "1.college#2.country_birth_cat = Argentina" ///
    "1.college#3.country_birth_cat = Bolivia" ///
    "1.college#4.country_birth_cat = Brazil" ///
    "1.college#5.country_birth_cat = Chile" ///
    "1.college#6.country_birth_cat = Colombia" ///
    "1.college#8.country_birth_cat = Cuba" ///
    "1.college#9.country_birth_cat = Ecuador" ///
    "1.college#10.country_birth_cat = El Salvador" ///
    "1.college#11.country_birth_cat = Guatemala" ///
    "1.college#12.country_birth_cat = Honduras" ///
    "1.college#14.country_birth_cat = Mexico" ///
    "1.college#15.country_birth_cat = Nicaragua" ///
    "1.college#16.country_birth_cat = Panama" ///
    "1.college#17.country_birth_cat = Paraguay" ///
    "1.college#18.country_birth_cat = Peru" ///
    "1.college#21.country_birth_cat = Uruguay" ///
    "1.college#23.country_birth_cat = Venezuela"

coefplot, keep(1.college#2.country_birth_cat 1.college#3.country_birth_cat ///
    1.college#4.country_birth_cat 1.college#5.country_birth_cat ///
    1.college#6.country_birth_cat 1.college#8.country_birth_cat ///
    1.college#9.country_birth_cat 1.college#10.country_birth_cat ///
    1.college#11.country_birth_cat 1.college#12.country_birth_cat ///
    1.college#14.country_birth_cat 1.college#15.country_birth_cat ///
    1.college#16.country_birth_cat 1.college#17.country_birth_cat ///
    1.college#18.country_birth_cat 1.college#21.country_birth_cat ///
    1.college#23.country_birth_cat) ///
    sort ///
    ciopts(recast(rcap) lwidth(thick)) ///
    mcolor(maroon%60) msize(large) msymbol(D) ///
    xline(0, lpattern(dash) lcolor(gray)) ///
    xtitle("College degree premium (log points)") ytitle("") ///
    title("Return to college degree by country of birth", size(large)) ///
    subtitle("vs. US-born") ///
    coeflabels(`coeflabels') ///
    note("ACS 2010-2023. Sample: HS graduates or higher. Year FE. Robust SE.") ///
    graphregion(color(white))

graph export "$resultsdir\figures\college_premium_by_country.pdf", replace
di as result "✓ Figure saved: college_premium_by_country.pdf"
di as result ""
* EXPORT TABLE
esttab college_interaction using "$resultsdir\tables\college_premium.tex", ///
    replace booktabs ///
    keep(*college#*country_birth_cat exp exp2 `controls') ///
    cells(b(star fmt(4)) se(par fmt(4))) ///
    stats(N r2, fmt(0 3) labels("Observations" "R-squared")) ///
    title("College wage premium by country of birth") ///
    nonotes addnotes("ACS 2010-2023. Sample: HS graduates or higher." ///
        "Person-weighted (PERWT). Year FE. Robust SE.")

di as result "✓ Table saved: college_premium.tex"
di as result ""
di as result "College premium varies by country!"
di as result "Check figure for details."