from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from flask_mysqldb import MySQL
import os
from MySQLdb import OperationalError

app = Flask(__name__)
app.secret_key = 'your_secret_key'

app.config['JSON_AS_ASCII'] = False

app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'root'
app.config['MYSQL_DB'] = 'Policija'
# app.config["MYSQL_AUTOCOMMIT"] = True ili False ... odaberite po želji i prema tome onda koristite ili ne koristite mysql.connection.commit()

mysql = MySQL(app)

@app.route('/')
def index():
    db_status = "No"
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT 1")
        cur.close()
        db_status = "Yes"  
        db = mysql.connection
        cursor = db.cursor()
        query = """
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
        ) AS max_voditelj)
        """
        cursor.execute(query)
        result = cursor.fetchall()
    except OperationalError:
        print("Failed to connect to the database")
    return render_template('index.html', result=result)

@app.route('/slucajevi')
def cases():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM Slucaj")
    cases = cur.fetchall()
    cur.close()
    return render_template('slucajevi.html', cases=cases)


@app.route('/showtables')
def show_tables():
    print("About to execute SHOW TABLES")
    cur = mysql.connection.cursor()
    cur.execute("SHOW TABLES")
    cur.execute("SELECT * FROM Slucaj")
    tables = [table[0] for table in cur.fetchall()]
    cur.close()
    print("Executed SHOW TABLES")
    print(tables)
    return 'Tables printed in console.'


@app.route('/vozila')
def vehicles():
    ime_prezime = request.args.get('ime_prezime', default="%", type=str)
    registracija = request.args.get('registracija', default="%", type=str)

    query = """
        SELECT Osoba.ime_prezime, Vozilo.*
        FROM Vozilo
        JOIN Osoba ON Vozilo.id_vlasnik = Osoba.id
        WHERE 1
    """
    params = []

    if ime_prezime != "":
        query += " AND Osoba.ime_prezime LIKE %s"
        params.append(ime_prezime)

    if registracija != "":
        query += " AND Vozilo.registracija LIKE %s"
        params.append(registracija)

    cur = mysql.connection.cursor()
    cur.execute(query, params)
    vehicles = cur.fetchall()
    print(vehicles)
    cur.close()
    return render_template('vozila.html', vehicles=vehicles)


@app.route('/add_vozilo', methods=['POST'])
def add_vozilo():
    marka = request.form.get('marka')
    model = request.form.get('model')
    registracija = request.form.get('registracija')
    godina_proizvodnje = request.form.get('godina_proizvodnje')
    sluzbeno_vozilo = int(request.form.get('sluzbeno_vozilo'))
    id_vlasnik = request.form.get('id_vlasnik')

    cur = mysql.connection.cursor()
    cur.callproc('Dodaj_Novo_Vozilo', [marka, model, registracija, godina_proizvodnje, sluzbeno_vozilo, id_vlasnik])
    mysql.connection.commit()
    cur.close()

    return render_template('vozila.html')

@app.route('/zaposlenici')
def zaposlenici():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM podrucje_uprave")
    podrucja = cur.fetchall()
    cur.close()
    return render_template('zaposlenici.html', podrucja=podrucja)

@app.route('/zaposlenici/<podrucje_uprave>')
def zaposlenici_podrucje(podrucje_uprave):
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM zaposlenik JOIN osoba ON osoba.id = zaposlenik.id_osoba JOIN zgrada ON zaposlenik.id_zgrada = zgrada.id JOIN mjesto ON mjesto.id = zgrada.id_mjesto WHERE id_podrucje_uprave = %s", [podrucje_uprave])
    zaposlenici = cur.fetchall()
    cur.close()
    return render_template('zaposlenici_podrucje.html', zaposlenici=zaposlenici)

@app.route('/odjeli')
def odjeli():
    cur = mysql.connection.cursor()
    query = """
        SELECT O.naziv AS naziv_odjela, COUNT(Z.id) AS broj_zaposlenika
        FROM Zaposlenik Z
        JOIN Odjeli O ON Z.id_odjel = O.id
        GROUP BY O.id, O.naziv
    """
    cur.execute(query)
    result = cur.fetchall()
    cur.close()
    return render_template('odjeli.html', result=result)

if __name__ == '__main__':
    app.run(debug=True, port=8000)
