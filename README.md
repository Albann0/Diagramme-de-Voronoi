# Diagramme-de-Voronoï
Implémentation du diagramme de Voronoï en x86-64 avec NASM



Pour compiler : 

nasm -felf64 -Fdwarf -g -l etape1.lst etape1.asm -o etape1.o 

nasm -felf64 -Fdwarf -g -l etape2.lst etape2.asm -o etape2.o

nasm -felf64 -Fdwarf -g -l etape3.lst etape3.asm -o etape3.o

nasm -felf64 -Fdwarf -g -l etape4.lst etape4.asm -o etape4.o

nasm -felf64 -Fdwarf -g -l random.lst random.asm -o random.o

nasm -felf64 -Fdwarf -g -l calculDistance.lst calculDistance.asm -o calculDistance.o

gcc -fPIC -no-pie etape1.o random.o calculDistance.o -o etape1 -lX11

gcc -fPIC -no-pie etape2.o random.o calculDistance.o -o etape2 -lX11

gcc -fPIC -no-pie etape3.o random.o calculDistance.o -o etape3 -lX11

gcc -fPIC -no-pie etape4.o random.o calculDistance.o -o etape4 -lX11



La taille de la fenêtre est par défaut de 400x400, si vous souhaitez changer cela il faut ajouter ça dans l'assemblage du fichier etapeX.asm : -dTAILLE_FENETRE=XXX où X la valeur que vous souhaitez comme taille de fenêtre.

Exemple : 
nasm -felf64 -Fdwarf -g -l etape4.lst etape4.asm -o etape4.o -dTAILLE_FENETRE=1000


https://www.cburch.com/csbsju/cs/350/docs/nasm/nasmdoc2.html#section-2.1.8


