// Master file for COVID Punjab research notes

// Set global file path

  global box "/Users/bbdaniels/Box/covid-punjab"
  global git "/Users/bbdaniels/github/covid-punjab"

// Set ado-path

  sysdir set PLUS "${directory}/ado/"

// Install packages

  net from "https://github.com/worldbank/iefieldkit/raw/feature/iecodebook-export-verify/src/"
    net install iefieldkit , replace
  // ssc install iefieldkit

// Globals

  global pct `" 0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%" "'

  global hist_opts ylab(, angle(0) axis(2)) yscale(noline alt axis(2)) ///
    ytit(, axis(2)) ytit(, axis(1)) yscale(off axis(2)) yscale(alt)

// Do cleaning and data construction

  global icmr_updated = 0
  run "${git}/makedata/icmr-cleaning.do"
  run "${git}/makedata/contact-tracing-cleaning.do"
  run "${git}/makedata/icmr-construct.do"
  run "${git}/makedata/contact-tracing-construct.do"

// End of dofile
