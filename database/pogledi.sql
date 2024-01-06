/*
1. Ako je uz osumnjičenika povezano vozilo, stvara se materijalizirani pogled koji prati sve osumnjičenike i njihova vozila
*/
CREATE VIEW osumnjicenici_vozila
AS
    SELECT O.id AS id_osobe, O.ime_prezime, O.datum_rodenja, O.oib, O.spol, O.adresa, O.telefon, O.email,
        V.id AS id_vozila, V.marka, V.model, V.registracija, V.godina_proizvodnje
    FROM Osoba O
        LEFT JOIN Vozilo V ON O.id = V.id_vlasnik
        INNER JOIN Slucaj S ON O.id = S.id_pocinitelj;


/*
2. Svi policajci koji su vlasnici vozila koja su starija od 10 godina
*/
CREATE VIEW policijski_sluzbenici_stara_vozilima
AS
    SELECT O.ime_prezime AS Policajac, V.marka, V.model, V.godina_proizvodnje
    FROM Osoba O
        JOIN Zaposlenik Z ON O.id = Z.id_osoba
        JOIN Vozilo V ON O.id = V.id_vlasnik
    WHERE Z.id_radno_mjesto =
(SELECT id
        FROM radno_mjesto
        WHERE vrsta = 'Policajac') AND V.godina_proizvodnje <= YEAR(NOW()) - 10;


/*
3. Sve osobe koje su počinile kažnjivo djelo pljačke, a da su pri tome su koristili pištolj (to dohvati pomoću tablice Predmet) 
*/
CREATE VIEW počinitelji_oružane_pljacke
AS
    SELECT O.ime_prezime AS pocinitelj, KD.naziv AS kazneno_djelo
    FROM Osoba O
        JOIN Slucaj S ON O.id = S.id_pocinitelj
        JOIN Kaznjiva_Djela_u_Slucaju KDS ON S.id = KDS.id_slucaj
        JOIN Kaznjiva_Djela KD ON KDS.id_kaznjivo_djelo = KD.id
        JOIN Predmet P ON S.id_dokaz = P.id
    WHERE KD.naziv = 'Pljačka' AND P.naziv LIKE '%Pištolj%';



/*
4. Sva evidentirana kažnjiva djela i njihov postotak pojavljivanja u slučajevima
*/
CREATE VIEW postotak_pojavljivanja_kaznjivih_djela
AS
    SELECT KD.naziv AS kaznjivo_djelo, COUNT(KDS.id_slucaj) AS broj_slucajeva,
        COUNT(KDS.id_slucaj) / (SELECT COUNT(*)
        FROM Slucaj) * 100 AS postotak_pojavljivanja
    FROM Kaznjiva_djela KD
        LEFT JOIN Kaznjiva_djela_u_slucaju KDS ON KD.id = KDS.id_kaznjivo_djelo
    GROUP BY KD.naziv;


/*
5. Sva evidentirana sredstva utvrđivanja istine i broj slučajeva u kojima je svako od njih korišteno
*/
CREATE VIEW evidentirana_sredstva_utvrdivanja_istine
AS
    SELECT SUI.naziv AS sredstvo_utvrdivanja_istine, COUNT(SS.id_sui) AS broj_slucajeva
    FROM Sredstvo_utvrdivanja_istine SUI
        LEFT JOIN Sui_slucaj SS ON SUI.id = SS.id_sui
    GROUP BY SUI.id;


/*
6. Svi slučajevi i sredstva utvrđivanja istine u njima, te trajanje svakog od slučajeva
*/
CREATE VIEW slucajevi_sortirani_po_trajanju_sredstva
AS
    SELECT S.*, TIMESTAMPDIFF(DAY, S.pocetak, S.zavrsetak) AS trajanje_u_danima,
        GROUP_CONCAT(SUI.naziv
    ORDER BY SUI.naziv ASC SEPARATOR ', ') AS sredstva_utvrdivanja_istine
FROM Slucaj S
	LEFT JOIN Sui_slucaj SS ON S.id = SS.id_slucaj
	LEFT JOIN Sredstvo_utvrdivanja_istine SUI ON SS.id_sui = SUI.id
	GROUP BY S.id
	ORDER BY trajanje_u_danima DESC;


/*
7. Svi izvještaji vezane uz pojedine slučajeve
*/
CREATE VIEW izvjestaji_za_slucajeve
AS
    SELECT S.naziv AS slucaj, I.naslov AS naslov_izvjestaja, I.sadrzaj AS sadrzaj_izvjestaja,
        O.ime_prezime AS autor_izvjestaja
    FROM Izvjestaji I
        INNER JOIN Slucaj S ON I.id_slucaj = S.id
        INNER JOIN Osoba O ON I.id_autor = O.id;


/*
8. Sve osobe i njihovu odjeli
Ukoliko osoba nije policajac i nema odjel (odjel je NULL), neka se uz tu osobu napiše 'Osoba nije policijski službenik'
*/
CREATE VIEW osobe_odjeli
AS
    SELECT O.ime_prezime AS ime_osobe,
        CASE
	WHEN Z.id_radno_mjesto IS NOT NULL THEN OD.naziv
	ELSE 'Osoba nije policijski službenik'
END AS naziv_odjela
    FROM Osoba O
        LEFT JOIN Zaposlenik Z ON O.id = Z.id_osoba
        LEFT JOIN Odjeli OD ON Z.id_odjel= OD.id;


/*
9. Svi voditelji slučajeva, ukupan broj slučajeva koje vode, ukupan broj riješenih slučajeva, ukupan broj neriješenih slučajeva i postotak riješenosti
*/
CREATE VIEW voditelji_slucajevi_pregled
AS
    SELECT
        O.ime_prezime AS voditelj,
        COUNT(S.id) AS ukupan_broj_slucajeva,
        SUM(CASE WHEN S.status = 'Završeno' THEN 1 ELSE 0 END) AS ukupan_broj_rijesenih_slucajeva,
        SUM(CASE WHEN S.status = 'Aktivan' THEN 1 ELSE 0 END) AS ukupan_broj_nerijesenih_slucajeva,
        (SUM(CASE WHEN S.status = 'Završeno' THEN 1 ELSE 0 END) / COUNT(S.id)) * 100 AS postotak_rjesenosti
    FROM
        Osoba O
        LEFT JOIN
        Slucaj S ON O.id = S.id_voditelj
    GROUP BY
    voditelj;



/*
10. Statistika zapljena za svaku vrstu kažnjivog djela (prosjek, minimum, maksimum (za vrijednosti) i broj predmeta)
*/
CREATE VIEW statistika_zapljena_po_kaznjivom_djelu
AS
    SELECT
        Kaznjiva_djela.naziv AS vrsta_kaznjivog_djela,
        AVG(Zapljene.vrijednost) AS prosjecna_vrijednost_zapljena,
        MAX(Zapljene.vrijednost) AS najveca_vrijednost_zapljena,
        MIN(Zapljene.vrijednost) AS najmanja_vrijednost_zapljena,
        COUNT(Zapljene.id) AS broj_zapljenjenih_predmeta
    FROM
        Zapljene
        JOIN
        Slucaj ON Zapljene.id_slucaj = Slucaj.id
        JOIN
        Kaznjiva_djela_u_slucaju ON Slucaj.id = Kaznjiva_djela_u_slucaju.id_slucaj
        JOIN
        Kaznjiva_djela ON Kaznjiva_djela_u_slucaju.id_kaznjivo_djelo = Kaznjiva_djela.id
    GROUP BY
    Kaznjiva_djela.naziv;



/*
11. Ukupna zatvorska kazna za svaki slučaj
Uz ograničenje da maksimalna zakonska zatvorska kazna u RH iznosi 50 godina
Ako ukupna kazna premaši 50, postaviti će se na 50 uz odgovarajuće upozorenje
*/
CREATE VIEW ukupna_predvidena_kazna_po_slucaju
AS
    SELECT S.id AS slucaj_id, S.naziv AS naziv_slucaja,
        CASE
	WHEN SUM(KD.predvidena_kazna) > 50 THEN 50
	ELSE SUM(KD.predvidena_kazna)
END AS ukupna_predvidena_kazna,
        CASE
	WHEN SUM(KD.predvidena_kazna) > 50 THEN 'Maksimalna zakonska zatvorska kazna iznosi 50 godina'
	ELSE NULL
END AS napomena
    FROM Slucaj S
        LEFT JOIN Kaznjiva_djela_u_slucaju KDS ON S.id = KDS.id_slucaj
        LEFT JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo = KD.id
    GROUP BY S.id, S.naziv;


/*
12. Dob i godine staža za sve policijske službenike
Ukoliko je još aktivan, oduzimat ćemo od trenutne godine godinu zaposlenja, a ako je umirovljen, oduzimat će od godine umirovljenja godinu zaposlenja
Dodatno, stupac koji prati da li je umirovljen ili aktivan
*/
CREATE VIEW pogled_policijskih_suzbenika
AS
    SELECT O.id AS zaposlenik_id, O.ime_prezime AS ime_prezime_osobe, O.datum_rodenja AS datum_rodenja_osobe,
        DATEDIFF(CURRENT_DATE, Z.datum_zaposlenja) AS godine_staza,
        CASE
	WHEN Z.datum_izlaska_iz_sluzbe IS NOT NULL AND Z.datum_izlaska_iz_sluzbe <= CURRENT_DATE THEN 'Da'
        ELSE 'Ne'
END AS umirovljen
    FROM Osoba O
        INNER JOIN Zaposlenik Z ON O.id = Z.id_osoba;


/*
13. Svi osumnjičenici i kažnjiva djelima za koja su osumnjičeni
*/
CREATE VIEW pogled_osumnjicene_osobe
AS
    SELECT DISTINCT
        Osoba.ime_prezime,
        Kaznjiva_djela.naziv AS naziv_kaznjivog_djela
    FROM
        Osoba
        JOIN
        Slucaj ON Osoba.id = Slucaj.id_pocinitelj
        JOIN
        Kaznjiva_djela_u_slucaju ON Slucaj.Id = Kaznjiva_djela_u_slucaju.id_slucaj
        JOIN
        Kaznjiva_djela ON Kaznjiva_djela_u_slucaju.id_kaznjivo_djelo = Kaznjiva_djela.id;



/*
14. Svi psi i broj slučajeva na kojima je svaki od njih radio
Dodatno u posebnim stupcima, broj riješenih slučajeva od onih na kojima su radili i postotak riješenosti slučajeva za svakog psa
*/
CREATE VIEW pregled_pasa
AS
    SELECT PA.Id AS pas_id, PA.oznaka AS oznaka_psa, O.ime_prezime AS vlasnik,
        COUNT(S.id) AS broj_slucajeva,
        SUM(CASE WHEN S.status = 'Završeno' THEN 1 ELSE 0 END) AS broj_rijesenih,
        (SUM(CASE WHEN S.status = 'Završeno' THEN 1 ELSE 0 END) / COUNT(S.id) * 100) AS postotak_rijesenosti
    FROM Pas PA
        LEFT JOIN Slucaj S ON PA.id = S.id_pas
        LEFT JOIN Osoba O ON PA.id_trener = O.id
    GROUP BY PA.id;

-- Nadogradnja prethodnog pogleda tako da pronalazi najefikasnijeg psa, s najvećim postotkom riješenosti
CREATE VIEW najefikasniji_pas
AS
    SELECT pas_id, oznaka_psa, vlasnik, broj_slucajeva, broj_rijesenih, postotak_rijesenosti
    FROM pregled_pasa
    WHERE postotak_rijesenosti = (SELECT MAX(postotak_rijesenosti)
    FROM pregled_pasa);


/*
15. Broj kazni zbog brze vožnje u svakom gradu u proteklih mjesec dana
*/
CREATE VIEW brza_voznja_gradovi
AS
    SELECT M.naziv, COUNT(*) AS broj_kazni_za_brzu_voznju
    FROM Mjesto M
        INNER JOIN Evidencija_dogadaja ED ON M.id = ED.id_mjesto
        INNER JOIN Slucaj S ON ED.id_slucaj = S.id
    WHERE S.naziv LIKE '%Brza voznja%' AND ED.datum_vrijeme >= (NOW()-INTERVAL
1 MONTH)
	GROUP BY M.naziv;

-- Grad u kojem je bilo najviše kazni zbog brze vožnje u proteklih mjesec dana
SELECT *
FROM brza_voznja_gradovi
ORDER BY broj_kazni_za_brzu_voznju DESC
	LIMIT 1; 


/*
16. Sve osobe koje su skrivile više od 2 prometne nesreće u posljednjih godinu dana
*/
CREATE VIEW osoba_prometna_nesreca
AS
SELECT
    O.*,
    COUNT(*) AS broj_prometnih_nesreca
FROM
    Osoba O
    INNER JOIN
    Slucaj S ON O.id = S.id_pocinitelj
    INNER JOIN
    Evidencija_dogadaja ED ON S.id = ED.id_slucaj
WHERE
    ED.datum_vrijeme <= (NOW() - INTERVAL
1 YEAR)
    AND S.naziv LIKE '%Prometna nesreća%'
GROUP BY
    O.id
HAVING
    broj_prometnih_nesreca > 2;




-- Osoba koja je skrivila najviše prometnih nesreća u posljednjih godinu dana
SELECT *
FROM osoba_prometna_nesreca
ORDER BY broj_prometnih_nesreca DESC
	LIMIT 1;


/*
17. Sva kažnjiva djela koja su se događala u slučajevima
*/
CREATE VIEW kaznjiva_djela_na_mjestu
AS
SELECT KD.naziv, KD.opis, ED.id_mjesto
FROM Kaznjiva_djela_u_slucaju KDS
    JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo = KD.id
    JOIN Evidencija_dogadaja ED ON KDS.id_slucaj = ED.id_slucaj;

-- Kažnjiva djela za određeno mjesto prema id-u
SELECT *
FROM kaznjiva_djela_na_mjestu
WHERE id_mjesto = 1
LIMIT 0, 500;




/*
18. Sve osobe, slučajeve koje su počinili i kažnjiva djela u njima
*/
CREATE VIEW osobe_kaznjiva_djela
AS
    SELECT DISTINCT O.ime_prezime
    FROM Osoba O
        JOIN Slucaj S ON O.id = S.id_pocinitelj
        JOIN Kaznjiva_djela_u_slucaju KDS ON S.id = KDS.id_slucaj
        JOIN Kaznjiva_djela KD ON KD.id = KDS.id_kaznjivo_djelo;



/*
19. Svi slučajeve i evidentirani događaji za osobe
*/
CREATE VIEW slucajevi_dogadaji_osoba
AS
    SELECT S.naziv AS naziv_slucaja, ED.opis_dogadaja, ED.datum_vrijeme, ED.id_mjesto, O.ime_prezime
    FROM Slucaj S
        JOIN Evidencija_dogadaja ED ON S.id = ED.id_slucaj
        JOIN Osoba O ON O.id = S.id_pocinitelj;

-- Slučajevi i evidencije za određenu osobu (osumnjičenika)
SELECT *
FROM slucajevi_dogadaji_osoba
WHERE ime_prezime = 'Pero Perić'
LIMIT 0, 500;



/*
20. Svi događaji koji su vezani za slučajeve koji sadrže određeno kažnjivo djelo
*/
CREATE VIEW dogadaji_kaznjiva_djela
AS
    SELECT ED.opis_dogadaja, ED.datum_vrijeme, KD.naziv AS naziv_kaznjivog_djela
    FROM Evidencija_dogadaja ED
        JOIN Slucaj S ON ED.id_slucaj = S.id
        JOIN Kaznjiva_djela_u_slucaju KDS ON S.id = KDS.id_slucaj
        JOIN Kaznjiva_djela KD ON KDS.id_kaznjivo_djelo = KD.id;

-- Događaji koji su vezani za slučajeve koji sadrže određeno kažnjivo djelo prema nazivu 
SELECT *
FROM dogadaji_kaznjiva_djela
WHERE naziv_kaznjivog_djela = 'Ubojstvo';