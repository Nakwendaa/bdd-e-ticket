/****************************************************************************************************************************
Fichier: requetes.sql
Description: fichier qui contient les requêtes sql pour la base de données e-ticket

Auteurs: Paul CHAFFANET
         Samuel GUIGUI
         
Les résultats des requêtes changent en fonction des aléas du peuplement de la base de données.
*****************************************************************************************************************************/

START peuplement.sql;

-- Afficher le nombre de transactions d'achat des 5 dernières semaines
SELECT COUNT(*) AS NBTRANSACTIONS
FROM TRANSACTION
WHERE CURRENT_DATE - DATEHEURE <= 7 * 5 AND STATUT = 'payée';

-- Afficher le nombre de clients utilisateurs de Google
SELECT COUNT(*) AS NB_CLIENTS_UTILISATEURS_GOOGLE
FROM CLIENT
WHERE ADRESSEMAIL LIKE '%@gmail.com';

-- Afficher les clients de l'arrondissement B4 (indiqué par le code postal commençant par "B4") et qui n'ont pas un compte Google
SELECT NOM, PRENOM, CODEPOSTAL
FROM CLIENT, ADRESSE
WHERE CLIENT.IDADRESSE = ADRESSE.IDADRESSE
      AND CODEPOSTAL LIKE 'B4%'
      AND ADRESSEMAIL NOT LIKE '%@gmail.com';

-- Afficher les noms des sous-catégories de la catégorie Sport

SELECT NOM AS SOUS_CATEGORIES_SPORT
FROM CATEGORIE
WHERE IDPARENT = (SELECT IDCATEGORIE
                  FROM CATEGORIE
                  WHERE NOM = 'Sport');
                      

-- Afficher les emplacements de Montréal qui accueillent plus de 2000 clients.
SELECT NOM
FROM EMPLACEMENT, ADRESSE
WHERE EMPLACEMENT.IDADRESSE = ADRESSE.IDADRESSE
      AND VILLE = 'Montréal'
      AND CAPACITE > 2000;




-- Afficher les informations des évènements passés de plus de 4 occurrences et dont le prix annoncé était supérieur à $150
SELECT *
FROM EVENEMENT
WHERE IDEVENEMENT IN (SELECT IDEVENEMENT
                      FROM OCCURRENCE
                      WHERE IDOCCURRENCE IN (SELECT IDOCCURRENCE
                                             FROM OCCURRENCE
                                             WHERE PRIX > 150 AND DATEHEURE < CURRENT_DATE)
                      GROUP BY IDEVENEMENT
                      HAVING COUNT(*) > 4);


-- Calculer les économies faites par un client de votre choix grâce aux coupons rabais de toutes ses transactions (peut-être 0 une fois sur deux en fonction
-- des aléas du peuplement de la bdd)
SELECT CLIENT.NOM, PRENOM, ROUND(SUM(CASE WHEN CODERABAIS IS NULL THEN 0 
                                          ELSE ((COUT/(1 - (SELECT TAUXDERABAIS 
                                                            FROM RABAIS 
                                                            WHERE CODE = CODERABAIS)/100)) - COUT) END), 2) AS ECONOMIES
FROM TRANSACTION, CLIENT
WHERE CLIENT.IDCLIENT = 9 AND TRANSACTION.IDCLIENT = CLIENT.IDCLIENT
GROUP BY CLIENT.NOM, PRENOM;

-- Afficher les informations des évènements passés de plus de 4 occurrences qui se sont tenus en 
-- Ontario et dont le prix était inférieur à $150 après le rabais “âge d’or”                
                      
SELECT *
FROM EVENEMENT
WHERE IDEVENEMENT IN (SELECT IDEVENEMENT
                      FROM OCCURRENCE, EMPLACEMENT, ADRESSE
                      WHERE EMPLACEMENT.IDADRESSE = ADRESSE.IDADRESSE 
                            AND PROVINCE = 'ON' 
                            AND EMPLACEMENT.IDEMPLACEMENT = OCCURRENCE.IDEMPLACEMENT
                            AND (PRIX * (1 - (SELECT TAUXDERABAIS FROM RABAIS WHERE CODE = 'AGEOR'))/100) < 150
                      GROUP BY IDEVENEMENT
                      HAVING COUNT(*) > 4);


-- Calculer et afficher les revenus totaux des emplacements pour tous les évènements triés par
-- ordre décroissant. (PS. Faites attention aux statut des transactions).

SELECT IDEMPLACEMENT, SUM(REVENUTOTAL) AS REVENUTOTAL
FROM (
      SELECT  LIGNETRANSACTION.IDOCCURRENCE AS occur, SUM(ROUND(PRIX * QUANTITE * (1 - (CASE 
                                                                                          WHEN CODERABAIS IS NULL THEN 0 
                                                                                          ELSE (SELECT TAUXDERABAIS 
                                                                                                FROM RABAIS 
                                                                                                WHERE CODE = CODERABAIS)/100 END )),2)) AS REVENUTOTAL
                                         
      FROM LIGNETRANSACTION, OCCURRENCE, TRANSACTION
      WHERE LIGNETRANSACTION.IDTRANSACTION = TRANSACTION.IDTRANSACTION
            AND LIGNETRANSACTION.IDOCCURRENCE = OCCURRENCE.IDOCCURRENCE
            AND STATUT = 'payée'
      GROUP BY LIGNETRANSACTION.IDOCCURRENCE),
      EMPLACEMENT
WHERE IDEMPLACEMENT = (SELECT IDEMPLACEMENT
                       FROM OCCURRENCE
                       WHERE IDOCCURRENCE = occur)
GROUP BY IDEMPLACEMENT
ORDER BY REVENUTOTAL DESC;

/*   afin de vérifier que ça calcule bien les bons revenus.   
SELECT *
FROM LIGNETRANSACTION, OCCURRENCE, TRANSACTION
WHERE IDEMPLACEMENT = 7
      AND LIGNETRANSACTION.IDOCCURRENCE = OCCURRENCE.IDOCCURRENCE
      AND LIGNETRANSACTION.IDTRANSACTION = TRANSACTION.IDTRANSACTION;
*/

-- Afficher l'arborescence de toutes les catégories et toutes leurs sous-categories
SELECT *
FROM CATEGORIE
START WITH IDCATEGORIE BETWEEN 1 AND 3 CONNECT BY PRIOR IDCATEGORIE = IDPARENT;