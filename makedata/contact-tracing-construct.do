// Data construction for contact tracing analysis

  // Use all sample dates from ICMR
  use id_icmr date using "${box}/data/icmr.dta" , clear
    isid id_icmr
    tempfile date
      save `date'

  use "${box}/clean/contact-tracing.dta" , clear
    merge m:1 id_icmr using `date' , keep(1 3) nogen

  // Calculate generation and origin
  ren generation generation_raw
  gen generation = 0 if id_contact == .
    lab var generation "Generation"
  gen origin = "Nanded" if regexm(generation_raw,"N0")
    replace origin = "Local" if regexm(generation_raw,"NN0")
    replace origin = "Cross" if regexm(generation_raw,"X0")
    lab var origin "Origin"

  local remain = 1
  local generation = 0
  while `remain' != 0 {
    // Stop when all filled
    qui count if generation == .
    local remain = `r(N)'

    // Get matching IDs for current generation
    preserve
      keep if generation == `generation'
      keep id_tracing origin
      ren id_tracing id_contact
      tempfile a
      save `a'
    restore

    // Flag next generation
    local ++generation
      merge m:1 id_contact using `a' , update replace keep(1 3 4 5)
      replace generation = `generation' if _merge > 1
      drop _merge
  }

  // Calculcate numbers of contacts
  egen contacts = rsum(contacts_hi contacts_lo)
    lab var contacts "Contacts"
  egen contacts_pos = rsum(contacts_hi_pos contacts_lo_pos)
    lab var contacts_pos "Contacts Positive"
  egen contacts_traced = rsum(contacts_hi_traced contacts_lo_traced)
    lab var contacts_traced "Contacts Traced"

  // Calculate number of infecteds
  preserve
    keep if id_contact != .
    gen infected = 1
    collapse (sum) infected, by(id_contact)
      lab var infected "Number Infected"
    ren id_contact id_tracing
    tempfile infected
    save `infected'
  restore
  merge 1:1 id_tracing using `infected' , nogen
    replace infected = 0 if infected == .

  // Cleanup
  order * , seq
    order id_* , first
    isid id_tracing , sort
      order id_tracing , first
  compress

  // Save
  iecodebook export using "${box}/data/contact-tracing.xlsx" , save replace
  export delimited using "${box}/data/contact-tracing.csv" , replace nolabel

// End of dofile
