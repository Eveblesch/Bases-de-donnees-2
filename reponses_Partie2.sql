/*********************************************************
CERDAN Baptiste                               L3S5 CMI
BLESCH Eve                          Université de Strasbourg

            Partie 2 - Projet BDD2
**********************************************************/

----------------------------------------------------------
-- 1.1 Définir une fonction qui convertit au format csv
----------------------------------------------------------
CREATE OR REPLACE FUNCTION csv_activite
(nom_activite IN VARCHAR2)
 RETURN VARCHAR2
 IS
 CURSOR activite_cur IS SELECT idActivite,titre,descriptif,heureDebut,heureFin,periodicite,priorite,type,archive FROM ACTIVITE WHERE titre=nom_activite;
 REPONSE VARCHAR2(1000);
BEGIN
  FOR row in activite_cur
  LOOP
    REPONSE := REPONSE||row.idActivite ||','||row.titre||','||row.descriptif||','||row.heureDebut||','||row.heureFin||','||row.periodicite||','||row.priorite||','||row.type||','||row.archive||CHR(13)||CHR(10);
  END LOOP;
  RETURN REPONSE;
END;
/

/*
  EXECUTION :
  SELECT CSV_activite('Judo') FROM DUAL;
*/



----------------------------------------------------------
-- 1.2 Procédure qui permet de fusionner plusieurs agendas
----------------------------------------------------------
/*
  Notre enseignant de TP nous a indiqué qu'il suffisait de faire une fusion de deux agendas.
  Nous avons donc fait une procédure qui fusionne 2 agendas, qu'il faudra appeler N-1 fois
  pour avoir la fusion de N agendas.
*/

CREATE OR REPLACE PROCEDURE fusion_agenda
(agenda1 integer, agenda2 integer)
IS
  CURSOR agenda_cur IS select idActivite, heureDebut from AGENDA_ACTIVITE NATURAL JOIN ACTIVITE WHERE idAgenda=agenda1 OR idAgenda=agenda2 ORDER BY (heureDebut);
  idCOURANT_v INT;
  newAgenda_v INT;
BEGIN
   newAgenda_v :=seq_agenda.nextval;
   SELECT idCreateur INTO idCOURANT_v FROM AGENDA WHERE idAgenda=agenda1;
   INSERT INTO AGENDA VALUES(newAgenda_v, idCOURANT_v, to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY'), 0, 0, NULL,0);
    FOR row IN agenda_cur
    LOOP
      INSERT INTO AGENDA_ACTIVITE VALUES(newAgenda_v,row.idActivite,1);
    END LOOP;
    INSERT INTO UTILISATEUR_AGENDA VALUES(idCOURANT_v,newAgenda_v,NULL,NULL,1,0,to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY'),NULL);
  DBMS_OUTPUT.PUT_LINE('Agendas fusionnés');
END;
/
/*
  Execution :
  execute fusion_agenda(1,2);
*/

---------------------------------------------------------------------------
-- 1.3 Procédure qui créé une activité inférée à partir d’agendas existants
----------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE inferer_activite
(nomActivite IN ACTIVITE.titre%type, dateModifDebut IN ACTIVITE.heureDebut%type, dateModifFin IN ACTIVITE.heureFin%type)
IS
    CURSOR activite_cur IS SELECT idAgenda, idActivite, heureDebut, heureFin FROM ACTIVITE NATURAL JOIN AGENDA_ACTIVITE;
    description_v ACTIVITE.descriptif%type;
    posG_v ACTIVITE.positionG%type;
    period_v ACTIVITE.periodicite%type;
    priorite_v ACTIVITE.priorite%type;
    type_v ACTIVITE.type%type;
    archive_v ACTIVITE.archive%type;
    nouveauIdActivite_v INT;
BEGIN
  SELECT descriptif,positionG,periodicite,priorite,type,archive INTO description_v,posG_v,period_v,priorite_v,type_v,archive_v FROM ACTIVITE WHERE titre=nomActivite;
  nouveauIdActivite_v := seq_activite.nextval;
  INSERT INTO ACTIVITE VALUES(nouveauIdActivite_v,nomActivite,description_v,posG_v,dateModifDebut,dateModifFin,period_v,priorite_v,type_v,archive_v);
  FOR row IN activite_cur
  LOOP
    UPDATE AGENDA_ACTIVITE SET idActivite=nouveauIdActivite_v WHERE idAgenda=row.idAgenda;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Procédure inferer_activite terminée');
END;
/

/*
  EXECUTION :
  EXECUTE inferer_activite('Handball',TO_DATE('02/12/2019 09:00', 'MM/DD/YYYY HH24:MI'),TO_DATE('02/2/2019 16:30', 'MM/DD/YYYY HH24:MI'));

*/

----------------------------------------------------------------------------
-- 1.4 Procédure qui archive les agendas dont toutes les dates sont passées.
-----------------------------------------------------------------------------
/*
Lorsqu'un agenda est passé et donc qu'un utilisateur supprime un agenda, nous ne le supprimons pas
rééllement de la table AGENDA. Nous avons une variable booléenne archive initialisée à 0, qui est
changée en 1 lorsque l'agenda est archivé. En même temps, l'id de l'agenda archivé est
inserée dans la table ARCHIVE_AGENDA. Enfin, la ligne supprimée est réinserée a la même place qu'au départ
dans la table AGENDA avec la variable archive modifiée (Idem pour l'archivage des agendas).
Ainsi, pour récupérer tous les agendas non archivés, il suffira de récuperer ceux dont archive est 0.
*/

CREATE OR REPLACE PROCEDURE activite_passee
IS
  CURSOR agenda_cur IS SELECT idAgenda FROM AGENDA;
  CURSOR activite_ag_cur IS SELECT idActivite,idAgenda FROM AGENDA_ACTIVITE;
  estPassee_v BOOLEAN;
  datePassee_v DATE;
  BEGIN
    FOR row_agenda IN agenda_cur
    LOOP
      estPassee_v := FALSE;
      FOR row_activite IN activite_ag_cur
      LOOP
        SELECT heureFin INTO datePassee_v FROM ACTIVITE WHERE idActivite=row_activite.idActivite;
        IF(datePassee_v>SYSDATE)
        THEN
          estPassee_v:=FALSE;
        END IF;
      END LOOP;
      IF(estPassee_v=TRUE)
      THEN
          UPDATE AGENDA SET archive = 1 WHERE idAgenda=row_agenda.idAgenda;
          INSERT INTO ARCHIVE_AGENDA VALUES(seq_archive_agenda.nextval,row_agenda.idAgenda);
          DBMS_OUTPUT.PUT_LINE('Toutes les activités de agenda '||row_agenda.idAgenda||' sont passées');
      END IF;
    END LOOP;
  END;
  /

/*
  EXECUTION :
  EXECUTE activite_passee();
*/

---------------------------------------------------------------
-- 2.1 Un agenda comportera au maximum 50 activités par semaine.
----------------------------------------------------------------

CREATE OR REPLACE TRIGGER activiteMaxSemaine
  BEFORE INSERT OR UPDATE ON AGENDA_ACTIVITE
  FOR EACH ROW
  DECLARE
    CURSOR semaineCursor IS
    SELECT to_char(heureFin - 7/24,'IYYY'), to_char(heureDebut - 7/24,'IW'),idAgenda, COUNT(idActivite) AS Activites_semaine
      FROM ACTIVITE NATURAL JOIN AGENDA_ACTIVITE GROUP BY to_char(heureFin - 7/24,'IYYY'), to_char(heureDebut - 7/24,'IW'), idAgenda;

  BEGIN
    FOR row IN semaineCursor
    LOOP
    IF (row.Activites_semaine>=50)
    THEN
       RAISE_APPLICATION_ERROR(-20004,'Erreur nombres activites trop important');
    END IF;
   END LOOP;
END;
/

----------------------------------------------------------------------------------------------------------------------------
-- 2.2 Les agendas et les activités supprimées seront archivés pour pouvoir être récupérés si nécessaire.
------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER archivage_activite
  AFTER DELETE ON ACTIVITE
  FOR EACH ROW
  DECLARE
    idArchive_v INTEGER;
    idActivite_v INTEGER;
  BEGIN
    idArchive_v:=seq_archive_activite.nextval;
    INSERT INTO ACTIVITE_SUPPRIME VALUES(idArchive_v, :old.idActivite, :old.titre, :old.descriptif, :old.positionG,:old.heureDebut,:old.heureFin,:old.periodicite,:old.priorite,:old.type);
    DBMS_OUTPUT.PUT_LINE('Trigger archivage activite déclenché');
  END;
  /

CREATE OR REPLACE TRIGGER archivage_agenda
  BEFORE DELETE ON AGENDA
  	FOR EACH ROW
  DECLARE
    idArchive_v INTEGER;
  BEGIN
    idArchive_v:=seq_archive_agenda.nextval;
    INSERT INTO AGENDA_SUPPRIME VALUES(idArchive_v,:old.idAgenda,:old.idCreateur,:old.dateCreation,:old.noteMoy,:old.superposition,SYSDATE);
    dbms_output.put_line('Trigger archivage agenda déclenché');
  END;
  /


----------------------------------------------------------------------------------------------------------------------------
-- 2.3 Le nombre d’activités présentes dans l’agenda et la périodicité indiquée pour l’activité correspondent strictement
------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER periodicite_valide
BEFORE INSERT ON AGENDA_ACTIVITE
FOR EACH ROW
  DECLARE
    CURSOR agenda_act_cur IS SELECT idAgenda,idActivite,occurrence FROM AGENDA_ACTIVITE where idAgenda=:new.idAgenda;
    titre_courant_v VARCHAR2(200);
    titre_v VARCHAR2(200);
    compteur_v INTEGER;
  BEGIN
    compteur_v := 0;
    SELECT titre INTO titre_courant_v FROM ACTIVITE WHERE idActivite=:new.idActivite;
      FOR row in agenda_act_cur
      LOOP
          SELECT titre INTO titre_v FROM ACTIVITE WHERE idActivite=row.idActivite;
          IF(titre_v=titre_courant_v)
          THEN
            compteur_v := compteur_v+1;
          END IF;
      END LOOP;
      IF(compteur_v!=0)
      THEN
        FOR row_second in agenda_act_cur
        LOOP
          SELECT titre INTO titre_v FROM ACTIVITE WHERE idActivite=row_second.idActivite;
          UPDATE AGENDA_ACTIVITE SET occurrence=compteur_v+1 WHERE idAgenda=:new.idAgenda AND idActivite=row_second.idActivite;
        END LOOP;
        :new.occurrence:=compteur_v+1;
      ELSE
        :new.occurrence:=1;
      END IF;
END;
/

----------------------------------------------------------------------------------------------------------------------------
-- 2.4   Pour les agendas où la simultanéité d’activité n’est pas autorisée, interdire que deux activités
--       aient une intersection non nulle de leur créneau.
------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER simultaneite_activite
  BEFORE UPDATE ON ACTIVITE
  FOR EACH ROW
  DECLARE
    CURSOR agenda_cur IS SELECT idAgenda FROM AGENDA WHERE superposition=0;
    CURSOR activite_cur IS SELECT idAgenda,heureDebut,heureFin FROM ACTIVITE NATURAL JOIN AGENDA_ACTIVITE;
    count_intersection_v INTEGER;
  BEGIN
    FOR row_agenda IN agenda_cur
    LOOP
      FOR row_activite IN activite_cur
      LOOP
        SELECT COUNT(row_activite.heureDebut) INTO count_intersection_v FROM ACTIVITE WHERE row_activite.idAgenda=row_agenda.idAgenda
        INTERSECT SELECT COUNT(row_activite.heureFin) FROM ACTIVITE WHERE row_activite.idAgenda=row_agenda.idAgenda;
        IF (count_intersection_v!=0)
        THEN
        RAISE_APPLICATION_ERROR(-20500,'Erreur de simultaneite');
        END IF;
      END LOOP;
    END LOOP;
  END;
/

----------------------------------------------------------------------------------------------------------------------------
-- 2.5  Afin de limiter le spam d'évaluation, un utilisateur enregistré depuis moins d'un semaine ne
--      pourra écrire une évaluation que toutes les 5 minutes.
------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE TRIGGER eval_agenda
  BEFORE INSERT ON UTILISATEUR_AGENDA
  FOR EACH ROW
  DECLARE
    CURSOR eval_cur IS SELECT derniereModif,dateInscription FROM UTILISATEUR_AGENDA;
  BEGIN
    FOR row_userAgenda IN eval_cur
      LOOP
        IF (row_userAgenda.derniereModif>(SYSDATE-(5/1440)) AND row_userAgenda.dateInscription>(SYSDATE - 7))
        THEN
          RAISE_APPLICATION_ERROR(-20921,'Ajout des notes refusé, veuillez attendre au moins 5 minutes avant votre dernier ajout');
        END IF;
      END LOOP;
END;
  /


CREATE OR REPLACE TRIGGER eval_activite
  BEFORE INSERT ON UTILISATEUR_ACTIVITE
  FOR EACH ROW
  DECLARE
    CURSOR eval_cur IS SELECT derniereModif,dateInscription FROM UTILISATEUR_ACTIVITE;
  BEGIN
    FOR row_utilisateur_activite IN eval_cur
      LOOP
        IF (row_utilisateur_activite.derniereModif>(SYSDATE-(5/1440)) AND row_utilisateur_activite.dateInscription>(SYSDATE - 7))
        THEN
          RAISE_APPLICATION_ERROR(-20922,'Ajout des notes refusé, veuillez attendre au moins 5 minutes avant votre dernier ajout');
        END IF;
    END LOOP;
END;
/
