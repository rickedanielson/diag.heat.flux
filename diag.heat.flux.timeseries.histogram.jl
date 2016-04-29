#=
 = Loop through the timeseries of all analyses and bin the values of all available
 = variables.  Where one analysis is unavailable, all analyses are skipped - RD April 2016.
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

if size(ARGS) != (1,) && size(ARGS) != (2,)
  print("\nUsage: jjj $(basename(@__FILE__)) z.list [30]\n\n")
  exit(1)
end
maxfiles = 9e9 ; size(ARGS) == (3,) && (maxfiles = parse(Int64, ARGS[3]))

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
dirn = length(dirs)
CFSR = try  findin(dirs, [  "cfsr"])[1]  catch  0  end
JOFU = try  findin(dirs, ["jofuro"])[1]  catch  0  end

shfi = 1.0 ; shfs = collect( -600.0 : shfi : 1500.0) ; shfn = zeros(length(shfs), length(dirs))
lhfi = 1.0 ; lhfs = collect(-1200.0 : lhfi : 2500.0) ; lhfn = zeros(length(lhfs), length(dirs))
wspi = 0.1 ; wsps = collect(  -40.0 : wspi :   80.0) ; wspn = zeros(length(wsps), length(dirs))
shui = 0.1 ; shus = collect(  -20.0 : shui :   50.0) ; shun = zeros(length(shus), length(dirs))
ssti = 0.1 ; ssts = collect(  -20.0 : ssti :   50.0) ; sstn = zeros(length(ssts), length(dirs))
airi = 0.2 ; airs = collect(  -40.0 : airi :   80.0) ; airn = zeros(length(airs), length(dirs))

function count(bound::Array{Float64,1}, grid::Array{Float64,2}, now::Array{Float64,1})
  flag = false
  for a = 1:dirn
    (now[a] < -3333 || now[a] > 3333) && (flag = true)
  end
  flag && return

  for a = 1:dirn
    delnow, indnow = findmin(abs(bound - now[a])) ; bound[indnow] > now[a] && indnow > 1 && (indnow -= 1)
    grid[indnow,a] += 1
  end
end                                                                           # (grid boundaries refer to lower limits)

nfile = 0                                                                     # loop through the list of locations and
fpn  = Array(IOStream, dirn)                                                  # grid the three timeseries, where valid
data = Array(Float64,  dirn, PARAMS)
fpa = My.ouvre(dirs[1] * "/" * ARGS[1], "r")
files = readlines(fpa) ; close(fpa)
for (a, fila) in enumerate(files)
  (z, tail) = split(strip(fila), dirs[1])
  for b = 1:dirn
    fpn[b] = My.ouvre("$(dirs[b])/$(dirs[b])$tail", "r")
  end

  for b = 1:TIMS
    for c = 1:dirn
      line = readline(fpn[c]) ; vals = split(line)
      data[c,SHFX] = float(vals[ 1])
      data[c,LHFX] = float(vals[ 2])
      data[c,WSPD] = float(vals[ 9])
      data[c,AIRT] = float(vals[12])
      data[c,SSTT] = float(vals[14])
      data[c,SHUM] = float(vals[15])
    end

    if CFSR > 0  data[CFSR,LHFX]                   = 3333  end                # set expected missing values to be
    if JOFU > 0  data[JOFU,AIRT] = data[JOFU,SSTT] = 3333  end                # outside the plotting range
    count(shfs, shfn, data[:,SHFX])
    count(lhfs, lhfn, data[:,LHFX])
    count(wsps, wspn, data[:,WSPD])
    count(airs, airn, data[:,AIRT])
    count(ssts, sstn, data[:,SSTT])
    count(shus, shun, data[:,SHUM])
  end

  for b = 1:dirn
    close(fpn[b])
  end
  nfile += 1 ; if nfile >= maxfiles  break  end
end
print("read $nfile files\n")

function store(bound::Array{Float64,1}, grid::Array{Float64,2}, pname::UTF8String)
  fname = "histogr." * pname * ".dat"
  fpa = My.ouvre(fname, "w")
  for (a, vala) in enumerate(bound)
    @printf(fpa, "%15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f\n",
      grid[a,1], grid[a,2], grid[a,3], grid[a,4], grid[a,5], grid[a,6], grid[a,7], grid[a,8])
  end
  close(fpa)
end

store(shfs, shfn, utf8("shfx"))
store(lhfs, lhfn, utf8("lhfx"))
store(wsps, wspn, utf8("wspd"))
store(airs, airn, utf8("airt"))
store(ssts, sstn, utf8("sstt"))
store(shus, shun, utf8("shum"))
exit(0)


#=
    if float(valb[ 1]) < 50 && (float(vala[ 1]) > 300 || float(valc[ 1]) > 300)
      @show vala ; @show valb ; @show valc  end
    @printf(fpa, "%15.8f\n", grid[a,1])
=#
