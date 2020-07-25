// Analysis for contact tracing data

global outputs "${git}/outputs/contact-tracing"

// Table. Transmission.
use "${box}/data/contact-tracing.dta" ///
  if origin == "Local" , clear

  gen inf = infected > 0
  gen con = contacts > 0
  replace con = 1 if inf > 0
  egen check = group(inf con) , label

  table generation check ///
  , c(freq sum contacts sum infected) ///
    replace

// Figure. Infection CDF.
use "${box}/data/contact-tracing.dta" ///
  if origin == "Local" , clear

  sort infected

  gen inf_running = sum(infected)
  egen inf_total = sum(infected)
  gen cdf = inf_running / inf_total
  gen inf = infected > 0
  gen tot = _n/_N
  bys inf : gen tot2 = _n/_N

  replace tot = 1-tot
  replace tot2 = 1-tot2
  replace cdf = 1 - cdf

  tw ///
    (function x , lp(dash) lc(gs14)) ///
    (line cdf tot , lc(black) lw(thick)) ///
    (line cdf tot2 if inf == 1 , lc(red) lw(thick)) ///
  , ylab(${pct}) xlab(${pct} .05 "5%" .143 "14%" .37 "37%") xtit("Share of Cases/Infectors") ytit("Share of New Infections") ///
    xline(0.05 .143 .370, lc(gs14)) yline(.25 .50 .75 , lc(gs14)) ///
    legend(on pos(4) ring(0) c(1) order(2 "All Cases" 3 "Infectors"))

    graph export "${outputs}/transmission-cdf.png" , replace

// Figure. Cases over time
use "${box}/data/contact-tracing.dta" ///
  if origin == "Local" , clear

  set seed 123456
  replace date = date + rnormal()
  replace contacts = contacts + abs(rnormal()/9)


  keep id_contact contacts date
  keep if id_contact != .
    ren (contacts date) (contacts2 date2)
    ren id_contact id_tracing

    tempfile contacts
    save `contacts'

use "${box}/data/contact-tracing.dta" ///
  if origin == "Local" , clear

  set seed 123456
  replace date = date + rnormal()
  replace contacts = contacts + abs(rnormal()/9)

  merge 1:m id_tracing using `contacts' , nogen
  replace contacts2 = contacts2 + 1
  replace contacts = contacts + 1

  tw ///
  (lowess contacts date , lc(red) lw(thick))  ///
  (pcarrow contacts date contacts2 date2 if contacts > 0 ///
    , lw(thin) lc(gs14) mc(none) mlw(thin)) ///
  (pcarrow contacts date contacts2 date2 if contacts > 0 ///
    & contacts2 > contacts ///
    , lw(thin) lc(red) mc(none) mlw(thin)) ///
  (scatter contacts date if generation != 0 & contacts > 1 ///
    , mlw(vthin) mlc(none)  mc(gs3))  ///
  (scatter contacts date if generation != 0 & contacts == 1 ///
    , mlw(vthin) mlc(none)  mc(gs3))  ///
  (scatter contacts date if generation == 0 & contacts > 0 ///
    , mlw(vthin) mlc(black) mc(red))  ///
   ///
  , yscale(log) ylab(1 5 25 125 625)  ///
    xtit("Date Sample Taken") ytit("Number of Contacts (Log Scale)") ///
    legend(on size(small) pos(11) r(3) order(1 "Average Contacts" ///
      0 "" 6 "Seed Case" 2 "Transmission" ///
      5 "Contact Case" 3 "Transmission to More Central Contact"))

    graph export "${outputs}/transmission-map.png" , replace

// Figure. Cases over time

use "${box}/data/contact-tracing.dta"  , clear

  merge m:1 id_icmr using "${box}/data/icmr.dta" , keepusing(date positive)
  keep if positive == 1

  gen tracing = _merge != 2
  gen nanded = origin != "Local" & _merge != 2

  keep date positive tracing nanded
  collapse (sum) tracing nanded (count) n = positive, by(date)

  tsset date

  qui su date
  drop if `r(max)' - date < 7

  gen nc = sum(n)

  tw ///
    (bar n date , yaxis(2) barw(0.9) fc(gs14) lc(none)) ///
    (bar tracing date , yaxis(2) barw(0.9) fc(red) lc(none)) ///
    (bar nanded date , yaxis(2) barw(0.9) fc(black) lc(none)) ///
  , legend(on c(1) ring(0) pos(11) ///
    order(1 "All Positive" 2 "Contact Tracing" 3 "Nanded Cases")) ///
    xtit("Date Sample Taken")

    graph export "${outputs}/tracing-total.png" , replace

// Figure. Contacts distribution
use "${box}/data/contact-tracing.dta" ///
  if contacts > 0 & origin == "Local" , clear

  tw histogram contacts , frac fc(gs14) lc(none) width(10) gap(10) ///
    ylab(0 "0% ".1 "10%" .2 "20%" .3 "30%" .4 "40%" .5 "50%") ///
    xtit("Number of Contacts") ytit("Share of Population")

  graph export "${outputs}/hist-contacts.png" , replace


// Figure. PCI distribution nonzeros
use "${box}/data/contact-tracing.dta" ///
  if pci > 0 & origin == "Local" , clear

  tw ///
    (histogram pci , hor xaxis(2) fc(gs14) w(.1) lc(none) gap(10)) ///
    (lowess pci contacts , lw(thick) lc(red)) ///
    (scatter pci contacts , mc(black) jitter(10)) ///
    if contacts > 0 ///
  , ${xhist_opts} ylab(${pct}) ytit("Per-Contact Infection Rate") ///
    xscale(log) xlab(1 5 25 125 625) xtit("Number of Contacts (Log Scale)")

  graph export "${outputs}/pci-contacts.png" , replace

// Figure. Infections distribution nonzeros
use "${box}/data/contact-tracing.dta" ///
  if contacts > 0 & origin == "Local" , clear

  tw ///
    (histogram infected , hor xaxis(2) fc(gs14) w(1) lc(none) gap(10)) ///
    (scatter infected contacts , msize(*2) mlc(none) mfc(black%50) jitter(5) ) ///
    (lowess infected contacts , lw(thick) lc(maroon)) ///
    (lowess infected contacts if infected > 0 , lw(thick) lc(red)) ///
    if contacts > 0 & infected < 30 ///
  , ${xhist_opts} ytit("Total Infected") ///
    yline(1 2 3 4 5 6 7 8 9 10 , lc(gs14)) ///
    legend(on pos(11) ring(0) c(1) ///
      order(3 "Average" 4 "Average ex. zero infectors")) ///
    xscale(log) xlab(1 5 25 125 625) xtit("Number of Contacts (Log Scale)")

  graph export "${outputs}/infected-contacts.png" , replace

// Figure. Contacts distribution logrank
use "${box}/data/contact-tracing.dta" ///
  if contacts > 0 & origin == "Local" , clear

  egen rank = rank(contacts)
  bys rank : gen j = _N
  bys rank : keep if _n == 1
  tw /// (histogram rank , yaxis(2) fc(gs14) lc(none) width(10) gap(10)) ///
    (scatter contacts rank [pweight = j] , mfc(gray%50) mlc(black)) ///
    (function (1.0065^(x+110)) , range(0 400) color(red)) ///
  ,  yscale(log axis(1))  ylab(1 5 25 125 625) /// ${hist_opts}
    xtit("Contact Rank of Traced Non-Nanded Cases") ytit("Number of Contacts (Log Scale)")

    graph export "${outputs}/logrank.png" , replace

// End of dofile
