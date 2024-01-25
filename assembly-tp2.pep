;Ce programme de traitement de texte forme un nouveau texte a partir du texte initial 
;en rempla�ant une s�quence de caract�res sp�cifiques par une autre s�quence de caract�res.
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
;Programme qui alloue de l'espace dans la pile et mets toutes les valeurs � 0
;Resultat: une pile compl�tement nettoy�. 
videur:          .EQUATE     0    		;2d
vidage:          LDA         0,i
                 LDX         2,i
createur:        CPX         30,i
                 BREQ        finVide
                 SUBSP       2,i  		;cr�ation de videur 
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
		 ;Saisir la chaine de d�part
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
		 ;Place un '\x00' au premier charact�re '\n' que l'on detecte
                 LDA         0,i
                 LDX         txt2,i 
                 CALL        enlevTxt
                 CHARO       '\n',i
                 ADDSP       2,i              	;d�pile nbOctets
                 RET0                         	;exit();
;
; STRI: lit une ligne dans un tampon et place '\x00' � la fin
; In:  A=Adresse du tampon
;      X=Taille du tampon en octet
; Out: A=Adresse du tampon (inchang�)
;      X=Nombre de caract�res lu (ou offset du '\x00')
; Err: Avorte si le tampon n'est pas assez grand pour
;      stocker la ligne et le '\0' final
saveA:           .EQUATE 0                    	;2d Variable locale stocker le contenu de A
saveX:           .EQUATE 2                    	;2d Variable locale stocker le contenu de X
STRI:            SUBSP 4,i                    	;r�serve saveX saveA 
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
deuxieme:        SUBX        1,i              	;va voir le caract�re pr�c�dent
                 LDA         0,i
                 LDBYTEA     0,x              	;lit le caract�re pr�c�dent
                 CPA         '\n',i      
                 BREQ        striFin
                 ADDX        2,i              	;remet au pointeur au caract�re d'avant et ajoute 1
                 BR          striLoop       
striFin:         ADDX        1,i               
                 LDBYTEA     0,i              
                 STBYTEA     0,x                ;*X='\x00'
                 SUBX        saveA,s            ;X = X-saveA  Adresse_Maximale - Adresse_D�but = nombre d'octets utilis�s
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
; Out: A=Positionn� a l'octet de fin de la chaine a affich�e
;      X=l'adresse du tampon inchang�e
; fin: Affiche le nombre d'octets sp�cifi�s
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
; fin: Retourne le nombre d'octets du texte form�            
nbOctFin:        .EQUATE     0    	       ;2d Variable locale ;Nombre d'octets du bufferTxtF
remp1:           SUBSP       2,i  	       ;reserve pour #nbOctFin
                 LDA         0,i
                 STA         0,s  	       ;mets le nombre d'octets a 0 dans la pile du processeur
                 LDX         buffTxtI,i
                 CALL        split
                 CALL        join 
                 RET2             	       ;d�saloue nbOctFin seulement
;
;
;Programme du split 
; In:  A=Texte initial (txtInit) a transformer en tableau de textes
;      X=Texte s�parateur (sep1 = txt1) qui sert comme unit� de d�coupage du texte initial
; Out: A=Nombre de sous-chaines suite au d�coupage.
;      X=Nombre de caracteres dans sep1.
; fin: Met notre buffTxtI dans tabSJ a partir de la troisi�me case du tableau. 
;      La premi�re sp�cifie le nombre de caracteres dans sep1 
;      et la deuxi�me le nombre de sous-chaines suite au d�coupage.
lettre:          .EQUATE     0     	       ;2d Variable locale ;Sauvegarde la lettre lu dans txtInit pour pouvoir faire la comparaison
debutVer:        .EQUATE     2     	       ;2d Variable locale ;D�but v�rification 
addrSous:        .EQUATE     4     	       ;2d Variable locale ;Position du d�but de l'adresse s�par�
posiSep:         .EQUATE     6     	       ;2d Variable locale ;Position dans le s�parateur
posiTxt:         .EQUATE     8     	       ;2d Variable Locale ;Position dans le text o� l'on v�rifie s'il correspond au s�parateur. 
txtInit:         .EQUATE     10    	       ;2d Variable Locale ;BufferTextInit
sep1:            .EQUATE     12    	       ;2d Variable Locale ;txt1
cmptSep:         .EQUATE     14    	       ;2d Variable Locale ;Nombre de champs s�par�s
nbOctSep:        .EQUATE     16    	       ;2d Variable locale ;Nombre d'octets du s�parateur txt1
;
split:           SUBSP       18,i              ;r�serve nbOctSep ,cmptSep ,sep1 ,txtInit ,posiTxt, posiSep, addrSous, debutVer, lettre 
                 LDA         0,i                
                 STA         nbOctSep,s        ;vide les deux champs qui �taient utilis�s par SaveA et SaveX
                 STA         cmptSep,s      
                 STX         txtInit,s
                 STX         posiTxt,s         ;sauvegarde l'adresse de d�but de txtInit
                 LDX         txt1,i            ;charge o� se trouve le sep1
                 STX         sep1,s
                 STX         posiSep,s         ;sauvegarde la position initiale du s�parateur
                 CALL        sizeSep
                 LDX         posiTxt,s         ;restaure contenu de X (adresse de d�but de txtInit)
                 STX         addrSous,s        ;sauvegarde le d�but de la chaine          
parcourt:        LDBYTEA     0,x               ;lit le caract�re � la position x de txtInit
                 CPA         '\n',i
                 BREQ        vFinParc
                 CPA         '\x00',i          ;compare si c'est le caract�re '\x00', si c'est le cas on a fini le parcourt
                 BREQ        finParc           ;on a atteint la fin de notre texte et on a tout mis dans notre tabSJ
                 STA         lettre,s          ;sauvegarde le caract�re lu de txtInit
                 LDX         posiSep,s         ;prends la position du s�parateur
                 LDBYTEA     0,x               ;caract�re du s�parateur
                 CPA         lettre,s          ;compare le caract�re du s�parateur avec celui du txtInit
                 BREQ        restCom  
                 LDX         posiTxt,s         ;remets le pointeur de txtInit
                 ADDX        1,i               ;incr�mente de 1
                 STX         posiTxt,s 
                 BR          parcourt          ;boucle infinie jusqu'� ce qu'on hit le '\n' et '\x00'
restCom:         LDX         posiTxt,s
                 STX         debutVer,s
blCheck:         LDX         posiTxt, s 
                 ADDX        1,i
                 STX         posiTxt,s         ;sauve la position du pointeur d'adresse texte temp
                 LDBYTEA     0,x               ;caract�re � pointeur texte temp +1
                 STA         lettre,s          ;sauve caract�re � la position du pointeur texte temp+1
                 LDX         posiSep,s
                 ADDX        1,i
                 STX         posiSep,s
                 LDBYTEA     0,x
                 CPA	      '\x00',i
                 BREQ        soutrouv          ;on est arriv� � la fin du s�parateur et on a trouv� la sous-chaine                
                 CPA         '\n',i
                 BREQ        vFinBl
                 CPA         lettre,s          ;compare lettre s�parateur avec lettre texte
                 BREQ        blCheck 
blFaux:          LDX         debutVer,s	  ;si ce n'est pas la m�me lettre
                 ADDX        1,i          
                 STX         posiTxt,s         ;remets posiTxt � notre d�but de verification +1 et on passe � la prochaine lettre
                 LDX         sep1,s
                 STX         posiSep,s         ;replace le posiSeparateur � sa place initiale.
                 LDX         posiTxt,s         ;replace posi pour la verif
                 BR          parcourt
vFinBl:          ADDX        1,i               ;d�place au prochain caract�re
                 STX         posiTxt,s
                 LDBYTEA     0,x               ;lit le caract�re � la position x + 1 de txtInit
                 CPA         '\x00',i          ;compare si c'est le caract�re '\x00'. Si c'est le cas on a fini le parcourt et la chaine n'est pas enti�rement pr�sente
                 BREQ        finParc           ;Interrompe la v�rification car on est arriv� � la fin de txtInit sans compl�tement trouver le s�parateur
                 SUBX        1,i                                                           
                 STX         posiTxt,s    
                 BR          blCheck                                              
soutrouv:        LDA         nbOctSep,s        ;cherche nombre octets sep1
                 LDX         tabSJ,i     
                 STA         0,x               ;sauvegarde le nombre d'octets du s�parateur dans la premi�re case du tabSJ
                 ADDX        2,i               ;va a la case2
                 LDA         cmptSep,s         ;cherche notre compteur de sous-chaines 
                 ADDA        1,i               ;incr�mente de 1
                 STA         cmptSep,s         ;sauvegarde le nombre de sous-chaines + 1 dans le cmptSep
                 STA         0,x               ;sauvegarde le nombre de sous-chaines + 1 dans la deuxi�me case
                 LDA         0,i  
deplace:         CPA         cmptSep,s         ;d�place le tableau pour autant de sous-chaines trouv�s.
                 BREQ        bonnepos     
                 ADDX        2,i    
                 ADDA        1,i
                 BR          deplace
bonnepos:        LDA         addrSous,s        ;load la position de l'adresse du d�but de la sous-chaine.
                 STA         0,x               ;place l'addresse de d�but de la sous-chaien dans la case du tabSJ
                 LDX         sep1,s            
                 STX         posiSep,s         ;remets notre posiSep � l'adresse initiale de sep1
                 LDX         posiTxt,s         ;cherche notre position dans le texte
                 STX         addrSous,s        ;pointe l'addrSous vers l� o� l'on se trouve pr�sentement. C'est maintenant le d�but de la deuxi�me sous-chaine.
                 LDA         0,i
                 BR          parcourt            
vFinParc:        ADDX        1,i               ;d�place au prochain charact�re
                 STX         posiTxt,s
                 LDBYTEA     0,x               ;lit le caract�re � la position X + 1 de txtInit
                 CPA         '\x00',i          ;compare si c'est le charact�re \0. Si c'est le cas on a fini le parcourt
                 BREQ        soutrouv          ;ajoute le reste du txtInit comme sous-chaine. 
                 BR          parcourt          ;boucle infinie jusqu'� ce qu'on hit le '\n' et '\x00'                                                                    
finParc:         ADDSP       18,i              ;d�pile nbOctSep cmptSep sep1 ,txtInit ,posiTxt, posiSep, addrSous, debutVer, lettre 
                 RET0        
;
;
;Programme qui calcul le nbOctets de txt1
; In:  X=Adresse de txt1
; Out: X=Adresse finale de txt1 (l'adresse incr�mente � chaque fois que la lettre lu n'est pas '\x00', 
;      on soustrait txt1 a X, puis est stock�e dans nbOctSep)
; fin: Retourne le nombre d'octets du s�parateur.
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
; fin: Retourne le nombre d'octets utilis�s lors de la formation du nouveau texte dans le tampon final
;      Permet aussi la cr�ation du tableau AddTpar 
iterator:        .EQUATE     0                 ;2d Variable locale ;It�rateur de n
tempAddr:        .EQUATE     2                 ;2d Variable locale ;Addresse temporaire qui contient l'adresse de tabSJ qu'on est en train de lire        
pAddTpar:        .EQUATE     4                 ;2d Variable locale ;Poiteur pour l'addresse de adrTpars
sep2:            .EQUATE     6                 ;2d Variable locale ;Addresse de txt2
cmptSep1:        .EQUATE     8                 ;2d Variable Locale ;Nombre de champs s�par�s 
nbOctSe1:        .EQUATE     10                ;2d Variable locale ;Nombre d'octets du s�parateur txt1
join:            SUBSP       12,i              ;empile  nbOctSe1 cmptSep1 sep2 pAddTpar tempAddr iterator
                 LDA         0,i
                 STA         tempAddr,s        ;remets � 0
                 STA         pAddTpar,s        ;remets � 0
                 LDA         txt2,i
                 STA         sep2,s            ;stocke l'adresse de d�but de txt2 dans sep2
                 LDA         1,i
                 STA         iterator,s        ;remets � 1 notre it�rateur
loopDplc:        LDA         0,i
                 LDX         tabSJ,i
                 ADDX        2,i               ;passe � la case tabSJ[1]
                 BR          deplace2
loopJoin:        CPA         cmptSep1,s        ;A= iterateur
                 BREQ        lectAFin
                 LDA         0,x               
                 STX         tempAddr,s        ;stocke l'addresse de tabSJ o� on travaille pr�sentement.
                 LDX         adrTpars,i
                 STA         0,x               ;stocker dans adrTpars[0]
                 LDX         tempAddr,s        ;reprends l'adresse o� l'on travaillait dans tabSJ
                 LDA         2,x               ;cherche le contenu de la prochaine case
                 LDX         adrTpars,i
                 SUBA        nbOctSe1,s        ;obtient l'addresse - nbOctets de sep1 = addresse o� l'on arr�te de lire les caract�res.
                 STA         2,x               ;stocker dans adrTpars[1]
                 CALL        copy        
                 CALL	      addSep2
                 LDA         iterator,s
                 ADDA        1,i               ;iterator++
                 STA         iterator,s
                 BR          loopDplc          ;ceci est le while
lectAFin:        LDA         0,i
                 LDA         0,x               ;obtenir l'adresse � laquelle on pointe dans tabSJ
                 STA         tempAddr,s        ;stocker l'adresse de d�part
                 LDX         tempAddr,s        ;load l'addresse du caract�re de d�but de la derni�re sous-chaine  
blectFin:        LDA         0,i
                 LDBYTEA     0,x               ;lit le caract�re de cette sous-chaine finale
                 CPA         '\x00',i     
                 BREQ        finJoin           ;si le caract�re lu est \x00 alors on est arriv� � la fin
                 ADDX        1,i               ;tempAddr = tempAddr++
                 STX         tempAddr,s   
                 LDX         buffTxtF,i
                 ADDX        14,s              ;addresse buffTxtF + nombre octets qu'on a d�j� rentr�
                 STBYTEA     0,x               ;sauvegarde dans buffTxtF le caract�re
                 LDA         14,s                            
                 ADDA        1,i               ;nbOctFin ++
                 STA         14,s           
                 CPA         100,i
                 BRGT        joinErr           ;if(nbOctFin > 100) alors on a un d�bordement tampon de fin
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
; Out: A=L'adresse du buffer final inchang�e
;      X=L'adresse finale de adrTpars (adrTpars[2])
; fin: Retourne l'adresse de la partie libre du tampon buffTxtF.
addrTemp:        .EQUATE     0                 ;2d Variable locale ;Addresse du caract�re
copy:            SUBSP       2,i               ;empile addrTemp
                 LDA         0,i
                 STA         addrTemp,s;
                 LDX         adrTpars,i
                 LDA         0,x
                 STA         8,s               ;.EQUATE     4+ 4 = 8 = pAddTpar
blCopy:          CPA         2,x               ;compare adrTpars[0] avec adrTpars[1]
                 BREQ        finCopy
                 STA         addrTemp,s
                 LDX         addrTemp,s        ;load l'addresse du caract�re de buffTxtI
                 LDA         0,i               ;vide le contenu de A
                 LDBYTEA     0,x               ;load le caract�re � l'addresse de buffTxtI 
                 LDX         buffTxtF,i
                 ADDX        18,s              ;addresse buffTxtF + nombre octets qu'on a d�j� rentr�
                 STBYTEA     0,x               ;sauvegarde dans buffTxtF le caract�re
                 LDA         18,s                           
                 ADDA        1,i               ;nbOctFin ++
                 STA         18,s         
                 CPA         100,i
                 BRGT        joinErr           ;if(nbOctFin > 100) alors on a un d�bordement tampon de fin
                 LDA         8,s
                 ADDA        1,i               ;pAddTpar = pAddTpar++
                 STA         8,s
                 LDX         adrTpars,i                 
                 BR          blCopy
finCopy:         RET2               	       ;d�pile addrTemp    
;
;
;Programme qui d�place X vers la case de la sous-chaine dans tabSJ
;Incr�mente de deux l'addresse de tabSJ jusqu'� ce que 
;le nombre de d�placements == iterator
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
; Out: A=Adresse de sep2 inchang�e
;      X=Nombre d'octets du buffer final
; fin: Retourne le buffer final avec les sep2 ajout�s
addSep2:         LDX         8,s      	 ;sep2 +2
bAddSep:         LDA         0,i               ;vide le contenu de A
                 LDBYTEA     0,x      	 ;lit le caract�re de sep2
                 CPA         '\x00',i
                 BREQ	     fAddSep2
                 LDX         buffTxtF,i
                 ADDX        16,s              ;addresse buffTxtF + nombre octets (d�j� entr�e)
                 STBYTEA     0,x               ;sauvegarde dans buffTxtF le caract�re
                 LDA         16,s                           
                 ADDA        1,i               ;nbOctFin ++
                 STA         16,s         
                 CPA         100,i
                 BRGT        joinErr           ;if(nbOctFin > 100) d�bordement tampon de fin         
                 LDX         8,s      
                 ADDX        1,i               ;sep2 = sep2++
                 STX         8,s
                 BR          bAddSep
fAddSep2:        LDA         txt2,i
                 STA         8,s               ;replace sep2 � l'addresse de d�but
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
txt1:            .BLOCK      11                ; 1c11a [�TAIT 10 mais pusiqu'on enl�ve le deuxi�me \n et ensuite on fait la m�me chose pour le premier, on doit avoir une taille de 11 ] 
txt2:            .BLOCK      11                ; 1c11a 
tabSJ:           .BLOCK      304               ; 2d10a  
adrTpars:        .BLOCK      6                 ; 2d3a   
msgDebut:        .ASCII      "Texte Initial : \n\x00" 
msgStriE:        .ASCII      "D�bordement du tampon de saisie.\x00"
msgM:            .ASCII      "Mot a remplacer : \n\x00"
msgMRemp:        .ASCII      "Mot de remplacement : \n\x00"
msgFinE:         .ASCII      "D�bordement du tampon du r�sultat.\x00"
                 .END