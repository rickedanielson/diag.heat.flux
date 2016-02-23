#=
 = Identify and count the location of all observations in the input file,
 = where locations are defined at the resolution of a grid (for subsequent
 = collocation) and only for elevations below sea level (i.e., excluding
 = inland waters) - RD June 2015
 =#

using My #, NetCDF

if size(ARGS) == (0,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux\n\n")
  exit(1)
end

tats = collect(89.875:-0.25:-89.875)                                          # first read height relative to sea level
tons = collect(0.1250: 0.25:359.875) ; for a = 1:1440  tons[a] > 180 && (tons[a] -= 360)  end
#topo = ncread("/home/ricani/data/topography/elev.0.25-deg.nc", "data", start=[1,1,1], count=[-1,-1,-1])
#      nc = NetCDF.open("/home/ricani/data/topography/elev.0.25-deg.nc", mode=NC_NOWRITE, readdimvar=false)
#try topo = NetCDF.readvar(nc, "data", start=[1,1,1], count=[-1,-1,-1])  catch  topo = false  end
#           NetCDF.close(nc)
tmparr = Array(Float32, 1036800) ; topo = Array(Float64, (1440,720))
#ccall((:cdcread, "/home/ricani/lib/libcdcnetcdf.so"), Void, (Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt8}, Ptr{Cfloat}, Int32), "/home/ricani/data/topography/elev.0.25-deg.nc", "data", "0001-01-01-00", tmparr, 1036800)
ccall((:cdcread, "/home1/homedir1/perso/rdaniels/lib/libcdcnetcdf.so"), Void, (Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt8}, Ptr{Cfloat}, Int32), "/home/cercache/users/rdaniels/topography/elev.0.25-deg.nc", "data", "0001-01-01-00", tmparr, 1036800)
c = 1 ; for a = 1:720, b = 1:1440  topo[b,a] = tmparr[c] ; c += 1  end

lats = collect( -90.0:0.25:89.75)                                             # then define the collocation grid
lons = collect(-180.0:0.25:179.75)                                            # and initialize the counts
subs = Set(Array(Tuple{Float64, Float64}, 0))
numb = zeros(length(lons), length(lats))

csv = readcsv(ARGS[1])                                                        # identify and count the collocations
vals, = size(csv)                                                             # between 1999-10 and 2009-12 (as long
for a = 1:vals                                                                # as the gridbox is below sea level)
  lat = csv[a,5]
  lon = csv[a,6] ; lon < -180 && (lon += 360)
  dellat, indlat = findmin(abs(tats - lat))
  dellon, indlon = findmin(abs(tons - lon))
  if topo[indlon,indlat] < 0 && 199909999999 < float(csv[a,4]) < 201000000000
    dellat, indlat = findmin(abs(lats - lat))
    dellon, indlon = findmin(abs(lons - lon))
    push!(subs, (lats[indlat], lons[indlon]))
    numb[indlon,indlat] += 1
  end
end

fpa = My.ouvre("$(ARGS[1]).locate", "w")                                      # and save them
for loc in subs
  (lat, lon) = loc
  indlat = findfirst(lats, lat)
  indlon = findfirst(lons, lon)
  line = @sprintf("%8.2f, %8.2f, %8f\n", lat, lon, numb[indlon,indlat])
  write(fpa, line)
end
close(fpa)
exit(0)


#=
@printf("%f,%f became %f,%f\n", lat, lon, tats[indlat], tons[indlon])
@printf("%f,%f became %f,%f\n", lat, lon, lats[indlat], lons[indlon])
=#
