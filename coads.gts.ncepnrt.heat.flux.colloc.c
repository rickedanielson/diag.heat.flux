/*
 * Identify all sets of collocated values among in situ and two
 * analyses at the resolution of the common grid - RD September 2015
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>

#define LEN        100
#define LOTS       500
#define D2R        (3.141592654/180.0)       /* degrees to radians conversion */
#define POSS       5516                      /* number of locations with available timeseries */
#define DAYS       3745                      /* number of days between 1999-10-01 and 2009-12-31 */
#define MISS      -9999.0                    /* generic missing value */

int   datref[DAYS];
float poslat[POSS],       poslon[POSS];
/* float shfobs[POSS][DAYS], lhfobs[POSS][DAYS];
   int   shfnum[POSS][DAYS], lhfnum[POSS][DAYS];  */
float shfana[POSS][DAYS], lhfana[POSS][DAYS];
float shfanb[POSS][DAYS], lhfanb[POSS][DAYS];

main (int argc, char *argv[])
{
    FILE *fpa, *fpb, *fpc, *fpd, *fopen();
    int a, b, c, d, count, lines, pos, chs, chkdat, dayind, llind;
    int yr, mo, dy, hr, posnum, daynum, obsnum, colnum, posind, latind, lonind;
    char infile[LEN], outfile[LEN], datafile[LEN], datbfile[LEN];
    char line[LOTS], lina[LEN], linb[LEN], linc[LEN], lind[LEN];
    char date[LEN], datempa[LEN], datempb[LEN], tmp[LEN];
    float inshf, inlhf, inlat, inlon, grdlat, grdlon, lldel, llmin;

    if (argc != 4) {
      printf("Usage: %s all.flux cfsr erainterim\n",argv[0]);
      exit(1);
    }

    strcpy(infile, argv[1]);                                                  /* define all file names and */
    sprintf(outfile, "%s.%s.%s", argv[1], argv[2], argv[3]);                  /* dates in the timeseries */
    strcpy(datafile, argv[2]) ; strcat(datafile, "/z.list");
    strcpy(datbfile, argv[3]) ; strcat(datbfile, "/z.list");

    strcpy(date, "1999-10-01-00");
    for (a = 0; a < DAYS; a++) {
      sscanf(date, "%d-%d-%d-%d", &yr, &mo, &dy, &hr);
      datref[a] = 10000 * yr + 100 * mo + dy;
      dateshift(date, 24);
    }

    printf("reading %s and %s\n", datafile, datbfile);                        /* store the gridded data in memory */
    if ((fpa = fopen(datafile,"r")) == NULL || (fpb = fopen(datbfile,"r")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open %s or %s\n", datafile, datbfile);
      exit(1);
    }
    posnum = 0;
    while (fgets(lina,LEN,fpa) != NULL && fgets(linb,LEN,fpb) != NULL) {
      sscanf(lina, "%s", line) ; sprintf(linc, "%s/%s", argv[2], line);
      sscanf(linb, "%s", line) ; sprintf(lind, "%s/%s", argv[3], line);
      for (a = 1; a < LEN-1; a++)  if (line[a] == '.' && (line[a-1] == ' ' || line[a+1] == '.'))  line[a] = ' ';
      sscanf(line, "%*s %f %f", &poslat[posnum], &poslon[posnum]);
/*    printf("reading %s %f %f\n", line, poslat[posnum], poslon[posnum]);
      printf("reading %s and %s\n", linc, lind);  */
      if ((fpc = fopen(linc,"r")) == NULL || (fpd = fopen(lind,"r")) == NULL) {
        fprintf(stderr, "ERROR : couldn't open %s or %s\n", linc, lind);
        exit(1);
      }
      daynum = 0;
      while (fgets(lina,LEN,fpc) != NULL && fgets(linb,LEN,fpd) != NULL) {
        sscanf(lina, "%*s %f %f", &shfana[posnum][daynum], &lhfana[posnum][daynum]);
        sscanf(linb, "%*s %f %f", &shfanb[posnum][daynum], &lhfanb[posnum][daynum]);
        daynum++;
      }
      if (daynum != DAYS) {fprintf(stderr, "read %d days\n", daynum) ; exit(1);}
      fclose(fpc);
      fclose(fpd);
      posnum++;
    }
    if (posnum != POSS) {fprintf(stderr, "ERROR : read %d positions\n", posnum) ; exit(1);}
    fclose(fpa);
    fclose(fpb);

    printf("reading %s\nwriting %s\n", infile, outfile);                      /* loop through the in situ */
    if ((fpa = fopen(infile,"r")) == NULL || (fpb = fopen(outfile,"w")) == NULL) {
      fprintf(stderr, "ERROR : couldn't open %s or %s\n", infile, outfile);
      exit(1);
    }
    obsnum = 0;
    while (fgets(line,LOTS,fpa) != NULL) {
      sscanf(line, "%f, %f, %*s %s %f, %f,", &inshf, &inlhf, date, &inlat, &inlon);
      if (inlon < -180) inlon += 360.0;
      sscanf(date, "%4d%2d%2d%2d", &yr, &mo, &dy, &hr) ; chkdat = 10000 * yr + 100 * mo + dy;
      dayind = -9999 ; for (a = 0; a < DAYS; a++) if (datref[a] = chkdat) {dayind = a ; break;}
/*    if (dayind < 0) {fprintf(stderr, "ERROR : %s seems to be outside [1999-10-01, 2009-12-31]\n", date) ; exit(1);}  */
      latind = -9999 ; for (a = 0; a <  720; a++) if (fabs(inlat - ( -90.0 + a * 0.25)) <= 0.125) {latind = a ; break;}
/*    if (latind < 0) {fprintf(stderr, "ERROR : %f seems to be outside [-90.125, 89.875]\n", inlat) ; exit(1);}  */
      lonind = -9999 ; for (a = 0; a < 1440; a++) if (fabs(inlon - (-180.0 + a * 0.25)) <= 0.125) {lonind = a ; break;}
/*    if (lonind < 0) {fprintf(stderr, "ERROR : %f seems to be outside [-180.125, 179.875]\n", inlon) ; exit(1);}  */
      inlat =  -90.0 + latind * 0.25;
      inlon = -180.0 + lonind * 0.25;
      posind = -9999 ; for (a = 0; a < POSS; a++) if (inlat == poslat[a] && inlon == poslon[a]) {posind = a ; break;}
/*    if (posind < 0) {fprintf(stderr, "ERROR : missing a collocation timeseries at lat %f lon %f\n", inlat, inlon) ; exit(1);}  */

      if (dayind >= 0 && latind >= 0 && lonind >= 0 && posind >= 0) {
        if ( inshf                 < -333 ||  inshf                 > 3333)  inshf                 = MISS;
        if ( inlhf                 < -333 ||  inlhf                 > 3333)  inlhf                 = MISS;
        if (shfana[posind][dayind] < -333 || shfana[posind][dayind] > 3333) shfana[posind][dayind] = MISS;
        if (lhfana[posind][dayind] < -333 || lhfana[posind][dayind] > 3333) lhfana[posind][dayind] = MISS;
        if (shfanb[posind][dayind] < -333 || shfanb[posind][dayind] > 3333) shfanb[posind][dayind] = MISS;
        if (lhfanb[posind][dayind] < -333 || lhfanb[posind][dayind] > 3333) lhfanb[posind][dayind] = MISS;
        fprintf(fpb, "%d %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f %9.3f\n",
          datref[dayind], inlat, inlon, inshf, inlhf,
          shfana[posind][dayind], lhfana[posind][dayind],
          shfanb[posind][dayind], lhfanb[posind][dayind]);
        obsnum++;
      }
    }
    printf("wrote %d collocations to %s\n\n", obsnum, outfile);
    fclose(fpa);
    fclose(fpb);
    exit(0);
}


/*    30.49,   189.55,   42036,    199901010050,  28.500,  -84.500,  3.0,  1.0,  1021.00,   20.000,    5.144,   -1.760,   -4.834,    17.50,     8.10,  -999.00,    21.90
   for (a = 0; line[a] != '\0'; a++) if (line[a] == ',') line[a] = ' ';
printf("%f %f %s\n",inshf,inlat,line);
printf("%s %d %d %d %d %d\n", date,yr, mo,dy,hr,chkdat);  */
