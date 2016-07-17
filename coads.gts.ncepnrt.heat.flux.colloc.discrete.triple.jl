#=
 = Perform a single or a series of analysis calibration and performance estimates,
 = with the single option employing all available collocations, or for a series of
 = estimates performed for a range of values of the variable of interest (e.g., air
 = temperature or sensible heat flux).  Fixed-size subsets are defined by in situ
 = values being as close as possible to the target values and each calibration and
 = performance estimate is obtained from these.  Note that the actual mean parameters
 = are calculated for each subset, since extreme values are few and extreme averages
 = that are close should probably be treated as one.  These irregularly distributed
 = variations in analysis quality are then gridded in order to permit a lookup table
 = for maps of analysis quality that depend on these parameters.  Simple polynomials
 = (whose coefficients are found by least squares) are employed to regrid - RD May 2016.
 =#

using My, Optim
const ODAT             = 1                              # identify indecies of the input data:
const OLAT             = 2                              # date/lat/lon on the collocation grid
const OLON             = 3
const OFLX             = 4                              # then five buoy parameters
const SUHM             = 5
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
const PERTRIM          = 0.7                            # percent deviation from mean trimming limit
const RECALIB          = true                           # perform an affine recalibration
const GLOBAL           = true                           # employ all collocations or a targeted subsets
const ANALYS           = 8                              # number of analyses
const HYPER            = 1                              # number of hypercube dimensions (independent variables)

const DIRS  = [         "cfsr",    "erainterim",         "hoaps",   "ifremerflux",        "jofuro",         "merra",        "oaflux",       "seaflux"]

const SHFAC = [     2.88766817,      6.97574926,     -3.51722257,      3.66560612,      3.37078303,      4.66003056,      4.46245830,      5.93353053]
const SHFBC = [     1.36270235,      1.38541927,      5.88553136,      1.83432717,      1.78334297,      1.20359905,      1.34795902,      2.03668145]
const SUHAC = [     0.29817384,      0.46882079,      0.99177712,      0.06456809,     -0.45480179,      0.95150575,     -0.00364809,     -0.98440730]
const SUHBC = [     0.97810629,      0.98020042,      0.92291390,      1.01288783,      1.03970950,      0.86113907,      1.01868176,      1.06665565]
const WSPAC = [    -2.09870243,      1.18375683,      1.71279863,      2.89900171,      2.06937495,      1.25707157,      2.02980441,      1.84792048]
const WSPBC = [     1.14192757,      0.75899032,      0.79356213,      0.61307123,      0.70780436,      0.88227319,      0.69882075,      0.71218195]
const SHFAV = [     2.00232744,      6.34213847,     -2.12599117,      2.50383184,      2.21872643,      4.10881431,      3.54853731,      5.27172273]
const SHFBV = [     1.62655604,      1.45824785,      4.84250522,      1.93364728,      2.21670893,      1.41460017,      1.49188857,      2.22547403]
const SUHAV = [     0.13533784,      0.33627756,      0.85487205,     -0.06381808,     -0.51478245,      0.88069142,     -0.12477173,     -1.05338812]
const SUHBV = [     0.99245423,      0.99210605,      0.93668403,      1.02706599,      1.04436029,      0.86558202,      1.02887872,      1.07068342]
const WSPAV = [    -2.67233488,      0.91336032,      1.41838690,      2.49843953,      1.61501765,      1.17144007,      1.75753731,      1.51582806]
const WSPBV = [     1.16997328,      0.76178826,      0.79388507,      0.64132762,      0.73185205,      0.85776150,      0.70252324,      0.72485240]

const SHLAC = [     14.96452070    383.49606321 -12131.63574095    -22.96312006    348.46907169   -380.44438875    -13.73063852    462.92141288  -3746.48083876   -147.22450287   3355.74288799   -748.75512094     47.43505187  -1174.19709919  -3965.65553739     33.78792457  -1098.84810198  10387.44799000     43.77323498  -1144.59178081  -2190.90564393    -46.05323909    313.35688624   7934.84096669]
const SHLBC = [    -14.67276440    302.53397161    600.91899649     -0.12679725     36.80095912   -558.84749830     -4.03961887    117.07360325   -505.01688216      1.34288997    191.24441089  -4891.94736966     -4.54714574     58.91005963   1324.29507974     10.87138663   -323.12341614   1436.21782487     -1.07467796     30.73275208    203.09242812      7.77403087   -180.68288745    322.77551597]
const SULAC = [    -17.53698995    316.96703754  -1059.20502657   -129.73341932   3120.23955985 -17456.56983581    -34.44516027    775.88642126  -4388.54168423  -1070.91751617  20638.04638932 -89109.03742547   -689.31606384  14570.57450869 -75682.80698917    -49.47730803   1169.64647093  -6185.08318855   -159.87569248   3718.66874399 -19420.34928549   -127.13060739   2606.82084365 -12868.31354981]
const SULBC = [      0.64325798     -6.60853283    -29.84933110     10.59091841   -267.90616849   1594.14492388      2.66270483    -65.52878981    410.12193191     54.05794881   -958.73763622   3421.90446380     45.92641215  -1034.84219853   5865.73318476      3.75488117    -91.47771362    501.73983063     11.78122032   -282.47093521   1525.87335905      7.80582839   -165.94809975    868.36656051]
const WSLAC = [   -289.96979536   4357.81104479  -9602.13412759    -33.13097845    573.48338455  -1927.93709023     -9.81760112    195.17558434   -568.58755019    -58.32392967   1171.82168683  -5491.77994880    -12.87778723    200.99630032   -393.79110865     11.19196130     40.41620268   -469.39629423     -9.76204548    140.60128285   -138.46266844    -50.02446267    671.64345164  -1578.96399205]
const WSLBC = [     38.49170969   -588.22179633   1368.71020249      7.72889276   -143.22272523    577.19280930      2.29024814    -42.41836167    146.00696947     22.04020286   -444.14705302   2103.85654642      1.59086547    -23.39961684     36.07299198      1.89266959    -54.35502990    241.66160565      0.56726986     -3.17195916    -55.72240886      6.34077477    -94.56841269    271.53631683]
const SHLAV = [   -159.68599354   3798.14991644  15544.78486939     23.60485376   -299.89186295   -174.62793837     23.52187810   -592.09701828  -1496.34400546     -9.10743588     39.88677763    496.08561798    -47.15299438    291.34577434   3310.25247854     93.44554097  -2401.35268785  -7417.10193763    -23.44898583    559.93048205   3922.53058384    -49.21237055   1055.72977012   3188.19902053]
const SHLBV = [     12.37233779   -309.79713093   -637.22112260     -0.09280583    -17.61884188    228.43935485     -0.91045524     24.67788876     93.10132897      0.33207046     -6.27157890     99.47824185      3.11959921    -48.45042686     62.43347779     -5.67004419    133.16441876    729.68158394      3.30901491    -93.25258554    113.03945680      2.31275295    -48.91918015   -262.14682074]
const SULAV = [    -67.77245735   1589.26438415  -8278.94141386     34.65026147   -951.19469849   5044.54505623   -135.31658208   3289.92389587 -17570.65442201    -39.99443238    646.49032237  -1129.03610267     51.44565573   -965.35450746   4187.02988313     40.32788438  -1037.36236395   5450.22010239   -258.59620295   6393.19727772 -33590.08569061     71.97186008  -1927.61164702  10005.83772551]
const SULBV = [      5.03377718   -121.05029441    648.00151828     -3.06642649     80.38226012   -410.26767787     10.68003445   -265.34081115   1456.73946587      0.68699924     14.22742738   -340.38144555     -2.54371875     44.00025123   -164.37617008     -3.31288267     83.95235048   -433.71990113     20.42020942   -507.43694259   2680.71057038     -6.08254651    156.20060203   -773.90734051]
const WSLAV = [     16.34065885   -156.50069388    318.13389518   -263.85095887   2700.86002991  -5523.63715291     37.57356814   -327.33246445    383.41741506    -30.52383949    325.31388560   -683.80848660    -10.04266764     87.19346277   -197.57761283     12.41686341   -101.23341505     98.93081703    -43.66810347    446.88994873   -858.34624730    -24.22667867    222.52664740   -297.70364945]
const WSLBV = [     -1.31899922     13.22532174    -32.61573993     23.11730864   -254.21760918    620.32889204     -1.59065235     -1.92543581     99.39787300      2.88364398    -34.06405475     88.86345084      0.84276486     -8.84244010     34.31081232     -0.39921951     -3.46705657     44.44075705      3.60524813    -37.15436728     71.77048399      1.26101726     -4.03277637    -40.92885050]

if (argc = length(ARGS)) != 1
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_calib.airt.got2000_obs.comb\n\n")
  exit(1)
end

#=
 = Function returning triple collocation cal/val measures for a group of analyses, following McColl
 = et al. (2014).  Inputs are an array of collocated values and stats are returned for each analysis,
 = where it is assumed that extrapolation from before and after is done using the same analysis, so
 = no consideration of relative effective resolution (and no iteration as in Vogelzang et al. 2011)
 = is necessary (i.e., in situ is highest resolution, but there is no representativeness error
 = associated with one analysis being intermediate resolution and another being even lower resolution).
 =#

function triple(coll::Array{Float64,3})
  allalp = Array(Float64, ANALYS)
  allbet = Array(Float64, ANALYS)
  allsig = Array(Float64, ANALYS)
  allcor = Array(Float64, ANALYS)
  allmas = Array(Float64, ANALYS, HYPER)

  totlen = msklen = 0
  for a = 1:ANALYS                                                            # get the parametric center of mass
    mask = masquepourcent(coll[1,   :,ANALYS+1], PERTRIM) &                   # that defines each subset in terms of
           masquepourcent(coll[1,   :,       a], PERTRIM) &                   # hypercube independent variable (after 
           masquepourcent(coll[2,   :,       a], PERTRIM)                     # trimming extreme values first)
    sampsitu    =         coll[1,mask,ANALYS+1]
    samprefa    =         coll[1,mask,       a]
    samprefb    =         coll[2,mask,       a]
    allmas[a,1] =    mean(coll[2,mask,ANALYS+1])
    totlen += length(coll[1,:,a]) ; msklen += length(coll[1,mask,a])

    avg1 = mean(sampsitu)                                                     # and use a robust calculation of covariance
    avg2 = mean(samprefa)                                                     # (two-pass here, but more algorithms are at
    avg3 = mean(samprefb)                                                     # en.wikipedia.org/wiki/Algorithms_for_calculating_variance)
    cv11 = mean((sampsitu - avg1) .* (sampsitu - avg1))
    cv12 = mean((sampsitu - avg1) .* (samprefa - avg2))
    cv13 = mean((sampsitu - avg1) .* (samprefb - avg3))
    cv22 = mean((samprefa - avg2) .* (samprefa - avg2))
    cv23 = mean((samprefa - avg2) .* (samprefb - avg3))
    cv33 = mean((samprefb - avg3) .* (samprefb - avg3))

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

    allalp[a] = 0.5 * (alp2 + alp3)
    allbet[a] = 0.5 * (bet2 + bet3)
    allsig[a] = 0.5 * (sig2 + sig3)
    allcor[a] = 0.5 * (cor2 + cor3)
  end
  totlen /= ANALYS ; msklen /= ANALYS
  @show totlen msklen

  return(allmas, allalp, allbet, allsig, allcor)                              # then return the average stats
end

#=
 = main program
 =#

const MISS             = -9999.0                        # generic missing value
if GLOBAL || RECALIB
  const RANGE          = 0.0:10.0: 0.0                  # target the sampling range of the subsets
  const CUTOFF         = 4500000000                     # and the number of collocations in each subset
else
  contains(ARGS[1], "shfx") && (const RANGE =  -5.0:10.0: 25.0)
  contains(ARGS[1], "lhfx") && (const RANGE =  50.0:50.0:200.0)
  contains(ARGS[1], "wspd") && (const RANGE =   2.5: 5.0: 12.5)
  contains(ARGS[1], "airt") && (const RANGE =  10.0:10.0: 30.0)
  contains(ARGS[1], "sstt") && (const RANGE =  10.0:10.0: 30.0)
  contains(ARGS[1], "shum") && (const RANGE =   7.5: 5.0: 17.5)
  const CUTOFF         = 5000
end

const ALPH             = 1                              # error model x = ALPH + BETA * truth + error
const BETA             = 2                              # error model x = ALPH + BETA * truth + error
const SIGM             = 3                              # triple coll RMSE
const CORR             = 4                              # triple coll correlation coefficient
const MASS             = 5                              # center-of-mass parameter
const PARAMS           = 5                              # number of triple collocation parameters

contains(ARGS[1], "calib.shfx") && (alph = SHFAV ; beta = SHFBV ; alpl = SHLAV ; betl = SHLBV ; varname = "SHF.C")
contains(ARGS[1], "calib.lhfx") && (alph = LHFAV ; beta = LHFBV ; alpl = LHLAV ; betl = LHLBV ; varname = "LHF.C")
contains(ARGS[1], "calib.wspd") && (alph = WSPAV ; beta = WSPBV ; alpl = WSLAV ; betl = WSLBV ; varname = "WSP.C")
contains(ARGS[1], "calib.airt") && (alph = AIRAV ; beta = AIRBV ; alpl = AILAV ; betl = AILBV ; varname = "AIR.C")
contains(ARGS[1], "calib.sstt") && (alph = SSTAV ; beta = SSTBV ; alpl = SSLAV ; betl = SSLBV ; varname = "SST.C")
contains(ARGS[1], "calib.shum") && (alph = SUHAV ; beta = SUHBV ; alpl = SULAV ; betl = SULBV ; varname = "SUH.C")
contains(ARGS[1], "valid.shfx") && (alph = SHFAC ; beta = SHFBC ; alpl = SHLAC ; betl = SHLBC ; varname = "SHF.V")
contains(ARGS[1], "valid.lhfx") && (alph = LHFAC ; beta = LHFBC ; alpl = LHLAC ; betl = LHLBC ; varname = "LHF.V")
contains(ARGS[1], "valid.wspd") && (alph = WSPAC ; beta = WSPBC ; alpl = WSLAC ; betl = WSLBC ; varname = "WSP.V")
contains(ARGS[1], "valid.airt") && (alph = AIRAC ; beta = AIRBC ; alpl = AILAC ; betl = AILBC ; varname = "AIR.V")
contains(ARGS[1], "valid.sstt") && (alph = SSTAC ; beta = SSTBC ; alpl = SSLAC ; betl = SSLBC ; varname = "SST.V")
contains(ARGS[1], "valid.shum") && (alph = SUHAC ; beta = SUHBC ; alpl = SULAC ; betl = SULBC ; varname = "SUH.V")
#=
contains(ARGS[1], "calib.shfx") && (alph = SHFAC ; beta = SHFBC ; alpl = SHLAC ; betl = SHLBC ; varname = "SHF.C")
contains(ARGS[1], "calib.lhfx") && (alph = LHFAC ; beta = LHFBC ; alpl = LHLAC ; betl = LHLBC ; varname = "LHF.C")
contains(ARGS[1], "calib.wspd") && (alph = WSPAC ; beta = WSPBC ; alpl = WSLAC ; betl = WSLBC ; varname = "WSP.C")
contains(ARGS[1], "calib.airt") && (alph = AIRAC ; beta = AIRBC ; alpl = AILAC ; betl = AILBC ; varname = "AIR.C")
contains(ARGS[1], "calib.sstt") && (alph = SSTAC ; beta = SSTBC ; alpl = SSLAC ; betl = SSLBC ; varname = "SST.C")
contains(ARGS[1], "calib.shum") && (alph = SUHAC ; beta = SUHBC ; alpl = SULAC ; betl = SULBC ; varname = "SUH.C")
contains(ARGS[1], "valid.shfx") && exit(0)
contains(ARGS[1], "valid.lhfx") && exit(0)
contains(ARGS[1], "valid.wspd") && exit(0)
contains(ARGS[1], "valid.airt") && exit(0)
contains(ARGS[1], "valid.sstt") && exit(0)
contains(ARGS[1], "valid.shum") && exit(0)
=#
fpa = My.ouvre(ARGS[1], "r") ; lines = readlines(fpa) ; close(fpa)            # read and count all triple collocations
linum = length(lines)                                                         # allocate for the target parameters and
dist = zeros(linum)                                                           # distance to them, the resulting mean params,
chnk = linum < CUTOFF ? linum : CUTOFF                                        # and the triple collocation cal/val estimates
coll = zeros(2, chnk, ANALYS + 1)
calval = [MISS for a = RANGE, b = 1:ANALYS, c = 1:PARAMS]

if !(GLOBAL || RECALIB)
  fpa = My.ouvre(ARGS[1] * ".cali.locl", "w")
  form = @sprintf("%33s %15s %15s %8s %8s %8s %8s\n",
    "analysis", "target value", "mean value", "allalp", "allbet", "allsig", "allcor")
  write(fpa, form)
  close(fpa)
end

for (a, rana) in enumerate(RANGE)                                             # loop through the target parameters and
  for d = 1:linum                                                             # isolate the nearest CUTOFF set of obs
    vals = float(split(lines[d]))
    dist[d] = abs(rana - vals[OFLX])
  end
  lims = sort(dist)[chnk]

  e = 1                                                                       # get cal/val parameters for this subset
  for d = 1:linum                                                             # (possibly after recalibrating)
    if dist[d] <= lims && e <= chnk
      vals = float(split(lines[d]))
      coll[1,e,:] = [vals[CFSB] vals[ERAB] vals[HOAB] vals[IFRB] vals[JOFB] vals[MERB] vals[OAFB] vals[SEAB] vals[OFLX]]
      coll[2,e,:] = [vals[CFSA] vals[ERAA] vals[HOAA] vals[IFRA] vals[JOFA] vals[MERA] vals[OAFA] vals[SEAA] vals[OFLX]]
      if RECALIB
        if GLOBAL
          for f = 1:ANALYS
            coll[1,e,f] = (coll[1,e,f] - alph[f]) / beta[f]
            coll[2,e,f] = (coll[2,e,f] - alph[f]) / beta[f]
          end
        else                                                                  # for the local calibration, choose local
          for f = 1:ANALYS                                                    # alpha and beta based on a global
            fshift = (f-1) * 3                                                # recalibration (rather than the raw value)
            ctmp = (coll[1,e,f] - alph[f]) / beta[f]
#           ctmp = vals[OFLX]
            localph = alpl[fshift+1] * ctmp^2 + alpl[fshift+2] * ctmp + alpl[fshift+3]
            locbeta = betl[fshift+1] * ctmp^2 + betl[fshift+2] * ctmp + betl[fshift+3]
            coll[1,e,f] = (coll[1,e,f] - localph) / locbeta
            ctmp = (coll[2,e,f] - alph[f]) / beta[f]
#           ctmp = vals[OFLX]
            localph = alpl[fshift+1] * ctmp^2 + alpl[fshift+2] * ctmp + alpl[fshift+3]
            locbeta = betl[fshift+1] * ctmp^2 + betl[fshift+2] * ctmp + betl[fshift+3]
            coll[2,e,f] = (coll[2,e,f] - localph) / locbeta
          end
        end
      end
      e += 1
    end
  end
#@show coll
  (allmas, allalp, allbet, allsig, allcor) = triple(coll)

  calval[a,:,ALPH] = allalp
  calval[a,:,BETA] = allbet
  calval[a,:,SIGM] = allsig
  calval[a,:,CORR] = allcor
  calval[a,:,MASS] = allmas[:,1]

  if GLOBAL || RECALIB
    fpb = My.ouvre(ARGS[1] * ".cali.glob", "w")
    form = @sprintf("const %sA%c = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
      varname[1:3], varname[5], allalp[1], allalp[2], allalp[3], allalp[4], allalp[5], allalp[6], allalp[7], allalp[8])
    write(fpb, form)
    form = @sprintf("const %sB%c = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
      varname[1:3], varname[5], allbet[1], allbet[2], allbet[3], allbet[4], allbet[5], allbet[6], allbet[7], allbet[8])
    write(fpb, form)
    form = @sprintf("\ntarget param   MASS is %6.2f\n", rana)
    write(fpb, form)
    form = @sprintf("  mean param   MASS is %6.2f\n\n", mean(allmas[:,1]))
    write(fpb, form)
    form = @sprintf("%33s %8s %8s %8s %8s\n", " ", "allalp", "allbet", "allsig", "allcor")
    write(fpb, form)
    for d = 1:ANALYS
      form = @sprintf("%33s %8.3f %8.3f %8.3f %8.3f\n", DIRS[d], allalp[d], allbet[d], allsig[d], allcor[d])
      write(fpb, form)
    end
    close(fpb)
  else
    for d = 1:ANALYS
      fpb = My.ouvre(ARGS[1] * ".cali.locl", "a")
      form = @sprintf("%33s %15.3f %15.3f %8.3f %8.3f %8.3f %8.3f\n",
        DIRS[d], rana, mean(allmas[d,1]), allalp[d], allbet[d], allsig[d], allcor[d])
      write(fpb, form)
      close(fpb)
    end
  end

  @printf("cala = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
    allalp[1], allalp[2], allalp[3], allalp[4], allalp[5], allalp[6], allalp[7], allalp[8])
  @printf("calb = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
    allbet[1], allbet[2], allbet[3], allbet[4], allbet[5], allbet[6], allbet[7], allbet[8])
  @printf("\ntarget param   MASS is %6.2f\n", rana)
  @printf("  mean param   MASS is %6.2f\n\n", mean(allmas[:,1]))
  @printf("%33s %8s %8s %8s %8s\n", " ", "allalp", "allbet", "allsig", "allcor")
  for d = 1:ANALYS
    @printf("%33s %8.3f %8.3f %8.3f %8.3f\n", DIRS[d], allalp[d], allbet[d], allsig[d], allcor[d])
  end
end

if GLOBAL || RECALIB  exit(0)  end

varmas = Array(Float64, 0)                                                    # the sqerror closure requires data
varcol = Array(Float64, 0)                                                    # arrays in global scope

function sqerror(coef::Array{Float64,1})                                      # define the least squares metric
  err = 0.0
  for i in 1:length(varmas)
    res  = coef[1] * varmas[i]^2 + coef[2] * varmas[i] + coef[3]
    err += (varcol[i] - res)^2
  end
  return err
end

coeff = Array(Float64, 3, 4, ANALYS)                                          # for each analysis, store the dependence
for a = 1:ANALYS                                                              # of the four triple-collocation statistics
  for b = 1:4                                                                 # in terms of second-order poynomial coeffs
    varmas = Array(Float64, 0)                                                # obtained using unconstrained optimization
    varcol = Array(Float64, 0)                                                # (so the stats' "hypercubes" are reduced to
    for (c, ranc) in enumerate(RANGE)                                         # variations on a multidimensional curve, but
      push!(varmas, calval[c,a,MASS])                                         # with values everywhere in parameter space)
      push!(varcol, calval[c,a,b])
    end
    res = optimize(sqerror, [0.0, 0.0, 0.0], iterations = 10000)

    coeff[1,b,a] = res.minimum[1]
    coeff[2,b,a] = res.minimum[2]
    coeff[3,b,a] = res.minimum[3]
    print("$(DIRS[a]) $b $(show(res)) \n")
  end
end

fpa = My.ouvre(ARGS[1] * ".cali.locl", "a")
for a = 1:4
  a == 1 && (stra = "const" ; strb = "A")
  a == 2 && (stra = "const" ; strb = "B")
  a == 3 && (stra = "     " ; strb = "S")
  a == 4 && (stra = "     " ; strb = "C")
  line = @sprintf("%s %sL%s%c = [", stra, varname[1:2], strb, varname[5])
  for b = 1:ANALYS
    line *= @sprintf(" %15.8f %15.8f %15.8f", coeff[1,a,b], coeff[2,a,b], coeff[3,a,b])
  end
  line *= "]\n"
  write(fpa, line)
  print(line)
end
close(fpa)

exit(0)
