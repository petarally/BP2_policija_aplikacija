from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from flask_mysqldb import MySQL
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


@app.route('/')
def index():
    db_status = "No"
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT 1")
        cur.close()
        db_status = "Yes"
    except OperationalError:
        print("Failed to connect to the database")
    return render_template('index.html', db_status=db_status)

@app.route('/slucajevi')
def cases():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM Slucaj")
    cases = cur.fetchall()
    cur.close()
    return render_template('cases.html', cases=cases)


@app.route('/vozila')
def vehicles():
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT Osoba.ime_prezime, Vozilo.*
        FROM Vozilo
        JOIN Osoba ON Vozilo.id_vlasnik = Osoba.id
    """)
    vehicles = cur.fetchall()
    cur.close()
    return render_template('vehicles.html', vehicles=vehicles)

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
    print(podrucje_uprave)
    cur.close()
    return render_template('zaposlenici_podrucje.html', zaposlenici=zaposlenici)


if __name__ == '__main__':
    app.run(debug=True, port=8000)
