using NetCDF
using Grid

stem = "/home1/homedir1/perso/rdaniels/data/ohf/"
# dirs = ["HOAPS", "cfsr", "erainterim", "ifremerflux", "jofuro", "oaflux", "seaflux"]
# (dirn,) = size(dirs)
res = Array(Float64,6)

searchdir(path,key) = filter(x->contains(x,key), readdir(path))               # return file names in "path" that contain the "key" string

x = readcsv("all.flux.sub")
shf =     x[:,1]
lhf =     x[:,2]
tim = int(x[:,4])
lat =     x[:,5]
lon =     x[:,6]
(vals,) = size(tim)
lats =  -90.0:0.25:89.75
lons = -180.0:0.25:179.75

for a = 1:vals
  time = string(tim[a]) ; day  = time[1:8]
  erafile = searchdir("erainterim",  day) ; (erasize,) = size(erafile)
  ifrfile = searchdir("ifremerflux", day) ; (ifrsize,) = size(ifrfile)
  seafile = searchdir("seaflux",     day) ; (seasize,) = size(seafile)
  if erasize == 1 && ifrsize == 1 && seasize == 1
    @printf("reading  %s %s     %s\n","erainterim/"*erafile[1],"ifremerflux/"*ifrfile[1],"seaflux/"*seafile[1])
    erashf = ncread( "erainterim/"*erafile[1], "surface_upward_sensible_heat_flux", start=[1,1,1], count=[-1,-1,-1])
    eralhf = ncread( "erainterim/"*erafile[1], "surface_upward_latent_heat_flux",   start=[1,1,1], count=[-1,-1,-1])
    ifrshf = ncread("ifremerflux/"*ifrfile[1], "surface_upward_sensible_heat_flux", start=[1,1,1], count=[-1,-1,-1])
    ifrlhf = ncread("ifremerflux/"*ifrfile[1], "surface_upward_latent_heat_flux",   start=[1,1,1], count=[-1,-1,-1])
    seashf = ncread(    "seaflux/"*seafile[1], "surface_upward_sensible_heat_flux", start=[1,1,1], count=[-1,-1,-1])
    sealhf = ncread(    "seaflux/"*seafile[1], "surface_upward_latent_heat_flux",   start=[1,1,1], count=[-1,-1,-1])

    (lon[a] < -180) && (lon[a] += 360)
    @printf("interpolating to %f %f\n",lat[a],lon[a])
    tmpvar = erashf[:,:,1] ; inter = CoordInterpGrid((lons,lats), tmpvar, BCnil, InterpNearest) ; res[1] = inter[lon[a], lat[a]]
    tmpvar = eralhf[:,:,1] ; inter = CoordInterpGrid((lons,lats), tmpvar, BCnil, InterpNearest) ; res[2] = inter[lon[a], lat[a]]
    tmpvar = ifrshf[:,:,1] ; inter = CoordInterpGrid((lons,lats), tmpvar, BCnil, InterpNearest) ; res[3] = inter[lon[a], lat[a]]
    tmpvar = ifrlhf[:,:,1] ; inter = CoordInterpGrid((lons,lats), tmpvar, BCnil, InterpNearest) ; res[4] = inter[lon[a], lat[a]]
    tmpvar = seashf[:,:,1] ; inter = CoordInterpGrid((lons,lats), tmpvar, BCnil, InterpNearest) ; res[5] = inter[lon[a], lat[a]]
    tmpvar = sealhf[:,:,1] ; inter = CoordInterpGrid((lons,lats), tmpvar, BCnil, InterpNearest) ; res[6] = inter[lon[a], lat[a]]
    if (-2500 <
    @printf("buoy %8.2f %8.2f\nera %8.2f %8.2f\nifr %8.2f %8.2f\nsea %8.2f %8.2f\n\n",x[a,1],x[a,2],res[1],res[2],res[3],res[4],res[5],res[6])
  else
    println(size(erafile))
    println(size(ifrfile))
    println(size(seafile))
  end
end
