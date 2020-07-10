// Analytical code for Note 1: CFR

// Figure 1: CCFR by day

  // Get death counts by day
  use death_date using "${box}/clean/icmr.dta" ///
    if death_date != . , clear
    gen deaths = 1
    collapse (sum) deaths , by(death_date)
    ren death_date date

    tempfile death
      save `death'

  // Load in all positive cases by day
  use date_pos sample_result ///
    using "${box}/clean/icmr.dta" ///
    if sample_result == 3 , clear

    replace date_pos = subinstr(date_pos,"/20","/2020",.)
    replace date_pos = subinstr(date_pos,"/202020","/2020",.)
    gen date = date(date_pos,"DMY")
    keep date
    format date %tdNN/DD
    gen cases = 1
    collapse (sum) cases , by(date)

  // Calculate CCCFR
  merge 1:1 date using `death' , nogen

    tsset date
    tsfill
    replace cases = 0 if cases == .
    replace deaths = 0 if deaths == .
    sort date

    gen c_cases = sum(cases)
    gen c_deaths = sum(deaths)
    gen c_death_lag = F14.c_deaths
    gen c_case_lag = L14.c_cases
    gen cccfr = c_deaths/c_cases
    gen cccfr_lag = c_deaths/c_case_lag
      replace cccfr_lag = 1 if cccfr_lag > 1 & !missing(cccfr_lag)

  // Graph
  tw ///
    (bar c_cases date , yaxis(2) barw(0.9) fc(gs14) lc(none)) ///
    (bar c_deaths date , yaxis(2) barw(0.9) fc(red) lc(none)) ///
    (line cccfr date if cccfr < .15, lw(thick) lc(black)) ///
    (line cccfr_lag date if cccfr_lag < .15, lw(thick) lc(black) lp(dash)) ///
    if c_cases >= 100 ///
  , ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
    ytit(, axis(2)) ytit(, axis(1)) yscale( axis(2)) yscale(alt) ///
    xlab(,format(%tdMon_DD)) ///
    ylab(.05 "5%" .1 "10%" .15 "15%") ytit("") xtit("") ///
    legend(on order(1 "Cases to date" 3 "CCFR" 2 "Deaths to date" 4 "Lag CFR") c(2) ring(1) pos(12))

    graph export "${git}/outputs/1-cfr/figure.png", replace

// End of dofile
