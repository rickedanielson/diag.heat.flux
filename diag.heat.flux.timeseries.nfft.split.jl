#=
 = Split a set of observation locations into locations of good and poor
 = temporal coverage (e.g., as given by the minimum SHFX coverage among
 = all analyses) throughout a core period (i.e., most of 2001-2007) and
 = save the two location subsets as separate files - RD March 2016.
 =#

using My
const SHFX             = 1                              # indecies of all data variables
const LHFX             = 2
const WSPD             = 9
const AIRT             = 12
const SSTT             = 14
const SHUM             = 15

const LAT              = 1
const LON              = 2
const NUM              = 3
const PARAMS           = 3

const TIMTOT           = 3745                           # length of the full timeseries
const TIMSTA           =  459                           #  start of the 2001-2007 period of interest
const TIMLEN           = 2556                           # length of the 2001-2007 period of interest
const CUTOFF           = 2000                           # minimum number from all analyses during period of interest
const MISS             = -9999.0                        # generic missing value

if size(ARGS) == (0,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily_2.0_locate.calib.sort\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
(dirn,) = size(dirs)

fpa = My.ouvre(ARGS[1],              "r")                                     # read the available obs counts
fpb = My.ouvre(ARGS[1]*"got$CUTOFF", "w")
fpc = My.ouvre(ARGS[1]*"not$CUTOFF", "w")

for line in eachline(fpa)
  (lat, lon, num) = float(split(line))
  tmp = @sprintf("%9.3f.%9.3f", lat, lon) ; tail = replace(tmp, " ", ".")

  max = TIMTOT                                                                # among all analyses, track the minimum
  for dir in dirs                                                             # number of valid SHFX values within the
    count = 0                                                                 # subperiod
    file = "$dir/$dir.$tail"
    fpd = My.ouvre(file, "r", false)
    lines = readlines(fpa) ; close(fpd)
    for a = TIMSTA:TIMSTA + TIMLEN - 1
      vals = float(split(lines[a]))
      if -333.0 < vals[SHFX] < 3333.0  count += 1  end
    end
    if count < max  max = count  end
  end

  if max >= CUTOFF                                                            # and augment one of the subfiles
    write(fpb, line)
  else
    write(fpc, line)
  end
end

close(fpa)
close(fpb)
close(fpc)
exit(0)
