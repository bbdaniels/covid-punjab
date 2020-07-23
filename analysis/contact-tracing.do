// Analysis for contact tracing data

global outputs "${git}/outputs/contact-tracing"

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
    (scatter pci contacts , mc(black)) ///
    (lowess pci contacts , lw(thick) lc(red)) ///
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
    (lowess infected contacts , lw(thick) lc(red)) ///
    if contacts > 0 ///
  , ${xhist_opts} ytit("Total Infected") ///
    xscale(log) xlab(1 5 25 125 625) xtit("Number of Contacts (Log Scale)")

  graph export "${outputs}/pci-contacts.png" , replace

// Figure. Contacts distribution logrank
use "${box}/data/contact-tracing.dta" ///
  if contacts > 0 & origin == "Local" , clear

  egen rank = rank(contacts)
  bys rank : gen j = _N
  bys rank : keep if _n == 1
  tw /// (histogram rank , yaxis(2) fc(gs14) lc(none) width(10) gap(10)) ///
    (scatter contacts rank [pweight = j] , mfc(gray%50) mlc(black)) ///
    (function (1.008^(x+80)) , range(0 400) color(red)) ///
  ,  yscale(log axis(1))  ylab(1 5 25 125 625) /// ${hist_opts}
    xtit("Contact Rank of Traced Non-Nanded Cases") ytit("Number of Contacts (Log Scale)")

    graph export "${outputs}/logrank.png" , replace

// End of dofile
