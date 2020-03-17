#@/Users/s.bykov/work/xray_pulsars/nustar/python_nu_pipeline/xspec_utils.tcl

proc writetext { {name output.txt} {error_run 0} {rebin_plot 50} {prefix mymodel}} {
# writes a bunch of information to a single line of a FITS file
query yes
set prefix [concat ${prefix}_]

# first check if the user input a ? for help

    if {0} {
       puts "Usage: writefits FITSfile"
       puts "Writes information to a single line a FITS file."
       puts "This script requires only one dataset to have been read in. The"
       puts "ERROR COMMAND SHOULD HAVE BEEN RUN for any parameters for which"
       puts "error output is required"
       puts " "
       puts "kaa  v1.0  11/06/08"
       puts "upgraded by sbykov in Feb 2020"
       puts "uses all parameters even if they are frozen"
       puts "creates txt file instead of FITS, with all parameters with errors (zero if no error command has been run or the parameter is frozen)"
       puts "in xspec: /path/@writetext.tcl to initiate a script, then use writefits filename.txt"
       return
    }

# now check that the user actually has data read in and a model set up

    set prompt "XSPEC12>"

    if {[tcloutr modcomp] == "0"} {
       puts "You must set up a model first"
       return
    }
    if {[tcloutr datasets] == "0"} {
       puts "You must set read in data first"
       return
    }

# parse the arguments - txt outfile



# get the exposure time

    set time [tcloutr expos]

# we will need to know the number of parameters

    set numpar [tcloutr modpar]


    if {$error_run==1} {
    fit
    parallel error $numpar
    error 1-$numpar
    }

# get the parameter information

    for {set ipar 1} {$ipar <= $numpar} {incr ipar} {
	if {[scan [tcloutr param $ipar] "%f %f" tmp1 tmp2] == 2} {
            set sparval($ipar) $tmp1
            set spardel($ipar) $tmp2
	    scan [tcloutr error $ipar] "%f %f" sparerrlow($ipar) sparerrhi($ipar)
        } else {
            set sparval($ipar) $tmp1
            set spardel($ipar) -1
        }
    }
#get MJD info
    set mjd [tcloutr fileinfo mjd-obs 1]
# get the statistic value

    tclout dof
    set dof $xspec_tclout

    tclout stat
    set stat $xspec_tclout

    set dof [lindex $dof 0]

    set chi_r [format "%.3f" [expr {$stat/$dof}]]



# open a text version of the output file

    set fileid [open ${name} w]

# write the text output

    set outstr "${prefix}exposure ${prefix}MJD ${prefix}chi2_red ${prefix}dof"
    for {set ipar 1} {$ipar <= $numpar} {incr ipar} {

	    scan [tcloutr pinfo $ipar] "%s %s" pname punit
	    append outstr " [concat $prefix$pname$ipar  ]"
	    append outstr " [concat $prefix$pname${ipar}_lo ]"
        append outstr " [concat $prefix$pname${ipar}_hi ]"

    }

    append outstr "\n$time $mjd $chi_r $dof "
    for {set ipar 1} {$ipar <= $numpar} {incr ipar} {

	    append outstr "$sparval($ipar) $sparerrlow($ipar) $sparerrhi($ipar) "

    }

    puts $fileid $outstr

    save model mymodel.xcm

    close $fileid

    #create a gif plot of eeufs del ra
    fit 1000
    setpl en
    rm -f ${prefix}spectra.gif
    cpd ${prefix}spectra.gif/VGIF
    plot eeufs del ra
    cpd none
    rm ${prefix}spectra.gif
    mv ${prefix}spectra.gif_2 spectra.gif


    cpd vgif

    #create plot points for each specta

    set sp_num [tcloutr datasets]

    for {set j 1} {$j <= $sp_num} {incr j} {
    setplot rebin $rebin_plot $rebin_plot $j
    rm -f spectra${j}.dat
    set f [open ${prefix}spectra${j}.dat w]
    puts $f [tcloutr plot eeufs x $j]
    puts $f [tcloutr plot eeufs y $j]
    puts $f [tcloutr plot eeufs yerr $j]
    puts $f [tcloutr plot eeufs model $j]
    puts $f [tcloutr plot delchi y $j]
    close $f

    rm -f vgif
    }

}



proc calc_flux { comp {elow 3} {ehi 10} {logF -9} {prefix mymodel} }  {
query yes
set prefix [concat ${prefix}_]


scan [tcloutr compinfo $comp] "%s %f %f" comp_name tmp tmp

set flux_name [concat ${comp_name}_${elow}_${ehi}]

rm -f ./tmp.xcm
save model ./tmp.xcm
sed '/^mdefine/ d' ./tmp.xcm > ./tmp_2.xcm
#sed '/mul/ s/$/ :/' ./tmp.xcm > ./tmp_2.xcm
rm ./tmp.xcm
mv ./tmp_2.xcm ./tmp.xcm

#chi square of an initial model to see if chi2 changes
tclout dof
set dof $xspec_tclout

tclout stat
set stat $xspec_tclout

set dof [lindex $dof 0]

set chi_r_init [format "%.3f" [expr {$stat/$dof}]]


#iterate over parameters and freeze if it is a norm
   set numpar [tcloutr modpar]
    for {set ipar 1} {$ipar <= $numpar} {incr ipar} {
        scan [tcloutr pinfo $ipar] "%s %s" pname punit
        if {$pname=="norm"} {
        freeze $ipar
        }

}



addcomp $comp cflux
$elow
$ehi
$logF


fit 1000

   set numpar [tcloutr modpar]
    for {set ipar 1} {$ipar <= $numpar} {incr ipar} {
        scan [tcloutr pinfo $ipar] "%s %s" pname punit
        if {$pname=="lg10Flux"} {
        set ipar_flux $ipar
        break
        }

}
#second iteration: use obtained flux as an initial value
set logF [tcloutr par $ipar_flux]
@tmp.xcm

fit
fit 1000

#iterate over parameters and freeze if it is a norm
   set numpar [tcloutr modpar]
    for {set ipar 1} {$ipar <= $numpar} {incr ipar} {
        scan [tcloutr pinfo $ipar] "%s %s" pname punit
        if {$pname=="norm"} {
        freeze $ipar
        }

}

addcomp $comp cflux
$elow
$ehi
$logF


fit 1000

tclout dof
set dof $xspec_tclout

tclout stat
set stat $xspec_tclout

set dof [lindex $dof 0]

set chi_r_final [format "%.3f" [expr {$stat/$dof}]]
#if difference between chi2 values is greater than 0.005, throw an error
if {[expr {abs($chi_r_final-$chi_r_init)}]>0.005} {
    @tmp.xcm
    fit 1000
    puts $stopvarname
    exit
    }

error $ipar_flux

tclout par $ipar_flux
set flux $xspec_tclout
tclout error $ipar_flux
set flux_err $xspec_tclout


@tmp.xcm


fit
fit 1000
rm -f ./tmp.xcm

rm -f flux_${flux_name}.txt
set fileid [open flux_${flux_name}.txt w]

set outstr "${prefix}flux_${flux_name} ${prefix}flux_${flux_name}_lo ${prefix}flux_${flux_name}_hi \n"
append outstr "[lindex $flux 0] [lindex $flux_err 0] [lindex $flux_err 1]"
puts $fileid $outstr
close $fileid


}



proc calc_eqw { comp {conf_int 68} {prefix mymodel} } {
query yes
fit 1000
set prefix [concat ${prefix}_]

query yes
scan [tcloutr compinfo $comp] "%s %f %f" comp_name tmp tmp

set eqw_name [concat ${comp_name}]


try {
eqw $comp  err 100 $conf_int
tclout eqwidth 1
set eqw $xspec_tclout

} on error {result options} {
echo 'eqw err fail'
eqw $comp
tclout eqwidth 1
set eqw $xspec_tclout
set eqw [list [lindex $eqw 0] [lindex $eqw 1] [lindex $eqw 0]]
}


rm -f eqw_${eqw_name}.txt
set fileid [open eqw_${eqw_name}.txt w]

set outstr "${prefix}eqw_${eqw_name} ${prefix}eqw_${eqw_name}_lo ${prefix}eqw_${eqw_name}_hi \n"
append outstr "[lindex $eqw 0] [lindex $eqw 1] [lindex $eqw 2]"
puts $fileid $outstr
close $fileid


}

