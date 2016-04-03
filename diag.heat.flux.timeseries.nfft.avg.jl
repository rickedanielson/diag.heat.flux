#=
 = Read NFFT power spectral coefficients (one-sided) for all analyses at all
 = locations where analyses provide good coverage of the 2001-2007 period and
 = store a weighted average of these spectra, where the number of observations
 = available at each location is the weight - RD October 2015, March 2016.
 =#

using My
const SPECS            = 1279                           # length of the one-sided spectra
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_calib.airt.got2000\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
dirn = length(dirs)
stot = zeros(SPECS, dirn + 1)
ntot = zeros(SPECS, dirn + 1)
vari = ARGS[1][end-11:end-8]

fpa = My.ouvre(ARGS[1], "r")                                                  # for each location, read all spectra
for line in eachline(fpa)
  (lat, lon, num) = float(split(line))
if lat > 15
  tmp = @sprintf("%9.3f.%9.3f", lat, lon)
  tail = replace(tmp, " ", ".")
  tmpz = "fft/$vari.$tail.fft"
  fpz  = My.ouvre(tmpz, "r", false) ; linez = readlines(fpz) ; close(fpz)
  for (z, linz) in enumerate(linez)
    vals = float(split(linz))
    for y = 1:dirn + 1
      if vals[y] != MISS
        stot[z,y] = num * vals[y]
        ntot[z,y] = num
      end
    end
  end
end
end
close(fpa)

tmp = zeros(dirn + 1)
fpa = My.ouvre(ARGS[1]*".spec", "w")
for z = 1:SPECS
  for y = 1:dirn + 1
    tmp[y] = ntot[z,y] == 0 ? MISS : stot[z,y] / ntot[z,y]
  end
  out = @sprintf("%15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f\n",
    tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6], tmp[7], tmp[8], tmp[9])
  write(fpa, out)
end
close(fpa)
exit(0)
