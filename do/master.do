************************************************************
* MASTER.DO - LATAM WAGES ACS
*
* Purpose: Estimate returns to education and college wage premium
*          for Latin American immigrants in the US, by country of
*          birth, using ACS 2010-2023.
*
* Author: Andrés Ramasco
* Updated: May 2026
*
* Workflow:
*   1. Data preparation (sample, schooling years, wages)
*   2. Mincer returns to education by country (with sheepskin)
*   3. College wage premium by country
*
* Pre-requisite: download IPUMS extract per ipums_extract_spec.md
*                and place in data/acs_2010_2023_raw.dta
*
************************************************************

clear all
set more off
set maxvar 32000

* ============================================================
* REQUIRED USER-WRITTEN PACKAGES
* ============================================================
* Uncomment on first run:
* ssc install reghdfe, replace
* ssc install ftools,  replace
* ssc install estout,  replace
* ssc install labutil, replace   // for labmask in figures

* ============================================================
* GLOBAL PATHS
* ============================================================

* Run from the repo root (the folder that contains do/, data/, results/)
global project    "`c(pwd)'"
global dofiles    "$project\do"
global datadir    "$project\data"
global resultsdir "$project\results"

capture mkdir "$resultsdir"
capture mkdir "$resultsdir\tables"
capture mkdir "$resultsdir\figures"
capture mkdir "$resultsdir\logs"

* ============================================================
* LOG FILE
* ============================================================

local timestamp = c(current_date) + "_" + subinstr(c(current_time),":","-",.)
log using "$resultsdir\logs\master_run_`timestamp'.log", replace

di as result "========================================================"
di as result "LATAM WAGES ACS - MASTER RUN"
di as result "Started: $S_DATE $S_TIME"
di as result "========================================================"

* ============================================================
* STAGE 1: DATA PREPARATION
* ============================================================

di as result ""
di as result ">> STAGE 1: DATA PREP (sample, schooling years, wages)"
di as result "   Running: 1_data_prep.do"
di as result ""
do "$dofiles\1_data_prep.do"

* ============================================================
* STAGE 2: MINCER RETURNS TO EDUCATION BY COUNTRY
* ============================================================

di as result ""
di as result ">> STAGE 2: MINCER + SHEEPSKIN BY COUNTRY OF BIRTH"
di as result "   Running: 2_mincer_by_country.do"
di as result ""
do "$dofiles\2_mincer_by_country.do"

* ============================================================
* STAGE 3: COLLEGE WAGE PREMIUM BY COUNTRY
* ============================================================

di as result ""
di as result ">> STAGE 3: COLLEGE WAGE PREMIUM BY COUNTRY"
di as result "   Running: 3_college_premium.do"
di as result ""
do "$dofiles\3_college_premium.do"

* ============================================================
* END
* ============================================================

di as result ""
di as result "========================================================"
di as result "MASTER RUN COMPLETE"
di as result "Completed: $S_DATE $S_TIME"
di as result "========================================================"

log close
di as result "Log: $resultsdir\logs\master_run_`timestamp'.log"
