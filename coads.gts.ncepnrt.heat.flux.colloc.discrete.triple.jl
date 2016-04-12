#=
 = Perform a single or a series of analysis calibration and performance estimates,
 = with the series performed across a parameter space defined in terms of surface
 = air temperature, wind speed, and SST (mainly because these are available from
 = buoy obs, although air temperature and SST covary globally and a more diverse
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
const RECALIB          = true                           # perform an affine recalibration
const ANALYS           = 8                              # number of flux analyses

const DIRS  = [         "cfsr",    "erainterim",         "hoaps",   "ifremerflux",        "jofuro",         "merra",        "oaflux",       "seaflux", "insitu"]
const SHFAC = [     2.76135691,      6.31441636,      7.17589103,      3.49867477,      4.95244811,      6.74647578,      5.08102979,     11.00157920,      0.0]
const SHFBC = [     0.86790229,      0.80026929,      0.68124198,      0.94179078,      0.79205130,      0.62359634,      0.84766274,      0.72668167,      1.0]
const LHFAC = [ -9999.00000000,             NaN,             NaN,   -101.03692236,             NaN,             NaN,             NaN,             NaN,      0.0]
const LHFBC = [ -9999.00000000,             NaN,             NaN,      6.71700633,             NaN,             NaN,             NaN,             NaN,      1.0]
const WSPAC = [     2.56131065,      1.22476559,      1.38981229,      1.48365331,      1.04283380,      0.72186691,      1.24598448,      1.17459132,      0.0]
const WSPBC = [     0.47757773,      0.78995222,      0.85314393,      0.82578129,      0.87601111,      0.93908010,      0.83673745,      0.83677699,      1.0]
const AIRAC = [     0.14211439,      0.08803240,      0.35191900,     -0.05095704,  -9999.00000000,     -0.61169821,      0.11527890,     -0.78900088,      0.0]
const AIRBC = [     0.99313766,      0.98507760,      0.97331478,      0.99709651,  -9999.00000000,      0.98909908,      0.99364162,      1.01914750,      1.0]
const SSTAC = [     0.86220944,      0.79066031,      0.87688409,      0.95889165,  -9999.00000000,      0.79243793,      0.94460760,      0.48999073,      0.0]
const SSTBC = [     0.99334493,      0.99317441,      0.99062691,      0.98900919,  -9999.00000000,      0.99237045,      0.99071446,      0.99801196,      1.0]
const SHUAC = [     0.32767469,      0.31948539,      0.50073885,      0.54156830,     -0.29589707,      0.39895843,      0.23572552,     -0.36321696,      0.0]
const SHUBC = [     0.97128962,      0.98090582,      0.95719337,      0.97012755,      1.02514137,      0.91927114,      0.99084996,      1.01749678,      1.0]

const SHFAV = [     2.87706414,      6.54915493,      7.24744296,      3.31856598,      4.86627722,      6.91166819,      5.12189436,     11.06293411,      0.0]
const SHFBV = [     0.87832569,      0.80657179,      0.68409855,      0.93620855,      0.80961224,      0.63275633,      0.85821249,      0.72387162,      1.0]
const LHFAV = [ -9999.00000000,             NaN,             NaN,   -104.86234163,             NaN,             NaN,             NaN,             NaN,      0.0]
const LHFBV = [ -9999.00000000,             NaN,             NaN,      6.85810749,             NaN,             NaN,             NaN,             NaN,      1.0]
const WSPAV = [     2.45593244,      1.41864074,      1.52851998,      1.51459929,      1.06080093,      0.84133482,      1.32763099,      1.23789345,      0.0]
const WSPBV = [     0.48646734,      0.74397171,      0.81798742,      0.80230728,      0.85203390,      0.90885273,      0.80287563,      0.80527460,      1.0]
const AIRAV = [     0.00956898,     -0.09989312,      0.23163061,     -0.20884799,  -9999.00000000,     -0.82045360,     -0.02902652,     -0.94081740,      0.0]
const AIRBV = [     0.99667134,      0.99250593,      0.97578899,      1.00276339,  -9999.00000000,      0.99389437,      0.99761292,      1.02184342,      1.0]
const SSTAV = [     0.68720842,      0.64590036,      0.67053058,      0.75302511,  -9999.00000000,      0.66953190,      0.77177973,      0.39717873,      0.0]
const SSTBV = [     0.99646632,      0.99633704,      0.99560792,      0.99286786,  -9999.00000000,      0.99531869,      0.99475432,      0.99958051,      1.0]
const SHUAV = [     0.22202419,      0.30849712,      0.48387998,      0.63071680,     -0.25202855,      0.31449602,      0.23544281,     -0.32790574,      0.0]
const SHUBV = [     0.98068638,      0.98230320,      0.95800823,      0.96256471,      1.01931695,      0.92572442,      0.98997709,      1.01202488,      1.0]

const SHFRC = [   378.50557917,    346.27919089,    316.31494744,    428.77415608,    336.64508304,    236.30473270,    336.74619578,    288.70277851,      0.0]
const LHFRC = [     0.00000000,   3103.72241154,   3368.31026468,   1891.16116883,   3046.35853964,   2153.94680805,   2519.93924922,   2787.15394381,      0.0]
const WSPRC = [     5.33871542,      6.21164760,      7.18682919,      7.23156993,      7.46575514,      8.88686058,      6.83639998,      6.55919942,      0.0]
const AIRRC = [    19.86096471,     19.30935915,     19.30673917,     19.95408684,      0.00000000,     18.55438331,     19.64124990,     19.35620347,      0.0]
const SSTRC = [    20.40017651,     20.45962118,     20.23188641,     20.38476145,      0.00000000,     20.47267436,     20.39713228,     29.66222972,      0.0]
const SHURC = [     9.01688152,      9.10224303,      9.02518428,      8.77924409,      9.62170852,      8.56340810,      9.05679297,      9.09048330,      0.0]
const SHFRV = [   386.33298139,    354.91304710,    331.19891935,    434.92706721,    350.52973292,    242.36182333,    346.32495274,    303.01755116,      0.0]
const LHFRV = [     0.00000000,   3207.92045001,   3470.97483130,   1886.43099649,   3206.45940408,   2220.01346222,   2611.93842196,   2940.93386985,      0.0]
const WSPRV = [     5.71232406,      6.48326765,      7.46829421,      7.46881947,      7.73270315,      9.29325042,      7.11064283,      6.86794025,      0.0]
const AIRRV = [    19.44867235,     18.94796499,     18.90174979,     19.61569800,      0.00000000,     18.13136937,     19.23381427,     18.88374999,      0.0]
const SSTRV = [    19.88061586,     19.93423838,     19.73101768,     19.84960148,      0.00000000,     19.95023923,     19.87054833,     27.06254198,      0.0]
const SHURV = [     8.78056859,      8.84251258,      8.80114875,      8.43621610,      9.25158216,      8.34412240,      8.74748265,      8.75826454,      0.0]

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
      sampairt = mean(flux[1,mask,ANALYS+2])
      sampwspd = mean(flux[2,mask,ANALYS+1])
      sampsstt = mean(flux[2,mask,ANALYS+2])
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
        subfrac = FRAC
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
#       @printf("%d %d rsqr[a] %9.3f / bet2 %9.3f = rsqrsate %9.3f   rsqr[b] %9.3f / bet3 %9.3f = rsqrfore %9.3f\n",
#         a, b, rsqr[a], bet2, rsqrsate, rsqr[b], bet3, rsqrfore)

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
      sampairt = mean(flux[1,mask,ANALYS+2])
      sampwspd = mean(flux[2,mask,ANALYS+1])
      sampsstt = mean(flux[2,mask,ANALYS+2])
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
        subfrac = FRAC
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
#       @printf("%d %d rsqr[a] %9.3f / bet2 %9.3f = rsqrsate %9.3f   rsqr[b] %9.3f / bet3 %9.3f = rsqrfore %9.3f\n",
#         a, b, rsqr[a], bet2, rsqrsate, rsqr[b], bet3, rsqrfore)

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

contains(ARGS[1], "calib.shfx") && (alph = SHFAV ; beta = SHFBV ; rsqr = SHFRC ; varname = "SHF.C")
contains(ARGS[1], "calib.lhfx") && (alph = LHFAV ; beta = LHFBV ; rsqr = LHFRC ; varname = "LHF.C")
contains(ARGS[1], "calib.wspd") && (alph = WSPAV ; beta = WSPBV ; rsqr = WSPRC ; varname = "WSP.C")
contains(ARGS[1], "calib.airt") && (alph = AIRAV ; beta = AIRBV ; rsqr = AIRRC ; varname = "AIR.C")
contains(ARGS[1], "calib.sstt") && (alph = SSTAV ; beta = SSTBV ; rsqr = SSTRC ; varname = "SST.C")
contains(ARGS[1], "calib.shum") && (alph = SHUAV ; beta = SHUBV ; rsqr = SHURC ; varname = "SHU.C")
contains(ARGS[1], "valid.shfx") && (alph = SHFAC ; beta = SHFBC ; rsqr = SHFRV ; varname = "SHF.V")
contains(ARGS[1], "valid.lhfx") && (alph = LHFAC ; beta = LHFBC ; rsqr = LHFRV ; varname = "LHF.V")
contains(ARGS[1], "valid.wspd") && (alph = WSPAC ; beta = WSPBC ; rsqr = WSPRV ; varname = "WSP.V")
contains(ARGS[1], "valid.airt") && (alph = AIRAC ; beta = AIRBC ; rsqr = AIRRV ; varname = "AIR.V")
contains(ARGS[1], "valid.sstt") && (alph = SSTAC ; beta = SSTBC ; rsqr = SSTRV ; varname = "SST.V")
contains(ARGS[1], "valid.shum") && (alph = SHUAC ; beta = SHUBC ; rsqr = SHURV ; varname = "SHU.V")

fpa = My.ouvre(ARGS[1], "r") ; lines = readlines(fpa) ; close(fpa)            # read and count all triple collocations
(linum,) = size(lines)                                                        # and allocate for the target parameters and
dist = zeros(linum)                                                           # distance to them, the resulting mean params,
chnk = linum < CUTOFF ? linum : CUTOFF                                        # and the triple collocation cal/val estimates
flux = zeros(2, chnk, ANALYS + 2)
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
      for (d, line) in enumerate(lines)                                       # (possibly after recalibrating)
        if dist[d] <= lims && e <= chnk
          vals = float(split(line))
          flux[1,e,:] = [vals[CFSB] vals[ERAB] vals[HOAB] vals[IFRB] vals[JOFB] vals[MERB] vals[OAFB] vals[SEAB] vals[OFLX] vals[AIRT]]
          flux[2,e,:] = [vals[CFSA] vals[ERAA] vals[HOAA] vals[IFRA] vals[JOFA] vals[MERA] vals[OAFA] vals[SEAA] vals[WSPD] vals[SSTT]]
          if RECALIB
            for f = 1:ANALYS
              flux[1,e,f] = (flux[1,e,f] - alph[f]) / beta[f]
              flux[1,e,f] = (flux[1,e,f] - alph[f]) / beta[f]
            end
          end
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

      if RECALIB
        fpb = My.ouvre(ARGS[1] * ".cali", "w")
        form = @sprintf("const %sA%c = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf,      0.0]\n",
          varname[1:3], varname[5], allalp[1], allalp[2], allalp[3], allalp[4], allalp[5], allalp[6], allalp[7], allalp[8])
        write(fpb, form)
        form = @sprintf("const %sB%c = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf,      1.0]\n",
          varname[1:3], varname[5], allbet[1], allbet[2], allbet[3], allbet[4], allbet[5], allbet[6], allbet[7], allbet[8])
        write(fpb, form)
        form = @sprintf("\ntarget params   AIRT,WSPD,SSTT are %6.2f %6.2f %6.2f\n",   rana, ranb, ranc)
        write(fpb, form)
        form = @sprintf("  mean params   AIRT,WSPD,SSTT are %6.2f %6.2f %6.2f\n\n", mean(allmas[:,1]), mean(allmas[:,2]), mean(allmas[:,3]))
        write(fpb, form)
        form = @sprintf("%22s %8s %8s %8s %8s\n", " ", "allalp", "allbet", "allsig", "allcor")
        write(fpb, form)
        for d = 1:ANALYS
          form = @sprintf("%22s %8.2f %8.2f %8.2f %8.2f\n", DIRS[d], allalp[d], allbet[d], allsig[d], allcor[d])
          write(fpb, form)
        end
        close(fpb)
      end

      @printf("cala = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
        allalp[1], allalp[2], allalp[3], allalp[4], allalp[5], allalp[6], allalp[7], allalp[8])
      @printf("calb = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
        allbet[1], allbet[2], allbet[3], allbet[4], allbet[5], allbet[6], allbet[7], allbet[8])
      @printf("\ntarget params   AIRT,WSPD,SSTT are %6.2f %6.2f %6.2f\n",   rana, ranb, ranc)
      @printf("  mean params   AIRT,WSPD,SSTT are %6.2f %6.2f %6.2f\n\n", mean(allmas[:,1]), mean(allmas[:,2]), mean(allmas[:,3]))
      @printf("%22s %8s %8s %8s %8s\n", " ", "allalp", "allbet", "allsig", "allcor")
      for d = 1:ANALYS
        @printf("%22s %8.2f %8.2f %8.2f %8.2f\n", DIRS[d], allalp[d], allbet[d], allsig[d], allcor[d])
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
