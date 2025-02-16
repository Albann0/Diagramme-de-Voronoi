global calculDistance ; La fonction calculDistance calcule la distance entre 2 points sur un plan
calculDistance:

; On passe par des registres 32 bits pour pouvoir utiliser mul sans risque de dépassement électrique

mov eax,edi ; On met les coordonnées X du foyer courant dans eax
sub eax,edx ; On soustrait les coordonnées X du point courant à celles du foyer courant
mul eax ; On multiplie le résultat de la soustraction par lui même pour obtenir le carré de la distance entre les coordonnées X du point et du foyer
mov ebx,eax ; mul marche que avec ax donc pas le choix de stocker dans ebx pour la suite

mov eax,esi ; On met les coordonnées Y du foyer courant dans eax
sub eax,ecx ; On soustrait les coordonnées Y du point courant à celles du foyer courant
mul eax ; On multiplie le résultat de la soustraction par lui même pour obtenir le carré de la distance entre les coordonnées Y du point et du foyer


add ebx,eax ; en gros là j'ai fait (x1-x2)² + (y1-y2)² il faut encore que je calcule la racine carré de ça pour trouver la distance

cvtsi2ss xmm0,ebx ; On met ebx dans xmm0 pour pouvoir utiliser sqrtss
sqrtss xmm1,xmm0 ; On met ecx dans eax car return de la fonction

cvtss2si eax,xmm1 ; On met le résultat de la racine carrée dans eax pour pouvoir le retourner


ret