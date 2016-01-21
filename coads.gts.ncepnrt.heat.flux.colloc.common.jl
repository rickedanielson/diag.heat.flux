#=
 = Report triple collocation stats following McColl et al. (2014)
 = using previously identified collocated values.  Both types of
 = extrapolation pairs (one analysis extrapolated from before and
 = the other from after each date, and vice versa) are reported
 = for the analyses (buoys are on the date) - RD September 2015
 =#

using My
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  write("\nUsage: jj $(basename(@__FILE__)) all.flux.common.shf\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "j-ofuro", "merra", "oaflux", "seaflux", "insitu"]
rsqr = [   717,          620,     474,           660,       617,     423,      606,       458,      000]

fpa = My.ouvre(ARGS[1], "r")
lines = readlines(fpa)
close(fpa)

(num,) = size(lines)                                                          # read all well defined collocations
flux = Array(Float64, 3, num, 9)                                              # (flux[1] = bef and flux[3] = aft)
for (a, line) in enumerate(lines)
  vals = float(split(line))
  flux[1,a,:] = [vals[ 4] vals[ 5] vals[ 6] vals[ 7] vals[ 8] vals[ 9] vals[10] vals[11] vals[12]]
  flux[2,a,:] = [vals[13] vals[14] vals[15] vals[16] vals[17] vals[18] vals[19] vals[20] vals[21]]
  flux[3,a,:] = [vals[22] vals[23] vals[24] vals[25] vals[26] vals[27] vals[28] vals[29] vals[30]]
# flux[2,a,:] = [vals[ 4] vals[ 5] vals[ 6] vals[ 7] vals[ 8] vals[ 9] vals[10] vals[11] vals[12]]
# flux[3,a,:] = [vals[ 4] vals[ 5] vals[ 6] vals[ 7] vals[ 8] vals[ 9] vals[10] vals[11] vals[12]]
end
write("found $num collocations in $(ARGS[1])\n")

allsiga = Array(Float64, 8, 8)                                                # use in situ and (a) any one analysis
allcora = Array(Float64, 8, 8)                                                # in turn as references and store the
allsigb = Array(Float64, 8, 8)                                                # third (b) error and correlation values
allcorb = Array(Float64, 8, 8)                                                # (do this for both extrapolations)
allalpa = Array(Float64, 8, 8)
allbeta = Array(Float64, 8, 8)
allalpb = Array(Float64, 8, 8)
allbetb = Array(Float64, 8, 8)

for a = 1:8
  for b = 1:8
    sampbuoy = flux[2,:,9]
    sampsate = flux[1,:,a]
    sampfore = flux[3,:,b]

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
# write("bet2 = $bet2\nbet3 = $bet3\nalp2 = $alp2\nalp3 = $alp3\n")

    sampsate = (flux[1,:,a] - alp2) / bet2
    sampfore = (flux[3,:,b] - alp3) / bet3

    avg1 = mean(sampbuoy)
    avg2 = mean(sampsate)
    avg3 = mean(sampfore)
    cv11 = mean(sampbuoy.*sampbuoy) - avg1^2
    cv12 = mean(sampbuoy.*sampsate) - avg1 * avg2
    cv13 = mean(sampbuoy.*sampfore) - avg1 * avg3
    cv22 = mean(sampsate.*sampsate) - avg2^2
    cv23 = mean(sampsate.*sampfore) - avg2 * avg3
    cv33 = mean(sampfore.*sampfore) - avg3^2

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

    sampsate = flux[3,:,a]
    sampfore = flux[1,:,b]

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
# write("bet2 = $bet2\nbet3 = $bet3\nalp2 = $alp2\nalp3 = $alp3\n")

    sampsate = (flux[1,:,a] - alp2) / bet2
    sampfore = (flux[3,:,b] - alp3) / bet3

    avg1 = mean(sampbuoy)
    avg2 = mean(sampsate)
    avg3 = mean(sampfore)
    cv11 = mean(sampbuoy.*sampbuoy) - avg1^2
    cv12 = mean(sampbuoy.*sampsate) - avg1 * avg2
    cv13 = mean(sampbuoy.*sampfore) - avg1 * avg3
    cv22 = mean(sampsate.*sampsate) - avg2^2
    cv23 = mean(sampsate.*sampfore) - avg2 * avg3
    cv33 = mean(sampfore.*sampfore) - avg3^2

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

write("allalp\n")
for b = 1:8                                                                   # then output the average alpha
  tmpa = tmpb = 0.0
  for a = 1:8
    if a != b  tmpa += allalpa[a,b]  end
    if a != b  tmpb += allalpb[a,b]  end
  end
  tmpa /= 7.0
  tmpb /= 7.0
  tmpc = 0.5 * (tmpa + tmpb)
  @printf("%22s %15.1f %15.1f %15.1f\n", dirs[b], tmpa, tmpb, tmpc)
end

write("allbet\n")
for b = 1:8                                                                   # then output the average beta
  tmpa = tmpb = 0.0
  for a = 1:8
    if a != b  tmpa += allbeta[a,b]  end
    if a != b  tmpb += allbetb[a,b]  end
  end
  tmpa /= 7.0
  tmpb /= 7.0
  tmpc = 0.5 * (tmpa + tmpb)
  @printf("%22s %15.2f %15.2f %15.2f\n", dirs[b], tmpa, tmpb, tmpc)
end

write("allsig\n")
for b = 1:8                                                                   # then output the average RMSE
  tmpa = tmpb = 0.0
  for a = 1:8
    if a != b  tmpa += allsiga[a,b]  end
    if a != b  tmpb += allsigb[a,b]  end
# if a != b @printf("%d %d %22s %15.5f %15.5f\n", a, b, dirs[a], allsiga[a,b], allsigb[a,b])  end
  end
  tmpa /= 7.0
  tmpb /= 7.0
  tmpc = 0.5 * (tmpa + tmpb)
  @printf("%22s %15.0f %15.0f %15.0f\n", dirs[b], tmpa, tmpb, tmpc)
end

write("allcor\n")
for b = 1:8                                                                   # then output the average correlation
  tmpa = tmpb = 0.0
  for a = 1:8
    if a != b  tmpa += allcora[a,b]  end
    if a != b  tmpb += allcorb[a,b]  end
  end
  tmpa /= 7.0
  tmpb /= 7.0
  tmpc = 0.5 * (tmpa + tmpb)
  @printf("%22s %15.2f %15.2f %15.2f\n", dirs[b], tmpa, tmpb, tmpc)
end
exit(0)


#=
filb = "$(ARGS[1]).triple.shf"
fpa = My.ouvre(filb, "w")                                                     # and save the stats
  write(fpa, "bet2 $bet2\n")
  write(fpa, "bet3 $bet3\n")
  write(fpa, "alp2 $alp2\n")
  write(fpa, "alp3 $alp3\n")
  write(fpa, "sig1 $sig1\n")
  write(fpa, "sig2 $sig2\n")
  write(fpa, "sig3 $sig3\n")
  write(fpa, "cor1 $cor1\n")
  write(fpa, "cor2 $cor2\n")
  write(fpa, "cor3 $cor3\n")
  close(fpa)
end

  sig1 = sqrt(cv11 - cv12 * cv13 / cv23)
  sig2 = sqrt(cv22 - cv12 * cv23 / cv13)
  sig3 = sqrt(cv33 - cv13 * cv23 / cv12)
  cor1 = sqrt(cv12 * cv13 / cv11 / cv23)
  cor2 = sqrt(cv12 * cv23 / cv22 / cv13)
  cor3 = sqrt(cv13 * cv23 / cv33 / cv12)

tmp = "avg1" ; println("$tmp = ",eval(parse(tmp)))
tmp = "avg2" ; println("$tmp = ",eval(parse(tmp)))
tmp = "avg3" ; println("$tmp = ",eval(parse(tmp)))
tmp = "cv11" ; println("$tmp = ",eval(parse(tmp)))
tmp = "cv12" ; println("$tmp = ",eval(parse(tmp)))
tmp = "cv13" ; println("$tmp = ",eval(parse(tmp)))
tmp = "cv22" ; println("$tmp = ",eval(parse(tmp)))
tmp = "cv23" ; println("$tmp = ",eval(parse(tmp)))
tmp = "cv33" ; println("$tmp = ",eval(parse(tmp)))

tmp = "bet2" ; println("$tmp = ",eval(parse(tmp)))
tmp = "bet3" ; println("$tmp = ",eval(parse(tmp)))
tmp = "alp2" ; println("$tmp = ",eval(parse(tmp)))
tmp = "alp3" ; println("$tmp = ",eval(parse(tmp)))

tmp = "mean(bet2)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(bet3)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(alp2)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(alp3)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(sig1)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(sig2)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(sig3)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(cor1)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(cor2)" ; println("$tmp = ",eval(parse(tmp)))
tmp = "mean(cor3)" ; println("$tmp = ",eval(parse(tmp)))
=#
