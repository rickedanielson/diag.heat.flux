#=
 = Compute a COARE sensible and latent heat flux estimate for each observation.  Use Bolton (1980)
 = (cf. https://www.eol.ucar.edu/projects/ceop/dm/documents/refdata_report/eqns.html) to get vapour
 = pressure and in the flux calculation ignore cool skin, wave, and rain corrections - RD June 2015
 =#

pytest = false                                                                # include a python library check

using My, COARE
# using PyCall ; @pyimport cerform.flux.coare3 as coare3

if size(ARGS) == (0,)
  print("\nUsage: jjj $(basename(@__FILE__)) nq9901 nq9902 ... nq1102\n\n")
  exit(1)
end

for fila in ARGS
  filb = replace(fila, ".ncepnrt", ".flux")
  fpa = My.ouvre(fila, "r")
  fpb = My.ouvre(filb, "w")
  while !eof(fpa)                                                             # get deq (ssq saturation wrt SST) specific
    line = readline(fpa)                                                      # humidity in units of g/kg, as expected
    vals = split(line, ',')
    lat  = float(strip(vals[ 3]))
    lon  = float(strip(vals[ 4]))
    slp  = float(strip(vals[ 7]))
    dir  = float(strip(vals[ 8]))
    spd  = float(strip(vals[ 9]))
    air  = float(strip(vals[12]))
    dpt  = float(strip(vals[13]))
    sst  = float(strip(vals[15]))
    e    = 6.112 * exp((17.67 * dpt) / (dpt + 243.5)) ; deq = 1000.0 * (0.622 * e) / (slp - (0.378 * e))
    e    = 6.112 * exp((17.67 * sst) / (sst + 243.5)) ; ssq = 1000.0 * (0.622 * e) / (slp - (0.378 * e))
    if !pytest
      x    = [spd, 0, sst, air, ssq, deq, 0, 0, 0, 600, slp, 10, 10, 10, lat, 1, 0, 0, 0]
      (shf, lhf) = cor30a(x)
    else
      y    = Dict("u"  => spd, "us" =>   0, "ts" => sst, "t"  => air, "Qs" => ssq, "Q"   => deq, "Rs"    => 0, "Rl"    => 0, "rain"  => 0,
                  "zi" => 600, "P"  => slp, "zu" =>  10, "zt" =>  10, "zq" =>  10, "lat" => lat, "jcool" => 1, "jwave" => 0, "twave" => 0, "hwave" => 0)
      z    = coare3.coare3(y)
      shf = z[:"hsb"][1]
      lhf = z[:"hlb"][1]
#     if abs(shf) > 0.1 || abs(lhf) > 0.1  print("$shf $lhf\n")  end
    end
    bigline = @sprintf("%8.2f, %8.2f, %s", shf, lhf, line)
    write(fpb, bigline)
  end
  close(fpa)
  close(fpb)
end


#=
        "%8s %15s %7.3f %8.3f %4.1f %4.1f %8.2f %8.3f %8.3f %8.3f %8.3f %8.2f %8.2f %8.2f %8.2f\n",
           1       2        3        4        5        6       7        8      9      10        11       12      13       14      15
        hdr.id, datempa, hdr.lat, hdr.lon, rpt.sid, rpt.wi, rpt.slp, rpt.d, rpt.w, rpt.uwnd, rpt.vwnd, rpt.at, rpt.dpt, rpt.n, rpt.sst
11  15      F5.2    Latitude (degrees) -- negative = southern hemisphere
16  20      F5.2    Longitude (degrees) -- 0 to 360 West
21  22 I2 or 2I1    Report type; or BUFR file type and wind speed indicator*
23  28        A6    Station ID/ship call sign
29  32      F4.1    Sea level press minus 900.0 (mb)    missing=9999
33  35        I3    Wind direction (code=0 or 1-360 degs**)    missing=999
36  38        I3    Wind speed (knots)    missing=999
39  42      F4.1    Air temp (deg c)    missing=9999
43  45      F3.1    Dew point depression (deg c)    missing=999
46  46        A1    Cloud cover***    missing=9
47  49      F3.1    Sea surface temp (deg c)    missing=999

x = [5.5, 0, 28.7, 27.2, 24.2, 18.5, 141, 419, 0, 600, 1010, 15, 15, 15, 0, 1, 1, 5, 1]
u     = x[1]                    # wind speed (m/s) at height zu (m)
us    = x[2]                    # surface current speed in the wind direction (m/s)
ts    = x[3]                    # bulk water temperature (C) if jcool=1, interface water T if jcool=0
t     = x[4]                    # bulk air temperature (C), height zt
Qs    = x[5] / 1000.0           # bulk water spec hum (g/kg) if jcool=1, ...
Q     = x[6] / 1000.0           # bulk air spec hum (g/kg), height zq
Rs    = x[7]                    # downward solar flux (W/m^2)
Rl    = x[8]                    # downard IR flux (W/m^2)
rain  = x[9]                    # rain rate (mm/hr)
zi    = x[10]                   # PBL depth (m)
P     = x[11]                   # Atmos surface pressure (mb)
#zu    = x[12]                   # wind speed measurement height (m)
zt    = x[13]                   # air T measurement height (m)
zq    = x[14]                   # air q measurement height (m)
lat   = x[15]                   # latitude (deg, N=+)
jcool = x[16]                   # implement cool calculation skin switch, 0=no, 1=yes
jwave = x[17]                   # implement wave dependent roughness model
twave = x[18]                   # wave period (s)
hwave = x[19]                   # wave height (m)


    list_input_needed = ['u','us','ts','t','Qs','Q','Rs','Rl','rain','zi','P','zu','zt','zq','lat','jcool','jwave','twave','hwave']
    inputs_complet = complete_missing_args(list_input_needed,inputs)
    u=inputs_complet['u']
    us=inputs_complet['us']
    ts=inputs_complet['ts']
    t=inputs_complet['t']
    Qs=inputs_complet['Qs']
    Q=inputs_complet['Q']
    Rs=inputs_complet['Rs']
    Rl=inputs_complet['Rl']
    rain=inputs_complet['rain']
    zi=inputs_complet['zi']
    P=inputs_complet['P']
    zu=inputs_complet['zu']
    zt=inputs_complet['zt']
    zq=inputs_complet['zq']
    lat=inputs_complet['lat']
    jcool=inputs_complet['jcool']
    jwave=inputs_complet['jwave']
    twave=inputs_complet['twave']
    hwave=inputs_complet['hwave']
y = [hsb, hlb, tau, zo, zot, zoq, L, usr, tsr, qsr, dter, dqer, tkt, RF, wbar, Cd, Ch, Ce, Cdn_10, Chn_10, Cen_10, ug ]
    res = {}
    res['hsb'] = hsb
    res['hlb'] = hlb
    res['tau'] = tau
    res['zo'] = zo
    res['zot'] = zot
    res['zoq'] = zoq
    res['L'] = L
    res['usr'] = usr
    res['tsr'] = tsr
    res['qsr'] = qsr
    res['dter'] = dter
    res['dqer'] = dqer
    res['tkt'] = tkt
    res['RF'] = RF
    res['wbar'] = wbar
    res['Cd'] = Cd
    res['Ch'] = Ch
    res['Ce'] = Ce
    res['Cdn_10'] = Cdn_10
    res['Chn_10'] = Chn_10
    res['Cen_10'] = Cen_10
    res['ug'] = ug
    return res
=#
