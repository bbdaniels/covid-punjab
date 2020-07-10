*! version 0.2 13-MAR-2019

capture program drop binsregselect
program define binsregselect, eclass
     version 13
	 
	 syntax varlist(min=2 numeric ts fv) [if] [in] [fw aw pw] [, deriv(integer 0) ///
	        bins(numlist integer max=2 >=0) binspos(string) ///
			binsmethod(string) nbinsrot(string) ///
			simsgrid(integer 20) savegrid(string asis) replace ///
			dfcheck(numlist integer max=2 >=0) masspoints(string) ///
			vce(passthru) useeffn(string) ///
			norotnorm numdist(string) numclust(string)]   
			/* last line only for internal use */
			
	 set more off
	 
	 **************************************
	 ******** Regularization constant  ****
	 **************************************
	 local qrot=2
	 local rot_lb=1
	 local den_alp=0.975
	 
	 **************************************
	 * Create weight local
     if ("`weight'"!="") {
	    local wt [`weight'`exp']
		local wtype=substr("`weight'",1,1)
	 }
	 	 
	 **********************
	 ** Extract options ***
	 **********************	 
	 * default vce
	 if ("`vce'"=="") local vce "vce(robust)"
	 
	 * binning
	 tokenize `bins'
	 local p "`1'"
	 local s "`2'"
	 if ("`p'"=="") local p=0
	 if ("`s'"=="") local s=`p'
	 if ("`binspos'"=="") local binspos "QS"
	 if ("`binspos'"=="es") local binspos "ES"
	 if ("`binspos'"=="qs") local binspos "QS"
	 if ("`binsmethod'"=="") local binsmethod "DPI"
	 if ("`binsmethod'"=="rot") local binsmethod "ROT"
	 if ("`binsmethod'"=="dpi") local binsmethod "DPI"
	 if ("`dfcheck'"=="") local dfcheck 20 30
	 
	 * mass check?
	 if ("`masspoints'"=="") {
	    local massadj "T"
		local localcheck "T"	    
	 }
	 else if ("`masspoints'"=="off") {
	    local massadj "F"
		local localcheck "F"
	 }
	 else if ("`masspoints'"=="noadjust") {
	    local massadj "F"
		local localcheck "T"
	 }
	 else if ("`masspoints'"=="nolocalcheck") {
	 	local massadj "T"
		local localcheck "F"
     }
	 else if ("`masspoints'"=="veryfew") {
	    di as text in gr "warning: masspoints(veryfew) not allowed for bin selection."
		local localcheck "F"
		local rot_fewobs "T"
		local dpi_fewobs "T"
	 }
	 
	 tokenize `dfcheck'
	 local dfcheck_n1 "`1'"
	 local dfcheck_n2 "`2'"
	 
	 * Error checks
	 if (`p'<0) {
	    di as error "bins() incorrectly specified."
		exit
	 }
	 if (`deriv'<0|`deriv'>`p') {
	    di as error "deriv() incorrectly specified."
		exit
	 }
	 if (`simsgrid'<0) {
	    di as error "simsgrid() incorrectly specified."
		exit
	 }
	 if (`"`savegrid'"'!=`""'&"`replace'"=="") {
	    confirm new file `"`savegrid'.dta"'
	 }
	 if ("`nbinsrot'"!="") {
	    confirm integer n `nbinsrot'
	 }
	 
	 * Mark sample
	 preserve
	 marksample touse, nov   /* do not account for missing values !! */
	 qui keep if `touse'
	 
	 * Parse varlist into y_var, x_var and w_var
	 tokenize `varlist'
	 fvrevar `1', tsonly
	 local y_var "`r(varlist)'"
	 fvrevar `2', tsonly
	 local x_var "`r(varlist)'"
	 fvrevar `2', list
	 local x_varname "`r(varlist)'"
	 
	 macro shift 2
	 local w_var "`*'"
	 fvrevar `w_var', list
	 local w_varname "`r(varlist)'"
	 fvrevar `w_var', tsonly
	 local w_var "`r(varlist)'"       /* so time series operator respected */
	 
	 marksample touse      /* now renew the mark to account for missing values */
	 qui keep if `touse'
	 local eN=_N
	 
	 if ("`masspoints'"!="off"|"`binspos'"=="QS") {
	    if ("`:sortedby'"!="`x_var'") sort `x_var'
	 }
	 
	 * Normalize support
	 tempvar z_var
	 if ("`wtype'"=="f") qui sum `x_var' `wt', meanonly
	 else                qui sum `x_var', meanonly
	 
	 local N=r(N)      /* sample size, with wt */
	 local xmin=r(min)
	 local xmax=r(max)
	 qui gen `z_var'=(`x_var'-`xmin')/(`xmax'-`xmin')
	 
	 tempname zvec Xm binedges
	 mata: `zvec'=st_data(., "`z_var'")
		 
	 * Extract effective sample size
	 local Ndist=.
	 if ("`massadj'"=="T") {
	    if ("`numdist'"!=""&"`numdist'"!=".") {
		   local Ndist=`numdist'
		}
		else {
		   mata: `binedges'=binsreg_uniq(`zvec', ., 1, "Ndist")
		   mata: mata drop `binedges'
		}   
		local eN=min(`eN', `Ndist')
	 }
	 local Nclust=.
	 if ("`vce'"!="") {
	    local vcetemp: subinstr local vce "vce(" "", all
		local vcetemp: subinstr local vcetemp ")" "", all
		tokenize `vcetemp'
		if ("`1'"=="cl"|"`1'"=="clu"|"`1'"=="clus"|"`1'"=="clust"| /// 
		    "`1'"=="cluste"|"`1'"=="cluster") {
		    if ("`numclust'"!=""&"`numclust'"!=".") {
			   local Nclust=`numclust'
			}
			else {
			   st_local("Nclust", strofreal(rows(uniqrows(st_data(.,"`2'")))))
			}
		}
		local eN=min(`eN', `Nclust')
	 }
	 
	 ***************************
	 ******* ROT choice ********
	 ***************************
	 tempname vcons bcons coef
	 local J_rot_reg=.
	 local J_rot_unreg=.
	 if ("`nbinsrot'"!="") local J_rot_reg=`nbinsrot'
	 
	 * Initial checking of sample size (for ROT)
	 if (`J_rot_reg'==.&"`rot_fewobs'"=="") {
        if (`eN'<=`dfcheck_n1'+`p'+1+`qrot') {
	       local rot_fewobs "T"
	       di as text in gr "warning: too small effective sample size for bin selection."
	    }
	 }
	 if ("`rot_fewobs'"!="T"&`J_rot_reg'==.) {
		* Power series
	    local series_rot ""
		forvalues i=0/`=`p'+`qrot'' {
	       tempvar z_var_`i'
	       qui gen `z_var_`i''=`z_var'^`i'
		   local series_rot `series_rot' `z_var_`i''
	    }
	    
	    * Variance Component
	    capture reg `y_var' `series_rot' `w_var' `wt', nocons `vce'
	    if (_rc==0) {
		   mat `coef'=e(b)
	       mat `coef'=`coef'[1,`=`p'+2'..`=`p'+1+`qrot'']
	    }
	    else {
	       error _rc
		   exit _rc
	    }
	    
		tempvar pred_y y_var_2 pred_y2 s2
	    qui predict `pred_y', xb
		
	    qui gen `y_var_2'=`y_var'^2
		capture reg `y_var_2' `series_rot' `w_var' `wt'
	    qui predict `pred_y2', xb
	    qui gen `s2'=`pred_y2'-`pred_y'^2         /* sigma^2(x) var */
	 
	    * Normal density
	    if ("`rotnorm'"=="") {
	       qui mean `z_var' `wt'
		   tempname m_z sd_z
		   mat `m_z'=e(b)
		   mat `sd_z'=e(V)
	       local zbar=`m_z'[1,1]
	       local zsd=sqrt(e(N)*`sd_z'[1,1])
	       tempvar fz
		   * trim density from below
		   local cutval=normalden(invnormal(`den_alp')*`zsd', 0, `zsd')
	       qui gen `fz'=max(normalden(`z_var', `zbar', `zsd'), `cutval')	 
	       if ("`binspos'"=="ES") qui replace `s2'=`s2'/`fz' 
		   else                   qui replace `s2'=`s2'*(`fz'^(2*`deriv'))
	    }
	 
	    if ("`wt'"!="") qui sum `s2' [aw`exp'], meanonly
		else            qui sum `s2', meanonly
	    local sig2=r(mean)    
	    mata: imse_v_cons(`p', `deriv', "`vcons'")
	    local imse_v=`sig2'*`vcons'                  /* variance constant */
		
	    * Bias component
	    * gen data for derivative
		tempname i
		tempvar pred_deriv
		mata: `Xm'=J(rows(`zvec'),0,.) 
		
		forval i=`=`p'+1'/`=`p'+`qrot'' {
		   mata:`Xm'=(`Xm',`zvec':^(`i'-`p'-1)*factorial(`i')/factorial(`i'-`p'-1))
		}
		  
		mata: `Xm'=`Xm'*st_matrix("`coef'")'; ///
		      st_store(.,st_addvar("float", "`pred_deriv'"), `Xm':^2)
		
		mata: mata drop `Xm'
	 
	    if ("`rotnorm'"=="") {
	       if ("`binspos'"=="QS") {
		      qui replace `pred_deriv'=`pred_deriv'/(`fz'^(	2*`p'+2-2*`deriv'))
		   }
	    }
		if ("`wt'"!="") qui sum `pred_deriv' [aw`exp'], meanonly
		else            qui sum `pred_deriv', meanonly
	    local mean_deriv=r(mean)

	    mata: imse_b_cons(`p', `deriv', "`bcons'")
	    local imse_b=`mean_deriv'*`bcons'          /* bias constant */
			
	    * ROT J
	    local J_rot_unreg=ceil((`imse_b'*2*(`p'+1-`deriv')/               ///
		                       (`imse_v'*(1+2*`deriv')))^(1/(2*`p'+2+1))* ///
		                      `eN'^(1/(2*`p'+2+1)))
		local J_rot_reg=max(`J_rot_unreg', ///
		                    ceil((2*(`p'+1-`deriv')/(1+2*`deriv')*`rot_lb'*`eN')^(1/(2*`p'+2+1)))) 
	 }
	 
	 ** Repeated knots? ***************
	 local J_rot_uniq=`J_rot_reg'
	 
	 if (("`binsmethod'"=="DPI"|"`localcheck'"=="T")&"`masspoints'"!="veryfew") {
	    tempvar zcat
	    qui gen `zcat'=. in 1
	    * Prepare bins
	    tempname kmat
	 
	    if "`binspos'"=="ES" {
	      local stepsize=1/`J_rot_reg'
		  forvalues i=1/`=`J_rot_reg'+1' {
		     mat `kmat'=(nullmat(`kmat') \ `=0+`stepsize'*(`i'-1)')
		  }
	    }
	    else {
		  if (`J_rot_reg'==1) {
		     mat `kmat'=(0 \ 1)
		  }
		  else {
	         binsreg_pctile `z_var' `wt', nq(`J_rot_reg')
		     mat `kmat'=(0 \ r(Q) \ 1)
		  }
	    }
        
	    mata: st_matrix("`kmat'", (0 \ uniqrows(st_matrix("`kmat'")[|2 \ `=`J_rot_reg'+1'|])))
	    local J_rot_uniq=rowsof(`kmat')-1
	    if ("`binsmethod'"=="DPI"&"`dpi_fewobs'"=="") binsreg_irecode `z_var', knotmat(`kmat') bin(`zcat')
	 }
	 
	 *********************************
	 ********** DPI Choice ***********
	 *********************************
	 local J_dpi=.	 
	 * Check if DPI can be implemented
	 if ("`J_rot_uniq'"!="."&"`binsmethod'"=="DPI"&"`masspoints'"!="veryfew") {
	    * Compare with degree of freedom
		if ((`p'-`s'+1)*(`J_rot_uniq'-1)+`p'+2+`dfcheck_n2'>=`eN') {
		   di as text in gr  "warning: too small effective sample size for DPI selection."
		   local dpi_fewobs "T"
	    }
		
		* Check local effective size
		if ("`localcheck'"=="T"&"`dpi_fewobs'"!="T") {
		   mata: `binedges'=binsreg_uniq(`zvec', st_data(.,"`zcat'"), `J_rot_uniq', "uniqmin")
		   mata: mata drop `binedges'
		   if (`uniqmin'<`p'+1) {
		      local dpi_fewobs "T"
		      di as text in gr  "warning: some bins have too few distinct x-values for DPI selection."
		   }
		}
	 }
	 else local dpi_fewobs "T"
	 
	 if ("`binsmethod'"=="DPI"&"`dpi_fewobs'"!="T") {	
		* Update vce condition
		if ("`massadj'"=="T") {
		   if ("`Nclust'"==".") {
		      local vce "vce(cluster `z_var')"
		   }
		   else {
		      if (`Nclust'>`Ndist') {
			     local vce "vce(cluster `z_var')"
				 di as text in gr "warning: # of mass points < # of clusters. vce option overridden."
			  }
		   }
		}
		
		********************************
	    * Start computation
		tempvar derivfit derivse biasterm biasterm_v projbias
		qui gen `derivfit'=. in 1
		qui gen `derivse'=. in 1
		qui gen `biasterm'=. in 1                   /* save bias */
		if (`deriv'>0) {
		    qui gen `biasterm_v'=. in 1             /* error of approx deriv */
		}
		qui gen `projbias'=. in 1                   /* save proj of bias */
		
		**********************
		* predict leading bias
		mata: bias("`z_var'", "`zcat'", "`kmat'", `p', 0, "`biasterm'")
		if (`deriv'>0) {
		    mata: bias("`z_var'", "`zcat'", "`kmat'", `p', `deriv', "`biasterm_v'")
		}
		
		* Increase order from p to p+1
		* Expand basis
	    local nseries=(`p'-`s'+1)*(`J_rot_uniq'-1)+`p'+2
	    local series ""
	    forvalues i=1/`nseries' {
	       tempvar sp`i'
	       local series `series' `sp`i''
		   qui gen `sp`i''=. in 1
	    }
		
		mata: binsreg_st_spdes(`zvec', "`series'", "`kmat'", st_data(.,"`zcat'"), `=`p'+1', 0, `=`s'+1')
	 
	    capture reg `y_var' `series' `w_var' `wt', nocon
	    * store results
		tempname temp_b temp_V
	    if (_rc==0) {
		    matrix `temp_b'=e(b)
		    matrix `temp_V'=e(V)
	    }
	    else {
	        error  _rc
	   	    exit _rc
        }
		
		* Predict (p+1)th derivative
		mata: `Xm'=binsreg_spdes(`zvec', "`kmat'", st_data(.,"`zcat'"), `=`p'+1', `=`p'+1', `=`s'+1'); ///
	          st_store(.,"`derivfit'", (binsreg_pred(`Xm', (st_matrix("`temp_b'")[|1 \ `nseries'|])', ///
			               st_matrix("`temp_V'")[|1,1 \ `nseries',`nseries'|], "xb"))[,1])
		mata: mata drop `Xm'
		
		qui replace `biasterm'=`derivfit'*`biasterm'
		if (`deriv'>0) qui replace `biasterm_v'=`derivfit'*`biasterm_v'
		drop `series'
		   
		* Then get back degree-p spline, run OLS
	    local nseries=(`p'-`s'+1)*(`J_rot_uniq'-1)+`p'+1
	    local series ""
	    forvalues i=1/`nseries' {
	       tempvar sp`i'
	       local series `series' `sp`i''
		   qui gen `sp`i''=. in 1
	    }
	   		  
		mata: binsreg_st_spdes(`zvec', "`series'", "`kmat'", st_data(.,"`zcat'"), `p', 0, `s')   
		capture reg `biasterm' `series' `wt', nocon       /* project bias on X of degree p */
		tempname bias_b bias_V
		if (_rc==0) {
		    matrix `bias_b'=e(b)
		    matrix `bias_V'=e(V)
		}
		else {
		    error _rc
			exit _rc
		}
		   
		capture reg `y_var' `series' `w_var' `wt', nocon `vce'        /* for variance purpose */
	    * store results
	    if (_rc==0) {
		    matrix `temp_b'=e(b)
		    matrix `temp_V'=e(V)
	    }
	    else {
	        error  _rc
	   	    exit _rc
        }
		   
		mata: `Xm'=binsreg_spdes(`zvec', "`kmat'", st_data(.,"`zcat'"), `p', `deriv', `s'); ///
	          st_store(.,"`projbias'", binsreg_pred(`Xm', st_matrix("`bias_b'")', st_matrix("`bias_V'"), "xb")[,1])

		if (`deriv'==0) {
		    qui replace `biasterm'=(`biasterm'-`projbias')^2
		}
		else {
		    qui replace `biasterm'=(`biasterm_v'-`projbias')^2   /* still save in biasterm if deriv>0 */
		}
		   
		if ("`wt'"!="") qui sum `biasterm' [aw`exp'], meanonly
		else            qui sum `biasterm', meanonly
		local m_bias=r(mean)
		local imse_b=`m_bias'*`J_rot_uniq'^(2*(`p'+1-`deriv'))
	 
		mata: st_store(., "`derivse'", ///
		               (binsreg_pred(`Xm', (st_matrix("`temp_b'")[|1 \ `nseries'|])', ///
		                st_matrix("`temp_V'")[|1,1 \ `nseries',`nseries'|], "se")[,2]):^2) ///
		
		if ("`wt'"!="") qui sum `derivse' [aw`exp'], meanonly
		else            qui sum `derivse', meanonly
		local m_se=r(mean)
		local imse_v=`m_se'/(`J_rot_uniq'^(1+2*`deriv'))	   
		mata: mata drop `Xm'   	   
		
        * DPI J
	    local J_dpi=ceil((`imse_b'*2*(`p'+1-`deriv')/               ///
		                 (`imse_v'*(1+2*`deriv')))^(1/(2*`p'+2+1)))
	 }
	 local J_dpi_uniq=`J_dpi'
	 
	 mata: mata drop `zvec'
	 ************************************************
	 
	 * update J if useeffn specified
	 if ("`useeffn'"!="") {
	    local scaling=(`useeffn'/`eN')^(1/(2*`p'+2+1))
	    if (`J_rot_unreg'!=.) local J_rot_unreg=`J_rot_unreg'*`scaling'
		if (`J_rot_reg'!=.)   local J_rot_reg=`J_rot_reg'*`scaling'
		if (`J_rot_uniq'!=.)  local J_rot_uniq=`J_rot_uniq'*`scaling'
		if (`J_dpi'!=.)       local J_dpi=`J_dpi'*`scaling'
		if (`J_dpi_uniq'!=.)  local J_dpi_uniq=`J_dpi_uniq'*`scaling'
	 }
	 
	 * Reconstruct knot list
	 tempname xkmat
	 
	 if ("`binsmethod'"=="ROT"&"`rot_fewobs'"!="T") {
	    local Jselected `J_rot_uniq'
	 }
	 else if ("`binsmethod'"=="DPI"&"`dpi_fewobs'"!="T") {
	    local Jselected `J_dpi'
	 }
	 else {
	    local Jselectfail "T"
	 }
	 
	 if ("`Jselectfail'"!="T"&"`useeffn'"=="") {
	    if ("`binspos'"=="ES") {
	       local stepsize=1/`Jselected'   
	       forvalues i=1/`=`Jselected'+1' {
		      mat `xkmat'=(nullmat(`xkmat') \ `=`xmin'+`stepsize'*(`i'-1)')
		   }
	    }
	    else {
		   if (`Jselected'>1) {
	          binsreg_pctile `x_var' `wt', nq(`Jselected')
			  mat `xkmat'=(`xmin'\ r(Q) \ `xmax')
		   }
		   else mat `xkmat'=(`xmin' \ `xmax')		   
	    }
		
		* Renew if needed
		mata: st_matrix("`xkmat'", (`xmin' \ uniqrows(st_matrix("`xkmat'")[|2 \ `=`Jselected'+1'|])))
	    if (`Jselected'!=rowsof(`xkmat')-1) {
		   local Jselected=rowsof(`xkmat')-1
		}
		if ("`binsmethod'"=="DPI") {
		   local J_dpi_uniq=`Jselected'
		}
	 }
	 else mat `xkmat'=.
	 
	 if ("`binsmethod'"=="DPI") {
	     local method "IMSE-optimal: plug-in choice"
	 }
	 else {
	     local method "IMSE-optimal: rule-of-thumb choice"
	 }
	 if ("`binspos'"=="ES") {
	     local placement "Evenly-spaced"
	 }
	 else {
	     local placement "Quantile-spaced"
	 }
	 
	 * Save data?
	 if (`"`savegrid'"'!=`""') {
	    if ("`Jselectfail'"!="T"&"`useeffn'"=="") {
		   clear
	       local obs=`simsgrid'*`Jselected'+`Jselected'-1
		   qui set obs `obs'
		   
		   qui gen `x_varname'=. in 1
		   label var `x_varname' "Eval. point"
	       qui gen binsreg_isknot=. in 1
		   label var binsreg_isknot "Is the eval. point an inner knot"
		   qui gen binsreg_bin=. in 1
		   label var binsreg_bin "indicator of bin"
		   mata: st_store(., (1,2,3), binsreg_grids("`xkmat'", `simsgrid'))
		   foreach var of local w_varname {
		      qui gen `var'=0
	   	   }
		   
		   qui save `"`savegrid'"', `replace'
	    }
		else {
		   di as text in gr "warning: Grid not saved. Selection fails or useeffn() is specified."
		}
	 }

	 * Display
	 di ""
	 di in smcl in gr "Bin selection for binscatter estimates"
	 di in smcl in gr "Method: `method'"
	 di in smcl in gr "Position: `placement'"
	 if (`"`savegrid'"'!=`""') {
	    di in smcl in gr `"Output file: `savegrid'.dta"' 
	 }
	 di ""
	 di in smcl in gr "{hline 28}{c TT}{hline 10}"
	 di in smcl in gr "{ralign 27:# of observations}"    _col(28) " {c |} " _col(30) as result %7.0f `N'
	 di in smcl in gr "{ralign 27:# of distince values}" _col(28) " {c |} " _col(30) as result %7.0f `Ndist'
	 di in smcl in gr "{ralign 27:# of clusters}"        _col(28) " {c |} " _col(30) as result %7.0f `Nclust'
     if ("`useeffn'"=="") {
	 di in smcl in gr "{ralign 27:eff. sample size}"     _col(28) " {c |} " _col(30) as result %7.0f `eN'
	 }
	 else {
	 di in smcl in gr "{ralign 27:eff. sample size}"     _col(28) " {c |} " _col(30) as result %7.0f `useeffn'
     }
	 di in smcl in gr "{hline 28}{c +}{hline 10}"
	 di in smcl in gr "{ralign 27:Degree of polynomial}"  _col(28) " {c |} " _col(30) as result %7.0f `p'
	 di in smcl in gr "{ralign 27:# of smoothness constraint}"  _col(28) " {c |} " _col(30) as result %7.0f `s' 
     di in smcl in gr "{hline 28}{c BT}{hline 10}"
	 di ""
	 local df_rot_unreg=.
	 if (`J_rot_unreg'!=.) local df_rot_unreg=(`p'-`s'+1)*(`J_rot_unreg'-1)+`p'+1
	 local df_rot_reg=.
	 if (`J_rot_reg'!=.) local df_rot_reg=(`p'-`s'+1)*(`J_rot_reg'-1)+`p'+1
	 local df_rot_uniq=.
	 if (`J_rot_uniq'!=.) local df_rot_uniq=(`p'-`s'+1)*(`J_rot_uniq'-1)+`p'+1
	 local df_dpi=.
	 if (`J_dpi'!=.) local df_dpi=(`p'-`s'+1)*(`J_dpi'-1)+`p'+1
	 local df_dpi_uniq=.
	 if (`J_dpi_uniq'!=.) local df_dpi_uniq=(`p'-`s'+1)*(`J_dpi_uniq'-1)+`p'+1
	 di in smcl in gr "{hline 14}{c TT}{hline 13}{c TT}{hline 10}"
	 di in smcl in gr "{rcenter 13: method}" _col(13) " {c |} " "{rcenter 12: # of bins}" _col(29) "{c |}" "{rcenter 10: df}"
	 di in smcl in gr "{hline 14}{c +}{hline 13}{c +}{hline 10}"
	 di in smcl in gr "{rcenter 13: ROT-POLY}"  _col(13) " {c |} " as result %7.0f `J_rot_unreg' _col(29) in gr "{c |}" as result %7.0f `df_rot_unreg'
	 di in smcl in gr "{rcenter 13: ROT-REGUL}" _col(13) " {c |} " as result %7.0f `J_rot_reg'   _col(29) in gr "{c |}" as result %7.0f `df_rot_reg'
	 di in smcl in gr "{rcenter 13: ROT-UKNOT}" _col(13) " {c |} " as result %7.0f `J_rot_uniq'  _col(29) in gr "{c |}" as result %7.0f `df_rot_uniq'
	 di in smcl in gr "{rcenter 13: DPI}"       _col(13) " {c |} " as result %7.0f `J_dpi'       _col(29) in gr "{c |}" as result %7.0f `df_dpi'
	 di in smcl in gr "{rcenter 13: DPI-UKNOT}" _col(13) " {c |} " as result %7.0f `J_dpi_uniq'  _col(29) in gr "{c |}" as result %7.0f `df_dpi_uniq'
	 di in smcl in gr "{hline 14}{c BT}{hline 13}{c BT}{hline 10}"
	 
	 * return
	 ereturn clear
	 ereturn scalar N=`N'
	 *ereturn scalar eN=`eN'
	 ereturn scalar Ndist=`Ndist'
	 ereturn scalar Nclust=`Nclust'
	 ereturn scalar p=`p'
	 ereturn scalar s=`s'
	 ereturn scalar deriv=`deriv'
	 ereturn scalar nbinsrot_poly=`J_rot_unreg'
	 ereturn scalar nbinsrot_regul=`J_rot_reg'
	 ereturn scalar nbinsrot_uknot=`J_rot_uniq'
	 ereturn scalar nbinsdpi=`J_dpi'
	 ereturn scalar nbinsdpi_uknot=`J_dpi_uniq'
	 ereturn matrix knot=`xkmat'
end



version 13
mata:
    // Constant in variance
    void imse_v_cons(real scalar degree, real scalar deriv, string scalar vcons)
	{  
	   real scalar v_cons, m
	   real matrix V, Vderiv
	   
	   m=degree+1
       if (deriv==0) {
	      v_cons=m
	   }
	   else {
	      V=J(m, m, .)
		  Vderiv=J(m, m, 0)
		  
		  for (i=1; i<=m; i++){
		      for (j=1; j<=i; j++) {
			       V[i,j]=1/(i+j-1)
			       if (i>deriv & j>deriv) {
				       Vderiv[i,j]=1/(i+j-1-2*deriv)* /*
					   */          (factorial(i-1)/factorial(i-1-deriv))* /*
					   */          (factorial(j-1)/factorial(j-1-deriv))
				   }
			  }
		  }
		  V=makesymmetric(V)
		  Vderiv=makesymmetric(Vderiv)
		  v_cons=trace(invsym(V)*Vderiv)
	   }
	   
	   // return results
	   st_numscalar(vcons,v_cons)
	}
	
	// Constant in bias
	void imse_b_cons(real scalar degree, real scalar deriv, string scalar bcons, | real scalar s)
	{  
	   real scalar b_cons, m, bernum
	   m=degree+1
       if (args()<4) {
	      b_cons=1/(2*(m-deriv)+1)/factorial(m-deriv)^2/comb(2*(m-deriv), m-deriv)^2
	   }
	   else {
	      if (degree==0) {
		     bernum=1/6
		  }
		  else if (degree==1) {
		     bernum=1/30
		  }
		  else if (degree==2) {
		     bernum=1/42
		  }
		  else  if (degree==3) {
		     bernum=1/30
		  }
		  else if (degree==4) {
		     bernum=5/66
		  }
		  else if (degree==5) {
		     bernum=691/2730
		  }
		  else if (degree==6) {
		     bernum=7/6
		  }
		  else {
		     _error("p>6 not allowed.")
		  }
	   	  b_cons=1/factorial(2*(m-deriv))*bernum
	   }
	   
	   // return results
	   st_numscalar(bcons, b_cons)
	}
  
    // Bernoulli polynomial
    real vector bernpoly(real vector x, real scalar degree)
    {
      n=rows(x)
	  if (degree==0) {
	     bernx=J(n,1,1)
	  }
	  else if (degree==1) {
	     bernx=x:-0.5
	  }
	  else if (degree==2) {
	     bernx=x:^2-x:+1/6
	  }
	  else if (degree==3) {
	     bernx=x:^3-1.5*x:^2+0.5*x
	  }
	  else if (degree==4) {
	     bernx=x:^4-2*x:^3+x:^2:-1/30
	  }
	  else if (degree==5) {
	     bernx=x:^5-2.5*x:^4+5/3*x:^3-1/6*x
	  }
	  else if (degree==6) {
	     bernx=x:^6-3*x:^5+2.5*x:^4-0.5*x:^2:+1/42
	  }
	  else {
	     _error("p is too large.")
	  }
	  return(bernx)
  }

  // Leading bias for splines
  void bias(string scalar Var, string scalar Xcat, string scalar knotname, ///
            real scalar degree, real scalar deriv, ///
			string scalar biasname, | string scalar select)
  {
    if (args()<7) {
	   X=st_data(., (Var))
	   xcat=st_data(., (Xcat))
	   st_view(bias=., ., (biasname))
	}
	else {
       X=st_data(., (Var), select)
	   xcat=st_data(., (Xcat), select)
	   st_view(bias=.,.,(biasname), select)
	}
	knot=st_matrix(knotname)
 	h=knot[|2 \ length(knot)|]-knot[|1 \ (length(knot)-1)|]
	h=h[xcat]
	if (rows(h)==1) {
	   h=h'
	}
	tl=knot[|1 \ (length(knot)-1)|]
	tl=tl[xcat]
	if (rows(tl)==1) {
	   tl=tl'
	}
	bern=bernpoly((X-tl):/h, degree+1-deriv)/factorial(degree+1-deriv):*(h:^(degree+1-deriv))
	bias[.,.]=bern
  }
  
end

