/****************************************************************************************************************************
Fichier: creation.sql
Description: fichier qui permet la création (création de tables et contraintes) de la base de données relationnelle e-ticket

Auteurs: Paul CHAFFANET
         Samuel GUIGUI
         
- NLS_FORMAT = 'DD/MM/YYYY H24:MI' est le format que l'on a utilisé pour les dates
*****************************************************************************************************************************/

-- Permet d'utiliser les caractères & dans la table des catégories
SET DEFINE OFF;

DROP TABLE CATEGORIE        CASCADE CONSTRAINTS;
DROP TABLE EVENEMENT        CASCADE CONSTRAINTS;
DROP TABLE ADRESSE          CASCADE CONSTRAINTS;
DROP TABLE EMPLACEMENT      CASCADE CONSTRAINTS;
DROP TABLE OCCURRENCE       CASCADE CONSTRAINTS;
DROP TABLE RABAIS           CASCADE CONSTRAINTS;
DROP TABLE CLIENT           CASCADE CONSTRAINTS;
DROP TABLE TRANSACTION      CASCADE CONSTRAINTS;
DROP TABLE LIGNETRANSACTION CASCADE CONSTRAINTS;


-- Table: CATEGORIE --------------------------------------------------------------------------------------------------------------------------------------
--
-- Une catégorie est composée d'un IDCATEGORIE, a un NOM, et a éventuellement un IDPARENT null (l'IDPARENT correspond
-- a la catégorie parente de la catégorie considérée).
--
-- Contraintes: - cs_doublonCat: Permet d'éviter l'insertion de catégories doublons pour les catégories partageant le même parent direct.             
CREATE TABLE CATEGORIE 
(
  IDCATEGORIE   NUMBER(3)         NOT NULL,
  NOM           VARCHAR2(50)      NOT NULL,
  IDPARENT      NUMBER(3),
  
  CONSTRAINT pk_idCategorie PRIMARY KEY(IDCATEGORIE),
  CONSTRAINT fk_idParent    FOREIGN KEY(IDPARENT) REFERENCES CATEGORIE(IDCATEGORIE),
  CONSTRAINT cs_doublonCat  UNIQUE(NOM, IDPARENT)
);
-- ************************************************************************************************************************************************


-- Table: EVENEMENT --------------------------------------------------------------------------------------------------------------------------------------
--
-- Un évènement est composée d'un IDEVENEMENT, est classé dans une catégorie (IDCATEGORIE), doit avoir un titre, une description, un siteweb, une durée
-- ainsi qu'une image d'affichage.
--
-- Contraintes: - cs_doublonEvenement: on interdit l'insertion d'évènement identique en tout point (créations d'évènements doublons)
--              - cs_dureePositive: Un évènement doit avoir une durée positive.
CREATE TABLE EVENEMENT 
(
  IDEVENEMENT   NUMBER(10)      NOT NULL,
  IDCATEGORIE   NUMBER (3)      NOT NULL,
  TITRE         VARCHAR2(100)   NOT NULL,
  DESCRIPTION   VARCHAR2(1000)  NOT NULL,
  SITEWEB       VARCHAR2(255)   NOT NULL,
  DUREE         NUMBER(38,12)   NOT NULL,
  IMAGE         VARCHAR2(255)   NOT NULL,
  
  CONSTRAINT pk_idEvenement       PRIMARY KEY(IDEVENEMENT),
  CONSTRAINT fk_idCategorie       FOREIGN KEY(IDCATEGORIE) REFERENCES CATEGORIE,
  CONSTRAINT cs_doublonEvenement  UNIQUE(TITRE, DESCRIPTION, SITEWEB, DUREE, IMAGE),
  CONSTRAINT cs_dureePositive     CHECK (DUREE > 0)
);
-- ************************************************************************************************************************************************


-- Table: ADRESSE ----------------------------------------------------------------------------------------------------------------------------------------
--
-- On crée une table adresse afin de regrouper toutes les adresses disponibles. Ainsi, les clients de la table CLIENT partageant la même adresse
-- auront alors le même IDADRESSE. On économise ainsi en espace.
--
-- Contraintes: - cs_doublon: on évite l'insertion d'adresse doublon.
--              - cs_numeroCivique: le numeroCivique doit être strictement positif.
--              - cs_codePostal: on contraint à ce que le code postal d'une adresse soit une chaîne de caractères au format canadien e.g H3T1J4
--              - cs_ville: Une ville est une chaîne de caractères de la forme (e.g Montréal, Saint Jean, Saint-Jean, Conté de Strathcona)
--              - cs_province: on contraint à ce que la province soit une province canadienne.
CREATE TABLE ADRESSE
(
  IDADRESSE     NUMBER(10)      NOT NULL,
  NUMEROCIVIQUE NUMBER(5)       NOT NULL,
  RUE           VARCHAR2(100)   NOT NULL,
  CODEPOSTAL    CHAR(6)         NOT NULL,
  VILLE         VARCHAR2(50)    NOT NULL,
  PROVINCE      VARCHAR2(3)     NOT NULL,
  
  CONSTRAINT pk_idAdresse       PRIMARY KEY(IDADRESSE),
  CONSTRAINT cs_doublon         UNIQUE(NUMEROCIVIQUE, RUE, CODEPOSTAL, VILLE, PROVINCE),
  CONSTRAINT cs_numeroCivique   CHECK(NUMEROCIVIQUE > 0),
  CONSTRAINT cs_codePostal      CHECK(REGEXP_LIKE(CODEPOSTAL, '([A-Z]{1}[0-9]{1}){3}')),
  CONSTRAINT cs_ville           CHECK(NOT REGEXP_LIKE(VILLE,'[0-9]') 
                                      AND REGEXP_LIKE(VILLE, '^[A-ZÉÀÈ]{1}[a-zéèà]{1,}(([[:space:]]{1}|[-]{1})[A-Za-zéèà]{1}[a-zéèà]{1,}){0,}$')),
  CONSTRAINT cs_province        CHECK(PROVINCE IN ('AB', 'BC', 'IPE', 'MB', 'NB', 'NS', 'ON', 'QC', 'SK', 'NL', 'NU', 'NT', 'YT'))
);
-- ************************************************************************************************************************************************


-- Table: EMPLACEMENT ------------------------------------------------------------------------------------------------------------------------------------
--
-- Un emplacement a un IDEMPLACEMENT, un NOM, un SITEWEB, une ADRESSEMAIL, un IDADRESSE qui correspond à une adresse dans la table ADRESSE,
-- une CAPACITE et un NOTELEPHONE
--
-- Contraintes: - cs_adresseMailEmplacement: on contraint à ce que l'adresse mail respecte le bon format. (p.e paul.philippe.chaffanet@gmail.com)
--              - cs_capacitePostive: on contraint à ce que la capacité soit toujours positive pour un emplacement
--              - cs_noTelephoneEmplacement: on contraint à ce qu'un numéro de téléphone soit au format 999-999-9999
CREATE TABLE EMPLACEMENT 
(
  IDEMPLACEMENT NUMBER(10)      NOT NULL,
  NOM           VARCHAR2(100)   NOT NULL,
  SITEWEB       VARCHAR2(255)   NOT NULL,
  ADRESSEMAIL   VARCHAR2(100)   NOT NULL,
  IDADRESSE     NUMBER(10)      NOT NULL,
  CAPACITE      NUMBER(10)      NOT NULL,
  NOTELEPHONE   CHAR(12)        NOT NULL,
  
  CONSTRAINT pk_idEmplacement           PRIMARY KEY(IDEMPLACEMENT),
  CONSTRAINT fk_idAdresseEmplacement    FOREIGN KEY(IDADRESSE) REFERENCES ADRESSE,
  CONSTRAINT cs_adresseMailEmplacement  CHECK (REGEXP_LIKE(ADRESSEMAIL,'^([a-z0-9\-\_]{1,}.){1,5}@([a-z0-9\-\_]{1,}.){1,5}$')),
  CONSTRAINT cs_capacitePositive        CHECK (CAPACITE > 0),
  CONSTRAINT cs_noTelephoneEmplacement  CHECK (REGEXP_LIKE(NOTELEPHONE, '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'))
);
-- ************************************************************************************************************************************************


-- Table: OCCURRENCE -------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Une occurrence se produit à une certaine DATEHEURE (sur OSX El Capitan dans SQL Developer: Préférences -> Base de données -> NLS -> Format de date: DD/MM/YYYY HH24:MI)
-- a un PRIX de vente pour un billet (d'une précision ramenée à 2 après la virgule), est associée à un évènement et un emplacement.
--
-- Contraintes: - cs_prixPositif: Le prix d'un évènemement peut être 0 ou plus. En effet, il existe bien des évènements gratuits pour lesquels
--                                des billets pourraient être émis. En revanche, les prix négatifs sont bien sûrs incohérents.
CREATE TABLE OCCURRENCE
(
  IDOCCURRENCE  NUMBER(10)                NOT NULL,
  DATEHEURE     DATE DEFAULT CURRENT_DATE NOT NULL,
  PRIX          NUMBER(10, 2)             NOT NULL,
  IDEVENEMENT   NUMBER(10)                NOT NULL,
  IDEMPLACEMENT NUMBER(10)                NOT NULL,
  
  CONSTRAINT pk_idOccurrence  PRIMARY KEY(IDOCCURRENCE),
  CONSTRAINT fk_idEvenement   FOREIGN KEY(IDEVENEMENT) REFERENCES EVENEMENT(IDEVENEMENT),
  CONSTRAINT fk_idEmplacement FOREIGN KEY(IDEMPLACEMENT) REFERENCES EMPLACEMENT(IDEMPLACEMENT),
  CONSTRAINT cs_prixPositif   CHECK (PRIX >= 0)
);
-- ************************************************************************************************************************************************


-- Table: CLIENT-------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Un client a un NOM, un PRENOM, une ADRESSEMAIL, un IDADRESSE qui correspond à une adresse dans la table des ADRESSE, un MOTDEPASSE et un NOTELEPHONE.
-- 
-- Contraintes: - cs_uniqueMail: le mail est la seule donnée qui doit être unique pour qu'un client puisse être inséré. (On ne peut pas créer
--                               de comptes clients partageant les mêmes identifiants)             
--              - cs_nomClient: Un NOM est une chaîne de caractères qui ne contient pas de nombre et qui commence par une lettre majuscule.
--              - cs_prenomClient: Un PRENOM est une chaîne de caractères qui ne contient pas de nombre et qui commence par une lettre majuscule.
--              - cs_adresseMailClient: on contraint à ce que l'adresse mail respecte le bon format. (p.e paul.philippe.chaffanet@gmail.com)
--              - cs_noTelephoneClient: on contraint à ce qu'un numéro de téléphone soit au format 999-999-9999
CREATE TABLE CLIENT
(
  IDCLIENT    NUMBER(10)      NOT NULL,
  NOM         VARCHAR2(50)    NOT NULL,
  PRENOM      VARCHAR2(50)    NOT NULL,
  ADRESSEMAIL VARCHAR2(100)   NOT NULL,
  IDADRESSE   NUMBER(10)      NOT NULL,
  MOTDEPASSE  VARCHAR2(200)   NOT NULL,
  NOTELEPHONE CHAR(12)        NOT NULL,
  
  CONSTRAINT pk_idClient          PRIMARY KEY(IDCLIENT),
  CONSTRAINT fk_idAdresseClient   FOREIGN KEY(IDADRESSE) REFERENCES ADRESSE(IDADRESSE),
  CONSTRAINT cs_uniqueMail        UNIQUE(ADRESSEMAIL),
  CONSTRAINT cs_nomClient         CHECK (NOT REGEXP_LIKE(NOM,'[0-9]')),
  CONSTRAINT cs_prenomClient      CHECK (NOT REGEXP_LIKE(PRENOM,'[0-9]')),
  CONSTRAINT cs_adresseMailClient CHECK (REGEXP_LIKE(ADRESSEMAIL,'^([a-z0-9\-\_]{1,}.){1,5}@([a-z0-9\-\_]{1,}.){1,5}$')),
  CONSTRAINT cs_noTelephoneClient CHECK (REGEXP_LIKE(NOTELEPHONE, '^[0-9]{3}-[0-9]{3}-[0-9]{4}$'))
);
-- ************************************************************************************************************************************************


-- Table: RABAIS -----------------------------------------------------------------------------------------------------------------------------------------
--
-- Un rabais a un CODE (e.g AGEOR correspond au rabais "Âge d'or", 'ETUDI' correspond au rabais "Étudiant", etc.), un NOM pour le rabais,
-- a un TAUXDERABAIS, et est valide de DATEDEBUT jusqu'à DATEEXPIRATION.
-- 
-- Contraintes: - cs_tauxDeRabais: on contraint à ce que le taux de rabais soit compris entre 1% à 99%
CREATE TABLE RABAIS
(
  CODE            CHAR(5)       NOT NULL,
  NOM             VARCHAR2(50)  NOT NULL,
  TAUXDERABAIS    NUMBER(4, 2)  NOT NULL,
  DATEDEBUT       DATE          NOT NULL,
  DATEEXPIRATION  DATE,
  
  CONSTRAINT pk_code          PRIMARY KEY(CODE),
  CONSTRAINT cs_tauxDeRabais  CHECK (TAUXDERABAIS BETWEEN 1 AND 99),
  CONSTRAINT cs_datesRabais   CHECK (DATEDEBUT < DATEEXPIRATION)
);
-- ************************************************************************************************************************************************


-- Table: TRANSACTION ------------------------------------------------------------------------------------------------------------------------------------
--
-- Une transaction est associée à un IDCLIENT. 
-- Si le client n'a pas utilisé de rabais lors de sa transaction, le CODERABAIS est NULL. Si le client a utilisé un rabais, alors la colonne
-- CODERABAIS contiendra le code du rabais utilisé par le client.
-- Une transaction a part défaut un statut 'en attente' et un coût 0 au moment de son insertion. Cela signifie que cette transaction est encore modifiable
-- Le coût d'une transaction donnée est mis-à-jour automatiquement lorsqu'une insertion dans la table LIGNETRANSACTION concerne cette transaction.
-- Une transaction s'effectue à une certaine DATEHEURE avec un certain MODEDEPAIEMENT"
--
-- Contraintes: - cs_statut: une transaction ne peut avoir que 4 statuts ('annulée', 'en attente', 'approuvée', 'payée')
--              - cs_modeDePaiement: le mode de paiement est contraint à seulement quelques modes de paiements autorisés
CREATE TABLE TRANSACTION 
(
  IDTRANSACTION   NUMBER(10)                          NOT NULL,
  IDCLIENT        NUMBER(10)                          NOT NULL,
  CODERABAIS      CHAR(5)       DEFAULT NULL,
  STATUT          VARCHAR2(15)  DEFAULT 'en attente'  NOT NULL,
  COUT            NUMBER(10, 2) DEFAULT 0             NOT NULL,
  DATEHEURE       DATE                                NOT NULL,
  MODEDEPAIEMENT  VARCHAR(16)                         NOT NULL,
  
  CONSTRAINT pk_idTransaction   PRIMARY KEY(IDTRANSACTION),
  CONSTRAINT fk_idClient        FOREIGN KEY(IDCLIENT) REFERENCES CLIENT,
  CONSTRAINT fk_codeRabais      FOREIGN KEY(CODERABAIS) REFERENCES RABAIS(CODE),
  CONSTRAINT cs_statut          CHECK (STATUT IN ('annulée', 'en attente', 'approuvée', 'payée')),
  CONSTRAINT cs_modeDePaiement  CHECK (MODEDEPAIEMENT IN ('CARTE_BANCAIRE', 'VISA', 'VISA_ELECTRON', 'MASTERCARD', 'AMERICAN_EXPRESS', 'CARTE_PREPAYEE', 'CARTE_CADEAU', 'PAYPAL'))
);
-- ************************************************************************************************************************************************


-- Table: LIGNETRANSACTION -------------------------------------------------------------------------------------------------------------------------------
--
-- Une ligne transaction est associée à une occurrence et à une transaction. Plusieurs lignes transaction peuvent être associées à une transaction.
-- Une ligne transaction a également une QUANTITE. Ainsi, une ligne qui a IDOCCURRENCE = 1, IDTRANSACTION = 1, QUANTITE = 2, cela signifie
-- que la transaction avec IDTRANSACTION = 1 a présentement dans sa transaction 2 billets pour l'occurrence dont l'IDOCCURRENCE = 1.
-- Une autre ligne transaction peut exister pour IDOCCURRENCE = 2, IDTRANSACTION = 1, QUANTITE = 3, signifie que la transaction avec IDTRANSACTION = 1
-- a dans sa transaction 3 billets pour l'IDOCCURRENCE = 2.
-- Ces lignes transaction nous permettent alors de calculer le coût d'une transaction de manière automatique à leur insertion.
--
-- Contraintes: - cs_quantitePositive: une ligne de transaction doit avoir forcément une quantité strictement positive pour pouvoir être insérée.
CREATE TABLE LIGNETRANSACTION
(
  IDTRANSACTION NUMBER(10) NOT NULL,
  IDOCCURRENCE NUMBER(10) NOT NULL,
  QUANTITE NUMBER(10) NOT NULL,
  
  CONSTRAINT pk_idTransactionIdOccurrence PRIMARY KEY(IDTRANSACTION, IDOCCURRENCE),
  CONSTRAINT fk_idTransaction             FOREIGN KEY(IDTRANSACTION) REFERENCES TRANSACTION,
  CONSTRAINT fk_idOccurrence              FOREIGN KEY(IDOCCURRENCE) REFERENCES OCCURRENCE,
  CONSTRAINT cs_quantitePositive          CHECK (QUANTITE > 0)
);                               
-- ************************************************************************************************************************************************











DROP VIEW billetsReserves;
DROP VIEW coutsTransaction;

-- View: BILLETSRESERVES ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Une ligne de transaction contient la quantité de billets qui ont été commandés par une transaction
-- Si la ligne de transaction est reliée à une transaction dont le statut est 'payée', alors le billet est considéré comme réservé
-- Une transaction dont le statut est 'approuvé' n'a pas nécessairement un billet qui lui est réservé. Ce qui compte, c'est que l'argent
-- ait été reçu pour qu'un billet soit sûr réservé.
--
-- Ainsi, nous avons accès à la quantité de billets vendus par occurrence et à la capacité de l'emplacement qui lui est associée ce qui va nous faciliter
-- certaines implantations de contraintes avec les trigger.
CREATE VIEW billetsReserves AS (SELECT LIGNETRANSACTION.IDOCCURRENCE, SUM(CASE WHEN QUANTITE IS NULL THEN 0 ELSE QUANTITE END) AS QUANTITE, 
                                                                      CASE WHEN CAPACITE IS NULL THEN 0 ELSE CAPACITE END AS CAPACITE
                                FROM  LIGNETRANSACTION, OCCURRENCE, EMPLACEMENT
                                WHERE LIGNETRANSACTION.IDOCCURRENCE = OCCURRENCE.IDOCCURRENCE 
                                      AND OCCURRENCE.IDEMPLACEMENT = EMPLACEMENT.IDEMPLACEMENT 
                                      AND IDTRANSACTION IN ( SELECT IDTRANSACTION
                                                             FROM TRANSACTION
                                                             WHERE STATUT = 'payée')
                                GROUP BY LIGNETRANSACTION.IDOCCURRENCE, EMPLACEMENT.CAPACITE) 
                                WITH CHECK OPTION;                          

-- View: COUTSTRANSACTION --
-- Cette view nous permet de calculer le coût des transactions en fonction des lignes transactions qui sont associées à ces transactions et le
-- code rabais utilisé lors de ces transactions. Cette view se met à jour en fonction des insertions et mis-à-jour dans les tables.
-- Ainsi, nous avons accès au coût d'une transaction très facilement, facilitant l'implantation de certains triggers.
CREATE VIEW coutsTransaction AS ((SELECT IDTRANSACTION, ROUND(SUM(PRIX * QUANTITE) - (SUM(PRIX * QUANTITE) * (CASE WHEN 
                                                                                                                  ( SELECT TAUXDERABAIS 
                                                                                                                    FROM RABAIS 
                                                                                                                    WHERE CODE = (SELECT  CODERABAIS 
                                                                                                                                          FROM TRANSACTION 
                                                                                                                                          WHERE IDTRANSACTION = LIGNETRANSACTION.IDTRANSACTION)) IS NULL THEN 0
                                                                                                                ELSE
                                                                                                                  ( SELECT  TAUXDERABAIS 
                                                                                                                            FROM RABAIS 
                                                                                                                            WHERE CODE = (SELECT CODERABAIS 
                                                                                                                                          FROM TRANSACTION 
                                                                                                                                          WHERE IDTRANSACTION = LIGNETRANSACTION.IDTRANSACTION)) 
                                                                                                                END ) / 100),2) AS COUT
                                    FROM  LIGNETRANSACTION, OCCURRENCE
                                    WHERE LIGNETRANSACTION.IDOCCURRENCE = OCCURRENCE.IDOCCURRENCE
                                    GROUP BY IDTRANSACTION)
                          UNION
                                (
                                    SELECT IDTRANSACTION, 0 AS COUT
                                    FROM TRANSACTION
                                    WHERE IDTRANSACTION NOT IN (SELECT IDTRANSACTION FROM LIGNETRANSACTION)
                                )) 
                          WITH CHECK OPTION;



-- TRIGGER: OCCURRENCE -------------------------------------------------------------------------------------------------------------------------------------------------------

-- Trigger: BUdateHeureOccurrence
-- La DATEHEURE n'a aucune contrainte à l'insertion.
-- En revanche, avant la mise à jour, on contraint à ce que chaque ligne transaction qui concerne cette occurrence aient une DATEHEUREligneTransaction < DATEHEUREOccurrence
-- Sinon il y aurait incohérence (transaction effectuée après le début d'une occurrence est impossible!). Après qu'une occurrence a débuté, la vente de billets est terminée.
CREATE OR REPLACE TRIGGER BUdateHeureOccurrence
  BEFORE UPDATE OF DATEHEURE ON OCCURRENCE
  FOR EACH ROW
  WHEN (NEW.IDOCCURRENCE IS NOT NULL)
  DECLARE
    CURSOR transactions IS  SELECT IDTRANSACTION
                            FROM LIGNETRANSACTION
                            WHERE LIGNETRANSACTION.IDOCCURRENCE = :NEW.IDOCCURRENCE;
    unIdTransaction         NUMBER(10);
    uneDateTransaction      DATE;
    uneDateOccurrence       DATE;
  BEGIN
  
    OPEN transactions;
    LOOP
      FETCH transactions INTO unIdTransaction;
      EXIT WHEN transactions%NOTFOUND;
      
      SELECT  DATEHEURE
      INTO    uneDateTransaction
      FROM    TRANSACTION
      WHERE   IDTRANSACTION = unIdTransaction;
      
      IF ( uneDateTransaction > :NEW.DATEHEURE ) THEN
        RAISE_APPLICATION_ERROR(-20021, 'Une occurrence ne peut pas avoir une dateHeure supérieure à une dateHeure de transaction rattachée à l''occurrence');
      END IF;
    END LOOP;
    CLOSE transactions;
  END;
/

-- Trigger: AUemplacementOccurrence
-- Après la mise à jour d'emplacements pour des occurrences, on vérifie que la nouvelle capacité est assez grande pour contenir tous les billets déjà payés.
-- Sinon la capacité est insuffisante pour le nouvel emplacement et on interdit la mise à jour de l'emplacement.
CREATE OR REPLACE TRIGGER AUemplacementOccurrence
  AFTER UPDATE OF IDEMPLACEMENT ON OCCURRENCE
  DECLARE
      uneCapacite NUMBER(10);
      unCount     NUMBER(10);
  BEGIN   
      SELECT COUNT(*)
      INTO   unCount
      FROM   BILLETSRESERVES
      WHERE  QUANTITE > CAPACITE;
      
      IF unCount != 0 THEN
        RAISE_APPLICATION_ERROR(-20020,'Capacité insuffisante pour le nouvel emplacement');
      END IF;      
  END;
/

-- Trigger: AUprixOccurrence
-- Si on met à jour le prix d'occurrences, on update le cout des transactions 'en attente' associées à ces occurrences.
-- Les transactions payés, annulées et approuvées ont été effectuées à un prix convenu, on ne modifie donc pas leur coût.
CREATE OR REPLACE TRIGGER AUprixOccurrence
  AFTER UPDATE OF PRIX ON OCCURRENCE
  DECLARE
    unIdTransaction NUMBER(10);
    CURSOR transactions IS  SELECT IDTRANSACTION
                            FROM TRANSACTION;
  BEGIN
    
    OPEN transactions;
    LOOP
      FETCH transactions INTO unIdTransaction;
      EXIT WHEN transactions%NOTFOUND;
      
      UPDATE TRANSACTION
      SET COUT = (SELECT COUT
                  FROM   COUTSTRANSACTION
                  WHERE  IDTRANSACTION = unIdTransaction)
      WHERE IDTRANSACTION = unIdTransaction AND STATUT = 'en attente';
    END LOOP;
    CLOSE transactions;
  END;
/
-- ************************************************************************************************************************************************************************



-- TRIGGER: EMPLACEMENT -------------------------------------------------------------------------------------------------------------------------------------------------------

-- Trigger: AUemplacement
-- Si on met à jour la capacité d'emplacements, on vérifie que la nouvelle capacité est assez grande pour contenir tous les billets déjà payés
-- pour toutes les occurrences associées à ces emplacements.
CREATE OR REPLACE TRIGGER AUemplacement
  AFTER UPDATE OF CAPACITE ON EMPLACEMENT
  DECLARE
      unCount NUMBER(10);
  BEGIN
    
    SELECT COUNT(*)
    INTO unCount
    FROM BILLETSRESERVES
    WHERE BILLETSRESERVES.QUANTITE > BILLETSRESERVES.CAPACITE;
    
    IF (unCount != 0) THEN
      RAISE_APPLICATION_ERROR(-20010,'Le nouvel emplacement n''a pas une capacité assez grande pour une des occurrences');
    END IF; 
  END;
/
-- ************************************************************************************************************************************************************************



-- TRIGGER: LIGNETRANSACTION -------------------------------------------------------------------------------------------------------------------------------------------------------

-- Trigger: BIUligneTransaction
-- On vérifie que la clé étrangère existe bien pour IDOCCURRENCE et IDTRANSACTION.
-- On vérifie avant d'insérer une ligne transaction, ou d'update son idoccurrence, que la dateHeureOccurrence > dateHeureTransaction
CREATE OR REPLACE TRIGGER BIUligneTransaction
BEFORE INSERT OR UPDATE ON LIGNETRANSACTION
FOR EACH ROW
DECLARE
    unStatut     VARCHAR2(200);
    unCount NUMBER(10);
    uneDateTransaction   DATE;
    uneDateOccurrence    DATE;
BEGIN

    SELECT COUNT(*)
    INTO unCount
    FROM TRANSACTION
    WHERE IDTRANSACTION = :NEW.IDTRANSACTION;
    
    IF (unCount = 0) THEN
      RAISE_APPLICATION_ERROR(-20083, 'IDTRANSACTION inexistant');
    END IF;
    
    SELECT COUNT(*)
    INTO unCount
    FROM OCCURRENCE
    WHERE IDOCCURRENCE = :NEW.IDOCCURRENCE;
    
    IF (unCount = 0) THEN
      RAISE_APPLICATION_ERROR(-20083, 'IDOCCURRENCE inexistant');
    END IF;
    
    SELECT STATUT
    INTO unStatut
    FROM TRANSACTION
    WHERE IDTRANSACTION = :NEW.IDTRANSACTION;
    
    IF (unStatut IN('payée', 'annulée', 'approuvée')) THEN
      RAISE_APPLICATION_ERROR(-20039, 'Impossible d''ajouter, de modifier ou de supprimer des lignes transaction d''une transaction  avec statut ''payée'', ''approuvée'', ou ''annulée''.');
    END IF;
    
-- VÉRIFICATION DE DATE  
    SELECT DATEHEURE
    INTO uneDateTransaction
    FROM TRANSACTION
    WHERE IDTRANSACTION = :NEW.IDTRANSACTION;
    
    SELECT DATEHEURE
    INTO uneDateOccurrence
    FROM OCCURRENCE
    WHERE IDOCCURRENCE = :NEW.IDOCCURRENCE;
    
    IF (uneDateTransaction > uneDateOccurrence) THEN
      RAISE_APPLICATION_ERROR(-20031, 'Incohérence entre la date de la transaction et la date de l''occurrence du billet'); 
    END IF;
END;
/

-- Trigger: BDligneTransaction
-- On ne peut pas supprimer des billets pour une transaction 'annulée' 'payée' ou 'approuvée'
CREATE OR REPLACE TRIGGER BDligneTransaction
  BEFORE DELETE ON LIGNETRANSACTION
  FOR EACH ROW
  DECLARE
    unStatut VARCHAR2(100);
  BEGIN
    
    SELECT STATUT
    INTO unStatut
    FROM TRANSACTION
    WHERE IDTRANSACTION = :OLD.IDTRANSACTION;
    
    IF (unStatut IN('payée', 'annulée', 'approuvée')) THEN
      RAISE_APPLICATION_ERROR(-20039, 'Impossible d''ajouter, de modifier ou de supprimer des lignes transaction d''une transaction  avec statut ''payée'', ''approuvée'', ou ''annulée''.');
    END IF;
  END;
/


-- Trigger: AIUDligneTransaction
-- On met à jour le coût des transaction 'en attente'.
-- On ne modifie pas le coût des transactions 'payée', 'en attente', ou 'approuvée' car ce sont des transactions passées.
-- On ne fait pas de vérification de capacité. Ce n'est qu'à partir du moment que la transaction est 'payée' que l'on vérifie si la capacité
-- de l'emplacement est suffisante pour délivrer les billets. Sinon la transaction ne pourra pas passer à payer.
CREATE OR REPLACE TRIGGER AIUDligneTransaction
  AFTER INSERT OR UPDATE OR DELETE ON LIGNETRANSACTION
  DECLARE
    unCount NUMBER(10);
    unIdTransaction NUMBER(10);
    CURSOR transactions IS  SELECT IDTRANSACTION
                            FROM TRANSACTION;
  BEGIN   
    UPDATE TRANSACTION
    SET TRANSACTION.STATUT = 'en attente'
    WHERE TRANSACTION.IDTRANSACTION NOT IN (SELECT LIGNETRANSACTION.IDTRANSACTION FROM LIGNETRANSACTION);
    
    OPEN transactions;
    LOOP
      FETCH transactions INTO unIdTransaction;
      EXIT WHEN transactions%NOTFOUND;
    

      UPDATE TRANSACTION
      SET COUT = (SELECT COUT
                  FROM COUTSTRANSACTION
                  WHERE IDTRANSACTION = unIdTransaction)
      WHERE IDTRANSACTION = unIdTransaction AND STATUT = 'en attente';
    END LOOP;
    CLOSE transactions;
  END;
/
-- ************************************************************************************************************************************************************************



-- TRIGGER: TRANSACTION -------------------------------------------------------------------------------------------------------------------------------------------------------

-- Trigger: BUrabaisTransaction
-- Interdire de modifier le rabais d'une transaction dont le statut est 'payée', 'approuvée' ou 'annulée'. La transaction est passée.
CREATE OR REPLACE TRIGGER BUrabaisTransaction
  BEFORE UPDATE OF CODERABAIS ON TRANSACTION
  FOR EACH ROW
  BEGIN
    IF (:NEW.STATUT != 'en attente') THEN
      RAISE_APPLICATION_ERROR(-20048, 'Vous ne pouvez pas changer le rabais d''une transaction dont le statut est ''payée'' ''approuvée'' ''annulée''. Vous pouvez changer le taux de rabais seulement pour les transactions dont le statut est ''en attente'' ');
    END IF;
  END;
/


-- Trigger: AUrabaisTransaction
-- Mise a jour du coût si changement rabais d'une transaction en attente
CREATE OR REPLACE TRIGGER AIUrabaisTransaction
  AFTER INSERT OR UPDATE OF CODERABAIS ON TRANSACTION
  DECLARE
    CURSOR transactions IS  SELECT IDTRANSACTION 
                            FROM TRANSACTION
                            WHERE STATUT = 'en attente';
    unIdTransaction NUMBER(10);
  BEGIN 
    OPEN transactions;
    LOOP
      FETCH transactions INTO unIdtransaction;
      EXIT WHEN transactions%NOTFOUND;
      
      UPDATE TRANSACTION
      SET COUT = (SELECT COUT 
                  FROM COUTSTRANSACTION 
                  WHERE COUTSTRANSACTION.IDTRANSACTION = unIdTransaction)
      WHERE IDTRANSACTION = unIdTransaction;
    END LOOP;
    CLOSE transactions;
  END;
/


-- Trigger: BItransaction
-- Une transaction doit avoir un statut 'en attente' à l'insertion. En effet, la transaction n'est liée à aucune ligne transaction, elle ne peut donc
-- avoir un statut 'payée', 'annulée' ou 'approuvée'
CREATE OR REPLACE TRIGGER BItransaction
  BEFORE INSERT ON TRANSACTION
  FOR EACH ROW
  BEGIN
    IF (:NEW.STATUT != 'en attente') THEN
      RAISE_APPLICATION_ERROR(-20040, 'Une transaction qui n''est reliée à aucun billets doit avoir un statut ''en attente''');
    END IF;
  END;
/

-- Trigger: BUtransaction
-- Avant de mettre à jour une transaction, si celle-ci était 'payée' ou 'annulée' alors on ne peut plus la modifier.
-- Si la transaction est 'approuvée', alors on peut changer son statut à 'annulée' ou 'payée' mais la transaction ne peut pas retourner au
-- statut 'en attente'.
-- Contraint à ne pas pouvoir changer le coût, le mode de paiement, ou l'idClient d'une transaction dont le statut est 'approuvée'
CREATE OR REPLACE TRIGGER BUtransaction
  BEFORE UPDATE ON TRANSACTION
  FOR EACH ROW
  BEGIN
    IF (:OLD.STATUT IN ('payée', 'annulée')) THEN
      RAISE_APPLICATION_ERROR(-20047, 'On ne peut pas modifier une transaction ''payée'' ou ''annulée''');
    ELSIF (:OLD.STATUT = 'approuvée' AND :NEW.STATUT = 'en attente') THEN
      RAISE_APPLICATION_ERROR(-20094, 'Une transaction ne peut pas passer du statut ''approuvée'' à ''en attente''');
    END IF;
    
    IF (((:OLD.MODEDEPAIEMENT != :NEW.MODEDEPAIEMENT ) OR (:OLD.COUT != :NEW.COUT) OR (:OLD.IDCLIENT != :NEW.IDCLIENT)) AND :OLD.STATUT = 'approuvée') THEN
      RAISE_APPLICATION_ERROR(-20091, 'Vous ne pouvez pas changer le mode de paiement, le coût, ou l''idclient d''une transaction ''approuvée''.');
    END IF;
  END;
/


-- Trigger: AIUstatutTransaction
-- Après la mise à jour de statut de transactions, on vérifie que les transactions qui ont un statut 'payée' ne font pas dépasser
-- la capacité des occurrences auxquelles les transactions sont reliées. Sinon on ne peut pas changer le statut de la transaction à 'payée'.
-- De plus, on vérifie que des lignes transactions existent pour les transactions qui ont un statut 'payée', 'approuvée', ou 'annulée'
-- Sinon on interdit également la mise à jour du statut.
CREATE OR REPLACE TRIGGER AIUstatutTransaction
  AFTER INSERT OR UPDATE OF STATUT ON TRANSACTION
  DECLARE
    unCount NUMBER(10);
    unIdTransaction NUMBER(10);
    unStatut VARCHAR2(100);
    CURSOR transactions IS SELECT IDTRANSACTION
                           FROM TRANSACTION;
                
  BEGIN
    
    SELECT COUNT(*)
    INTO unCount
    FROM BILLETSRESERVES;
  
    IF (unCount != 0) THEN
      SELECT COUNT(*)
      INTO unCount
      FROM BILLETSRESERVES
      WHERE QUANTITE > CAPACITE;
    
      IF unCount > 0 THEN 
        RAISE_APPLICATION_ERROR(-20040, 'Plus assez de billets disponibles pour une occurrence pour changer le statut d''une transaction');
      END IF;
    END IF;
    
    OPEN transactions;
    LOOP
      FETCH transactions INTO unIdTransaction;
      EXIT WHEN transactions%NOTFOUND;
      
      SELECT COUNT(*)
      INTO unCount
      FROM LIGNETRANSACTION
      WHERE IDTRANSACTION = unIdTransaction;
      
      IF unCount = 0 THEN
        SELECT STATUT
        INTO unStatut
        FROM TRANSACTION
        WHERE IDTRANSACTION = unIdTransaction;
        
        IF (unStatut IN ('payée', 'approuvée', 'annulée')) THEN
          RAISE_APPLICATION_ERROR(-20045, 'Une transaction ne peut pas avoir un statut ''payée'', ''annulée'' ou ''approuvée'' si aucunes lignes transaction n''est lié à cette transaction');
        END IF;
      END IF;
    END LOOP;
    CLOSE transactions;
    
  END;
/


-- Trigger: BUdateHeureTransaction
-- On ne peut pas modifier la dateHeure d'une transaction avec un statut 'payée' ou 'annulée'
-- On autorise la modification de la dateHeure d'une transaction 'approuvée' dans la mesure où elle peut désigner l'heure d'un changement de statut vers 'payée' ou 'annulée'.
-- La nouvelle dateHeure ne peut donc être inférieure à l'ancienne dateHeure quelque soit le statut de la transaction
-- La date heure doit être, de plus, inférieures à tous les dateheures des occurrences (on regarde les lignestransactions associées à cette transaction pour trouver ces occurrences) .
CREATE OR REPLACE TRIGGER BIUdateHeureTransaction
  BEFORE UPDATE OF DATEHEURE ON TRANSACTION
  FOR EACH ROW
  DECLARE
    CURSOR billetsTransaction IS  SELECT IDOCCURRENCE
                                  FROM LIGNETRANSACTION
                                  WHERE IDTRANSACTION = :NEW.IDTRANSACTION;
    unIdOccurrence  NUMBER(10);
    uneDateOccurrence DATE;
  BEGIN    
    IF (:OLD.DATEHEURE > :NEW.DATEHEURE) THEN
      RAISE_APPLICATION_ERROR(-20040, 'La nouvelle date ne peut pas être inférieure à l''ancienne date de la transaction');
    END IF;
    
    OPEN billetsTransaction;
    LOOP
      FETCH billetsTransaction INTO unIdOccurrence;
      EXIT WHEN billetsTransaction%NOTFOUND;
      
      SELECT DATEHEURE
      INTO uneDateOccurrence
      FROM OCCURRENCE
      WHERE IDOCCURRENCE = unIdOccurrence;
      
      IF (uneDateOccurrence < :NEW.DATEHEURE) THEN
        RAISE_APPLICATION_ERROR(-20455, 'La nouvelle date de transaction est une date qui est après une des dates des occurrences auxquelles la transaction a acheté des billets. Modification incohérente');
      END IF;
    END LOOP;
  END;
/
-- ************************************************************************************************************************************************************************


-- TRIGGER: RABAIS -------------------------------------------------------------------------------------------------------------------------------------------------------

-- Trigger: BIUdatesRabais
-- S'il existe une transaction utilisant ce rabais existe telle que NOT(dateDebutRabais <= dateTransaction <= DateExpirationRabais), alors
-- on interdit la mise à jour des dates du rabais.
CREATE OR REPLACE TRIGGER BIUdatesRabais
  BEFORE INSERT OR UPDATE OF DATEDEBUT, DATEEXPIRATION ON RABAIS
  FOR EACH ROW
  DECLARE
    CURSOR datesTransaction IS  SELECT DATEHEURE
                                FROM TRANSACTION
                                WHERE CODERABAIS = :NEW.CODE;
    uneDateTransaction DATE;
  BEGIN
    
    OPEN datesTransaction;   
    LOOP
      FETCH datesTransaction INTO uneDateTransaction;
      EXIT WHEN datesTransaction%NOTFOUND;
      
      IF (uneDateTransaction < :NEW.DATEDEBUT OR uneDateTransaction > CASE WHEN :NEW.DATEEXPIRATION IS NULL THEN '01/01/1900 00:00' ELSE :NEW.DATEEXPIRATION END ) THEN
        RAISE_APPLICATION_ERROR(-20050,'Une transaction existe qui n''est pas telle que dateDebutRabais <= dateTransaction <= DateExpirationRabais');
      END IF;
    END LOOP;
    CLOSE datesTransaction;
  END;
/

-- Trigger: BUtauxRabais
-- Contexte: On met à jour des taux de rabais.
-- S'il existe des transactions avec un statut 'payée', 'approuvée' ou 'annulée' utilisant ce rabais, on interdit la mise à jour du taux de rabais.
-- Si ce rabais n'est utilisé que par des transactions avec un statut 'en attente', on autorise la mise à jour du taux de rabais
CREATE OR REPLACE TRIGGER BUtauxRabais
  BEFORE UPDATE OF TAUXDERABAIS ON RABAIS
  FOR EACH ROW
  DECLARE
    unCount NUMBER(10);
  BEGIN
    
    SELECT COUNT(*)
    INTO unCount
    FROM TRANSACTION
    WHERE CODERABAIS LIKE :NEW.CODE AND STATUT != 'en attente';
    
    IF (unCount != 0) THEN
      RAISE_APPLICATION_ERROR(-20069, 'Il existe des transactions dont le coût est calculé à partir de l''ancien taux de rabais. Vous ne pouvez donc pas modifier le taux de ce rabais.');
    END IF;
  END;
/


-- Trigger: AUtauxRabais 
-- Contexte: On met à jour des taux de rabais.
-- Si ces taux de rabais sont utilisés seulement par des transactions 'en attente',on met à jour le coût des transactions 'en attente' 
-- avec le nouveau taux de rabais.
CREATE OR REPLACE TRIGGER AUtauxRabais
  AFTER UPDATE OF TAUXDERABAIS ON RABAIS
  DECLARE
    unIdTransaction NUMBER(10);
    CURSOR transactions IS (SELECT IDTRANSACTION 
                            FROM TRANSACTION 
                            WHERE STATUT = 'en attente');
  BEGIN
    OPEN transactions;
    LOOP
      FETCH transactions INTO unIdTransaction;
      EXIT WHEN transactions%NOTFOUND;

      UPDATE TRANSACTION
      SET COUT = (SELECT COUT
                  FROM COUTSTRANSACTION
                  WHERE IDTRANSACTION = unIdTransaction)
      WHERE IDTRANSACTION = unIdTransaction;
    END LOOP;
    CLOSE transactions;
  END;
/
-- ************************************************************************************************************************************************************************
