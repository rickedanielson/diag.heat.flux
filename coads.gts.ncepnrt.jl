#=
 = This program estimates bulk sensible and latent heat flux given ship and buoy observations
 = in ICOADS in IMMA (R2.5) format.  A calculation of (saturated) specific humidity following
 = https://www.eol.ucar.edu/projects/ceop/dm/documents/refdata_report/eqns.html (Bolton 1980)
 = is included.  Where observation height is available, this is included and boundary layer
 = height is simply parameterized by latitude (2km at the equator and 0.5km at the poles,
 = with a Gaussian transition and no seasonality) - RD March 2016.
 =#

using My, ICOADS, COARE
const MISS             = -9999.0                        # generic missing value
const D2R              = 3.141592654 / 180.0            # degrees to radians conversion

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) ICOADS_R3_Beta3_199910.dat\n\n")
  exit(1)
end
if isfile(ARGS[1]*".flux")  exit(0)  end

fpa = My.ouvre(ARGS[1],         "r")
fpb = My.ouvre(ARGS[1]*".flux", "w")

for line in readlines(fpa)
  val = imma(rstrip(line))
  if haskey(val,  :YR) && haskey(val,  :MO) && haskey(val,  :DY) &&  haskey(val,  :HR) &&
     haskey(val, :LAT) && haskey(val, :LON) && haskey(val,   :D) &&  haskey(val,   :W) &&
     haskey(val, :SLP) && haskey(val,  :AT) && haskey(val, :SST) &&  haskey(val, :DPT)
    if 0 <= val[:W] < 50 && 880 < val[:SLP] < 1080 && -40 <= val[:AT] < 40 && -40 <= val[:DPT] < 40 && -2 <= val[:SST] < 40 &&
#      val[:SF]  < 4 && val[:AF]  < 4 && val[:UF]  < 4 && val[:VF]  < 4 && val[:PF]  < 4 && val[:RF]  < 4
       val[:SF] == 1 && val[:AF] == 1 && val[:UF] == 1 && val[:VF] == 1 && val[:PF] == 1 && val[:RF] == 1
      uwnd = -val[:W] * sin(val[:D] * D2R)
      vwnd = -val[:W] * cos(val[:D] * D2R)
      blay = 1500.0 * exp(-val[:LAT]^2.0 / 1600.0) + 500.0
      if haskey(val, :HOA) && 4 < val[:HOA] < 50  hgtu = val[:HOA]  else  hgtu = 10.0  end
      if haskey(val, :HOT) && 4 < val[:HOT] < 50  hgtt = val[:HOT]  else  hgtt = 10.0  end
      vprs = 6.112 * exp((17.67 * val[:DPT]) / (val[:DPT] + 243.5)) ; shum = 1000.0 * (0.622 * vprs) / (val[:SLP] - (0.378 * vprs))
      vprs = 6.112 * exp((17.67 * val[:SST]) / (val[:SST] + 243.5)) ; ssum = 1000.0 * (0.622 * vprs) / (val[:SLP] - (0.378 * vprs))
      best = [val[:W], 0, val[:SST], val[:AT], ssum, shum, 0, 0, 0, blay, val[:SLP], hgtu, hgtt, hgtt, val[:LAT], 1, 0, 0, 0]
      (shf, lhf) = cor30a(best)
      if haskey(val, :ID)  iden = replace(strip(val[:ID]), ' ', '_')  else  iden = "MISSING"  end
      date = @sprintf("%4d%2d%2d%4d", val[:YR], val[:MO], val[:DY], val[:HR]) ; date = replace(date, ' ', '0')
      form = @sprintf("%8.2f %8.2f %9s %14s %7.3f %8.3f %8.2f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.2f %8.3f %8.2f %8.2f %8.2f\n",
        shf, lhf, iden, date, val[:LAT], val[:LON], val[:SLP], val[:D], val[:W], uwnd, vwnd, val[:AT], val[:DPT], val[:SST], shum,
        blay, hgtu, hgtt)
      write(fpb, form)
    end
  end
end

close(fpa)
close(fpb)
exit(0)
