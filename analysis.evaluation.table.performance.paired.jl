#=
 = Reformat triple collocation metric summaries as markdown
 = tables.  It is assumed that the files passed as arguments
 = are the available group of analyses for a given variable
 = (e.g., wspd) - RD April, October 2016.
 =#

using My
const ALPH             = 2                              # error model x = ALPH + BETA * truth + error
const BETA             = 3                              # error model x = ALPH + BETA * truth + error
const SIGM             = 4                              # triple coll RMSE
const CORR             = 5                              # triple coll correlation coefficient
const VARS             = 4                              # number of triple collocation metrics
const MISS             = -9999.0                        # generic missing value

if (argc = length(ARGS)) == 0
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_calib.shfx*cali.pair.morph\n\n")
  exit(1)
end
contains(ARGS[1], "shfx") && (varname = "Sensible Heat Flux")                 # assume six files of the same variable
contains(ARGS[1], "lhfx") && (varname = "Latent Heat Flux")
contains(ARGS[1], "wspd") && (varname = "Wind Speed")
contains(ARGS[1], "airt") && (varname = "Air Temperature")
contains(ARGS[1], "sstt") && (varname = "SST")
contains(ARGS[1], "shum") && (varname = "Specific Humidity")

fpa = My.ouvre(ARGS[1] * ".md", "w")                                          # use the first to name the markdown file
if contains(ARGS[1], "shfx")
  form =                             "\nBegin Table\n\n" ; write(fpa, form)
  form = "|Group-1 Group-2 Recal-1 Recal-2|Obs RMSE|Obs Corr|Anlys Bias Addit|Anlys Bias Multi|Anlys RMSE|Anlys Corr|\n" ; write(fpa, form)
  form = "|-|-|-|-|-|-|-|\n" ; write(fpa, form)
end
form  = @sprintf("|%s|||||||\n", varname) ; write(fpa, form)

for a = 1:argc                                                                # and convert each input file to markdown
  contains(ARGS[a],        "cfsr") && (dirname =     "CFSR")
  contains(ARGS[a],  "erainterim") && (dirname =      "ERA")
  contains(ARGS[a],       "hoaps") && (dirname =    "HOAPS")
  contains(ARGS[a], "ifremerflux") && (dirname =  "Ifremer")
  contains(ARGS[a],      "jofuro") && (dirname =  "J-Ofuro")
  contains(ARGS[a],       "merra") && (dirname =    "Merra")
  contains(ARGS[a],      "oaflux") && (dirname =   "OAFlux")
  contains(ARGS[a],     "seaflux") && (dirname =  "SeaFlux")
  contains(ARGS[a],    "ensemble") && (dirname = "Ensemble")
  fpb = My.ouvre(ARGS[a], "r") ; lines = readlines(fpb) ; close(fpb)
  vala = split(lines[ 4]) ; valb = split(lines[ 5]) ; obsa = split(lines[ 6]) ; obsb = split(lines[ 7])
  valc = split(lines[14]) ; vald = split(lines[15]) ; obsc = split(lines[16]) ; obsd = split(lines[17])

  stra  =     float(obsa[SIGM])      <     float(obsc[SIGM])      ?  "**" * obsa[SIGM] * "**" :  "" * obsa[SIGM]
  strb  =     float(obsa[CORR])      >     float(obsc[CORR])      ?  "**" * obsa[CORR] * "**" :  "" * obsa[CORR]
  strc  = abs(float(vala[ALPH]) - 0) < abs(float(valc[ALPH]) - 0) ?  "**" * vala[ALPH] * "**" :  "" * vala[ALPH]
  strd  = abs(float(vala[BETA]) - 1) < abs(float(valc[BETA]) - 1) ?  "**" * vala[BETA] * "**" :  "" * vala[BETA]
  stre  =     float(vala[SIGM])      <     float(valc[SIGM])      ?  "**" * vala[SIGM] * "**" :  "" * vala[SIGM]
  strf  =     float(vala[CORR])      >     float(valc[CORR])      ?  "**" * vala[CORR] * "**" :  "" * vala[CORR]
  stra *=     float(obsb[SIGM])      <     float(obsd[SIGM])      ? " **" * obsb[SIGM] * "**" : " " * obsb[SIGM]
  strb *=     float(obsb[CORR])      >     float(obsd[CORR])      ? " **" * obsb[CORR] * "**" : " " * obsb[CORR]
  strc *= abs(float(valb[ALPH]) - 0) < abs(float(vald[ALPH]) - 0) ? " **" * valb[ALPH] * "**" : " " * valb[ALPH]
  strd *= abs(float(valb[BETA]) - 1) < abs(float(vald[BETA]) - 1) ? " **" * valb[BETA] * "**" : " " * valb[BETA]
  stre *=     float(valb[SIGM])      <     float(vald[SIGM])      ? " **" * valb[SIGM] * "**" : " " * valb[SIGM]
  strf *=     float(valb[CORR])      >     float(vald[CORR])      ? " **" * valb[CORR] * "**" : " " * valb[CORR]
  strc *= abs(float(vala[ALPH]) - 0) < abs(float(valc[ALPH]) - 0) ? " **" * valc[ALPH] * "**" : " " * valc[ALPH]
  strd *= abs(float(vala[BETA]) - 1) < abs(float(valc[BETA]) - 1) ? " **" * valc[BETA] * "**" : " " * valc[BETA]
  stre *=     float(vala[SIGM])      <     float(valc[SIGM])      ? " **" * valc[SIGM] * "**" : " " * valc[SIGM]
  strc *= abs(float(valb[ALPH]) - 0) < abs(float(vald[ALPH]) - 0) ? " **" * vald[ALPH] * "**" : " " * vald[ALPH]
  strd *= abs(float(valb[BETA]) - 1) < abs(float(vald[BETA]) - 1) ? " **" * vald[BETA] * "**" : " " * vald[BETA]
  stre *=     float(valb[SIGM])      <     float(vald[SIGM])      ? " **" * vald[SIGM] * "**" : " " * vald[SIGM]

  if float(obsa[SIGM]) != float(obsc[SIGM])
    stra *=   float(obsa[SIGM])      <     float(obsc[SIGM])      ? " **" * obsc[SIGM] * "**" : " " * obsc[SIGM]
  end
  if float(obsa[CORR]) != float(obsc[CORR])
    strb *=   float(obsa[CORR])      >     float(obsc[CORR])      ? " **" * obsc[CORR] * "**" : " " * obsc[CORR]
  end
  if float(vala[CORR]) != float(valc[CORR])
    strf *=   float(vala[CORR])      >     float(valc[CORR])      ? " **" * valc[CORR] * "**" : " " * valc[CORR]
  end
  if float(obsb[SIGM]) != float(obsd[SIGM])
    stra *=   float(obsb[SIGM])      <     float(obsd[SIGM])      ? " **" * obsd[SIGM] * "**" : " " * obsd[SIGM]
  end
  if float(obsb[CORR]) != float(obsd[CORR])
    strb *=   float(obsb[CORR])      >     float(obsd[CORR])      ? " **" * obsd[CORR] * "**" : " " * obsd[CORR]
  end
  if float(valb[CORR]) != float(vald[CORR])
    strf *=   float(valb[CORR])      >     float(vald[CORR])      ? " **" * vald[CORR] * "**" : " " * vald[CORR]
  end
  form  = @sprintf("|%s|%s|%s|%s|%s|%s|%s|\n", dirname, stra, strb, strc, strd, stre, strf) ; write(fpa, form)
end

if contains(ARGS[1], "shum")
  form = "\nEnd Table\n" ; write(fpa, form)
end
close(fpa)
exit(0)


#=
  temp = 0.5 * (float(vala[2]) + float(valb[2])) ; vala[2] = @sprintf("%.3f", temp)
  temp = 0.5 * (float(vala[3]) + float(valb[3])) ; vala[3] = @sprintf("%.3f", temp)
  temp = 0.5 * (float(vala[4]) + float(valb[4])) ; vala[4] = @sprintf("%.3f", temp)
  temp = 0.5 * (float(vala[5]) + float(valb[5])) ; vala[5] = @sprintf("%.3f", temp)
  temp = 0.5 * (float(valc[2]) + float(vald[2])) ; valc[2] = @sprintf("%.3f", temp)
  temp = 0.5 * (float(valc[3]) + float(vald[3])) ; valc[3] = @sprintf("%.3f", temp)
  temp = 0.5 * (float(valc[4]) + float(vald[4])) ; valc[4] = @sprintf("%.3f", temp)
  temp = 0.5 * (float(valc[5]) + float(vald[5])) ; valc[5] = @sprintf("%.3f", temp)

1 mean param   MASS is  20.78
2 mean param   MASS is  20.57
3                                                                               allalp   allbet   allsig   allcor
4        all/all.flux.daily.locate_2.0_calib.sstt.got2000_obs.comt.erainterim   -0.117    1.001    0.237    1.000
5        all/all.flux.daily.locate_2.0_valid.sstt.got2000_obs.comt.erainterim   -0.131    1.001    0.229    1.000
6                                                                         obs    0.000    1.000    0.705    0.996
7                                                                         obs    0.000    1.000    0.904    0.993
8                                                                         bef   -0.096    1.000    0.289    0.999
9                                                                         bef   -0.114    1.001    0.295    0.999
10                                                                        aft   -0.138    1.002    0.185    1.000
11                                                                        aft   -0.148    1.002    0.164    1.000
12mean param   MASS is  20.78 after recalibration only (using alpha and beta from the opposite set of collocations)
13mean param   MASS is  20.57 after recalibration only (using alpha and beta from the opposite set of collocations)
14       all/all.flux.daily.locate_2.0_calib.sstt.got2000_obs.comt.erainterim    0.014    1.000    0.237    1.000
15       all/all.flux.daily.locate_2.0_valid.sstt.got2000_obs.comt.erainterim   -0.014    1.000    0.229    1.000
16                                                                        obs    0.000    1.000    0.705    0.996
17                                                                        obs    0.000    1.000    0.904    0.993
18                                                                        bef    0.034    0.999    0.288    0.999
19                                                                        bef    0.003    1.000    0.295    0.999
20                                                                        aft   -0.007    1.000    0.185    1.000
21                                                                        aft   -0.031    1.001    0.164    1.000
=#
