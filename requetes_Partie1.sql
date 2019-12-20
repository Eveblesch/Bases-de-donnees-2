/***************************************************************
1) Nombre d’activité des agendas par catégorie et par utilisateur
***************************************************************/
--> par utilisateur
SELECT idAgenda,type, count(idActivite) FROM AGENDA_ACTIVITE NATURAL JOIN ACTIVITE GROUP BY type,idAgenda;
--> Par catégorie
SELECT idAgenda,idUser,count(idActivite) FROM UTILISATEUR_AGENDA NATURAL JOIN AGENDA_ACTIVITE GROUP BY idUser,idAgenda ORDER BY idAgenda;
--> Les deux en même temps
SELECT idAgenda,idUser, type, count(idActivite) FROM (UTILISATEUR_AGENDA NATURAL JOIN AGENDA_ACTIVITE) NATURAL JOIN ACTIVITE GROUP BY idUser,idAgenda,type ORDER BY idAgenda;

/***************************************************************
2) Nombre d’évaluations totales pour les utilisateurs actifs
***************************************************************/

SELECT DISTINCT(idUser),derniereModif FROM UTILISATEUR_AGENDA NATURAL JOIN AGENDA WHERE ((MONTHS_BETWEEN(SYSDATE,derniereModif)) < 3) GROUP BY idUser,derniereModif ORDER BY idUser;

/***************************************************************************************************
3) Les agendas ayant eu au moins cinq évaluations et dont la note moyenne est inférieure à trois
***************************************************************************************************/

SELECT idAgenda FROM (SELECT idAgenda,noteMoy,COUNT(note) AS somme FROM UTILISATEUR_AGENDA NATURAL JOIN AGENDA WHERE noteMoy<3 GROUP BY idAgenda,noteMoy) WHERE somme>=5;


/*************************************************************************
4) L’agenda ayant le plus grand nombre d’activités en moyenne par semaine
**************************************************************************/
-- la base

SELECT idAgenda,COUNT(idActivite)/((MAX(heureFin)-MIN(heureDebut))*7) FROM AGENDA_ACTIVITE NATURAL JOIN ACTIVITE GROUP BY idAgenda;

-- la requete

SELECT MAX(moyenne) from (SELECT idAgenda,(COUNT(idActivite)/((MAX(heureFin)-MIN(heureDebut))*7)) as moyenne FROM AGENDA_ACTIVITE NATURAL JOIN ACTIVITE GROUP BY idAgenda);

-- version finale

SELECT base.idAgenda FROM
  (SELECT idAgenda,COUNT(idActivite)/((MAX(heureFin)-MIN(heureDebut))*7) AS moyenne FROM AGENDA_ACTIVITE NATURAL JOIN ACTIVITE GROUP BY idAgenda) base JOIN
  (SELECT MAX(moyenne) AS maxmoy FROM (SELECT idAgenda,(COUNT(idActivite)/((MAX(heureFin)-MIN(heureDebut))*7)) AS moyenne FROM AGENDA_ACTIVITE NATURAL JOIN ACTIVITE GROUP BY idAgenda)) maxbase
ON maxbase.maxmoy=base.moyenne;


--autre version (avec WITH)
WITH base AS (SELECT idAgenda,COUNT(idActivite)/((MAX(heureFin)-MIN(heureDebut))*7) AS moyenne FROM AGENDA_ACTIVITE NATURAL JOIN ACTIVITE GROUP BY idAgenda)
SELECT base.idAgenda from base join (SELECT MAX(moyenne) as maxmoy from base) maxbase on maxbase.maxmoy=base.moyenne;

/***************************************************************************************************
5) Pour chaque utilisateur, son login, son nom, son prénom, son adresse, son nombre d’agendas, son
   nombre d’activités et son nombre d’évaluation.
***************************************************************************************************/
SELECT * FROM
  ((SELECT idUser,login,nom,prenom,adresse,count(idAgenda),count(note)
    FROM UTILISATEUR NATURAL JOIN UTILISATEUR_AGENDA
    GROUP BY (idUser,login,nom,prenom,adresse))
    NATURAL JOIN (SELECT idUser, sum(somme) FROM (SELECT idUser,count(idActivite) AS somme FROM UTILISATEUR_ACTIVITE GROUP BY (iduser)
    UNION SELECT idUser,count(idUser) AS somme FROM UTILISATEUR_AGENDA NATURAL JOIN AGENDA NATURAL JOIN AGENDA_ACTIVITE
    GROUP BY (idUser)) GROUP BY (idUser)));
