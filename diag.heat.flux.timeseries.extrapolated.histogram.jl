#=
 = Loop through the timeseries of all analyses and grid the corresponding forward and
 = backward extrapolated timeseries of all available variables, relative to the actual
 = (uninterpolated) values.  Note that BEF refers to an interpolation using analysis
 = data from before the extrapolation; AFT extrapolations use analysis data afterward.
 = Where one analysis is unavailable, all analyses are skipped - RD April 2016.
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

if (argc = length(ARGS)) != 1 && argc != 2
  print("\nUsage: jjj $(basename(@__FILE__)) z.list [30]\n\n")
  exit(1)
end
maxfiles = 9e9 ; argc == 2 && (maxfiles = parse(Int64, ARGS[2]))

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
dirn = length(dirs)
CFSR = try  findin(dirs, [  "cfsr"])[1]  catch  0  end
JOFU = try  findin(dirs, ["jofuro"])[1]  catch  0  end

shfi = 1.0 ; shfs = collect( -600.0 : shfi : 1500.0) ; shfn = zeros(length(shfs), length(shfs), length(dirs))
lhfi = 1.0 ; lhfs = collect(-1200.0 : lhfi : 2500.0) ; lhfn = zeros(length(lhfs), length(lhfs), length(dirs))
wspi = 0.1 ; wsps = collect(  -40.0 : wspi :   80.0) ; wspn = zeros(length(wsps), length(wsps), length(dirs))
shui = 0.1 ; shus = collect(  -20.0 : shui :   50.0) ; shun = zeros(length(shus), length(shus), length(dirs))
ssti = 0.1 ; ssts = collect(  -20.0 : ssti :   50.0) ; sstn = zeros(length(ssts), length(ssts), length(dirs))
airi = 0.2 ; airs = collect(  -40.0 : airi :   80.0) ; airn = zeros(length(airs), length(airs), length(dirs))

function count(bound::Array{Float64,1}, grid::Array{Float64,3}, bef::Array{Float64,1}, now::Array{Float64,1}, aft::Array{Float64,1})
  flag = false
  for a = 1:dirn
    (bef[a] < -3333 || now[a] < -3333 || aft[a] < -3333 ||
     bef[a] >  3333 || now[a] >  3333 || aft[a] >  3333) && (flag = true)
  end
  flag && return

  for a = 1:dirn
    delbef, indbef = findmin(abs(bound - bef[a])) ; bound[indbef] > bef[a] && indbef > 1 && (indbef -= 1)
    delnow, indnow = findmin(abs(bound - now[a])) ; bound[indnow] > now[a] && indnow > 1 && (indnow -= 1)
    delaft, indaft = findmin(abs(bound - aft[a])) ; bound[indaft] > aft[a] && indaft > 1 && (indaft -= 1)
    grid[indbef,indnow,a] += 1 ; grid[indaft,indnow,a] += 1
  end
end                                                                           # (grid boundaries refer to lower limits)

nfile = 0                                                                     # loop through the list of locations and
fpna = Array(IOStream, dirn)                                                  # grid the three timeseries, where valid
fpnb = Array(IOStream, dirn)
fpnc = Array(IOStream, dirn)
data = Array(Float64,  dirn, PARAMS, SRCS)
fpa = My.ouvre(dirs[1] * "/" * ARGS[1], "r")
files = readlines(fpa) ; close(fpa)
for (a, fila) in enumerate(files)
  (z, tail) = split(strip(fila), dirs[1])
  for b = 1:dirn
    fpna[b] = My.ouvre("$(dirs[b])/$(dirs[b])$tail.bet", "r", false)
    fpnb[b] = My.ouvre("$(dirs[b])/$(dirs[b])$tail",     "r")
    fpnc[b] = My.ouvre("$(dirs[b])/$(dirs[b])$tail.aff", "r", false)
  end

  for b = 1:TIMS
    for c = 1:dirn
      line = readline(fpna[c]) ; vala = split(line)
      line = readline(fpnb[c]) ; valb = split(line)
      line = readline(fpnc[c]) ; valc = split(line)
      data[c,SHFX,BEF] = float(vala[ 1]) ; data[c,SHFX,NOW] = float(valb[ 1]) ; data[c,SHFX,AFT] = float(valc[ 1])
      data[c,LHFX,BEF] = float(vala[ 2]) ; data[c,LHFX,NOW] = float(valb[ 2]) ; data[c,LHFX,AFT] = float(valc[ 2])
      data[c,WSPD,BEF] = float(vala[ 9]) ; data[c,WSPD,NOW] = float(valb[ 9]) ; data[c,WSPD,AFT] = float(valc[ 9])
      data[c,AIRT,BEF] = float(vala[12]) ; data[c,AIRT,NOW] = float(valb[12]) ; data[c,AIRT,AFT] = float(valc[12])
      data[c,SSTT,BEF] = float(vala[14]) ; data[c,SSTT,NOW] = float(valb[14]) ; data[c,SSTT,AFT] = float(valc[14])
      data[c,SHUM,BEF] = float(vala[15]) ; data[c,SHUM,NOW] = float(valb[15]) ; data[c,SHUM,AFT] = float(valc[15])
    end

    if CFSR > 0  data[CFSR,LHFX,:]                     = [3333 3333 3333] end  # set expected missing values to be
    if JOFU > 0  data[JOFU,AIRT,:] = data[JOFU,SSTT,:] = [3333 3333 3333] end  # outside the plotting range
    count(shfs, shfn, data[:,SHFX,BEF], data[:,SHFX,NOW], data[:,SHFX,AFT])
    count(lhfs, lhfn, data[:,LHFX,BEF], data[:,LHFX,NOW], data[:,LHFX,AFT])
    count(wsps, wspn, data[:,WSPD,BEF], data[:,WSPD,NOW], data[:,WSPD,AFT])
    count(airs, airn, data[:,AIRT,BEF], data[:,AIRT,NOW], data[:,AIRT,AFT])
    count(ssts, sstn, data[:,SSTT,BEF], data[:,SSTT,NOW], data[:,SSTT,AFT])
    count(shus, shun, data[:,SHUM,BEF], data[:,SHUM,NOW], data[:,SHUM,AFT])
  end

  for b = 1:dirn
    close(fpna[b])
    close(fpnb[b])
    close(fpnc[b])
  end
  nfile += 1 ; if nfile >= maxfiles  break  end
end
print("read $nfile files\n")

function store(bound::Array{Float64,1}, grid::Array{Float64,3}, pname::UTF8String)
  fname = "extrapolated.histogr." * pname * ".dat"
  fpa = My.ouvre(fname, "w")
  for (a, vala) in enumerate(bound)
    for (b, valb) in enumerate(bound)
      @printf(fpa, "%15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f %15.8f\n",
        grid[b,a,1], grid[b,a,2], grid[b,a,3], grid[b,a,4], grid[b,a,5], grid[b,a,6], grid[b,a,7], grid[b,a,8])
    end
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
