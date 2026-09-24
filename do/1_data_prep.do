************************************************************
* 1_data_prep.do
*
* Inputs : $datadir\acs_2010_2023_raw.dta  (from IPUMS, per spec)
* Output : $datadir\acs_latam_clean.dta
*
* Builds:
*   - sample: foreign-born from Latin America, age 18-64,
*     employed wage workers with positive wages
*   - yrs_educ: continuous years of schooling from EDUCD
*   - degree dummies (HS, AA, BA, MA+) for sheepskin
*   - exp = age - yrs_educ - 6 ; exp2 = exp^2
*   - hourly wage (real 2020 USD) = INCWAGE / (WKSWORK1 * UHRSWORK)
*   - country_birth: detailed Latin American country from BPLD
************************************************************

use "$datadir\acs_2010_2023_raw.dta", clear

* ============================================================
* SAMPLE RESTRICTIONS
* ============================================================

* Age 18-64
keep if inrange(age, 18, 64)

* Foreign-born from Latin America (BPL range covers Mexico/CentAm/Caribbean/SAm)
*   200      = Mexico
*   210-260  = Central America + Caribbean (Cuba, DR, etc.)
*   300-399  = South America
* Anyone in this BPL range is by definition foreign-born — BPL already
* identifies country of birth, so NATIVITY filter would be redundant.
* US-born (NATIVITY == 1 o BPL == 1)
* + Foreign-born from Latin America

* Keep USA-born + Latin America for comparison
keep if inrange(bpl, 1, 60) | bpl == 200 | inrange(bpl, 210, 399)


gen origin = ""
replace origin = "USA native" if inrange(bpl, 1, 60)
replace origin = "Mexico" if bpl == 200
replace origin = "Central America" if inrange(bpl, 210, 219)
replace origin = "Caribbean" if inrange(bpl, 250, 299)
replace origin = "South America" if inrange(bpl, 300, 399)

keep if origin != ""
* Employed wage/salary workers (CLASSWKR==2 = works for wages)
keep if empstat == 1
keep if classwkr == 2

* Drop missing key vars
drop if missing(incwage, age, educd, uhrswork, wkswork1)
drop if incwage <= 0
drop if uhrswork == 0 | wkswork1 == 0

* ============================================================
* YEARS OF SCHOOLING (mapping from EDUCD)
* Standard Jaeger (1997) mapping used in labor literature
* ============================================================

gen yrs_educ = .
replace yrs_educ = 0  if inlist(educd, 002, 011, 012)
replace yrs_educ = 1  if educd == 014
replace yrs_educ = 2  if educd == 015
replace yrs_educ = 3  if educd == 016
replace yrs_educ = 4  if inlist(educd, 013, 017)
replace yrs_educ = 5  if educd == 022
replace yrs_educ = 6  if educd == 023
replace yrs_educ = 7  if educd == 025
replace yrs_educ = 8  if inlist(educd, 024, 026)
replace yrs_educ = 9  if educd == 030
replace yrs_educ = 10 if educd == 040
replace yrs_educ = 11 if educd == 050
replace yrs_educ = 12 if inlist(educd, 061, 062, 063, 064)
replace yrs_educ = 13 if inlist(educd, 065, 070, 071)
replace yrs_educ = 14 if inlist(educd, 080, 081, 082, 083)
replace yrs_educ = 15 if educd == 090
replace yrs_educ = 16 if inlist(educd, 100, 101)
replace yrs_educ = 17 if inlist(educd, 110, 111, 112, 113)
replace yrs_educ = 18 if educd == 114
replace yrs_educ = 19 if educd == 115
replace yrs_educ = 20 if educd == 116

label var yrs_educ "Years of schooling"

* ============================================================
* DEGREE DUMMIES (sheepskin)
* ============================================================

gen hs_grad   = inlist(educd, 062, 063, 064) | inrange(educd, 065, 116)
gen some_coll = inrange(educd, 065, 083) | educd == 071 | educd == 070
gen aa_deg    = inlist(educd, 081, 082, 083)
gen ba_deg    = inrange(educd, 100, 116)
gen ma_plus   = inrange(educd, 114, 116)

label var hs_grad   "High school diploma or higher"
label var some_coll "Some college (no degree)"
label var aa_deg    "Associate's degree"
label var ba_deg    "Bachelor's degree or higher"
label var ma_plus   "Master's, professional, or doctoral"

* College indicator for the wage premium analysis
gen college = ba_deg
label var college "Bachelor's degree or higher"

* ============================================================
* POTENTIAL EXPERIENCE
* ============================================================

gen exp  = max(0, age - yrs_educ - 6)
gen exp2 = exp^2 / 100
label var exp  "Potential experience (years)"
label var exp2 "Experience squared / 100"

* ============================================================
* HOURLY WAGE (real 2020 USD)
* ============================================================

* Annual hours worked (UHRSWORK weekly × WKSWORK1)
gen ann_hours = uhrswork * wkswork1

* Nominal hourly wage
gen hwage_nom = incwage / ann_hours

* CPI-U All Items, annual averages, BLS base 1982-84=100
* Source: BLS series CUUR0000SA0
gen cpi = .
replace cpi = 218.056 if year == 2010
replace cpi = 224.939 if year == 2011
replace cpi = 229.594 if year == 2012
replace cpi = 232.957 if year == 2013
replace cpi = 236.736 if year == 2014
replace cpi = 237.017 if year == 2015
replace cpi = 240.007 if year == 2016
replace cpi = 245.120 if year == 2017
replace cpi = 251.107 if year == 2018
replace cpi = 255.657 if year == 2019
replace cpi = 258.811 if year == 2020
replace cpi = 270.970 if year == 2021
replace cpi = 292.655 if year == 2022
replace cpi = 304.702 if year == 2023

* Deflate to 2020 USD: real = nominal * (CPI_2020 / CPI_t)
gen hwage_real = hwage_nom * 258.811 / cpi

label var hwage_real "Hourly wage, 2020 USD"

* Trim implausible wages: <$2/hr or >$500/hr (BLS / Lemieux convention)
drop if hwage_real < 2 | hwage_real > 500

gen ln_hwage = ln(hwage_real)
label var ln_hwage "Log hourly wage (real 2020 USD)"

* ============================================================
* COUNTRY OF BIRTH (detailed Latin America)
* ============================================================

* Use BPLD for the detail
decode bpld, gen(country_birth)
label var country_birth "Country of birth (BPLD label)"

* ============================================================
* RESTRICT TO LATIN AMERICA (Hispanic + Brazil)
* Drop anglophone/francophone/Dutch Caribbean and the Guianas
* Note: BPLD labels in this extract appear in lowercase.
* CAREFUL: "dominica" (Lesser Antilles, anglophone) ≠ "dominican republic" (Hispanic)
* ============================================================

gen byte _drop_country = 0
local excl `" "barbados" "belize/british honduras" "belize" "bermuda" "bahamas" "antigua" "antigua-barbuda" "british virgin islands" "cayman islands" "dominica" "grenada" "guadeloupe" "guyana/british guiana" "guyana" "haiti" "jamaica" "martinique" "montserrat" "saint kitts-nevis" "saint kitts and nevis" "saint lucia" "saint vincent" "saint vincent and the grenadines" "suriname" "trinidad and tobago" "turks and caicos" "u.s. virgin islands" "us virgin islands" "aruba" "curacao" "netherlands antilles" "anguilla" "bonaire" "sint maarten" "saint barthelemy" "french guiana" "'

foreach c of local excl {
    replace _drop_country = 1 if lower(country_birth) == "`c'"
}
drop if _drop_country == 1
drop _drop_country

* Region groupings
gen region_birth = ""
replace region_birth = "Mexico"         if bpl == 200
replace region_birth = "Central America" if inrange(bpl, 210, 219)
replace region_birth = "Caribbean"       if inrange(bpl, 250, 299)
replace region_birth = "South America"   if inrange(bpl, 300, 399)

* ============================================================
* ADDITIONAL CONTROLS
* ============================================================

gen female      = sex == 2
gen married     = inlist(marst, 1, 2)
gen us_citizen  = inlist(citizen, 1, 2)
label var female       "Female"
label var married      "Currently married"
label var us_citizen   "US citizen (native or naturalized)"

* SPEAKENG: optional control — only build if variable was extracted
capture confirm variable speakeng
if !_rc {
    gen english_well = inlist(speakeng, 3, 4, 5)
    label var english_well "Speaks English well or better"
}
else {
    di as error "WARNING: SPEAKENG not in extract — english_well control omitted"
}

* YRIMMIG: years in US — optional
capture confirm variable yrimmig
if !_rc {
    gen yrs_in_us = year - yrimmig
    replace yrs_in_us = . if yrimmig == 0 | yrimmig > year
    label var yrs_in_us "Years since immigration"
}
else {
    di as error "WARNING: YRIMMIG not in extract — yrs_in_us omitted"
}

* ============================================================
* SAVE
* ============================================================

compress
save "$datadir\acs_latam_clean.dta", replace

di as result ""
di as result "================================================"
di as result "Sample size: " _N " person-year obs after cleaning"
di as result "================================================"
di as result ""
di as result "Countries retained (verify these are all Hispanic Latin America + Brazil):"
tab country_birth, sort
di as result ""
di as result "By region:"
tab region_birth
