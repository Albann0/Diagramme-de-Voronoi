# Diagramme-de-Voronoï
Implémentation du diagramme de Voronoï en x86-64 avec NASM



Pour compiler : 

nasm -felf64 -Fdwarf -g -l etapeX.lst etapeX.asm -o etapeX.o 
nasm -felf64 -Fdwarf -g -l random.lst random.asm -o random.o
nasm -felf64 -Fdwarf -g -l calculDistance.lst calculDistance.asm -o calculDistance.o

gcc -fPIC -no-pie etapeX.o random.o calculDistance.o -o etapeX


(où X le numéro de votre étape)
