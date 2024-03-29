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
        cursor.execute("SELECT * FROM Zaposlenici_s_najvise_rijesenih_slucajeva")
        result = cursor.fetchall()
        cursor.close()
        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM Slucajevi_u_posljednjih_n_dana")
        svjezi_slucajevi = cur.fetchall()
        cur.close()
        cur = mysql.connection.cursor()
        cur.execute('SELECT pregled_pasa.*, pas.status, pas.godina_rodjenja FROM pregled_pasa JOIN pas ON pas.id=pregled_pasa.pas_id')
        pregled_pasa = cur.fetchall()
        cur.execute('SELECT * FROM najefikasniji_pas JOIN pas ON pas.id = najefikasniji_pas.pas_id')
        najefikasniji_pas = cur.fetchall()
        cur.close()
    except OperationalError:
        print("Failed to connect to the database")
    return render_template('index.html', result=result, svjezi_slucajevi=svjezi_slucajevi, najefikasniji_pas=najefikasniji_pas)

@app.route('/slucajevi')
def slucajevi():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM Slucaj")
    cases = cur.fetchall()
    cur.close()
    return render_template('slucajevi.html', slucajevi=cases)



@app.route('/sluzbeni_psi', methods=['GET', 'POST'])
def sluzbeni_psi():
    if request.method == 'POST':
        id_trener = request.form['id_trener']
        oznaka = request.form['oznaka']
        godina_rodjenja = request.form['godina_rodjenja']
        status = "aktivan"
        id_kaznjivo_djelo = request.form['id_kaznjivo_djelo']
        cur = mysql.connection.cursor()
        cur.callproc('Dodaj_Novog_Psa', [id_trener, oznaka, godina_rodjenja, status, id_kaznjivo_djelo])
        mysql.connection.commit()
        cur.close()
    cur = mysql.connection.cursor()
    cur.execute('SELECT pregled_pasa.*, pas.status, pas.godina_rodjenja FROM pregled_pasa JOIN pas ON pas.id=pregled_pasa.pas_id')
    pregled_pasa = cur.fetchall()
    cur.execute('SELECT * FROM najefikasniji_pas JOIN pas ON pas.id = najefikasniji_pas.pas_id')
    najefikasniji_pas = cur.fetchall()
    cur.close()
    return render_template('sluzbeni_psi.html', pregled_pasa=pregled_pasa, najefikasniji_pas=najefikasniji_pas)

@app.route('/change_status', methods=['POST'])
def change_status():
    new_status = request.form['status']
    dog_id = request.form['dog_id']
    cur = mysql.connection.cursor()
    cur.execute('UPDATE pas SET status = %s WHERE id = %s', (new_status, dog_id))
    mysql.connection.commit()
    cur.close()
    return redirect(url_for('sluzbeni_psi'))

@app.route('/odjeli/<int:id_grad>/sluzbenici/<int:id_sluzbenici>')
def sluzbenici(id_grad, id_sluzbenici):
    cur = mysql.connection.cursor()
    cur.execute('SELECT * FROM prikaz_odjela WHERE zg_id=%s AND id_odjel=%s', [id_grad, id_sluzbenici])
    sluzbenici = cur.fetchall()
    cur.close()
    return render_template('sluzbenici.html', sluzbenici=sluzbenici)


@app.route('/showtables')
def show_tables():
    cur = mysql.connection.cursor()
    cur.execute("SHOW TABLES")
    tables = [table[0] for table in cur.fetchall()]
    cur.close()
    return '<br>'.join(f'{i+1}. {table}' for i, table in enumerate(tables))


@app.route('/vozila')
def vozila():
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

@app.route('/podrucja_uprave')
def podrucja_uprave():
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM podrucje_uprave")
    podrucja = cur.fetchall()
    cur.close()
    return render_template('podrucja_uprave.html', podrucja=podrucja)

@app.route('/podrucja_uprave/<podrucje_uprave>')
def odjeli_podrucje(podrucje_uprave):
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM odjeli_podrucje_uprave WHERE podrucje_id = %s", [podrucje_uprave])
    odjeli = cur.fetchall()
    cur.close()
    return render_template('odjeli_podrucje.html', odjeli=odjeli)

@app.route('/odjeli/<int:id_odjel>')
def odjeli(id_odjel):
    cur = mysql.connection.cursor()
    cur.execute("SELECT DISTINCT id_odjel, naziv, opis, zg_id FROM prikaz_odjela WHERE zg_id = %s", [id_odjel])
    result = cur.fetchall()
    cur.close()
    print(result)
    return render_template('odjeli.html', result=result)

if __name__ == '__main__':
    app.run(debug=True, port=8000)
