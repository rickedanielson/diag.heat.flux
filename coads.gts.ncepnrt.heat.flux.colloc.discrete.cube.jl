#=
 = Partition a set of collocations into subsets that are geometrically closest
 = to the coordinates of a cube that (mostly) encompasses them.  Also yield the
 = coordinates at the center-of-mass of each subset so that interpolation can
 = be performed - RD February 2016.
 =#

using My
const COORD            = 2*2*2                          # number of cube coordinates
const LINES            = 45032                          # number of collocation lines
const CUTOFF           = 2000                           # number of collocations in a subset

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.combined\n\n")
  exit(1)
end

 fpn = Array(IOStream, COORD)
file = Array(UTF8String, COORD)
lims = Array(Float64, COORD)
diss = Array(Float64, LINES)
dist = Array(Float64, LINES, COORD)                                           # allocate for distance to the reference
cube = Array(Float64, COORD,     3)                                           # cube coords, as well as for the coords
mass = Array(Float64, COORD,     3)                                           # themselves and their center-of-mass
#         T   V  SST
cube = [-30.  0.  0.;
        -30.  0. 40.;
        -30. 40.  0.;
        -30. 40. 40.;
         40.  0.  0.;
         40.  0. 40.;
         40. 40.  0.;
         40. 40. 40.]

#      2   3   4         5    6    7    8
# date lat lon shfx lhfx shum wspd airt sstt
fpa = My.ouvre(ARGS[1], "r")                                                  # calculate distance to the reference
for a = 1:LINES                                                               # coords
  line = readline(fpa)
  vals = split(line)
  for b = 1:COORD
    dist[a,b] = (cube[b,1] - float(strip(vals[7])))^2.0 +
                (cube[b,2] - float(strip(vals[6])))^2.0 +
                (cube[b,3] - float(strip(vals[8])))^2.0
  end
end
close(fpa)

for a = 1:COORD                                                               # then find the closest distance that 
  diss = sort(dist[:,a])                                                      # contains a CUTOFF number of collocations
  lims[a] = diss[CUTOFF]
  print("limit for coord $a is $(lims[a])\n")
end

for a = 1:COORD                                                               # open the output subset files
  tmp = @sprintf("%4.0f.%4.0f.%4.0f", cube[a,1], cube[a,2], cube[a,3])
  tmq = replace(tmp, " ", ".")
  file[a] = ARGS[1] * tmq
  fpn[a] = My.ouvre(file[a], "w")
end

fpa = My.ouvre(ARGS[1], "r")                                                  # reopen the collocations and store those
for a = 1:LINES                                                               # that make the cut for each cube coord
  line = readline(fpa)
  for b = 1:COORD
    if dist[a,b] < lims[b]
      write(fpn[b], line)
    end
  end
end
close(fpa)

for a = 1:COORD                                                               # finally close the subset files
  close(fpn[a])
end
exit(0)
#                     9/10 11/12      13/14 15/16       17/18  19/20 21/22  23/24
# and (16) bef/aft of cfsr erainterim hoaps ifremerflux jofuro merra oaflux seaflux
