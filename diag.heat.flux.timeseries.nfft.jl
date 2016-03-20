#=
 = Create NFFT power spectral coefficients (one-sided) at locations where
 = analyses provide good coverage of the 2001-2007 period and store a weighted
 = average of these spectra - RD October 2015
 =#

using My #, NFFT
const MISS             = -9999.0                        # generic missing value
const DAYS             = 3745                           # number of days in full timeseries
const TIMES            = 2556                           # number of days in during 2001-2007 (and number of spectral coefficients)
const CALIB            = 0                              # flag determining whether to calibrate (1 = yes)

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) ....41.750...148.250\n\n")
  exit(1)
end

dirs   = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
calalp = [   2.2,          4.1,     3.4,           3.4,      3.3,     1.9,      3.3,       5.6]
calbet = [  0.96,         0.92,    0.82,          0.98,     0.91,    0.87,     0.95,      0.85]
dlen   = length(dirs) + 1
data   = Array(Float64, dlen, DAYS)                                           # allocate space for timeseries in all dirs

torus(x) =              (x - 459) / TIMES - 0.5                               # map daily index to the NFFT torus [-0.5,0.5)
#artl(x) = x < 1736.5 ? (x - 459) / 1277.5 : (3014 - x) / 1277.5              # map daily index to Bartlett triangular weights
bartl(x) = 1.0

for (a, dir) in enumerate(dirs)                                               # loop through each analysis dir and read series
  tmpa = "$dir/$dir$(ARGS[1])"                                                # read  date    shf       lhf
  fpa = My.ouvre(tmpa, "r", false) ; lines = readlines(fpa) ; close(fpa)      # 1999102312 62.820 -9999.000
  for (b, line) in enumerate(lines)
    vals = float(split(line))
    data[a,b] = CALIB == 1 ? (vals[2] - calalp[a]) / calbet[a] : vals[2]
  end
end

for a = 1:DAYS                                                                # mask days missing any one analysis
  data[dlen,a] = 1
  for b = 1:dlen - 1
    if -333 >= data[b,a] || data[b,a] >= 3333
      data[dlen,a] = 0
    end
  end
end

for (a, dir) in enumerate(dirs)                                               # then for each dir
  datb = Array(Float64, 0)
  datc = Array(Float64, 0)

  push!(datb, torus(459))                                                     # define the NFFT sampled data with
  push!(datc, bartl(459) * 0.0)                                               # valid (zero-amplitude) endpoints
  for b = 460:3013                                                            # at 2001-01-01 and 2007-12-31
    if data[dlen,b] > 0
      push!(datb, torus(b))
      push!(datc, bartl(b) * data[a,b])
    end
  end
  push!(datb, torus(3014))
  push!(datc, bartl(3014) * 0.0)
  nums = length(datb)

  if CALIB == 1
    tmpa = "$dir/$dir$(ARGS[1]).fftcal"
  else
    tmpa = "$dir/$dir$(ARGS[1]).fft"
  end
  fpa = My.ouvre(tmpa, "w", false)
  for b = 1:nums
    tmpb = @sprintf("%15.8f %15.8f\n", datb[b], datc[b])
    write(fpa, tmpb)
  end
  close(fpa)

# print("diag.heat.flux.timeseries.nfft $tmpa\n")
    run(`diag.heat.flux.timeseries.nfft $tmpa`)                               # and compute each spectra
end
exit(0)
