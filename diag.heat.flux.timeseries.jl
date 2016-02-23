#=
 = Loop through all analyses and extract variables of interest at the position
 = of a set of buoy observations - RD September 2015, February 2016
 =#

using My, NetCDF, Grid
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (2,)
  print("\nUsage: jjo $(basename(@__FILE__)) all.flux.locate.sort cfsr\n\n")
  exit(1)
end

buoy = Set{(Float64, Float64)}()                                              # initialize a grid mask that is
csv = readcsv(ARGS[1]) ; (vals,) = size(csv)                                  # true wherever buoys are located
for a = 1:vals  push!(buoy, (csv[a,2], csv[a,1]))  end

lats =  -90.0:0.25:89.75                                                      # locs[   1,  1] = (-180.00,-90.00)
lons = -180.0:0.25:179.75                                                     # locs[   1,720] = (-180.00, 89.75)
locs = [   (x, y)        for x=lons, y=lats]                                  # locs[1440,  1] = ( 179.75,-90.00)
mask = [in((x, y), buoy) for x=lons, y=lats]                                  # locs[1440,720] = ( 179.75, 89.75)
fend = locs[mask .== true] ; (locn,) = size(fend)                             # and define all filename endings

vars = ["surface_upward_sensible_heat_flux", "surface_upward_latent_heat_flux",
        "air_surface_specific_humidity", "wind_speed", "air_temperature",
        "sea_surface_temperature"] ; (varn,) = size(vars)                     # define the available variables
tail = "-OHF-L4-global_daily_0.25x0.25-v0.7-f01.0.nc"                         # and the filename stems/ending

ARGS[2] ==        "cfsr" && (stem =        "cfsr-" ; vars[2] = "" ; vars[5] = "2t")
ARGS[2] ==  "erainterim" && (stem =  "erainterim-" ; vars[3] = "")            # dew_point_temperature is available but slp is missing
ARGS[2] ==       "hoaps" && (stem =       "hoaps-" ; vars[5] = "")            # should air_temperature be missing?
ARGS[2] == "ifremerflux" && (stem = "ifremerflux-")
ARGS[2] ==      "jofuro" && (stem =      "jofuro-" ; vars[5] = "" ; vars[6] = "")
ARGS[2] ==       "merra" && (stem =       "merra-")
ARGS[2] ==      "oaflux" && (stem =      "oaflux-")
ARGS[2] ==     "seaflux" && (stem =     "seaflux-")

fpn = Array(IOStream, 0)                                                      # then open a set of output files
for a = 1:locn                                                                # at all buoy locations
  (lon, lat) = fend[a]
  tmp = @sprintf("%9.3f.%9.3f", lat, lon)
  tmq = replace(tmp, " ", ".")
  tmr = "$(ARGS[2])/$(ARGS[2]).$tmq"
  fpa = My.ouvre(tmr, "w")
  push!(fpn, fpa)
end

date = "19991001120000"                                                       # and fill the output files (all
while int(date) < 20100101000000                                              # locs and vars) one date at a time
  stor = fill(MISS, locn, varn)
  file = ARGS[2] * "/" * stem * date * tail ; println(file)
  if isfile(file)
    for a = 1:varn
      flag = dat3 = false
      if vars[a] != ""
        flag = true
                 try    nc = NetCDF.open(file, mode=NC_NOWRITE, readdimvar=false)          catch  flag = false  end
        if flag  try  dat3 = NetCDF.readvar(nc, vars[a], start=[1,1,1], count=[-1,-1,-1])  catch  flag = false  end  end
                 try         NetCDF.close(nc)                                                                   end
      end
      if flag
        dat2 = dat3[:,:,1]
        stor[:,a] = dat2[mask .== true]
      end
    end
  end

  for a = 1:locn
    stor[a,:] = map(x -> begin
          if x > -MISS return MISS
      elseif x <  MISS return MISS
      else return x
      end
    end, stor[a,:])
#   if vars[3] == "dew_point_temperature"
#     
#   end
    tmp = @sprintf("%s %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f\n", date[1:10],
      stor[a,1], stor[a,2], stor[a,3], stor[a,4], stor[a,5], stor[a,6])
    write(fpn[a], tmp)
  end
  date = My.dateadd(date, 1, "dy")
end

print("closing...\n")
for a = 1:locn  close(fpn[a])  end
exit(0)
