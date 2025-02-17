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

; Nos fonctions
extern calculDistance
extern random

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
%ifndef TAILLE_FENETRE
	%define TAILLE_FENETRE 400
%endif

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
reponse: resb 1 ; Permet de stocker le résultat de certains de nos scanf (savoir si on va générer un nb aléatoire de foyers / points)

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
minDistance: dw 0 ; La distance minimale entre un point et un foyer, on la met à 0 pour l'instant parce qu'az pk pas

demandeSiFoyerRandom: db "Voulez-vous que le nombre de foyer soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeSiPointsRandom: db "Voulez-vous que le nombre de points soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeNbFoyer : db "Entrez le nombre de foyer (entre 1 et 200) : ",0
demandeNbPoints : db "Entrez le nombre de points (entre 1 et 30000): ",0
reponseValeurRandomFoyer: db "Le nombre de foyer est de : %d",10,0
reponseValeurRandomPoints: db "Le nombre de points est de : %d",10,0
fmt_scan: db "%d",0

i: dw 0 ; Variable qui va servir pour les boucles
j: dw 0 ; Variable qui va servir pour les boucles

flag: db 0 ; Variable qui va servir pour éviter le bug qui exécute 2 fois notre code dessin et quui fait une erreur de segmentation à cause de la gestion des évènements

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
mov r8,TAILLE_FENETRE	; largeur
mov r9,TAILLE_FENETRE	; hauteur
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
push rbp ; Pour faire fonctionner le printf et le scanf il faut push rbp et pop rbp autour de notre code, c'est pour ça que c'est ici. Le pop rbp est à la ligne 257.

dessin:

; Si le flag est à 1 alors on saute à la fin de notre code pour éviter de dessiner 2 fois (erreur de segmentation)
cmp byte[flag],1
je flush

mov byte[flag],1 ; On met le flag à 1 

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

    movzx rdi,word[maxFoyer]
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
    jl foyerRandomNo ; on le renvoie chez sa mère

    mov ax,word[maxFoyer]
    cmp word[nbFoyer],ax
    jg foyerRandomNo ; t'essayes de nous niquer encore ? jsuis dans le train g pas ton temps



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

    movzx rdi,word[maxPoint]
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

    mov ax,word[maxPoint]
    cmp word[nbPoints],ax
    jg pointsRandomNo


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

pop rbp ; POP, bye bye les printfs


; Dans cette partie on va initialiser les coordonnées des foyers et des points : 

boucleInitCoordFoyers: ; Initialisation des coordonnées des foyers

    movzx rsi,word[i] ; On met i dans rsi pour pouvoir l'utiliser dans les tableaux car on ne peut pas utiliser word[i] directement (pas 2 variables sur la même ligne)

    mov edi,TAILLE_FENETRE ; On met TAILLE_FENETRE dans di car la valeur maximale que l'on peut avoir pour les coordonnées (taille de la fenêtre) - 1 (car pixel de 0 à TAILLE_FENETRE - 1 --> je fais pas la même technique de l'incrémentation car le 0 est une coordonée possible pour la fenêtre)
    call random ; On appelle notre fonction random qui permet de générer des nombres aléatoires
    mov word[coordFoyersX+rsi*WORD],ax ; Le retour de la fonction se fait dans le registre ax donc on stocke le coordonnée que l'on a généré dans le tableau coordFoyersX à l'indice rsi (i)

    mov edi,TAILLE_FENETRE
    call random
    mov word[coordFoyersY+rsi*WORD],ax    

    inc word[i] ; Ici on incrémente i pour passer au foyer suivant

    mov ax,word[i]
    cmp ax,word[nbFoyer] ; On compare ax (i) avec le nombre de foyer qu'on utilise pour cette instance du programme
    jb boucleInitCoordFoyers ; Si ax < nbFoyer alors on recommence la boucle, on ne fait pas <= car on commence à 0 donc on doit s'arrêter à nbFoyer-1

mov word[i],0 ; On remet i à 0 pour pouvoir l'utiliser dans la boucle suivante

boucleInitCoordPoints: ; Initialisation des coordonnées des points, tous pareil que pour les foyers mais on compare à nbPoints

    movzx rsi,word[i]

    mov edi,TAILLE_FENETRE
    call random
    mov word[coordPointsX+rsi*WORD],ax
    

    mov edi,TAILLE_FENETRE
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

    mov word[minDistance],TAILLE_FENETRE ; On met minDistance à TAILLE_FENETRE car ça sera la distance maximale théoriquement possible entre un point et son foyer le plus proche
   
    ; Maintenant qu'on a stocké les coordonnées du point courant dans x1 et y1 on va explorer chacun de nos foyers pour trouver le foyer le plus proche
    boucleExploreFoyers:

        movzx esi,word[j]
        
        movzx edi,word[coordFoyersX+esi*WORD] ; On met les coordonnées X du foyer courant dans edi
        movzx esi,word[coordFoyersY+esi*WORD] ; On met les coordonnées Y du foyer courant dans esi
        movzx edx,word[x1] ; On met x1 (les coordonnées X du point courant) dans edx
        movzx ecx,word[y1] ; On met y1 (les coordonnées Y du point courant) dans ecx
        
        call calculDistance ; Maintenant qu'on a mis nos paramètres (edi, esi, edx, ecx) on peut appeler notre fonction calculDistance qui va nous retourner la distance entre le point courant et le foyer courant

        movzx esi,word[j] ; On remet j dans esi pour pouvoir l'utiliser dans les tableaux, je ne sais pas pourquoi mais push et pop ne fonctionnaient pas donc j'ai fait ça
        
        cmp ax,word[minDistance] ; On compare la distance qu'on a récupéré via notre fonction calculDistance (résultat stocké dans eax) avec la distance minimale qu'on a trouvé jusqu'à présent
        jb ifDistanceInf ; Si la distance avec le foyer courant est strictement inférieur au précédent minimum alors on saute à ifDistanceInf

        jmp incJ ; On arrive ici si la distance avec le foyer courant est supérieur ou égale à la distance minimale qu'on a trouvé jusqu'à présent,, on fait alors un saut inconditionnel afin d'incrémenter j et de passer au foyer suivant

        ifDistanceInf:
        
        mov word[minDistance],ax ; On met dans minDistance la nouvelle distance minimale qu'on vient de trouver

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


flush:
    mov rdi, qword[display_name]
    call XFlush
    jmp boucle ; On retourne à la boucle des events pour attendre un nouvel évènement
    mov rax,34
    syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit ; LA FIN LETS GOOOOO !
	














