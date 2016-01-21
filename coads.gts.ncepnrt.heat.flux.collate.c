/*
 * Populate an "insitu" directory by collating and discretizing "all.flux" into averages
 * at the resolution of a set of reference analyses (daily/0.25-degree for 3745 days/5516
 * positions) - RD September, October 2015
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>

#define LEN        100
#define LOTS       500
#define LATS       720                       /* number of domain latitudes */
#define LONS       1440                      /* number of domain longitudes */
#define FIRSTLAT  -90.0                      /* first latitude (deg), last is FIRST + DEL * (LATS-1) */
#define DELLAT     0.25                      /* difference in adjacent latitudes (deg) */
#define FIRSTLON  -180.0                     /* first longitude (deg), last is FIRST + DEL * (LONS-1) */
#define DELLON     0.25                      /* difference in adjacent longitudes (deg) */

#define POSS       5516                      /* number of locations with available timeseries */
#define DAYS       3745                      /* number of days between 1999-10-01 and 2009-12-31 */
#define MISS      -9999.0                    /* generic missing value */

int   datref[DAYS];
float poslat[POSS],       poslon[POSS];
float shfobs[POSS][DAYS], lhfobs[POSS][DAYS];
int   shfnum[POSS][DAYS], lhfnum[POSS][DAYS];
char  posnam[POSS][LEN];

main (int argc, char *argv[])
{
    FILE *fpa, *fpb, *fpc, *fpd, *fopen();
    int a, b, c, d, count, lines, pos, chs, chkdat, dayind, llind, grdind[LATS][LONS];
    int yr, mo, dy, hr, posnum, daynum, obsnum, totnum, posind, latind, lonind;
    char infile[LEN], outfile[LEN], datafile[LEN], datbfile[LEN];
    char line[LOTS], lina[LEN], linb[LEN], linc[LEN], lind[LEN];
    char date[LEN], datempa[LEN], datempb[LEN], tmp[LEN];
    float inshf, inlhf, inlat, inlon, grdlat[LATS], grdlon[LONS], lldel, llmin;

    if (argc != 2) {
      printf("Usage: %s all.flux\n",argv[0]);
      exit(1);
    }
    for (a = 0; a < LATS; a++) grdlat[a] = FIRSTLAT + DELLAT * a;
    for (a = 0; a < LONS; a++) grdlon[a] = FIRSTLON + DELLON * a;
    for (a = 0; a < LATS; a++) for (b = 0; b < LONS; b++) grdind[a][b] = -1;
    for (a = 0; a < POSS; a++) for (b = 0; b < DAYS; b++) shfobs[a][b] = lhfobs[a][b] = 0.0;
    for (a = 0; a < POSS; a++) for (b = 0; b < DAYS; b++) shfnum[a][b] = lhfnum[a][b] = 0;

    strcpy(date, "1999-10-01-00");                                            /* define a mapping to day index */
    for (a = 0; a < DAYS; a++) {
      sscanf(date, "%d-%d-%d-%d", &yr, &mo, &dy, &hr);
      datref[a] = 10000 * yr + 100 * mo + dy;
      dateshift(date, 24);
    }

    strcpy(datafile, "hoaps/z.list");                                         /* and a mapping to location index */
    printf("reading %s\n", datafile);
    if ((fpa = fopen(datafile,"r")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open %s\n", datafile);
      exit(1);
    }
    posnum = 0;
    while (fgets(lina,LEN,fpa) != NULL) {
      for (a = 0; lina[a] != '\0'; a++) if (lina[a] == '\n') lina[a] = '\0';
      strcpy(posnam[posnum], lina+5);
      strcpy(linb, lina);
      for (a = 1; lina[a+1] != '\0'; a++) if (lina[a] == '.' && (lina[a-1] == '.' || lina[a+1] == '.')) linb[a] = ' ';
      sscanf(linb, "%*s %f %f", &inlat, &inlon);
      latind = (inlat - FIRSTLAT) / DELLAT;
      lonind = (inlon - FIRSTLON) / DELLON;
      grdind[latind][lonind] = posnum;
      posnum++;
    }
    if (posnum != POSS) {fprintf(stderr, "ERROR : read %d positions\n", posnum) ; exit(1);}
    fclose(fpa);

    strcpy(infile, argv[1]);                                                  /* then loop through in situ data and */
    printf("reading %s\n", infile);                                           /* grid them, then sum the valid ones */
    if ((fpa = fopen(infile,"r")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open %s\n", infile);
      exit(1);
    }
    obsnum = totnum = 0;
    while (fgets(line,LOTS,fpa) != NULL) {
      sscanf(line, "%f, %f, %*s %s %f, %f,", &inshf, &inlhf, date, &inlat, &inlon);
      if (inlon < -180.125) inlon += 360.0;
      sscanf(date, "%4d%2d%2d%2d", &yr, &mo, &dy, &hr) ; chkdat = 10000 * yr + 100 * mo + dy;
      if (chkdat > 19990999 && chkdat < 20100000) {
        dayind = -9999 ; for (a = 0; a < DAYS; a++) if (datref[a] == chkdat) {dayind = a ; break;}
/*      if (dayind < 0) {fprintf(stderr, "ERROR : %s seems to be outside [1999-10-01, 2009-12-31]\n", date) ; exit(1);}  */
        latind = -9999 ; for (a = 0; a < LATS; a++) if (fabs(inlat - (FIRSTLAT + a * DELLAT)) <= 0.125) {latind = a ; break;}
/*      if (latind < 0) {fprintf(stderr, "ERROR : %f seems to be outside [-90.125, 89.875]\n", inlat) ; exit(1);}  */
        lonind = -9999 ; for (a = 0; a < LONS; a++) if (fabs(inlon - (FIRSTLON + a * DELLON)) <= 0.125) {lonind = a ; break;}
/*      if (lonind < 0) {fprintf(stderr, "ERROR : %f seems to be outside [-180.125, 179.875]\n", inlon) ; exit(1);}  */
        posind = grdind[latind][lonind];
        if (dayind < 0 || latind < 0 || lonind < 0 || posind < 0) {
          fprintf(stderr, "WARNING : unable to index %s %d %d %d %d %f\n", line, dayind, latind, lonind, posind, fabs(inlon-FIRSTLON));
          lonind = LONS - 1;
          posind = grdind[latind][lonind];
          fprintf(stderr, "QUESTION : ?able to index %s %d %d %d %d\n", line, dayind, latind, lonind, posind);
        }

        if (dayind >= 0 && latind >= 0 && lonind >= 0 && posind >= 0) {
          if (inshf > -333 && inshf < 3333) {shfobs[posind][dayind] += inshf ; shfnum[posind][dayind] += 1;}
          if (inlhf > -333 && inlhf < 3333) {lhfobs[posind][dayind] += inlhf ; lhfnum[posind][dayind] += 1;}
          obsnum++;
        }
        totnum++;
      }
    }
    printf("collated %d of %d observations\n\n", obsnum, totnum);
    fclose(fpa);
exit(0);

    for (a = 0; a < POSS; a++) {                                              /* save the daily sums on the grid */
      sprintf(outfile, "insitu/insitu%s", posnam[a]);
      if ((fpa = fopen(outfile,"w")) == NULL) {
        fprintf(stderr, "ERROR : couldn't open %s\n", outfile);
        exit(1);
      }
      for (b = 0; b < DAYS; b++) {
        inshf = MISS ; if (shfnum[a][b] > 0) inshf = shfobs[a][b] / shfnum[a][b];
        inlhf = MISS ; if (lhfnum[a][b] > 0) inlhf = lhfobs[a][b] / lhfnum[a][b];
        fprintf(fpa, "%d12 %9.3f %9.3f %9d %9d\n", datref[b], inshf, inlhf, shfnum[a][b], lhfnum[a][b]);
      }
      fclose(fpa);
    }
    exit(0);
}
