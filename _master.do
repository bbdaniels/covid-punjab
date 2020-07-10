// Master file for COVID Punjab research notes

// Set global file path

  global datadir "/Users/bbdaniels/Box/covid-punjab"
  global directory "/Users/bbdaniels/github/covid-punjab"

// Set ado-path

  sysdir set PLUS "${directory}/ado/"

// Install packages

  ssc install iefieldkit

// Globals

  global pct `" 0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%" "'

  global hist_opts ylab(, angle(0) axis(2)) yscale(noline alt axis(2)) ///
    ytit(, axis(2)) ytit(, axis(1)) yscale(off axis(2)) yscale(alt)

// Do cleaning and data construction

  global icmr_updated = 0
  global icmr_name "ICMR_Punjab_new_appended_23Marchto28June_dedup_deid.xlsx"
  run "${datadir}/makedata/cleaning.do"
  run "${datadir}/makedata/construct.do"

// End of dofile
