```shell
`
# get a copy
git clone git@github.com:rickedanielson/diag.heat.flux.git

# requirements on ubuntu 14.04 (local) and at Ifremer (12.04)
julia (http://julialang.org/)
GNU parallel (http://www.gnu.org/software/parallel/)
alias wrks 'cd ~/work/works; ls'

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

# (this step can be skipped) identify the location of individual observations
wrks ; mkdir all ; cat coads/ICOADS*dat.flux > all/all.flux ; cd all
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux /home/cercache/users/rdaniels/topography/elev.0.25-deg.nc
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux /home/ricani/data/topography/elev.0.25-deg.nc
       grads -blc "coads.gts.ncepnrt.heat.flux.locate all.flux.locate" ; di plot.ocean.heat.flux.dots.all.flux.locate.png

# identify all locations with at least one daily-average observation
wrks ; mkdir all ; cat coads/ICOADS*dat.flux.daily > all/all.flux.daily ; cd all
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux.daily /home/cercache/users/rdaniels/topography/elev.0.25-deg.nc
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux.daily /home/ricani/data/topography/elev.0.25-deg.nc
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate" ; di plot.ocean.heat.flux.dots.all.flux.daily.locate.png

# make an initial split of the daily-average observations into cal/val groups (based only on insitu, and not analysis, availability)
wrks ; cd all
       jjj coads.gts.ncepnrt.heat.flux.collate.split.jl all.flux.daily.locate
       jjj coads.gts.ncepnrt.heat.flux.collate.split.jl all.flux.daily.locate_2.0_valid
       mv all.flux.daily.locate_2.0_valid           all.flux.daily.locate_2.0_calib_remainder
       mv all.flux.daily.locate_2.0_valid_2.0_calib all.flux.daily.locate_2.0_valid
       mv all.flux.daily.locate_2.0_valid_2.0_valid all.flux.daily.locate_2.0_valid_remainder
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate"
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib"
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib_remainder"
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid"
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid_remainder"
       di plot.ocean.heat.flux.dots.all.flux.daily*png

# further split the in situ cal/val observations by location and store files in an insitu dir
wrks ; mkdir insitu
       sort -k5,5 -k6,6 -k4,4 all/all.flux.daily > all.flux.daily.sort
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.collate.split.location.jl ::: all/all.flux.daily.locate_2.0_?ali? ::: all.flux.daily.sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       cd insitu ; ls -1 ins* | grep -v OHF > z.list ; cd .. ; wc insitu/z.list
       rm all.flux.daily.sort

# create local links to all analysis data files and example ncdumps too
wrks ; mkdir cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
       cd /home/cercache/users/rdaniels/work/works/cfsr        ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/cfsr
       cd /home/cercache/users/rdaniels/work/works/erainterim  ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/erainterim
       cd /home/cercache/users/rdaniels/work/works/hoaps       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/hoaps
       cd /home/cercache/users/rdaniels/work/works/ifremerflux ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/ifremerflux
       cd /home/cercache/users/rdaniels/work/works/jofuro      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/jofuro
       cd /home/cercache/users/rdaniels/work/works/merra       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/merra
       cd /home/cercache/users/rdaniels/work/works/oaflux      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/oaflux
       cd /home/cercache/users/rdaniels/work/works/seaflux     ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/seaflux
wrks ; mkdir ncdump
       ncdump               cfsr/cfsr-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/cfsr
       ncdump   erainterim/erainterim-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/erainterim
       ncdump             hoaps/hoaps-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/hoaps
       ncdump ifremerflux/ifremerflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/ifremerflux
       ncdump           jofuro/jofuro-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/jofuro
       ncdump             merra/merra-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/merra
       ncdump           oaflux/oaflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/oaflux
       ncdump         seaflux/seaflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/seaflux

# assemble a large third dataset for analysis evaulation (with respect to the 2.0_valid_remainder in situ obs)
wrks ; cd all ; jjj analysis.evaluation.assemble.insitu.jl all.flux.daily all.flux.daily.locate_2.0_valid_remainder ; cd ..
#      cd .. ; mv all/all.flux.dailyall.flux.daily.locate_2.0_valid_remainder      all/all.flux.daily.locate_2.0_valid_remainder_obs
       sort -k4,4 -k5,5 -k6,6   all/all.flux.daily.locate_2.0_valid_remainder_obs >    all.flux.daily.locate_2.0_valid_remainder_obs.sort
       split -l 321644              all.flux.daily.locate_2.0_valid_remainder_obs.sort all.flux.daily.locate_2.0_valid_remainder_obs
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.assemble.analyses.jl ::: all.flux.daily.locate_2.0_valid_remainder_obs?? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.cfsr        | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.cfsr
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.erainterim  | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.erainterim
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.hoaps       | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.hoaps
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.ifremerflux | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.ifremerflux
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.jofuro      | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.jofuro
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.merra       | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.merra
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.oaflux      | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.oaflux
       cat all.flux.daily.locate_2.0_valid_remainder_obs??.seaflux     | sort > all/all.flux.daily.locate_2.0_valid_remainder_obs.seaflux
       wc all/all.flux.daily.locate_2.0_valid_remainder_obs all/all.flux.daily.locate_2.0_valid_remainder_obs.*
       rm commands all.flux.daily.locate_2.0_valid_remainder_obs*

# perform an initial eight-analysis evaulation, but without calibration (versus the 2.0_valid_remainder obs)
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.versus.insitu.jl all/all.flux.daily.locate_2.0_valid_remainder_obs ::: shfx lhfx wspd airt sstt shum | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands ; cd all ; cat *shfx.summ *lhfx.summ *wspd.summ *airt.summ *sstt.summ *shum.summ

# return to the cal/val locations to create analysis timeseries (some locations missing too much of this timeseries are later ignored)
wrks ; sort     all/all.flux.daily.locate_2.0_calib    > all.flux.daily.locate_2.0_calib.sort
       split -l 401 all.flux.daily.locate_2.0_calib.sort all.flux.daily.locate_2.0_calib.sort
       sort     all/all.flux.daily.locate_2.0_valid    > all.flux.daily.locate_2.0_valid.sort
       split -l 400 all.flux.daily.locate_2.0_valid.sort all.flux.daily.locate_2.0_valid.sort
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.jl ::: all.flux.daily.locate_2.0_?ali?.sort?? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands all.flux.daily.locate_2.0_?ali?.sor*

# verify that each subdir contains the expected number of files (e.g., 4010 + 3578 = 7588 files with 3745 dates)
wrks ; cd cfsr        ; ls -1 cfs* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd erainterim  ; ls -1 era* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd hoaps       ; ls -1 hoa* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd ifremerflux ; ls -1 ifr* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd merra       ; ls -1 mer* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd oaflux      ; ls -1 oaf* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd seaflux     ; ls -1 sea* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       cd jofuro      ; ls -1 jof* | grep -v OHF | grep -v .bef | grep -v .aft > z.list ; split -l 1000 z.list z.list ; cd ..
       wc *[a-z]/z.list

# plot examples of temporal coverage by all analyses (include in situ) at a few locations
wrks ; xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.available.jl ....45.000...-48.500
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.available.jl ....55.000...-12.500
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.available.jl ....48.750...-12.500

# create the forward and backward extrapolated timeseries
wrks ; cd cfsr ; ls z.list?? ; cd ..
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.jl ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ::: z.listaa z.listab z.listac z.listad z.listae z.listaf z.listag z.listah | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands

# plot forward and backward extrapolations versus the actual values for assessment of bias in the method
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.scatter.jl ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ::: z.list | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia
       parallel --dry-run julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ::: z.list | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e "xvfb-run -a"
       rm commands
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl        cfsr z.list
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl  erainterim z.list
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl       hoaps z.list
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl ifremerflux z.list
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl      jofuro z.list
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl       merra z.list
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl      oaflux z.list
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.tatter.jl     seaflux z.list
       gzip scatter*dat ; mv scatter* all/scatter

# identify the subset of the ICOADS cal/val locations for which analyses are also available for much of 2001-2007 (call these the collocations)
wrks ; split -l 400 all/all.flux.daily.locate_2.0_calib all.flux.daily.locate_2.0_calib
       split -l 400 all/all.flux.daily.locate_2.0_valid all.flux.daily.locate_2.0_valid
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.jl ::: all.flux.daily.locate_2.0_?ali??? ::: shfx lhfx wspd airt sstt shum | grep flux | sort > commands
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
#      sort all/all.flux.daily.locate_2.0_calib > aa ; cat all/all.flux.daily.locate_2.0_calib.shfx.got2000 all/all.flux.daily.locate_2.0_calib.shfx.not2000 | sort > bb ; diff aa bb ; rm aa bb
#      sort all/all.flux.daily.locate_2.0_valid > aa ; cat all/all.flux.daily.locate_2.0_valid.shfx.got2000 all/all.flux.daily.locate_2.0_valid.shfx.not2000 | sort > bb ; diff aa bb ; rm aa bb
       mv commands all.flux.daily.locate_2.0_?ali?* all/limbo

# plot the location and distribution of the collocations
       echo julia /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.distribution.plot.jl all/all.flux.daily.locate_2.0_calib.????.got2000 > commands
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
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_valid.shum.not2000\" >> commands ; echo "
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e xvfb-run --mem=2000mb
       rm commands ; di plot.ocean.heat.flux.dots.all.flux.daily.locate_2.0_?ali?.????.?ot2000.png

# plot the all-collocation-averaged (weighted by daily obs number) one-sided NFFT spectra for each variable and identify submonthly variance
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl  ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000      | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e              julia  --mem=2000mb
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.????.got2000.spec
       xvfb-run -a julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.????.got2000.spec
       cd all ; cat *calib.shfx.got2000.spec.stat *calib.lhfx.got2000.spec.stat *calib.wspd.got2000.spec.stat *calib.airt.got2000.spec.stat *calib.sstt.got2000.spec.stat *calib.shum.got2000.spec.stat
                cat *valid.shfx.got2000.spec.stat *valid.lhfx.got2000.spec.stat *valid.wspd.got2000.spec.stat *valid.airt.got2000.spec.stat *valid.sstt.got2000.spec.stat *valid.shum.got2000.spec.stat
       cd .. ; rm commands ; vi coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl

# assemble the insitu and analysis data for a triple collocation cal/val (such a slow analysis assembly needs profiling!)
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.assemble.insitu.jl all/all.flux.daily    ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000          | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.source.jl        ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs      | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia
       rm commands

# perform a global triple collocation cal/val and evaluate the calibrated analyses using all.flux.daily.locate_2.0_calib
wrks ; cd all ; mkdir zali.recalib.false.iterate.false zali.recalib.false.iterate.true zali.recalib.true.iterate.false zali.recalib.true.iterate.true
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.cfsr.jl   ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.coml | grep flux | sort  > commands
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl        ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comb | grep flux | sort >> commands
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jofuro.jl ::: all/all.flux.daily.locate_2.0_?ali?.????.got2000_obs.comt | grep flux | sort >> commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia
       mv *cali zali.recalib.false.iterate.false                            (following "grep const *colloc.discrete.triple* | grep -i alib")
       cd       zali.recalib.false.iterate.false ; cat *calib.shfx*cali *calib.lhfx*cali *calib.wspd*cali *calib.airt*cali *calib.sstt*cali *calib.shum*cali | grep const
                                                   cat *valid.shfx*cali *valid.lhfx*cali *valid.wspd*cali *valid.airt*cali *valid.sstt*cali *valid.shum*cali | grep const
       vi coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.j*
       mv *cali zali.recalib.false.iterate.true                             (following "grep const *colloc.discrete.triple* | grep -i alib")
       cd       zali.recalib.false.iterate.true  ; cat *calib.shfx*cali *calib.lhfx*cali *calib.wspd*cali *calib.airt*cali *calib.sstt*cali *calib.shum*cali | grep const
                                                   cat *valid.shfx*cali *valid.lhfx*cali *valid.wspd*cali *valid.airt*cali *valid.sstt*cali *valid.shum*cali | grep const
       vi coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.j*
       mv *cali zali.recalib.true.iterate.false
       cd       zali.recalib.true.iterate.false  ; diff zali.recalib.*.iterate.false/*calib.shfx*cali
       mv *cali zali.recalib.true.iterate.true
       cd       zali.recalib.true.iterate.true   ; diff zali.recalib.*.iterate.true/*calib.shfx*cali
       wrks ; rm commands

# convert the triple collocation cal/val results to markdown
wrks ; cd all/zali.recalib.false.iterate.true
       jjj analysis.evaluation.table.performance.jl all.flux.daily.locate_2.0_calib*
       cat all.flux.daily.locate_2.0_calib.shfx.got2000_obs.comb.cali.md all.flux.daily.locate_2.0_calib.lhfx.got2000_obs.coml.cali.md all.flux.daily.locate_2.0_calib.wspd.got2000_obs.comb.cali.md all.flux.daily.locate_2.0_calib.shum.got2000_obs.comb.cali.md all.flux.daily.locate_2.0_calib.sstt.got2000_obs.comt.cali.md all.flux.daily.locate_2.0_calib.airt.got2000_obs.comt.cali.md > analysis.evaluation.table.performance.md
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

# perform another eight-analysis evaulation, but this time with calibration (versus the 2.0_valid_remainder obs)
jjj analysis.evaluation.versus.insitu.jl all/all.flux.daily.locate_2.0_valid_remainder_obs shfx
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.versus.insitu.jl all/all.flux.daily.locate_2.0_valid_remainder_obs ::: shfx lhfx wspd airt sstt shum | grep flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands ; cd all ; cat *shfx.summ *lhfx.summ *wspd.summ *airt.summ *sstt.summ *shum.summ
