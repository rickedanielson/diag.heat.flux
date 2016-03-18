```shell `

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

# identify the location of daily average observations
wrks ; mkdir all ; cat coads/ICOADS*dat.flux.daily > all/all.flux.daily ; cd all
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux.daily /home/cercache/users/rdaniels/topography/elev.0.25-deg.nc
       jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux.daily /home/ricani/data/topography/elev.0.25-deg.nc
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily.locate" ; di plot.ocean.heat.flux.dots.all.flux.daily.locate.png

# split the daily average observations into calibration and validation groups
wrks ; cd all
       jjj coads.gts.ncepnrt.heat.flux.collate.split.jl all.flux.daily
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily_2.0_locate.calib"
       grads -blc "coads.gts.ncepnrt.heat.flux.locate.daily all.flux.daily_2.0_locate.valid"
       di plot.ocean.heat.flux.dots.all.flux.daily*png

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

# get all analysis timeseries at these open ocean locations
wrks ; sort all/all.flux.daily_2.0_locate.calib    > all.flux.daily_2.0_locate.calib.sort
       split    all.flux.daily_2.0_locate.calib.sort all.flux.daily_2.0_locate.calib.sort
       parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.jl ::: all.flux.daily_2.0_locate.calib.sorta* ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux | grep all.flux | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands all.flux.daily_2.0_locate.calib.sor*

# verify that each subdir contains the expected number of files (e.g., 4010 files with 3745 dates)
wrks ; cd cfsr        ; ls -1 cfs* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; cd erainterim  ; ls -1 era* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; cd hoaps       ; ls -1 hoa* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; cd ifremerflux ; ls -1 ifr* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; cd merra       ; ls -1 mer* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; cd oaflux      ; ls -1 oaf* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; cd seaflux     ; ls -1 sea* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; cd jofuro      ; ls -1 jof* | grep -v OHF > z.list ; split -n 10 z.list z.list
wrks ; wc *./z.list

# split the daily average calibration observations by location and store files in an insitu dir
wrks ; mkdir insitu
       sort -k5,5 -k6,6 -k4,4 all/all.flux.daily > all.flux.daily.sort
       jjj coads.gts.ncepnrt.heat.flux.collate.split.location.jl all/all.flux.daily_2.0_locate.calib all.flux.daily.sort
       cd insitu ; ls -1 ins* | grep -v OHF > z.list ; cd .. ; wc insitu/z.list
       rm all.flux.daily.sort

# plot temporal coverage of all data (including in situ) at one location (using subdirectory data)
wrks ; jjj diag.heat.flux.timeseries.available.jl ....45.000...-45.500 ; di plot.avail....45.000...-45.500.png
       jjj diag.heat.flux.timeseries.available.jl ....55.000...-12.500 ; di plot.avail....55.000...-12.500.png

# create the forward and backward extrapolated timeseries (probably easiest to do pairs on br156-097,099,241,252)
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.jl ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ::: z.listaa z.listab z.listac z.listad z.listae z.listaf z.listag z.listah z.listai z.listaj | grep timeseries | sort > commands
       cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
       rm commands

# create all.flux.combined including buoy (shfx lhfx shum wspd airt sstt) and eight analysis extrapolations before and after
# then perform the partitioned triple collocations and create a cal/val hypercube
wrks ; jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.source.jl
       jjj coads.gts.ncepnrt.heat.flux.colloc.discrete.triple.jl all.flux.combined





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

# create all.flux.locate.min2000(.pos) to identify the best (non-coastal) flux locations for much of 2001-2007
wrks ; coads.gts.ncepnrt.heat.flux.colloc.fft all.flux.common ; mv all.flux.common.lhf.mask all.flux.common.shf.mask limbo
grads -blc "coads.gts.ncepnrt.heat.flux.locate all.flux.locate.min2000" ; di plot.ocean.heat.flux.dots.all.flux.locate.min2000.png

# for best flux locations, identify all insitu/analysis collocations valid at all lags (using subdirectory data)
# create all.flux.common.min2000.lhf and all.flux.common.min2000.shf then report their triple collocation averages
    coads.gts.ncepnrt.heat.flux.colloc.common            all.flux.common.min2000
jjj coads.gts.ncepnrt.heat.flux.colloc.common.jl         all.flux.common.min2000.shf
jjj coads.gts.ncepnrt.heat.flux.colloc.common.iterate.jl all.flux.common.min2000.shf

# export the NFFT timeseries data (edit CALIB first!)
cat all.flux.locate.min2000.pos | parallel -j 8 "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.nfft.jl"
jjj diag.heat.flux.timeseries.nfft.avg.jl  all.flux.locate.min2000
jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectrum.all.flux.locate.min2000.png
jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectruo.all.flux.locate.min2000.png
parallel -j 8 "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.nfft.by.analysis.jl all.flux.locate.min2000" ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectrun.all.flux.locate.min2000.png




# pack up the results at Ifremer
cd /home/cercache/users/rdaniels/work/works/cfsr        ; tar cvfz ../x_cfs.taz *"..."*
cd /home/cercache/users/rdaniels/work/works/erainterim  ; tar cvfz ../x_era.taz *"..."*
cd /home/cercache/users/rdaniels/work/works/hoaps       ; tar cvfz ../x_hop.taz *"..."*
cd /home/cercache/users/rdaniels/work/works/ifremerflux ; tar cvfz ../x_ifr.taz *"..."*
cd /home/cercache/users/rdaniels/work/works/merra       ; tar cvfz ../x_mer.taz *"..."*
cd /home/cercache/users/rdaniels/work/works/oaflux      ; tar cvfz ../x_oaf.taz *"..."*
cd /home/cercache/users/rdaniels/work/works/seaflux     ; tar cvfz ../x_sea.taz *"..."*
cd /home/cercache/users/rdaniels/work/works/jofuro      ; tar cvfz ../x_jro.taz *"..."*

# and unpack them locally and plot availability at these open ocean locations
wrks
mkdir cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
cd /home/ricani/work/works/cfsr        ; tar xvf ../x_cfs.taz
cd /home/ricani/work/works/erainterim  ; tar xvf ../x_era.taz
cd /home/ricani/work/works/hoaps       ; tar xvf ../x_hop.taz
cd /home/ricani/work/works/ifremerflux ; tar xvf ../x_ifr.taz
cd /home/ricani/work/works/merra       ; tar xvf ../x_mer.taz
cd /home/ricani/work/works/oaflux      ; tar xvf ../x_oaf.taz
cd /home/ricani/work/works/seaflux     ; tar xvf ../x_sea.taz
cd /home/ricani/work/works/jofuro      ; tar xvf ../x_jro.taz
wrks ; cp ../workr/all.flux* .
grads -blc "coads.gts.ncepnrt.heat.flux.locate all.flux.locate" ; di plot.ocean.heat.flux.dots.all.flux.locate.png

# or else download the NCEP NRT data and assemble a COARE flux file (convert from nq???? to .ncepnrt to .flux into all.flux)
ohf ; mkdir coads ; cd coads
wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq991*'
wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq0*'
# wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq1*'
# wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/gts.sfcmar_201101.gz
ls -1 *gz | parallel -j 7 gunzip
ls -1 *Z  | parallel -j 7 uncompress
mkdir limbo ; mv nq0503 limbo/nq0503_incomplete ; mv nq0503_complete nq0503
ls -1 nq????         | parallel -j 7      coads.gts.ncepnrt
ls -1 nq????.ncepnrt | parallel -j 7 "jjj coads.gts.ncepnrt.heat.flux.jl"
cat   nq991?.flux    > all.flux ; cat nq0???.flux >> all.flux
cp all.flux ~/work/works

# assemble a COARE flux file (convert from nq???? to .ncepnrt to .flux into all.flux)
wrks ; cd coads
ls -1 nq????         | parallel -j 7      coads.gts.ncepnrt
ls -1 nq????.ncepnrt | parallel -j 7 "jjj coads.gts.ncepnrt.heat.flux.jl"
cat   nq991?.flux    > all.flux ; cat nq0???.flux >> all.flux
mv all.flux ..
