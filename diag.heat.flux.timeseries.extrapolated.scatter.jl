#=
 = Loop through timeseries of a given analysis and plot the corresponding forward and
 = backward extrapolated timeseries, for all available variables, relative to actual
 = (uninterpolated) values.  Note that BEF refers to an interpolation using analysis
 = data from before the extrapolation; AFT extrapolations use analysis data afterward
 = - RD April 2016.
 =#

using My, Winston
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

if size(ARGS) != (2,)
  print("\nUsage: jjj $(basename(@__FILE__)) cfsr z.list\n\n")
  exit(1)
end

data = Array(Float64, PARAMS, SRCS, TIMS)

fpa = My.ouvre("$(ARGS[1])/$(ARGS[2])", "r")                                  # loop through the list of locations
files = readlines(fpa) ; close(fpa)                                           # and read the three timeseries
for fila in files
  fila = strip(fila)
  fpa = My.ouvre("$(ARGS[1])/$fila.bef", "r", false)
  fpb = My.ouvre("$(ARGS[1])/$fila",     "r", false)
  fpc = My.ouvre("$(ARGS[1])/$fila.aft", "r", false)

  lines = readlines(fpa) ; close(fpa)
  for (a, line) in enumerate(lines)
    vals = split(line)
    data[SHFX,BEF,a] = float(vals[1])
    data[LHFX,BEF,a] = float(vals[2])
    data[WSPD,BEF,a] = float(vals[9])
    data[AIRT,BEF,a] = float(vals[12])
    data[SSTT,BEF,a] = float(vals[14])
    data[SHUM,BEF,a] = float(vals[15])
  end

  lines = readlines(fpb) ; close(fpb)
  for (a, line) in enumerate(lines)
    vals = split(line)
    data[SHFX,NOW,a] = float(vals[1])
    data[LHFX,NOW,a] = float(vals[2])
    data[WSPD,NOW,a] = float(vals[9])
    data[AIRT,NOW,a] = float(vals[12])
    data[SSTT,NOW,a] = float(vals[14])
    data[SHUM,NOW,a] = float(vals[15])
  end

  lines = readlines(fpc) ; close(fpc)
  for (a, line) in enumerate(lines)
    vals = split(line)
    data[SHFX,AFT,a] = float(vals[1])
    data[LHFX,AFT,a] = float(vals[2])
    data[WSPD,AFT,a] = float(vals[9])
    data[AIRT,AFT,a] = float(vals[12])
    data[SSTT,AFT,a] = float(vals[14])
    data[SHUM,AFT,a] = float(vals[15])
  end
end

keep = 1                                                                      # collapse the timeseries, excluding any
for a = 1:TIMS                                                                # data for which one variable is poorly defined
  flag = true
  for b = 1:SRCS
    for c = 1:PARAMS
      if ((ARGS[1] ==   "cfsr" &&               c != LHFX)   ||
          (ARGS[1] == "jofuro" && (c != SSTT || c != AIRT))) &&
         data[c,b,a] <= -3333 || data[c,b,a] >= 3333  flag = false  end
    end
  end

  if flag
    for b = 1:SRCS 
      for c = 1:PARAMS
        data[c,b,keep] = data[c,b,a]
      end
    end 
    keep += 1
  end
end
keep -= 1
print("kept $keep (out of $TIMS) times as valid for all variables\n")

ppp = Winston.Table(3,2) ; setattr(ppp, "cellpadding", -0.5)                  # and then create the scatterplots
for z = 1:PARAMS
  if ((ARGS[1] ==   "cfsr" &&               z != LHFX)   ||
      (ARGS[1] == "jofuro" && (z != SSTT || z != AIRT)))
    z == SHFX && (varname = "a) Sensible Heat Flux (Wm^{-2})" ; ymin = -100 ; ymax = 250 ; tpos = (1,1))
    z == LHFX && (varname = "b) Latent Heat Flux (Wm^{-2})"   ; ymin = -250 ; ymax = 750 ; tpos = (1,2))
    z == WSPD && (varname = "c) Wind Speed (ms^{-1})"         ; ymin =  -10 ; ymax =  30 ; tpos = (2,1))
    z == SHUM && (varname = "d) Specific Humidity (g/kg)"     ; ymin =    5 ; ymax =  25 ; tpos = (2,2))
    z == SSTT && (varname = "e) Sea Surface Temp (^{o}C)"     ; ymin =   20 ; ymax =  35 ; tpos = (3,1))
    z == AIRT && (varname = "f) Air Temperature (^{o}C)"      ; ymin =   10 ; ymax =  35 ; tpos = (3,2))

    xmin = min(data[z,NOW,1:keep]...) - 1
    xmax = max(data[z,NOW,1:keep]...) + 1
    ymin = min(data[z,BEF,1:keep]...) - 1
    ymax = max(data[z,BEF,1:keep]...) + 1

    tmp = Winston.FramedPlot(title="$varname", xrange = (xmin,xmax), yrange = (ymin,ymax))
    ppp[tpos...] = Winston.add(tmp)

    ump = Winston.Points(data[z,NOW,1:keep], data[z,BEF,1:keep], kind = "filled circle", "color", parse(Winston.Colorant,   "red"), symbolsize = 0.1)
          setattr(ump, label = "before")
          Winston.add(ppp[tpos...], ump)
    vmp = Winston.Points(data[z,NOW,1:keep], data[z,AFT,1:keep], kind =        "circle", "color", parse(Winston.Colorant, "green"), symbolsize = 0.1)
          setattr(vmp, label = "after")
          Winston.add(ppp[tpos...], vmp)
    tmp = Winston.Legend(0.05, 0.85, Any[ump, vmp])
          Winston.add(ppp[tpos...], tmp)

    (intbef, slobef) = linreg(vec(data[z,NOW,1:keep]), vec(data[z,BEF,1:keep]))
    tmp = Winston.Slope(slobef, (0, intbef), kind = "solid", "linewidth", 5, "color", parse(Winston.Colorant,   "red"))
          Winston.add(ppp[tpos...], tmp)
    (intaft, sloaft) = linreg(vec(data[z,NOW,1:keep]), vec(data[z,AFT,1:keep]))
    tmp = Winston.Slope(sloaft, (0, intaft), kind = "solid", "linewidth", 5, "color", parse(Winston.Colorant, "green"))
          Winston.add(ppp[tpos...], tmp)
    tmp = Winston.Slope(     1, (0,      0), kind = "solid")
          Winston.add(ppp[tpos...], tmp)
  end
end

xyzzy = ARGS[1] * "scatter.png"
print("writing $xyzzy\n")
Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
exit(0)


#=
          title="$varname Spectra (dB)", xlog = true,
          xlabel="Timescale (days)", xrange = (1/1000,1/2), yrange = (ymin,ymax))
          xlog = true, xrange = (1/1000,1/2), yrange = (ymin,ymax))
  setattr(tmp.x1, "ticks",          xposa) ; setattr(tmp.x2, "ticks",          xposb) ; setattr(tmp.y1, "ticks",          yposa)
  setattr(tmp.x1, "tickdir",            1) ; setattr(tmp.x2, "tickdir",           -1) ; setattr(tmp.y1, "tickdir",            1)
  setattr(tmp.x1, "ticklabels_offset",  0) ; setattr(tmp.x2, "ticklabels_offset", -7) ; setattr(tmp.y1, "ticklabels_offset",  0)
  setattr(tmp.x1, "ticklabels",     xlaba) ; setattr(tmp.x2, "ticklabels",     xlabb) ; setattr(tmp.y1, "ticklabels",     ylaba)
  setattr(tmp.x1, "draw_subticks",  false) ; setattr(tmp.x2, "draw_subticks",   true) ; setattr(tmp.y1, "draw_subticks",   true)
  tpos[1] <= 2 && setattr(tmp.x1, :ticklabels_style, Dict{Symbol, Any}(:color => "transparent"))
  tpos[1] >= 2 && setattr(tmp.x2, :ticklabels_style, Dict{Symbol, Any}(:color => "transparent"))
  tpos[2] == 1 && setattr(tmp.y1, :ticklabels_style, Dict{Symbol, Any}(:color => "black"))
  tpos[2] == 2 && setattr(tmp.y1, :ticklabels_style, Dict{Symbol, Any}(:color => "transparent"))

  ump = Array(Any, 8)
  cols = [  "red",  "blue", "green", "orange",    "red",   "blue",  "green", "orange"]
  kynd = ["solid", "solid", "solid",  "solid", "dashed", "dashed", "dashed", "dashed"]
=#
