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

shfi = 1.00 ; shfs = collect( -250.0 : shfi :  500.0) ; shfn = zeros(length(shfs), length(shfs))
lhfi = 1.00 ; lhfs = collect( -500.0 : lhfi : 2000.0) ; lhfn = zeros(length(lhfs), length(lhfs))
wspi = 0.10 ; wsps = collect(  -50.0 : wspi :  100.0) ; wspn = zeros(length(wsps), length(wsps))
shui = 0.05 ; shus = collect(   -5.0 : shui :   30.0) ; shun = zeros(length(shus), length(shus))
ssti = 0.05 ; ssts = collect(   -5.0 : ssti :   40.0) ; sstn = zeros(length(ssts), length(ssts))
airi = 0.10 ; airs = collect(  -50.0 : airi :  100.0) ; airn = zeros(length(airs), length(airs))

function count(bound::Array{Float64,1}, grid::Array{Float64,2}, bef::Float64, now::Float64, aft::Float64)
  (bef < -3333 || now < -3333 || aft < -3333 || bef > 3333 || now > 3333 || aft > 3333) && return
  delbef, indbef = findmin(abs(bound - bef)) ; bound[indbef] > bef && indbef > 1 && (indbef -= 1)
  delnow, indnow = findmin(abs(bound - now)) ; bound[indnow] > now && indnow > 1 && (indnow -= 1)
  delaft, indaft = findmin(abs(bound - aft)) ; bound[indaft] > aft && indaft > 1 && (indaft -= 1)
  grid[indbef,indnow] += 1 ; grid[indaft,indnow] += 1
end                                                                           # (grid boundaries refer to lower limits)

fpa = My.ouvre("$(ARGS[1])/$(ARGS[2])", "r")                                  # loop through the list of locations and
files = readlines(fpa) ; close(fpa)                                           # grid the three timeseries, where valid
for fila in files
  fila = strip(fila)
  fpa = My.ouvre("$(ARGS[1])/$fila.bef", "r", false)
  fpb = My.ouvre("$(ARGS[1])/$fila",     "r")
  fpc = My.ouvre("$(ARGS[1])/$fila.aft", "r", false)
  for a = 1:TIMS
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
end

function point(bound::Array{Float64,1}, grid::Array{Float64,2})
  xpts = Array(Float64, 0)
  ypts = Array(Float64, 0)
  zpts = Array(Float64, 0)
  for (a, vala) in enumerate(bound)
    for (b, valb) in enumerate(bound)
      if grid[b,a] > 0
        push!(xpts, vala)
        push!(ypts, valb)
        push!(zpts, float(grid[b,a]))
      end
    end
  end
  return(xpts, ypts, zpts)
end

ARGS[1] ==        "cfsr" && (plotitle = "CFSR")
ARGS[1] ==  "erainterim" && (plotitle = "ERA Interim")
ARGS[1] ==       "hoaps" && (plotitle = "HOAPS")
ARGS[1] == "ifremerflux" && (plotitle = "IfremerFlux")
ARGS[1] ==      "jofuro" && (plotitle = "J-OFURO")
ARGS[1] ==       "merra" && (plotitle = "MERRA")
ARGS[1] ==      "oaflux" && (plotitle = "OAFlux")
ARGS[1] ==     "seaflux" && (plotitle = "SeaFlux")

ppp = Winston.Table(3,2) ; setattr(ppp, "cellpadding", -0.5)                  # and then create the scatterplots
for z = 1:PARAMS
  if ((ARGS[1] ==   "cfsr" &&               z != LHFX)   ||
      (ARGS[1] == "jofuro" && (z != SSTT || z != AIRT)))
    z == SHFX && (varname = "a) Sensible Heat Flux (Wm^{-2})" ; (xpts, ypts, zpts) = point(shfs, shfn) ; tpos = (1,1) ; delt = shfi)
    z == LHFX && (varname = "b) Latent Heat Flux (Wm^{-2})"   ; (xpts, ypts, zpts) = point(lhfs, lhfn) ; tpos = (1,2) ; delt = lhfi)
    z == WSPD && (varname = "c) Wind Speed (ms^{-1})"         ; (xpts, ypts, zpts) = point(wsps, wspn) ; tpos = (2,1) ; delt = wspi)
    z == SHUM && (varname = "d) Specific Humidity (g/kg)"     ; (xpts, ypts, zpts) = point(shus, shun) ; tpos = (2,2) ; delt = shui)
    z == SSTT && (varname = "e) Sea Surface Temp (^{o}C)"     ; (xpts, ypts, zpts) = point(ssts, sstn) ; tpos = (3,1) ; delt = ssti)
    z == AIRT && (varname = "f) Air Temperature (^{o}C)"      ; (xpts, ypts, zpts) = point(airs, airn) ; tpos = (3,2) ; delt = airi)

    xpts += 0.5 * delt                                                        # make xpts and ypts refer to grid midpoints
    ypts += 0.5 * delt                                                        # and locate the plot limits
    xmin = minimum(xpts) - delt * 5
    xmax = maximum(xpts) + delt * 5
    ymin = minimum(ypts) - delt * 5
    ymax = maximum(ypts) + delt * 5

    cols = ["red",  "blue", "green", "orange", "black", "white"]
    lims = [    1,      10,     100,     1000,   10000,  100000]

    tmp = Winston.FramedPlot(title="$varname", xrange = (xmin,xmax), yrange = (ymin,ymax))
    ppp[tpos...] = Winston.add(tmp)

    for (a, color) in enumerate(cols)
      mask = zpts .>= lims[a]
      tmp = Winston.Points(xpts[mask], ypts[mask], kind = "filled circle", "color", parse(Winston.Colorant, cols[a]), symbolsize = 0.1)
            Winston.add(ppp[tpos...], tmp)
      if z == SHFX
        tmp = Winston.PlotLabel(0.05, 0.85, plotitle, "texthalign", "left", "size", 3.4)
              Winston.add(ppp[tpos...], tmp)
      end
      if z == SSTT
        tmp = Winston.PlotLabel(0.05, 1.05 - a * 0.1, "<span foreground=\"$(cols[length(cols) - a + 1])\">\\geq $(lims[length(cols) - a + 1])</span>", "texthalign", "left", "size", 1.4)
              Winston.add(ppp[tpos...], tmp)
      end
    end

    (intbef, slobef) = linreg(xpts, ypts, zpts)
    tmp = Winston.Slope(slobef, (0, intbef), kind = "solid", "linewidth", 5, "color", parse(Winston.Colorant, "green"))
          Winston.add(ppp[tpos...], tmp)
    tmp = Winston.Slope(     1, (0,      0), kind = "solid")
          Winston.add(ppp[tpos...], tmp)
  end
end

xyzzy = "scatter." * ARGS[1] * ".png"
print("writing $xyzzy\n")
Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
exit(0)


#=
    ump = Array(Any, length(cols))
    ump[a] = Winston.Curve(specval[1:end,z], spectra[a,1:end,z], "color", parse(Winston.Colorant, cols[b]))
             style(ump[a], kind = kynd[b])
             setattr(ump[a], label = "($(specstr[a,z])) $(dirs[a])")
             Winston.add(ppp[tpos...], ump[a])
    b += 1
  end
  tmp = Winston.Legend(.23, .92, Any[ump[order[1]], ump[order[2]], ump[order[3]], ump[order[4]]])
        Winston.add(ppp[tpos...], tmp)
  tmp = Winston.Legend(.58, .92, Any[ump[order[5]], ump[order[6]], ump[order[7]], ump[order[8]]])
        Winston.add(ppp[tpos...], tmp)

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
=#
