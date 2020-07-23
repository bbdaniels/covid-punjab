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
    (scatter pci contacts , mc(black)) ///
    (lowess pci contacts , lw(thick) lc(red)) ///
  , ylab(${pct}) xtit("Number of Contacts") ytit("Per-Contact Infection Rate")

// Figure. Contacts distribution logrank
use "${box}/data/contact-tracing.dta" ///
  if contacts > 0 & origin == "Local" , clear

  egen rank = rank(contacts)
  bys rank : gen j = _N
  tw /// (histogram rank , yaxis(2) fc(gs14) lc(none) width(10) gap(10)) ///
    (scatter contacts rank [pweight = j] , mfc(gray%50) mlc(black)) ///
    (function (1.008^(x+80)) , range(0 400) color(red)) ///
  ,  yscale(log axis(1))  ylab(1 5 25 125 625) /// ${hist_opts}
    xtit("Contact Rank of Traced Non-Nanded Cases") ytit("Number of Contacts (Log Scale)")

    graph export "${outputs}/logrank.png" , replace

  -

// Figure. PCI and contacts
use "${box}/data/contact-tracing.dta" , clear

  lowess pci contacts ///
    if origin != "Nanded" & contacts > 0






// End of dofile
