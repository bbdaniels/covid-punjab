// Analysis for contact tracing data

global outputs "${git}/outputs/contact-tracing"

// Figure. Contacts distribution logrank
use "${box}/data/contact-tracing.dta" if contacts > 0 , clear




// Figure. Contacts distribution logrank
use "${box}/data/contact-tracing.dta" if contacts > 0 & origin == "Local" , clear

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
