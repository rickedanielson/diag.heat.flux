#=
 = Split the daily average observations into calibration and validation groups, where the
 = calibration subset is taken to be at locations within each RESOL-degree box that contains
 = the largest number of available observations - RD March 2016.
 =#

using My
const RESOL            = 2.0                            # resolution at which to choose the calib subset
const CUTOFF           = 10                             # minimum number of obs at calib location
const LAT              = 1
const LON              = 2
const NUM              = 3
const PARAMS           = 3

if size(ARGS) == (0,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily\n\n")
  exit(1)
end

minlons = collect(-180.0:RESOL:180.0-RESOL)                                   # define a search grid for speed
midlons = minlons + RESOL / 2.0
maxlons = minlons + RESOL
minlats = collect( -90.0:RESOL: 90.0-RESOL)
midlats = minlats + RESOL / 2.0
maxlats = minlats + RESOL
numlons = length(minlons)
numlats = length(minlats)

fpa = My.ouvre(ARGS[1]*".locate", "r")                                        # read the available obs counts and
lines = readlines(fpa) ; close(fpa)                                           # convert to float (also for speed)
valn = length(lines)
vals = Array(Float64, valn, PARAMS)
for (a, line) in enumerate(lines)
  tmp = split(line)
  vals[a,LAT] = float(tmp[1])
  vals[a,LON] = float(tmp[2])
  vals[a,NUM] = float(tmp[3])
end

locs = Array(Tuple{Float64, Float64}, 0)                                      # find the calib locations
for a = 1:numlons                                                             # (largest number of daily obs
  for b = 1:numlats                                                           #  in each gridbox if available)
    @printf("%8.2f %8.2f\n", midlons[a], midlats[b])
    maxlat = maxlon = maxnum = -1.0
    for c = 1:valn
      if vals[c,NUM] > maxnum && minlons[a] <= vals[c,LON] < maxlons[a] &&
                                 minlats[b] <= vals[c,LAT] < maxlats[b]
        maxlat = vals[c,LAT]
        maxlon = vals[c,LON]
        maxnum = vals[c,NUM]
      end
    end
    if maxnum > CUTOFF
      push!(locs, (maxlat, maxlon))
    end
  end
end

tmp = @sprintf("%s_%.1f_locate.calib", ARGS[1], RESOL) ; fpb = My.ouvre(tmp, "w")
tmp = @sprintf("%s_%.1f_locate.valid", ARGS[1], RESOL) ; fpc = My.ouvre(tmp, "w")
for line in lines
  vals = split(line)
  vlat = float(vals[1])
  vlon = float(vals[2])
  if findfirst(locs, (vlat, vlon)) > 0  write(fpb, line)
  else                                  write(fpc, line)  end
end
close(fpb)
close(fpc)
exit(0)

#=
fpa = My.ouvre(ARGS[1],          "r")
fpb = My.ouvre(ARGS[1]*".calib", "w")
fpc = My.ouvre(ARGS[1]*".valid", "w")

for line in readlines(fpa)

end

close(fpa)
close(fpb)
close(fpc)
exit(0)

dats = Array(ASCIIString, 0)
date = ARGS[1][17:22]*"01" ; push!(dats, date) ; date = My.dateadd(date, 1, "dy")
   while date[7:8] != "01"   push!(dats, date) ; date = My.dateadd(date, 1, "dy")  end
sums = zeros(length(lons), length(lats), length(dats), length(inds))
numb = zeros(length(lons), length(lats), length(dats))

fpa = My.ouvre(ARGS[1], "r")                                                  # perform averages for each location and date
for line in readlines(fpa)
  vals = split(line)
  date = vals[4][1:8]
  lat = float(vals[5])
  lon = float(vals[6]) ; lon < -180 && (lon += 360) ; lon > 180 && (lon -= 360)

          inddat = findfirst(dats, date)
  dellat, indlat = findmin(abs(lats - lat))
  dellon, indlon = findmin(abs(lons - lon))

  if inddat > 0
    for (a, vind) in enumerate(inds)
      sums[indlon,indlat,inddat,a] += float(vals[vind])
    end
    numb[indlon,indlat,inddat] += 1.0
  end
end
close(fpa)

fpb = My.ouvre(ARGS[1]*".daily", "w")
for (inddat, date) in enumerate(dats)
  for (indlat, lat) in enumerate(lats)
    for (indlon, lon) in enumerate(lons)
      if numb[indlon,indlat,inddat] > 0
        sums[indlon,indlat,inddat,:] /= numb[indlon,indlat,inddat]
        form = @sprintf("%8.2f %8.2f %9s %14s %7.3f %8.3f %8.2f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.2f %8.3f %8.2f %8.2f %8.2f\n",
          sums[indlon,indlat,inddat, 1], sums[indlon,indlat,inddat, 2], "0000", date*"0000", lat, lon, sums[indlon,indlat,inddat, 3], sums[indlon,indlat,inddat, 4],
          sums[indlon,indlat,inddat, 5], sums[indlon,indlat,inddat, 6], sums[indlon,indlat,inddat, 7], sums[indlon,indlat,inddat, 8], sums[indlon,indlat,inddat, 9],
          sums[indlon,indlat,inddat,10], sums[indlon,indlat,inddat,11], sums[indlon,indlat,inddat,12], sums[indlon,indlat,inddat,13], sums[indlon,indlat,inddat,14])
        write(fpb, form)
      end
    end
  end
end

close(fpb)
exit(0)


#=
all.flux.daily:
  -24.23    32.21      0000   199910010000 -37.250   99.500  1015.50  320.000   14.400    9.256  -11.031    12.20     9.90    11.30    7.500  1128.71    10.00    10.00
all.flux.daily.locate:
   19.25   139.75       10

inds = [1 2 7 8 9 10 11 12 13 14 15 16 17 18]                                 # define the indecies of the daily averages,
lats = collect( -90.0:0.25:89.75)                                             # the output grid, the days in the month, and
lons = collect(-180.0:0.25:179.75)                                            # then initialize the (large) averaging arrays

#form = @sprintf("%8.2f %8.2f %9s %14s %7.3f %8.3f %8.2f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.2f %8.3f %8.2f %8.2f %8.2f\n",
#        shf, lhf, iden, date, val[:LAT], val[:LON], val[:SLP], val[:D], val[:W], uwnd, vwnd, val[:AT], val[:DPT], val[:SST], shum,
#        blay, hgtu, hgtt)
#   -0.07     0.21   384LNXH   199910010000  74.500   22.000   999.50  100.000    0.500   -0.492    0.087     2.00    -2.10     2.50    3.268   546.73    10.00    10.00
=#
