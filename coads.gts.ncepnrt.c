/*
 * This program is designed to isolate NRT GTS obs within a
 * specific time and space domain - RD Dec 2004, May 2011.
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "/home/ricani/prog/include.netcdf/include/coadstruct.h"

#define LEN        100
#define LOTS       500
#define D2R        (3.141592654/180.0)       /* degrees to radians conversion */
#define SEARCH     180                       /* search minutes before and after reference time */
#define BORDER     2.5                       /* expansion of SAR domain in lat and lon (degrees) */
#define OBSMISS    -999.0                    /* observational missing value */

main (int argc, char *argv[])
{
    FILE *fpa, *fpb, *fpc, *fpd, *fopen();
    int a, b, c, d, count, lines, pos, chs;
    char infile[LEN], outfile[LEN], datafile[LEN], datbfile[LEN];
    char line[LOTS], tag[LEN], date[LEN], datempa[LEN], datempb[LEN], tmp[LEN];
    float maxlat, minlat, maxlon, minlon, inlat, inlon;
    struct header hdr;  struct report rpt;
    double delmin, delmina, delminb;

    if (argc != 2) {
      printf("Usage: %s nq0503\n",argv[0]);
      exit(1);
    }

    minlat =   10.0;                                                          /* set the search domain */
    maxlat =   17.5;
    minlon =  -99.0;
    maxlon =  -92.5;

    strcpy(infile,argv[1]);                                                   /* and open all files then */
    strcpy(outfile,argv[1]);
    strcat(outfile,".ncepnrt");
    if ((fpa = fopen(infile,"r")) == NULL || (fpb = fopen(outfile,"w")) == NULL) {
      fprintf(stderr,"ERROR : couldn't open %s or %s\n",infile,outfile);
      exit(1);
    }

    count = lines = 0;
    while (fgets(line,LOTS,fpa) != NULL) {                                    /* loop through the input data and */
      getrptnrt(line, &rpt);                                                  /* save any valid ncepnrt obs */
      getdatenrt(line,datempa);
      pos = 10;  chs = 5;  strncpy(tmp,line+pos,chs);  tmp[chs] = '\0';
      hdr.lat = (float)atoi(tmp) / 100.0;
      pos = 15;  chs = 5;  strncpy(tmp,line+pos,chs);  tmp[chs] = '\0';
      hdr.lon = (float)atoi(tmp) / -100.0;
      pos = 20;  chs = 1;  strncpy(tmp,line+pos,chs);  tmp[chs] = '\0';
      rpt.sid = (float)atoi(tmp);
      pos = 21;  chs = 1;  strncpy(tmp,line+pos,chs);  tmp[chs] = '\0';
      rpt.wi  = (float)atoi(tmp);
      pos = 22;  chs = 6;  strncpy(tmp,line+pos,chs);  tmp[chs] = '\0';
      strcpy(hdr.id,tmp);
      if (rpt.slp < 880 || rpt.slp >   1080 ||
          rpt.w   <   0 || rpt.w   >     50 ||
          rpt.at  < -40 || rpt.at  >     40 ||
          rpt.dpt < -40 || rpt.dpt > rpt.at ||
          rpt.sst <  -2 || rpt.sst >     40)
        rpt.sst = OBSMISS;
      if (hdr.id[0] > 47 && hdr.id[0] < 58 &&
          hdr.id[1] > 47 && hdr.id[1] < 58 &&
          hdr.id[2] > 47 && hdr.id[2] < 53 &&
          hdr.id[3] > 47 && hdr.id[3] < 58 &&
          hdr.id[4] > 47 && hdr.id[4] < 58 &&
          hdr.id[5] == ' ' &&
          rpt.d   != OBSMISS && rpt.w   != OBSMISS &&
          rpt.at  != OBSMISS && rpt.dpt != OBSMISS &&
          rpt.sst != OBSMISS && rpt.slp != OBSMISS) {
/*        hdr.lat <= maxlat  && hdr.lat >= minlat &&
          hdr.lon <= maxlon  && hdr.lon >= minlon &&  */
        hdr.id[5] = ',';
        fprintf(fpb,
          "%8s %15s, %7.3f, %8.3f, %4.1f, %4.1f, %8.2f, %8.3f, %8.3f, %8.3f, %8.3f, %8.2f, %8.2f, %8.2f, %8.2f\n",
          hdr.id, datempa, hdr.lat, hdr.lon, rpt.sid, rpt.wi, rpt.slp, rpt.d, rpt.w,
          rpt.uwnd, rpt.vwnd, rpt.at, rpt.dpt, rpt.n, rpt.sst);
        count++;
      }
      lines++;
    }
    fclose(fpb);
    fclose(fpa);

    printf("read  %s with %d lines\n",infile,lines);
    printf("wrote %s with %d valid obs\n",outfile,count);
    exit(0);
}

/*
Column     Format    Field
from  to                                                             
===============================================================================
   1   2        I2    Year (last two digits: 1999 = '99'; 2000 = '00') (UTC)
   3   4        I2    Month (UTC)
   5   6        I2    Day (UTC)
   7  10      F4.2    Hour (UTC)
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
*/
