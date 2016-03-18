#=
 = Loop through timeseries of a given analysis and create the corresponding forward and
 = backward extrapolated timeseries for available variables - RD September 2015, March 2016.
 =#

using My, Interpolations
const SHFX             = 1                              # indecies of all data variables
const LHFX             = 2
const WSPD             = 3
const AIRT             = 4
const SSTT             = 5
const SHUM             = 6
const PARS             = 6

const BEF              = 1                              # indecies of the source of extrapolations
const NOW              = 2
const AFT              = 3
const SRCS             = 3

const EXTRA            = 9                              # number of points used for extrapolation
const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) cfsr z.listah\n\n")
  exit(1)
end

inner = div(EXTRA - 1, 2)
outer = div(EXTRA + 1, 2)
dats = Array(Float64,             TIMS)
data = Array(Float64, PARS, SRCS, TIMS)

fpa = My.ouvre("$(ARGS[1])/$(ARGS[2])", "r")                                  # loop through the list of locations
files = readlines(fpa) ; close(fpa)                                           # and process each timeseries
for fila in files
  fila = strip(fila)
  fpa = My.ouvre("$(ARGS[1])/$fila", "r", false)
  lines = readlines(fpa) ; close(fpa)
  for (a, line) in enumerate(lines)
    vals = float(split(line))
    data[SHFX,NOW,a] = float(vals[1])
    data[LHFX,NOW,a] = float(vals[2])
    dats[a]          =       vals[4]
    data[WSPD,NOW,a] = float(vals[9])
    data[AIRT,NOW,a] = float(vals[12])
    data[SSTT,NOW,a] = float(vals[14])
    data[SHUM,NOW,a] = float(vals[15])
  end

  for a = 1:PARS                                                              # set to missing the first few BEF
    for b = 1:EXTRA+1                                                         # extrapolations (not defined below)
      data[a,BEF,b] = MISS
    end
  end

  for a = 1:PARS                                                              # simultaneously extrap from BEF and AFT
    for b = 1+outer:TIMS-outer
      tmp = vec(data[a,NOW,b-inner:b+inner])
      if all(-333 .< tmp .< 3333)
        itp = interpolate(tmp, BSpline(Quadratic(Line())), OnCell())
        data[a,BEF,b+outer] = itp[10]
        data[a,AFT,b-outer] = itp[0]
      else
        data[a,BEF,b+outer] = data[a,AFT,b-outer] = MISS
      end
    end
  end

  for a = 1:PARS                                                              # set to missing the last few AFT
    for b = 0:EXTRA                                                           # extrapolations (not defined above)
      data[a,AFT,TIMS-b] = MISS
    end
  end

  filb = "$fila.bef"                                                          # then save all extrapolations
  filc = "$fila.aft"
  fpb = My.ouvre("$(ARGS[1])/$filb", "w", false)
  fpc = My.ouvre("$(ARGS[1])/$filc", "w", false)
  (lll, lat, lon) = split(replace(fila, r"[\.]{2,}", " "))
  for a = 1:TIMS
    formb = @sprintf("%8.2f %8.2f %9s %14s %7.3f %8.3f %8.2f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.2f %8.3f %8.2f %8.2f %8.2f\n",
      data[SHFX,BEF,a],       data[LHFX,BEF,a], "0000", dats[a], float(lat), float(lon), MISS, MISS, data[WSPD,BEF,a], MISS, MISS,
      data[AIRT,BEF,a], MISS, data[SSTT,BEF,a],                                                      data[SHUM,BEF,a], MISS, MISS, MISS)
    formc = @sprintf("%8.2f %8.2f %9s %14s %7.3f %8.3f %8.2f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.2f %8.3f %8.2f %8.2f %8.2f\n",
      data[SHFX,AFT,a],       data[LHFX,AFT,a], "0000", dats[a], float(lat), float(lon), MISS, MISS, data[WSPD,AFT,a], MISS, MISS,
      data[AIRT,AFT,a], MISS, data[SSTT,AFT,a],                                                      data[SHUM,AFT,a], MISS, MISS, MISS)
    write(fpb, formb)
    write(fpc, formc)
  end
  close(fpb)
  close(fpc)
end
exit(0)
