import sqlite3
import os # Necesario para check_db_exists
from flask import Flask, render_template, request, redirect, url_for, g, flash, session
# Necesitamos la función init_db y la nueva lógica de usuarios
from database import init_db, get_ubts_activas, get_checklist_maestro, get_user_by_username, hash_password_for_init, get_auditoria_asignada_hoy

# --- CONFIGURACIÓN ---
# Define la ubicación de la DB
DATABASE = 'apqp_auditoria.db' 

# Inicializa la aplicación Flask
app = Flask(__name__)
# Configura dónde está el archivo de la base de datos
app.config['DATABASE'] = DATABASE
# CLAVE SECRETA OBLIGATORIA para que las sesiones de usuario funcionen
app.secret_key = b'_5#y2L"F4Q8z\n\xec]/' 


# --- FUNCIONES DE CONEXIÓN A LA BASE DE DATOS ---

def get_db_connection():
    """Obtiene una conexión de DB única para cada solicitud."""
    if 'db' not in g:
        g.db = sqlite3.connect(app.config['DATABASE'])
        g.db.row_factory = sqlite3.Row  # Acceder a columnas por nombre
    return g.db

@app.teardown_appcontext
def close_db_connection(exception):
    """Cierra la conexión a la DB al final de la solicitud."""
    db = g.pop('db', None)
    if db is not None:
        db.close()

# --- ARRANQUE INICIAL: Crear la DB si no existe ---

@app.before_request
def check_db_exists():
    """Verifica si la DB existe antes de procesar una solicitud."""
    if not os.path.exists(app.config['DATABASE']):
        # Si el archivo .db no existe, lo inicializa usando el script SQL
        print("¡ADVERTENCIA! La Base de Datos no existe. Inicializando...")
        init_db()


# --- RUTAS DE SEGURIDAD Y APLICACIÓN (NUEVAS) ---

@app.route('/', methods=['GET', 'POST'])
def login():
    # Si el usuario ya está en sesión, lo enviamos directamente al dashboard
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        user = get_user_by_username(username)

        # Autenticación: Compara la contraseña ingresada (hash simple) con la de la DB
        if user and hash_password_for_init(password) == user['password']: 
            # Autenticación exitosa
            session['user_id'] = user['id_usuario']
            session['username'] = user['nombre']
            session['profile_id'] = user['id_perfil']
            session['profile_name'] = user['nombre_perfil']
            
            flash(f'Bienvenido, {user["nombre"]} ({user["nombre_perfil"]})', 'success')
            return redirect(url_for('dashboard'))
        else:
            # Autenticación fallida
            flash('Usuario o contraseña incorrectos.', 'error')
            return redirect(url_for('login'))

    return render_template('login.html')

@app.route('/logout')
def logout():
    # Borra todos los datos de la sesión y redirige al login
    session.pop('user_id', None)
    session.pop('username', None)
    session.pop('profile_id', None)
    session.pop('profile_name', None)
    flash('Has cerrado sesión.', 'info')
    return redirect(url_for('login'))


@app.route('/dashboard')
def dashboard():
    # RESTRICCIÓN: Si no hay sesión activa, redirige al login
    if 'user_id' not in session:
        flash('Debes iniciar sesión para acceder.', 'error')
        return redirect(url_for('login'))

    # Lógica de dashboard según el perfil
    return render_template('dashboard.html', 
                            username=session['username'], 
                            profile=session['profile_name'])


@app.route('/nueva_auditoria')
def nueva_auditoria():
    # 1. Verificar Login
    if 'user_id' not in session:
        flash('Debes iniciar sesión para acceder.', 'error')
        return redirect(url_for('login'))

    # 2. Verificar Perfil: Solo Perfil 3 (Auditor)
    if session['profile_id'] != 3: 
        flash('Acceso denegado. Solo Auditores pueden iniciar auditorías.', 'error')
        return redirect(url_for('dashboard'))

    # --- LÓGICA DE ASIGNACIÓN ---
    asignacion = get_auditoria_asignada_hoy() # Solo la UBT/Familia que le toca hoy

    if not asignacion:
         flash('ERROR: No hay auditoría asignada para hoy. Contacte a un administrador.', 'error')
         return redirect(url_for('dashboard'))

    checklist = get_checklist_maestro()

    return render_template('auditoria_form.html', 
                           asignacion=asignacion, # Pasamos la data de asignación
                           checklist=checklist)


# --- BLOQUE DE EJECUCIÓN ---
if __name__ == '__main__':
    # Arranca el servidor
    app.run(debug=True)