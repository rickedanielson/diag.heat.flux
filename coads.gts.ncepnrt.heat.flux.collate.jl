#=
 = Discretize one month of ICOADS observations into averages at daily, 0.25-degree resolution
 = (corresponding to a set of gridded OHF reference analyses) including all flux input variables
 = (e.g., wspd, sst, airt, and shum) - RD March 2016.
 =#

using My

if size(ARGS) == (0,)
  print("\nUsage: jjj $(basename(@__FILE__)) ICOADS_R3_Beta3_200001.dat.flux\n\n")
  exit(1)
end
if isfile(ARGS[1]*".daily")  exit(0)  end

inds = [1 2 7 8 9 10 11 12 13 14 15 16 17 18]                                 # define the indecies of the daily averages,
lats = collect( -90.0:0.25:89.75)                                             # the output grid, the days in the month, and
lons = collect(-180.0:0.25:179.75)                                            # then initialize the (large) averaging arrays

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

  for (a, vind) in enumerate(inds)
    sums[indlon,indlat,inddat,a] += float(vals[vind])
  end
  numb[indlon,indlat,inddat] += 1.0
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
#form = @sprintf("%8.2f %8.2f %9s %14s %7.3f %8.3f %8.2f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.2f %8.3f %8.2f %8.2f %8.2f\n",
#        shf, lhf, iden, date, val[:LAT], val[:LON], val[:SLP], val[:D], val[:W], uwnd, vwnd, val[:AT], val[:DPT], val[:SST], shum,
#        blay, hgtu, hgtt)
#   -0.07     0.21   384LNXH   199910010000  74.500   22.000   999.50  100.000    0.500   -0.492    0.087     2.00    -2.10     2.50    3.268   546.73    10.00    10.00

const SHFX             = 1                              # identify indecies of the input data
const LHFX             = 2
const SLPP             = 3
const WDIR             = 4
const WSPD             = 5
const UWND             = 6
const VWND             = 7
const AIRT             = 8
const DPTT             = 9
const SSTT             = 10
const SHUM             = 11
const BLAY             = 12
const HGTU             = 13
const HGTT             = 14
const PARAMS           = 14
=#
