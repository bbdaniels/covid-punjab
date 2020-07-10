
/* Table 1
  presents each of these three measures for four different age-groups
  for the states of Maharashtra and Punjab.
  In addition, Columns X and Y present comparisons to age-specific mortality rates
  from Italy and China. Discuss the results in the table.
  We emphasize that if age-specific case-fatality rates
  in Maharashtra/Punjab had been identical to those in Italy,
  we would have seen XXX/YY (MM/NN%) fewer deaths over the duration of these data.
*/

// Table: CCFR by age
use "${datadir}/data/icmr.dta" , clear
table agecat if positive == 1 , c( mean death) format(%9.3f)
ta agecat if positive == 1
  /*
-------------------------------------------------
   agecat | mean(death)   sum(death)        Freq.
----------+--------------------------------------
      0-9 |       0.018        3.000      166.000
    10-19 |       0.000        0.000      333.000
    20-29 |       0.001        1.000      734.000
    30-39 |       0.004        3.000      792.000
    40-49 |       0.010        6.000      600.000
    50-59 |       0.022       13.000      585.000
    60-69 |       0.026       13.000      493.000
    70-79 |       0.025        4.000      163.000
    80-89 |       0.061        2.000       33.000
      90+ |       0.143        1.000        7.000
-------------------------------------------------

     agecat |      Freq.     Percent        Cum.
------------+-----------------------------------
        0-9 |        166        4.25        4.25
      10-19 |        333        8.53       12.78
      20-29 |        734       18.79       31.57
      30-39 |        792       20.28       51.84
      40-49 |        600       15.36       67.20
      50-59 |        585       14.98       82.18
      60-69 |        493       12.62       94.80
      70-79 |        163        4.17       98.98
      80-89 |         33        0.84       99.82
        90+ |          7        0.18      100.00
------------+-----------------------------------
      Total |      3,906      100.00

  */

// Regression: mortality if positive
reg death i.comorbid c.age##c.age woman symptomatic if positive==1 , cformat(%9.3f)
  /*
        Source |       SS           df       MS      Number of obs   =     3,906
  -------------+----------------------------------   F(5, 3900)      =     31.48
         Model |  1.76367951         5  .352735903   Prob > F        =    0.0000
      Residual |  43.6945898     3,900  .011203741   R-squared       =    0.0388
  -------------+----------------------------------   Adj R-squared   =    0.0376
         Total |  45.4582693     3,905  .011641042   Root MSE        =    .10585

  ------------------------------------------------------------------------------
         death |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
  -------------+----------------------------------------------------------------
    1.comorbid |      0.031      0.010     3.26   0.001        0.012       0.050
           age |     -0.001      0.000    -2.59   0.010       -0.002      -0.000
               |
   c.age#c.age |     +0.000      0.000     3.63   0.000        0.000       0.000
               |
         woman |     -0.005      0.004    -1.49   0.137       -0.012       0.002
   symptomatic |      0.038      0.004     8.81   0.000        0.029       0.046
         _cons |      0.012      0.007     1.65   0.099       -0.002       0.027
  ------------------------------------------------------------------------------
  */

// Stats - days in hopital
  ta death_daysinhospital
  /* Third, 50% of deaths in Punjab occur
  within 2 days of coming to a hospital,
  and 75% within 3 days.
      Days in |
     Hospital |      Freq.     Percent        Cum.
  ------------+-----------------------------------
            0 |          4        8.51        8.51
            1 |         10       21.28       29.79
            2 |         10       21.28       51.06
            3 |          4        8.51       59.57
            4 |          3        6.38       65.96
            5 |          5       10.64       76.60
            6 |          3        6.38       82.98
            7 |          1        2.13       85.11
            8 |          3        6.38       91.49
            9 |          1        2.13       93.62
           11 |          1        2.13       95.74
           13 |          2        4.26      100.00
  ------------+-----------------------------------
        Total |         47      100.00
  */
