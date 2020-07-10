// Figure 2: by gender

  // Get death counts by day
  use death_date gender using "${box}/data/icmr.dta" ///
    if death_date != . & gender == "M" , clear

    gen deaths = 1
    collapse (sum) deaths , by(death_date)
    ren death_date date

    tempfile death
      save `death'

  // Load in all positive cases by day
  use date_pos sample_result gender ///
    using "${box}/data/icmr.dta" ///
    if sample_result == 3 & gender == "M", clear

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

    gen mc_cases = sum(cases)
    gen mc_deaths = sum(deaths)
    gen mc_death_lag = F14.mc_deaths
    gen mc_case_lag = L14.mc_cases
    gen mcccfr = mc_deaths/mc_cases
    gen mcccfr_lag = mc_deaths/mc_case_lag
      replace mcccfr_lag = 1 if mcccfr_lag > 1 & !missing(mcccfr_lag)

      tempfile male
      save `male'

  // Women
  use death_date gender using "${datadir}/clean/icmr.dta" ///
    if death_date != . & gender == "F" , clear

    gen deaths = 1
    collapse (sum) deaths , by(death_date)
    ren death_date date

    tempfile death
      save `death'

  // Load in all positive cases by day
  use date_pos sample_result gender ///
    using "${box}/data/icmr.dta" ///
    if sample_result == 3 & gender == "F", clear

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

    gen fc_cases = sum(cases)
    gen fc_deaths = sum(deaths)
    gen fc_death_lag = F14.fc_deaths
    gen fc_case_lag = L14.fc_cases
    gen fcccfr = fc_deaths/fc_cases
    gen fcccfr_lag = fc_deaths/fc_case_lag
      replace fcccfr_lag = 1 if fcccfr_lag > 1 & !missing(fcccfr_lag)

      merge 1:1 date using `male'

  gen c_cases = fc_cases + mc_cases
  gen c_deaths = fc_deaths + mc_deaths
    // Graph
    tw ///
      (bar c_cases date , yaxis(2) barw(0.9) fc(gs14) lc(none)) ///
      (bar c_deaths date , yaxis(2) barw(0.9) fc(red) lc(none)) ///
      (line mcccfr date if mcccfr < .15, lc(red) ) ///
      (line fcccfr date if fcccfr < .15, lc(black) ) ///
      if c_cases >= 100 & c_cases != . ///
    , ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
      ytit(, axis(2)) ytit(, axis(1)) yscale( axis(2)) yscale(alt) ///
      xlab(,format(%tdMon_DD)) ///
      ylab(.05 "5%" .1 "10%" .15 "15%") ytit("") xtit("") ///
      legend(on order(1 "Cases to date" 3 "CCFR (Men)" 2 "Deaths to date" 4 "CCFR (Women)") c(2) ring(1) pos(12))

      graph export "${git}/outputs/1-cfr/figure-gender.png", replace
