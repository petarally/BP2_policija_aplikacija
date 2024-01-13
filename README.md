# Policija

Policija je web aplikacija razvijena kao dio projekta za kolegij Baze podataka 2 na Fakultetu informatike u Puli.

![alt text](https://github.com/petarally/BP2_policija_aplikacija/blob/master/naslovna.png?raw=true)

## Instalacija

1. Kloniranje:
    ```bash
    git clone https://github.com/petarally/BP2_policija_aplikacija.git
    cd policija
    ```

2. Stvaranje i pokretanje virtual environmenta:

    Windows:
    ```bash
    python -m venv venv
    .\venv\Scripts\activate
    ```

    Unix / MacOS:
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3. Preuzimanje potrebnih biblioteka:
    ```bash
    pip install -r requirements.txt
    ```

4. Pokretanje aplikacije:
    ```bash
    python app.py
    ```

Aplikacija se pokreće na `http://127.0.0.1:8000/`.

## Funkcionalnosti
U aplikaciji je moguće pogledati sve slučajeve:
![alt text](https://github.com/petarally/BP2_policija_aplikacija/blob/master/slucajevi.png
?raw=true)

Dodati, umiroviti i pregledati sve službene pse:
![alt text](https://github.com/petarally/BP2_policija_aplikacija/blob/master/sluzbeni_psi.png
?raw=true)

Pronaći sve zaposlenike u svakom od odjela u svakoj od zgrada iz odabranog područja uprave:
![alt text](https://github.com/petarally/BP2_policija_aplikacija/blob/master/podrucja_uprave.png
?raw=true)
![alt text](https://github.com/petarally/BP2_policija_aplikacija/blob/master/zgrade.png
?raw=true)
![alt text](https://github.com/petarally/BP2_policija_aplikacija/blob/master/odjeli.png
?raw=true)
![alt text](https://github.com/petarally/BP2_policija_aplikacija/blob/master/sluzbenici.png
?raw=true)

