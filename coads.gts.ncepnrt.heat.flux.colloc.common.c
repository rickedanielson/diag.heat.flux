/*
 * Identify all sets of valid collocations among in situ and the
 * available analyses (at the resolution of the common grid) so
 * as to better compare them all - RD September 2015
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "/home/ricani/prog/include.netcdf/include/genalloc.h"

#define LEN        100
#define LOTS       500
#define D2R        (3.141592654/180.0)       /* degrees to radians conversion */

#define CUTOFF     2000                      /* minimum number of daily estimates from all analyses */
#define LAGS       3                         /* extrapolation from 0=before, 1=now, 2=after */
#define ESTS       9                         /* number of heat flux estimates */
#define POSS       5516                        /* number of locations with available timeseries */
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
    char *dir[ESTS] = {"cfsr", "erainterim", "hoaps", "ifremerflux", "jofuro", "merra", "oaflux", "seaflux", "insitu"};
    char *lagnam[LAGS] = {".bef", "", ".aft"};

    if (argc != 2) {
      printf("Usage: %s all.flux.common.min2000\n",argv[0]);
      exit(1);
    }

    strcpy(date, "1999-10-01-00");
    for (a = 0; a < DAYS; a++) {
      sscanf(date, "%d-%d-%d-%d", &yr, &mo, &dy, &hr);
      datref[a] = 10000 * yr + 100 * mo + dy;
      dateshift(date, 24);
    }

    strcpy(infile, "all.flux.locate.min2000");                                /* read all position file endings */
    printf("reading %s\n", infile);
    if ((fpa = fopen(infile,"r")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open %s\n", infile);
      exit(1);
    }
    posnum = 0;
    while (fgets(line,LEN,fpa) != NULL) {
      sscanf(line, "%f, %f, %f", &poslat[posnum], &poslon[posnum], &posdup[posnum]);
      if (posdup[posnum] > 0) {
        sprintf(tmp, ".%9.3f.%9.3f",poslat[posnum], poslon[posnum]);
        for (a = 0; a < LEN; a++)  if (tmp[a] == ' ') tmp[a] = '.';
        strcpy(posnam[posnum], tmp);
        posnum++;
      }
    }
/*  if (posnum != POSS) {fprintf(stderr, "ERROR : read %d positions\n", posnum) ; exit(1);}  */
    printf("found %d collocation positions\n", posnum);
    fclose(fpa);

    get_mem4Dfloat(&shf, LAGS, ESTS, POSS, DAYS);
    get_mem4Dfloat(&lhf, LAGS, ESTS, POSS, DAYS);

    for (d = 0; d < LAGS; d++)
      for (a = 0; a < ESTS; a++) {                                              /* then read the heat fluxes */
        printf("reading %s\n", dir[a]);
        for (b = 0; b < posnum; b++) {
          if (a == ESTS - 1)
            sprintf(infile, "%s/%s%s%s", dir[a], dir[a], posnam[b], lagnam[1]);
          else
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

    strcpy(datafile, argv[1]) ; strcat(datafile, ".shf");                     /* output the collocations that are */
    strcpy(datbfile, argv[1]) ; strcat(datbfile, ".lhf");                     /* valid, SHF and LHF, all on one line */
    printf("writing %s and %s\n", datafile, datbfile);
    if ((fpa = fopen(datafile,"w")) == NULL || (fpb = fopen(datbfile,"w")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open either %s or %s\n", datafile, datbfile);
      exit(1);
    }

    obsnum = 0;
    for (a = 0; a < DAYS; a++)
      for (b = 0; b < posnum; b++) {
        flag = 1;
        for (d = 0; d < LAGS; d++) for (c = 0; c < ESTS; c++)
          if (shf[d][c][b][a] < -333 || shf[d][c][b][a] > 3333) flag = 0;
        if (flag == 1) {
          fprintf(fpa, "%d %9.3f %9.3f", datref[a], poslat[b], poslon[b]);
          for (d = 0; d < LAGS; d++) for (c = 0; c < ESTS; c++) fprintf(fpa, " %9.3f", shf[d][c][b][a]);
          fprintf(fpa, "\n");
          obsnum++;
        }
      }
    printf("wrote %d SHF collocations to %s\n", obsnum, datafile);
    fclose(fpa);

    obsnum = 0;
    for (a = 0; a < DAYS; a++)
      for (b = 0; b < posnum; b++) {
        flag = 1;
        for (d = 0; d < LAGS; d++) for (c = 1; c < ESTS; c++)                 /* but for LHF skip CFSR entirely */
          if (lhf[d][c][b][a] < -333 || lhf[d][c][b][a] > 3333) flag = 0;
        if (flag == 1) {
          fprintf(fpb, "%d %9.3f %9.3f", datref[a], poslat[b], poslon[b]);
          for (d = 0; d < LAGS; d++) for (c = 0; c < ESTS; c++) fprintf(fpb, " %9.3f", lhf[d][c][b][a]);
          fprintf(fpb, "\n");
          obsnum++;
        }
      }
    printf("wrote %d LHF collocations to %s\n\n", obsnum, datbfile);
    fclose(fpb);
    exit(0);
}
