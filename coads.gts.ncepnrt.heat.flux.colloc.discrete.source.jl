#=
 = Loop through all 4793 locations and assemble the valid collocations
 = from the various in situ and analysis subdirs - RD February 2016.
 =#

using My
const VARN             = 21                             # number of output variables (besides date/lat/lon)
const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (0,)
  write("\nUsage: jjj $(basename(@__FILE__))\n\n")
  exit(1)
end

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"]
(dirn,) = size(dirs)
fpa = My.ouvre("all.flux.combined", "w")

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
    date =                vals[1]                                             # 2004101112 18.420 128.960 16.373 5.659 25.000 28.000
    data[1] = float(strip(vals[2]))                                           # date       shfx   lhfx    shum   wspd  airt   sstt
    data[2] = float(strip(vals[4]))
    data[3] = float(strip(vals[5]))
    data[4] = float(strip(vals[6]))
    data[5] = float(strip(vals[7]))

    for b = 1:2*dirn                                                          # then eight before and after extrapolations
      line = readline(fpn[b])
      vals = split(line)
      data[b+5] = float(strip(vals[2]))
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
        linb = @sprintf(" %9.3f", data[b])
        line *= linb
      end
      write(fpa, line)
    end
  end

  close(fpb)
  for a = 1:2*dirn                                                            # then close this set of files
    close(fpn[a])
  end
end

close(fpa)
exit(0)
