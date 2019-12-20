CREATE TABLE UTILISATEUR
(
    idUser number(8) PRIMARY KEY,
    nom varchar2(100) NOT NULL,
    prenom varchar2(100) NOT NULL,
    login varchar2(100) NOT NULL,
    adresse varchar2(200),
    CONSTRAINT login_unique UNIQUE (login)
);


CREATE TABLE AGENDA
(
    idAgenda number(8) PRIMARY KEY,
    idCreateur number(8) NOT NULL,
    dateCreation date NOT NULL,
    noteMoy float(2) DEFAULT NULL,
    superposition INTEGER DEFAULT 0,
    dateModif date DEFAULT NULL,
    archive INT DEFAULT 0,
    FOREIGN KEY (idCreateur) REFERENCES UTILISATEUR(idUser),
    CONSTRAINT superposition_CT CHECK (superposition=1 OR superposition=0),
    CONSTRAINT archive_CT CHECK (archive=1 OR archive=0)
);


CREATE TABLE ACTIVITE
(
    idActivite number(8) PRIMARY KEY,
    titre varchar2(200) NOT NULL,
    descriptif varchar2(200),
    positionG varchar2(200),
    heureDebut DATE NOT NULL,
    heureFin DATE NOT NULL,
    periodicite number(3),
    priorite INT DEFAULT 0,
    type varchar2(100) NOT NULL,
    archive INT DEFAULT 0,
    CONSTRAINT priorite_CT CHECK (priorite=1 OR priorite=0),
    CONSTRAINT archiveAct_CT CHECK (archive=1 OR archive=0)
);

CREATE TABLE UTILISATEUR_AGENDA
(
    idUser number(8),
    idAgenda number(8),
    note number(1),
    commentaire varchar2(200) DEFAULT NULL,
    lecture INT DEFAULT 1,
    ecritureLecture INT DEFAULT 0,
    derniereModif date DEFAULT NULL,
    dateInscription date DEFAULT NULL,
    CHECK (note between 0 and 5),
    PRIMARY KEY(idUser,idAgenda),
    FOREIGN KEY(idAgenda) REFERENCES AGENDA(idAgenda) ON DELETE CASCADE,
    FOREIGN KEY(idUser) REFERENCES UTILISATEUR(idUser),
    CONSTRAINT lecture_CT CHECK (lecture=1 OR lecture=0),
    CONSTRAINT ecritureLecture_CT CHECK (ecritureLecture=1 OR ecritureLecture=0)
);

CREATE TABLE AGENDA_ACTIVITE
(
    idAgenda number(8),
    idActivite number(8),
    occurrence number(3),
    FOREIGN KEY (idAgenda) REFERENCES AGENDA(idAgenda) ON DELETE CASCADE,
    FOREIGN KEY (idActivite) REFERENCES ACTIVITE(idActivite) ON DELETE CASCADE
);

CREATE TABLE UTILISATEUR_ACTIVITE
(
  idUser number(8),
  idActivite number(8),
  note number(1),
  commentaire varchar2(8) DEFAULT NULL,
  derniereModif date DEFAULT NULL,
  dateInscription date DEFAULT NULL,
  CHECK (note between 0 and 5),
  FOREIGN KEY (idUser) REFERENCES UTILISATEUR(idUser),
  FOREIGN KEY (idActivite) REFERENCES ACTIVITE(idActivite) ON DELETE CASCADE
);

CREATE TABLE ACTIVITE_SUPPRIME
(
  idArchive number(8) PRIMARY KEY,
  idActivite number(8),
  titre varchar2(200) NOT NULL,
  descriptif varchar2(200),
  positionG varchar2(200),
  heureDebut DATE NOT NULL,
  heureFin DATE NOT NULL,
  periodicite number(3),
  priorite INT DEFAULT 0,
  type varchar2(100) NOT NULL
);

CREATE TABLE ARCHIVE_ACTIVITE
(
  idArchive number(8) PRIMARY KEY,
  idActivite number(8) NOT NULL,
  FOREIGN KEY(idActivite) REFERENCES ACTIVITE(idActivite) ON DELETE CASCADE,
  FOREIGN KEY(idArchive) REFERENCES ACTIVITE_SUPPRIME(idArchive) ON DELETE CASCADE
);

CREATE TABLE AGENDA_SUPPRIME
(
  idArchive number(8) PRIMARY KEY,
  idAgenda number(8),
  idCreateur number(8) NOT NULL,
  dateCreation date NOT NULL,
  noteMoy float(2) DEFAULT NULL,
  superposition INTEGER DEFAULT 0,
  dateModif date DEFAULT NULL
);

CREATE TABLE ARCHIVE_AGENDA
(
  idArchive number(8) PRIMARY KEY,
  idAgenda number(8) NOT NULL,
  FOREIGN KEY(idAgenda) REFERENCES AGENDA(idAgenda) ON DELETE CASCADE,
  FOREIGN KEY(idArchive) REFERENCES AGENDA_SUPPRIME(idArchive) ON DELETE CASCADE
);



create sequence seq_utilisateur start with 1 increment by 1;
create sequence seq_agenda start with 1 increment by 1;
create sequence seq_activite start with 1 increment by 1;
create sequence seq_archive_activite start with 1 increment by 1;
create sequence seq_archive_agenda start with 1 increment by 1;
