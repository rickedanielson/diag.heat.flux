#=
 = Loop through timeseries of a given analysis and bin
 = the values of all available variables - RD April 2016.
 =#

using My
const SHFX             = 1                              # indecies of all data variables
const LHFX             = 2
const WSPD             = 3
const AIRT             = 4
const SSTT             = 5
const SHUM             = 6
const PARAMS           = 6

const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (2,) && size(ARGS) != (3,)
  print("\nUsage: jjj $(basename(@__FILE__)) cfsr z.list [30]\n\n")
  exit(1)
end
maxfiles = 9e9 ; size(ARGS) == (3,) && (maxfiles = parse(Int64, ARGS[3]))

shfi = 1.00 ; shfs = collect( -600.0 : shfi : 1500.0) ; shfn = zeros(length(shfs))
lhfi = 1.00 ; lhfs = collect(-1200.0 : lhfi : 2500.0) ; lhfn = zeros(length(lhfs))
wspi = 0.05 ; wsps = collect(  -40.0 : wspi :   80.0) ; wspn = zeros(length(wsps))
shui = 0.05 ; shus = collect(  -20.0 : shui :   50.0) ; shun = zeros(length(shus))
ssti = 0.05 ; ssts = collect(  -20.0 : ssti :   50.0) ; sstn = zeros(length(ssts))
airi = 0.10 ; airs = collect(  -40.0 : airi :   80.0) ; airn = zeros(length(airs))

function count(bound::Array{Float64,1}, grid::Array{Float64,1}, now::Float64)
  (now < -3333 || now > 3333) && return
  delnow, indnow = findmin(abs(bound - now)) ; bound[indnow] > now && indnow > 1 && (indnow -= 1)
  grid[indnow] += 1
end                                                                           # (grid boundaries refer to lower limits)

nfile = 0
fpa = My.ouvre("$(ARGS[1])/$(ARGS[2])", "r")                                  # loop through the list of locations and
files = readlines(fpa) ; close(fpa)                                           # grid the three timeseries, where valid
for (a, fila) in enumerate(files)
  fila = strip(fila)
  fpa = My.ouvre("$(ARGS[1])/$fila", "r")
  for b = 1:TIMS
    line = readline(fpa) ; vala = split(line)
                           count(shfs, shfn, float(vala[ 1]))
    ARGS[1] !=   "cfsr" && count(lhfs, lhfn, float(vala[ 2]))
                           count(wsps, wspn, float(vala[ 9]))
    ARGS[1] != "jofuro" && count(airs, airn, float(vala[12]))
    ARGS[1] != "jofuro" && count(ssts, sstn, float(vala[14]))
                           count(shus, shun, float(vala[15]))
#   if float(valb[ 1]) < 50 && (float(vala[ 1]) > 300 || float(valc[ 1]) > 300)
#     @show vala ; @show valb ; @show valc
#   end
  end
  close(fpa)
  nfile += 1 ; if nfile >= maxfiles  break  end
end
print("read $nfile files\n")

function store(bound::Array{Float64,1}, grid::Array{Float64,1}, fname::UTF8String)
  fpa = My.ouvre(fname, "w")
  for (a, vala) in enumerate(bound)
    @printf(fpa, "%15.8f\n", float(grid[a]))
  end
  close(fpa)
end

store(shfs, shfn, "histogr." * ARGS[1] * "_" * ARGS[2] * ".shfx.dat")
store(lhfs, lhfn, "histogr." * ARGS[1] * "_" * ARGS[2] * ".lhfx.dat")
store(wsps, wspn, "histogr." * ARGS[1] * "_" * ARGS[2] * ".wspd.dat")
store(airs, airn, "histogr." * ARGS[1] * "_" * ARGS[2] * ".airt.dat")
store(ssts, sstn, "histogr." * ARGS[1] * "_" * ARGS[2] * ".sstt.dat")
store(shus, shun, "histogr." * ARGS[1] * "_" * ARGS[2] * ".shum.dat")
exit(0)
