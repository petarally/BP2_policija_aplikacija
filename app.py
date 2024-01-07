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
app.config['MYSQL_DB'] = 'policija_aplikacija'
# app.config["MYSQL_AUTOCOMMIT"] = True ili False ... odaberite po želji i prema tome onda koristite ili ne koristite mysql.connection.commit()

mysql = MySQL(app)

def init_db():
    with app.app_context():
        db = mysql.connection
        cursor = db.cursor()
        sql_files = ['policija.sql', 'podatci.sql', 'upiti.sql', 'pogledi.sql']
        loaded_files = []
        for file in sql_files:
            try:
                with app.open_resource(os.path.join('database', file)) as f:
                    sql_commands = f.read().decode('utf8').split(';')
                    for command in sql_commands:
                        if command.strip() != '':
                            cursor.execute(command)
                loaded_files.append(file)
            except Exception as e:
                print(f"Failed to load {file}: {e}")
        db.commit()
    return loaded_files


@app.route('/')
def index():
    db_status = "No"
    loaded_files = []
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT 1")
        cur.close()
        db_status = "Yes"
        loaded_files = init_db()
        print(db_status)
        print(loaded_files)    
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
    cur.close()
    return render_template('vozila.html', vehicles=vehicles)

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
