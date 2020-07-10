// Asymptomatic vs symptomatic positivity

// Category stuff
use "${datadir}/data/icmr.dta" if touse_result == 1 , clear

betterbarci positive , by(recoded_patient_category) barlab pct xoverhang ///
  xlab(.02 "2%" .04 "4%" .06 "6%" .08 "8%" .1 "10%")

  graph export  "${directory}/misc/categories.png"  , replace

// Grouping statistics
use "${datadir}/data/icmr.dta" if touse_result == 1 , clear

  gen touse = inlist(sample_result,2,3)
  keep if touse == 1

  graph bar (count) positive if gender != "T" ///
  , over(asymptomatic) over(gender) over(agecat) ///
    legend(on c(1) ring(0) pos(1) order(1 "Symptomatic" 2 "Asymptomatic")) ///
    bar(2, fc(black)) bar(1, fc(red)) ytit("Number Tested")

  graph export  "${directory}/2-asymptomatics/asymp-test.png"  , replace

  graph bar positive if gender != "T" ///
  , over(asymptomatic) over(gender) over(agecat) ///
    legend(on c(1) ring(0) pos(11) order(1 "Symptomatic" 2 "Asymptomatic")) ///
    bar(2, fc(black)) bar(1, fc(red)) ///
    ylab(0 "0%" .05 "5%" .1 "10%") ytit("Share Positive")

  graph export  "${directory}/2-asymptomatics/asymp-pos.png"  , replace

// Asymptomatic vs symptomatic positivity over time
use "${datadir}/data/icmr.dta" if touse_result == 1 , clear

  keep date positive asymptomatic age
  collapse (mean) positive age (count) n = positive, by(date asymptomatic)

  tsset asymptomatic date

  qui su date
  drop if `r(max)' - date < 7

  gen ma3 = (L2.positive + L1.positive + positive) / 3
  gen nc = sum(n)

  tw ///
    (bar n date , yaxis(2) barw(0.9) fc(gs14) lc(none)) ///
    (line ma3 date if asymptomatic == 1 , lc(black)) ///
    (line ma3 date if asymptomatic == 0 , lc(red)) ///
    (scatter positive date if asymptomatic == 1 , mc(black)) ///
    (scatter positive date if asymptomatic == 0 , mc(red)) ///
  if positive < 0.3 & ma3 < 0.2 & nc > 100 ///
  , ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
    ytit("", axis(2)) ytit("", axis(1)) yscale( axis(2)) yscale(alt) ///
    legend(on order(2 "Asymptomatic" 3 "Symptomatic") c(1) ring(0) pos(11)) ///
    xlab(`=date("1 Mar 2020","DMY")' ///
      `=date("1 Apr 2020","DMY")' ///
      `=date("1 May 2020","DMY")' ///
      `=date("1 Jun 2020","DMY")' ///
      ,format(%tdMon)) xtit("") ///
    ylab(0 "0%" .05 "5%" .1 "10%" .15 "15%")


  graph export  "${directory}/2-asymptomatics/asymp-pos-time.png"  , replace

// Asymptomatic vs symptomatic CONDITIONAL ON positivity over time
use "${datadir}/data/icmr.dta" if touse_result == 1 , clear

  keep date positive symptomatic age
  collapse (mean) symptomatic age (count) n = symptomatic, by(date positive)

  qui su date
  drop if `r(max)' - date < 7

  tsset positive date

  gen ma3 = (L2.symptomatic + L1.symptomatic + symptomatic) / 3
  gen nc = sum(n)

  tw ///
    (bar n date , yaxis(2) barw(0.9) fc(gs14) lc(none)) ///
    (line ma3 date if positive == 0 , lc(black)) ///
    (line ma3 date if positive == 1 , lc(red)) ///
    (scatter symptomatic date if positive == 0 , mc(black)) ///
    (scatter symptomatic date if positive == 1 , mc(red)) ///
  if nc > 100 ///
  , ylab(, angle(0) axis(2)) yscale( alt axis(2)) ///
    ytit("", axis(2)) ytit("", axis(1)) yscale( axis(2)) yscale(alt) ///
    legend(on order(0 "Share Symptomatic if:" 2 "Negative" 3 "Positive") r(1) ring(1) pos(11)) ///
    xlab(`=date("1 Mar 2020","DMY")' ///
      `=date("1 Apr 2020","DMY")' ///
      `=date("1 May 2020","DMY")' ///
      `=date("1 Jun 2020","DMY")' ///
      ,format(%tdMonth)) xtit("") ylab(${pct})

  graph export  "${directory}/2-asymptomatics/pos-asymp-time.png"  , replace

// End of dofile
