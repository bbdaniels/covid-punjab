// Data cleaning and validation for contact tracing

  import delimited "${git}/raw/contact-tracing.csv" , clear

  iecodebook apply using "${git}/meta/contact-tracing.xlsx" , drop

  // Cleaning

    destring id_icmr , force replace // NOTE: several duplicates here
    keep if id_icmr != .

    drop if id_tracing == .
    replace district = trim(district)
    destring age, force replace
      replace age = floor(age)
    gen woman = gender == "F"
      lab var woman "Woman"
    replace id_contact = . if id_contact == 0
      replace type_clean = "Case" if id_contact == .
      replace type_clean = "Contact" if id_contact != .
      encode type_clean , gen(type)

  // Cleanup
  order * , seq
    order id_* , first
    isid id_tracing , sort
      order id_tracing , first
  compress

  iecodebook export using "${box}/clean/contact-tracing.xlsx" , save replace verify
  export delimited using "${box}/clean/contact-tracing.csv" , replace

// End of dofile
