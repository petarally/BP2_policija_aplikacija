DROP DATABASE IF EXISTS policija_aplikacija;

CREATE DATABASE policija_aplikacija;
USE policija_aplikacija;

CREATE TABLE Podrucje_uprave
(
    id INT PRIMARY KEY,
    naziv VARCHAR(255) NOT NULL UNIQUE
);

ALTER TABLE Podrucje_uprave MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Mjesto
(
    id INT PRIMARY KEY,
    naziv VARCHAR(255) NOT NULL,
    id_podrucje_uprave INT,
    FOREIGN KEY (id_podrucje_uprave) REFERENCES Podrucje_uprave(id)
);

ALTER TABLE Mjesto MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Zgrada
(
    id INT PRIMARY KEY,
    adresa VARCHAR(255) NOT NULL,
    id_mjesto INT,
    vrsta_zgrade VARCHAR(30),
    FOREIGN KEY (id_mjesto) REFERENCES Mjesto(id)
);

ALTER TABLE Zgrada MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Radno_mjesto
(
    id INT PRIMARY KEY,
    vrsta VARCHAR(255) NOT NULL,
    dodatne_informacije TEXT
);

ALTER TABLE Radno_mjesto MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Odjeli
(
    id INT PRIMARY KEY,
    naziv VARCHAR(255) NOT NULL UNIQUE,
    opis TEXT
);

ALTER TABLE Odjeli MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Osoba
(
    id INT PRIMARY KEY,
    ime_prezime VARCHAR(255) NOT NULL,
    datum_rodenja DATE NOT NULL,
    oib CHAR(11) NOT NULL UNIQUE,
    spol VARCHAR(10) NOT NULL,
    adresa VARCHAR(255) NOT NULL,
    telefon VARCHAR(20) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE
);

ALTER TABLE Osoba MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Zaposlenik
(
    id INT PRIMARY KEY,
    datum_zaposlenja DATE NOT NULL,
    datum_izlaska_iz_sluzbe DATE,
    id_nadređeni INT,
    id_radno_mjesto INT,
    id_odjel INT,
    id_zgrada INT,
    id_osoba INT,
    FOREIGN KEY (id_radno_mjesto) REFERENCES Radno_mjesto(id),
    FOREIGN KEY (id_odjel) REFERENCES Odjeli(id),
    FOREIGN KEY (id_zgrada) REFERENCES Zgrada(id),
    FOREIGN KEY (id_osoba) REFERENCES Osoba(id)
);

ALTER TABLE Zaposlenik MODIFY COLUMN id INT AUTO_INCREMENT;
ALTER TABLE Zaposlenik ADD CONSTRAINT FK_Zaposlenik_Nadredeni FOREIGN KEY (id_nadređeni) REFERENCES Zaposlenik(id);


CREATE TABLE Vozilo
(
    id INT PRIMARY KEY,
    marka VARCHAR(255) NOT NULL,
    model VARCHAR(255) NOT NULL,
    registracija VARCHAR(20) UNIQUE,
    godina_proizvodnje INT NOT NULL,
    sluzbeno_vozilo BOOLEAN,
    id_vlasnik INT NOT NULL,
    FOREIGN KEY (id_vlasnik) REFERENCES Osoba(id)
);

ALTER TABLE Vozilo MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Predmet
(
    id INT PRIMARY KEY,
    naziv VARCHAR(255) NOT NULL,
    id_mjesto_pronalaska INT,
    FOREIGN KEY (id_mjesto_pronalaska) REFERENCES Mjesto(id)
);

ALTER TABLE Predmet MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Kaznjiva_djela
(
    id INT PRIMARY KEY,
    naziv VARCHAR(255) NOT NULL UNIQUE,
    opis TEXT NOT NULL,
    predvidena_kazna INT,
    predvidena_novcana_kazna DECIMAL(10,2)
);

ALTER TABLE Kaznjiva_djela MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Pas
(
    id INT PRIMARY KEY,
    id_trener INT,
    oznaka VARCHAR(255) UNIQUE,
    dob INT NOT NULL,
    status VARCHAR(255),
    id_kaznjivo_djelo INT,
    FOREIGN KEY (id_trener) REFERENCES Zaposlenik(id),
    FOREIGN KEY (id_kaznjivo_djelo) REFERENCES Kaznjiva_djela(id)
);

ALTER TABLE Pas MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Slucaj
(
    id INT PRIMARY KEY,
    naziv VARCHAR(255) NOT NULL,
    opis TEXT,
    pocetak DATETIME NOT NULL,
    zavrsetak DATETIME,
    status VARCHAR(20),
    id_pocinitelj INT,
    id_izvjestitelj INT,
    id_voditelj INT,
    id_dokaz INT,
    ukupna_vrijednost_zapljena INT DEFAULT 0,
    id_pas INT,
    id_svjedok INT,
    id_ostecenik INT,
    FOREIGN KEY (id_pocinitelj) REFERENCES Osoba(id),
    FOREIGN KEY (id_izvjestitelj) REFERENCES Osoba(id),
    FOREIGN KEY (id_voditelj) REFERENCES Zaposlenik(id),
    FOREIGN KEY (id_dokaz) REFERENCES Predmet(id),
    FOREIGN KEY (id_pas) REFERENCES Pas(id),
    FOREIGN KEY (id_svjedok) REFERENCES Osoba(id),
    FOREIGN KEY (id_ostecenik) REFERENCES Osoba(id)
);

ALTER TABLE Slucaj MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Evidencija_dogadaja
(
    id INT PRIMARY KEY,
    id_slucaj INT,
    opis_dogadaja TEXT NOT NULL,
    datum_vrijeme DATETIME NOT NULL,
    id_mjesto INT NOT NULL,
    FOREIGN KEY (id_slucaj) REFERENCES Slucaj(id),
    FOREIGN KEY (id_mjesto) REFERENCES Mjesto(id)
);

ALTER TABLE Evidencija_dogadaja MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Kaznjiva_djela_u_slucaju
(
    id INT PRIMARY KEY,
    id_mjesto INT,
    id_slucaj INT,
    id_kaznjivo_djelo INT,
    FOREIGN KEY (id_mjesto) REFERENCES Mjesto(id),
    FOREIGN KEY (id_slucaj) REFERENCES Slucaj(id),
    FOREIGN KEY (id_kaznjivo_djelo) REFERENCES Kaznjiva_djela(id)
);

ALTER TABLE Kaznjiva_djela_u_slucaju MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Izvjestaji
(
    id INT PRIMARY KEY,
    naslov VARCHAR(255) NOT NULL,
    sadrzaj TEXT NOT NULL,
    id_autor INT NOT NULL,
    id_slucaj INT NOT NULL,
    FOREIGN KEY (id_autor) REFERENCES Zaposlenik(id),
    FOREIGN KEY (id_slucaj) REFERENCES Slucaj(id)
);

ALTER TABLE Izvjestaji MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Zapljene
(
    id INT PRIMARY KEY,
    id_slucaj INT NOT NULL,
    id_predmet INT NOT NULL,
    vrijednost NUMERIC (10,2),
    FOREIGN KEY (id_slucaj) REFERENCES Slucaj(id),
    FOREIGN KEY (id_predmet) REFERENCES Predmet(id)
);

ALTER TABLE Zapljene MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Sredstvo_utvrdivanja_istine
(
    id INT PRIMARY KEY,
    naziv VARCHAR(100) NOT NULL
);

ALTER TABLE Sredstvo_utvrdivanja_istine MODIFY COLUMN id INT AUTO_INCREMENT;

CREATE TABLE Sui_slucaj
(
    id INT PRIMARY KEY,
    id_sui INT NOT NULL,
    id_slucaj INT NOT NULL,
    FOREIGN KEY (id_sui) REFERENCES Sredstvo_utvrdivanja_istine(id),
    FOREIGN KEY (id_slucaj) REFERENCES Slucaj(id)
);

ALTER TABLE Sui_slucaj MODIFY COLUMN id INT AUTO_INCREMENT;