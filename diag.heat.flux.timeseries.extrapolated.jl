#=
 = Loop through all timeseries of a given analysis and create the
 = corresponding forward and backward extrapolated timeseries - RD
 = September 2015
 =#

using My, Interpolations
const BEF              = 1
const NOW              = 2
const AFT              = 3
const EXTRA            = 9                              # number of points used for extrapolation
const TIMS             = 3745                           # number in timeseries
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  write("\nUsage: jj $(basename(@__FILE__)) cfsr\n\n")
  exit(1)
end

inner = div(EXTRA - 1, 2)
outer = div(EXTRA + 1, 2)
dat = Array(Float64,      TIMS)
shf = Array(Float64, AFT, TIMS)
lhf = Array(Float64, AFT, TIMS)

fpa = My.ouvre("$(ARGS[1])/z.list", "r")                                      # get the list of timeseries
files = readlines(fpa) ; close(fpa)                                           # and process each in turn
for fila in files
  fila = strip(fila)
  fpa = My.ouvre("$(ARGS[1])/$fila", "r", false)
  lines = readlines(fpa) ; close(fpa)
  for (a, line) in enumerate(lines)
    vals = float(split(line))
    dat[    a] = vals[1]
    shf[NOW,a] = vals[2]
    lhf[NOW,a] = vals[3]
  end

  for a = 1:EXTRA+1  shf[BEF,a] = lhf[BEF,a] = MISS  end                      # simultaneously extrapolate
  for a = 1+outer:TIMS-outer                                                  # from BEF and AFT
    shftmp = vec(shf[NOW,a-inner:a+inner])
    if all(-333 .< shftmp .< 3333)
      itpshf = interpolate(shftmp, BSpline(Quadratic(Line)), OnCell)
      shf[BEF,a+outer] = itpshf[10]
      shf[AFT,a-outer] = itpshf[0]
    else
      shf[BEF,a+outer] = shf[AFT,a-outer] = MISS
    end
    lhftmp = vec(lhf[NOW,a-inner:a+inner])
    if all(-333 .< lhftmp .< 3333)
      itplhf = interpolate(lhftmp, BSpline(Quadratic(Line)), OnCell)
      lhf[BEF,a+outer] = itplhf[10]
      lhf[AFT,a-outer] = itplhf[0]
    else
      lhf[BEF,a+outer] = lhf[AFT,a-outer] = MISS
    end
  end
  for a = 0:EXTRA  shf[AFT,end-a] = lhf[AFT,end-a] = MISS  end

  filb = "$fila.bef"                                                          # then save the extrapolations
  filc = "$fila.aft"
  fpb = My.ouvre("$(ARGS[1])/$filb", "w", false)
  fpc = My.ouvre("$(ARGS[1])/$filc", "w", false)
  for a = 1:TIMS
    tmpb = @sprintf("%.0f %9.3f %9.3f\n", dat[a], shf[BEF,a], lhf[BEF,a])
    tmpc = @sprintf("%.0f %9.3f %9.3f\n", dat[a], shf[AFT,a], lhf[AFT,a])
    write(fpb, tmpb)
    write(fpc, tmpc)
  end
  close(fpb)
  close(fpc)
end
