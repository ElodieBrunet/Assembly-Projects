;Ce programme permet de fusionner les deux listes triées des notes en une seule.
;(utilise PEP8)
;
;Programme principal
main:            CALL        vidage        
                 ;Liste 1
                 LDA          buffer,i
                 STA          -8,s         
                 STRO        msgList1,d 
                 CALL        notes         
                 LDA         cptList,d
                 ADDA        1,i
                 STA         cptList,d        ;Compteur de liste ++
                 LDX         tete1,d
                 CALL        affListe 
                 ;Liste 2
                 STRO        msgList2,d 
                 CALL        notes
                 LDX         tete2,d
                 CALL        affListe
                 ;Liste 3
                 STRO        msgFusio,d 
                 CALL        fusion
                 LDX         -4,s             ;Addresse de liste 3
                 CALL        affListe
                 BR          fin
;
;
;Fonction qui alloue de l'espace dans la pile et mets toutes les valeurs à 0
;Résultat: une pile complètement nettoyée. 
videur:          .EQUATE     0    		  ;2d ;Nettoie la pile
vidage:          LDA         0,i
                 LDX         2,i
createur:        CPX         42,i
                 BREQ        finVide
                 SUBSP       2,i  		
                 ADDX        2,i
                 STA         videur,s         
                 BR          createur
finVide:         ADDSP       40,i 
                 RET0 
;
;
;Fonction notes
; In:  A=Adresse initiale du buffer
;      X=La tete de la liste courante
; Out: A=???????
;      X=La tete de la liste créée
; fin: Retourne un pointeur vers le premier élément (tete) de la liste créée
saisie:          .EQUATE     4                ;2d ;Réponse saisie par l'utilisateur
addrIni:         .EQUATE     2                ;2h ;L'adresse initiale du buffer
buffPtr:         .EQUATE     0                ;2h ;Le pointeur du buffer
notes:           SUBSP       6,i         
                 LDA         buffer,i    
                 STA         addrIni,s
menu:            STRO        msgStar,d
                 STRO        msgSaisi,d 
                 STRO        msgQuit,d
                 STRO        msgStar,d
choix:           STRO        msgChoix,d
                 DECI        saisie,s
                 LDA         saisie,s
                 CPA         1,i
                 BREQ        suite
                 CPA         2,i
                 BREQ        quitter
                 STRO        msgErr,d
                 BR          choix
suite:           CHARO       '\n',i
                 CALL        creer
                 LDA         cptList,d
                 CPA         1,i
                 BREQ        LDlist1
                 CPA         2,i
                 BREQ        LDlist2
finInse:         BR          menu             ;Quand fin créer et insérer, retour au menu
LDlist1:         LDX         tete1,d          ;Charge liste 1
                 CALL        inserer          ;Paramètre(X = tete) ;return (A = tete)
                 STA         tete1,d  
                 BR          finInse
LDlist2:         LDX         tete2,d          ;Charge liste 2
                 CALL        inserer          ;Paramètre(X = tete) ;return (A = tete)
                 STA         tete2,d
                 BR          finInse
quitter:         CHARO       '\n',i
                 RET6                
;
;
;Fonction créer
; In:  A=Adresse de début du nom
;      X=Adresse du noeud qu'on vient de créer
; Out: A=???????
;      X=Adresse du maillon créé
; fin: Retourne l'adresse d'un maillon de quatre champs contenant les données saisies sur une note
etudiant:        .EQUATE     0                ;2h ;Adresse du noeud qu'on vient de créer
creer:           SUBSP       2,i         
                 LDA         mLength,i   
                 CALL        new         
                 STX         etudiant,s  
                 STX         nouveau,d   
                 LDA         4,s         
                 STA         mNom,x           ;Stocke l'adresse de début du nom dans etudiant.mNom    
                 LDX         300,i        
                 STRO        msgNom,d
                 CALL        STRI
                 LDX         etudiant,s
noteErr:         STRO        msgNote,d
                 DECI        mNote,x
                 LDA         mNote,x
                 CPA         0,i
                 BRLT        noteErr
                 CPA         100,i
                 BRGT        noteErr
                 LDA         0,i
                 STA         mNext,x
                 STA         mPrec,x
                 ADDSP       2,i         
                 RET0
;
;
;Fonction insérer
; In:  A=Adresse du maillon
;      X=Adresse de la tete de la liste
; Out: A=???????
;      X=Adresse du maillon inséré
; fin: Insere un maillon dans une liste a la bonne position
curTete:         .EQUATE     0                ;2h ;L'addresse de notre tete courante
inserer:         SUBSP       2,i         
                 STX         curTete,s        ;Sauvegarde l'addresse de la tete dans laquelle on travaille dans cette variable
                 CPX         0,i              ;Si adresse tete = 0
                 BREQ        iniList          ;Initialise notre liste
                 CALL        cmpMs 
                 LDA         curTete,s
                 RET2                
iniList:         LDA         nouveau,d
                 STA         curTete,s   
                 ADDSP       2,i         
                 RET0        
;
;
;Fonction de comparaison des maillons  
; In:  A=Adresse du nom du maillon courant
;      X=Adresse du nom du maillon nouveau
; Out: A=???????
;      X=???????  
charNom:         .EQUATE     0                ;2d ;Charactère lu
adrNomN:         .EQUATE     2                ;2h ;Addresse du nom du maillon nouveau
adrNomC:         .EQUATE     4                ;2h ;Addresse du nom du maillon courant 
mCour:           .EQUATE     6                ;2h ;L'addresse du maillon courant de notre liste
cmpMs:           SUBSP       8,i              
blNext:          STX         mCour,s          ;Sauve addresse du courant (c'est la tête lorsqu'on est ici) ;BOUCLE SI ON PASSE AU NOEUD SUIVANT                                                                                ;;PARAMETRE X = NOEUD COURANT UPDATED
                 LDA         mNom,x           ;Charge l'adresse du nom courant
                 STA         adrNomC,s        ;Sauvegarde l'adresse du nom Courant
                 LDX         nouveau,d   
                 LDA         mNom,x           ;Charge l'adresse du nom de nouveau
                 STA         adrNomN,s        ;Sauvegarde l'adresse du nom Nouveau
blCmp:           LDX         adrNomN,s        ;Charge dans X l'adresse du nom de nouveau
                 LDA         0,i
                 LDBYTEA     0,x
                 CPA         '\x00',i         ;Compare si la lettre où l'on est arrivé dans notre maillon nouveau est '\x00'
                 BREQ        verFN
                 STA         charNom,s        ;Sauvegarde la lettre du maillon nouveau dans charNom
                 LDX         adrNomC,s
                 LDA         0,i
                 LDBYTEA     0,x
                 CPA         '\x00',i         ;Compare si la lettre où on est arrivé dans notre maillon courant est '\x00'
                 BREQ        verFC            
                                              ;nouveau.char != '\x00' 
                 CPA         charNom,s        ;Compare le nom de courant avec nom de nouveau
                 BREQ        incNom           ;Si les deux lettres ne sont pas '\x00' et sont égales, on incrémentes les lettres
                 BRLT        nodeNex          ;Courant.char < nouveau.char (ou nouv > courant) 
                 BRGT        nodePre          ;Courant.char > nouveau.char (ou nouv < courant) 
;
;Méthode qui vérifie si notre noeud nouveau aussi est à '\x00' sinon c'est "Scénario Jaune ou Orange"
verFC:           LDA         charNom,s        ;Charge la lettre de notre maillon nouveau
                 CPA         '\x00',i         ;Compare si la lettre ici aussi est '\x00'
                 BREQ        cmpNote          ;Si c'est égal alors on est arrivé au '\x00' en même temps et on doit comparer les notes 
                                              
                 BR          nodeNex  
;
;Méthode qui vérifie si notre noeud courant aussi est à '\x00' sinon c'est "Scénario Mauve ou Bleu"
verFN:           LDX         adrNomC,s
                 LDA         0,i
                 LDBYTEA     0,x
                 CPA         '\x00',i         ;Compare si la lettre où on est arrivé dans notre maillon courant est '\x00
                 BREQ        cmpNote          ;Si c'est égal alors on doit comparer la note, 
                                              ;sinon notre maillon est plus petit que le courant
                 BR          nodePre     
;
;Vérifie si le node suivant est 0 
nodeNex:         LDX         mCour,s          ;Charge l'addresse courant
                 LDA         mNext,x          ;Charge dans A le contenu de mNext du noeud courant
                 CPA         0,i         
                 BRNE        deplace          ;Si mNext != 0 alors on se déplace dans le prochain noeud
                                              ;Sinon
                 LDA         nouveau,d        ;Charge l'addresse de notre noeud courant
                 STA         mNext,x          ;Sauvegarde cette addresse dans le champ mNext de notre élément Courant
                 LDX         nouveau,d        ;Charge l'addresse de notre noeud courant
                 LDA         mCour,s          ;Charge l'addresse de notre dernier maillon
                 STA         mPrec,x          ;Sauvegarde dans le champ mPrec l'addresse de l'ancient maillon
                 ADDSP       8,i              
                 RET0 
;    
;Se déplace dans le prochain maillon, sauvegarde le courant comme étant le précédent de notre maillon courant
deplace:         LDX         nouveau,d 
                 LDA         mCour,s
                 STA         mPrec,x
                 LDX         mCour,s
                 LDX         mNext,x          
                 BR          blNext
;
;Vérifie si le node suivant est 0         
nodePre:         LDX         mCour,s          ;Charge l'addresse courant
                 LDA         mPrec,x          ;Charge dans A le contenu de mNext du noeud courant
                 CPA         0,i         
                 BREQ        modTete          ;Si mPrec == 0 alors on est dans la tete et on doit la modifier
                                              ;Sinon
                 LDA         nouveau,d
                 STA         mPrec,x
                 LDX         nouveau,d
                 LDA         mCour,s
                 STA         mNext,x
                 LDX         mPrec,x          
                 LDA         nouveau,d 
                 STA         mNext,x
                 ADDSP       8,i         
                 RET0       
modTete:         LDX         nouveau,d
                 LDA         mCour,s
                 STA         mNext,x
                 STX         10,s             ;Accès à l'adresse de curTete
                 LDX         mCour,s
                 LDA         nouveau,d
                 STA         mPrec,x
                 ADDSP       8,i        
                 RET0
cmpNote:         LDX         nouveau,d   
                 LDA         mNote,x          ;Charge dans A la note du nouveau
                 STA         charNom,s        ;Sauvegarde la note du maillon nouveau dans charNom             
                 LDX         mCour,s
                 LDA         mNote,x
                 CPA         charNom,s        ;Compare la note courant avec la note de nouveau
                 BRLT        nodeNex          ;Courant.char < nouveau.char (ou nouv > courant)
                 BRGE        nodePre          ;Courant.char > nouveau.char (ou nouv < courant) 
incNom:          ADDX        1,i              ;Prochain char pour adrNomC
                 STX         adrNomC,s
                 LDX         adrNomN,s
                 ADDX        1,i              ;Prochain char pour adrNomN
                 STX         adrNomN,s   
                 BR          blCmp 
finCmp:          ADDSP       8,i         
                 RET0
;
;
;Fonction d'affichage  
; In:  A=Ancienne position de nbOctets 
;      X=Adresse du tampon initial
; Out: A=Positionné a l'octet de fin de la chaine a affichée
;      X=l'adresse du tampon inchangée
; fin: Affiche le nombre d'octets spécifiés
chaine:          .EQUATE     0                ;2h ;Le nom que le maillon contient
maillon:         .EQUATE     2                ;2h ;Un maillon de la liste
affListe:        SUBSP       4,i      
                 CPX         0,i              ;Vérifie si notre liste contient au moins 1 élément (si tete != 0)
                 BREQ        finfin
                 STX         maillon,s
bclaff:          LDA         0,i
                 LDA         mNom,x   
                 STA         chaine,s    
boucle2:         LDX         chaine,s
                 CHARO       0,x
                 ADDX        1,i
                 STX         chaine,s
                 LDA         0,i
                 LDBYTEA     0,x
                 CPA         '\x00',i   
                 BRNE        boucle2
                 CHARO       ' ',i            ;print(X.val + " ");   
                 CHARO       ';',i            ;print(X.val + " ");         
                 CHARO       ' ',i            ;print(X.val + " ");   
                 LDX         maillon,s
                 STRO        msgNote,d
                 DECO        mNote,x 
                 CHARO       '\n',i           ;print(X.val + " ");
                 LDA         mNext,x
                 CPA         0,i         
                 BREQ        finfin  
                 LDX         mNext,x
                 STX         maillon,s     
                 BR          bclaff           ;} // fin for
finfin:          CHARO       '\n',i           ;print(X.val + " ");
                 RET4                         
;
;
;Structure de liste d'étudiants
; Une liste est constituée d'une chaîne de maillons nommés étudiants.
; Chaque étudiants contient un nom, une valeur, l'adresse du maillon suivant et l'adresse du maillon précédent
; La fin de la liste est marquée arbitrairement par l'adresse 0
mLength:         .EQUATE     8                ;2h ;La taille d'un objet étudiant
mPrec:           .EQUATE     6                ;2h ;L'adresse de l'étudiant précédent
mNext:           .EQUATE     4                ;2h ;L'adresse de l'étudiant suivant
mNote:           .EQUATE     2                ;2d ;La note de l'étudiant
mNom:            .EQUATE     0                ;2h ;L'adresse du nom de l'étudiant
;
;
;STRI: Lit une ligne dans un tampon et place '\x00' à la fin
;In:  A=Adresse du tampon
;     X=Taille du tampon en octet
;Out: A=Adresse du tampon (inchangé)
;     X=Nombre de caractères lu (ou offset du '\x00')
;Err: Avorte si le tampon n'est pas assez grand pour
;     stocker la ligne et le '\0' final
saveA:           .EQUATE     0                ;2d ;Stocker le contenu de A
saveX:           .EQUATE     2                ;2d ;Stocker le contenu de X
STRI:            SUBSP       4,i              
                 STA         saveA,s          ;Sauvegarde A (L'addresse où l'on travaille) dans A                  
                 ADDX        12,s             ;Accès a la variable addrIni
                 STX         saveX,s          ;Sauvegarde buffer+300 = addresse maximale
                 LDX         saveA,s          ;X = saveA
striLoop:        CPX         saveX,s          ;while(true) {
                 BRGE        striErr          ;if(X>=saveX) throws new Error(); 
                 CHARI       0,x              ;*X = getChar()
                 LDA         0,i         
                 LDBYTEA     0,x
                 CPA         '\n',i        
                 BREQ        striFin          ;if(*X=='\x00') break
                 ADDX        1,i              ;X++;
                 BR          striLoop         ;} // fin boucle
striFin:         LDBYTEA     0,i              
                 STBYTEA     0,x              ;*X='\x00'
                                              ;Ici, X contient l'addresse du dernier caractère
                 ADDX        1,i              ;Prends le prochain byte après notre '\x00'
                 CPX         saveX,s          	
                 BRGE        striErr          ;if addresse courant dépasse la limite du buffer, il y a une erreur
                 STX         10,s             ;Accès a la variable buffPtr
                 LDA         saveA,s          ;Restaure A
                 ADDSP       4,i               
                 RET0                         ;Return
striErr:         STRO        msgStriE,d  
                 BR          fin   
;
;
;Fonction fusion
; In:  A=Addresse de la tete de liste 1
;      X=Addresse de la tete de liste 2
; Out: A=Adresse de la tete de la liste courante
;      X=Adresse de la tete de liste 3
; fin: Retourne une liste 3 issue de la fusion des listes 1 et 2
lettre1:         .EQUATE     0                ;2d ;Lettre de la liste 1
indiceL:         .EQUATE     2                ;2d ;L'indice qui indique quelle liste on est en train de travailler (pour notre simili return)
;
;Si 1 alors on est en train d'ajouter 1 seul élément de liste1 et on retourne dans Rgrand
;Si 2 alors on est en train d'ajouter 1 seul élément de liste2 et on retourne dans Rgrand
;Si 3 alors on est en train d'ajouter tout le contenu d'une liste et on retourne dans RajoutL
;
adrNom1:         .EQUATE     4                ;2h ;Addresse du nom de la tete de liste 1 
adrNom2:         .EQUATE     6                ;2h ;Addresse du nom de la tete de liste 2
temp:            .EQUATE     8                ;2h ;Variable utilisé pour la copie des informations du maillon de la liste 1-2 à la liste 3
mCourL3:         .EQUATE     10               ;2h ;Le dernier noeud de la liste 3 qu'on a créé
curList:         .EQUATE     12               ;2h ;L'addresse de la tete de la liste dans laquelle on est en train de travailler
l1:              .EQUATE     14               ;2h ;Liste 1
l2:              .EQUATE     16               ;2h ;Liste 2
l3:              .EQUATE     18               ;2h ;Liste 3
fusion:          SUBSP       20,i        
                 ;Vide le contenu des informations précédentes sur la pile
                 LDA         0,i
                 STA         l3,s
                 STA         l2,s
                 STA         l1,s
                 STA         curList,s
                 STA         mCourL3,s
                 STA         temp,s
                 STA         adrNom2,s
                 STA         adrNom1,s
                 STA         indiceL,s
                 STA         lettre1,s
                 ;Crée la tete de liste 3
                 LDA         mLength,i        
                 CALL        new              
                 STX         l3,s
                 STX         mCourL3,s        ;Sauve l'addresse de la tete de liste 3 dans l3 et dans mCourL3  
                 ;Si liste 1 vide
                 LDX         tete2,d
                 STX         l2,s
                 LDX         tete1,d
                 STX         l1,s	
                 CPX         0,i
                 BREQ        verifL2
                 ;Si liste 2 vide	
                 LDX         l2,s
                 CPX         0,i 
                 BRNE        blListe
                 LDX         l1,s
                 BR          ajouteL  
;Si liste 1 et 2 pas vide 
;Boucle de comparaison des deux listes pour insérer alphabétiquement dans liste 3
blListe:         LDX         l2,s             ;Charge l'addresse de la tete de liste 2 dans X
                 LDA         l1,s             ;Charge l'addresse de tete de liste 1 dans A
                 CPA         0,i
                 BREQ        ajouteL          ;Passe en paramètre liste 2 pour ajouter le reste de cette liste à l3
                 LDX         l1,s             ;Charge l'addresse de la tete de l1 dans X
                 LDA         l2,s             ;Charge l'addresse de la tete de l2 dans A
                 CPA         0,i
                 BREQ        ajouteL          ;Passe en paramètre l1 pour qu'on ajoute le reste de cette liste à l3         
                 LDX         l1,s
                 LDA         mNom,x
                 STA         adrNom1,s
                 LDX         l2,s
                 LDA         mNom,x
                 STA         adrNom2,s         
blLettre:        LDX         adrNom1,s 
                 LDA         0,i
                 LDBYTEA     0,x              ;Lit le caractère du nom auquel on pointe dans liste 1
                 STA         lettre1,s
                 CPA         '\x00',i         ;Compare si la lettre où l'on est arrivé dans notre maillon liste 1 est '\x00'
                 BREQ        fLettre1
                 LDX         adrNom2,s
                 LDA         0,i
                 LDBYTEA     0,x              ;Lit le caractère du nom auquel on pointe dans liste 2
                 CPA         '\x00',i         ;Compare si la lettre où l'on est arrivé dans notre maillon liste 2 est '\x00'
                 BREQ        petit
                 CPA         lettre1,s           
                 BREQ        pareil           ;Vérifier la prochaine lettre car elles sont pareilles
                 BRLT        petit            ;Lettre de la liste 2 < lettre de la liste 1 (donc ajoute liste 2)
                 BRGT        grand            ;Lettre de la liste 2 > lettre de la liste 1 (donc ajoute liste 1)
pareil:          ADDX        1,i              ;Prochain char pour adrNom2
                 STX         adrNom2,s
                 LDX         adrNom1,s
                 ADDX        1,i              ;Prochain char pour adrNom1
                 STX         adrNom1,s   
                 BR          blLettre 
;
;Vérifie si lettre de l2 est aussi à '\x00'
fLettre1:        LDX         adrNom2,s
                 LDA         0,i
                 LDBYTEA     0,x              ;Lit la lettre de liste2
                 CPA         lettre1,s        ;Si les deux sont '\x00'
                 BREQ        cmpGrade         ;Compare la note
                 BR          grand            ;Lettre de la liste 2 > lettre de la liste 1 qui est '\x00'         
cmpGrade:        LDX         l1,s   
                 LDA         mNote,x          ;Charge dans A la note de liste1
                 STA         lettre1,s        ;Save la note de liste1 dans lettre1 
                 LDX         l2,s
                 LDA         mNote,x
                 CPA         lettre1,s        ;Compare la note l2 avec la note de l1
                 BRLT        petit            ;l2.note < l1.note (ou l1 > l2) ajouter l2
                 BRGE        grand            ;l2.note >= l1.note (ou l1 < l2) ajouter l1 
petit:           LDX         l2,s             ;Charge l'addresse de l2
                 STX         curList,s        ;Sauvegarde la liste2 dans curList
                 LDA         2,i
                 STA         indiceL,s        ;Sauvegarde l'indice 2
                 BR          copy
Rpetit:          LDA         curList,s
                 STA         l2,s             ;Remplace la tete de l2 avec l'addresse de son prochain élément
                 BR          blListe  
;
;Copie la liste dans liste 3 
copy:            LDX         mNom,i           ;X = 0
                 LDA         curList,sxf      ;Charge l'addresse dans curList (s) 
                                              ;-> se déplace dans l'addresse (f)
                                              ;-> fait un déplacement X (x) 
                                              ;-> lit la valeur = nom
                 LDX         mCourL3,s        ;X = Adresse du dernier maillon créé dans l3
                 STA         mNom,x
                 LDX         mNote,i          ;X = 2
                 LDA         curList,sxf      ;Charge l'addresse dans curList (s) 
                                              ;-> se déplace dans l'addresse (f)
                                              ;-> fait un déplacement X (x) 
                                              ;-> lit la valeur = note
                 LDX         mCourL3,s
                 STA         mNote,x
;
;Fin insertion noms et notes
                 STX         temp,s           ;Sauvegarde le maillon qu'on vient d'éditer dans temp
                 LDA         mLength,i        
                 CALL        new              
                 STX         mCourL3,s        ;Sauve l'addresse dans mCourL3

                 LDX         mNext,i
                 LDA         mCourL3,s        ;Charge l'adresse de notre nouveau maillon qu'on vient de créer 
                 STA         temp,sxf         ;Sauvegarde cette adresse dans le champ mNext de notre avant-dernier élément
                 LDX         mPrec,i     
                 LDA         temp,s           ;Charge l'adresse de notre avant-dernier maillon
                 STA         mCourL3,sxf      ;Sauvegarde dans le champ mPrec de notre nouveau maillon l'addresse de l'avant-dernier maillon
;
;Déplace notre tete de curList vers son prochain element 
                 LDX         curList,s
                 LDX         mNext,x
                 STX         curList,s
;
;Vérifie l'indice
                 LDA         indiceL,s
                 CPA         2,i              ;Compare notre indice avec 2
                 BREQ        Rpetit           ;Si indiceL = 2 alors on vient de faire l'opération sur l2
                 BRLT        Rgrand           ;Si indiceL = 1 alors on vient de faire l'opération sur l1
                 BRGT        RajoutL          ;Si indiceL = 3 alors on vient de faire l'opération sur ajouteL
grand:           LDX         l1,s             ;Charge l'addresse de l1
                 STX         curList,s        ;Sauvegarde la liste2 dans curList       
                 LDA         1,i
                 STA         indiceL,s        ;Sauvegarde l'indice 1
                 BR          copy
Rgrand:          LDA         curList,s
                 STA         l1,s             ;Remplace la tete de l1 avec l'addresse de son prochain élément
                 BR          blListe
;
;Vérifie si liste 2 est null
verifL2:         LDX         l2,s
                 CPX         0,i
                 BRNE        ajouteL
                 BR          finito           ;Liste 3 reste null
;
;Ajoute la liste passée en paramètre à la liste 3
;In: X contient l'addresse de la tete de la liste non-null
ajouteL:         STX         curList,s
                 LDA         3,i
                 STA         indiceL,s        ;Sauvegarde l'indice 3
blAddL:          LDX         curList,s        ;Prends l'addresse de notre curList
                 CPX         0,i              ;Si notre curList pointe à 0 alors on a inséré tous les éléments de notre liste restante
                 BREQ        finito      
                 BR          copy             ;Sinon, cela veut dire que notre tete ne pointe pas à 0 et qu'on a encore des éléments à l'interieur
RajoutL:         BR          blAddL
;
finito:          LDX         l3,s
                 LDA         mNext,x
                 CPA         0,i              ;Vérifie si notre l3 n'est pas qu'une liste qui contient une tête qui est vide (aucune information)
                 BREQ        viderL3
                                              ;Sinon, si elle contient des éléments
                                              ;Alors temp contient la référence à l'avant dernier élément de notre liste
                 LDA         0,i
                 LDX         mNext,i     
                 STA         temp,sxf         ;Se déplace à l'addresse contenu dans temp et fait un + X pour arriver au champ mNext
                 ADDSP       20,i         
	        RET0
viderL3:         LDA         0,i
                 STA         l3,s
                 ADDSP       20,i         
	        RET0
;
;
;Commande pour terminer le programme
fin:             STOP   
;
;
;Variables globales
buffer:          .BLOCK      300              ;1c300a  
tete1:           .BLOCK      2                ;2h ;Tête de liste1 (null (aka 0) si liste vide)
tete2:           .BLOCK      2                ;2h ;Tête de liste2 (null (aka 0) si liste vide)
nouveau:         .BLOCK      2                ;2h ;Nouveau maillon créé (null (aka 0) si liste vide)
cptList:         .WORD       1                ;Dit avec quelle liste est-ce qu'on est en train de travailler 
msgStar:         .ASCII      "***************\n\x00"
msgSaisi:        .ASCII      "* 1 - Saisir  *\n\x00"
msgQuit:         .ASCII      "* 2 - Quitter *\n\x00"
msgChoix:        .ASCII      "Votre choix: \x00"
msgErr:          .ASCII      "Choix invalide, veuillez réessayez \n\x00"
msgList1:        .ASCII      "Liste 1 \n\x00"
msgList2:        .ASCII      "Liste 2 \n\x00" 
msgNom:          .ASCII      "Nom, Prénom: \n\x00"
msgStriE:        .ASCII      "Débordement du tampon de saisie.\x00"
msgNote:         .ASCII      "Note : \x00"
msgFusio:        .ASCII      "Liste fusion \n\x00"
;
;
;Fonction new (pour créer une nouvelle liste)
; In:  A= Un nombre d'octets
; Out: X= Contient un pointeur qui pointe sur des octets
new:             LDX         hpPtr,d          ;Pointeur retourné
                 ADDA        hpPtr,d          ;Allouer a partir du tas
                 STA         hpPtr,d          ;Met a jour hpPtr
                 RET0                
hpPtr:           .ADDRSS     heap             ;.address du prochain octet libre
heap:            .BLOCK      1                ;Premier octet du tas
                 .END