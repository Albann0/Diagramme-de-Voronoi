global random  ; La fonction random permet de générer des nombres aléatoires entre 0 et la valeur passée en paramètre (di)
random:


xor rdx,rdx ; Permet de mettre dx à 0 afin d'éviter des conflits avec les valeurs précédentes
retry:
rdrand rax ; On utilise rdrand pour générer un nombre aléatoire, rdrand pren un registre d'au moins 16 bits et génére un nb dans ce range, ici on le stocke dans ax
jnc retry
div rdi ; Comme en C, afin d'avoir un range précis il faut récupérer le reste du nombre généré par di (le nombre max qu'on veut) pour avoir un nombre entre 0 et di. Div di met le reste de ax/di dans dx, dx sera notre nb aléatoire entre 0 et di-1

mov rax,rdx ; On met la valeur de retour de la fonction dans ax (convention)

ret ; Fin de la fonction