/**
 *
 *  fastfixmath.c
 *
 *  Petr Sladek
 *
*/

#include "fastfixmath.h"

// 1/4 of sine (0-pi/2)  
const int sinelut[128+1]={0,25,50,75,100,126,151,176,201,226,251,276,301,325,350,375,400,424,449,473,498,522,546,570,595,619,642,666,690,714,737,760,784,807,830,853,876,898,921,943,965,988,1009,1031,1053,1074,1096,1117,1138,1159,1179,1200,1220,1240,1260,1280,1299,1319,1338,1357,1375,1394,1412,1430,1448,1466,1483,1500,1517,1534,1551,1567,1583,1599,1615,1630,1645,1660,1674,1689,1703,1717,1730,1744,1757,1769,1782,1794,1806,1818,1829,1840,1851,1862,1872,1882,1892,1902,1911,1920,1928,1937,1945,1952,1960,1967,1974,1980,1987,1993,1998,2004,2009,2013,2018,2022,2026,2029,2033,2036,2038,2040,2042,2044,2046,2047,2047,2048,0};

int ffm_mult(int a, int b)
{
  return (int)(((long long int)a)*((long long int)b))/(FFM_UNIT*FFM_UNIT);
};

int ffm_sin(int x)
{
  int k, sign, y;
  
  k=(x/(FFM_PI/2));///FFM_UNIT;
  
  y = x - k*(FFM_PI/2);
  
  if (k<0) { sign=-1; k*=-1; y*=-1; } else sign = 1;
  
  k%=4;
  
  switch (k)
  {
    case 0: return sinelut[y/((FFM_PI/2)/128)]*sign; break;
    case 1: return sinelut[((FFM_PI/2)-y)/((FFM_PI/2)/128)]*sign; break;
    case 2: return sinelut[y/((FFM_PI/2)/128)]*sign*-1; break;
    case 3: return sinelut[((FFM_PI/2)-y)/((FFM_PI/2)/128)]*sign*-1; break;
    default:  return FFM_NAN; break;
  }    
}

 
      