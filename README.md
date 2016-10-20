```shell
`
# get a copy
git clone git@github.com:rickedanielson/diag.heat.flux.git

# requirements on ubuntu 14.04 (local) and at Ifremer (12.04)
julia (http://julialang.org/)
alias  jjj 'julia $HOME/bin/\!*'
alias wrks 'cd ~/work/works; ls'
GNU parallel (http://www.gnu.org/software/parallel/)

# download (by NCAR script) and unpack the ICOADS data
wrks ; cd coads ; navigate to http://rda.ucar.edu/datasets/ds540.0/index.html#!access
       tar xvf IMMA1_R3.0_BETA3_CLEAN_1998_2000.tar ; rm ICOADS_R3_Beta3_1998* ICOADS_R3_Beta3_19990*
       tar xvf IMMA1_R3.0_BETA3_CLEAN_2001-2002.tar
       tar xvf IMMA1_R3.0_BETA3_CLEAN_2003-2004.tar
       tar xvf IMMA1_R3.0_BETA3_CLEAN_2005.tar
       tar xvf IMMA1_R3.0_BETA3_CLEAN_2006.tar
       tar xvf IMMA1_R3.0_BETA3_CLEAN_2007.tar
       tar xvf IMMA1_R3.0_BETA3_CLEAN_2008.tar
       tar xvf IMMA1_R3.0_BETA3_CLEAN_2009.tar

# assemble daily average COARE flux files (either at Ifremer or locally)
wrks ; cd coads
       ls -1 | grep -E '^ICOADS' | grep -E  'gz$' | /home5/begmeil/tools/gogolist/bin/gogolist.py -e   gunzip --mem=2000mb
       ls -1 | grep -E '^ICOADS' | grep -E 'dat$' | /home5/begmeil/tools/gogolist/bin/gogolist.py -e "julia /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.jl" --mem=2000mb
       ls -1 | grep -E '^ICOADS' | grep -E 'lux$' | /home5/begmeil/tools/gogolist/bin/gogolist.py -e "julia /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.collate.jl"
       ls -1 | grep -E '^ICOADS' | grep -E  'gz$' |                                      parallel -j 7 gunzip
       ls -1 | grep -E '^ICOADS' | grep -E 'dat$' |                                      parallel -j 7                                    "jjj coads.gts.ncepnrt.jl"
       ls -1 | grep -E '^ICOADS' | grep -E 'lux$' |                                      parallel -j 7                                    "jjj coads.gts.ncepnrt.heat.flux.collate.jl"

### (this step can be skipped) identify the location of individual observations
wrks ; mkdir all ; cat coads/ICOADS*dat.flux > all/all.flux ; cd all
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux /home/cercache/users/rdaniels/topography/elev.0.25-deg.nc
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux /home/ricani/data/topography/elev.0.25-deg.nc
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate all.flux.locate" ; mv plot.ocean.heat.flux.dots.all.flux.locate.png plot.locate

# identify all locations with at least one daily-average observation
wrks ; mkdir all ; cat coads/ICOADS*dat.flux.daily > all/all.flux.daily ; cd all
       mkdir plot.available plot.histogr plot.locate
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux.daily /home/cercache/users/rdaniels/topography/elev.0.25-deg.nc
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux.daily /home/ricani/data/topography/elev.0.25-deg.nc
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate"
       mv plot.ocean.heat.flux.dots*locate*png plot.locate

# make an initial split of the daily-average observations into cal/val/extra groups (based only on insitu, and not analysis, availability)
wrks ; cd all
       jjj coads.gts.ncepnrt.heat.flux.collate.split.jl all.flux.daily.locate
       jjj coads.gts.ncepnrt.heat.flux.collate.split.jl all.flux.daily.locate_2.0_valid
       jjj coads.gts.ncepnrt.heat.flux.collate.split.jl all.flux.daily.locate_2.0_valid_2.0_valid
       mv all.flux.daily.locate_2.0_valid                     all.flux.daily.locate_2.0_calib_remainder
       mv all.flux.daily.locate_2.0_valid_2.0_calib           all.flux.daily.locate_2.0_valid
       mv all.flux.daily.locate_2.0_valid_2.0_valid           all.flux.daily.locate_2.0_valid_remainder
       mv all.flux.daily.locate_2.0_valid_2.0_valid_2.0_calib all.flux.daily.locate_2.0_extra
       mv all.flux.daily.locate_2.0_valid_2.0_valid_2.0_valid all.flux.daily.locate_2.0_extra_remainder
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate"
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib"
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib_remainder"
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid"
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid_remainder"
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra"
       xvfb-run -a grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra_remainder"
       mv plot.ocean.heat.flux.dots*locate*png plot.locate

# further split the in situ cal/val observations by location and store files in an insitu dir
wrks ; mkdir insitu
       sort -k5,5 -k6,6 -k4,4 all/all.flux.daily > all.flux.daily.sort
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.collate.split.location.jl ::: all/all.flux.daily.locate_2.0_????? ::: all.flux.daily.sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       cd insitu ; ls -1 ins* | grep -v OHF > z.list ; cd .. ; wc insitu/z.list
       rm all.flux.daily.sort

# create local links to all analysis data files and example ncdumps too
wrks ; mkdir cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble bestest
       cd /home/cercache/users/rdaniels/work/works/cfsr        ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/cfsr
       cd /home/cercache/users/rdaniels/work/works/erainterim  ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/erainterim
       cd /home/cercache/users/rdaniels/work/works/hoaps       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/hoaps
       cd /home/cercache/users/rdaniels/work/works/ifremerflux ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/ifremerflux
       cd /home/cercache/users/rdaniels/work/works/jofuro      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/jofuro
       cd /home/cercache/users/rdaniels/work/works/merra       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/merra
       cd /home/cercache/users/rdaniels/work/works/oaflux      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/oaflux
       cd /home/cercache/users/rdaniels/work/works/seaflux     ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/seaflux
       cd /home/cercache/users/rdaniels/work/works/ensemble    ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/products/turbulent-fluxes/ensemble
       cd /home/cercache/users/rdaniels/work/works/bestest     ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/products/turbulent-fluxes/best-estimate
wrks ; mkdir ncdump
       ncdump               cfsr/cfsr-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/cfsr
       ncdump   erainterim/erainterim-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/erainterim
       ncdump             hoaps/hoaps-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/hoaps
       ncdump ifremerflux/ifremerflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/ifremerflux
       ncdump           jofuro/jofuro-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/jofuro
       ncdump             merra/merra-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/merra
       ncdump           oaflux/oaflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/oaflux
       ncdump         seaflux/seaflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/seaflux
       ncdump       ensemble/ensemble-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/ensemble
       ncdump    bestest/bestestimate-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/bestest

### assemble a large third dataset for analysis evaulation (with respect to the 2.0_extra_remainder in situ obs)
wrks ; cd all ; jjj analysis.evaluation.assemble.insitu.jl all.flux.daily all.flux.daily.locate_2.0_extra_remainder ; cd ..
#      cd .. ; mv all/all.flux.dailyall.flux.daily.locate_2.0_extra_remainder      all/all.flux.daily.locate_2.0_extra_remainder_obs
       sort -k4,4 -k5,5 -k6,6   all/all.flux.daily.locate_2.0_extra_remainder_obs >    all.flux.daily.locate_2.0_extra_remainder_obs.sort
       split -l 321644              all.flux.daily.locate_2.0_extra_remainder_obs.sort all.flux.daily.locate_2.0_extra_remainder_obs
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.assemble.analyses.jl ::: all.flux.daily.locate_2.0_extra_remainder_obs?? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble bestest | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.cfsr        | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.cfsr
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.erainterim  | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.erainterim
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.hoaps       | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.hoaps
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.ifremerflux | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.ifremerflux
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.jofuro      | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.jofuro
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.merra       | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.merra
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.oaflux      | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.oaflux
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.seaflux     | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.seaflux
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.ensemble    | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.ensemble
       cat all.flux.daily.locate_2.0_extra_remainder_obs??.bestest     | sort > all/all.flux.daily.locate_2.0_extra_remainder_obs.bestest
       wc all/all.flux.daily.locate_2.0_extra_remainder_obs all/all.flux.daily.locate_2.0_extra_remainder_obs.*
       rm all.flux.daily.locate_2.0_extra_remainder_obs*

### perform an initial eight-analysis evaulation, but without calibration (versus the 2.0_extra_remainder obs)
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.versus.insitu.jl all/all.flux.daily.locate_2.0_extra_remainder_obs ::: shfx lhfx wspd airt sstt shum | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       cd all ; cat *shfx.summ *lhfx.summ *wspd.summ *airt.summ *sstt.summ *shum.summ

# return to the cal/val locations to create analysis timeseries (some locations missing too much of this timeseries might be later ignored)
wrks ; sort     all/all.flux.daily.locate_2.0_calib    > all.flux.daily.locate_2.0_calib.sort
       split -l 401 all.flux.daily.locate_2.0_calib.sort all.flux.daily.locate_2.0_calib.sort
       sort     all/all.flux.daily.locate_2.0_valid    > all.flux.daily.locate_2.0_valid.sort
       split -l 400 all.flux.daily.locate_2.0_valid.sort all.flux.daily.locate_2.0_valid.sort
       sort     all/all.flux.daily.locate_2.0_extra    > all.flux.daily.locate_2.0_extra.sort
       split -l 400 all.flux.daily.locate_2.0_extra.sort all.flux.daily.locate_2.0_extra.sort
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.jl ::: all.flux.daily.locate_2.0_?????.sort?? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble bestest | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm all.flux.daily.locate_2.0_?????.sor*

# verify that each subdir contains the expected number of files (e.g., 4010 + 3578 + 3355 = 10943 files with 3745 dates)
wrks ; cd cfsr        ; ls -1 cfs* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd erainterim  ; ls -1 era* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd hoaps       ; ls -1 hoa* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd ifremerflux ; ls -1 ifr* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd merra       ; ls -1 mer* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd oaflux      ; ls -1 oaf* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd seaflux     ; ls -1 sea* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd jofuro      ; ls -1 jof* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd ensemble    ; ls -1 ens* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd bestest     ; ls -1 bes* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       wc *[a-z]/z.list

### plot examples of temporal coverage by all analyses (include in situ) at a few locations
wrks ; xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.available.jl ....45.000...-48.500
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.available.jl ....55.000...-12.500
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.available.jl ....48.750...-12.500
       mv plot.avail.* all/plot.available

### plot histograms
wrks ; echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.histogram.jl z.list > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.histoplot.jl
       gzip histogr*dat ; mv histogr* all/plot.histogr

# create the forward and backward extrapolated timeseries (save old extrapolations first)
wrks ; cd cfsr        ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd erainterim  ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd hoaps       ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd ifremerflux ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd merra       ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd oaflux      ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd seaflux     ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd jofuro      ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd ensemble    ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
       cd bestest     ; mkdir new_bef_aft ; mv *.bef *.aft *.bet *.aff new_bef_aft ; cd ..
wrks ; cd cfsr ; ls z.list?? ; cd ..
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.unextrapolated.jl ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble bestest ::: z.listaa z.listab z.listac z.listad z.listae z.listaf z.listag z.listah z.listai z.listaj z.listak | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb

# plot extrapolation histograms (forward and backward versus the actual values for assessment of bias in the extrapolation method)
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histogram.jl ::: z.list | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl        cfsr
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl  erainterim
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl       hoaps
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl ifremerflux
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl      jofuro
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl       merra
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl      oaflux
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl     seaflux
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl    ensemble
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.histoplot.jl     bestest
       gzip extrapolated.histogr*dat extrapolated.xcom ; mv extrapolated* all/plot.histogr

# identify the subset of the ICOADS cal/val locations for which analyses are also available for much of 2001-2007 (call these the collocations)
wrks ; mkdir fft
       split -l 400 all/all.flux.daily.locate_2.0_calib all.flux.daily.locate_2.0_calib
       split -l 400 all/all.flux.daily.locate_2.0_valid all.flux.daily.locate_2.0_valid
       split -l 400 all/all.flux.daily.locate_2.0_extra all.flux.daily.locate_2.0_extra
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.jl ::: all.flux.daily.locate_2.0_??????? ::: shfx lhfx wspd airt sstt shum | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       cat all.flux.daily.locate_2.0_calib??.shfx.got2000 | sort > all/all.flux.daily.locate_2.0_calib.shfx.got2000
       cat all.flux.daily.locate_2.0_calib??.shfx.not2000 | sort > all/all.flux.daily.locate_2.0_calib.shfx.not2000
       cat all.flux.daily.locate_2.0_valid??.shfx.got2000 | sort > all/all.flux.daily.locate_2.0_valid.shfx.got2000
       cat all.flux.daily.locate_2.0_valid??.shfx.not2000 | sort > all/all.flux.daily.locate_2.0_valid.shfx.not2000
       cat all.flux.daily.locate_2.0_calib??.lhfx.got2000 | sort > all/all.flux.daily.locate_2.0_calib.lhfx.got2000
       cat all.flux.daily.locate_2.0_calib??.lhfx.not2000 | sort > all/all.flux.daily.locate_2.0_calib.lhfx.not2000
       cat all.flux.daily.locate_2.0_valid??.lhfx.got2000 | sort > all/all.flux.daily.locate_2.0_valid.lhfx.got2000
       cat all.flux.daily.locate_2.0_valid??.lhfx.not2000 | sort > all/all.flux.daily.locate_2.0_valid.lhfx.not2000
       cat all.flux.daily.locate_2.0_calib??.wspd.got2000 | sort > all/all.flux.daily.locate_2.0_calib.wspd.got2000
       cat all.flux.daily.locate_2.0_calib??.wspd.not2000 | sort > all/all.flux.daily.locate_2.0_calib.wspd.not2000
       cat all.flux.daily.locate_2.0_valid??.wspd.got2000 | sort > all/all.flux.daily.locate_2.0_valid.wspd.got2000
       cat all.flux.daily.locate_2.0_valid??.wspd.not2000 | sort > all/all.flux.daily.locate_2.0_valid.wspd.not2000
       cat all.flux.daily.locate_2.0_calib??.airt.got2000 | sort > all/all.flux.daily.locate_2.0_calib.airt.got2000
       cat all.flux.daily.locate_2.0_calib??.airt.not2000 | sort > all/all.flux.daily.locate_2.0_calib.airt.not2000
       cat all.flux.daily.locate_2.0_valid??.airt.got2000 | sort > all/all.flux.daily.locate_2.0_valid.airt.got2000
       cat all.flux.daily.locate_2.0_valid??.airt.not2000 | sort > all/all.flux.daily.locate_2.0_valid.airt.not2000
       cat all.flux.daily.locate_2.0_calib??.sstt.got2000 | sort > all/all.flux.daily.locate_2.0_calib.sstt.got2000
       cat all.flux.daily.locate_2.0_calib??.sstt.not2000 | sort > all/all.flux.daily.locate_2.0_calib.sstt.not2000
       cat all.flux.daily.locate_2.0_valid??.sstt.got2000 | sort > all/all.flux.daily.locate_2.0_valid.sstt.got2000
       cat all.flux.daily.locate_2.0_valid??.sstt.not2000 | sort > all/all.flux.daily.locate_2.0_valid.sstt.not2000
       cat all.flux.daily.locate_2.0_calib??.shum.got2000 | sort > all/all.flux.daily.locate_2.0_calib.shum.got2000
       cat all.flux.daily.locate_2.0_calib??.shum.not2000 | sort > all/all.flux.daily.locate_2.0_calib.shum.not2000
       cat all.flux.daily.locate_2.0_valid??.shum.got2000 | sort > all/all.flux.daily.locate_2.0_valid.shum.got2000
       cat all.flux.daily.locate_2.0_valid??.shum.not2000 | sort > all/all.flux.daily.locate_2.0_valid.shum.not2000
       cat all.flux.daily.locate_2.0_extra??.shfx.got2000 | sort > all/all.flux.daily.locate_2.0_extra.shfx.got2000
       cat all.flux.daily.locate_2.0_extra??.shfx.not2000 | sort > all/all.flux.daily.locate_2.0_extra.shfx.not2000
       cat all.flux.daily.locate_2.0_extra??.lhfx.got2000 | sort > all/all.flux.daily.locate_2.0_extra.lhfx.got2000
       cat all.flux.daily.locate_2.0_extra??.lhfx.not2000 | sort > all/all.flux.daily.locate_2.0_extra.lhfx.not2000
       cat all.flux.daily.locate_2.0_extra??.wspd.got2000 | sort > all/all.flux.daily.locate_2.0_extra.wspd.got2000
       cat all.flux.daily.locate_2.0_extra??.wspd.not2000 | sort > all/all.flux.daily.locate_2.0_extra.wspd.not2000
       cat all.flux.daily.locate_2.0_extra??.airt.got2000 | sort > all/all.flux.daily.locate_2.0_extra.airt.got2000
       cat all.flux.daily.locate_2.0_extra??.airt.not2000 | sort > all/all.flux.daily.locate_2.0_extra.airt.not2000
       cat all.flux.daily.locate_2.0_extra??.sstt.got2000 | sort > all/all.flux.daily.locate_2.0_extra.sstt.got2000
       cat all.flux.daily.locate_2.0_extra??.sstt.not2000 | sort > all/all.flux.daily.locate_2.0_extra.sstt.not2000
       cat all.flux.daily.locate_2.0_extra??.shum.got2000 | sort > all/all.flux.daily.locate_2.0_extra.shum.got2000
       cat all.flux.daily.locate_2.0_extra??.shum.not2000 | sort > all/all.flux.daily.locate_2.0_extra.shum.not2000
#      sort all/all.flux.daily.locate_2.0_calib > aa ; cat all/all.flux.daily.locate_2.0_calib.shfx.got2000 all/all.flux.daily.locate_2.0_calib.shfx.not2000 | sort > bb ; diff aa bb ; rm aa bb
#      sort all/all.flux.daily.locate_2.0_valid > aa ; cat all/all.flux.daily.locate_2.0_valid.shfx.got2000 all/all.flux.daily.locate_2.0_valid.shfx.not2000 | sort > bb ; diff aa bb ; rm aa bb
#      sort all/all.flux.daily.locate_2.0_extra > aa ; cat all/all.flux.daily.locate_2.0_extra.shfx.got2000 all/all.flux.daily.locate_2.0_extra.shfx.not2000 | sort > bb ; diff aa bb ; rm aa bb
       rmdir fft ; mv commands all.flux.daily.locate_2.0_?????* all/limbo

### plot the location and distribution of the collocations
wrks ; cd all
       echo julia /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.distribution.plot.jl all.flux.daily.locate_2.0_calib.????.got2000 > commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.shfx.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.lhfx.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.wspd.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.airt.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.sstt.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.shum.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.shfx.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.lhfx.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.wspd.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.airt.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.sstt.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.shum.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.shfx.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.lhfx.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.wspd.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.airt.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.sstt.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.shum.got2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.shfx.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.lhfx.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.wspd.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.airt.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.sstt.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.shum.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.shfx.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.lhfx.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.wspd.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.airt.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.sstt.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.shum.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.shfx.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.lhfx.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.wspd.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.airt.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.sstt.not2000\" >> commands
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_extra.shum.not2000\" >> commands ; echo "
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e xvfb-run --mem=2000mb
       mv plot.ocean.heat.flux.dots.all.flux.daily.locate_2.0_?????.????.?ot2000.png plot.locate

### plot the all-collocation-averaged (weighted by daily obs number) one-sided NFFT spectra for each variable and identify submonthly variance
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl  ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000 | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia  --mem=2000mb
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.????.got2000.spec
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.????.got2000.spec
       cd all ; cat *calib.shfx.got2000.spec.stat *calib.lhfx.got2000.spec.stat *calib.wspd.got2000.spec.stat *calib.airt.got2000.spec.stat *calib.sstt.got2000.spec.stat *calib.shum.got2000.spec.stat
                cat *valid.shfx.got2000.spec.stat *valid.lhfx.got2000.spec.stat *valid.wspd.got2000.spec.stat *valid.airt.got2000.spec.stat *valid.sstt.got2000.spec.stat *valid.shum.got2000.spec.stat
       cd .. ; vi coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl

# assemble the insitu and analysis data for a triple collocation cal/val
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.assemble.insitu.jl all/all.flux.daily ::: all/all.flux.daily.locate_2.0_?????.????.got2000     | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.source.jl     ::: all/all.flux.daily.locate_2.0_?????.????.got2000_obs | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia

### perform global and local calibrations of the two extrapolations (BEF and AFT relative to NOW) using the extra collocation set
wrks ; parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.extrapolated.histogram.jl ::: all/all.flux.daily.locate_2.0_extra.????.got2000_obs.com? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.extrapolated.histoplot.jl ::: all/all.flux.daily.locate_2.0_extra.????.got2000_obs.com? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble

# perform a paired triple collocation cal/val globally
wrks ; parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.paired.jl ::: all/all.flux.daily.locate_2.0_calib.????.got2000_obs.com? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble ::: 0.10
       mkdir all/zali.recalib.paired ; mv all/*.cali.pair all/*.recalibrate all/zali.recalib.paired
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired/all.flux.daily.locate_2.0_calib.shfx*cali.pair
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired/all.flux.daily.locate_2.0_calib.lhfx*cali.pair
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired/all.flux.daily.locate_2.0_calib.wspd*cali.pair
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired/all.flux.daily.locate_2.0_calib.airt*cali.pair
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired/all.flux.daily.locate_2.0_calib.sstt*cali.pair
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired/all.flux.daily.locate_2.0_calib.shum*cali.pair
       cat all/zali.recalib.paired/*shfx*.md all/zali.recalib.paired/*lhfx*.md all/zali.recalib.paired/*wspd*.md all/zali.recalib.paired/*airt*.md all/zali.recalib.paired/*sstt*.md all/zali.recalib.paired/*shum*.md > analysis.evaluation.table.coefficients.md
       pandoc analysis.evaluation.table.coefficients.md -o analysis.evaluation.table.coefficients.html
       mv analysis.evaluation.table.coefficients.html analysis.evaluation.table.coefficients.0.10.html
       mv analysis.evaluation.table.coefficients.md   analysis.evaluation.table.coefficients.0.10.md
       mv all/zali.recalib.paired                                    all/zali.recalib.paired.0.10

# perform a paired triple collocation cal/val locally
wrks ; parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.pairlo.jl ::: all/all.flux.daily.locate_2.0_calib.shfx.got2000_obs.com? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble ::: 0.10
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.pairlo.jl ::: all/all.flux.daily.locate_2.0_calib.lhfx.got2000_obs.com? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ensemble ::: 0.10
       mkdir all/zali.recalib.pairlo ; mv all/*.cali.plo* all/zali.recalib.pairlo ; lst all/zali.recalib.pairlo/*cali.ploc
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.pairlo/all.flux.daily.locate_2.0_calib.shfx*cali.ploc
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.pairlo/all.flux.daily.locate_2.0_calib.lhfx*cali.ploc
       cat all/zali.recalib.pairlo/*shfx*.md all/zali.recalib.pairlo/*lhfx*.md > analysis.evaluation.table.coefficients.pairlo.md
       pandoc analysis.evaluation.table.coefficients.pairlo.md -o analysis.evaluation.table.coefficients.pairlo.html
       mv analysis.evaluation.table.coefficients.pairlo.html analysis.evaluation.table.coefficients.pairlo.0.10.html
       mv analysis.evaluation.table.coefficients.pairlo.md   analysis.evaluation.table.coefficients.pairlo.0.10.md
       mv all/zali.recalib.pairlo                                           all/zali.recalib.pairlo.0.10





# perform a paired triple collocation cal/val globally (MORPH = true)
       mkdir all/zali.recalib.paired.morph
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.paired.jl ::: all/all.flux.daily.locate_2.0_calib.????.got2000_obs.com? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
       mv all/*.cali.pair.morph all/zali.recalib.paired.morph ; cat all/zali.recalib.paired.morph/*cali.pair.morph
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired.morph/all.flux.daily.locate_2.0_calib.shfx*cali.pair.morph
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired.morph/all.flux.daily.locate_2.0_calib.lhfx*cali.pair.morph
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired.morph/all.flux.daily.locate_2.0_calib.wspd*cali.pair.morph
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired.morph/all.flux.daily.locate_2.0_calib.airt*cali.pair.morph
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired.morph/all.flux.daily.locate_2.0_calib.sstt*cali.pair.morph
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.paired.morph/all.flux.daily.locate_2.0_calib.shum*cali.pair.morph
       cat all/zali.recalib.paired.morph/*shfx*.md all/zali.recalib.paired.morph/*lhfx*.md all/zali.recalib.paired.morph/*wspd*.md all/zali.recalib.paired.morph/*airt*.md all/zali.recalib.paired.morph/*sstt*.md all/zali.recalib.paired.morph/*shum*.md > analysis.evaluation.table.coefficients.morph.md
       pandoc analysis.evaluation.table.coefficients.morph.md -o analysis.evaluation.table.coefficients.morph.html

# perform a global triple collocation cal/val (GLOBAL = true; RECALIB = false then true) and compare calibrated and uncalibrated RMSE
wrks ; mkdir all/zali.recalib.false all/zali.recalib.true
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl        ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comb
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.cfsr.jl   ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.coml
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jofuro.jl ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comt
       mv all/*cali.glob all/zali.recalib.false
       cat               all/zali.recalib.false/*cali.glob | grep const | grep AIR
       cat               all/zali.recalib.false/*cali.glob | grep const | grep SST
       cat               all/zali.recalib.false/*cali.glob | grep const | grep LHF
       cat               all/zali.recalib.false/*cali.glob | grep const | grep -v LHF | grep -v SST | grep -v AIR
       vi coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.*               (and inject the various alpha and beta)
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl        ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comb
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.cfsr.jl   ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.coml
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jofuro.jl ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comt
       mv all/*cali.glob all/zali.recalib.true
       cat               all/zali.recalib.false/*cali.glob | grep cfsr
       cat               all/zali.recalib.true/*cali.glob  | grep cfsr
       cat               all/zali.recalib.false/*cali.glob | grep erainterim
       cat               all/zali.recalib.true/*cali.glob  | grep erainterim
       cat               all/zali.recalib.false/*cali.glob | grep hoaps
       cat               all/zali.recalib.true/*cali.glob  | grep hoaps
       cat               all/zali.recalib.false/*cali.glob | grep ifremerflux
       cat               all/zali.recalib.true/*cali.glob  | grep ifremerflux
       cat               all/zali.recalib.false/*cali.glob | grep jofuro
       cat               all/zali.recalib.true/*cali.glob  | grep jofuro
       cat               all/zali.recalib.false/*cali.glob | grep merra
       cat               all/zali.recalib.true/*cali.glob  | grep merra
       cat               all/zali.recalib.false/*cali.glob | grep oaflux
       cat               all/zali.recalib.true/*cali.glob  | grep oaflux
       cat               all/zali.recalib.false/*cali.glob | grep seaflux
       cat               all/zali.recalib.true/*cali.glob  | grep seaflux

# perform a local triple collocation cal/val (GLOBAL = false; RECALIB = false then true) and compare calibrated and uncalibrated RMSE
wrkt ; mkdir all/zali.recalib.local
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl        ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comb
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.cfsr.jl   ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.coml
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jofuro.jl ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comt
       mv all/*cali.locl all/zali.recalib.false
       cat               all/zali.recalib.false/*cali.locl | grep const
       vi  diag.trajectory.drifters.colloc.discrete.triple.jl                 (and inject the various alpha and beta)
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl        ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comb
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.cfsr.jl   ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.coml
       parallel julia ~/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jofuro.jl ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comt
       mv all/*cali.glob all/zali.recalib.local
       cat               all/zali.recalib.false/*cali.glob | grep total
       cat               all/zali.recalib.true/*cali.glob  | grep total
       cat               all/zali.recalib.local/*cali.glob | grep total

# plot local calibration and performance as a function of the variable of interest
wrkt ; cd all
       jjj diag.trajectory.drifters.evaluation.calval.plot.jl all/zali.recalib.false/*cali.locl

# convert the triple collocation cal/val results to markdown
wrks ; cd all/zali.recalib.false
       jjj analysis.evaluation.table.performance.jl all.flux.daily.locate_2.0_calib*glob
       cat all.flux.daily.locate_2.0_calib.shfx.got2000_obs.comb.cali.glob.md all.flux.daily.locate_2.0_calib.lhfx.got2000_obs.coml.cali.glob.md all.flux.daily.locate_2.0_calib.wspd.got2000_obs.comb.cali.glob.md all.flux.daily.locate_2.0_calib.shum.got2000_obs.comb.cali.glob.md all.flux.daily.locate_2.0_calib.sstt.got2000_obs.comt.cali.glob.md all.flux.daily.locate_2.0_calib.airt.got2000_obs.comt.cali.glob.md > analysis.evaluation.table.performance.md
       pandoc analysis.evaluation.table.performance.md -o analysis.evaluation.table.performance.html

# perform a local triple collocation cal/val and convert the second-order polynomial coeffs to tables
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl        ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comb | grep flux | sort  > commands
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jofuro.jl ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comt | grep flux | sort >> commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia
       cd all
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_calib.airt.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_calib.lhfx.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_calib.shfx.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_calib.shum.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_calib.sstt.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_calib.wspd.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_valid.airt.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_valid.lhfx.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_valid.shfx.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_valid.shum.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_valid.sstt.got2000_obs.com?.*
       jjj analysis.evaluation.table.coefficients.jl all.flux.daily.locate_2.0_valid.wspd.got2000_obs.com?.*
       cat all.flux.daily.locate_2.0_calib.shfx.got2000_obs.trip.metrics all.flux.daily.locate_2.0_calib.lhfx.got2000_obs.trip.metrics all.flux.daily.locate_2.0_calib.wspd.got2000_obs.trip.metrics all.flux.daily.locate_2.0_calib.shum.got2000_obs.trip.metrics all.flux.daily.locate_2.0_calib.sstt.got2000_obs.trip.metrics all.flux.daily.locate_2.0_calib.airt.got2000_obs.trip.metrics > analysis.evaluation.table.coefficients.md
       pandoc analysis.evaluation.table.coefficients.md -o analysis.evaluation.table.coefficients.html

# for job submission from vepocean rather than cerhouse (when the latter is unavailable)
 cd ; mkdir workspace_tmp
 cat ~/commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia -w /home1/homedir1/perso/rdaniels/workspace_tmp
 with
 cdh = "/home/cercache/users/rdaniels/work/works"
 try cd(cdh) catch err
   write(STDERR, "ERROR : ¯\_(ツ)_/¯ couldn't cd($cdh)\n")
   exit(-1)
 end
 print("\ncd $cdh\n\n")

# other commands
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.pairlo/all.flux.daily.locate_2.0_calib.wspd*cali.ploc
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.pairlo/all.flux.daily.locate_2.0_calib.airt*cali.ploc
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.pairlo/all.flux.daily.locate_2.0_calib.sstt*cali.ploc
       jjj analysis.evaluation.table.performance.paired.jl all/zali.recalib.pairlo/all.flux.daily.locate_2.0_calib.shum*cali.ploc
       cat all/zali.recalib.pairlo/*shfx*.md all/zali.recalib.pairlo/*lhfx*.md all/zali.recalib.pairlo/*wspd*.md all/zali.recalib.pairlo/*airt*.md all/zali.recalib.pairlo/*sstt*.md all/zali.recalib.pairlo/*shum*.md > analysis.evaluation.table.coefficients.pairlo.md
