#=
 = Loop through all analyses and visualize the availability of heat
 = flux values at the position of interest - RD September 2015
 =#

using My, Winston
const VARS             = 24
const LINES            = 45032
const MISS             = -9999.0                        # generic missing value

if size(ARGS) != (1,)
  print("\nUsage: jjj $(basename(@__FILE__)) all.flux.combined\n\n")
  exit(1)
end

data = Array(Float64, LINES, VARS)                                            # allocate for all days between

fpa = My.ouvre(ARGS[1], "r")
a = airt = wspd = sstt = 0
for line in eachline(fpa)
  a += 1
  vals = split(line)
  for b = 1:VARS
    data[a,b] = float(strip(vals[b]))
  end
  airt += data[a,7]
  wspd += data[a,6]
  sstt += data[a,8]
end
close(fpa)
count = a

airt /= count ; airt = @sprintf "%.1f" airt
wspd /= count ; wspd = @sprintf "%.1f" wspd
sstt /= count ; sstt = @sprintf "%.1f" sstt

#tmpb = "...."*ARGS[1][18:end]
(refa, refw, refs) = float(split(replace("...."*ARGS[1][18:end], r"[\.]{2,}", " ")))

xyzzy = "plot.$(ARGS[1]).png"
print("writing $xyzzy\n")

tmp      = Table(3,1)
tmp[1,1] = Winston.plothist(data[1:count,7], xrange = (-30,35), title="Air temperature ($count obs)  mean $airt  target $refa")
tmp[2,1] = Winston.plothist(data[1:count,6], xrange = (  0,35), title="Wind speed ($count obs)  mean $wspd  target $refw")
tmp[3,1] = Winston.plothist(data[1:count,8], xrange = (  0,35), title="SST ($count obs)  mean $sstt  target $refs")
#          Winston.DataLabel(20, 40, "asfd", "textangle", 90.0, "texthalign", "right", "size", 1.1)
           Winston.savefig(tmp, xyzzy, "width", 1000, "height", 1700)
exit(0)

#=
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
=#

#=
xlab = Array(ASCIIString, 0)                                                  # initialize the date label strings
xpos = Array(      Int64, 0)                                                  # (first date and then first day of
date = "1999-10-01"                                                           #  each subsequent year)
push!(xlab, "1 Oct\n$(date[1:4])") ; push!(xpos, 1)
for a = 2:3745
  date = dateadd(date, 1, "dy")
  if date[6:10] == "01-01" && date[1:4] != "2000"
    push!(xlab, date[1:4]) ; push!(xpos, a)
ppp = Winston.add(tmp)
      Winston.savefig(ppp, xyzzy, "width", 1700, "height", 1000)
  end
end  =#

#dirs = ["cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux", "insitu"]


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
