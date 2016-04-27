#=
 = Loop through timeseries of a given analysis and grid the corresponding forward and
 = backward extrapolated timeseries, for all available variables, relative to actual
 = (uninterpolated) values.  Note that BEF refers to an interpolation using analysis
 = data from before the extrapolation; AFT extrapolations use analysis data afterward
 = - RD April 2016.
 =#

using My
const SHFX             = 1                              # indecies of all data variables
const LHFX             = 2
const WSPD             = 3
const AIRT             = 4
const SSTT             = 5
const SHUM             = 6
const PARAMS           = 6

const BEF              = 1                              # indecies of the source of extrapolations
const NOW              = 2
const AFT              = 3
const SRCS             = 3

const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (2,) && size(ARGS) != (3,)
  print("\nUsage: jjj $(basename(@__FILE__)) cfsr z.list [30]\n\n")
  exit(1)
end
maxfiles = 9e9 ; size(ARGS) == (3,) && (maxfiles = parse(Int64, ARGS[3]))

shfi = 1.00 ; shfs = collect( -600.0 : shfi : 1500.0) ; shfn = zeros(length(shfs), length(shfs))
lhfi = 1.00 ; lhfs = collect(-1200.0 : lhfi : 2500.0) ; lhfn = zeros(length(lhfs), length(lhfs))
wspi = 0.05 ; wsps = collect(  -40.0 : wspi :   80.0) ; wspn = zeros(length(wsps), length(wsps))
shui = 0.05 ; shus = collect(  -20.0 : shui :   50.0) ; shun = zeros(length(shus), length(shus))
ssti = 0.05 ; ssts = collect(  -20.0 : ssti :   50.0) ; sstn = zeros(length(ssts), length(ssts))
airi = 0.10 ; airs = collect(  -40.0 : airi :   80.0) ; airn = zeros(length(airs), length(airs))

function count(bound::Array{Float64,1}, grid::Array{Float64,2}, bef::Float64, now::Float64, aft::Float64)
  (bef < -3333 || now < -3333 || aft < -3333 || bef > 3333 || now > 3333 || aft > 3333) && return
  delbef, indbef = findmin(abs(bound - bef)) ; bound[indbef] > bef && indbef > 1 && (indbef -= 1)
  delnow, indnow = findmin(abs(bound - now)) ; bound[indnow] > now && indnow > 1 && (indnow -= 1)
  delaft, indaft = findmin(abs(bound - aft)) ; bound[indaft] > aft && indaft > 1 && (indaft -= 1)
  grid[indbef,indnow] += 1 ; grid[indaft,indnow] += 1
end                                                                           # (grid boundaries refer to lower limits)

nfile = 0
fpa = My.ouvre("$(ARGS[1])/$(ARGS[2])", "r")                                  # loop through the list of locations and
files = readlines(fpa) ; close(fpa)                                           # grid the three timeseries, where valid
for (a, fila) in enumerate(files)
  fila = strip(fila)
  fpa = My.ouvre("$(ARGS[1])/$fila.bef", "r", false)
  fpb = My.ouvre("$(ARGS[1])/$fila",     "r")
  fpc = My.ouvre("$(ARGS[1])/$fila.aft", "r", false)
  for b = 1:TIMS
    line = readline(fpa) ; vala = split(line)
    line = readline(fpb) ; valb = split(line)
    line = readline(fpc) ; valc = split(line)
                           count(shfs, shfn, float(vala[ 1]), float(valb[ 1]), float(valc[ 1]))
    ARGS[1] !=   "cfsr" && count(lhfs, lhfn, float(vala[ 2]), float(valb[ 2]), float(valc[ 2]))
                           count(wsps, wspn, float(vala[ 9]), float(valb[ 9]), float(valc[ 9]))
    ARGS[1] != "jofuro" && count(airs, airn, float(vala[12]), float(valb[12]), float(valc[12]))
    ARGS[1] != "jofuro" && count(ssts, sstn, float(vala[14]), float(valb[14]), float(valc[14]))
                           count(shus, shun, float(vala[15]), float(valb[15]), float(valc[15]))
  end
  close(fpa)
  close(fpb)
  close(fpc)
  nfile += 1 ; if nfile >= maxfiles  break  end
end
print("read $nfile files\n")

function store(bound::Array{Float64,1}, grid::Array{Float64,2}, fname::UTF8String)
  fpa = My.ouvre(fname, "w")
  for (a, vala) in enumerate(bound)
    for (b, valb) in enumerate(bound)
      @printf(fpa, "%15.8f\n", float(grid[b,a]))
    end
  end
  close(fpa)
end

store(shfs, shfn, ARGS[1] * "_" * ARGS[2] * ".shfx.dat")
store(lhfs, lhfn, ARGS[1] * "_" * ARGS[2] * ".lhfx.dat")
store(wsps, wspn, ARGS[1] * "_" * ARGS[2] * ".wspd.dat")
store(airs, airn, ARGS[1] * "_" * ARGS[2] * ".airt.dat")
store(ssts, sstn, ARGS[1] * "_" * ARGS[2] * ".sstt.dat")
store(shus, shun, ARGS[1] * "_" * ARGS[2] * ".shum.dat")
exit(0)
