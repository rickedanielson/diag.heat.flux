#=
 = Loop through all spectra and visualize - RD October 2015, March 2016.
 =#

using My, Winston
const SPECS            = 1279                           # length of the one-sided spectra
const TIMES            = 2556                           # number of days in during 2001-2007 (and number of spectral coefficients)
const VARSUM           = 30                             # cutoff timescale for variance summation (days)
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_calib.airt.got2000.spec\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
dirn = length(dirs)

specval = Array(Float64, SPECS)
spectra = Array(Float64, dirn, SPECS)
specvar = zeros(Float64, dirn)
specstr = Array(UTF8String, dirn)

fpa = My.ouvre(ARGS[1], "r") ; lines = readlines(fpa) ; close(fpa)
for (a, line) in enumerate(lines)
  vals = float(split(line))
  specval[a] = vals[1]
  for b = 1:dirn
    if vals[b+1] == MISS
      spectra[b,a] = MISS
    else
      spectra[b,a] = 10.0 * log10(vals[b+1])
      if vals[1] > 1 / VARSUM
        specvar[b] += vals[b+1]
      end
    end
  end
end
order = sortperm(specvar, rev=true)

for a in order
  ARGS[1][end-16:end-13] == "shfx" && (specstr[a] = @sprintf("%.0lf", specvar[a]))
  ARGS[1][end-16:end-13] == "lhfx" && (specstr[a] = @sprintf("%.0lf", specvar[a]))
  ARGS[1][end-16:end-13] == "wspd" && (specstr[a] = @sprintf("%.1lf", specvar[a]))
  ARGS[1][end-16:end-13] == "airt" && (specstr[a] = @sprintf("%.2lf", specvar[a]))
  ARGS[1][end-16:end-13] == "sstt" && (specstr[a] = @sprintf("%.3lf", specvar[a]))
  ARGS[1][end-16:end-13] == "shum" && (specstr[a] = @sprintf("%.2lf", specvar[a]))
  print("variance $(specstr[a]) in $(dirs[a])\n")
end

ARGS[1][end-16:end-13] == "shfx" && (varname = "SHFR")
ARGS[1][end-16:end-13] == "lhfx" && (varname = "LHFR")
ARGS[1][end-16:end-13] == "wspd" && (varname = "WSPR")
ARGS[1][end-16:end-13] == "airt" && (varname = "AIRR")
ARGS[1][end-16:end-13] == "sstt" && (varname = "SSTR")
ARGS[1][end-16:end-13] == "shum" && (varname = "SHUR")
fpb = My.ouvre(ARGS[1] * ".stat", "w")
form = @sprintf("const %s = [%15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf, %15.8lf,      0.0]\n",
  varname, specvar[1], specvar[2], specvar[3], specvar[4], specvar[5], specvar[6], specvar[7], specvar[8])
write(fpb, form)
print(form)
close(fpb)

#xlaba = ["121", "60", "30", "14", "5", "3", "2"]
xlaba = ["1000", "365", "182", "121", "60", "30", "14", "5", "3", "2"]
xlabb = ["0.002", "0.3"]
xposa = float(xlaba).^-1
xposb = float(xlabb)

xyzzy = ARGS[1]*".png"
print("writing $xyzzy\n")
ARGS[1][end-16:end-13] == "shfx" && (varname = "Sensible Heat Flux" ; ymin = -40 ; ymax = 40)
ARGS[1][end-16:end-13] == "lhfx" && (varname = "Latent Heat Flux"   ; ymin = -40 ; ymax = 40)
ARGS[1][end-16:end-13] == "wspd" && (varname = "Wind Speed"         ; ymin = -50 ; ymax = 10)
ARGS[1][end-16:end-13] == "airt" && (varname = "Air Temperature"    ; ymin = -50 ; ymax = 10)
ARGS[1][end-16:end-13] == "sstt" && (varname = "Sea Surface Temp"   ; ymin = -70 ; ymax = 10)
ARGS[1][end-16:end-13] == "shum" && (varname = "Specific Humidity"  ; ymin = -60 ; ymax =  0)
tmp = Winston.FramedPlot(
        title="2001-2007 $varname Spectra (dB)", xlog = true,
        xlabel="Timescale (days)", xrange = (1/1000,1/2),
                                   yrange = (ymin,ymax))
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
  ump[a] = Winston.Curve(specval[1:end], spectra[a,1:end], "color", parse(Winston.Colorant, cols[b]))
           style(ump[a], kind = kynd[b])
           setattr(ump[a], label = "($(specstr[a])) $(dirs[a])")
           Winston.add(ppp, ump[a])
  b += 1
end
tmp = Winston.Legend(.30, .94, Any[ump[order[1]], ump[order[2]], ump[order[3]], ump[order[4]]])
      Winston.add(ppp, tmp)
tmp = Winston.Legend(.60, .94, Any[ump[order[5]], ump[order[6]], ump[order[7]], ump[order[8]]])
      Winston.add(ppp, tmp)
      Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
exit(0)


#=
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
=#
