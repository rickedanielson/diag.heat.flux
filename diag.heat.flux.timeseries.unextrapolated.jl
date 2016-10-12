#=
 = Loop through timeseries of a given analysis and create the corresponding forward and
 = backward extrapolated timeseries for available variables. - RD September 2015, March 2016.
 =#

using My
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

const EXTRA            = 5                              # number of points used for extrapolation
const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if (argc = length(ARGS)) != 2
  print("\nUsage: jjj $(basename(@__FILE__)) cfsr z.listah\n\n")
  exit(1)
end

inner = div(EXTRA - 1, 2)
outer = div(EXTRA + 1, 2)
dats = Array(UTF8String,          TIMS)
data = Array(Float64, PARS, SRCS, TIMS)
mins = [MISS, MISS, 0.0, MISS, -2.0, 0.0]
stdv = [20.0, 40.0, 2.0,  2.0,  2.0, 2.0]

function scale(a::Int64, val::Float64)                                        # define a linearly increasing scale
  if     mins[a] == MISS  return(stdv[a])  end                                # (0 to stdv for val=mins to 3stdv)
  if     mins[a] >=  val  return(    0.0)  end
  if 3 * stdv[a] <=  val  return(stdv[a])  end
  stdv[a] * (val - mins[a]) / (3 * stdv[a] - mins[a])
end

fpa = My.ouvre("$(ARGS[1])/$(ARGS[2])", "r")                                  # loop through the list of locations
files = readlines(fpa) ; close(fpa)                                           # and process each timeseries
for fila in files
  fila = strip(fila)
  if isfile("$(ARGS[1])/$fila.bef") && isfile("$(ARGS[1])/$fila.aft")  continue  end

  fpa = My.ouvre("$(ARGS[1])/$fila", "r", false)
  lines = readlines(fpa) ; close(fpa)
  for (a, line) in enumerate(lines)
    vals = split(line)
    data[SHFX,NOW,a] = float(vals[1])
    data[LHFX,NOW,a] = float(vals[2])
    dats[a]          =       vals[4]
    data[WSPD,NOW,a] = float(vals[9])
    data[AIRT,NOW,a] = float(vals[12])
    data[SSTT,NOW,a] = float(vals[14])
    data[SHUM,NOW,a] = float(vals[15])
  end

  for a = 1:PARS                                                              # perturb both bef and aft symmetrically using
    for b = 1:TIMS                                                            # the same fake (scaled Gaussian) extrapolation
      delta = randn() * scale(a, data[a,NOW,b])
      data[a,BEF,b] = data[a,NOW,b] - delta
      data[a,AFT,b] = data[a,NOW,b] + delta
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


#=
if 0 <= val[:W] < 50 && 880 < val[:SLP] < 1080 && -40 <= val[:AT] < 40 && -40 <= val[:DPT] < 40 && -2 <= val[:SST] < 40
  boundlo = [-333.0 -555.0  0.0 -40.0 -4.0]
  boundhi = [3333.0 5555.0 50.0  40.0 40.0]
=#
