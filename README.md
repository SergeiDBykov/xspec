# xspec_utils
 an array of xspec scripts
**xspec_util**

An array of useful Xspec scripts and functions (Xspec if a part of HEASOFT package)


**NO ERROR HANDLING IS PRESENTED IN THOSE SCRIPTS, BE AWARE!**

 _For instance, if the fit fails during the calc_flux command, it would calculate the flux for a broken model. Please, use with caution._ 



1. **Usage:**

Download xspec_utils.tcl to some path

in Xspec, after the data have been loaded and some model have been fitted, print this:
```
XSPEC12> @/path/to/xspec_utils.tcl
```
After that you can use one of function from xspec_utils.tcl. 


Note that you can add it to you xspec initialization so you would not need to print it everytime

2. **Functions:**
- **writetext _filename, run_all_errors, rebin_plot, model_prefix_**

This command is an analogue to writefits by Keith Arnold (in-build tcl script for Xspec).


A function does the following things:

- Creates a txt file `filename.txt` and writes _every_ parameter of a model best fit value and upper/lower 90% confidence interval. In case the parameter if frozen or error has not been calculated, upped and lower confidence intervals are zeros. It also writes the statistics value, exposure and the number of dof.

If a parameter `run_all_errors` is 1 (default is 0), it runs xspec commands 
```
parallel error $numpar 
error 1-$numpar
``` 
where `$numpar` if a number of parameters of a model (calculated automatically). So, before writing parameters values into a txt file,  you do not need to run `error` command.

A prefix `model_prefix` is added To the names of parameters  (default prefix is `mymodel_`). It might be useful if you are using several spectral models for one spectra and want to save parameters in different files


The first row of a text file is parameters names array and, if any, names of errors. 
For instance,  
> ...  mymodel_LineE2 mymodel_LineE2_lo mymodel_LineE2_hi  ...

> ...  6.4            6.3                6.5 ...

means that the corresponding value in the second row in a value of Line Energy (6.4) and the parameter number (in the model) is 2. `_lo` and `_hi` strings mean lower and upper 90% confidence intervals (6.3 and 6.5 in out example).

- Creates Xspec's iplot `eeufs del ra` gif image of an unfolded spectral model versus energy with chi squared residuals and the ration between  data and  model. No rebinnig used.



- Creates `.dat` file with iplot `eeufs del` plot points _for each_ loaded dataset. 

In `.dat` files, the first row is energy values, the second row is unfolded data values, the next row is errors on data, the next row is full model values, and, finally,  chi (data-model)/err values.

Those files can be then used in plotting purposes in python/matlab/whatever.

On the spectra in output dat files Xspec command `setplot rebin $rebin_plot $rebin_plot ` was set, rebinning data for clarity (default 50). Use 1 to not change spectra at all.

**Example**
- writetext cutoffpl.txt 1 50 cutoff_no_nH
Would create a text file `cutoffpl.txt`  and plots according to the discription above. It would write all parameters of cutoffpl model, and save their names as cutoffpl_no_nH_{parameter name}

=====calc_flux (comp, en_lo, en_hi, init_log10FLux) ====
runs cflux command for a component number $comp.
It firstly scans parameter names and freezes all normalizations.
Then in adds cflux command for a given component with energy range between en_lo and en_hi.
The initial guess for log(Flux) if $init_log10FLux, so try to set this value as close as possible to real figure for a flux so that you will not have any problems with fit.
It creates a text file with a name consisted of the name of a component for which flux was calculated as well energy ranges.
The upped and lower limits are 90%

====calc_eqw (comp, conf_level) ===
runs eqwidth command for a given component and finds error after 100 trials in conf_level confidence interval.
It returns eqw value for the first dataset (for instance, if you use NuSTAR data with A and B modules, xspec returns TWO values of the equivalent width for two datsets.)




