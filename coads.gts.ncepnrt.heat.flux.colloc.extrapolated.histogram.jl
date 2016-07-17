#=
 = Loop through the available collocations and grid the corresponding forward and
 = backward extrapolations relative to the actual (uninterpolated) values.  Note that
 = BEF refers to an extrapolation using analysis data from before the target value and
 = AFT refers to an extrapolation using data from afterward.  Relative to the values at
 = the extrapolation target time (TOTN), both local (binwise) and global regressions of
 = the two separate extrapolations (from before and after) are also saved.  The global
 = regression is then applied to the data and the same files are stored - RD June 2016.
 =#

using My
const ODAT             = 1                              # identify indecies of the input data:
const OLAT             = 2                              # date/lat/lon on the collocation grid
const OLON             = 3
const OCUR             = 4                              # then five buoy parameters
const SUHM             = 5
const WSPD             = 6
const AIRT             = 7
const SSTT             = 8

const CUTOFF           = 400                            # number of collocations in a sample
const MISS             = -9999.0                        # generic missing value

if (argc = length(ARGS)) != 2
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.daily.locate_2.0_extra.airt.got2000_obs.comt cfsr\n\n")
  exit(1)
end

vind = 0                                                                      # define the location of the variable
  ARGS[2] ==        "cfsr" && (vind =  9)                                     # of interest in the input data file
  ARGS[2] ==  "erainterim" && (vind = 12)                                     # (omit cfsr LHFX and jofuro AIRT/SSTT)
  ARGS[2] ==       "hoaps" && (vind = 15)
  ARGS[2] == "ifremerflux" && (vind = 18)
  ARGS[2] ==      "jofuro" && (vind = 21)
  ARGS[2] ==       "merra" && (vind = 24)
  ARGS[2] ==      "oaflux" && (vind = 27)
  ARGS[2] ==     "seaflux" && (vind = 30)
if contains(ARGS[1], "lhfx")
  ARGS[2] ==        "cfsr" && (vind =  0)
  ARGS[2] ==  "erainterim" && (vind =  9)
  ARGS[2] ==       "hoaps" && (vind = 12)
  ARGS[2] == "ifremerflux" && (vind = 15)
  ARGS[2] ==      "jofuro" && (vind = 18)
  ARGS[2] ==       "merra" && (vind = 21)
  ARGS[2] ==      "oaflux" && (vind = 24)
  ARGS[2] ==     "seaflux" && (vind = 27)
elseif contains(ARGS[1], "airt") || contains(ARGS[1], "sstt")
  ARGS[2] ==        "cfsr" && (vind =  9)
  ARGS[2] ==  "erainterim" && (vind = 12)
  ARGS[2] ==       "hoaps" && (vind = 15)
  ARGS[2] == "ifremerflux" && (vind = 18)
  ARGS[2] ==      "jofuro" && (vind =  0)
  ARGS[2] ==       "merra" && (vind = 21)
  ARGS[2] ==      "oaflux" && (vind = 24)
  ARGS[2] ==     "seaflux" && (vind = 27)
end
if vind == 0
  print("\n$(ARGS[1]) does not contain data from $(ARGS[2])\n\n")
  exit(0)
end
const TOTB             = vind
const TOTN             = vind + 1
const TOTA             = vind + 2

contains(ARGS[1], "shfx") && (const RANGE = 100.0: 5.0:250.0)                 # define the target sampling range
contains(ARGS[1], "lhfx") && (const RANGE =  50.0:10.0:450.0)                 # (as in paired triple collocation)
contains(ARGS[1], "wspd") && (const RANGE =   2.5: 0.5: 17.5)                 # and BEF and AFT grids for plotting
contains(ARGS[1], "airt") && (const RANGE =   0.0: 0.5: 30.0)
contains(ARGS[1], "sstt") && (const RANGE =   5.0: 0.5: 30.0)
contains(ARGS[1], "shum") && (const RANGE =   2.5: 0.5: 22.5)

contains(ARGS[1], "shfx") && (step = 1.0 ; bound = collect( -600.0 : step : 1500.0))
contains(ARGS[1], "lhfx") && (step = 1.0 ; bound = collect(-1200.0 : step : 2500.0))
contains(ARGS[1], "wspd") && (step = 0.1 ; bound = collect(  -40.0 : step :   80.0))
contains(ARGS[1], "airt") && (step = 0.1 ; bound = collect(  -20.0 : step :   50.0))
contains(ARGS[1], "sstt") && (step = 0.1 ; bound = collect(  -20.0 : step :   50.0))
contains(ARGS[1], "shum") && (step = 0.2 ; bound = collect(  -40.0 : step :   80.0))
gridb = zeros(length(bound), length(bound)) ; meanb = zeros(length(bound))
grida = zeros(length(bound), length(bound)) ; meana = zeros(length(bound))
oridb = zeros(length(bound), length(bound)) ; oeanb = zeros(length(bound))
orida = zeros(length(bound), length(bound)) ; oeana = zeros(length(bound))
regb = Array(Float64, 0)
regn = Array(Float64, 0)
rega = Array(Float64, 0)
oegb = Array(Float64, 0)
oego = Array(Float64, 0)
oega = Array(Float64, 0)

fpa = My.ouvre(ARGS[1], "r") ; tinea = readlines(fpa) ; close(fpa)            # grid the collocations and save values
tinuma = length(tinea)                                                        # for a regression versus TOTN and OCUR
for a = 1:tinuma
  vals = float(split(tinea[a]))
  if vals[TOTB] > -3333 && vals[TOTB] < 3333 &&
     vals[TOTN] > -3333 && vals[TOTN] < 3333 &&
     vals[TOTA] > -3333 && vals[TOTA] < 3333 &&
     vals[OCUR] > -3333 && vals[OCUR] < 3333
    delbef, indbef = findmin(abs(bound - vals[TOTB])) ; bound[indbef] > vals[TOTB] && indbef > 1 && (indbef -= 1)
    delnow, indnow = findmin(abs(bound - vals[TOTN])) ; bound[indnow] > vals[TOTN] && indnow > 1 && (indnow -= 1)
    delaft, indaft = findmin(abs(bound - vals[TOTA])) ; bound[indaft] > vals[TOTA] && indaft > 1 && (indaft -= 1)
    delobs, indobs = findmin(abs(bound - vals[OCUR])) ; bound[indobs] > vals[OCUR] && indobs > 1 && (indobs -= 1)
    gridb[indbef,indnow] += 1 ; meanb[indnow] += vals[TOTB]
    grida[indaft,indnow] += 1 ; meana[indnow] += vals[TOTA]
    oridb[indbef,indobs] += 1 ; oeanb[indobs] += vals[TOTB]
    orida[indaft,indobs] += 1 ; oeana[indobs] += vals[TOTA]
    push!(regb, vals[TOTB])
    push!(regn, vals[TOTN])
    push!(rega, vals[TOTA])
    push!(oegb, vals[TOTB])
    push!(oego, vals[OCUR])
    push!(oega, vals[TOTA])
  end
end

fname = ARGS[1] * "." * ARGS[2] * ".extra.dat"
fpa = My.ouvre(fname, "w")                                                    # and save the grids
for (a, vala) in enumerate(bound)
  for (b, valb) in enumerate(bound)
    @printf(fpa, "%15.8f %15.8f %15.8f %15.8f\n", gridb[b,a], grida[b,a], oridb[b,a], orida[b,a])
  end
end
close(fpa)

sumb = sum(gridb, 1)                                                          # as well as the corresponding count and sum
suma = sum(grida, 1)                                                          # of extrapolation values in each TOTN interval
oumb = sum(oridb, 1)
ouma = sum(orida, 1)
fname = ARGS[1] * "." * ARGS[2] * ".extra.sum"
fpa = My.ouvre(fname, "w")
for (a, vala) in enumerate(bound)
  @printf(fpa, "%22.0f %33.11f %22.0f %33.11f %22.0f %33.11f %22.0f %33.11f\n",
    sumb[a], meanb[a], suma[a], meana[a], oumb[a], oeanb[a], ouma[a], oeana[a])
end
close(fpa)

fname = ARGS[1] * "." * ARGS[2] * ".extra.reg"                                # and finally save the regression coefficients
fpa = My.ouvre(fname, "w")
(intb, slob) = linreg(regn, regb)
(inta, sloa) = linreg(regn, rega)
(ontb, olob) = linreg(oego, oegb)
(onta, oloa) = linreg(oego, oega)
@printf(fpa, "%33.11f %33.11f %33.11f %33.11f %33.11f %33.11f %33.11f %33.11f\n",
  intb, slob, inta, sloa, ontb, olob, onta, oloa)
close(fpa)

gridb = zeros(length(bound), length(bound)) ; meanb = zeros(length(bound))    # reinitialize the variables for calibration
grida = zeros(length(bound), length(bound)) ; meana = zeros(length(bound))
oridb = zeros(length(bound), length(bound)) ; oeanb = zeros(length(bound))
orida = zeros(length(bound), length(bound)) ; oeana = zeros(length(bound))
regb = Array(Float64, 0)
regn = Array(Float64, 0)
rega = Array(Float64, 0)
oegb = Array(Float64, 0)
oego = Array(Float64, 0)
oega = Array(Float64, 0)

for a = 1:tinuma                                                              # now calibrate the same collocations using
  vals = float(split(tinea[a]))                                               # the global regressions above and regrid
  if vals[TOTB] > -3333 && vals[TOTB] < 3333 &&
     vals[TOTN] > -3333 && vals[TOTN] < 3333 &&
     vals[TOTA] > -3333 && vals[TOTA] < 3333 &&
     vals[OCUR] > -3333 && vals[OCUR] < 3333
    tmpb = (vals[TOTB] - intb) / slob
    tmpn =  vals[TOTN]
    tmpa = (vals[TOTA] - inta) / sloa
    tmpo =  vals[OCUR]
    delbef, indbef = findmin(abs(bound - tmpb)) ; bound[indbef] > tmpb && indbef > 1 && (indbef -= 1)
    delnow, indnow = findmin(abs(bound - tmpn)) ; bound[indnow] > tmpn && indnow > 1 && (indnow -= 1)
    delaft, indaft = findmin(abs(bound - tmpa)) ; bound[indaft] > tmpa && indaft > 1 && (indaft -= 1)
    delobs, indobs = findmin(abs(bound - tmpo)) ; bound[indobs] > tmpo && indobs > 1 && (indobs -= 1)
    gridb[indbef,indnow] += 1 ; meanb[indnow] += tmpb
    grida[indaft,indnow] += 1 ; meana[indnow] += tmpa
    oridb[indbef,indobs] += 1 ; oeanb[indobs] += tmpb
    orida[indaft,indobs] += 1 ; oeana[indobs] += tmpa
    push!(regb, tmpb)
    push!(regn, tmpn)
    push!(rega, tmpa)
    push!(oegb, tmpb)
    push!(oego, tmpo)
    push!(oega, tmpa)
  end
end

fname = ARGS[1] * "." * ARGS[2] * ".extra.dau"
fpa = My.ouvre(fname, "w")                                                    # and save the grids
for (a, vala) in enumerate(bound)
  for (b, valb) in enumerate(bound)
    @printf(fpa, "%15.8f %15.8f %15.8f %15.8f\n", gridb[b,a], grida[b,a], oridb[b,a], orida[b,a])
  end
end
close(fpa)

sumb = sum(gridb, 1)                                                          # as well as the corresponding count and sum
suma = sum(grida, 1)                                                          # of extrapolation values in each TOTN interval
oumb = sum(oridb, 1)
ouma = sum(orida, 1)
fname = ARGS[1] * "." * ARGS[2] * ".extra.sun"
fpa = My.ouvre(fname, "w")
for (a, vala) in enumerate(bound)
  @printf(fpa, "%22.0f %33.11f %22.0f %33.11f %22.0f %33.11f %22.0f %33.11f\n",
    sumb[a], meanb[a], suma[a], meana[a], oumb[a], oeanb[a], ouma[a], oeana[a])
end
close(fpa)

fname = ARGS[1] * "." * ARGS[2] * ".extra.reh"                                # and finally save the regression coefficients
fpa = My.ouvre(fname, "w")
(intb, slob) = linreg(regn, regb)
(inta, sloa) = linreg(regn, rega)
(ontb, olob) = linreg(oego, oegb)
(onta, oloa) = linreg(oego, oega)
@printf(fpa, "%33.11f %33.11f %33.11f %33.11f %33.11f %33.11f %33.11f %33.11f\n",
  intb, slob, inta, sloa, ontb, olob, onta, oloa)
close(fpa)
exit(0)


#=
count(shfs, shfn, data[:,SHFX,BEF], data[:,SHFX,NOW], data[:,SHFX,AFT])
function count(bound::Array{Float64,1}, grid::Array{Float64,3}, bef::Array{Float64,1}, now::Array{Float64,1}, aft::Array{Float64,1})
  for a = 1:dirn
    delbef, indbef = findmin(abs(bound - bef[a])) ; bound[indbef] > bef[a] && indbef > 1 && (indbef -= 1)
    delnow, indnow = findmin(abs(bound - now[a])) ; bound[indnow] > now[a] && indnow > 1 && (indnow -= 1)
    delaft, indaft = findmin(abs(bound - aft[a])) ; bound[indaft] > aft[a] && indaft > 1 && (indaft -= 1)
    grid[indbef,indnow,a] += 1 ; grid[indaft,indnow,a] += 1
  end
end
=#
