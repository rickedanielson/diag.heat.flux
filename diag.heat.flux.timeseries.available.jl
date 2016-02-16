#=
 = Loop through all analyses and visualize the availability of heat
 = flux values at the position of interest - RD September 2015
 =#

using My, Winston
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  write("\nUsage: jjj $(basename(@__FILE__)) ....45.000...-45.500\n\n")
  exit(1)
end

shfx = Array(Float64, 1800, 3745)                                             # allocate for all days between
lhfx = Array(Float64, 1800, 3745)                                             # 1999-10-01 and 2009-12-31

dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "j-ofuro", "merra", "oaflux", "seaflux", "insitu"]

for (a, dir) in enumerate(dirs)                                               # and read the daily fluxes
  fila = "$dir/$dir$(ARGS[1])"
  fpa = My.ouvre(fila, "r")
  lines = readlines(fpa)
  close(fpa)
  for (b, linb) in enumerate(lines)
    vals = float(split(linb))
    shfx[a,b] = -333 < vals[2] < 3333 ? 1.0 : 0.0
    lhfx[a,b] = -333 < vals[3] < 3333 ? 1.0 : 0.0
  end
end

for a = 1:3745                                                                # map each dir to a thick line
  shfx[1701:1800,a] = shfx[9,a] ; shfx[1601:1700,a] = lhfx[9,a]
  shfx[1501:1600,a] = shfx[8,a] ; shfx[1401:1500,a] = lhfx[8,a]
  shfx[1301:1400,a] = shfx[7,a] ; shfx[1201:1300,a] = lhfx[7,a]
  shfx[1101:1200,a] = shfx[6,a] ; shfx[1001:1100,a] = lhfx[6,a]
  shfx[ 901:1000,a] = shfx[5,a] ; shfx[ 801: 900,a] = lhfx[5,a]
  shfx[ 701: 800,a] = shfx[4,a] ; shfx[ 601: 700,a] = lhfx[4,a]
  shfx[ 501: 600,a] = shfx[3,a] ; shfx[ 401: 500,a] = lhfx[3,a]
  shfx[ 301: 400,a] = shfx[2,a] ; shfx[ 201: 300,a] = lhfx[2,a]
  shfx[ 101: 200,a] = shfx[1,a] ; shfx[   1: 100,a] = lhfx[1,a]
end

#=
fila = "insitu/insitu$(ARGS[1])"
fpa = My.ouvre(fila, "r")
lines = readlines(fpa)
close(fpa)
for (b, linb) in enumerate(lines)
  vals = float(split(linb))
  if -333 < vals[2] < 3333
    for c = b-0:b+0
      if shfx[1501,c] == 1  shfx[1501:1600,c] = -1  end
      if shfx[1301,c] == 1  shfx[1301:1400,c] = -1  end
      if shfx[1101,c] == 1  shfx[1101:1200,c] = -1  end
      if shfx[ 901,c] == 1  shfx[ 901:1000,c] = -1  end
      if shfx[ 701,c] == 1  shfx[ 701: 800,c] = -1  end
      if shfx[ 501,c] == 1  shfx[ 501: 600,c] = -1  end
      if shfx[ 301,c] == 1  shfx[ 301: 400,c] = -1  end
      if shfx[ 101,c] == 1  shfx[ 101: 200,c] = -1  end
    end
  end
  if -333 < vals[3] < 3333
    for c = b-0:b+0
      if shfx[1401,c] == 1  shfx[1401:1500,c] = -1  end
      if shfx[1201,c] == 1  shfx[1201:1300,c] = -1  end
      if shfx[1001,c] == 1  shfx[1001:1100,c] = -1  end
      if shfx[ 801,c] == 1  shfx[ 801: 900,c] = -1  end
      if shfx[ 601,c] == 1  shfx[ 601: 700,c] = -1  end
      if shfx[ 401,c] == 1  shfx[ 401: 500,c] = -1  end
      if shfx[ 201,c] == 1  shfx[ 201: 300,c] = -1  end
      if shfx[   1,c] == 1  shfx[   1: 100,c] = -1  end
    end
  end
end
=#

# shfx = lhfx = int(rand(1800, 3745) .> 0.5)

xlab = Array(ASCIIString, 0)                                                  # initialize the date label strings
xpos = Array(      Int64, 0)                                                  # (first date and then first day of
date = "1999-10-01"                                                           #  each subsequent year)
push!(xlab, "1 Oct\n$(date[1:4])") ; push!(xpos, 1)
for a = 2:3745
  date = dateadd(date, 1, "dy")
  if date[6:10] == "01-01" && date[1:4] != "2000"
    push!(xlab, date[1:4]) ; push!(xpos, a)
  end
end

xyzzy = "plot.avail$(ARGS[1]).png"
write("writing $xyzzy\n")
Colors.colormap("Blues", 3)
tmp = Winston.imagesc(shfx)
setattr(tmp.x2, "ticks",           xpos) ; setattr(tmp.x1, "draw_nothing",    true)
setattr(tmp.x2, "tickdir",            1) ; setattr(tmp.x1, "tickdir",            1)
setattr(tmp.x2, "ticklabels",      xlab) ; setattr(tmp.x1, "draw_ticks",     false)
setattr(tmp.x2, "draw_subticks",  false) ; setattr(tmp.x1, "draw_subticks",  false)
#setattr(tmp.x1, "ticklabels_style.rotation", "90")
setattr(tmp.y1, "ticks", [100:200:1700])#; setattr(tmp.y2, "ticks", [100:200:1700])
setattr(tmp.y1, "tickdir",            1) ; setattr(tmp.y2, "tickdir",            1)
setattr(tmp.y1, "ticklabels",      dirs) ; setattr(tmp.y2, "draw_ticks",     false)
setattr(tmp.y1, "draw_subticks",  false) ; setattr(tmp.y2, "draw_subticks",  false)
ppp = Winston.add(tmp)
      Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
exit(0)






#=
for (a, label) in enumerate(xlab)
  tmp = Winston.DataLabel(xpos[a], 0, xlab[a], "textangle", 90.0, "texthalign", "left", "size", 1.1)
        Winston.add(ppp, tmp)
end

using Gadfly
plt = spy(shfx)
draw(PNG(xyzzy, 170cm, 70cm), plt)
#plot(dataset("Zelig", "macro"), x="Year", y="Country", color="GDP", Geom.rectbin)

using PyPlot
PyPlot.matshow(shfx)
#PyPlot.title("Temporal coverage of TIE-OHF reference data (SHF at 45N,45W)")
PyPlot.xticks(xpos, xlab, rotation = 90)
PyPlot.yticks([100:200:1500], dirs)
#PyPlot.ylabel("Reference data (SHF/LHF)")
PyPlot.savefig(xyzzy)

PyPlot.xaxis.set_label_coords(0.5, -0.1)
@pyimport 
plt.figure(2)
ax1 = plt.axes([0,0,1,0.5])
ax2 = plt.axes([0,0.5,1,0.5])
ax1.set_yticks([0.5])
ax1.set_yticklabels(["very long label"])
ax1.set_ylabel("Y label")
ax2.set_title("Title")
make_axes_area_auto_adjustable(ax1, pad=0.1, use_axes=[ax1, ax2])
make_axes_area_auto_adjustable(ax2, pad=0.1, use_axes=[ax1, ax2])

using Winston
#tmp = Winston.FramedPlot(
#        title="Availability of SHF data",
#        xlabel="Days after launch", # xrange = (0,25),
#        ylabel="Cumulative skill") #,  yrange = (-0.1,1.0))
#ppp = Winston.add(tmp)
#for a = 1:4:LEN
#  tmp = Winston.DataLabel(hours[a], 240, "$(int(disnum[a]))", "textangle", 90.0, "texthalign", "right", "size", 1.1)
#        Winston.add(ppp, tmp)
#end
tmp = Winston.imagesc(shfx)
ppp = Winston.add(tmp)
      Winston.savefig(ppp, xyzzy, "width", 1700, "height", 700)
exit(0)
=#
