{smcl}
{* *! version 0.2 13-MAR-2019}{...}
{viewerjumpto "Syntax" "binsregtest##syntax"}{...}
{viewerjumpto "Description" "binsregtest##description"}{...}
{viewerjumpto "Options" "binsregtest##options"}{...}
{viewerjumpto "Examples" "binsregtest##examples"}{...}
{viewerjumpto "Stored results" "binsregtest##stored_results"}{...}
{viewerjumpto "References" "binsregtest##references"}{...}
{viewerjumpto "Authors" "binsregtest##authors"}{...}
{cmd:help binsregtest}
{hline}

{title:Title}

{p 4 8}{hi:binsregtest} {hline 2} Data-driven Nonparametric Shape Restriction and Parametric Model Specification Testing using Binscatter.{p_end}


{marker syntax}{...}
{title:Syntax}

{p 4 16} {cmdab:binsregtest} {depvar} {it:indvar} [{it:covars}] {ifin} {weight} [ {cmd:,} {opt deriv(v)}{p_end}
{p 16 16} {opt testmodel(p s)} {opt testmodelparfit(filename)} {opt testmodelpoly(p)}{p_end}
{p 16 16} {opt testshape(p s)} {opt testshapel(numlist)} {opt testshaper(numlist)} {opt testshape2(numlist)}{p_end}
{p 16 16} {opt bins(p s)} {opt nbins(#)} {opt binspos(position)} {opt binsmethod(method)} {opt nbinsrot(#)}{p_end}
{p 16 16} {opt nsims(#)} {opt simsgrid(#)} {opt simsseed(seed)}{p_end}
{p 16 16} {opt dfcheck(n1 n2)} {opt masspoints(masspointsoption)}{p_end}
{p 16 16} {cmd:vce(}{it:{help vcetype}}{cmd:)} ]{p_end}

{p 4 8} where {depvar} is the dependent variable, {it:indvar} is the independent variable for binning, and {it:covars} are other covariates to be controlled for.{p_end}

{p 4 8} p, s and v are integers satisfying 0 <= s,v <= p, which can take different values in each case.{p_end}

{p 4 8} {opt fweight}s, {opt aweight}s and {opt pweight}s are allowed; see {help weight}.{p_end}

{marker description}{...}
{title:Description}

{p 4 8} {cmd:binsregtest} implements binscatter-based hypothesis testing procedures for parametric functional forms and nonparametric shape restrictions on of the regression function  estimators, following the results in
{browse "https://sites.google.com/site/nppackages/binsreg/Cattaneo-Crump-Farrell-Feng_2019_Binscatter.pdf":Cattaneo, Crump, Farrell and Feng (2019a)}.
If the binning scheme is not set by the user, the companion command {help binsregselect:binsregselect} is used to implement binscatter in a data-driven (optimal) way and inference procedures are based on robust bias correction.
Binned scatter plots can be constructed using the companion command {help binsreg:binsreg}.
{p_end}

{p 4 8} A detailed introduction to this command is given in
{browse "https://sites.google.com/site/nppackages/binsreg/Cattaneo-Crump-Farrell-Feng_2019_Stata.pdf":Cattaneo, Crump, Farrell and Feng (2019b)}.
A companion R package with the same capabilities is available (see website below).
{p_end}

{p 4 8} Companion commands: {help binsreg:binsreg} for binscatter estimation with robust inference procedures and plots, and {help binsregselect:binsregselect} data-driven (optimal) binning selection.{p_end}

{p 4 8} Related Stata and R packages are available in the following website:{p_end}

{p 8 8} {browse "https://sites.google.com/site/nppackages/":https://sites.google.com/site/nppackages/}{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Estimand}

{p 4 8} {opt deriv(v)} specifies the derivative order of the regression function for estimation, testing and plotting.
The default is {cmd:deriv(0)}, which corresponds to the function itself.
{p_end}

{dlgtab:Parametric Model Specification Testing}

{p 4 8} {opt testmodel(p s)} sets a piecewise polynomial of degree {it:p} with {it:s} smoothness constraints for parametric model specification testing.
The default is {cmd:testmodel(3 3)}, which corresponds to a cubic B-spline estimate of the regression function of interest for testing against the fitting from a parametric model specification.
{p_end}

{p 4 8} {opt testmodelparfit(filename)} specifies a dataset which contains the evaluation grid and fitted values of the model(s) to be tested against.
The file must have a variable with the same name as {it:indvar}, which contains a series of evaluation points at which the binscatter model and the parametric model of interest are compared with each other.
Each parametric model is represented by a variable named as {it:binsreg_fit*}, which must contain the fitted values at the corresponding evaluation points.
{p_end}

{p 4 8} {opt testmodelpoly(p)} specifies the degree of a global polynomial model to be tested against.
{p_end}
 
{dlgtab:Nonparametric Shape Restriction Testing}

{p 4 8} {opt testshape(p s)} sets a piecewise polynomial of degree {it:p} with {it:s} smoothness constraints for nonparametric shape restriction testing.
The default is {cmd:testmodel(3 3)}, which corresponds to a cubic B-spline estimate of the regression function of interest for one-sided or two-sided testing.
{p_end}

{p 4 8} {opt testshapel(numlist)} specifies a {help numlist} of null boundary values for hypothesis testing.
Each number {it:a} in the {it:numlist} corresponds to one boundary of a one-sided hypothesis test to the left of the form H0: {it:sup_x mu(x)<=a}.
{p_end}

{p 4 8} {opt testshaper(numlist)} specifies a {help numlist} of null boundary values for hypothesis testing.
Each number {it:a} in the {it:numlist} corresponds to one boundary of a one-sided hypothesis test to the right of the form H0: {it:inf_x mu(x)>=a}.
{p_end}

{p 4 8} {opt testshape2(numlist)} specifies a {help numlist} of null boundary values for hypothesis testing.
Each number {it:a} in the {it:numlist} corresponds to one boundary of a two-sided hypothesis test of the form H0: {it:sup_x |mu(x)-a|=0}.
{p_end}
 
{dlgtab:Partitioning/Binning Selection}

{p 4 8} {opt bins(p s)} sets a piecewise polynomial of degree {it:p} with {it:s} smoothness constraints for data-driven (IMSE-optimal) selection of the partitioning/binning scheme.
The default is {cmd:bins(0 0)}, which corresponds to piecewise constant (canonical binscatter).

{p 4 8} {opt nbins(#)} sets the number of bins for partitioning/binning of {it:indvar}.
If not specified, the number of bins is selected via the companion command {help binsregselect:binsregselect} in a data-driven, optimal way whenever possible.
{p_end}

{p 4 8} {opt binspos(position)} specifies the position of binning knots.
The default is {cmd:binspos(qs)}, which corresponds to quantile-spaced binning (canonical binscatter).
Other options are: {cmd:es} for evenly-spaced binning, or a {help numlist} for manual specification of the positions of inner knots (which must be within the range of {it:indvar}).
{p_end}

{p 4 8} {opt binsmethod(method)} specifies the method for data-driven selection of the number of bins via the companion command {help binsregselect:binsregselect}.
The default is {cmd:binsmethod(dpi)}, which corresponds to the IMSE-optimal direct plug-in rule.
The other option is: {cmd:rot} for rule of thumb implementation.
{p_end}

{p 4 8} {opt nbinsrot(#)} specifies an initial number of bins value used to construct the DPI number of bins selector.
If not specified, the data-driven ROT selector is used instead.
{p_end}

{dlgtab:Simulation}

{p 4 8} {opt nsims(#)} specifies the number of random draws for constructing confidence bands and hypothesis testing.
The default is {cmd:nsims(500)}, which corresponds to 500 draws from a standard Gaussian random vector of size [(p+1)*J - (J-1)*s].
{p_end}

{p 4 8} {opt simsgrid(#)} specifies the number of evaluation points of an evenly-spaced grid within each bin used for evaluation of the supremum (or infimum) operation needed to construct confidence bands and hypothesis testing procedures.
The default is {cmd:simsgrid(20)}, which corresponds to 20 evenly-spaced evaluation points within each bin for approximating the supremum (or infimum) operator.
{p_end}

{p 4 8} {opt simsseed(#)} sets the seed for simulations.
{p_end}

{dlgtab:Mass Points and Degrees of Freedom}

{p 4 8} {opt dfcheck(n1 n2)} sets cutoff values for minimum effective sample size checks, which take into account the number of unique values of {it:indvar} (i.e., adjusting for the number of mass points), number of clusters, and degrees of freedom of the different statistical models considered.
The default is {cmd:dfcheck(20 30)}. See Cattaneo, Crump, Farrell and Feng (2019b) for more details.
{p_end}

{p 4 8} {opt masspoints(masspointsoption)} specifies how mass points in {it:indvar} are handled.
By default, all mass point and degrees of freedom checks are implemented.
Available options:
{p_end}
{p 8 8} {opt masspoints(noadjust)} omits mass point checks and the corresponding effective sample size adjustments.{p_end}
{p 8 8} {opt masspoints(nolocalcheck)} omits within-bin mass point and degrees of freedom checks.{p_end}
{p 8 8} {opt masspoints(off)} sets {opt masspoints(noadjust)} and {opt masspoints(nolocalcheck)} simultaneously.{p_end}
{p 8 8} {opt masspoints(veryfew)} forces the command to proceed as if {it:indvar} has only a few number of mass points (i.e., distinct values).
In other words, forces the command to proceed as if the mass point and degrees of freedom checks were failed.{p_end}

{dlgtab:Other Options}

{p 4 8} {cmd:vce(}{it:{help vcetype}}{cmd:)} specifies the {it:vcetype} for variance estimation used by the command {help regress##options:regress}.
The default is {cmd:vce(robust)}.
{p_end}


{marker examples}{...}
{title:Examples}

{p 4 8} Test linear model{p_end}
{p 8 8} . {stata binsregtest y x w, testmodelpoly(1)}{p_end}


{marker stored_results}{...}
{title:Stored results}

{synoptset 17 tabbed}{...}
{p2col 5 17 21 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(Ndist)}}number of distince values{p_end}
{synopt:{cmd:e(Nclust)}}number of clusters{p_end}
{synopt:{cmd:e(nbins)}}number of bins{p_end}
{synopt:{cmd:e(p)}}degree of polynomial for bin selection{p_end}
{synopt:{cmd:e(s)}}smoothness of polynomial for bin selection{p_end}
{synopt:{cmd:e(testshape_p)}}degree of polynomial for testing shape{p_end}
{synopt:{cmd:e(testshape_s)}}smoothnes of polynomial for testing shape{p_end}
{synopt:{cmd:e(testmodel_p)}}degree of polynomial for testing models{p_end}
{synopt:{cmd:e(testmodel_s)}}smoothness of polynomial for testing models{p_end}
{synopt:{cmd:e(testpolyp)}}degree of polynomial regression model{p_end}
{synopt:{cmd:e(stat_poly)}}statistic for testing global polynomial model{p_end}
{synopt:{cmd:e(pval_poly)}}p value for testing global polynomial model{p_end}
{p2col 5 17 21 2: Locals}{p_end}
{synopt:{cmd:e(testvalueL)}}values in {cmd:testshapel()}{p_end}
{synopt:{cmd:e(testvalueR)}}values in {cmd:testshaper()}  {p_end}
{synopt:{cmd:e(testvalue2)}}values in {cmd:testshape2()}  {p_end}
{synopt:{cmd:e(testvarlist)}}varlist found in {cmd:testmodel()}{p_end}
{p2col 5 17 21 2: Matrices}{p_end}
{synopt:{cmd:e(stat_shapeL)}}statistics for {cmd:testshapel()}{p_end}
{synopt:{cmd:e(pval_shapeL)}}p values for {cmd:testshapel()}{p_end}
{synopt:{cmd:e(stat_shapeR)}}statistics for {cmd:testshaper()}{p_end}
{synopt:{cmd:e(pval_shapeR)}}p values for {cmd:testshaper()}{p_end}
{synopt:{cmd:e(stat_shape2)}}statistics for {cmd:testshape2()}{p_end}
{synopt:{cmd:e(pval_shape2)}}p values for {cmd:testshape2()}{p_end}
{synopt:{cmd:e(stat_model)}}statistics for {cmd:testmodel()}{p_end}
{synopt:{cmd:e(pval_model)}}p values for {cmd:testmodel()}{p_end}


{marker references}{...}
{title:References}

{p 4 8} Cattaneo, M. D., R. K. Crump, M. H. Farrell, and Y. Feng. 2019a.
{browse "https://sites.google.com/site/nppackages/binsreg/Cattaneo-Crump-Farrell-Feng_2019_Binscatter.pdf":On Binscatter}.
{it:arXiv:1902.09608}.
{p_end}

{p 4 8} Cattaneo, M. D., R. K. Crump, M. H. Farrell, and Y. Feng. 2019b.
{browse "https://sites.google.com/site/nppackages/binsreg/Cattaneo-Crump-Farrell-Feng_2019_Stata.pdf":Binscatter Regressions}.
{it:arXiv:1902.09615}.
{p_end}


{marker authors}{...}
{title:Authors}

{p 4 8} Matias D. Cattaneo, University of Michigan, Ann Arbor, MI.
{browse "mailto:cattaneo@umich.edu":cattaneo@umich.edu}.
{p_end}

{p 4 8} Richard K. Crump, Federal Reserve Band of New York, New York, NY.
{browse "mailto:richard.crump@ny.frb.org":richard.crump@ny.frb.org}.
{p_end}

{p 4 8} Max H. Farrell, University of Chicago, Chicago, IL.
{browse "mailto:max.farrell@chicagobooth.edu":max.farrell@chicagobooth.edu}.
{p_end}

{p 4 8} Yingjie Feng, University of Michigan, Ann Arbor, MI.
{browse "mailto:yjfeng@umich.edu":yjfeng@umich.edu}.
{p_end}

