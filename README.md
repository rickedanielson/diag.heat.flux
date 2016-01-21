
# get a copy
git clone git@github.com:rickedanielson/diag.heat.flux.git

# requirements on ubuntu 14.04 (local) and at Ifremer (12.04)
julia (http://julialang.org/)
GNU parallel (http://www.gnu.org/software/parallel/)
alias wrkr 'cd ~/work/workr; ls'

# download the NCEP NRT data and unpack them
wrkr ; mkdir coads ; cd coads
wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq991*'
wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq0*'
# wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/nq1*'
# wget 'ftp://ftp.ncdc.noaa.gov/pub/data/ncep_gts/gts.sfcmar_201101.gz
ls -1 *gz | parallel -j 7 gunzip
ls -1 *Z  | parallel -j 7 uncompress
mkdir limbo ; mv nq0503 limbo/nq0503_incomplete ; mv nq0503_complete nq0503

# assemble a COARE flux file (convert from nq???? to .ncepnrt to .flux into all.flux)
wrkr ; cd coads
ls -1 nq????         | parallel -j 7     coads.gts.ncepnrt
ls -1 nq????.ncepnrt | parallel -j 7 "jj coads.gts.ncepnrt.heat.flux.jl"
cat   nq991?.flux    > all.flux ; cat nq0???.flux >> all.flux
mv all.flux ..

# identify the location of available observations, excluding inland waters
wrkr
jj coads.gts.ncepnrt.heat.flux.locate.jl all.flux
sort all.flux.locate > all.flux.locate.sort

# create local links to all analysis data files
wrkr ; mkdir cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux
cd /home/cercache/users/rdaniels/work/workr/cfsr        ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/cfsr
cd /home/cercache/users/rdaniels/work/workr/erainterim  ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/erainterim
cd /home/cercache/users/rdaniels/work/workr/hoaps       ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/hoaps
cd /home/cercache/users/rdaniels/work/workr/ifremerflux ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/ifremerflux
cd /home/cercache/users/rdaniels/work/workr/j-ofuro     ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/j-ofuro
cd /home/cercache/users/rdaniels/work/workr/merra       ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/merra
cd /home/cercache/users/rdaniels/work/workr/oaflux      ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/oaflux
cd /home/cercache/users/rdaniels/work/workr/seaflux     ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/seaflux

# get all analysis timeseries at these open ocean locations
wrkr
split all.flux.locate.sort all.flux.locate.sort
parallel --dry-run /home1/homedir1/perso/rdaniels/bin/diag.heat.flux.timeseries.jl ::: all.flux.locate.sorta* ::: cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux | grep all.flux | sort > commands
cat commands | /home5/begmeil/tools/gogolist/bin/gogolist.py -e julia --mem=2000mb

# pack up the results
cd /home/cercache/users/rdaniels/work/workr/cfsr        ; tar cvfz ../x_cfs.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/erainterim  ; tar cvfz ../x_era.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/hoaps       ; tar cvfz ../x_hop.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/ifremerflux ; tar cvfz ../x_ifr.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/merra       ; tar cvfz ../x_mer.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/oaflux      ; tar cvfz ../x_oaf.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/seaflux     ; tar cvfz ../x_sea.taz *"..."*
cd /home/cercache/users/rdaniels/work/workr/j-ofuro     ; tar cvfz ../x_jro.taz *"..."*

# and unpack them and plot availability at these open ocean locations
wrks
mkdir cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux
cd /home/ricani/work/works/cfsr        ; tar xvf ../x_cfs.taz
cd /home/ricani/work/works/erainterim  ; tar xvf ../x_era.taz
cd /home/ricani/work/works/hoaps       ; tar xvf ../x_hop.taz
cd /home/ricani/work/works/ifremerflux ; tar xvf ../x_ifr.taz
cd /home/ricani/work/works/merra       ; tar xvf ../x_mer.taz
cd /home/ricani/work/works/oaflux      ; tar xvf ../x_oaf.taz
cd /home/ricani/work/works/seaflux     ; tar xvf ../x_sea.taz
cd /home/ricani/work/works/j-ofuro     ; tar xvf ../x_jro.taz
wrks ; cp ../workr/all.flux* .
grads -blc "coads.gts.ncepnrt.heat.flux.locate all.flux.locate" ; di plot.ocean.heat.flux.dots.all.flux.locate.png

# create insitu dir files by discretizing all.flux into averages at the resolution of reference analyses (as daily/0.25-degree files for 3745 days/5516 positions)
wrks
mkdir insitu
coads.gts.ncepnrt.heat.flux.collate all.flux

# plot temporal coverage of all data (including in situ) at one location (using subdirectory data)
jj diag.heat.flux.timeseries.available.jl ....45.000...-45.500 ; di plot.avail....45.000...-45.500.png
jj diag.heat.flux.timeseries.available.jl ....55.000...-12.500 ; di plot.avail....55.000...-12.500.png

# for good measure, list all 5516 files with 3745 dates for each dataset (in subdirectories)
cd /home/ricani/work/works/insitu      ; ls -1 ins* > z.list
cd /home/ricani/work/works/cfsr        ; ls -1 cfs* > z.list
cd /home/ricani/work/works/erainterim  ; ls -1 era* > z.list
cd /home/ricani/work/works/hoaps       ; ls -1 hoa* > z.list
cd /home/ricani/work/works/ifremerflux ; ls -1 ifr* > z.list
cd /home/ricani/work/works/merra       ; ls -1 mer* > z.list
cd /home/ricani/work/works/oaflux      ; ls -1 oaf* > z.list
cd /home/ricani/work/works/seaflux     ; ls -1 sea* > z.list
cd /home/ricani/work/works/j-ofuro     ; ls -1 j-o* > z.list

# create the forward and backward extrapolated timeseries (using z.list)
wrks
parallel --dry-run "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.extrapolated.jl" ::: cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux
parallel -j 7      "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.extrapolated.jl" :::      erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux

# create all.flux.locate.min2000(.pos) to identify the best (non-coastal) flux locations for much of 2001-2007
wrks
coads.gts.ncepnrt.heat.flux.colloc.fft all.flux.common ; mv all.flux.common.lhf.mask all.flux.common.shf.mask limbo
grads -blc "coads.gts.ncepnrt.heat.flux.locate all.flux.locate.min2000" ; di plot.ocean.heat.flux.dots.all.flux.locate.min2000.png

# for best flux locations, identify all insitu/analysis collocations valid at all lags (using subdirectory data)
# create all.flux.common.min2000.lhf and all.flux.common.min2000.shf then report their triple collocation averages
   coads.gts.ncepnrt.heat.flux.colloc.common            all.flux.common.min2000
jj coads.gts.ncepnrt.heat.flux.colloc.common.jl         all.flux.common.min2000.shf
jj coads.gts.ncepnrt.heat.flux.colloc.common.iterate.jl all.flux.common.min2000.shf

# export the NFFT timeseries data (edit CALIB first!)
cat all.flux.locate.min2000.pos | parallel -j 8 "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.nfft.jl"
jj  diag.heat.flux.timeseries.nfft.avg.jl  all.flux.locate.min2000
jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectrum.all.flux.locate.min2000.png
jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectruo.all.flux.locate.min2000.png
parallel -j 8 "/home/ricani/soft/julia-now/julia /home/ricani/bin/diag.heat.flux.timeseries.nfft.by.analysis.jl all.flux.locate.min2000" ::: cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux
jjo diag.heat.flux.timeseries.nfft.plot.jl all.flux.locate.min2000 ; di spectrun.all.flux.locate.min2000.png










# calculate paired collocations
wrks ; vi commands.colloc
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr erainterim
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr            hoaps
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                  ifremerflux
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                              j-ofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                                      merra
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                                            oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux cfsr                                                   seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim hoaps
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim       ifremerflux
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                   j-ofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                           merra
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                                 oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux      erainterim                                        seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps ifremerflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps             j-ofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps                     merra
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps                           oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                 hoaps                                  seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux j-ofuro
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux         merra
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux               oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                       ifremerflux                      seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                   j-ofuro merra
coads.gts.ncepnrt.heat.flux.colloc all.flux                                   j-ofuro       oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                   j-ofuro              seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                           merra oaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                           merra        seaflux
coads.gts.ncepnrt.heat.flux.colloc all.flux                                                 oaflux seaflux
parallel < commands.colloc

# calculate paired triple collocation stats
wrks ; vi commands.triple
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr erainterim
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr            hoaps
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                  ifremerflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                              j-ofuro
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                                      merra
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                                            oaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux cfsr                                                   seaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim hoaps
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim       ifremerflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                   j-ofuro
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                           merra
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                                 oaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux      erainterim                                        seaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps ifremerflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps             j-ofuro
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps                     merra
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps                           oaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                 hoaps                                  seaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux j-ofuro
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux         merra
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux               oaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                       ifremerflux                      seaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                   j-ofuro merra
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                   j-ofuro       oaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                   j-ofuro              seaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                           merra oaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                           merra        seaflux
jj coads.gts.ncepnrt.heat.flux.triple.jl all.flux                                                 oaflux seaflux
parallel < commands.triple

parallel --dry-run ::: cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux ::: cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux > commands.dataset.pairs
vi commands.datasetpairs
split -n all.flux ; wc x?? ; rm x?? ; split -l 737526 all.flux
parallel --dry-run "jj coads.gts.ncepnrt.heat.flux.stdev.jl" ::: xaa  xab  xac  xad  xae  xaf  xag  xah ::: "cfsr erainterim" "cfsr hoaps" "cfsr ifremerflux" "cfsr j-ofuro" "cfsr merra" "cfsr oaflux" "cfsr seaflux" "erainterim hoaps" "erainterim ifremerflux" "erainterim j-ofuro" "erainterim merra" "erainterim oaflux" "erainterim seaflux" "hoaps ifremerflux" "hoaps j-ofuro" "hoaps merra" "hoaps oaflux" "hoaps seaflux" "ifremerflux j-ofuro" "ifremerflux merra" "ifremerflux oaflux" "ifremerflux seaflux" "j-ofuro merra" "j-ofuro oaflux" "j-ofuro seaflux" "merra oaflux" "merra seaflux" "oaflux seaflux"

wrke ; mkdir cfsr erainterim hoaps ifremerflux j-ofuro merra oaflux seaflux
cd /home/cercache/users/rdaniels/work/worke/cfsr        ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/cfsr
cd /home/cercache/users/rdaniels/work/worke/erainterim  ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/erainterim
cd /home/cercache/users/rdaniels/work/worke/hoaps       ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/hoaps
cd /home/cercache/users/rdaniels/work/worke/ifremerflux ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/ifremerflux
cd /home/cercache/users/rdaniels/work/worke/j-ofuro     ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/j-ofuro
cd /home/cercache/users/rdaniels/work/worke/merra       ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/merra
cd /home/cercache/users/rdaniels/work/worke/oaflux      ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/oaflux
cd /home/cercache/users/rdaniels/work/worke/seaflux     ; jj diag.heat.flux.links.jl /home/cercache/project/oceanheatflux/data/references/seaflux
cp /home/cercache/users/rdaniels/work/workr/all* /home/cercache/users/rdaniels/work/worke

jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr erainterim
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr            hoaps
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                  ifremerflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                              j-ofuro
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                                      merra
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                                            oaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux cfsr                                                   seaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim hoaps
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim       ifremerflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                   j-ofuro
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                           merra
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                                 oaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux      erainterim                                        seaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps ifremerflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps             j-ofuro
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps                     merra
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps                           oaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                 hoaps                                  seaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux j-ofuro
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux         merra
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux               oaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                       ifremerflux                      seaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                   j-ofuro merra
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                   j-ofuro       oaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                   j-ofuro              seaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                           merra oaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                           merra        seaflux
jj coads.gts.ncepnrt.heat.flux.stdev.jl all.flux                                                 oaflux seaflux

cfsr erainterim
cfsr hoaps
cfsr ifremerflux
cfsr j-ofuro
cfsr merra
cfsr oaflux
cfsr seaflux
erainterim hoaps
erainterim ifremerflux
erainterim j-ofuro
erainterim merra
erainterim oaflux
erainterim seaflux
hoaps ifremerflux
hoaps j-ofuro
hoaps merra
hoaps oaflux
hoaps seaflux
ifremerflux j-ofuro
ifremerflux merra
ifremerflux oaflux
ifremerflux seaflux
j-ofuro merra
j-ofuro oaflux
j-ofuro seaflux
merra oaflux
merra seaflux
oaflux seaflux
