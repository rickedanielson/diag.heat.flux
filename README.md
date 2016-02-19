
# get a copy
git clone git@github.com:rickedanielson/diag.heat.flux.git

# requirements on ubuntu 14.04 (local) and at Ifremer (12.04)
julia (http://julialang.org/)
GNU parallel (http://www.gnu.org/software/parallel/)
alias wrks 'cd ~/work/works; ls'

# download the NCEP NRT data and unpack them
wrks ; mkdir coads ; cd coads
wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq991*'
wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq0*'
# wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq1*'
# wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/gts.sfcmar_201101.gz
ls -1 *gz | parallel -j 7 gunzip
ls -1 *Z  | parallel -j 7 uncompress
mkdir limbo ; mv nq0503 limbo/nq0503_incomplete ; mv nq0503_complete nq0503

# assemble a COARE flux file (convert from nq???? to .ncepnrt to .flux into all.flux)
wrks ; cd coads
ls -1 nq????         | parallel -j 7      coads.gts.ncepnrt
ls -1 nq????.ncepnrt | parallel -j 7 "jjj coads.gts.ncepnrt.heat.flux.jl"
cat   nq991?.flux    > all.flux ; cat nq0???.flux >> all.flux
mv all.flux ..

# identify the location of available observations, excluding inland waters
wrks ; jjj coads.gts.ncepnrt.heat.flux.locate.jl all.flux
grads -blc "coads.gts.ncepnrt.heat.flux.locate all.flux.locate" ; di plot.ocean.heat.flux.dots.all.flux.locate.png
sort all.flux.locate > all.flux.locate.sort

# create local links to all analysis data files and example ncdumps too
wrks ; mkdir cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
cd /home/cercache/users/rdaniels/work/workr/cfsr        ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/cfsr
cd /home/cercache/users/rdaniels/work/workr/erainterim  ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/erainterim
cd /home/cercache/users/rdaniels/work/workr/hoaps       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/hoaps
cd /home/cercache/users/rdaniels/work/workr/ifremerflux ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/ifremerflux
cd /home/cercache/users/rdaniels/work/workr/jofuro      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/jofuro
cd /home/cercache/users/rdaniels/work/workr/merra       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/merra
cd /home/cercache/users/rdaniels/work/workr/oaflux      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/oaflux
cd /home/cercache/users/rdaniels/work/workr/seaflux     ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/seaflux
mkdir ncdump
ncdump               cfsr/cfsr-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/cfsr
ncdump   erainterim/erainterim-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/erainterim
ncdump             hoaps/hoaps-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/hoaps
ncdump ifremerflux/ifremerflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/ifremerflux
ncdump           jofuro/jofuro-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/jofuro
ncdump             merra/merra-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/merra
ncdump           oaflux/oaflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/oaflux
ncdump         seaflux/seaflux-20040529120000-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc > ncdump/seaflux

# get all analysis timeseries at these open ocean locations
wrks ; split all.flux.locate.sort all.flux.locate.sort
parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.jl ::: all.flux.locate.sorta* ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux | grep all.flux | sort > commands
cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julio --mem=2000mb

# create insitu dir files by discretizing all.flux into averages at the resolution of reference analyses
# (as daily/0.25-degree files for 3745 days/4793 positions) and include daily flux input variables also
wrks ; mkdir insitu
cd hoaps ; ls -1 hoa* | grep -v OHF > z.list ; cd ..
coads.gts.ncepnrt.heat.flux.collate all.flux

# plot temporal coverage of all data (including in situ) at one location (using subdirectory data)
jjj diag.heat.flux.timeseries.available.jl ....45.000...-45.500 ; di plot.avail....45.000...-45.500.png
jjj diag.heat.flux.timeseries.available.jl ....55.000...-12.500 ; di plot.avail....55.000...-12.500.png

# for good measure, list all 4793 (previously 5516) files with 3745 dates for each dataset (in subdirectories)
wrks ; cd insitu      ; ls -1 ins* | grep -v OHF > z.list
wrks ; cd cfsr        ; ls -1 cfs* | grep -v OHF > z.list
wrks ; cd erainterim  ; ls -1 era* | grep -v OHF > z.list
wrks ; cd hoaps       ; ls -1 hoa* | grep -v OHF > z.list
wrks ; cd ifremerflux ; ls -1 ifr* | grep -v OHF > z.list
wrks ; cd merra       ; ls -1 mer* | grep -v OHF > z.list
wrks ; cd oaflux      ; ls -1 oaf* | grep -v OHF > z.list
wrks ; cd seaflux     ; ls -1 sea* | grep -v OHF > z.list
wrks ; cd jofuro      ; ls -1 jof* | grep -v OHF > z.list

# create the forward and backward extrapolated timeseries (using z.list)
wrks ; parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.jl ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux | grep extrapolated | sort > commands
cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb
or
parallel --dry-run "julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.jl" ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
parallel -j 8      "julia /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.extrapolated.jl" ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux

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
cd /home/cercache/users/rdaniels/work/workr/cfsr        ; tar cvfz ../x_cfs.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/erainterim  ; tar cvfz ../x_era.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/hoaps       ; tar cvfz ../x_hop.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/ifremerflux ; tar cvfz ../x_ifr.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/merra       ; tar cvfz ../x_mer.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/oaflux      ; tar cvfz ../x_oaf.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/seaflux     ; tar cvfz ../x_sea.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/jofuro      ; tar cvfz ../x_jro.taz *"..."*

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

# calculate paired collocations
wrks ; vi commands.colloc
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr erainterim
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr            hoaps
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                  ifremerflux
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                              jofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                                      merra
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                                            oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                                                   seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim hoaps
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim       ifremerflux
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                   jofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                           merra
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                                 oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                                        seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps ifremerflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps             jofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps                     merra
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps                           oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps                                  seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux jofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux         merra
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux               oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux                      seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                   jofuro  merra
coads.gts.ncepnrt.heat.flux.colloc all.flux                                   jofuro        oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                   jofuro               seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                           merra oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                           merra        seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                                 oaflux seaflux
parallel < commands.colloc

# calculate paired triple collocation stats
wrks ; vi commands.triple
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr erainterim
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr            hoaps
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                  ifremerflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                              jofuro
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                                      merra
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                                            oaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                                                   seaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim hoaps
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim       ifremerflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                   jofuro
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                           merra
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                                 oaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                                        seaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps ifremerflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps             jofuro
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps                     merra
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps                           oaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps                                  seaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux jofuro
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux         merra
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux               oaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux                      seaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                   jofuro  merra
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                   jofuro        oaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                   jofuro               seaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                           merra oaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                           merra        seaflux
jjj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                                 oaflux seaflux
parallel < commands.triple

parallel --dry-run ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux ::: cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux > commands.dataset.pairs
vi commands.datasetpairs
split -n all.flux ; wc x?? ; rm x?? ; split -l 737526 all.flux
parallel --dry-run "jjj coads.gts.ncepnrt.heat.flux.stdev.jl" ::: xaa  xab  xac  xad  xae  xaf  xag  xah ::: "cfsr erainterim" "cfsr hoaps" "cfsr ifremerflux" "cfsr jofuro" "cfsr merra" "cfsr oaflux" "cfsr seaflux" "erainterim hoaps" "erainterim ifremerflux" "erainterim jofuro" "erainterim merra" "erainterim oaflux" "erainterim seaflux" "hoaps ifremerflux" "hoaps jofuro" "hoaps merra" "hoaps oaflux" "hoaps seaflux" "ifremerflux jofuro" "ifremerflux merra" "ifremerflux oaflux" "ifremerflux seaflux" "jofuro merra" "jofuro oaflux" "jofuro seaflux" "merra oaflux" "merra seaflux" "oaflux seaflux"

wrke ; mkdir cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
cd /home/cercache/users/rdaniels/work/worke/cfsr        ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/cfsr
cd /home/cercache/users/rdaniels/work/worke/erainterim  ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/erainterim
cd /home/cercache/users/rdaniels/work/worke/hoaps       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/hoaps
cd /home/cercache/users/rdaniels/work/worke/ifremerflux ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/ifremerflux
cd /home/cercache/users/rdaniels/work/worke/jofuro      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/jofuro
cd /home/cercache/users/rdaniels/work/worke/merra       ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/merra
cd /home/cercache/users/rdaniels/work/worke/oaflux      ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/oaflux
cd /home/cercache/users/rdaniels/work/worke/seaflux     ; jjj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/seaflux
cp /home/cercache/users/rdaniels/work/workr/all* /home/cercache/users/rdaniels/work/worke

jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr erainterim
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr            hoaps
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                  ifremerflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                              jofuro
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                                      merra
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                                            oaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                                                   seaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim hoaps
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim       ifremerflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                   jofuro
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                           merra
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                                 oaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                                        seaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps ifremerflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps             jofuro
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps                     merra
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps                           oaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps                                  seaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux jofuro
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux         merra
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux               oaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux                      seaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                   jofuro  merra
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                   jofuro        oaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                   jofuro               seaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                           merra oaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                           merra        seaflux
jjj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                                 oaflux seaflux

cfsr erainterim
cfsr hoaps
cfsr ifremerflux
cfsr jofuro
cfsr merra
cfsr oaflux
cfsr seaflux
erainterim hoaps
erainterim ifremerflux
erainterim jofuro
erainterim merra
erainterim oaflux
erainterim seaflux
hoaps ifremerflux
hoaps jofuro
hoaps merra
hoaps oaflux
hoaps seaflux
ifremerflux jofuro
ifremerflux merra
ifremerflux oaflux
ifremerflux seaflux
jofuro merra
jofuro oaflux
jofuro seaflux
merra oaflux
merra seaflux
oaflux seaflux
