#=
 = Loop through all locations of interest and assemble valid collocations
 = from the various in situ and analysis subdirs.  Include a conversion of
 = units, as required - RD February, March 2016.
 =#

using My
const SHFX             = 1                              # indecies of all data variables
const LHFX             = 2
const WSPD             = 9
const AIRT             = 12
const SSTT             = 14
const SHUM             = 15

const VARN             = 22                             # number of output variables (besides date/lat/lon)
const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) shfx/lhfx/wspd/airt/sstt/shum\n\n")
  exit(1)
end

varind = 0
ARGS[1] == "shfx" && (varind = SHFX)
ARGS[1] == "lhfx" && (varind = LHFX)
ARGS[1] == "wspd" && (varind = WSPD)
ARGS[1] == "airt" && (varind = AIRT)
ARGS[1] == "sstt" && (varind = SSTT)
ARGS[1] == "shum" && (varind = SHUM)

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
(dirn,) = size(dirs)
fpa = My.ouvre("all.flux.combined." * ARGS[1], "w")

files = filter(x -> ismatch(r"^in", x), readdir("insitu"))                    # loop through all locations (e.g., as
for fila in files                                                             # given by insitu...-10.000..-105.000)
  data = fill(MISS, VARN)
  fpn = Array(IOStream, 0)
  tail = fila[7:end]
  (lat, lon) = float(split(replace(tail, r"[\.]{2,}", " ")))

  tmp = "insitu/$fila"           ; fpb = My.ouvre(tmp, "r", false)            # open this set of files
  for dira in dirs
    tmp = "$dira/$dira$tail.bef" ; fpc = My.ouvre(tmp, "r", false) ; push!(fpn, fpc)
    tmp = "$dira/$dira$tail.aft" ; fpc = My.ouvre(tmp, "r", false) ; push!(fpn, fpc)
  end

  for a = 1:TIMS                                                              # loop through the 3745 times of all nine
    line = readline(fpb)                                                      # files in step, starting with insitu
    vals = split(line)
    date    =             vals[4]
    data[1] = float(strip(vals[SHFX]))
    data[2] = float(strip(vals[LHFX]))
    data[3] = float(strip(vals[WSPD]))
    data[4] = float(strip(vals[AIRT]))
    data[5] = float(strip(vals[SSTT]))
    data[6] = float(strip(vals[SHUM]))

    for b = 1:2*dirn                                                          # then eight before and after extrapolations
      line = readline(fpn[b])
      vals = split(line)
      data[b+6] = float(strip(vals[varind]))
    end

    if     varind == LHFX                                                     # accommodate CFSR units for AIRT, all SSTT,
      data[ 7] = data[ 8] = -332.9                                            # missing JOFURO AIRT/SSTT, and CFSR LHFX
    elseif varind == AIRT
      data[ 7] != MISS && (data[ 7] -= 273.15)
      data[ 8] != MISS && (data[ 8] -= 273.15)
      data[15] = data[16] = -332.9
    elseif varind == SSTT
      data[ 7] != MISS && (data[ 7] -= 273.15)
      data[ 8] != MISS && (data[ 8] -= 273.15)
      data[ 9] != MISS && (data[ 9] -= 273.15)
      data[10] != MISS && (data[10] -= 273.15)
      data[11] != MISS && (data[11] -= 273.15)
      data[12] != MISS && (data[12] -= 273.15)
      data[13] != MISS && (data[13] -= 273.15)
      data[14] != MISS && (data[14] -= 273.15)
      data[17] != MISS && (data[17] -= 273.15)
      data[18] != MISS && (data[18] -= 273.15)
      data[19] != MISS && (data[19] -= 273.15)
      data[20] != MISS && (data[20] -= 273.15)
      data[21] != MISS && (data[21] -= 273.15)
      data[22] != MISS && (data[22] -= 273.15)
      data[15] = data[16] = -332.9
    end

    flag = true                                                               # ensure that all values are valid
    for b = 1:VARN
      if data[b] < -333 || data[b] > 3333
        flag = false
      end
    end

    if flag                                                                   # and store the line if so
      line = @sprintf("%s %9.3f %9.3f", date, lat, lon)
      for b = 1:VARN
        linb = @sprintf(" %9.3f", data[b]) ; line *= linb
      end
      line *= "\n" ; write(fpa, line)
    end
  end

  close(fpb)
  for a = 1:2*dirn                                                            # then close this set of files
    close(fpn[a])
  end
end

close(fpa)
exit(0)
