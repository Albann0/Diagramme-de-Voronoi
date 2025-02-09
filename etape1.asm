; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern scanf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

section .bss

; Les variables non initialisées du prof
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1


; Nos variables non initialisées

coordFoyersX: resw 200 ; Tableau qui contiendra les coordonnées x des foyers
coordFoyersY: resw 200 ; Tableau qui contiendra les coordonnées y des foyers

coordPointsX: resw 30000 ; Tableau qui contiendra les coordonnées x des points
coordPointsY: resw 30000 ; Tableau qui contiendra les coordonnées y des points


nbFoyer: resw 1 ; Nombre de foyers qu'on va utiliser, soit ce nombre sera généré aléatoirement soit l'utilisateur le rentrera. Valeur comprise entre 1 et 200
nbPoints: resw 1 ; Nombre de points qu'on va utiliser, soit ce nombre sera généré aléatoirement soit l'utilisateur le rentrera. Valeur comprise entre 1 et 30000
reponse: resb 1 ; Permet de stocker le résultat de nos scanf (je crois à vérif). Il faut vérifier si on ne peut pas la virer et passer les variables automatiquement en paramètre de scanf



section .data

; Les variables initialisées du prof
event:		times	24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0


; Nos variables initialisées
maxFoyer: dw 200 ; Le nombre maximum de foyer qu'on autorise dans le programme
maxPoint: dw 30000 ; Le nombre maximum de points qu'on autorise dans le programme
minDistance: dd 0 ; La distance minimale entre un point et un foyer, on la met à 0 pour l'instant parce qu'az pk pas

demandeSiFoyerRandom: db "Voulez-vous que le nombre de foyer soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeSiPointsRandom: db "Voulez-vous que le nombre de points soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeNbFoyer : db "Entrez le nombre de foyer (entre 1 et 200) : ",0
demandeNbPoints : db "Entrez le nombre de points (entre 1 et 30000): ",0
reponseValeurRandomFoyer: db "Le nombre de foyer est de : %d",10,0
reponseValeurRandomPoints: db "Le nombre de points est de : %d",10,0
fmt_scan: db "%d",0


i: dw 0 ; Variable qui va servir pour les boucles
j: dw 0 ; Variable qui va servir pour les boucles

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ################## Ici c'est le code du prof, il permet de faire fonctionner la partie graphique
;##################################################
global main
main:

xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 # Ici c'est notre code ! C'est principalement de l'algo, on intervient sur la fenêtre uniquement afin de dessiner des lignes
;#########################################
push rbp ; Pour faire fonctionner le printf et le scanf il faut push rbp et pop rbp autour de notre code, c'est pour ça que c'est ici. Le pop rbp est à la ligne 262.
dessin:

; On demande à l'utilisateur si il veut que le nombre de foyer et soit déterminé aléatoirement
foyerRandomYesOrNo:

mov rdi,demandeSiFoyerRandom
mov rax,0
call printf

mov rdi,fmt_scan
mov rsi,reponse
mov rax,0
call scanf

cmp byte[reponse],1 
jne foyerRandomNo  ; Si l'utilisateur entre autre chose que 1 alors on passe à foyerRandomNo qui permet de demander à l'utilisateur le nombre de foyer qu'il veut

foyerRandomYes :

mov di,word[maxFoyer]
call random
inc ax ; On incrémente ax car on ne veut pas 0 foyer
mov word[nbFoyer],ax

jmp pointsRandomYesOrNo ; On saute à la suite (même chose que pour les foyers mais pour les points)



foyerRandomNo: 

mov rdi,demandeNbFoyer
mov rax,0
call printf

mov rdi,fmt_scan
mov rsi,nbFoyer
mov rax,0
call scanf

cmp word[nbFoyer],1
jl foyerRandomNo

mov ax,word[maxFoyer]
cmp word[nbFoyer],ax
jg foyerRandomNo



; On demande à l'utilisateur si il veut que le nombre de points soit déterminé aléatoirement
pointsRandomYesOrNo:

mov rdi,demandeSiPointsRandom
mov rax,0
call printf

mov rdi,fmt_scan
mov rsi,reponse
mov rax,0
call scanf
 
cmp byte[reponse],1 ; Si l'utilisateur entre autre chose que 1 alors on passe à pointsRandomNo qui permet de demander à l'utilisateur le nombre de foyer qu'il veut
jne pointsRandomNo

pointsRandomYes:

mov di,word[maxPoint]
call random
inc ax ; On incrémente ax car on ne veut pas 0 point
mov word[nbPoints],ax

jmp affichageValeurs ; On saute à l'affichage des valeurs utilisés pour les foyers et les points

pointsRandomNo:

mov rdi,demandeNbPoints
mov rax,0
call printf

mov rdi,fmt_scan
mov rsi,nbPoints
mov rax,0
call scanf

cmp word[nbPoints],1
jl pointsRandomNo




; Ici on affiche le nombre de foyers et de points utilisés
affichageValeurs:

mov rdi,reponseValeurRandomFoyer 
movzx rsi,word[nbFoyer]
mov rax,0 
call printf

mov rdi,reponseValeurRandomPoints
movzx rsi,word[nbPoints]
mov rax,0 
call printf

pop rbp



; Dans cette partie on va initialiser les coordonnées des foyers et des points : 

boucleInitCoordFoyers: ; Initialisation des coordonnées des foyers

    movzx rsi,word[i] ; On met i dans rsi pour pouvoir l'utiliser dans les tableaux car on ne peut pas utiliser word[i] directement (pas 2 variables sur la même ligne)

    mov di,401 ; On met 401 dans di car c'est la valeur maximale que l'on peut avoir pour les coordonnées (taille de la fenêtre) + 1 (on ajoute +1 par rapport à l'opcode rdrand), je fais pas la même technique de l'incrémentation car le 0 est une coordonée possible pour la fenêtre
    call random ; On appelle notre fonction random qui permet de générer des nombres aléatoires
    mov word[coordFoyersX+rsi*WORD],ax ; Le retour de la fonction se fait dans le registre ax donc on stocke le coordonnée que l'on a généré dans le tableau coordFoyersX à l'indice rsi (i)
    

    mov di,401
    call random
    mov word[coordFoyersY+rsi*WORD],ax

    

    inc word[i] ; Ici on incrémente i pour passer au foyer suivant

    mov ax,word[i]
    cmp ax,word[nbFoyer] ; On compare ax (i) avec le nombre de foyer qu'on utilise pour cette instance du programme
    jb boucleInitCoordFoyers ; Si ax < nbFoyer alors on recommence la boucle, on ne fait pas <= car on commence à 0 donc on doit s'arrêter à nbFoyer-1

mov word[i],0 ; On remet i à 0 pour pouvoir l'utiliser dans la boucle suivante

boucleInitCoordPoints: ; Initialisation des coordonnées des points, tous pareil que pour les foyers mais on compare à nbPoints

    movzx rsi,word[i]

    mov di,401
    call random
    mov word[coordPointsX+rsi*WORD],ax
    

    mov di,401
    call random
    mov word[coordPointsY+rsi*WORD],ax

   

    inc word[i]

    mov ax,word[i]
    cmp ax,word[nbPoints]
    jb boucleInitCoordPoints

mov word[i],0


; Dans cette partie on va explorer chacun de nos points et calculer la distance entre ce point et chacun de nos foyers pour trouver le foyer le plus proche

boucleExplorePoints:
    movzx esi,word[i]
    mov word[j],0 ; On met j à 0 pour pouvoir l'utiliser dans la boucle imbriquée 

    movzx eax,word[coordPointsX+esi*WORD] ; On met les coordonnées X du point courant dans eax afin d'ensuite stocker cette coordonnée dans x1
    mov [x1],eax

    movzx eax,word[coordPointsY+esi*WORD] ; On met les coordonnées Y du point courant dans eax afin d'ensuite stocker cette coordonnée dans y1
    mov [y1],eax

    mov dword[minDistance],400 ; On met minDistance à 400 car ça sera la distance maximale théoriquement possible entre un point et son foyer le plus proche

   
    ; Maintenant qu'on a stocké les coordonnées du point courant dans x1 et y1 on va explorer chacun de nos foyers pour trouver le foyer le plus proche

    boucleExploreFoyers:

        movzx esi,word[j]
        


        
        movzx edi,word[coordFoyersX+esi*WORD] ; On met les coordonnées X du foyer courant dans edi
        movzx esi,word[coordFoyersY+esi*WORD] ; On met les coordonnées Y du foyer courant dans esi
        movzx edx,word[x1] ; On met x1 (les coordonnées X du point courant) dans edx
        movzx ecx,word[y1] ; On met y1 (les coordonnées Y du point courant) dans ecx
        
        call calculDistance ; Maintenant qu'on a mis nos paramètres (edi, esi, edx, ecx) on peut appeler notre fonction calculDistance qui va nous retourner la distance entre le point courant et le foyer courant

        movzx esi,word[j] ; On remet j dans esi pour pouvoir l'utiliser dans les tableaux, je ne sais pas pourquoi mais push et pop ne fonctionnaient pas donc j'ai fait ça

        
        cmp eax,dword[minDistance] ; On compare la distance qu'on a récupéré via notre fonction calculDistance (résultat stocké dans eax) avec la distance minimale qu'on a trouvé jusqu'à présent
        jb ifDistanceInf ; Si la distance avec le foyer courant est strictement inférieur au précédent minimum alors on saute à ifDistanceInf

        jmp incJ ; On arrive ici si la distance avec le foyer courant est supérieur ou égale à la distance minimale qu'on a trouvé jusqu'à présent,, on fait alors un saut inconditionnel afin d'incrémenter j et de passer au foyer suivant

        ifDistanceInf:
        
        mov dword[minDistance],eax ; On met dans minDistance la nouvelle distance minimale qu'on vient de trouver

        movzx eax,word[coordFoyersX+esi*WORD]
        mov dword[x2],eax ; On met le nouveau coordonée X du foyer le plus proche dans x2
        movzx eax,word[coordFoyersY+esi*WORD]
        mov dword[y2],eax ; On met le nouveau coordonée Y du foyer le plus proche dans y2

        incJ:

        inc word[j] ; On incrémente j pour passer au foyer suivant

        mov ax,word[j]
        cmp ax,word[nbFoyer] ; Comme pour l'initialisation des coordonnées on compare j avec le nombre de foyers qu'on utilise
        jb boucleExploreFoyers ; Si j < nbFoyer-1 alors on recommence la sous boucle pour explorer le prochain foyer, si non alors on sort de cette sous boucle

    
  

    ; Maintenant qu'on a exploré tous nos foyers et qu'on a les coordonées du foyer avec lequel notre point courant à la distance minimal, on peut tracer le trait entre le point et le foyer
   
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,qword[gc]
    movzx ecx,word[x1]	
    movzx r8d,word[y1]	
    movzx r9d,word[x2]	
    push qword[y2]	
    call XDrawLine ; On appel la fonction responsable du traçage des traits

    inc word[i] ; On incrément i afin de passer au point suivant

    mov ax,word[i]
    cmp ax,word[nbPoints] ; Comme pour l'initialisation des coordonnées on compare j avec le nombre de foyers qu'on utilise
    jb boucleExplorePoints ; Si i < nbPoints-1 alors on recommence la boucle pour explorer le prochain point, si non alors on sort de cette boucle





mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit ; LA FIN LETS GOOOOO !
	






global random  ; La fonction random permet de générer des nombres aléatoires entre 0 et la valeur passée en paramètre (di)
random:


xor dx,dx ; Permet de mettre dx à 0 afin d'éviter des conflits avec les valeurs précédentes
rdrand ax ; On utilise rdrand pour générer un nombre aléatoire, rdrand pren un registre d'au moins 16 bits et génére un nb dans ce range, ici on le stocke dans ax
div di ; Comme en C, afin d'avoir un range précis il faut récupérer le reste du nombre généré par di (le nombre max qu'on veut) pour avoir un nombre entre 0 et di. Div di met le reste de ax/di dans dx, dx sera notre nb aléatoire entre 0 et di-1


mov ax,dx

ret


global calculDistance
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



mov ecx, 0
xor rax,rax ; on met rax à 0 pour éviter des conflits avec des valeurs précédemment stockés

boucleRacineCarrée: ; Le principe de cette boucle est de tester la puissance de chaque nombre à partir de 1 jusqu'à ce que la puissance soit suppérieur à la somme de (x1-x2)² + (y1-y2)² 

inc ecx ; On incrémente à chaque tour de boucle pour tester chaque puissance

mov eax,ecx ; Je mets ecx dans eax car mul utilise tjrs que eax à quand une update svp ????
mul eax ; on fait la îossance

cmp eax,ebx ; Je compare notre valeur avec la somme des deux carrés obtenu précédemment ( (x1-x2)² + (y1-y2)² )
jg finBoucleRacineCarrée ; Si notre valeur est supérieur à la somme des deux carrés alors on sort de la boucle

jmp boucleRacineCarrée ; Sinon je recommence la boucle

finBoucleRacineCarrée :
dec ecx  ; On soustrait 1 à ecx pour revenir à la puissance précédente qui était inférieur à la somme des deux carrés car on fait une racine carrée approximative
mov eax,ecx ; On met ecx dans eax car return de la fonction


ret




