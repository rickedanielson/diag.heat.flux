#=
 = Loop through all analyses and visualize the availability of all
 = variables at the position of interest - RD September 2015, April
 = 2016.
 =#

using My, Winston
const SHFX             = 3                              # identify indecies of all data variables
const LHFX             = 2
const WSPD             = 6
const SHUM             = 4
const SSTT             = 5
const AIRT             = 1
const PARAMS           = 6

const SHFP             = 1                              # position of data variables on input data lines
const LHFP             = 2
const WSPP             = 9
const AIRP             = 12
const SSTP             = 14
const SHUP             = 15

const LOTS             = 1800                           # width of each analysis timeseries
const DAYS             = 3745                           # number of days between 1999-10-01 and 2009-12-31
const MISS             = -9999.0                        # generic missing value

if (argc = length(ARGS)) != 1
  print("\nUsage: jjj $(basename(@__FILE__)) ....45.000...-45.500\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux", "insitu"]
data = Array(Float64, LOTS, DAYS, PARAMS)

for (a, dir) in enumerate(dirs)                                               # and read the daily fluxes
fila = "$dir/$dir$(ARGS[1])"
  fpa = My.ouvre(fila, "r")
  lines = readlines(fpa)
  close(fpa)
  for (b, linb) in enumerate(lines)
    vals = float(split(linb))
    data[a,b,SHFX] = -333 < vals[SHFP] < 3333 ? 1.0 : 0.0
    data[a,b,LHFX] = -333 < vals[LHFP] < 3333 ? 1.0 : 0.0
    data[a,b,WSPD] = -333 < vals[WSPP] < 3333 ? 1.0 : 0.0
    data[a,b,SHUM] = -333 < vals[SHUP] < 3333 ? 1.0 : 0.0
    data[a,b,SSTT] = -333 < vals[SSTP] < 3333 ? 1.0 : 0.0
    data[a,b,AIRT] = -333 < vals[AIRP] < 3333 ? 1.0 : 0.0
  end
end

for a = 1:PARAMS, b = 1:DAYS                                                  # map each dir to a thick line
  data[1601:1800,b,a] = data[9,b,a]
  data[1401:1600,b,a] = data[8,b,a]
  data[1201:1400,b,a] = data[7,b,a]
  data[1001:1200,b,a] = data[6,b,a]
  data[ 801:1000,b,a] = data[5,b,a]
  data[ 601: 800,b,a] = data[4,b,a]
  data[ 401: 600,b,a] = data[3,b,a]
  data[ 201: 400,b,a] = data[2,b,a]
  data[   1: 200,b,a] = data[1,b,a]
end

xlab = Array(UTF8String, 0)                                                   # initialize the date label strings
xpos = Array(     Int64, 0)                                                   # (first date and then first day of
date = "1999-10-01"                                                           #  each subsequent year)
push!(xlab, "1 Oct\n$(date[1:4])") ; push!(xpos, 1)
for a = 2:DAYS
  date = dateadd(date, 1, "dy")
  if date[6:10] == "01-01" && date[1:4] != "2000"
    push!(xlab, date[1:4]) ; push!(xpos, a)
  end
end

Colors.colormap("Blues", 3)
ppp  = Winston.Table(3,2) ; setattr(ppp, "cellpadding", -4.0)
for z = 1:PARAMS
  z == SHFX && (varname = "a) Sensible Heat Flux" ; tpos = (1,1))
  z == LHFX && (varname = "b) Latent Heat Flux"   ; tpos = (1,2))
  z == WSPD && (varname = "c) Wind Speed"         ; tpos = (2,1))
  z == SHUM && (varname = "d) Specific Humidity"  ; tpos = (2,2))
  z == SSTT && (varname = "e) Sea Surface Temp"   ; tpos = (3,1))
  z == AIRT && (varname = "f) Air Temperature"    ; tpos = (3,2))

  tmp = Winston.imagesc(data[:,:,z])
  setattr(tmp,    "title",               varname) ; setattr(tmp,    "aspect_ratio",           0.35)
  setattr(tmp.x1, "ticks",                  xpos)#; setattr(tmp.x2, "draw_nothing",           true)
  setattr(tmp.x1, "tickdir",                   1)#; setattr(tmp.x2, "tickdir",                   1)
  setattr(tmp.x1, "ticklabels",             xlab) ; setattr(tmp.x2, "draw_ticks",            false)
  setattr(tmp.x1, "draw_subticks",         false) ; setattr(tmp.x2, "draw_subticks",         false)
  setattr(tmp.y1, "ticks", collect(100:200:1700))#; setattr(tmp.y2, "draw_nothing",           true)
  setattr(tmp.y1, "tickdir",                   1)#; setattr(tmp.y2, "tickdir",                   1)
  setattr(tmp.y1, "ticklabels",             dirs) ; setattr(tmp.y2, "draw_ticks",            false)
  setattr(tmp.y1, "draw_subticks",         false) ; setattr(tmp.y2, "draw_subticks",         false)
  ppp[tpos...] = Winston.add(tmp)

# @show getattr(tmp, :aspect_ratio)
  tpos[1] <= 2 && setattr(tmp.x1, :ticklabels_style, Dict{Symbol, Any}(:fontsize => 3, :color => "transparent"))
  tpos[2] == 1 && setattr(tmp.y1, :ticklabels_style, Dict{Symbol, Any}(:fontsize => 3, :color => "black"))
  tpos[2] == 2 && setattr(tmp.y1, :ticklabels_style, Dict{Symbol, Any}(:fontsize => 3, :color => "transparent"))
end

xyzzy = "plot.avail$(ARGS[1]).png"
print("writing $xyzzy\n")
Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
exit(0)
