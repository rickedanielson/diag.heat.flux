#=
 = Loop through all analyses and extract variables of interest at
 = the position of a set of buoy observations - RD September 2015
 =#

using My, NetCDF, Grid
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (2,)
  write("\nUsage: jjj $(basename(@__FILE__)) all.flux.locate.sort cfsr\n\n")
  exit(1)
end

buoy = Set{(Float64, Float64)}()                                              # initialize a grid mask that is
csv = readcsv(ARGS[1]) ; (vals,) = size(csv)                                  # true wherever buoys are located
for a = 1:vals  push!(buoy, (csv[a,2], csv[a,1]))  end                        # and initialize filename components

lats =  -90.0:0.25:89.75                                                      # locs[   1,  1] = (-180.00,-90.00)
lons = -180.0:0.25:179.75                                                     # locs[   1,720] = (-180.00, 89.75)
locs = [   (x, y)        for x=lons, y=lats]                                  # locs[1440,  1] = ( 179.75,-90.00)
mask = [in((x, y), buoy) for x=lons, y=lats]                                  # locs[1440,720] = ( 179.75, 89.75)
varc = locs[mask .== true] ; (varn,) = size(varc)

tail = "-OHF-L4-global_daily_0.25x0.25-v0.6-f01.0.nc"
ARGS[2] ==        "cfsr" && (stem =        "cfsr-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "")
ARGS[2] ==  "erainterim" && (stem =  "erainterim-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux")
ARGS[2] ==       "hoaps" && (stem =       "hoaps-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux")
ARGS[2] == "ifremerflux" && (stem = "ifremerflux-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux")
ARGS[2] ==      "jofuro" && (stem =      "jofuro-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux")
ARGS[2] ==       "merra" && (stem =       "merra-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux")
ARGS[2] ==      "oaflux" && (stem =      "oaflux-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux")
ARGS[2] ==     "seaflux" && (stem =     "seaflux-" ; vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux")
vara = "surface_upward_sensible_heat_flux" ; varb = "surface_upward_latent_heat_flux"

fpn = Array(IOStream, 0)                                                      # then open a set of output files
for a = 1:varn
  (lon, lat) = varc[a]
  tmp = @sprintf("%9.3f.%9.3f", lat, lon)
  tmq = replace(tmp, " ", ".")
# tmr = "$(ARGS[2])/$(ARGS[1]).$tmq"
  tmr = "$(ARGS[2])/$(ARGS[2]).$tmq"
  fpa = My.ouvre(tmr, "w")
  push!(fpn, fpa)
end

date = "19991001120000"
while int(date) < 20100101000000
  file = ARGS[2] * "/" * stem * date * tail ; println(file)
  if isfile(file)
    shflag = lhflag = true
#   try  shf = ncread(file, vara, start=[1,1,1], count=[-1,-1,-1])  catch  flag = false  end
#   try  lhf = ncread(file, varb, start=[1,1,1], count=[-1,-1,-1])  catch  flag = false  end
          nc = NetCDF.open(file, mode=NC_NOWRITE, readdimvar=false)
    try  shf = NetCDF.readvar(nc, vara, start=[1,1,1], count=[-1,-1,-1])  catch  shflag = false  end
    try  lhf = NetCDF.readvar(nc, varb, start=[1,1,1], count=[-1,-1,-1])  catch  lhflag = false  end
               NetCDF.close(nc)
    if shflag && lhflag
      if length(size(shf)) == 3
        arrtmp = shf[:,:,1] ; shf = arrtmp
        arrtmp = lhf[:,:,1] ; lhf = arrtmp
      end
      subshf = shf[mask .== true]
      sublhf = lhf[mask .== true]
      for a = 1:varn
        tmp = @sprintf("%s %9.3f %9.3f\n", date[1:10], subshf[a], sublhf[a])
        write(fpn[a], tmp)
      end
    elseif shflag
      if length(size(shf)) == 3
        arrtmp = shf[:,:,1] ; shf = arrtmp
      end
      subshf = shf[mask .== true]
      for a = 1:varn
        tmp = @sprintf("%s %9.3f %9.3f\n", date[1:10], subshf[a], MISS)
        write(fpn[a], tmp)
      end
    elseif lhflag
      if length(size(lhf)) == 3
        arrtmp = lhf[:,:,1] ; lhf = arrtmp
      end
      sublhf = lhf[mask .== true]
      for a = 1:varn
        tmp = @sprintf("%s %9.3f %9.3f\n", date[1:10], MISS, sublhf[a])
        write(fpn[a], tmp)
      end
    else
      for a = 1:varn
        tmp = @sprintf("%s %9.3f %9.3f\n", date[1:10], MISS, MISS)
        write(fpn[a], tmp)
      end
    end
  else
    for a = 1:varn
      tmp = @sprintf("%s %9.3f %9.3f\n", date[1:10], MISS, MISS)
      write(fpn[a], tmp)  
    end
  end
  date = My.dateadd(date, 1, "dy")
end

write("closing...\n")
for a = 1:varn  close(fpn[a])  end
exit(0)
