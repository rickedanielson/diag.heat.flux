#=
 = Reformat triple collocation metric summaries as markdown
 = tables.  It is assumed that the files passed as arguments
 = are the available group of analyses for a given variable
 = (e.g., wspd) - RD April 2016.
 =#

using My
const VARS             = 4                              # number of triple collocation metrics
const COEF             = 10                             # number of polynomial coefficients
const MISS             = -9999.0                        # generic missing value

if (argc = length(ARGS)) == 0
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_calib*\n\n")
  exit(1)
end

for a = 1:argc                                                                # convert each input file to markdown
  contains(ARGS[a], "shfx") && (varname = "Sensible Heat Flux")
  contains(ARGS[a], "lhfx") && (varname = "Latent Heat Flux")
  contains(ARGS[a], "wspd") && (varname = "Wind Speed")
  contains(ARGS[a], "airt") && (varname = "Air Temperature")
  contains(ARGS[a], "sstt") && (varname = "SST")
  contains(ARGS[a], "shum") && (varname = "Specific Humidity")

  fpa = My.ouvre(                          ARGS[a],         "r") ; lines = readlines(fpa) ; close(fpa)
  fpa = My.ouvre("../zali.recalib.true/" * ARGS[a],         "r") ; linez = readlines(fpa) ; close(fpa)
  fpb = My.ouvre(                          ARGS[a] * ".md", "w")

  form = "\n$varname\n\n"
  write(fpb, form)
  form = "\n| | Bias | Slope | RMSE | Correlation |\n"
  write(fpb, form)
  form = "| --- | --- | --- | --- | --- |\n"
  write(fpb, form)

  (linc,) = size(lines)
  for b = 8:linc
    contains(lines[b],        "cfsr") && (dirname =    "CFSR")
    contains(lines[b],  "erainterim") && (dirname =     "ERA")
    contains(lines[b],       "hoaps") && (dirname =   "HOAPS")
    contains(lines[b], "ifremerflux") && (dirname = "Ifremer")
    contains(lines[b],      "jofuro") && (dirname = "J-Ofuro")
    contains(lines[b],       "merra") && (dirname =   "Merra")
    contains(lines[b],      "oaflux") && (dirname =  "OAFlux")
    contains(lines[b],     "seaflux") && (dirname = "SeaFlux")
    vals = split(lines[b][34:end]) ; nals = float(split(lines[b][34:end]))
    valz = split(linez[b][34:end]) ; nalz = float(split(linez[b][34:end]))

    stra = abs(nals[1] - 0) < abs(nalz[1] - 0) ? "**" * vals[1] * "/" * valz[1] * "**" : vals[1] * "/" * valz[1]
    strb = abs(nals[2] - 1) < abs(nalz[2] - 1) ? "**" * vals[2] * "/" * valz[2] * "**" : vals[2] * "/" * valz[2]
    strc =     nals[3]      <     nalz[3]      ? "**" * vals[3] * "/" * valz[3] * "**" : vals[3] * "/" * valz[3]
    strd =     nals[4]      >     nalz[4]      ? "**" * vals[4] * "/" * valz[4] * "**" : vals[4] * "/" * valz[4]
    form = @sprintf("| %7s | %18s |  %18s |  %18s |  %18s |\n", dirname, stra, strb, strc, strd)
    write(fpb, form)
  end
  close(fpb)
end
exit(0)
