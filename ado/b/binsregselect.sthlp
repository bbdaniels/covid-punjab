{smcl}
{* *! version 0.2 13-MAR-2019}{...}
{viewerjumpto "Syntax" "binsregselect##syntax"}{...}
{viewerjumpto "Description" "binsregselect##description"}{...}
{viewerjumpto "Options" "binsregselect##options"}{...}
{viewerjumpto "Examples" "binsregselect##examples"}{...}
{viewerjumpto "Stored results" "binsregselect##stored_results"}{...}
{viewerjumpto "References" "binsregselect##references"}{...}
{viewerjumpto "Authors" "binsregselect##authors"}{...}
{cmd:help binsregselect}
{hline}

{title:Title}

{p 4 8}{hi:binsregselect} {hline 2} Data-driven IMSE-Optimal Partitioning/Binning Selection for Binscatter.{p_end}


{marker syntax}{...}
{title:Syntax}

{p 4 18} {cmdab:binsregselect} {depvar} {it:indvar} [{it:covars}] {ifin} {weight} [{cmd:,} {opt deriv(v)}{p_end}
{p 18 18} {opt bins(p s)} {opt binspos(position)} {opt binsmethod(method)} {opt nbinsrot(#)}{p_end}
{p 18 18} {opt simsgrid(#)} {opt savegrid(filename)} {opt replace}{p_end}
{p 18 18} {opt dfcheck(n1 n2)} {opt masspoints(masspointsoption)}{p_end}
{p 18 18} {cmd:vce(}{it:{help vcetype}}{cmd:)} {opt useeffn(#)} ]{p_end}

{p 4 8} where {depvar} is the dependent variable, {it:indvar} is the independent variable for binning, and {it:covars} are other covariates to be controlled for.{p_end}

{p 4 8} p, s and v are integers satisfying 0 <= s,v <= p.{p_end}

{p 4 8} {opt fweight}s, {opt aweight}s and {opt pweight}s are allowed; see {help weight}.{p_end}

{marker description}{...}
{title:Description}

{p 4 8} {cmd:binsregselect} implements data-driven procedures for selecting the number of bins for binscatter estimation. The selected number is optimal in minimizing the (asymptotic) integrated mean squared error (IMSE).
{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Estimand}

{p 4 8} {opt deriv(v)} specifies the derivative order of the regression function for estimation, testing and plotting.
The default is {cmd:deriv(0)}, which corresponds to the function itself.
{p_end}

{dlgtab:Partitioning/Binning Selection}

{p 4 8} {opt bins(p s)} sets a piecewise polynomial of degree {it:p} with {it:s} smoothness constraints for data-driven (IMSE-optimal) selection of the partitioning/binning scheme.
The default is {cmd:bins(0 0)}, which corresponds to piecewise constant (canonical binscatter).

{p 4 8} {opt binspos(position)} specifies the position of binning knots.
The default is {cmd:binspos(qs)}, which corresponds to quantile-spaced binning (canonical binscatter).
Other option is {cmd:es} for evenly-spaced binning.
{p_end}

{p 4 8} {opt binsmethod(method)} specifies the method for data-driven selection of the number of bins.
The default is {cmd:binsmethod(dpi)}, which corresponds to the IMSE-optimal direct plug-in rule.
The other option is: {cmd:rot} for rule of thumb implementation.
{p_end}

{p 4 8} {opt nbinsrot(#)} specifies an initial number of bins value used to construct the DPI number of bins selector.
If not specified, the data-driven ROT selector is used instead.
{p_end}

{dlgtab:Evaluation Points Grid Generation}

{p 4 8} {opt simsgrid(#)} specifies the number of evaluation points of an evenly-spaced grid within each bin used for evaluation of the supremum (or infimum) operation needed to construct confidence bands and hypothesis testing procedures.
The default is {cmd:simsgrid(20)}, which corresponds to 20 evenly-spaced evaluation points within each bin for approximating the supremum (or infimum) operator.
{p_end}

{p 4 8} {opt savegrid(filename)} specifies a filename for storing the simulation grid of evaluation points.
It contains the following variables:
{it:indvar}, which is a sequence of evaluation points used in approximation;
all control variables in {it:covars}, which take values of zero for prediction purpose;
{it:binsreg_isknot}, indicating  whether the evaluation point is an inner knot;
and {it:binsreg_bin}, indicating which bin the evaluation point belongs to.
{p_end}

{p 4 8} {opt replace} overwrites the existing file when saving the grid.
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

{p 4 8} {opt useeffn(#)} specifies the effective sample size {it:#} to be used when computing the (IMSE-optimal) number of bins. This option is useful for extrapolating the optimal number of bins to larger (or smaller) datasets than the one used to compute it.
{p_end}

    
{marker examples}{...}
{title:Examples}

{p 4 8} Select IMSE-optimal number of bins using DPI-procedure{p_end}
{p 8 8} . {stata binsregselect y x w}{p_end}


{marker stored_results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(Ndist)}}number of distince values{p_end}
{synopt:{cmd:e(Nclust)}}number of clusters{p_end}
{synopt:{cmd:e(p)}}degree of piecewise polynomial{p_end}
{synopt:{cmd:e(s)}}smoothness of piecewise polynomial{p_end}
{synopt:{cmd:e(deriv)}}order of derivative{p_end}
{synopt:{cmd:e(nbinsrot_poly)}}ROT number of bins, unregularized{p_end}
{synopt:{cmd:e(nbinsrot_regul)}}ROT number of bins, regularized or user-specified{p_end}
{synopt:{cmd:e(nbinsrot_uknot)}}ROT number of bins, unique knots{p_end}
{synopt:{cmd:e(nbinsdpi)}}DPI number of bins{p_end}
{synopt:{cmd:e(nbinsdpi_uknot)}}DPI number of bins, unique knots{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(knot)}}numlist of knots{p_end}


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

