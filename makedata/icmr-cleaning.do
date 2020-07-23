// Data cleaning for Death Audit

  import excel "${box}/raw/death_cases_line_DeID.xlsx" ///
     , first clear

   ren ICMRID id_icmr
   ren DateofOutcome death_date
   keep id_icmr death_date
   drop if id_icmr == .

  // iecodebook apply using "${datadir}/meta/Death_original.xlsx"

  tempfile death
    save `death'

// Data cleaning for ICMR

  // Create dta version of initial data. Run only if xlsx updated.
  if ${icmr_updated} == 1 {
    import delimited "${git}/raw/icmr.csv" ///
      ,  clear

    save "${box}/raw/icmr.dta" , replace
  }

  // Load dta version and apply variable naming and labelling

    use "${box}/raw/icmr.dta" , clear
    iecodebook apply using "${git}/meta/icmr.xlsx"

  // Merge death data

    merge 1:1 id_icmr using `death'

    gen death = _merge != 1
      label def death 0 "Alive" 1 "Died"
      lab val death death
      lab var death "Death"
      note death: "Defined as matched to death audit"

      drop _merge

  // Cleaning of strings and variable encoding
    // Note that everything from here depends on string coding!
    // If the list of strings changes category codes MUST be updated.
    // Refer to the codebook accompanying the data.

    qui foreach var of varlist * {
      local type : type `var'
      if regexm("`type'","str") replace `var' = trim(itrim(`var'))
    }

    foreach var of varlist ///
      district quarantine quarantine_loc travel sari ili ///
      healthcare hosp symptom_status testing_kit egene rdrp orf1b repeat ///
      sample_result /* recoded_patient_category gop_code */ {

      ren `var' `var'_raw
      encode `var'_raw , gen(`var')

    }
/*
  // Cleaning of symptom status

    // Step 1 – all blanks in the “symptoms.status” field with symptoms in the “symptoms” field to Symptomatic
    replace symptom_status = 2 if (symptom_status == . & symptoms != "")

    // Step 2 – all yes in the “Respiratory.Infection.Influenza.like.illness” field and blanks in the “symptoms.status” field to Symptomatic
    // Redundant with 3
    // replace symptom_status = 2 if (symptom_status == . & ili == 2)

    // Step 3 - all yes to ILI and Asymptomatic to Symptomatic
    replace symptom_status = 2 if ili == 2

    // Step 4 all yes to SARI and blanks to Symptomatic – 12
    // Redudant with 5
    // replace symptom_status = 2 if (symptom_status == . & sari == 2)

    // Step 5 all yes to SARI and Asymptomatic to Symptomatic
    replace symptom_status = 2 if sari == 2

    // Step 6 + 7 All Cat 1 Cat 2, Cate 3, Cat4 and Cat 6 [and blank] to Symptomatic
    // Assuming to use " recoded_patient_category " here
    replace symptom_status = 2 if inlist(recoded_patient_category,1,2,3,4,7)

    // Step 8 Illness in Contact tracing and blank to Symptomatic
    // Step 9 Illness in Contact tracing and Asymptomatic to Symptomatic

    // Step 10 All Cat 5a Cat 5b, and blank to Asymptomatic
    replace symptom_status = 1 if inlist(recoded_patient_category,5,6)

    // Step 10 All Cat 5a Cat 5b, and Symptomatic to Cat2 (all recorded symptoms in the symptoms field)
    // This cannot have any effect if implemented after the previous step since 5a/5b have just been redefined Asymptomatic

    // Step 11 All non-contacts in Contact Tracing and Cat2 Cat5a in contacts to be changed “others” or appropriate
    // ???
*/
  // Save

    qui compress
    save "${box}/clean/icmr.dta" , replace
    export delimited using "${box}/clean/icmr.csv" , replace nolabel
    iecodebook export using "${box}/clean/icmr.xlsx" , replace

// End of dofile
