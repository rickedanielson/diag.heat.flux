#=
 = Split many daily observations by location and store the resulting files
 = in an insitu dir (assuming that the observations have been sorted already).
 = First read the locations of interest, as given, for example, by a list of
 = calibration locations and only the store daily obs groups at these
 = locations - RD March 2016.
 =#

using My
const LEN              = 100
const LOTS             = 1000
const START            = 2                              # make START-1 a valid array index

if size(ARGS) == (0,)
  print("\nUsage: jjj $(basename(@__FILE__)) all/all.flux.daily_2.0_locate.calib all.flux.daily.sort\n\n")
  exit(1)
end

miss = "-9999.00 -9999.00      0000   200007260000  77.500   11.500 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00 -9999.00"
locs = Set(Array(Tuple{Float64, Float64}, 0))                                 # allocate for and read the locations
lins = Array(ASCIIString, 1)                                                  # of interest

fpa = My.ouvre(ARGS[1], "r")
for line in eachline(fpa)
  vals = split(line)
  lat = float(vals[1])
  lon = float(vals[2])
  push!(locs, (lat, lon))
end
close(fpa)

n = 0 ; i = START                                                             # having initialized arrays with the first
fpb = My.ouvre(ARGS[2], "r")                                                  # entry undefined, starting with the second
for line in eachline(fpb)                                                     # entry, data for a new location is stored
  push!(lins, line)
  if i != START && lins[i][44:59] != lins[i-1][44:59]                         # at end of one location and beginning of
    vals = split(lins[i-1])                                                   # next (where 44:59 cover lat and lon):
    lat = float(vals[5])
    lon = float(vals[6])
    if in((lat, lon), locs)                                                   # if the location is of interest then write
      tmp = @sprintf("insitu/insitu.%9.3f.%9.3f", lat, lon)
      tmp = replace(tmp, " ", ".")
      fpc = My.ouvre(tmp, "w")
      for j = START:i-1  write(fpc, lins[j])  end
      close(fpc)
      n += 1
    end

    lins = Array(ASCIIString, 1) ; push!(lins, line)                          # then reset arrays with the new starting line
    i = START
  end
  i += 1
end
close(fpb)

vals = split(lins[i-1])                                                       # write the last file, if also of interest
lat = float(vals[5])
lon = float(vals[6])
if in((lat, lon), locs)
  tmp = @sprintf("insitu/insitu.%9.3f.%9.3f", lat, lon)
  tmp = replace(tmp, " ", ".")
  fpc = My.ouvre(tmr, "w")
  for j = START:i-1  write(fpc, lins[j])  end
  close(fpc)
  n += 1
end

print("wrote $n insitu files\n\n")
exit(0)
