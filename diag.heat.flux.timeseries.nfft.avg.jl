#=
 = Read NFFT power spectral coefficients (one-sided) at all locations where
 = analyses provide good coverage of the 2001-2007 period and store a weighted
 = average of these spectra - RD October 2015
 =#

using My
const MISS             = -9999.0                        # generic missing value
const DAYS             = 3745                           # number of days in full timeseries
const TIMES            = 2556                           # number of days in during 2001-2007 (and number of spectral coefficients)
const CALIB            = 1                              # flag determining whether to calibrate (1 = yes)

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.locate.min2000\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
csv = readcsv(ARGS[1])                                                        # read the flux data to identify
(locs,) = size(csv)                                                           # locations with good timeseries

for (b, dir) in enumerate(dirs)                                               # then loop through the analyses and
  spectra  = zeros(Float64, div(TIMES, 2) + 1)                                # allocate space for the average spectrum
  totsum = 0.0
  for a = 1:locs
    if csv[a,3] > 0
      tmpa = @sprintf("%9.3f.%9.3f", csv[a,1], csv[a,2])
      tmpb = replace(tmpa, " ", ".")
      if CALIB == 1
        tmpd = "$dir/$dir.$tmpb.fftcal"
        tmpe = "$dir/$dir.$tmpb.fftcalest"
      else
        tmpd = "$dir/$dir.$tmpb.fft"
        tmpe = "$dir/$dir.$tmpb.fftest"
      end

      fpa = My.ouvre(tmpe, "r", false) ; lines = readlines(fpa) ; close(fpa)
      for (b, line) in enumerate(lines)
        vals = float(split(line))
        spectra[b] += vals[2] * csv[a,3]
      end
      totsum += csv[a,3]
#     rm(tmpd) ; rm(tmpe)
    end
  end

  tmpa = "spectruo.$(ARGS[1]).$dir"                                           # store the weighted average spectrum
  fpa = My.ouvre(tmpa, "w")
  for a = 1:div(TIMES, 2) + 1
    tmpa = @sprintf("%15.8f %15.8f\n", (a - 1) / TIMES, spectra[a] / totsum)
    write(fpa, tmpa)
  end
  close(fpa)
end
exit(0)
