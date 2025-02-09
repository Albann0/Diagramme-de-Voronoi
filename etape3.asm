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

display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1



coordFoyersX: resw 200
coordFoyersY: resw 200


coordPointsX: resw 30000
coordPointsY: resw 30000


nbFoyer: resw 1
nbPoints: resw 1
reponse: resb 1



section .data

event:		times	24 dq 0

x1:	dd	0
x2:	dd	0
y1:	dd	0
y2:	dd	0

colors: dd 0x9400d3, 0x7c1ddc, 0x653ae5, 0x4d56ed, 0x3673f6, 0x1e90ff

maxFoyer: dw 200
maxPoint: dw 30000
minDistance: dd 0

demandeSiFoyerRandom: db "Voulez-vous que le nombre de foyer soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeSiPointsRandom: db "Voulez-vous que le nombre de points soit déterminé aléatoirement (1 si oui, autre si non) : ",0
demandeNbFoyer : db "Entrez le nombre de foyer (entre 1 et 200) : ",0
demandeNbPoints : db "Entrez le nombre de points (entre 1 et 30000): ",0
reponseValeurRandomFoyer: db "Le nombre de foyer est de : %d",10,0
reponseValeurRandomPoints: db "Le nombre de points est de : %d",10,0
fmt_scan: db "%d",0

test1: db "foyer x : %d",10,0
test2: db "foyer y : %d",10,0

test: db 0
i: dw 0
j: dw 0

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
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
push rbp
dessin:

cmp byte[test],0
jne TEST

foyerRandomYesOrNo:

mov rdi,demandeSiFoyerRandom
mov rax,0
call printf

mov rdi,fmt_scan
mov rsi,reponse
mov rax,0
call scanf

cmp byte[reponse],1
je foyerRandomYes


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

jmp pointsRandomYesOrNo

foyerRandomYes :


mov di,word[maxFoyer]
call random
mov word[nbFoyer],ax


pointsRandomYesOrNo:

mov rdi,demandeSiPointsRandom
mov rax,0
call printf



mov rdi,fmt_scan
mov rsi,reponse
mov rax,0
call scanf

cmp byte[reponse],1
je pointsRandomYes

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

jmp affichageValeurs


pointsRandomYes:

mov di,word[maxPoint]
call random
mov word[nbPoints],ax

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


boucleInitCoordFoyers:

    movzx rsi,word[i]

    mov di,400
    call random
    mov word[coordFoyersX+rsi*WORD],ax
    

    mov di,400
    call random
    mov word[coordFoyersY+rsi*WORD],ax

    

    inc word[i]

    mov ax,word[i]
    cmp ax,word[nbFoyer]
    jb boucleInitCoordFoyers 

mov word[i],0



boucleInitCoordPoints:

    movzx rsi,word[i]

    mov di,400
    call random
    mov word[coordPointsX+rsi*WORD],ax
    

    mov di,400
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

    mov dword[minDistance],400

   

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

    
  

    ; push rbp
    ; mov rdi,test1
    ; movzx rsi,word[coordFoyersX]
    ; mov rax,0
    ; call printf

    ; mov rdi,test2
    ; movzx rsi,word[coordFoyersY]
    ; mov rax,0
    ; call printf

    ; mov rdi,test1
    ; movzx rsi,word[x2]
    ; mov rax,0
    ; call printf

    ; mov rdi,test2
    ; movzx rsi,word[y2]
    ; mov rax,0
    ; call printf
    ; pop rbp

    mov di,6
    call random
    
    mov ebx,dword[colors+eax*DWORD]


    mov rdi,qword[display_name]
    mov rsi,qword[gc]
    mov edx, ebx	
    call XSetForeground


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



; mov word[i],0
    
;     push rbp

;     TESTBOUCLE:

;         movzx rbx, word[i]

;         mov rdi,test1
;         movzx rsi,word[coordFoyersX+rbx*WORD]
;         mov rax,0
;         call printf

        
;         mov rdi,test2
;         movzx rsi,word[coordFoyersY+rbx*WORD]
;         mov rax,0
;         call printf

;         inc word[i]

;         mov ax,word[i]
;         cmp ax,word[nbFoyer]
;         jb TESTBOUCLE



;         pop rbp


; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################

inc byte[test]

TEST:

; ICI SUPP FLUSH CAR ASKIP SOURCE PB SEGMENTATION CAR APPEL 2 EVENTS QUAND LANCE PROGRAMME DUCOUP ENLEVER LE TRUC TEST

jmp flush

flush:
mov rdi,qword[display_name] ; TEMPORAIREMENT ENLEVE CAR FAIT ERREUR DE SEGMENTATION, retourne en haut et re exécute tout ????
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	






global random 
random:

xor dx,dx
rdrand ax
div di ; reste de ax/di dans dx
mov ax,dx

ret


global calculDistance
calculDistance:

mov eax,edi
sub eax,edx
mul eax
mov ebx,eax ; mul marche que avec ax donc pas le choix de stocker dans bx

mov eax,esi
sub eax,ecx
mul eax


add ebx,eax ; en gros j'ai fait (x1-x2)² + (y1-y2)² il faut encore que je calcule la racine carré de ça pour trouver la distance

; jsuis vraiment pas sur de comment calculer la racine carrée lol

mov ecx, 0
xor rax,rax

boucleRacineCarrée:

inc ecx

mov eax,ecx
mul eax

cmp eax,ebx
jg finBoucleRacineCarrée

jmp boucleRacineCarrée

finBoucleRacineCarrée :
sub ecx,1
mov eax,ecx


ret




