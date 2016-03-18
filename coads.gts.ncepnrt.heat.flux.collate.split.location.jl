#=
 = Split a set of daily observations by location and store the resulting
 = files in the insitu dir (assuming that the observations have been sorted
 = already).  First read the locations of interest, as given, for example,
 = by a list of calibration locations and only the store daily obs groups
 = at these locations - RD March 2016.
 =#

using My
const LEN              = 100
const LOTS             = 1000
const START            = 2                              # make START-1 a valid array index

if size(ARGS) == (0,)
  print("\nUsage: jjj $(basename(@__FILE__)) all/all.flux.daily_2.0_locate.calib all.flux.daily.sort\n\n")
  exit(1)
end

locs = Set(Array(Tuple{Float64, Float64}, 0))                                 # allocate for the locations of interest
lins = Array(ASCIIString, 1)                                                  # and initialize some arrays with the first
lats = Array(ASCIIString, 1)                                                  # entry undefined (starting with the second
lons = Array(ASCIIString, 1)                                                  # entry, data for a new location is stored)

fpa = My.ouvre(ARGS[1], "r")                                                  # read the locations of interest
for line in eachline(fpa)
  vals = split(line)
  lat = float(vals[1])
  lon = float(vals[2])
  push!(locs, (lat, lon))
end
close(fpa)

fpb = My.ouvre(ARGS[2], "r")
for line in eachline(fpb)
  vals = split(line)
  lat = float(vals[1])
  lon = float(vals[2]) 
  push!(locs, (lat, lon))
end
close(fpb)
exit(0)

#=
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

=#
