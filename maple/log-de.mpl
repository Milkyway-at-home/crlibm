#######################################################################
# To use:
# restart; read "log.mpl";
Digits := 100:

interface(quiet=true):

read "common-procedures.mpl":
read "double-extended.mpl":
mkdir("TEMPLOG"):


ln2h,ln2l := hiloExt(log(2)):

L := 6: # As in Markstein's book

MAXINDEX    := round(2^L * (sqrt(2)-1)):

# The following loop defining wi could be replaced by a search for accurate table.
for i from 0 to MAXINDEX-1 do
    wi[i] := nearest(1 + i*2^(-L)): # double-precision, not extended !
od:
for i from MAXINDEX to 2^L do
    # y has been divided by two
    wi[i] := nearest((1 + i*2^(-L))/2): # double-precision, not extended !
od:



for i from 0 to 2^L do
    (invwih[i], invwil[i]) := hiloExt(1/wi[i]):
    (logwih[i], logwil[i]) := hiloExt(log(wi[i])):
od:

zmax:=2^(-L-1):


PolyDegreeAccurate:=15:

printf("Computing the polynomial for accurate phase (this may take some time...)\n"):
pe:= x  * numapprox[minimax](  log(1+x)/x,  x=-zmax..zmax,  [PolyDegreeAccurate-1,0], 1 ,  'delta_approx'):
log2(delta_approx):
# 123 bits


MaxDegreeDDE:=9:  # 8 gives 120 bits, 9 gives 122

polyAccurate := polyExact2Ext(pe, MaxDegreeDDE):
#delta_approx := numapprox[infnorm](polyAccurate-log(1+x), x=-zmax..zmax):
epsilon_approx := numapprox[infnorm]( 1-polyAccurate/log(1+x), x=-zmax..zmax):
printf("   approximation error for the accurate phase is 2^(%2f)\n", log2(epsilon_approx) ) :


PolyDegreeQuick:=8:

if(1+1=3) then
# Here we tried to use the polynomial from the accurate phase for the
# quick one.  This loses 7 bits of precision compared to a clean minimax, meaning
# one degree more. Better do two polynomials. To investigate some day,
# there must be a polynomial that does both.

#truncated to PolyDegreeQuick and to DE. We use the fact that series(p)=p
polyQuick := convert(series(polyExact2Ext(polyAccurate, 0), x=0, PolyDegreeQuick+1), polynom):
#delta_approx := numapprox[infnorm](polyAccurate-log(1+x), x=-zmax..zmax):
epsilon_approx := numapprox[infnorm]( 1-polyQuick/log(1+x), x=-zmax..zmax):
printf("   approximation error for the quick phase is 2^(%2f)\n", log2(epsilon_approx) ) ;
fi:


polyQuick:= polyExact2Ext(x  * numapprox[minimax](  log(1+x)/x,  x=-zmax..zmax,  [PolyDegreeQuick-1,0], 1 ,  'delta_approx'), 0):
epsilon_approx := numapprox[infnorm]( 1-polyQuick/log(1+x), x=-zmax..zmax):
printf("   approximation error for the quick phase is 2^(%2f)\n", log2(epsilon_approx) ) :











filename:="TEMPLOG/log-de.h":
fd:=fopen(filename, WRITE, TEXT):

fprintf(fd, "\n/*File generated by maple/log-de.mpl*/\n"):

  # Various constants
  fprintf(fd, "#define L        %d\n", L):
  fprintf(fd, "#define MAXINDEX %d\n", MAXINDEX):
  fprintf(fd, "static const long double ln2h  = %1.50eL ;\n", ln2h):
  fprintf(fd, "static const long double ln2l  = %1.50eL ;\n", ln2l):
  fprintf(fd, "static const long double two64 = %1.50eL ;\n", evalf(2^64)):


  # The polynomials
  #  polynomial for quick phase
  for i from PolyDegreeQuick to 1 by -1 do
    fprintf(fd, "static const long double c%d =    %1.50eL ;\n", i, coeff(polyQuick,x,i)):
  od:

  #  polynomial for accurate phase
  for i from PolyDegreeAccurate to MaxDegreeDDE by -1 do
    fprintf(fd, "static const long double c%dh =    %1.50eL ;\n", i, coeff(polyAccurate,x,i)):
  od:
  for i from  MaxDegreeDDE-1 to 1 by -1 do
    (ch, cl) := hiloExt(coeff(polyAccurate,x,i)):
    fprintf(fd, "static const long double c%dh =    %1.50eL ;\n", i, ch):
    fprintf(fd, "static const long double c%dl =    %1.50eL ;\n", i, cl):
  od:

  # The tables

  fprintf(fd, "typedef struct tablestruct_tag {double wi; long double invwih; long double logwih; long double invwil; long double logwil; } tablestruct ;  \n"):
  fprintf(fd, "static const tablestruct argredtable[%d] = {\n", 2^L+1):
  for i from 0 to 2^L do
      fprintf(fd, "  { %1.40e, /* wi[%d] */ \n", wi[i], i):
      fprintf(fd, "    %1.50eL, /* invwih[%d] */ \n", invwih[i], i):
      fprintf(fd, "    %1.50eL, /* logwih[%d] */ \n", logwih[i], i):
      fprintf(fd, "    %1.50eL, /* invwil[%d] */ \n", invwil[i], i):
      fprintf(fd, "    %1.50eL, /* logwil[%d] */ \n", logwil[i], i):
      fprintf(fd, "  } \n"):
      if(i<2^L) then  fprintf(fd, ", \n"): fi
  od:
fprintf(fd, "}; \n \n"):


fclose(fd):


if(1+1=3) then

maxpt:= numapprox[infnorm]( pt, x=-zmax..zmax):



  errlist := errlist_quickphase_horner(deg, 2, 2, 0,0); # two dd adds, two dd mul, no error on x
  epsilon_lastmult, delta_rounding, minptr, maxptr := compute_horner_rounding_error(pt, x, Xmax[i], errlist, true):
  if i=5 then
    epsilonZero := (1+epsilon_approx)  * (1 + epsilon_lastmult) - 1 :
  else
    epsilonZero := (delta_approx + delta_rounding)/minptr:
  fi:

  printf(" epsilonZero =  %3.2f ", -log2(epsilonZero));


  # For 0<E<= EminFastPath, the Horner evaluation ends in double-double
  errlist := errlist_quickphase_horner(deg, 2, 1, 0,0); # two dd adds, one dd mul, no error on x
  epsilon_lastmult, delta_rounding, minptr, maxptr := compute_horner_rounding_error(pt, x, Xmax[i], errlist, true):

  # epsilon for 0<E<= EminMedPath

  miny:=nearest(log(2.)) - maxptr;       #  worst-case miny
  # and add to the absolute error that of computing Elog2 : 2**(-90)
  epsilon:=evalf(  (delta_approx + delta_rounding + 2**(-90) )/miny  )  ;
  printf(" epsilon =  %3.2f ", -log2(epsilon));

  #delta for EminMedPath < E <= EminFastPath

  miny := (EminMedPath+1)*log(2.) - maxptr;
  epsilonEgtMed := (delta_approx + delta_rounding + 2**(-90) ) /miny:
  printf(" epsilonEgtMed =  %3.2f ", -log2(epsilonEgtMed));

  #epsilon for the fast path : in this case the polynomial is rounded to double, and evaluated only in double
  ptFastPath := poly_exact2(pt,1); # only coeff of degree 0 in double-double
  delta_approx :=  numapprox[infnorm](ptFastPath-log(x+midI[i]), x=-Xmax[i]..Xmax[i]);
  s1 := expand((ptFastPath - coeff(ptFastPath,x,0)) / x); # the polynomial computed in double
  errlist := errlist_quickphase_horner(deg-1, 0, 0, 0,0); # no dd adds, no dd mul, no error on x
  epsilon_lastmult, delta_rounding_s1, minptr, maxptrFastPath := compute_horner_rounding_error(s1, x, Xmax[i], errlist, true):
  p1 := s1*x ;
  maxp1:=numapprox[infnorm](p1, x=-Xmax[i]..Xmax[i]);
  delta_rounding_p1 := delta_rounding_s1*Xmax[i] + 0.5*ulp(maxp1);   # the last mult by z
  c0h,c0l := hi_lo(coeff(ptFastPath, x, 0));
  maxP_hi := 1075*log(2) + c0h;
  maxP_lo := maxP_hi*2^(-53);
  maxEln2_lo := maxP_lo;
  # the delta is that of the second argument of the last Add12.
  delta_rounding := delta_rounding_p1
                      +  0.5*ulp(maxp1 + c0l + maxEln2_lo + maxP_lo)
                      +  0.5*ulp(c0l + maxEln2_lo + maxP_lo)     # these two last terms are zero in the case i=5
                      +  0.5*ulp(maxEln2_lo + maxP_lo);          #  but it doesn't change much
  miny := (EminFastPath+1)*log(2.) - maxp1 ;
  epsilonFastPath := (delta_approx + delta_rounding + 2**(-90) ) / miny ;
  printf(" epsilonFastPath = %3.2f\n", -log2(epsilonFastPath) );
  [pt, epsilon_approx, max(maxpt,maxptr), epsilonZero, epsilon, epsilonEgtMed, epsilonFastPath]
end proc:

fi:





