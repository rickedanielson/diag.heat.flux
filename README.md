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
wrks ; cd all ; jjj analysis.evaluation.assemble.insitu.jl all.flux.daily all.flux.daily.locate_2.0_valid_remainder
       cd .. ; mv all/all.flux.dailyall.flux.daily.locate_2.0_valid_remainder      all/all.flux.daily.locate_2.0_valid_remainder_obs
       sort -k4,4 -k5,5 -k6,6   all/all.flux.daily.locate_2.0_valid_remainder_obs >    all.flux.daily.locate_2.0_valid_remainder_obs.sort
       split -l 321644              all.flux.daily.locate_2.0_valid_remainder_obs.sort all.flux.daily.locate_2.0_valid_remainder_obs
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.assemble.analyses.jl ::: all.flux.daily.locate_2.0_valid_remainder_obs?? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux | grep all.flux | sort > commands
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
       rm commands all.flux.daily_2.0_valid_remaind*

# perform an initial eight-analysis evaulation, but without calibration (versus the 2.0_valid_remainder obs)
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/analysis.evaluation.versus.insitu.jl all/all.flux.daily.locate_2.0_valid_remainder_obs ::: shfx lhfx wspd airt sstt shum | grep all.flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands ; cd all ; cat *shfx.summ *lhfx.summ *wspd.summ *airt.summ *sstt.summ *shum.summ

# return to the cal/val locations to create analysis timeseries (some locations missing too much of this timeseries are later ignored)
wrks ; sort     all/all.flux.daily.locate_2.0_calib    > all.flux.daily.locate_2.0_calib.sort
       split -l 401 all.flux.daily.locate_2.0_calib.sort all.flux.daily.locate_2.0_calib.sort
       sort     all/all.flux.daily.locate_2.0_valid    > all.flux.daily.locate_2.0_valid.sort
       split -l 400 all.flux.daily.locate_2.0_valid.sort all.flux.daily.locate_2.0_valid.sort
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.jl ::: all.flux.daily.locate_2.0_?ali?.sort?? ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux | grep all.flux | sort > commands
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
wrks ; jjj diag.heat.flux.timeseries.available.jl ....45.000...-48.500 ; di plot.avail....45.000...-48.500.png
       jjj diag.heat.flux.timeseries.available.jl ....55.000...-12.500 ; di plot.avail....55.000...-12.500.png
       jjj diag.heat.flux.timeseries.available.jl ....48.750...-12.500 ; di plot.avail....48.750...-12.500.png

# create the forward and backward extrapolated timeseries
wrks ; cd cfsr ; ls z.list?? ; cd ..
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.jl ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ::: z.listaa z.listab z.listac z.listad z.listae z.listaf z.listag z.listah | grep timeseries | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands

# identify the subset of the ICOADS cal/val locations for which analyses are also available for much of 2001-2007 (call these the collocations)
wrks ; split -l 400 all/all.flux.daily.locate_2.0_calib all.flux.daily.locate_2.0_calib
       split -l 400 all/all.flux.daily.locate_2.0_valid all.flux.daily.locate_2.0_valid
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.jl ::: all.flux.daily.locate_2.0_?ali??? ::: shfx lhfx wspd airt sstt shum | grep timeseries | sort > commands
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
       echo grads -blc \"coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate_2.0_calib.shfx.got2000\"  > commands
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

# plot the all-collocation-averaged (weighted by daily obs number) one-sided NFFT spectra for each variable and add submonthly variance to code
wrks ; echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_calib.shfx.got2000  > commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_calib.lhfx.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_calib.wspd.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_calib.airt.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_calib.sstt.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_calib.shum.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_valid.shfx.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_valid.lhfx.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_valid.wspd.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_valid.airt.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_valid.sstt.got2000 >> commands
       echo /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.avg.jl all/all.flux.daily.locate_2.0_valid.shum.got2000 >> commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.shfx.got2000.spec  > commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.lhfx.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.wspd.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.airt.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.sstt.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_calib.shum.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.shfx.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.lhfx.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.wspd.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.airt.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.sstt.got2000.spec >> commands
       echo julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.nfft.plot.jl all/all.flux.daily.locate_2.0_valid.shum.got2000.spec >> commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e xvfb-run --mem=2000mb
       cd all ; cat *calib.shfx.got2000.spec.stat *calib.lhfx.got2000.spec.stat *calib.wspd.got2000.spec.stat *calib.airt.got2000.spec.stat *calib.sstt.got2000.spec.stat *calib.shum.got2000.spec.stat
                cat *valid.shfx.got2000.spec.stat *valid.lhfx.got2000.spec.stat *valid.wspd.got2000.spec.stat *valid.airt.got2000.spec.stat *valid.sstt.got2000.spec.stat *valid.shum.got2000.spec.stat
       cd .. ; rm commands ; vi coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl

# create all.flux.combined including buoy (shfx lhfx shum wspd airt sstt) and eight analysis extrapolations before and after
# then perform the partitioned triple collocations and create a cal/val hypercube
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/coads.gts.ncepnrt.heat.flux.colloc.discrete.source.jl ::: shfx lhfx wspd airt sstt shum | grep discrete | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl all.flux.combined.shfx


# partition a set of collocations into subsets that are geometrically closest to the coordinates of a cube that (mostly) encompasses them
wrks ; jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.cube.jl all.flux.combined
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined.-30....0....0
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined.-30....0...40
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined.-30...40....0
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined.-30...40...40
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined..40....0....0
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined..40....0...40
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined..40...40....0
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.plot.jl all.flux.combined..40...40...40
       di plot.all.flux.combined.*


#      cat all.flux.locate.min2000.pos | parallel -j 8 "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.nfft.jl"
#      jjj diag.heat.flux.timeseries.nfft.avg.jl  all.flux.locate.min2000
#      jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectrum.all.flux.locate.min2000.png
#      jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectruo.all.flux.locate.min2000.png
#                                        parallel -j 8 "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.nfft.by.analysis.jl all.flux.locate.min2000" ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
#      jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectrun.all.flux.locate.min2000.png
