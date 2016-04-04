#=
 = Perform a single or a series of analysis calibration and performance estimates,
 = with the series performed across a parameter space defined in terms of surface
 = air temperature, wind speed, and SST (mainly because these are available from
 = buoy obs, although air tempertaure and SST covary globally and a more diverse
 = set of parameters could be taken).  Fixed-size subsets of available collocations
 = are selected based on geometrical closeness to the target parameters (after
 = equating metric units and ignoring pdf shape, for example) and employed to
 = obtain each calibration and performance estimate.  Target parameters are then
 = varied with each subset yielding the actual mean parameters by a simple average
 = (and where two averages are close these are combined).  The ungridded variations
 = in analysis quality are then gridded in order to permit a lookup table for maps
 = of analysis quality that depend on these parameters.  Simple polynomials (whose
 = coefficients are found by least squares) are employed to regrid - RD February 2016.
 =#

using My, Optim
const ODAT             = 1                              # identify indecies of the input data:
const OLAT             = 2                              # date/lat/lon on the collocation grid
const OLON             = 3
const OFLX             = 4                              # then five buoy parameters
const SHUM             = 5
const WSPD             = 6
const AIRT             = 7
const SSTT             = 8
const CFSB             = 9                              # and for each of eight analyses, two
const CFSA             = 10                             # extrapolations from before and after
const ERAB             = 11
const ERAA             = 12
const HOAB             = 13
const HOAA             = 14
const IFRB             = 15
const IFRA             = 16
const JOFB             = 17
const JOFA             = 18
const MERB             = 19
const MERA             = 20
const OAFB             = 21
const OAFA             = 22
const SEAB             = 23
const SEAA             = 24

const FRAC             = 0.9                            # fractional update during iterations
const DELTA            = 0.001                          # generic convergence criterion
const SDTRIM           = 6.0                            # standard deviation trimming limit
const ANALYS           = 7                              # number of flux analyses

const DIRS  = [       "cfsr",    "erainterim",         "hoaps",   "ifremerflux",         "merra",        "oaflux",       "seaflux", "insitu"]
const SHFRC = [ 378.50557917,    346.27919089,    316.31494744,    428.77415608,    236.30473270,    336.74619578,    288.70277851,      0.0]
const LHFRC = [   0.00000000,   3103.72241154,   3368.31026468,   1891.16116883,   2153.94680805,   2519.93924922,   2787.15394381,      0.0]
const WSPRC = [   5.33871542,      6.21164760,      7.18682919,      7.23156993,      8.88686058,      6.83639998,      6.55919942,      0.0]
const AIRRC = [  19.86096471,     19.30935915,     19.30673917,     19.95408684,     18.55438331,     19.64124990,     19.35620347,      0.0]
const SSTRC = [  20.40017651,     20.45962118,     20.23188641,     20.38476145,     20.47267436,     20.39713228,     29.66222972,      0.0]
const SHURC = [   9.01688152,      9.10224303,      9.02518428,      8.77924409,      8.56340810,      9.05679297,      9.09048330,      0.0]
const SHFRV = [ 386.33298139,    354.91304710,    331.19891935,    434.92706721,    242.36182333,    346.32495274,    303.01755116,      0.0]
const LHFRV = [   0.00000000,   3207.92045001,   3470.97483130,   1886.43099649,   2220.01346222,   2611.93842196,   2940.93386985,      0.0]
const WSPRV = [   5.71232406,      6.48326765,      7.46829421,      7.46881947,      9.29325042,      7.11064283,      6.86794025,      0.0]
const AIRRV = [  19.44867235,     18.94796499,     18.90174979,     19.61569800,     18.13136937,     19.23381427,     18.88374999,      0.0]
const SSTRV = [  19.88061586,     19.93423838,     19.73101768,     19.84960148,     19.95023923,     19.87054833,     27.06254198,      0.0]
const SHURV = [   8.78056859,      8.84251258,      8.80114875,      8.43621610,      8.34412240,      8.74748265,      8.75826454,      0.0]
const SHFOO = [        717.0,           620.0,           474.0,           660.0,           423.0,           606.0,           458.0,      0.0]

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_calib.airt.got2000_obs.comb\n\n")
  exit(1)
end

#=
 = Function returning triple collocation cal/val measures for a group of analyses, following McColl
 = et al. (2014).  Inputs are an array of collocated values and an array of measures of short timescale
 = variability (rsqr).  Here we loop over many analyses (e.g., given by two types of extrapolations: one
 = analysis extrapolated from before and the other analyses extrapolated from after each date, and vice
 = versa, with the third dataset being in situ data that are valid and independent on the date).  Stats
 = are returned for each analysis, with possible consideration (using rsqr) of effective resolution after
 = a rescaling, given that the analysis of interest may be either low or intermediate resolution compared
 = to the other analysis and in situ.  Effective resolution is then monitored, as only at low resolution
 = does rsqr enter into the equations and require iteration [i.e., when the analysis of interest has the
 = lowest resolution, the covariance between the other analysis and in situ should be reduced by rsqr
 = (McColl et al. 2014); this impacts rescaling, and in turn, rsqr depends on rescaling (Vogelzang et al.
 = 2011, Eq. 10), so iteration is required as long as the analysis of interest remains lowest resolution;
 = the rsqr ranking is checked to ensure that the effective resolution ranking does not change; if the
 = analysis of interest is intermediate resolution, then its RMSE does not depend on rsqr and no iteration
 = is required (Vogelzang and Stoffelen 2012 Eq. 2.25)] - RD September, October 2015, February 2016.
 =#

function triple(flux::Array{Float64,3}, rsqr::Array{Float64,1})
  allalpa = Array(Float64, ANALYS, ANALYS)                                    # use in situ and (a) any one analysis
  allbeta = Array(Float64, ANALYS, ANALYS)                                    # in turn as references and store the
  allsiga = Array(Float64, ANALYS, ANALYS)                                    # third (b) error and correlation values
  allcora = Array(Float64, ANALYS, ANALYS)                                    # (do this for both extrapolations)
  allmasa = Array(Float64, ANALYS, ANALYS, 3)
  allalpb = Array(Float64, ANALYS, ANALYS)
  allbetb = Array(Float64, ANALYS, ANALYS)
  allsigb = Array(Float64, ANALYS, ANALYS)
  allcorb = Array(Float64, ANALYS, ANALYS)
  allmasb = Array(Float64, ANALYS, ANALYS, 3)
  allalpc = Array(Float64, ANALYS)
  allbetc = Array(Float64, ANALYS)
  allsigc = Array(Float64, ANALYS)
  allcorc = Array(Float64, ANALYS)
  allmass = Array(Float64, ANALYS, 3)

  for a = 1:ANALYS
    for b = 1:ANALYS                                                          # in addition to the "now" in situ obs,
 @show a, b
      mask = masquextreme(flux[1,:,9], SDTRIM) &                              # use bef analysis "a" and aft analysis "b"
             masquextreme(flux[1,:,a], SDTRIM) &                              # (having removed collocations that are beyond
             masquextreme(flux[2,:,b], SDTRIM)                                # SDTRIM standard deviations from their mean)
      sampbuoy = flux[1,mask,9]                                               # and iterate if "b" is higher resolution
      sampsate = flux[1,mask,a]                                               # then get the parametric center of mass of
      sampfore = flux[2,mask,b]                                               # the resulting subset using its buoy values
      sampairt = mean(flux[1,mask,10])
      sampwspd = mean(flux[2,mask, 9])
      sampsstt = mean(flux[2,mask,10])
      allmasa[a,b,:] = [sampairt sampwspd sampsstt]

      deltasqr = rsqr[b] > rsqr[a] ? rsqr[b] - rsqr[a] : 0.0
# deltasqr = 0.0
      bet2 = bet3 = 1.0
      alp2 = alp3 = 0.0

      flag = true
# flag = false
      while flag == true
        avg1 = mean(sampbuoy)
        avg2 = mean(sampsate)
        avg3 = mean(sampfore)
        cv11 = mean(sampbuoy.*sampbuoy) - avg1^2
        cv12 = mean(sampbuoy.*sampsate) - avg1 * avg2 - deltasqr              # write("cv12 = $cv12\n")
        cv13 = mean(sampbuoy.*sampfore) - avg1 * avg3
        cv22 = mean(sampsate.*sampsate) - avg2^2
        cv23 = mean(sampsate.*sampfore) - avg2 * avg3
        cv33 = mean(sampfore.*sampfore) - avg3^2

        alp2old = alp2
        alp3old = alp3
        bet2old = bet2
        bet3old = bet3
        subfrac = FRAC - 0.2 * rand()
        bet2 = subfrac * bet2old + (1.0 - subfrac) * (cv23 / cv13)            # write("bet2 = $bet2\n")
        bet3 = subfrac * bet3old + (1.0 - subfrac) * (cv23 / cv12)            # write("bet3 = $bet3\n")
        alp2 = subfrac * alp2old + (1.0 - subfrac) * (avg2 - bet2 * avg1)     # write("alp2 = $alp2\n")
        alp3 = subfrac * alp3old + (1.0 - subfrac) * (avg3 - bet3 * avg1)     # write("alp3 = $alp3\n")
        sampsate = (flux[1,mask,a] - alp2) / bet2                             # rescale analysis fluxes
        sampfore = (flux[2,mask,b] - alp3) / bet3
        rsqrsate =      rsqr[a]         / bet2 / bet2
        rsqrfore =      rsqr[b]         / bet3 / bet3
#       print("cv23 $cv23 cv13 $cv13 cv23 / cv13 $(cv23 / cv13)\n")
#       print("loop-1 $a $b rsqr[a] $(rsqr[a]) / bet2 $bet2 = rsqrsate $rsqrsate   rsqr[b] $(rsqr[b]) / bet3 $bet3 = rsqrfore $rsqrfore\n")
#       print("$a $b rsqr[a] $(rsqr[a]) / bet2 $bet2 = rsqrsate $rsqrsate   rsqr[b] $(rsqr[b]) / bet3 $bet3 = rsqrfore $rsqrfore\n")

        deltaold = deltasqr
        deltasqr = rsqrfore > rsqrsate ? rsqrfore - rsqrsate : 0.0
        if abs(deltasqr - deltaold) < DELTA  flag = false  end
        if rsqr[a] > rsqr[b] || a == b  flag = false  end
      end

      avg1 = mean(sampbuoy)
      avg2 = mean(sampsate)
      avg3 = mean(sampfore)
      cv11 = mean(sampbuoy.*sampbuoy) - avg1^2
      cv12 = mean(sampbuoy.*sampsate) - avg1 * avg2 - deltasqr
      cv13 = mean(sampbuoy.*sampfore) - avg1 * avg3
      cv22 = mean(sampsate.*sampsate) - avg2^2
      cv23 = mean(sampsate.*sampfore) - avg2 * avg3
      cv33 = mean(sampfore.*sampfore) - avg3^2

      bet2 = cv23 / cv13
      bet3 = cv23 / cv12
      alp2 = avg2 - bet2 * avg1
      alp3 = avg3 - bet3 * avg1

      tmpval = cv11 - cv12 * cv13 / cv23 ; sig1 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv22 - cv12 * cv23 / cv13 ; sig2 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv33 - cv13 * cv23 / cv12 ; sig3 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv12 * cv13 / cv11 / cv23 ; cor1 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv12 * cv23 / cv22 / cv13 ; cor2 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv13 * cv23 / cv33 / cv12 ; cor3 = tmpval > 0 ? sqrt(tmpval) : 0.0

      allalpa[a,b] = alp3
      allbeta[a,b] = bet3
      allsiga[a,b] = sig3
      allcora[a,b] = cor3

      mask = masquextreme(flux[1,:,9], SDTRIM) &                              # use aft analysis "a" and bef analysis "b"
             masquextreme(flux[2,:,a], SDTRIM) &                              # (having removed collocations that are beyond
             masquextreme(flux[1,:,b], SDTRIM)                                # SDTRIM standard deviations from their mean)
      sampbuoy = flux[1,mask,9]                                               # and iterate if "b" is higher resolution
      sampsate = flux[2,mask,a]                                               # then get the parametric center of mass of
      sampfore = flux[1,mask,b]                                               # the resulting subset using its buoy values
      sampairt = mean(flux[1,mask,10])
      sampwspd = mean(flux[2,mask, 9])
      sampsstt = mean(flux[2,mask,10])
      allmasb[a,b,:] = [sampairt sampwspd sampsstt]

      deltasqr = rsqr[b] > rsqr[a] ? rsqr[b] - rsqr[a] : 0.0
# deltasqr = 0.0
      bet2 = bet3 = 1.0
      alp2 = alp3 = 0.0

      flag = true
# flag = false
      while flag == true
        avg1 = mean(sampbuoy)
        avg2 = mean(sampsate)
        avg3 = mean(sampfore)
        cv11 = mean(sampbuoy.*sampbuoy) - avg1^2
        cv12 = mean(sampbuoy.*sampsate) - avg1 * avg2 - deltasqr              # write("cv12 = $cv12\n")
        cv13 = mean(sampbuoy.*sampfore) - avg1 * avg3
        cv22 = mean(sampsate.*sampsate) - avg2^2
        cv23 = mean(sampsate.*sampfore) - avg2 * avg3
        cv33 = mean(sampfore.*sampfore) - avg3^2

        alp2old = alp2
        alp3old = alp3
        bet2old = bet2
        bet3old = bet3
        subfrac = FRAC - 0.2 * rand()
        bet2 = subfrac * bet2old + (1.0 - subfrac) * (cv23 / cv13)            # write("bet2 = $bet2\n")
        bet3 = subfrac * bet3old + (1.0 - subfrac) * (cv23 / cv12)            # write("bet3 = $bet3\n")
        alp2 = subfrac * alp2old + (1.0 - subfrac) * (avg2 - bet2 * avg1)     # write("alp2 = $alp2\n")
        alp3 = subfrac * alp3old + (1.0 - subfrac) * (avg3 - bet3 * avg1)     # write("alp3 = $alp3\n")
        sampsate = (flux[2,mask,a] - alp2) / bet2                             # rescale analysis fluxes
        sampfore = (flux[1,mask,b] - alp3) / bet3
        rsqrsate =      rsqr[a]         / bet2 / bet2
        rsqrfore =      rsqr[b]         / bet3 / bet3
#       print("cv23 $cv23 cv13 $cv13 cv23 / cv13 $(cv23 / cv13)\n")
#       print("loop-2 $a $b rsqr[a] $(rsqr[a]) / bet2 $bet2 = rsqrsate $rsqrsate   rsqr[b] $(rsqr[b]) / bet3 $bet3 = rsqrfore $rsqrfore\n")
#       print("$a $b rsqr[a] $(rsqr[a]) / bet2 $bet2 = rsqrsate $rsqrsate   rsqr[b] $(rsqr[b]) / bet3 $bet3 = rsqrfore $rsqrfore\n")

        deltaold = deltasqr
        deltasqr = rsqrfore > rsqrsate ? rsqrfore - rsqrsate : 0.0
        if abs(deltasqr - deltaold) < DELTA  flag = false  end
        if rsqr[a] > rsqr[b] || a == b  flag = false  end
      end

      avg1 = mean(sampbuoy)
      avg2 = mean(sampsate)
      avg3 = mean(sampfore)
      cv11 = mean(sampbuoy.*sampbuoy) - avg1^2
      cv12 = mean(sampbuoy.*sampsate) - avg1 * avg2
      cv13 = mean(sampbuoy.*sampfore) - avg1 * avg3
      cv22 = mean(sampsate.*sampsate) - avg2^2
      cv23 = mean(sampsate.*sampfore) - avg2 * avg3
      cv33 = mean(sampfore.*sampfore) - avg3^2

      bet2 = cv23 / cv13
      bet3 = cv23 / cv12
      alp2 = avg2 - bet2 * avg1
      alp3 = avg3 - bet3 * avg1

      tmpval = cv11 - cv12 * cv13 / cv23 ; sig1 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv22 - cv12 * cv23 / cv13 ; sig2 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv33 - cv13 * cv23 / cv12 ; sig3 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv12 * cv13 / cv11 / cv23 ; cor1 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv12 * cv23 / cv22 / cv13 ; cor2 = tmpval > 0 ? sqrt(tmpval) : 0.0
      tmpval = cv13 * cv23 / cv33 / cv12 ; cor3 = tmpval > 0 ? sqrt(tmpval) : 0.0

      allalpb[a,b] = alp3
      allbetb[a,b] = bet3
      allsigb[a,b] = sig3
      allcorb[a,b] = cor3
    end
  end

  for b = 1:ANALYS
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allalpa[a,b]    + allalpb[a,b]    end  end ; allalpc[b]   = 0.5 * tmpa / (ANALYS - 1.0)
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allbeta[a,b]    + allbetb[a,b]    end  end ; allbetc[b]   = 0.5 * tmpa / (ANALYS - 1.0)
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allsiga[a,b]    + allsigb[a,b]    end  end ; allsigc[b]   = 0.5 * tmpa / (ANALYS - 1.0)
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allcora[a,b]    + allcorb[a,b]    end  end ; allcorc[b]   = 0.5 * tmpa / (ANALYS - 1.0)
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allmasa[a,b,:] .+ allmasb[a,b,:]  end  end ; allmass[b,:] = 0.5 * tmpa / (ANALYS - 1.0)
  end

  return(allmass, allalpc, allbetc, allsigc, allcorc)                # then return the average stats
end

#=
 = main program
 =#

const MISS             = -9999.0                        # generic missing value
#=
const RANGA            = -40.0:10.0:30.0                # target sampling range for AIRT dimension
const RANGB            =   0.0:10.0:30.0                # target sampling range for WSPD dimension
const RANGC            =   0.0:10.0:30.0                # target sampling range for SSTT dimension
const CUTOFF           = 5000                           # number of collocations in a subset
=#
const RANGA            =   0.0:10.0: 0.0                # target sampling range for AIRT dimension
const RANGB            =   0.0:10.0: 0.0                # target sampling range for WSPD dimension
const RANGC            =   0.0:10.0: 0.0                # target sampling range for SSTT dimension
const CUTOFF           = 4500000000                     # number of collocations in a subset

const ALPH             = 1                              # error model x = ALPH + BETA * truth + error
const BETA             = 2                              # error model x = ALPH + BETA * truth + error
const SIGM             = 3                              # triple coll RMSE
const CORR             = 4                              # triple coll correlation coefficient
const MAIR             = 5                              # center-of-mass parameter
const MSPD             = 6                              # center-of-mass parameter
const MSST             = 7                              # center-of-mass parameter
const PARAMS           = 7                              # number of triple coll statistics

contains(ARGS[1], "shfx") && contains(ARGS[1],   "nrt") && (rsqr = SHFOO) 
contains(ARGS[1], "shfx") && contains(ARGS[1], "calib") && (rsqr = SHFRC)     # first define the measures of short
contains(ARGS[1], "lhfx") && contains(ARGS[1], "calib") && (rsqr = LHFRC)     # timescale variability for this var
contains(ARGS[1], "wspd") && contains(ARGS[1], "calib") && (rsqr = WSPRC)
contains(ARGS[1], "airt") && contains(ARGS[1], "calib") && (rsqr = AIRRC)
contains(ARGS[1], "sstt") && contains(ARGS[1], "calib") && (rsqr = SSTRC)
contains(ARGS[1], "shum") && contains(ARGS[1], "calib") && (rsqr = SHURC)
contains(ARGS[1], "shfx") && contains(ARGS[1], "valid") && (rsqr = SHFRV)
contains(ARGS[1], "lhfx") && contains(ARGS[1], "valid") && (rsqr = LHFRV)
contains(ARGS[1], "wspd") && contains(ARGS[1], "valid") && (rsqr = WSPRV)
contains(ARGS[1], "airt") && contains(ARGS[1], "valid") && (rsqr = AIRRV)
contains(ARGS[1], "sstt") && contains(ARGS[1], "valid") && (rsqr = SSTRV)
contains(ARGS[1], "shum") && contains(ARGS[1], "valid") && (rsqr = SHURV)

fpa = My.ouvre(ARGS[1], "r") ; lines = readlines(fpa) ; close(fpa)            # read and count all triple collocations
(linum,) = size(lines)                                                        # and allocate for the target parameters and
dist = zeros(linum)                                                           # distance to them, the resulting mean params,
chnk = linum < CUTOFF ? linum : CUTOFF                                        # and the triple collocation cal/val estimates
flux = zeros(2, chnk, 10)
target = [MISS for a = RANGA, b = RANGB, c = RANGC, d = 1:3]
calval = [MISS for a = RANGA, b = RANGB, c = RANGC, d = 1:ANALYS, e = 1:PARAMS]

for (a, rana) in enumerate(RANGA)                                             # loop through the target parameters and
  for (b, ranb) in enumerate(RANGB)                                           # isolate the nearest CUTOFF set of obs
    for (c, ranc) in enumerate(RANGC)
      for (d, line) in enumerate(lines)
        vals = float(split(line))
        dist[d] = (rana - vals[AIRT])^2.0 +
                  (ranb - vals[WSPD])^2.0 +
                  (ranc - vals[SSTT])^2.0
      end
      lims = sort(dist)[chnk]

      e = 1                                                                   # get cal/val parameters for this subset
      for (d, line) in enumerate(lines)
        if dist[d] <= lims && e <= chnk
          vals = float(split(line))
          flux[1,e,:] = [vals[CFSB] vals[ERAB] vals[HOAB] vals[IFRB] vals[JOFB] vals[MERB] vals[OAFB] vals[SEAB] vals[OFLX] vals[AIRT]]
          flux[2,e,:] = [vals[CFSA] vals[ERAA] vals[HOAA] vals[IFRA] vals[JOFA] vals[MERA] vals[OAFA] vals[SEAA] vals[WSPD] vals[SSTT]]
          e += 1
        end
      end
      (allmas, allalp, allbet, allsig, allcor) = triple(flux, rsqr)

      target[a,b,c,:] = [rana ranb ranc]
      calval[a,b,c,:,ALPH] = allalp
      calval[a,b,c,:,BETA] = allbet
      calval[a,b,c,:,SIGM] = allsig
      calval[a,b,c,:,CORR] = allcor
      calval[a,b,c,:,MAIR] = allmas[:,1]
      calval[a,b,c,:,MSPD] = allmas[:,2]
      calval[a,b,c,:,MSST] = allmas[:,3]

      @printf("\ntarget params   AIRT,WSPD,SSTT are %6.2f %6.2f %6.2f\n",   rana, ranb, ranc)
      @printf("  mean params   AIRT,WSPD,SSTT are %6.2f %6.2f %6.2f\n\n", mean(allmas[:,1]), mean(allmas[:,2]), mean(allmas[:,3]))
      @printf("%22s %8s %8s %8s %8s\n", " ", "allalp", "allbet", "allsig", "allcor")
      for d = 1:ANALYS
        @printf("%22s %8.1f %8.2f %8.0f %8.2f\n", DIRS[d], allalp[d], allbet[d], allsig[d], allcor[d])
      end
    end
  end
end

exit(0)

varair = Array(Float64, 0)                                                    # the sqerror closure requires data
varspd = Array(Float64, 0)                                                    # arrays in global scope
varsst = Array(Float64, 0)
varcol = Array(Float64, 0)

function sqerror(coef::Array{Float64,1})                                      # define the least squares metric
  err = 0.0
  for i in 1:length(varair)
    res  = coef[1] * varair[i] * varair[i] + coef[2] * varspd[i] * varspd[i] + coef[3] * varsst[i] * varsst[i] +
           coef[4] * varair[i] * varspd[i] + coef[5] * varair[i] * varsst[i] + coef[6] * varspd[i] * varsst[i] +
           coef[7] * varair[i]             + coef[8] * varspd[i]             + coef[9] * varsst[i] + coef[10]
    err += (varcol[i] - res)^2
  end
  return err
end

for a = 1:ANALYS                                                              # for each analysis, store the dependence
  outfile = ARGS[1] * "." * DIRS[a]                                           # of the four triple-collocation statistics
  fpa = My.ouvre(outfile, "w")                                                # in terms of second-order poynomial coeffs
  for b = 1:4                                                                 # obtained using unconstrained optimization
    varair = Array(Float64, 0)                                                # (so the stats' "hypercubes" are reduced to
    varspd = Array(Float64, 0)                                                # variations on a multidimensional curve, but
    varsst = Array(Float64, 0)                                                # with values everywhere in parameter space)
    varcol = Array(Float64, 0)
    for (c, ranc) in enumerate(RANGA)
      for (d, rand) in enumerate(RANGB)
        for (e, rane) in enumerate(RANGC)
          push!(varair, calval[c,d,e,a,MAIR])
          push!(varspd, calval[c,d,e,a,MSPD])
          push!(varsst, calval[c,d,e,a,MSST])
          push!(varcol, calval[c,d,e,a,b])
        end
      end
    end
    res = optimize(sqerror, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], iterations = 10000)

    line = @sprintf("%15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f\n",
      res.minimum[1], res.minimum[2], res.minimum[3], res.minimum[4], res.minimum[5],
      res.minimum[6], res.minimum[7], res.minimum[8], res.minimum[9], res.minimum[10])
    write(fpa, line)
    print("$(DIRS[a]) $b $(show(res)) \n")
  end
  close(fpa)
end

exit(0)
