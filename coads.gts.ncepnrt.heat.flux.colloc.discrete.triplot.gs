* This script is designed to plot cyclone location and intensity (colour code).
* It can be executed using a command like
*
*     grads -blc "coads.gts.ncepnrt.heat.flux.colloc.discrete.triplot 55.000 75.000 -40.000 30.000 1"
*
* - RD November 2012

function plot(arg)
minlat = subwrd(arg,1)
maxlat = subwrd(arg,2)
minlon = subwrd(arg,3)
maxlon = subwrd(arg,4)
reftim = subwrd(arg,5)
cenlat = (minlat + maxlat) / 2
cenlon = (minlon + maxlon) / 2

z2 = 0 ; z1 = (maxlat - minlat) / 4
if(z2=0&z1>50.00);z2=50.00;endif;if(z2=0&z1>30.00);z2=30.00;endif;if(z2=0&z1>20.00);z2=20.00;endif;if(z2=0&z1>15.000);z2=15.000;endif;if(z2=0&z1>10.00);z2=10.00;endif
if(z2=0&z1> 5.00);z2= 5.00;endif;if(z2=0&z1> 3.00);z2= 3.00;endif;if(z2=0&z1> 2.00);z2= 2.00;endif;if(z2=0&z1> 1.500);z2= 1.500;endif;if(z2=0&z1> 1.00);z2= 1.00;endif
if(z2=0&z1> 0.50);z2= 0.50;endif;if(z2=0&z1> 0.30);z2= 0.30;endif;if(z2=0&z1> 0.20);z2= 0.20;endif;if(z2=0&z1> 0.150);z2= 0.150;endif;if(z2=0&z1> 0.10);z2= 0.10;endif
if(z2=0&z1> 0.05);z2= 0.05;endif;if(z2=0&z1> 0.03);z2= 0.03;endif;if(z2=0&z1> 0.02);z2= 0.02;endif;if(z2=0&z1> 0.015);z2= 0.015;endif;if(z2=0&z1> 0.01);z2= 0.01;endif
dellat = z2
z2 = 0 ; z1 = (maxlon - minlon) / 4
if(z2=0&z1>50.00);z2=50.00;endif;if(z2=0&z1>30.00);z2=30.00;endif;if(z2=0&z1>20.00);z2=20.00;endif;if(z2=0&z1>15.000);z2=15.000;endif;if(z2=0&z1>10.00);z2=10.00;endif
if(z2=0&z1> 5.00);z2= 5.00;endif;if(z2=0&z1> 3.00);z2= 3.00;endif;if(z2=0&z1> 2.00);z2= 2.00;endif;if(z2=0&z1> 1.500);z2= 1.500;endif;if(z2=0&z1> 1.00);z2= 1.00;endif
if(z2=0&z1> 0.50);z2= 0.50;endif;if(z2=0&z1> 0.30);z2= 0.30;endif;if(z2=0&z1> 0.20);z2= 0.20;endif;if(z2=0&z1> 0.150);z2= 0.150;endif;if(z2=0&z1> 0.10);z2= 0.10;endif
if(z2=0&z1> 0.05);z2= 0.05;endif;if(z2=0&z1> 0.03);z2= 0.03;endif;if(z2=0&z1> 0.02);z2= 0.02;endif;if(z2=0&z1> 0.015);z2= 0.015;endif;if(z2=0&z1> 0.01);z2= 0.01;endif
dellon = z2
*fpz = "xyzzy.forgetit" ; "!echo $HOME > "fpz ; line = read(fpz) ; home = sublin(line,2) ; ret = close(fpz) ; "!rm "fpz

"clear"
"set grid off"
"set mpt * off"
"set clopts 1 6 .20"
"set xlopts 1 6 .20"
"set ylopts 1 6 .20"
"set xlint "dellon
"set ylint "dellat
"set mproj off"

"set rgb  51 255 255 255"
"set rgb  52 255 240 150"
"set rgb  53 215 160 160"
"set rgb  54 255 120 120"
"set rgb  55 175  80  80"
"set rgb  56 255  40  40"
"set rgb  88   0   0 208" ;* default best track colour
"set rgb  99 200 200 200" ;* default land colour

*"sdfopen /home/ricani/data/topography/elev.0.25-deg.nc"
*"set lat "minlat" "maxlat
*"set lon "minlon" "maxlon
*"set gxout shaded"
*"set ccols  51    52   53   54   99"
*"set clevs    -1000 -500 -100   0"
*"set grads off" ; "set clab off" ; "d data"
*"q gxinfo" ; _gxinfo = result ; "q shades" ; _shadea = result
*"run basemap L 99 1"
*"set gxout contour"
*"close 1"

"open /home/ricani/work/works/ifremerflux_2005/ifremerflux.ctl"
"set t "reftim
"set lat "minlat" "maxlat
"set lon "minlon" "maxlon
"set gxout shaded"
"set ccols  9   4   5   3   7    8"
"set clevs   25   50  75 100  125"
"set grads off" ; "set clab off" ; "d 0.22812659*air*air - 0.21859154*spd*spd + 0.30715734*(sst-273.15)*(sst-273.15) - 0.14577318*air*spd - 0.58272658*air*(sst-273.15) + 0.13243353*spd*(sst-273.15) - 7.04641458*air + 6.11999371*spd + 7.63826821*(sst-273.15) +  2.68540473"
"q gxinfo" ; _gxinfo = result ; "q shades" ; _shadea = result
"set gxout contour"
"run basemap L 99 1"
"set grads off"
"set string 1 c 6"
"set strsiz 0.25 0.25"
"set line 15 1 7"
"set gxout stream"
"set ccols   51  52  53  54  55  56"
"set clevs     1   5  10  15  20"
"set strmden -5 9.0 0.1 1" ; "set cthick 4"
"d u;v;mag(u,v)"
"q gxinfo" ; _gxinfo = result ; "q shades" ; _shadeb = result

"run gui_date_simple" ; date = result
"set string 1 c 6"
"set strsiz 0.23"
"draw string 3.85 8.25 SHF RMSE (Wm`a-2`n) "date

"set strsiz 0.13"
"set string 1 bc 5"
"set grads off" ; inner_cbarn("0.60 0 9.25 8.30 a")
*"set grads off" ; inner_cbarn("0.60 0 2.00 8.30 b")

                 tval = "00"reftim
if reftim >  9 ; tval =  "0"reftim ; endif
if reftim > 99 ; tval =     reftim ; endif
say "gxprint coads.gts.ncepnrt.heat.flux.colloc.discrete.triplot."tval".png png white x1100 y850"
    "gxprint coads.gts.ncepnrt.heat.flux.colloc.discrete.triplot."tval".png png white x1100 y850"
"quit"

*   res  = coef[1] * varair[i] * varair[i] + coef[2] * varspd[i] * varspd[i] + coef[3] * varsst[i] * varsst[i] +
*          coef[4] * varair[i] * varspd[i] + coef[5] * varair[i] * varsst[i] + coef[6] * varspd[i] * varsst[i] +
*          coef[7] * varair[i]             + coef[8] * varspd[i]             + coef[9] * varsst[i] + coef[10]
*     1.58142453*air*air + 0.21192243*spd*spd + 1.67550186*sst*sst - 0.41619424*air*spd - 3.24287984*air*sst + 0.45987590*spd*sst + 1.70888986*air - 3.84710777*spd - 2.46165525*sst + 18.81675320
*    -0.03783432*air*air + 0.02171992*spd*spd - 0.03027189*sst*sst - 0.01635796*air*spd + 0.07194274*air*sst + 0.01944569*spd*sst + 0.03169998*air - 0.51312824*spd - 0.18250736*sst +  4.20293794
*     0.22812659*air*air - 0.21859154*spd*spd + 0.30715734*sst*sst - 0.14577318*air*spd - 0.58272658*air*sst + 0.13243353*spd*sst - 7.04641458*air + 6.11999371*spd + 7.63826821*sst +  2.68540473
*    -0.03947466*air*air + 0.00270543*spd*spd - 0.03975109*sst*sst + 0.00189707*air*spd + 0.07981320*air*sst - 0.00087165*spd*sst - 0.19026551*air - 0.06386870*spd + 0.16114838*sst +  0.80171620


function inner_cbarn(args)
  sf  =subwrd(args,1)
  vert=subwrd(args,2)
  xmid=subwrd(args,3)
  ymid=subwrd(args,4)
  svar=subwrd(args,5)

  if(sf='');sf=1.0;endif
*
*  Check shading information
*
*  'query shades'
  if (svar = "a") ; shdinfo = _shadea ; endif
  if (svar = "b") ; shdinfo = _shadeb ; endif
* if (svar = "c") ; shdinfo = _shadec ; endif
* say shdinfo
* shdinfo = _shades
  if (subwrd(shdinfo,1)='None')
    say 'Cannot plot color bar: No shading information'
    return
  endif

*
*  Get plot size info
*
  "set vpage off"
  'query gxinfo'
*  result = _gxinfo
*say result
  rec2 = sublin(result,2)
  rec3 = sublin(result,3)
  rec4 = sublin(result,4)
  xsiz = subwrd(rec2,4)
  ysiz = subwrd(rec2,6)
  ylo = subwrd(rec4,4)
  xhi = subwrd(rec3,6)
  xd = xsiz - xhi

  ylolim=0.6*sf
  xdlim1=1.0*sf
  xdlim2=1.5*sf
  barsf=0.8*sf
  yoffset=0.2*sf
  stroff=0.1*sf
  strxsiz=0.17*sf
  strysiz=0.18*sf
*
*  Decide if horizontal or vertical color bar
*  and set up constants.
*
  if (ylo<ylolim & xd<xdlim1)
    say "Not enough room in plot for a colorbar"
    return
  endif
  cnum = subwrd(shdinfo,5)
*
*       logic for setting the bar orientation with user overides
*
  if (ylo<ylolim | xd>xdlim1)
    vchk = 1
    if(vert = 0) ; vchk = 0 ; endif
  else
    vchk = 0
    if(vert = 1) ; vchk = 1 ; endif
  endif
*
*       vertical bar
*

  if (vchk = 1 )

    if(xmid = '') ; xmid = xhi+xd/2 ; endif
    xwid = 0.2*sf
    ywid = 0.5*sf

    xl = xmid-xwid/2
    xr = xl + xwid
    if (ywid*cnum > ysiz*barsf)
      ywid = ysiz*barsf/cnum
    endif
    if(ymid = '') ; ymid = ysiz/2 ; endif
    yb = ymid - ywid*cnum/2
#RD    'set string 1 l'
    'set string 1 r'
    vert = 1

  else

*
*       horizontal bar
*

    ywid = 0.4
    xwid = 0.63

    if(ymid = '') ; ymid = ylo/2-ywid/2 ; endif
    yt = ymid + yoffset
    yb = ymid
    if(xmid = '') ; xmid = xsiz/2 ; endif
    if (xwid*cnum > xsiz*barsf)
      xwid = xsiz*barsf/cnum
    endif
    xl = xmid - xwid*cnum/2
    'set string 1 tc'
    vert = 0
  endif


*
*  Plot colorbar
*


* 'set strsiz 'strxsiz' 'strysiz
  num = 0
  while (num<cnum)
    rec = sublin(shdinfo,num+2)
*RD    rec = sublin(shdinfo,num+20)
    col = subwrd(rec,1)
    hi = subwrd(rec,3)
    if (vert)
      yt = yb + ywid
    else
      xr = xl + xwid
    endif

*   Draw the left/bottom triangle
    if (num = 0)
      if(vert = 1)
        xm = (xl+xr)*0.5
        'set line 'col
        'draw polyf 'xl' 'yt' 'xm' 'yb' 'xr' 'yt' 'xl' 'yt
        'set line 1 1'
        'draw line 'xl' 'yt' 'xm' 'yb
        'draw line 'xm' 'yb' 'xr' 'yt
        'draw line 'xr' 'yt' 'xl' 'yt
      else
        ym = (yb+yt)*0.5
        'set line 'col
        'draw polyf 'xl' 'ym' 'xr' 'yb' 'xr' 'yt' 'xl' 'ym
        'set line 1 1'
        'draw line 'xl' 'ym' 'xr' 'yb
        'draw line 'xr' 'yb' 'xr' 'yt
        'draw line 'xr' 'yt' 'xl' 'ym
      endif
    endif

*   Draw the middle boxes
    if (num!=0 & num!= cnum-1)
      'set line 'col
      'draw recf 'xl' 'yb' 'xr' 'yt
      'set line 1 1'
      'draw rec  'xl' 'yb' 'xr' 'yt
    endif

*   Draw the right/top triangle
    if (num = cnum-1)
      if (vert = 1)
        'set line 'col
        'draw polyf 'xl' 'yb' 'xm' 'yt' 'xr' 'yb' 'xl' 'yb
        'set line 1 1'
        'draw line 'xl' 'yb' 'xm' 'yt
        'draw line 'xm' 'yt' 'xr' 'yb
        'draw line 'xr' 'yb' 'xl' 'yb
      else
        'set line 'col
        'draw polyf 'xr' 'ym' 'xl' 'yb' 'xl' 'yt' 'xr' 'ym
        'set line 1 1'
        'draw line 'xr' 'ym' 'xl' 'yb
        'draw line 'xl' 'yb' 'xl' 'yt
        'draw line 'xl' 'yt' 'xr' 'ym
      endif
    endif

*   Put numbers under each segment of the color key
    if (num < cnum-1)
      if (vert)
#RD        xp=xr+stroff
        xp=xl-stroff
        'draw string 'xp' 'yt' 'hi
      else
        yp=yb-stroff
       'draw string 'xr' 'yp' 'hi
      endif
    endif

*   Reset variables for next loop execution
    if (vert)
      yb = yt
    else
      xl = xr
    endif
    num = num + 1
  endwhile
return
