/*
1. Naziv kažnjivog djela, predviđena kazna i broj pojavljivanja u slučajevima
*/
DELIMITER
//
CREATE FUNCTION kaznjivo_djelo_info(naziv_kaznjivog_djela VARCHAR(255)) RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE predvidena_kazna INT;
DECLARE broj_pojavljivanja INT;

SELECT predvidena_kazna
INTO predvidena_kazna
FROM Kaznjiva_djela
WHERE naziv = naziv_kaznjivog_djela;

SELECT COUNT(*)
INTO broj_pojavljivanja
FROM Kaznjiva_djela_u_slucaju
WHERE id_kaznjivo_djelo = naziv_kaznjivog_djela;

RETURN CONCAT('Naziv kaznjivog djela: ', naziv_kaznjivog_djela, ', Predvidena kazna: ', predvidena_kazna, ', Broj pojavljivanja: ', broj_pojavljivanja);
END
//
DELIMITER ;

-- Sva kažnjiva djela koja su se dogodila u 2023. godini (ili nekoj drugoj) i njihov broj pojavljivanja
SELECT kaznjivo_djelo_info(KD.naziv) AS kaznjivo_djelo_upit, COUNT(KDS.id_kaznjivo_djelo) AS BrojPojavljivanja
FROM Kaznjiva_djela_u_slucaju KDS
    INNER JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo = KD.id
    INNER JOIN Slucaj S ON KDS.id_slucaj = S.id
WHERE YEAR(S.pocetak) = 2023
GROUP BY KD.naziv;


/*
2. Informacije o osobi prema broju telefona
*/
DELIMITER //
CREATE FUNCTION informacije_o_osobi_po_telefonu(broj_telefona VARCHAR(20)) RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE osoba_info TEXT;

SELECT CONCAT('Ime i prezime: ', ime_prezime, '\nDatum rođenja: ', datum_rodenja, '\nAdresa: ', adresa, '\nEmail: ', email)
INTO osoba_info
FROM Osoba
WHERE telefon = broj_telefona;

IF osoba_info IS NOT NULL THEN
RETURN osoba_info;
ELSE
RETURN 'Osoba s navedenim brojem telefona nije pronađena.';
END
IF;
END //
DELIMITER ;

-- Svi brojevi telefona i informacije o tim osobama, ali samo ako te osobe nisu policijski službenici
SELECT telefon, informacije_o_osobi_po_telefonu(telefon) AS osoba_info_telefon
FROM Osoba O
WHERE O.id NOT IN
(SELECT id_osoba
FROM Zaposlenik);

#
SET SQL_safe_updates
= 0; ?????


/*
3. Slučaj u kojem je određeni predmet dokaz i osoba koja je u tom slučaju osumnjičena
*/
DELIMITER //
CREATE FUNCTION dohvati_slucaj_i_osobu(id_predmet INT) RETURNS VARCHAR
(512)
DETERMINISTIC
BEGIN
    DECLARE slucaj_naziv VARCHAR
    (255);
DECLARE osoba_ime_prezime VARCHAR
(255);
DECLARE rezultat VARCHAR
(512);

SELECT S.naziv
INTO slucaj_naziv
FROM Slucaj S
WHERE S.id_dokaz = id_predmet;

SELECT O.ime_prezime
INTO osoba_ime_prezime
FROM Osoba O
    INNER JOIN Slucaj S ON O.id = S.id_pocinitelj
WHERE S.id_dokaz = id_predmet;

SET rezultat
= CONCAT
('Odabrani je predmet dokaz u slučaju: ', slucaj_naziv, ', gdje je osumnjičena osoba: ', osoba_ime_prezime);

RETURN rezultat;
END //
DELIMITER ;

-- Informacije o određenom predmetu, uključujući naziv predmeta, naziv povezanog slučaja te ime i prezime osumnjičenika u tom slučaju
SELECT P.id AS predmet_id, P.naziv AS naziv_predmeta, S.naziv AS naziv_slucaja,
    O.ime_prezime AS ime_prezime_osumnjicenika, dohvati_slucaj_i_osobu(P.id) AS informacije_o_predmetu
FROM Predmet P
    INNER JOIN Slucaj S ON P.id = S.id_dokaz
    INNER JOIN Osoba O ON S.id_pocinitelj = O.id
WHERE P.id = 5;


/*
4. U koliko je slučajeva određeno sredstvo utvrđivanja istine korišteno
Dodatno, koliko je slučajeva od tog broja riješeno te će na temelju ta 2 podatka izračunati postotak riješenosti slučajeva gdje se odabrano sredstvo koristi
*/
DELIMITER //
CREATE FUNCTION izracunaj_postotak_rijesenosti(sredstvo_id INT) RETURNS DECIMAL
(5, 2)
DETERMINISTIC
BEGIN
    DECLARE ukupno INT;
DECLARE koristeno INT;
DECLARE postotak DECIMAL
(5,2);

SELECT COUNT(*)
INTO ukupno
FROM Sui_slucaj
WHERE id_sui = sredstvo_id;

SELECT COUNT(*)
INTO koristeno
FROM Sui_slucaj SS
    INNER JOIN Slucaj S ON SS.id_slucaj = S.id
WHERE SS.id_sui = sredstvo_id AND S.status = 'Riješen';

IF ukupno IS NOT NULL AND ukupno > 0 THEN
SET postotak
=
(koristeno / ukupno) * 100;
	ELSE
SET postotak
= 0.00;
END
IF;

	RETURN postotak;
END //
DELIMITER ;

-- Sredstva koja imaju riješenost veću od 50% (riješeno je više od 50% slučajeva koji koriste to sredstvo)
SELECT SUI.id AS id_sredstvo, SUI.naziv AS naziv_sredstva,
    izracunaj_postotak_rijesenosti(SUI.id) AS postotak
FROM Sredstvo_utvrdivanja_istine SUI
WHERE izracunaj_postotak_rijesenosti(SUI.id) > 50.00;


/*
5. Informacija za traženo vozilo je li se pojavilo u nekom od slučajeva
Provjerava je li se id_osoba, koji referencira vlasnika, pojavila u nekom slučaju kao pocinitelj_id
Ako se pojavio, vraćat će 'Vozilo se pojavljivalo u slučajevima, a ako se nije pojavilo, vraćat će 'Vozilo se nije pojavljivalo u slučajevima'
Također, funkcija vraća i broj koliko se puta vozilo pojavilo
*/
DELIMITER //
CREATE FUNCTION provjera_vozila(registracija VARCHAR(20)) RETURNS VARCHAR
(100)
DETERMINISTIC
BEGIN
    DECLARE rezultat VARCHAR
    (100);
DECLARE count INT;

SELECT COUNT(*)
INTO count
FROM Slucaj
WHERE id_pocinitelj IN
	(SELECT id_vlasnik
FROM Vozilo
WHERE registracija = registracija);

IF count > 0 THEN
SET rezultat
= CONCAT
('Vozilo se pojavljivalo u slučajevima (', count, ' puta)'); 
	ELSE
SET rezultat
= 'Vozilo se nije pojavljivalo u slučajevima';
END
IF;

	RETURN rezultat;
END //
DELIMITER ;

-- Vozila koja se pojavljuju iznad prosjeka 
CREATE TEMPORARY TABLE prosjek_pojavljivanja AS
SELECT AVG(count) AS prosjek
FROM
    (SELECT COUNT(*) AS count
    FROM Slucaj S
        INNER JOIN Vozilo V ON S.id_pocinitelj = V.id_vlasnik
    GROUP BY V.registracija) AS podupit_1;

SELECT V.registracija, provjera_vozila(V.registracija) AS status_vozila
FROM Vozilo V
    INNER JOIN
    (SELECT V.Registracija, COUNT(*) AS count
    FROM Slucaj S
        INNER JOIN Vozilo V ON S.id_pocinitelj = V.id_vlasnik
    GROUP BY V.registracija) AS podupit_2 ON V.registracija = podupit_2.registracija
WHERE podupit_2 .count >
(SELECT prosjek
FROM prosjek_pojavljivanja);


/*
6. Broj mjesta nekog području i naziv svih mjesta u 1 stringu
*/
DELIMITER //
CREATE FUNCTION podaci_o_podrucju(id_podrucje INT) RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE broj_mjesta INT;
DECLARE mjesta TEXT;

SELECT COUNT(*)
INTO broj_mjesta
FROM Mjesto
WHERE id_podrucje_uprave = id_podrucje;

SELECT GROUP_CONCAT(naziv SEPARATOR ';'
) INTO mjesta
		FROM Mjesto
		WHERE id_podrucje_uprave = id_podrucje;

RETURN CONCAT('Područje: ', (SELECT naziv
FROM Podrucje_uprave
WHERE id = id_podrucje), 
		', Broj mjesta: ', broj_mjesta, ', Mjesta: ', mjesta);
END //
DELIMITER ;


/*
7. Broj kažnjivih djela u slučaju
*/
DELIMITER //
CREATE FUNCTION broj_kaznjivih_djela_u_slucaju(id_slucaj INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE broj_kaznjivih_djela INT;

SELECT COUNT(*)
INTO broj_kaznjivih_djela
FROM Kaznjiva_djela_u_slucaju
WHERE id_slucaj = id_slucaj;

RETURN broj_kaznjivih_djela;
END //
DELIMITER ;

-- Slučaj s najviše kažnjivih djela
SELECT S.id AS id_slucaj, S.naziv AS naziv_slucaja,
    MAX(broj_kaznjivih_djela_u_slucaju(S.id)) AS broj_kaznjivih_djela
FROM Slucaj S
GROUP BY id_slucaj, naziv_slucaja;


/*
8. Broj slučajeva prema nekom statusu slučaja
*/
DELIMITER //
CREATE FUNCTION broj_slucajeva_po_statusu(status VARCHAR(20)) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE broj_slucajeva INT;

IF status IS NULL THEN
SET broj_slucajeva
= 0;
	ELSE
SELECT COUNT(*)
INTO broj_slucajeva
FROM Slucaj
WHERE status = status;
END
IF;

	RETURN broj_slucajeva;
END //
DELIMITER ;

-- Svi statusi koji vrijede za više od 5 slučajeva (ili neki drugi broj)
SELECT status, COUNT(*) AS broj_slucajeva
FROM Slucaj
GROUP BY status
HAVING broj_slucajeva_po_statusu(status) > 5;


/*
9. Trajanje slučaja
Ako je završen, onda trajanje od početka do završetka, a ako nije, trajanje od početka do poziva funkcije
*/
DELIMITER //
CREATE FUNCTION informacije_o_slucaju(id_slucaj INT) RETURNS TEXT
DETERMINISTIC
BEGIN
    DECLARE status_slucaja VARCHAR
    (20);
DECLARE trajanje_slucaja INT;

SELECT status,
    CASE
		WHEN zavrsetak IS NULL THEN DATEDIFF(NOW(), pocetak)
		ELSE DATEDIFF(zavrsetak, pocetak)
	END AS trajanje
INTO status_slucaja
, trajanje_slucaja
		FROM Slucaj
		WHERE id = id_slucaj;

RETURN CONCAT('Status slučaja: ', status_slucaja, '\nTrajanje slučaja: ', trajanje_slucaja, ' dana');
END //
DELIMITER ;

-- Svi slučajevi te njihov status i trajanje
SELECT dd AS sluca_id, naziv AS naziv_slucaja, informacije_o_slucaju(id) AS info_slucaj
FROM Slucaj;


/*
10. Broj slučajeva na kojima je određeni zaposlenik bio voditelj i postotak riješenosti tih slučajeva
Na temelju toga, je li zaposlenik neuspiješan (od 0 do 49 %) ili uspješan (od 50 do 100 %)
*/
DELIMITER //
CREATE FUNCTION zaposlenik_slucaj(p_id_zaposlenik INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE l_broj INT;
DECLARE l_broj_rijeseni INT;
DECLARE l_postotak DECIMAL
(5, 2);

SELECT COUNT(*)
INTO l_broj
FROM Slucaj
WHERE id_voditelj = p_id_zaposlenik;

SELECT COUNT(*)
INTO l_broj_rijeseni
FROM Slucaj
WHERE id_voditelj = p_id_zaposlenik AND status = 'Riješen';

SET l_postotak
=
(l_broj_rijeseni / l_broj) * 100;

IF l_postotak <= 49
		THEN
RETURN "Neuspješan";
ELSE
RETURN "Uspješan";
END
IF;
END//
DELIMITER ;

-- Rezultat uspješnosti za svakog zaposlenika
SELECT Z.id AS zaposlenik_id, Z.ime_prezime AS ime_zaposlenika,
    CASE
	WHEN (SELECT COUNT(*)
    FROM Slucaj
    WHERE id_voditelj = Z.id) > 0
		THEN zaposlenik_slucaj(Z.id)
		ELSE 'Zaposlenik nije vodio slučajeve'
	END AS 'Uspješnost'
FROM Zaposlenik Z;


/*
11. 'Da' ako je osoba barem jednom bila oštećenik u nekom slučaju, a u protivnom 'Ne'
*/
DELIMITER //
CREATE FUNCTION osoba_ostecenik(p_id_osoba INT) RETURNS CHAR
(2)
DETERMINISTIC
BEGIN
    DECLARE l_broj INT;

SELECT COUNT(*)
INTO l_broj
FROM Slucaj
WHERE id_ostecenik = p_id_osoba;

IF l_broj > 0
		THEN
RETURN 'Da';
ELSE
RETURN 'Ne';
END
IF;
END //
DELIMITER ;

-- Sve osobe koje su oštećene više od 3 puta
SELECT O.id AS osoba_id, O.ime_prezime AS ime_prezime_osobe
FROM Osoba O
WHERE osoba_ostecenik(O.id) = 'Da'
GROUP BY O.id, O.ime_prezime
HAVING COUNT(*) > 3;


/*
12. 
*/

-- Sve osobe i njihove uloge u slučajevima
SELECT id, ime_prezime, ologe_osobe_u_slucajevima(id) AS uloge
FROM Osoba;


/*
13. Je li osoba sumnjiva ili nije 
*/
DELIMITER
CREATE FUNCTION sumnjivost_osobe(osoba_id INT) RETURNS VARCHAR
(50)
DETERMINISTIC //
BEGIN
    DECLARE broj_slucajeva INT;
DECLARE sumnjivost VARCHAR
(50);

SELECT COUNT(*)
INTO broj_slucajeva
FROM Slucaj
WHERE id_okrivljenik = osoba_id;

IF broj_slucajeva > 10 THEN
SET sumnjivost
= 'Jako sumnjiva';
	ELSEIF broj_slucajeva > 0 THEN
SET sumnjivost
= 'Umjereno sumnjiva';
	ELSE
SET sumnjivost
= 'Nije sumnjiva';
END
IF;

	RETURN sumnjivost;
END //
DELIMITER ;

-- Sve osobe, pa i policajci te podaci o njihovoj sumnjivosti
SELECT id, ime_prezime, sumnjivost_osobe(id) AS sumnjivost
FROM Osoba;


/*
14. Broj zaposlenih na nekom odjelu u zadnjih 6 mjeseci
*/
DELIMITER //
CREATE FUNCTION broj_zaposlenih(odjel_id INT) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE broj_zaposlenih INT;

SELECT COUNT(*)
INTO broj_zaposlenih
FROM Zaposlenik
WHERE id_odjel = odjel_id AND datum_zaposlenja >= CURDATE() - INTERVAL
6 MONTH;

RETURN broj_zaposlenih;
END //
DELIMITER ;

-- Id i naziv odjela koji je imao najveći broj zaposlenih u zadnjih 6 mjeseci
SELECT id, naziv, broj_zaposlenih(id) AS zaposleni_broj
FROM odjeli
ORDER BY zaposleni_broj DESC
	LIMIT 1;


/*
15. Broj zaposlenih i broj slučajeva na nekom odjelu 
Dodatno, koliko prosječno ima slučajeva po osobi na tom odjelu
*/
DELIMITER
//
CREATE FUNCTION avg_slucaj_osoba_odjel(odjel_id INT) RETURNS DECIMAL
(10, 2)
DETERMINISTIC
BEGIN
    DECLARE broj_zaposlenih INT;
DECLARE broj_slucajeva INT;
DECLARE prosječan_broj_slucajeva DECIMAL
(10, 2);

SELECT COUNT(*)
INTO broj_zaposlenih
FROM Zaposlenik
WHERE id_odjel = odjel_id;

SELECT COUNT(*)
INTO broj_slucajeva
FROM Slucaj
WHERE id_voditelj IN
	(SELECT id_osoba
FROM Zaposlenik
WHERE id_odjel = odjel_id);

IF broj_zaposlenih > 0 THEN
SET prosječan_broj_slucajeva
= broj_slucajeva / broj_zaposlenih;
	ELSE
SET prosjecan_broj_slučajeva
= 0;
END
IF;
	RETURN prosjecan_broj_slučajeva;
END //
DELIMITER ;

-- Odjel s ispod prosječnim brojem slučajeva po osobi
SELECT naziv AS nazivi_ispodprosječnih_odjela
FROM Odjeli
WHERE avg_slucaj_osoba_odjel(id) < 
(SELECT AVG(avg_slucaj_osoba_odjel(id))
FROM Odjeli);

-- Odjel s iznad prosječnim brojem slučajeva po osobi
SELECT id, naziv
FROM Odjeli
WHERE avg_slucaj_osoba_odjel(id) >
(SELECT AVG(avg_slucaj_osoba_odjel(id))
FROM Odjeli);