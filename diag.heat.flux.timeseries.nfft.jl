#=
 = Split a set of observation locations into locations of good and poor temporal coverage
 = (e.g., as given by the minimum shfx coverage among all analyses) throughout a core period
 = (i.e., most of 2001-2007) and save the two location subsets as separate files.  Call these
 = locations of good coverage "the collocations".  Then create one-sided NFFT power spectral
 = coefficients for the collocations.  Note that all data gaps in any one analysis are mapped
 = to the other analyses and that a nonequidistant FFT algorithm (NFFT; www.nfft.org) is thus
 = employed - RD October 2015, March 2016.
 =#

using My, NFFT
const SHFX             = 1                              # indecies of all data variables
const LHFX             = 2
const WSPD             = 9
const AIRT             = 12
const SSTT             = 14
const SHUM             = 15

const TIMTOT           = 3745                           # length of the full timeseries
const TIMSTA           =  459                           #  start of the 2001-2007 period of interest
const TIMLEN           = 2556                           # length of the 2001-2007 period of interest (and number of spectral coefficients)
const CUTOFF           = 2000                           # minimum number from all analyses during period of interest
const MISS             = -9999.0                        # generic missing value
const CALIB            = 0                              # flag determining whether to calibrate (1 = yes)

if size(ARGS) != (2,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_calib shfx\n\n")
  exit(1)
end

vind = 0                                                                      # identify the variable of interest
ARGS[2] == utf8("shfx") && (vind = SHFX)                                      # (note ARGS are UTF8 by default)
ARGS[2] == utf8("lhfx") && (vind = LHFX)
ARGS[2] == utf8("wspd") && (vind = WSPD)
ARGS[2] == utf8("airt") && (vind = AIRT)
ARGS[2] == utf8("sstt") && (vind = SSTT)
ARGS[2] == utf8("shum") && (vind = SHUM)
if vind == 0
  write(STDERR, "ERROR : didn't recognize $(ARGS[2]) among shfx/lhfx/wspd/airt/sstt/shum\n")
  exit(-1)
end

torus(x) = (x - TIMSTA) / TIMLEN - 0.5                                        # map daily index to the NFFT torus [-0.5,0.5)
dirs     = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
calalp   = [   2.2,          4.1,     3.4,           3.4,      3.3,     1.9,      3.3,       5.6]
calbet   = [  0.96,         0.92,    0.82,          0.98,     0.91,    0.87,     0.95,      0.85]
dirn     = length(dirs)

fpa = My.ouvre(ARGS[1],                           "r")
fpb = My.ouvre(ARGS[1]*"."*ARGS[2]*".got$CUTOFF", "w")
fpc = My.ouvre(ARGS[1]*"."*ARGS[2]*".not$CUTOFF", "w")

for line in eachline(fpa)                                                     # read the available obs counts and
  (lat, lon, num) = float(split(line))                                        # allocate timeseries data for all dir
  tmp = @sprintf("%9.3f.%9.3f", lat, lon) ; tail = replace(tmp, " ", ".")
  data = Array(Float64, TIMLEN, dirn)

  max = TIMTOT                                                                # among all analyses, track the minimum
  for (a, dir) in enumerate(dirs)                                             # number of valid values in the subperiod
    count = 0
    file = "$dir/$dir.$tail"
    fpd = My.ouvre(file, "r", false)
    lines = readlines(fpd) ; close(fpd)
    for b = TIMSTA:TIMSTA + TIMLEN - 1
      vals = float(split(lines[b]))
      data[b,a] = vals[vind]
      if -333.0 < vals[vind] < 3333.0  count += 1  end
    end
    if count < max   max = count  end
    if max < CUTOFF  break        end
  end

  if max < CUTOFF                                                             # augment one of the subset list files
    write(fpc, line)
  else
    write(fpb, line)
    for (a, dir) in enumerate(dirs)                                           # and for each dir
      datb = Array(Float64, 0)
      datc = Array(Float64, 0)

      push!(datb, torus(TIMSTA))                                              # define the NFFT sampled data with
      push!(datc, bartl(TIMSTA) * 0.0)                                        # valid (zero-amplitude) endpoints
      for b = TIMSTA + 1:3013                                                 # at 2001-01-01 and 2007-12-31
        if data[dlen,b] > 0
          push!(datb, torus(b))
          push!(datc, bartl(b) * data[a,b])
        end
      end
      push!(datb, torus(3014))
      push!(datc, bartl(3014) * 0.0)
      nums = length(datb)

      p = NFFTPlan(datb, nums)
      f = nfft_adjoint(p, datc)
      absf = abs2(f)
      datd = Array(Float64, 0)
      push!(datd, absf[div(TIMES,2)+1])
      for a = 1:TIMES/2-1
        push!(datd, absf[TIMES/2+1+a] + absf[TIMES/2+1-a])
      end
      push!(datd, absf[1])
      datd /= TIMES * nums
      for a = 1:TIMES/2+1
        @printf("%15.8f %15.8f\n", (float)a / (float)TIMES, datd[a])
      end
    end

    if CALIB == 0  tmp = "fft/$(ARGS[2]).$tail.fft"
    else           tmp = "fft/$(ARGS[2]).$tail.fftcal"  end
    fpd = My.ouvre(tmp, "w", false)
    for b = 1:nums
      tmp = @sprintf("%15.8f %15.8f\n", datb[b], datc[b])
      write(fpd, tmp)
    end
    close(fpd)
  end
end

close(fpa)
close(fpb)
close(fpc)
exit(0)


#=
bartl(x) = x < 1736.5 ? (x - TIMSTA) / 1277.5 : (3014 - x) / 1277.5           # map daily index to Bartlett triangular weights
bartl(x) = 1.0

using My, NFFT
const MISS             = -9999.0
const DAYS             = 3745
const TIMES            = 2556
const CALIB            = 0
dirs   = ["cfsr"]
dlen   = length(dirs) + 1
data   = Array(Float64, dlen, DAYS)
torus(x) = (x - TIMSTA) / TIMES - 0.5
bartl(x) = 1.0
tmpa = "cfsr....27.500...-39.000"
fpa = My.ouvre(tmpa, "r", false) ; lines = readlines(fpa) ; close(fpa)
a = 1
for (b, line) in enumerate(lines)
  vals = float(split(line))
  data[a,b] = vals[1]
end
for a = 1:DAYS                                                                # mask days missing any one analysis
  data[dlen,a] = 1
  for b = 1:dlen - 1
    if -333 >= data[b,a] || data[b,a] >= 3333
      data[dlen,a] = 0
    end
  end
end
datb = Array(Float64, 0)
datc = Array(Complex{Float64}, 0)
push!(datb, torus(TIMSTA))
push!(datc, bartl(TIMSTA) * 0.0im)
a = 1
for b = 460:3013
  if data[dlen,b] > 0
    push!(datb, torus(b))
    push!(datc, bartl(b) * data[a,b])
  end
end
push!(datb, torus(3014))
push!(datc, bartl(3014) * 0.0)

nums = length(datb)
p = NFFTPlan(datb, nums)
f = nfft_adjoint(p, datc)
# g = nfft(p, f)
absf = abs2(f)
datd = Array(Float64, 0)
push!(datd, absf[div(TIMES,2)+1])
for a = 1:TIMES/2-1
  push!(datd, absf[TIMES/2+1+a] + absf[TIMES/2+1-a])
end
push!(datd, absf[1])
datd /= TIMES * nums
for a = 1:TIMES/2+1
  @printf("%15.8f %15.8f\n", (float)a / (float)TIMES, datd[a])
end

    for (a = 1; a <= TIMES/2+1; a++) {
      if (a == 1)
        tmp = powf(p.f_hat[TIMES/2+1][0], 2.0) + powf(p.f_hat[TIMES/2+1][1], 2.0);
      else if (a == TIMES/2+1)
        tmp = powf(p.f_hat[1        ][0], 2.0) + powf(p.f_hat[1        ][1], 2.0);
      else
        tmp = powf(p.f_hat[TIMES/2+1+a][0], 2.0) + powf(p.f_hat[TIMES/2+a][1], 2.0) +
              powf(p.f_hat[TIMES/2+1-a][0], 2.0) + powf(p.f_hat[TIMES/2-a][1], 2.0);
      tmp /= (float)TIMES * (float)obsnum;
      fprintf(fpa, "%15.8f %15.8f\n", (float)a / (float)TIMES, tmp);
=#
