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
%define NB_COLOR 15
%define MAX_HEXA_COLOR 16777216

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
foyerColor: resd 200 ; Tableau qui contiendra la couleur de chaque foyer
coordPointsX: resw TAILLE_FENETRE ; Tableau de taille TAILLE_FENETRE car coordonnées de 0 à 399
coordPointsY: resw TAILLE_FENETRE ; Tableau de taille TAILLE_FENETRE car coordonnées de 0 à 399
colors: resd 15 ; Tableau qui contiendra nos couleurs utilisés dans l'instance du programme

nbFoyer: resw 1
reponse: resb 1

section .data

; Les variables initialisées du prof
event:		times	24 dq 0
x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

; Nos variables initialisées
colorsDefault: dd 0xFF0000, 0x00FF00, 0x0000FF, 0xFFFF00, 0xFF00FF, 0x00FFFF, 0x800000, 0x808000, 0x008000, 0x800080, 0x008080, 0x000080, 0xC0C0C0, 0xFFA500, 0xA52A2A  ; Palette de couleur par défaut

maxFoyer: dw 200
maxPoint: dw 30000
minDistance: dd 0
indiceFoyerMin : dw 0
colorRandomOrNot: db 0

demandeSiFoyerRandom: db "Voulez-vous que le nombre de foyer soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeNbFoyer: db "Entrez le nombre de foyer (entre 1 et 200) : ",0
demandeSiCouleurRandom: db "Voulez-vous que la couleur des foyers soit déterminée aléatoirement (1 si oui, autre pour les couleurs par défaut) : ",0
reponseValeurRandomFoyer: db "Le nombre de foyer est de : %d",10,0
reponseCouleurs: db "Les couleurs des foyers sont :",10,0
reponseCouleursHexa: db "0x%x",10,0
fmt_scan: db "%d",0

i: dw 0
j: dw 0
k: dw 0

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

    jmp colorRandomYesorNo

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

colorRandomYesorNo:

    mov rdi,demandeSiCouleurRandom
    mov rax,0
    call printf

    mov rdi,fmt_scan
    mov rsi,reponse
    mov rax,0
    call scanf

    mov word[i],0

    cmp byte[reponse],1
    je colorRandomYes

    cmp byte[reponse],1
    jne colorRandomNo

colorRandomYes:

    movzx rsi,word[i]

    mov rdi, MAX_HEXA_COLOR  ; 0xFFFFFF + 1 pour inclure 0xFFFFFF car random ne prend pas en compte la borne supérieure
    call random
    mov dword[colors+esi*DWORD],eax

    inc word[i]

    mov ax,word[i]
    cmp ax,NB_COLOR
    jb colorRandomYes
    jmp affichageValeurs
    

colorRandomNo:

    movzx rsi,word[i]

    mov eax,dword[colorsDefault+rsi*DWORD]
    mov dword[colors+rsi*DWORD],eax

    inc word[i]
    mov ax,word[i]
    cmp ax,NB_COLOR
    jb colorRandomNo
    jmp affichageValeurs





affichageValeurs:

    mov rdi,reponseValeurRandomFoyer 
    movzx rsi,word[nbFoyer]
    mov rax,0 
    call printf

    mov word[i],0

    mov rdi,reponseCouleurs
    mov rax,0
    call printf

affichageCouleurs:

    movzx rbx,word[i]

    mov rdi, reponseCouleursHexa
    mov esi,[colors+rbx*DWORD]
    mov rax,0
    call printf

    inc word[i]
    mov ax,word[i]
    cmp ax,15
    jb affichageCouleurs



pop rbp

mov word[i],0

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

boucleInitColorFoyers:

    movzx rsi,word[i]

    mov rdi,NB_COLOR
    call random
    mov ebx,dword[colors+eax*DWORD]
    mov dword[foyerColor+rsi*DWORD],ebx


    inc word[i]

    mov ax,word[i]
    cmp ax,word[nbFoyer]
    jb boucleInitColorFoyers 

mov word[i],0

boucleInitCoordPoints:

    movzx rsi,word[i]

    mov ax,word[i]
    
    mov word[coordPointsX+rsi*WORD],si
    
    mov word[coordPointsY+rsi*WORD],si

    inc word[i]

    mov ax,word[i]
    cmp ax,TAILLE_FENETRE
    jb boucleInitCoordPoints

mov word[i],0


boucleExplorePointsX :
    movzx esi,word[i]
    

    movzx eax,word[coordPointsX+esi*WORD]
    mov [x1],eax

    
    mov word[j],0

    boucleExplorePointsY:

        movzx edi,word[j]
        movzx eax,word[coordPointsY+edi*WORD]
        mov [y1],eax


        mov dword[minDistance],TAILLE_FENETRE

        mov word[k],0

        boucleExploreFoyers:

            movzx esi,word[k]
        
            movzx edi,word[coordFoyersX+esi*WORD]
            movzx esi,word[coordFoyersY+esi*WORD]
            movzx edx,word[x1]
            movzx ecx,word[y1]

            call calculDistance

            movzx esi,word[k]

            
            cmp eax,dword[minDistance]
            jb ifDistanceInf

            jmp incK

            ifDistanceInf:
            
            mov dword[minDistance],eax

            movzx eax,word[coordFoyersX+esi*WORD]
            mov dword[x2],eax
            movzx eax,word[coordFoyersY+esi*WORD]
            mov dword[y2],eax

            mov ax,word[k]
            mov word[indiceFoyerMin],ax

            incK:

            inc word[k]

            mov ax,word[k]
            cmp ax,word[nbFoyer]
            jb boucleExploreFoyers

        
        movzx rax,word[indiceFoyerMin]

        mov rdi,qword[display_name]
        mov rsi,qword[gc]
        mov edx, dword[foyerColor+rax*DWORD]	
        call XSetForeground


        mov rdi,qword[display_name]
        mov rsi,qword[window]
        mov rdx,qword[gc]
        movzx ecx,word[x1]	; coordonnée source en x
        movzx r8d,word[y1]	; coordonnée source en y
        movzx r9d,word[x2]	; coordonnée destination en x
        push qword[y2]	; coordonnée destination en y
        call XDrawLine

        inc word[j]

        mov ax,word[j]
        cmp ax,TAILLE_FENETRE
        jb boucleExplorePointsY

    inc word[i]

    mov ax,word[i]
    cmp ax,TAILLE_FENETRE
    jb boucleExplorePointsX

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
	
