/*
 * Identify all sets of valid collocations among grids (excluding the
 * in situ) so as to better compare spectral tails - RD October 2015
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "prog/include.netcdf/include/genalloc.h"

#define LEN        100
#define LOTS       500
#define D2R        (3.141592654/180.0)       /* degrees to radians conversion */

#define CUTOFF     2000                      /* minimum number of daily estimates from all analyses */
#define LAGS       3                         /* extrapolation from 0=before, 1=now, 2=after */
#define ESTS       8                         /* number of heat flux estimates */
#define POSS       4793                      /* number of locations with available timeseries */
#define DAYS       3745                      /* number of days between 1999-10-01 and 2009-12-31 */
#define MISS      -9999.0                    /* generic missing value */

int      datref[DAYS];
char     posnam[POSS][LEN];
/*float shf[LAGS][ESTS][POSS][DAYS], poslat[POSS];
  float lhf[LAGS][ESTS][POSS][DAYS], poslon[POSS]; */
float    poslat[POSS], poslon[POSS], posdup[POSS];

main (int argc, char *argv[])
{
    FILE *fpa, *fpb, *fpc, *fpd, *fopen();
    int a, b, c, d, count, lines, pos, chs, chkdat, dayind, llind, flag;
    int yr, mo, dy, hr, posnum, daynum, obsnum, colnum, posind, latind, lonind;
    char infile[LEN], outfile[LEN], datafile[LEN], datbfile[LEN];
    char line[LOTS], lina[LEN], linb[LEN], linc[LEN], lind[LEN];
    char date[LEN], datempa[LEN], datempb[LEN], tmp[LEN];
    float inshf, inlhf, inlat, inlon, grdlat, grdlon, lldel, llmin, ****shf, ****lhf;
    char *dir[ESTS] = {"cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux"};
    char *lagnam[LAGS] = {".bef", "", ".aft"};

    if (argc != 2) {
      printf("Usage: %s all.flux.common\n",argv[0]);
      exit(1);
    }

    strcpy(date, "1999-10-01-00");
    for (a = 0; a < DAYS; a++) {
      sscanf(date, "%d-%d-%d-%d", &yr, &mo, &dy, &hr);
      datref[a] = 10000 * yr + 100 * mo + dy;
      dateshift(date, 24);
    }

    strcpy(infile, "all.flux.locate");                                        /* read all position file endings */
    printf("reading %s\n", infile);
    if ((fpa = fopen(infile,"r")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open %s\n", infile);
      exit(1);
    }
    posnum = 0;
    while (fgets(line,LEN,fpa) != NULL) {
      sscanf(line, "%f, %f, %f", &poslat[posnum], &poslon[posnum], &posdup[posnum]);
      sprintf(tmp, ".%9.3f.%9.3f",poslat[posnum], poslon[posnum]);
      for (a = 0; a < LEN; a++)  if (tmp[a] == ' ') tmp[a] = '.';
      strcpy(posnam[posnum], tmp);
/*    if (strcmp(posnam[posnum], "....55.000...-12.500") == 0) posdup[posnum] = 9e9;  */
      posnum++;
    }
    if (posnum != POSS) {fprintf(stderr, "ERROR : read %d positions\n", posnum) ; exit(1);}
    fclose(fpa);

    get_mem4Dfloat(&shf, LAGS, ESTS, POSS, DAYS);                             /* allocate the full grids */
    get_mem4Dfloat(&lhf, LAGS, ESTS, POSS, DAYS);

    for (d = 1; d < LAGS-1; d++)
      for (a = 0; a < ESTS; a++) {                                            /* then read the heat fluxes */
        printf("reading %s\n", dir[a]);
        for (b = 0; b < POSS; b++) {
          sprintf(infile, "%s/%s%s%s", dir[a], dir[a], posnam[b], lagnam[d]);
          if ((fpa = fopen(infile,"r")) == NULL) {
            fprintf(stderr, "ERROR : couldn't open %s\n", infile);
            exit(1);
          }
          daynum = 0;
          while (fgets(lina,LEN,fpa) != NULL) {
            sscanf(lina, "%*s %f %f", &shf[d][a][b][daynum], &lhf[d][a][b][daynum]);
            daynum++;
          }
          if (daynum != DAYS) {fprintf(stderr, "ERROR : read %d days\n", daynum) ; exit(1);}
          fclose(fpa);
        }
      }
/*  printf("requiring >= %d collocations passes %d of %d locations\n", CUTOFF, posnum / ESTS, POSS); */

    strcpy( infile, "all.flux.locate.min2000");                               /* and identify locations with good timeseries */
    strcpy(outfile, "all.flux.locate.min2000.pos");                           /* (i.e., where all analyses are available on */
    printf("writing %s\nwriting %s\n", infile, outfile);                      /*  at least CUTOFF days) and store just the */
    if ((fpa = fopen(infile,"w")) == NULL || (fpb = fopen(outfile,"w")) == NULL) {  /* position endings as well */
      fprintf(stderr, "ERROR : couldn't open %s or %s\n", infile, outfile);
      exit(1);
    }
    posnum = 0;
    for (a = 0; a < POSS; a++) {
      obsnum = 0;
      for (b = 0; b < DAYS; b++) {
        flag = 1;
        for (c = 0; c < ESTS; c++)
          if (shf[1][c][a][b] < -333 || shf[1][c][a][b] > 3333) flag = 0;
        if (flag == 1) obsnum++;
      }
      if (obsnum >= CUTOFF) posnum++;
      if (obsnum <  CUTOFF) posdup[a] *= -1.0;
      fprintf(fpa, "%8.2f,%8.2f, %.6f\n", poslat[a], poslon[a], posdup[a]);
      if (posdup[a] > 0) fprintf(fpb, "%s\n", posnam[a]);
    }
    printf("found %d positions (out of %d) with more than %d valid days in the collocated SHF timeseries\n", posnum, POSS, CUTOFF);
    fclose(fpa);
    fclose(fpb);

    strcpy(datafile, argv[1]) ; strcat(datafile, ".shf.mask");                /* then get the percentage of good-timeseries */
    strcpy(datbfile, argv[1]) ; strcat(datbfile, ".lhf.mask");                /* locations that are actually good on each day */
    printf("writing %s and %s\n", datafile, datbfile);
    if ((fpa = fopen(datafile,"w")) == NULL || (fpb = fopen(datbfile,"w")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open either %s or %s\n", datafile, datbfile);
      exit(1);
    }

    daynum = 0;
    for (a = 0; a < DAYS; a++) {
      obsnum = 0;
      for (b = 0; b < POSS; b++)
        if (posdup[b] > 0) {
          flag = 1;
          for (c = 0; c < ESTS; c++)
            if (shf[1][c][b][a] < -333 || shf[1][c][b][a] > 3333) flag = 0;
          if (flag == 1) obsnum++;
        }
      fprintf(fpa, "%d %5d %5d %5.1f\n", datref[a], obsnum, posnum, 100.0 * (float)obsnum / (float)posnum);
      if (obsnum == posnum) daynum++;
    }
    printf("found %d perfectly valid SHF collocations (out of %d) in %s\n", daynum, DAYS, datafile);
    fclose(fpa);

    daynum = 0;                                                               /* (and for LHF we ignore CFSR entirely) */
    for (a = 0; a < DAYS; a++) {
      obsnum = 0;
      for (b = 0; b < POSS; b++)
        if (posdup[b] > 0) {
          flag = 1;
          for (c = 1; c < ESTS; c++)
            if (lhf[1][c][b][a] < -333 || lhf[1][c][b][a] > 3333) flag = 0;
          if (flag == 1) obsnum++;
        }
      fprintf(fpb, "%d %5d %5d %5.1f\n", datref[a], obsnum, posnum, 100.0 * (float)obsnum / (float)posnum);
      if (obsnum == posnum) daynum++;
    }
    printf("found %d perfectly valid SHF collocations (out of %d) in %s\n", daynum, DAYS, datbfile);
    fclose(fpb);
    exit(0);
}
