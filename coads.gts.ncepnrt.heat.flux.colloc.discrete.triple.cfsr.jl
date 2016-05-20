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
const ERAB             = 9                              # and for each of eight analyses, two
const ERAA             = 10                             # extrapolations from before and after
const HOAB             = 11
const HOAA             = 12
const IFRB             = 13
const IFRA             = 14
const JOFB             = 15
const JOFA             = 16
const MERB             = 17
const MERA             = 18
const OAFB             = 19
const OAFA             = 20
const SEAB             = 21
const SEAA             = 22

const FRAC             = 0.9                            # fractional update during iterations
const DELTA            = 0.001                          # generic convergence criterion
const PERTRIM          = 0.7                            # percent deviation from mean trimming limit
const RECALIB          = true                           # perform an affine recalibration
const GLOBAL           = true                           # employ all collocations or a targeted subsets
const ANALYS           = 7                              # number of analyses
const HYPER            = 1                              # number of hypercube dimensions (independent variables)

const DIRS  = [   "erainterim",         "hoaps",   "ifremerflux",        "jofuro",         "merra",        "oaflux",       "seaflux"]

const LHFAC = [     4.54226165,    -24.23769546,     10.57257240,      0.78621753,      5.30069338,      0.87558627,     15.56280765]
const LHFBC = [     1.27420735,      1.52948296,      1.03009329,      1.18665526,      1.08436103,      1.19315736,      0.91969119]
const LHFAV = [     0.67161582,    -27.65864935,      9.89104997,     -5.64814519,      2.63421698,     -0.05127182,      5.60035426]
const LHFBV = [     1.23816519,      1.48545609,      0.96254007,      1.21224506,      1.04406791,      1.12319564,      0.98863245]
const LHLAC = [     0.04417926     -0.10298563      0.02980934]
const LHLBC = [     4.01156863     -6.30790060      3.07021902]
const LHLAV = [    -0.02881019      0.00653482      0.01137809]
const LHLBV = [     4.51764345     -6.78495552      3.07755129]

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

    avg1 = mean(sampsitu)
    avg2 = mean(samprefa)
    avg3 = mean(samprefb)
    cv11 = mean(sampsitu.*sampsitu) - avg1^2
    cv12 = mean(sampsitu.*samprefa) - avg1 * avg2
    cv13 = mean(sampsitu.*samprefb) - avg1 * avg3
    cv22 = mean(samprefa.*samprefa) - avg2^2
    cv23 = mean(samprefa.*samprefb) - avg2 * avg3
    cv33 = mean(samprefb.*samprefb) - avg3^2

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
      coll[1,e,:] = [vals[ERAB] vals[HOAB] vals[IFRB] vals[JOFB] vals[MERB] vals[OAFB] vals[SEAB] vals[OFLX]]
      coll[2,e,:] = [vals[ERAA] vals[HOAA] vals[IFRA] vals[JOFA] vals[MERA] vals[OAFA] vals[SEAA] vals[OFLX]]
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
    form = @sprintf("const %sA%c = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
      varname[1:3], varname[5], allalp[1], allalp[2], allalp[3], allalp[4], allalp[5], allalp[6], allalp[7])
    write(fpb, form)
    form = @sprintf("const %sB%c = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
      varname[1:3], varname[5], allbet[1], allbet[2], allbet[3], allbet[4], allbet[5], allbet[6], allbet[7])
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

  @printf("cala = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
    allalp[1], allalp[2], allalp[3], allalp[4], allalp[5], allalp[6], allalp[7])
  @printf("calb = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf]\n",
    allbet[1], allbet[2], allbet[3], allbet[4], allbet[5], allbet[6], allbet[7])
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
