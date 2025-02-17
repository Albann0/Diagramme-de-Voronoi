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
%define NB_COLOR 6

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
coordFoyersX: resw 200
coordFoyersY: resw 200
coordPointsX: resw 30000
coordPointsY: resw 30000

nbFoyer: resw 1
nbPoints: resw 1
reponse: resb 1

section .data

; Les variables initialisées du prof
event:		times	24 dq 0
x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

; Nos variables initialisées
colors1: dd 0x5766ac, 0x566e9c, 0x56758b, 0x557d7b, 0x55846a, 0x548c5a ; Une couleur = 3 octets donc DWORD (4 octets), dégradé bleu vers vert
colors2: dd 0xb56590, 0xb3669f, 0xb267ae, 0xb069bd, 0xaf6acc, 0x0ad6bdb ; Dégradé de rose vers violet
colors3: dd 0xe5e355, 0xded553, 0xd7c752, 0xcfb850, 0xc8aa4f, 0xc19c4d; Dégradé de jaune vers orange

maxFoyer: dw 200
maxPoint: dw 30000
minDistance: dd 0
numPaletteChoisie: db 0

demandeSiFoyerRandom: db "Voulez-vous que le nombre de foyer soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeSiPointsRandom: db "Voulez-vous que le nombre de points soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeNbFoyer : db "Entrez le nombre de foyer (entre 1 et 200) : ",0
demandeNbPoints : db "Entrez le nombre de points (entre 1 et 30000): ",0
décritPalette1: db "1 : Dégradé de bleu vers vert",10,0
décritPalette2: db "2 : Dégradé de rose vers violet",10,0
décritPalette3: db "3 : Dégradé de jaune vers orange",10,0
demandeDégradéCouleur : db "Choisissez le dégradé de couleur que vous voulez : ",0
reponseValeurRandomFoyer: db "Le nombre de foyer est de : %d",10,0
reponseValeurRandomPoints: db "Le nombre de points est de : %d",10,0
reponseDégradéCouleur: db "La palette de couleur choisie est la numéro :",10,0
fmt_scan: db "%d",0

i: dw 0
j: dw 0

flag: db 0 ; Variable qui va servir pour éviter le bug qui exécute 2 fois notre code dessin et quui fait une erreur de segmentation à cause de la gestion des évènements

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
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
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
push rbp
dessin:

; Si le flag est à 1 alors on saute à la fin de notre code pour éviter de dessiner 2 fois (erreur de segmentation)
cmp byte[flag],1
je flush

mov byte[flag],1 ; On met le flag à 1 

foyerRandomYesOrNo:

    mov rdi,demandeSiFoyerRandom
    mov rax,0
    call printf

    mov rdi,fmt_scan
    mov rsi,reponse
    mov rax,0
    call scanf

    cmp byte[reponse],1
    jne foyerRandomNo

foyerRandomYes :


    movzx rdi,word[maxFoyer]
    call random
    inc ax
    mov word[nbFoyer],ax

    jmp pointsRandomYesOrNo


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



pointsRandomYesOrNo:

    mov rdi,demandeSiPointsRandom
    mov rax,0
    call printf

    mov rdi,fmt_scan
    mov rsi,reponse
    mov rax,0
    call scanf

    cmp byte[reponse],1
    jne pointsRandomNo

pointsRandomYes:

    movzx rdi,word[maxPoint]
    call random
    inc ax
    mov word[nbPoints],ax

    jmp paletteCouleur

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

paletteCouleur:

    mov rdi,décritPalette1
    mov rax,0
    call printf

    mov rdi,décritPalette2
    mov rax,0
    call printf

    mov rdi,décritPalette3
    mov rax,0
    call printf

demandePalette :

    mov rdi, demandeDégradéCouleur
    mov rax, 0
    call printf

    mov rdi, fmt_scan
    mov rsi, numPaletteChoisie
    mov rax, 0
    call scanf

    cmp byte[numPaletteChoisie], 1
    jl demandePalette

    cmp byte[numPaletteChoisie], 3
    jg demandePalette

affichageValeurs:

    mov rdi,reponseValeurRandomFoyer 
    movzx rsi,word[nbFoyer]
    mov rax,0 
    call printf

    mov rdi,reponseValeurRandomPoints
    movzx rsi,word[nbPoints]
    mov rax,0 
    call printf

    mov rdi,reponseDégradéCouleur
    mov rax,0
    call printf

    cmp byte[numPaletteChoisie], 1
    je palette1Affichage

    cmp byte[numPaletteChoisie], 2
    je palette2Affichage

    cmp byte[numPaletteChoisie], 3
    je palette3Affichage


    palette1Affichage:

        mov rdi, décritPalette1
        mov rax, 0
        call printf

        jmp initialisation

    palette2Affichage:

        mov rdi, décritPalette2
        mov rax, 0
        call printf

        jmp initialisation

    palette3Affichage:

        mov rdi, décritPalette3
        mov rax, 0
        call printf


initialisation:

pop rbp


boucleInitCoordFoyers:

    movzx rsi,word[i]

    mov rdi,TAILLE_FENETRE
    call random
    mov word[coordFoyersX+rsi*WORD],ax
    

    mov rdi,TAILLE_FENETRE
    call random
    mov word[coordFoyersY+rsi*WORD],ax

    inc word[i]

    mov ax,word[i]
    cmp ax,word[nbFoyer]
    jb boucleInitCoordFoyers 

mov word[i],0

boucleInitCoordPoints:

    movzx rsi,word[i]

    mov rdi,TAILLE_FENETRE
    call random
    mov word[coordPointsX+rsi*WORD],ax

    mov rdi,TAILLE_FENETRE
    call random
    mov word[coordPointsY+rsi*WORD],ax

    inc word[i]

    mov ax,word[i]
    cmp ax,word[nbPoints]
    jb boucleInitCoordPoints

mov word[i],0


boucleExplorePoints:
    movzx esi,word[i]
    mov word[j],0

    movzx eax,word[coordPointsX+esi*WORD]
    mov [x1],eax

    movzx eax,word[coordPointsY+esi*WORD]
    mov [y1],eax

    mov dword[minDistance],TAILLE_FENETRE

    boucleExploreFoyers:

        movzx esi,word[j]
         
        movzx edi,word[coordFoyersX+esi*WORD]
        movzx esi,word[coordFoyersY+esi*WORD]
        movzx edx,word[x1]
        movzx ecx,word[y1]
        
        call calculDistance

        movzx esi,word[j]
        
        cmp eax,dword[minDistance]
        jb ifDistanceInf

        jmp incJ

        ifDistanceInf:
        
        mov dword[minDistance],eax

        movzx eax,word[coordFoyersX+esi*WORD]
        mov dword[x2],eax
        movzx eax,word[coordFoyersY+esi*WORD]
        mov dword[y2],eax

        incJ:

        inc word[j]

        mov ax,word[j]
        cmp ax,word[nbFoyer]
        jb boucleExploreFoyers


    mov di,NB_COLOR
    call random ; On génére un nombre aléatoire entre 0 et 5 afin de choisir une couleur aléatoire dans le tableau colors
    
    cmp byte[numPaletteChoisie], 1
    je palette1

    cmp byte[numPaletteChoisie], 2
    je palette2

    cmp byte[numPaletteChoisie], 3
    je palette3

    palette1:
    mov ebx,dword[colors1+eax*DWORD] ; On stocke la couleur dans ebx
    jmp changeColor

    palette2:
    mov ebx,dword[colors2+eax*DWORD] ; On stocke la couleur dans ebx
    jmp changeColor

    palette3:
    mov ebx,dword[colors3+eax*DWORD] ; On stocke la couleur dans ebx

    changeColor:
    mov rdi,qword[display_name]
    mov rsi,qword[gc]
    mov edx, ebx	
    call XSetForeground ; On change la couleur pour la couleur choisie aléatoirement

    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,qword[gc]
    movzx ecx,word[x1]	; coordonnée source en x
    movzx r8d,word[y1]	; coordonnée source en y
    movzx r9d,word[x2]	; coordonnée destination en x
    push qword[y2]	; coordonnée destination en y
    call XDrawLine

    inc word[i]

    mov ax,word[i]
    cmp ax,word[nbPoints]
    jb boucleExplorePoints




flush:
    mov rdi,qword[display_name] 
    call XFlush
    jmp boucle ; On retourne à la boucle des events pour attendre un nouvel évènement
    mov rax,34
    syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	
