/*
1. Prosječan broj godina osoba koje su prijavile digitalno nasilje
*/
SELECT AVG(YEAR(S.pocetak) - YEAR(O.datum_rodenja)) AS prosjecan_broj_godina
	FROM Slucaj S
	INNER JOIN Osoba O ON S.id_izvjestitelj = O.id
	WHERE S.naziv LIKE '%Digitalno nasilje%';


/*
2. Osoba čiji je nestanak posljednji prijavljen
*/
SELECT O.*
	FROM Osoba O
	INNER JOIN Slucaj S ON O.id = S.id_ostecenik
	WHERE S.naziv LIKE '%Nestanak%'
	ORDER BY S.pocetak DESC
	LIMIT 1;


/*
3. Najčešća vrsta kažnjivog djela
*/
SELECT KD.*
	FROM Kaznjiva_djela KD
	INNER JOIN Kaznjiva_djela_u_slucaju KDS ON KDS.id_kaznjivo_djelo = KD.id
	GROUP BY KD.id
	ORDER BY COUNT(*)
	LIMIT 1;


/*
4. Svi voditelji slučajeva i slučajeve koje vode
*/
SELECT O.ime_prezime, S.naziv AS naziv_slucaja
	FROM Zaposlenik Z
	JOIN Osoba O ON Z.id_osoba = O.id
	JOIN Slucaj S ON Z.id = S.id_voditelj;


/*
5. Slučajeve i evidencije za određenu osobu (osumnjičenika)
*/
SELECT O.ime_prezime, S.naziv AS naziv_slucaja, ED.opis_dogadaja, ED.datum_vrijeme, ED.id_mjesto
	FROM Slucaj S
	JOIN Evidencija_dogadaja ED ON S.id = ED.id_slucaj
	JOIN Osoba O ON O.id = S.id_pocinitelj
	WHERE O.ime_prezime = 'Ime Prezime';


/*
6. Sve osobe koje su osumnjičene za određeno kažnjivo djelo
*/
SELECT DISTINCT O.ime_prezime
	FROM Osoba O
	JOIN Slucaj S ON O.id = S.id_pocinitelj
	JOIN Kaznjiva_djela_u_slucaju KDS ON S.id = KDS.id_slucaj
	JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo = KD.id
	WHERE KD.naziv = 'Naziv kažnjivog djela';


/*
7. Svi slučajevi koji sadrže kažnjivo djelo i nisu riješeni
*/
SELECT S.naziv, KD.naziv AS kaznjivo_djelo
	FROM Slucaj S
	INNER JOIN Kaznjiva_djela_u_slucaju KDS ON S.id = KDS.id_slucaj
	INNER JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo= KD.id
	WHERE S.status = 'Aktivan';


/*
8. Iznos zapljene za svaki slučaj
*/
SELECT S.id, S.naziv, SUM(ZA.vrijednost) AS ukupna_vrijednost_zapljena
	FROM Slucaj S
	LEFT JOIN Zapljene ZA ON S.id = ZA.id_slucaj
	GROUP BY S.id, S.naziv;


/*
9. Prosječne vrijednosti zapljena kažnjivih djela
*/
SELECT KD.naziv AS vrsta_kaznjivog_djela, AVG(ZA.vrijednost) AS prosjecna_vrijednost_zapljene
	FROM Kaznjiva_djela_u_slucaju KDS
	JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo= KD.id
	JOIN Zapljene ZA ON KDS.id_slucaj = ZA.id_slucaj
	GROUP BY KD.naziv;


/*
10. Svi odjele i broj zaposlenika na njima
*/
SELECT O.naziv AS naziv_odjela, COUNT(Z.id) AS broj_zaposlenika
	FROM Zaposlenik Z
	JOIN Odjeli O ON Z.id_odjel = O.id
	GROUP BY O.id, O.naziv;


/*
11. Ukupna vrijednost zapljena po odjelu, sortirano po vrijednosti silazno
*/
SELECT Z.id_odjel, SUM(ZA.vrijednost) AS ukupna_vrijednost_zapljena
	FROM Slucaj S
	JOIN Zapljene ZA ON S.id = ZA.id_slucaj
	JOIN Zaposlenik Z ON S.id_voditelj= Z.id
	GROUP BY Z.id_odjel
	ORDER BY ukupna_vrijednost_zapljena DESC;


/*
12. Osoba koja mora odslužiti najveću ukupnu zatvorsku kaznu
*/
SELECT O.id, O.ime_prezime, SUM(KD.predvidena_kazna) AS ukupna_kazna
	FROM Osoba O
	INNER JOIN Slucaj S ON O.id = S.id_pocinitelj
	INNER JOIN Kaznjiva_djela_u_slucaju KDS ON S.id = KDS.id_slucaj
	INNER JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo= KD.id
	WHERE KD.predvidena_kazna IS NOT NULL
	GROUP BY O.id, O.ime_prezime
	ORDER BY ukupna_kazna DESC
	LIMIT 1;


/*
13. Sva vozila i u koliko slučajeva su se oni upisali
*/
SELECT V.*, COUNT(S.id) AS broj_slucajeva
	FROM Vozilo V
	LEFT OUTER JOIN Osoba O ON V.id_vlasnik = O.id
	INNER JOIN Slucaj S ON O.id = S.id_pocinitelj
	GROUP BY V.id;


/*
14. i 15.
*/
-- Mjesto s najviše slučajeva
SELECT M.*, COUNT(ED.id) AS broj_slucajeva
FROM Mjesto M
INNER JOIN Evidencija_dogadaja ED ON M.id = ED.id_mjesto
GROUP BY M.id
ORDER BY broj_slucajeva DESC
LIMIT 1;


-- Mjesto s najmanje slučajeva
SELECT M.*, COUNT(ED.id) AS broj_slucajeva
FROM Mjesto M
INNER JOIN Evidencija_dogadaja ED ON M.id = ED.id_mjesto
GROUP BY M.id
ORDER BY broj_slucajeva ASC
LIMIT 1;



/*
16.
Policijski službenik koji je vodio najviše slučajeva
*/
SELECT Z.id AS id_zaposlenika, O.ime_prezime AS ime_prezime_zaposlenika, COUNT(S.id) AS broj_slucajeva
	FROM Zaposlenik Z
	JOIN Osoba O ON Z.id_osoba= O.id
	LEFT JOIN Slucaj S ON S.id_voditelj = Z.id
	GROUP BY Z.id, o.ime_prezime
	HAVING COUNT(S.id) =
(SELECT MAX(broj_slucajeva)
	FROM (
SELECT COUNT(id) AS broj_slucajeva
	FROM Slucaj 
	GROUP BY id_voditelj
) AS max_voditelj);


/*
17.
Sva mjesta gdje nema evidentiranih kažnjivih djela u slučajevima ili uopće nema slučajeva
*/
SELECT M.id, M.naziv
	FROM Mjesto M
	LEFT JOIN Evidencija_dogadaja ED ON M.id = ED.id_mjesto
	LEFT JOIN Slucaj S ON ED.id_slucaj= S.id
	LEFT JOIN Kaznjiva_djela_u_slucaju KDS ON S.id = KDS.id_slucaj
	WHERE KDS.id_slucaj IS NULL OR KDS.id_kaznjivo_djelo IS NULL
	GROUP BY M.id, M.naziv;