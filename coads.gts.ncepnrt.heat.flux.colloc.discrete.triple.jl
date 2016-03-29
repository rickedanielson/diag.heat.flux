#=
 = Perform a series of analysis calibration and performance estimates
 = across a parameter space defined in terms of surface air temperature,
 = wind speed, and SST (mainly because these are available from buoy obs,
 = although air tempertaure and SST covary globally and a more diverse set of
 = parameters could be taken).  Fixed-size subsets of available collocations
 = are selected based on geometrical closeness to the target parameters (after
 = equating metric units and ignoring pdf shape, for example) and employed to
 = obtain each calibration and performance estimate.  Target parameters are
 = then varied with each subset yielding the actual mean parameters by a simple
 = average (and where two averages are close these are combined).  The ungridded
 = variations in analysis quality are then gridded in order to permit a lookup
 = table for maps of analysis quality that depend on these parameters.  Simple
 = polynomials (whose coefficients are found by least squares) are employed to
 = regrid - RD February 2016.
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

const FRAC             = 0.7757 #2.0 /  3.0                     # fractional update during iterations
const DELTA            = 0.001                          # generic convergence criterion
const ANALYS           = 8                              # number of flux analyses

const DIRS = [         "cfsr",    "erainterim",         "hoaps",   "ifremerflux",        "jofuro",         "merra",        "oaflux",       "seaflux", "insitu"]
const SHFR = [   696.12605328,    585.78051385,   1086.73700607,    701.67897796,    444.45494849,    391.63751651,    584.66786977,    517.19733353,      0.0] # calib
const LHFR = [     0.00000000,    908.83931667,   1889.44297245,    595.73235788,   1142.69043337,    634.27207633,    713.44857159,    655.33237141,      0.0]
const WSPR = [     3.64304993,      7.24863802,      6.02812613,      9.79599184,      6.90330277,     10.99504325,      6.56158327,      6.82556676,      0.0]
const AIRR = [     1.94038667,      1.90424361,      2.62517326,      2.91976963,      0.00000000,      2.20387251,      1.75971708,      1.75081369,      0.0]
const SSTR = [     0.03468674,      0.05867710,      0.04485646,      0.57836960,      0.00000000,      0.01574442,      0.03861961,      0.21115767,      0.0]
const SHUR = [     0.39793107,      0.37427633,      0.66851717,      0.48689399,      0.67972228,      0.52315412,      0.28716091,      0.29722441,      0.0]
#=
const SHFR = [   755.78394848,    615.55338379,    965.91845338,    592.09456595,    365.22980984,    351.12610404,    493.07227239,    445.93657336,      0.0] # valid
const LHFR = [     0.00000000,    624.81426109,   1058.23558058,    324.64821962,   1219.08397045,    401.54647993,    413.23142202,    397.47350466,      0.0]
const WSPR = [     3.94589771,      7.38449252,      6.50787300,      9.36856825,      7.15111205,     11.65697733,      6.74582380,      7.17639461,      0.0]
const AIRR = [     1.82613847,      1.63468166,      2.29017567,      2.25770527,      0.00000000,      1.60863841,      1.37894484,      1.57754032,      0.0]
const SSTR = [     0.02387010,      0.04381256,      0.04870639,      0.24888892,      0.00000000,      0.00589912,      0.03975117,      0.54950286,      0.0]
const SHUR = [     0.29769725,      0.26898164,      0.38916258,      0.43334857,      0.93356232,      0.34437823,      0.19235738,      0.21468285,      0.0]
=#

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.combined\n\n")
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

function triple(flux::Array{Float64,3})
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

  rsqr = SHFR

  for a = 1:ANALYS
    for b = 1:ANALYS                                                          # in addition to the "now" in situ obs,
      mask = masquextreme(flux[1,:,9], 4.0) &                                 # use bef analysis "a" and aft analysis "b"
             masquextreme(flux[1,:,a], 4.0) &                                 # (having removed collocations that are beyond
             masquextreme(flux[2,:,b], 4.0)                                   # four standard deviations from their mean)
#     mask = masquextreme(flux[1,:,9], 4e8) &
#            masquextreme(flux[1,:,a], 4e8) &
#            masquextreme(flux[2,:,b], 4e8)
      sampbuoy = flux[1,mask,9]                                               # and iterate if "b" is higher resolution
      sampsate = flux[1,mask,a]                                               # then get the parametric center of mass of
      sampfore = flux[2,mask,b]                                               # the resulting subset using its buoy values
      sampairt = mean(flux[1,mask,10])
      sampwspd = mean(flux[2,mask, 9])
      sampsstt = mean(flux[2,mask,10])
      allmasa[a,b,:] = [sampairt sampwspd sampsstt]

      deltasqr = rsqr[b] > rsqr[a] ? rsqr[b] - rsqr[a] : 0.0
  deltasqr = 0.0
      bet2 = bet3 = 1.0
      alp2 = alp3 = 0.0

      flag = true
  flag = false
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
# print("cv23 $cv23 cv13 $cv13 cv23 / cv13 $(cv23 / cv13)\n")
# print("loop-1 $a $b rsqr[a] $(rsqr[a]) / bet2 $bet2 = rsqrsate $rsqrsate   rsqr[b] $(rsqr[b]) / bet3 $bet3 = rsqrfore $rsqrfore\n")

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

      mask = masquextreme(flux[1,:,9], 4.0) &                                 # use aft analysis "a" and bef analysis "b"
             masquextreme(flux[2,:,a], 4.0) &                                 # (having removed collocations that are beyond
             masquextreme(flux[1,:,b], 4.0)                                   # four standard deviations from their mean)
#     mask = masquextreme(flux[1,:,9], 4e8) &
#            masquextreme(flux[2,:,a], 4e8) &
#            masquextreme(flux[1,:,b], 4e8)
      sampbuoy = flux[1,mask,9]                                               # and iterate if "b" is higher resolution
      sampsate = flux[2,mask,a]                                               # then get the parametric center of mass of
      sampfore = flux[1,mask,b]                                               # the resulting subset using its buoy values
      sampairt = mean(flux[1,mask,10])
      sampwspd = mean(flux[2,mask, 9])
      sampsstt = mean(flux[2,mask,10])
      allmasb[a,b,:] = [sampairt sampwspd sampsstt]

      deltasqr = rsqr[b] > rsqr[a] ? rsqr[b] - rsqr[a] : 0.0
  deltasqr = 0.0
      bet2 = bet3 = 1.0
      alp2 = alp3 = 0.0

      flag = true
  flag = false
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
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allalpa[a,b]    + allalpb[a,b]    end  end ; allalpc[b]   = 0.5 * tmpa / 7.0
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allbeta[a,b]    + allbetb[a,b]    end  end ; allbetc[b]   = 0.5 * tmpa / 7.0
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allsiga[a,b]    + allsigb[a,b]    end  end ; allsigc[b]   = 0.5 * tmpa / 7.0
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allcora[a,b]    + allcorb[a,b]    end  end ; allcorc[b]   = 0.5 * tmpa / 7.0
    tmpa = 0.0 ; for a = 1:ANALYS  if a != b  tmpa += allmasa[a,b,:] .+ allmasb[a,b,:]  end  end ; allmass[b,:] = 0.5 * tmpa / 7.0
  end

  return(allmass, allalpc, allbetc, allsigc, allcorc)                # then return the average stats
end

#=
 = main program
 =#

const MISS             = -9999.0                        # generic missing value
const RANGA            = -40.0:10.0:30.0                # target sampling range for AIRT dimension
const RANGB            =   0.0:10.0:30.0                # target sampling range for WSPD dimension
const RANGC            =   0.0:10.0:30.0                # target sampling range for SSTT dimension
const CUTOFF           = 5000                           # number of collocations in a subset

const ALPH             = 1                              # error model x = ALPH + BETA * truth + error
const BETA             = 2                              # error model x = ALPH + BETA * truth + error
const SIGM             = 3                              # triple coll RMSE
const CORR             = 4                              # triple coll correlation coefficient
const MAIR             = 5                              # center-of-mass parameter
const MSPD             = 6                              # center-of-mass parameter
const MSST             = 7                              # center-of-mass parameter
const PARAMS           = 7                              # number of triple coll statistics

fpa = My.ouvre(ARGS[1], "r") ; lines = readlines(fpa) ; close(fpa)            # read and count all triple collocations
(linum,) = size(lines)                                                        # and allocate for the target parameters and
dist = zeros(linum)                                                           # distance to them, the resulting mean params,
flux = zeros(2, CUTOFF, 10)                                                   # and the triple collocation cal/val estimates
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
      lims = sort(dist)[CUTOFF]

      e = 1                                                                   # get cal/val parameters for this subset
      for (d, line) in enumerate(lines)
        if dist[d] <= lims && e <= CUTOFF
          vals = float(split(line))
          flux[1,e,:] = [vals[CFSB] vals[ERAB] vals[HOAB] vals[IFRB] vals[JOFB] vals[MERB] vals[OAFB] vals[SEAB] vals[OFLX] vals[AIRT]]
          flux[2,e,:] = [vals[CFSA] vals[ERAA] vals[HOAA] vals[IFRA] vals[JOFA] vals[MERA] vals[OAFA] vals[SEAA] vals[WSPD] vals[SSTT]]
          e += 1
        end
      end
      (allmas, allalp, allbet, allsig, allcor) = triple(flux)

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
