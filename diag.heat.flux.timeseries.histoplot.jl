#=
 = Loop through all analyses and plot the binned sums
 = of all available variables - RD April, October 2016.
 =#

using My, Winston
const SHFX             = 1                              # indecies of all data variables
const LHFX             = 2
const WSPD             = 3
const AIRT             = 4
const SSTT             = 5
const SHUM             = 6
const PARAMS           = 6

const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if (argc = length(ARGS)) != 0
  print("\nUsage: jjj $(basename(@__FILE__))\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux", "ensemble", "bestest"]
dirn = length(dirs)

shfi = 1.0 ; shfs = collect( -600.0 : shfi : 1500.0) ; shfn = zeros(length(shfs), length(dirs))
lhfi = 1.0 ; lhfs = collect(-1200.0 : lhfi : 2500.0) ; lhfn = zeros(length(lhfs), length(dirs))
wspi = 0.1 ; wsps = collect(  -40.0 : wspi :   80.0) ; wspn = zeros(length(wsps), length(dirs))
shui = 0.1 ; shus = collect(  -20.0 : shui :   50.0) ; shun = zeros(length(shus), length(dirs))
ssti = 0.1 ; ssts = collect(  -20.0 : ssti :   50.0) ; sstn = zeros(length(ssts), length(dirs))
airi = 0.2 ; airs = collect(  -40.0 : airi :   80.0) ; airn = zeros(length(airs), length(dirs))

function restore(bound::Array{Float64,1}, grid::Array{Float64,2}, pname::UTF8String)
  fname = "histogr." * pname * ".dat"
  fpa = My.ouvre(fname, "r")
  for (a, vala) in enumerate(bound)
    line = readline(fpa)
    (grid[a,1], grid[a,2], grid[a,3], grid[a,4], grid[a,5], grid[a,6], grid[a,7], grid[a,8], grid[a,9], grid[a,10]) = float(split(line))
  end
  close(fpa)
end

restore(shfs, shfn, utf8("shfx"))
restore(lhfs, lhfn, utf8("lhfx"))
restore(wsps, wspn, utf8("wspd"))
restore(airs, airn, utf8("airt"))
restore(ssts, sstn, utf8("sstt"))
restore(shus, shun, utf8("shum"))

ppp = Winston.Table(3,2) ; setattr(ppp, "cellpadding", -0.5)                  # and then create the plots
for z = 1:PARAMS
  z == SHFX && (varname = "a) Sensible Heat Flux (Wm^{-2})" ; bound = shfs ; grid = shfn ; tpos = (1,1) ; delt = shfi)
  z == LHFX && (varname = "b) Latent Heat Flux (Wm^{-2})"   ; bound = lhfs ; grid = lhfn ; tpos = (1,2) ; delt = lhfi)
  z == WSPD && (varname = "c) Wind Speed (ms^{-1})"         ; bound = wsps ; grid = wspn ; tpos = (2,1) ; delt = wspi)
  z == SHUM && (varname = "d) Specific Humidity (g/kg)"     ; bound = shus ; grid = shun ; tpos = (2,2) ; delt = shui)
  z == SSTT && (varname = "e) Sea Surface Temp (^{o}C)"     ; bound = ssts ; grid = sstn ; tpos = (3,1) ; delt = ssti)
  z == AIRT && (varname = "f) Air Temperature (^{o}C)"      ; bound = airs ; grid = airn ; tpos = (3,2) ; delt = airi)

  bound += 0.5 * delt                                                         # make bound refer to grid midpoints
  z == SHFX && (xmin = -25 ; xmax =   50 ; ymin = 0 ; ymax =1200000)          # and locate the plot limits
  z == LHFX && (xmin = -60 ; xmax =  340 ; ymin = 0 ; ymax = 170000)
  z == WSPD && (xmin =  -1 ; xmax =   20 ; ymin = 0 ; ymax = 300000)
  z == SHUM && (xmin =   0 ; xmax =   23 ; ymin = 0 ; ymax = 250000)
  z == SSTT && (xmin =  -2 ; xmax =   33 ; ymin = 0 ; ymax = 230000)
  z == AIRT && (xmin =  -4 ; xmax =   32 ; ymin = 0 ; ymax = 500000)

  ump = Array(Any, dirn)
  cols = [  "red",  "blue", "green", "orange",    "red",   "blue",  "green", "orange"]
  kynd = ["solid", "solid", "solid",  "solid", "dashed", "dashed", "dashed", "dashed"]

  tmp = Winston.FramedPlot(title="$varname", xrange = (xmin,xmax), yrange = (ymin,ymax))
  ppp[tpos...] = Winston.add(tmp)

  for a = 1:dirn
    ump[a] = Winston.Curve(bound, grid[:,a], "color", parse(Winston.Colorant, cols[a]))
             style(ump[a], kind = kynd[a])
             setattr(ump[a], label = dirs[a])
             Winston.add(ppp[tpos...], ump[a])
  end
  if z == SSTT
    tmp = Winston.Legend(.05, .92, Any[ump[1], ump[2], ump[3], ump[4]])
          Winston.add(ppp[tpos...], tmp)
    tmp = Winston.Legend(.30, .92, Any[ump[5], ump[6], ump[7], ump[8]])
          Winston.add(ppp[tpos...], tmp)
  end
end

xyzzy = "histogr_z.list.png"
print("writing $xyzzy\n")
Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
exit(0)


# if ( ARGS[1] ==  "erainterim" || ARGS[1] ==       "hoaps" || ARGS[1] == "ifremerflux" ||
#      ARGS[1] ==       "merra" || ARGS[1] ==      "oaflux" || ARGS[1] ==     "seaflux" ||
#     (ARGS[1] ==        "cfsr" &&              z != LHFX)   ||
#     (ARGS[1] ==      "jofuro" && z != SSTT && z != AIRT))
