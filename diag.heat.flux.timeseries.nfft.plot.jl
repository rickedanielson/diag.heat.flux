#=
 = Loop through all spectra and visualize - RD October 2015
 =#

using My, Winston
const MISS             = -9999.0                        # generic missing value
const DAYS             = 3745                           # number of days in full timeseries
const TIMES            = 2556                           # number of days in during 2001-2007 (and number of spectral coefficients)
const VARSUM           = 30                             # cutoff timescale for variance summation (days)

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.locate.min2000\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]

specval = Array(Float64, length(dirs), div(TIMES, 2) + 1)
spectra = Array(Float64, length(dirs), div(TIMES, 2) + 1)
specvar = zeros(Float64, length(dirs))
specstr = Array(UTF8String, length(dirs))

for (a, dir) in enumerate(dirs)
  fila = "spectruo.$(ARGS[1]).$dir"
  fpa = My.ouvre(fila, "r") ; lines = readlines(fpa) ; close(fpa)
  for (b, linb) in enumerate(lines)
    vals = float(split(linb))
    specval[a,b] = vals[1]
#   specval[a,b] = (b - 1) / TIMES
    spectra[a,b] = 10.0 * log10(vals[2])
    if vals[1] > 1 / VARSUM
      specvar[a] += vals[2]
    end
  end
end
order = sortperm(specvar, rev=true)

for a in order
  specstr[a] = @sprintf("%.0lf", specvar[a])
  print("variance $(specstr[a]) in $(dirs[a])\n")
end

#xlaba = ["121", "60", "30", "14", "5", "3", "2"]
xlaba = ["1000", "365", "182", "121", "60", "30", "14", "5", "3", "2"]
xlabb = ["0.01", "0.1"]
xposa = float(xlaba).^-1
xposb = float(xlabb)

xyzzy = "spectruo.$(ARGS[1]).png"
print("writing $xyzzy\n")
tmp = Winston.FramedPlot(
        title="2001-2007 SHF Spectra (dB)", xlog = true,
        xlabel="Timescale (days)", xrange = (1/1000,1/2),
                                   yrange = (-15,30))
setattr(tmp.x1, "ticks",          xposa) ; setattr(tmp.x2, "ticks",          xposb)
setattr(tmp.x1, "tickdir",            1) ; setattr(tmp.x2, "tickdir",           -1)
                                           setattr(tmp.x2, "ticklabels_offset", -6)
setattr(tmp.x1, "ticklabels",     xlaba) ; setattr(tmp.x2, "ticklabels",     xlabb)
setattr(tmp.x1, "draw_subticks",  false) ; setattr(tmp.x2, "draw_subticks",   true)
ppp = Winston.add(tmp)

ump = Array(Any, 8)
cols = [  "red",  "blue", "green", "orange",    "red",   "blue",  "green", "orange"]
kynd = ["solid", "solid", "solid",  "solid", "dashed", "dashed", "dashed", "dashed"]

b = 1
for a in order
  ump[a] = Winston.Curve(specval[a,1:end], spectra[a,1:end], "color", parse(Winston.Colorant, cols[b]))
           style(ump[a], kind = kynd[b])
           setattr(ump[a], label = "($(specstr[a])) $(dirs[a])")
           Winston.add(ppp, ump[a])
  b += 1
end
tmp = Winston.Legend(.41, .8, {ump[order[1]], ump[order[2]], ump[order[3]], ump[order[4]]})
      Winston.add(ppp, tmp)
tmp = Winston.Legend(.75, .8, {ump[order[5]], ump[order[6]], ump[order[7]], ump[order[8]]})
      Winston.add(ppp, tmp)
      Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
exit(0)
