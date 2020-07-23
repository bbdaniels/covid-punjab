
use "${box}/clean/icmr.dta" , clear

// Age categorical
  egen agecat = cut(age) , at(0 10 20 30 40 50 60 70 80 90 150) icodes
  lab def agecat 0 "0-9" ///
     1 "10-19" ///
     2 "20-29" ///
     3 "30-39" ///
     4 "40-49" ///
     5 "50-59" ///
     6 "60-69" ///
     7 "70-79" ///
     8 "80-89" ///
     9 "90+"
  lab val agecat agecat

// Gender
  gen woman = gender == "F"
    lab var woman "Woman"

// Comorbidities
  gen comorbid = conditions != ""
    lab var comorbid "Underlying Conditions"

// Test results
  gen positive = sample_result == 3
    lab var positive "Covid Positive"

// Symptomatic
  gen asymptomatic = symptom_status == 1 if !missing(symptom_status)
    lab var asymptomatic "Asymptomatic"

  gen symptomatic = symptom_status == 2 if !missing(symptom_status)
    lab var symptomatic "Symptomatic"

// Dates
  replace date_sample = subinstr(date_sample,"/20","/2020",.)
  replace date_sample = subinstr(date_sample,"/202020","/2020",.)
  gen date = date(date_sample,"DMY")
    lab var date "Sample Date"
    format date %tdNN/DD

// Subsamples
  gen touse_result = inlist(sample_result,2,3)
    lab var touse_result "Has Test Result"

// Save

save "${box}/data/icmr.dta" , replace
export delimited using "${box}/data/icmr.csv" , replace nolabel
iecodebook export using "${box}/data/icmr.xlsx" , replace
