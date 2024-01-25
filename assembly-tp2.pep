;Ce programme de traitement de texte forme un nouveau texte a partir du texte initial 
;en remplaçant une séquence de caractères spécifiques par une autre séquence de caractères.
;(utilise PEP8)
;


;Programme principal
main:            CALL        vidage
                 CALL        saisir
                 LDX         buffTxtI,i
                 CALL        affTxt
                 CALL        remp1
                 LDX         buffTxtF,i
                 CALL        affTxt   
                 BR          fin
;
;
;Programme qui alloue de l'espace dans la pile et mets toutes les valeurs à 0
;Resultat: une pile complètement nettoyé. 
videur:          .EQUATE     0    		;2d
vidage:          LDA         0,i
                 LDX         2,i
createur:        CPX         30,i
                 BREQ        finVide
                 SUBSP       2,i  		;création de videur 
                 ADDX        2,i
                 STA         videur,s         
                 BR          createur
finVide:         ADDSP       28,i 
                 RET0
;
;
;Programme pour la saisie
nbOctets:        .EQUATE     0                	;2d Variable locale ;Nombre d'octets pour la saisie
saisir:          SUBSP       2,i              	;empile nbOctets
		 ;Saisir la chaine de départ
                 LDA         buffTxtI,i         
                 LDX         50,i              	           
                 STRO        msgDebut,d     
                 CALL        STRI             	;STRI(buffer,size)   
		 ;Saisir la chaine a remplacer                               
                 STX         nbOctets,s                
                 LDA         txt1,i          
                 LDX         11,i              	
                 STRO        msgM,d
                 CALL        STRI             	;STRI(txt1,size)   
		 ;Saisir la chaine de remplacement           	
                 LDA         0,i
                 LDX         txt1,i
                 CALL        enlevTxt                         
                 LDA         txt2,i           
                 LDX         11,i              
                 STRO        msgMRemp,d 
                 CALL        STRI             	;STRI(txt2,size)
		 ;Place un '\x00' au premier charactère '\n' que l'on detecte
                 LDA         0,i
                 LDX         txt2,i 
                 CALL        enlevTxt
                 CHARO       '\n',i
                 ADDSP       2,i              	;dépile nbOctets
                 RET0                         	;exit();
;
; STRI: lit une ligne dans un tampon et place '\x00' à la fin
; In:  A=Adresse du tampon
;      X=Taille du tampon en octet
; Out: A=Adresse du tampon (inchangé)
;      X=Nombre de caractères lu (ou offset du '\x00')
; Err: Avorte si le tampon n'est pas assez grand pour
;      stocker la ligne et le '\0' final
saveA:           .EQUATE 0                    	;2d Variable locale stocker le contenu de A
saveX:           .EQUATE 2                    	;2d Variable locale stocker le contenu de X
STRI:            SUBSP 4,i                    	;réserve saveX saveA 
                 STA         saveA,s          	;sauve A
                 ADDX        saveA,s 
                 STX         saveX,s          	;sauve A+X 
                 LDX         saveA,s          	;X = saveA
striLoop:        CPX         saveX,s          	;while(true) {
                 BRGE        striErr          	;if(X>=saveX) throws new Error();
                 CHARI       0,x              	;*X = getChar()
                 LDA         0,i         
                 LDBYTEA     0,x
                 CPA         '\n',i      
                 BREQ        deuxieme     
                 CPA         '\x00',i    
                 BREQ        striFin          	;if(*X=='\x00') break
                 ADDX        1,i              	;X++;
                 BR          striLoop         	;} // fin boucle
deuxieme:        SUBX        1,i              	;va voir le caractère précédent
                 LDA         0,i
                 LDBYTEA     0,x              	;lit le caractère précédent
                 CPA         '\n',i      
                 BREQ        striFin
                 ADDX        2,i              	;remet au pointeur au caractère d'avant et ajoute 1
                 BR          striLoop       
striFin:         ADDX        1,i               
                 LDBYTEA     0,i              
                 STBYTEA     0,x                ;*X='\x00'
                 SUBX        saveA,s            ;X = X-saveA  Adresse_Maximale - Adresse_Début = nombre d'octets utilisés
                 LDA         saveA,s            ;restaure A
                 ADDSP       4,i                ;depile saveA saveX
                 RET0                           ;return
striErr:         STRO        msgStriE,d  
                 BR          fin   
;
;
;Programme d'affichage
; In:  A=Ancienne position de nbOctets 
;      X=Adresse du tampon initial
; Out: A=Positionné a l'octet de fin de la chaine a affichée
;      X=l'adresse du tampon inchangée
; fin: Affiche le nombre d'octets spécifiés
affTxt:          LDA         -2,s     	        ;se positionne sur pile-2 
loopAff:         CHARO       0,x
                 ADDX        1,i
                 SUBA        1,i
                 CPA         0,i
                 BRGE        loopAff
                 CHARO       '\n',i
                 RET0
enlevTxt:        LDBYTEA     0,x
                 CPA         '\n',i
                 BREQ        loopFin
                 ADDX        1,i              
                 BR          enlevTxt
loopFin:         LDBYTEA     0,i
                 STBYTEA     0,x
                 RET0         
;
;
;Programme de remplacement  
; In:  A=Adresse du txt1
;      X=Adresse du txt2
; Out: A=Adresse du tampon final
;      X=Retourne le nombre d'octet du tampon final
; fin: Retourne le nombre d'octets du texte formé            
nbOctFin:        .EQUATE     0    	       ;2d Variable locale ;Nombre d'octets du bufferTxtF
remp1:           SUBSP       2,i  	       ;reserve pour #nbOctFin
                 LDA         0,i
                 STA         0,s  	       ;mets le nombre d'octets a 0 dans la pile du processeur
                 LDX         buffTxtI,i
                 CALL        split
                 CALL        join 
                 RET2             	       ;désaloue nbOctFin seulement
;
;
;Programme du split 
; In:  A=Texte initial (txtInit) a transformer en tableau de textes
;      X=Texte séparateur (sep1 = txt1) qui sert comme unité de découpage du texte initial
; Out: A=Nombre de sous-chaines suite au découpage.
;      X=Nombre de caracteres dans sep1.
; fin: Met notre buffTxtI dans tabSJ a partir de la troisième case du tableau. 
;      La première spécifie le nombre de caracteres dans sep1 
;      et la deuxième le nombre de sous-chaines suite au découpage.
lettre:          .EQUATE     0     	       ;2d Variable locale ;Sauvegarde la lettre lu dans txtInit pour pouvoir faire la comparaison
debutVer:        .EQUATE     2     	       ;2d Variable locale ;Début vérification 
addrSous:        .EQUATE     4     	       ;2d Variable locale ;Position du début de l'adresse séparé
posiSep:         .EQUATE     6     	       ;2d Variable locale ;Position dans le séparateur
posiTxt:         .EQUATE     8     	       ;2d Variable Locale ;Position dans le text où l'on vérifie s'il correspond au séparateur. 
txtInit:         .EQUATE     10    	       ;2d Variable Locale ;BufferTextInit
sep1:            .EQUATE     12    	       ;2d Variable Locale ;txt1
cmptSep:         .EQUATE     14    	       ;2d Variable Locale ;Nombre de champs séparés
nbOctSep:        .EQUATE     16    	       ;2d Variable locale ;Nombre d'octets du séparateur txt1
;
split:           SUBSP       18,i              ;réserve nbOctSep ,cmptSep ,sep1 ,txtInit ,posiTxt, posiSep, addrSous, debutVer, lettre 
                 LDA         0,i                
                 STA         nbOctSep,s        ;vide les deux champs qui étaient utilisés par SaveA et SaveX
                 STA         cmptSep,s      
                 STX         txtInit,s
                 STX         posiTxt,s         ;sauvegarde l'adresse de début de txtInit
                 LDX         txt1,i            ;charge où se trouve le sep1
                 STX         sep1,s
                 STX         posiSep,s         ;sauvegarde la position initiale du séparateur
                 CALL        sizeSep
                 LDX         posiTxt,s         ;restaure contenu de X (adresse de début de txtInit)
                 STX         addrSous,s        ;sauvegarde le début de la chaine          
parcourt:        LDBYTEA     0,x               ;lit le caractère à la position x de txtInit
                 CPA         '\n',i
                 BREQ        vFinParc
                 CPA         '\x00',i          ;compare si c'est le caractère '\x00', si c'est le cas on a fini le parcourt
                 BREQ        finParc           ;on a atteint la fin de notre texte et on a tout mis dans notre tabSJ
                 STA         lettre,s          ;sauvegarde le caractère lu de txtInit
                 LDX         posiSep,s         ;prends la position du séparateur
                 LDBYTEA     0,x               ;caractère du séparateur
                 CPA         lettre,s          ;compare le caractère du séparateur avec celui du txtInit
                 BREQ        restCom  
                 LDX         posiTxt,s         ;remets le pointeur de txtInit
                 ADDX        1,i               ;incrémente de 1
                 STX         posiTxt,s 
                 BR          parcourt          ;boucle infinie jusqu'à ce qu'on hit le '\n' et '\x00'
restCom:         LDX         posiTxt,s
                 STX         debutVer,s
blCheck:         LDX         posiTxt, s 
                 ADDX        1,i
                 STX         posiTxt,s         ;sauve la position du pointeur d'adresse texte temp
                 LDBYTEA     0,x               ;caractère à pointeur texte temp +1
                 STA         lettre,s          ;sauve caractère à la position du pointeur texte temp+1
                 LDX         posiSep,s
                 ADDX        1,i
                 STX         posiSep,s
                 LDBYTEA     0,x
                 CPA	      '\x00',i
                 BREQ        soutrouv          ;on est arrivé à la fin du séparateur et on a trouvé la sous-chaine                
                 CPA         '\n',i
                 BREQ        vFinBl
                 CPA         lettre,s          ;compare lettre séparateur avec lettre texte
                 BREQ        blCheck 
blFaux:          LDX         debutVer,s	  ;si ce n'est pas la même lettre
                 ADDX        1,i          
                 STX         posiTxt,s         ;remets posiTxt â notre début de verification +1 et on passe à la prochaine lettre
                 LDX         sep1,s
                 STX         posiSep,s         ;replace le posiSeparateur à sa place initiale.
                 LDX         posiTxt,s         ;replace posi pour la verif
                 BR          parcourt
vFinBl:          ADDX        1,i               ;déplace au prochain caractère
                 STX         posiTxt,s
                 LDBYTEA     0,x               ;lit le caractère à la position x + 1 de txtInit
                 CPA         '\x00',i          ;compare si c'est le caractère '\x00'. Si c'est le cas on a fini le parcourt et la chaine n'est pas entièrement présente
                 BREQ        finParc           ;Interrompe la vérification car on est arrivé à la fin de txtInit sans complètement trouver le séparateur
                 SUBX        1,i                                                           
                 STX         posiTxt,s    
                 BR          blCheck                                              
soutrouv:        LDA         nbOctSep,s        ;cherche nombre octets sep1
                 LDX         tabSJ,i     
                 STA         0,x               ;sauvegarde le nombre d'octets du séparateur dans la première case du tabSJ
                 ADDX        2,i               ;va a la case2
                 LDA         cmptSep,s         ;cherche notre compteur de sous-chaines 
                 ADDA        1,i               ;incrémente de 1
                 STA         cmptSep,s         ;sauvegarde le nombre de sous-chaines + 1 dans le cmptSep
                 STA         0,x               ;sauvegarde le nombre de sous-chaines + 1 dans la deuxième case
                 LDA         0,i  
deplace:         CPA         cmptSep,s         ;déplace le tableau pour autant de sous-chaines trouvés.
                 BREQ        bonnepos     
                 ADDX        2,i    
                 ADDA        1,i
                 BR          deplace
bonnepos:        LDA         addrSous,s        ;load la position de l'adresse du début de la sous-chaine.
                 STA         0,x               ;place l'addresse de début de la sous-chaien dans la case du tabSJ
                 LDX         sep1,s            
                 STX         posiSep,s         ;remets notre posiSep à l'adresse initiale de sep1
                 LDX         posiTxt,s         ;cherche notre position dans le texte
                 STX         addrSous,s        ;pointe l'addrSous vers là où l'on se trouve présentement. C'est maintenant le début de la deuxième sous-chaine.
                 LDA         0,i
                 BR          parcourt            
vFinParc:        ADDX        1,i               ;déplace au prochain charactère
                 STX         posiTxt,s
                 LDBYTEA     0,x               ;lit le caractère à la position X + 1 de txtInit
                 CPA         '\x00',i          ;compare si c'est le charactère \0. Si c'est le cas on a fini le parcourt
                 BREQ        soutrouv          ;ajoute le reste du txtInit comme sous-chaine. 
                 BR          parcourt          ;boucle infinie jusqu'à ce qu'on hit le '\n' et '\x00'                                                                    
finParc:         ADDSP       18,i              ;dépile nbOctSep cmptSep sep1 ,txtInit ,posiTxt, posiSep, addrSous, debutVer, lettre 
                 RET0        
;
;
;Programme qui calcul le nbOctets de txt1
; In:  X=Adresse de txt1
; Out: X=Adresse finale de txt1 (l'adresse incrémente à chaque fois que la lettre lu n'est pas '\x00', 
;      on soustrait txt1 a X, puis est stockée dans nbOctSep)
; fin: Retourne le nombre d'octets du séparateur.
sizeSep:         LDBYTEA     0,x
                 CPA         '\x00',i
                 BREQ        finSep
                 ADDX        1,i              
                 BR          sizeSep       
finSep:          SUBX        txt1,i
                 STX         18,s              ;sauvegarde la taille de sep1 dans nbOctSep  (.EQUATE 16 + RET = 18)     
                 RET0
;
;
;Programme du join
; In:  A=L'adresse du sep2
;      X=L'adresse du tabSJ[1]
; fin: Retourne le nombre d'octets utilisés lors de la formation du nouveau texte dans le tampon final
;      Permet aussi la création du tableau AddTpar 
iterator:        .EQUATE     0                 ;2d Variable locale ;Itérateur de n
tempAddr:        .EQUATE     2                 ;2d Variable locale ;Addresse temporaire qui contient l'adresse de tabSJ qu'on est en train de lire        
pAddTpar:        .EQUATE     4                 ;2d Variable locale ;Poiteur pour l'addresse de adrTpars
sep2:            .EQUATE     6                 ;2d Variable locale ;Addresse de txt2
cmptSep1:        .EQUATE     8                 ;2d Variable Locale ;Nombre de champs séparés 
nbOctSe1:        .EQUATE     10                ;2d Variable locale ;Nombre d'octets du séparateur txt1
join:            SUBSP       12,i              ;empile  nbOctSe1 cmptSep1 sep2 pAddTpar tempAddr iterator
                 LDA         0,i
                 STA         tempAddr,s        ;remets à 0
                 STA         pAddTpar,s        ;remets à 0
                 LDA         txt2,i
                 STA         sep2,s            ;stocke l'adresse de début de txt2 dans sep2
                 LDA         1,i
                 STA         iterator,s        ;remets à 1 notre itérateur
loopDplc:        LDA         0,i
                 LDX         tabSJ,i
                 ADDX        2,i               ;passe à la case tabSJ[1]
                 BR          deplace2
loopJoin:        CPA         cmptSep1,s        ;A= iterateur
                 BREQ        lectAFin
                 LDA         0,x               
                 STX         tempAddr,s        ;stocke l'addresse de tabSJ où on travaille présentement.
                 LDX         adrTpars,i
                 STA         0,x               ;stocker dans adrTpars[0]
                 LDX         tempAddr,s        ;reprends l'adresse où l'on travaillait dans tabSJ
                 LDA         2,x               ;cherche le contenu de la prochaine case
                 LDX         adrTpars,i
                 SUBA        nbOctSe1,s        ;obtient l'addresse - nbOctets de sep1 = addresse où l'on arrête de lire les caractères.
                 STA         2,x               ;stocker dans adrTpars[1]
                 CALL        copy        
                 CALL	      addSep2
                 LDA         iterator,s
                 ADDA        1,i               ;iterator++
                 STA         iterator,s
                 BR          loopDplc          ;ceci est le while
lectAFin:        LDA         0,i
                 LDA         0,x               ;obtenir l'adresse à laquelle on pointe dans tabSJ
                 STA         tempAddr,s        ;stocker l'adresse de départ
                 LDX         tempAddr,s        ;load l'addresse du caractère de début de la dernière sous-chaine  
blectFin:        LDA         0,i
                 LDBYTEA     0,x               ;lit le caractère de cette sous-chaine finale
                 CPA         '\x00',i     
                 BREQ        finJoin           ;si le caractère lu est \x00 alors on est arrivé à la fin
                 ADDX        1,i               ;tempAddr = tempAddr++
                 STX         tempAddr,s   
                 LDX         buffTxtF,i
                 ADDX        14,s              ;addresse buffTxtF + nombre octets qu'on a déjà rentré
                 STBYTEA     0,x               ;sauvegarde dans buffTxtF le caractère
                 LDA         14,s                            
                 ADDA        1,i               ;nbOctFin ++
                 STA         14,s           
                 CPA         100,i
                 BRGT        joinErr           ;if(nbOctFin > 100) alors on a un débordement tampon de fin
                 LDX         tempAddr,s
                 BR          blectFin
finJoin:         ADDSP       12,i              ;empile  nbOctSe1 cmptSep1 sep2 pAddTpar tempAddr iterator
                 RET0                        
joinErr:         STRO        msgFinE,d  
                 BR          fin                
;
;
;Programme du copy 
; In:  A=L'adresse du buffer final
;      X=L'adresse initiale de adrTpars (adrTpars[0])
; Out: A=L'adresse du buffer final inchangée
;      X=L'adresse finale de adrTpars (adrTpars[2])
; fin: Retourne l'adresse de la partie libre du tampon buffTxtF.
addrTemp:        .EQUATE     0                 ;2d Variable locale ;Addresse du caractère
copy:            SUBSP       2,i               ;empile addrTemp
                 LDA         0,i
                 STA         addrTemp,s;
                 LDX         adrTpars,i
                 LDA         0,x
                 STA         8,s               ;.EQUATE     4+ 4 = 8 = pAddTpar
blCopy:          CPA         2,x               ;compare adrTpars[0] avec adrTpars[1]
                 BREQ        finCopy
                 STA         addrTemp,s
                 LDX         addrTemp,s        ;load l'addresse du caractère de buffTxtI
                 LDA         0,i               ;vide le contenu de A
                 LDBYTEA     0,x               ;load le caractère à l'addresse de buffTxtI 
                 LDX         buffTxtF,i
                 ADDX        18,s              ;addresse buffTxtF + nombre octets qu'on a déjà rentré
                 STBYTEA     0,x               ;sauvegarde dans buffTxtF le caractère
                 LDA         18,s                           
                 ADDA        1,i               ;nbOctFin ++
                 STA         18,s         
                 CPA         100,i
                 BRGT        joinErr           ;if(nbOctFin > 100) alors on a un débordement tampon de fin
                 LDA         8,s
                 ADDA        1,i               ;pAddTpar = pAddTpar++
                 STA         8,s
                 LDX         adrTpars,i                 
                 BR          blCopy
finCopy:         RET2               	       ;dépile addrTemp    
;
;
;Programme qui déplace X vers la case de la sous-chaine dans tabSJ
;Incrémente de deux l'addresse de tabSJ jusqu'à ce que 
;le nombre de déplacements == iterator
; In:  A= 0
;      X= addresse tabSJ[1]
; Out: A= iterator
;      X= addresse de la sous-chaine qu'on va lire           
deplace2:        CPA         iterator,s      
                 BREQ        place     
                 ADDX        2,i    
                 ADDA        1,i
                 BR          deplace2
place:           BR          loopJoin
                 RET0
;
;
;Programme qui ajoute le sep2
; In:  A=Adresse de sep2
;      X=Nombre d'octets du buffer final
; Out: A=Adresse de sep2 inchangée
;      X=Nombre d'octets du buffer final
; fin: Retourne le buffer final avec les sep2 ajoutés
addSep2:         LDX         8,s      	 ;sep2 +2
bAddSep:         LDA         0,i               ;vide le contenu de A
                 LDBYTEA     0,x      	 ;lit le caractère de sep2
                 CPA         '\x00',i
                 BREQ	     fAddSep2
                 LDX         buffTxtF,i
                 ADDX        16,s              ;addresse buffTxtF + nombre octets (déjà entrée)
                 STBYTEA     0,x               ;sauvegarde dans buffTxtF le caractère
                 LDA         16,s                           
                 ADDA        1,i               ;nbOctFin ++
                 STA         16,s         
                 CPA         100,i
                 BRGT        joinErr           ;if(nbOctFin > 100) débordement tampon de fin         
                 LDX         8,s      
                 ADDX        1,i               ;sep2 = sep2++
                 STX         8,s
                 BR          bAddSep
fAddSep2:        LDA         txt2,i
                 STA         8,s               ;replace sep2 à l'addresse de début
                 RET0
;
;
;Commande pour terminer le programme
fin:             STOP
;
;              
;Variables globales
buffTxtI:        .BLOCK      50                ; 1c20a Buffer for the string   
buffTxtF:        .BLOCK      100               ; 1c20a adresse de fin de tampon 
txt1:            .BLOCK      11                ; 1c11a [ÉTAIT 10 mais pusiqu'on enlève le deuxième \n et ensuite on fait la même chose pour le premier, on doit avoir une taille de 11 ] 
txt2:            .BLOCK      11                ; 1c11a 
tabSJ:           .BLOCK      304               ; 2d10a  
adrTpars:        .BLOCK      6                 ; 2d3a   
msgDebut:        .ASCII      "Texte Initial : \n\x00" 
msgStriE:        .ASCII      "Débordement du tampon de saisie.\x00"
msgM:            .ASCII      "Mot a remplacer : \n\x00"
msgMRemp:        .ASCII      "Mot de remplacement : \n\x00"
msgFinE:         .ASCII      "Débordement du tampon du résultat.\x00"
                 .END