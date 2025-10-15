import sqlite3
import bcrypt # Importamos bcrypt (asumimos que ya lo instalaste con pip install bcrypt)

# Nombre del archivo de la Base de Datos que se creará
DATABASE = 'apqp_auditoria.db'
# Nombre del archivo que contiene el esquema SQL
SCHEMA_FILE = 'schema.sql'


def get_db():
    """Conecta con la base de datos."""
    # Usamos la conexión simple para funciones de inicialización y obtención de listas
    db = sqlite3.connect(DATABASE)
    db.row_factory = sqlite3.Row  # Permite acceder a las columnas por nombre
    return db


def init_db():
    """Inicializa la base de datos a partir del archivo schema.sql."""
    # 1. Abrir conexión a la base de datos
    db = get_db()
    
    # 2. Abrir y leer el archivo schema.sql
    with open(SCHEMA_FILE, mode='r',encoding='utf-8') as f:
        db.cursor().executescript(f.read())
        
    # 3. Guardar los cambios (creación de tablas y datos)
    db.commit()
    db.close() # Es importante cerrar la conexión de inicialización


# --- FUNCIONES DE OBTENCIÓN DE DATOS (YA EXISTENTES) ---

def get_ubts_activas():
    """Obtiene la lista de UBTs que están marcadas como 'SI' (Activas)."""
    db = get_db()
    # Ejecuta una consulta SQL para seleccionar el ID y nombre de las UBTs activas de Planta Esperanza
    ubts = db.execute(
        'SELECT id_ubt, nombre_ubt FROM ubts u '
        'JOIN plantas p ON u.id_planta = p.id_planta '
        'WHERE u.activo = "SI" AND p.nombre_planta = "Esperanza"'
    ).fetchall()
    db.close()
    return ubts

def get_checklist_maestro():
    """Obtiene todas las preguntas del checklist maestro para el formulario."""
    db = get_db()
    # Ahora usamos los nombres de columna correctos: tipo_pregunta, texto_pregunta
    checklist = db.execute(
        'SELECT id_pregunta, tipo_pregunta, texto_pregunta FROM auditorias_maestras ORDER BY id_pregunta'
    ).fetchall()
    db.close()
    return checklist


# --- FUNCIONES DE SEGURIDAD (NUEVAS Y REQUERIDAS) ---

def hash_password_for_init(password):
    """
    Función temporal para simular el hashing y permitir que el login funcione.
    En un entorno real, esto sería bcrypt.hashpw(password.encode('utf-8'), salt).
    Por ahora, devolvemos el texto plano, ya que la DB lo tiene en texto plano (1234).
    """
    return password

def get_user_by_username(username):
    """Busca un usuario por su nombre de usuario (para el login)."""
    db = get_db()
    # JOIN para obtener el nombre del perfil (Auditor/Supervisor/Admin)
    user = db.execute(
        'SELECT u.id_usuario, u.nombre, u.usuario, u.password, u.id_perfil, p.nombre_perfil '
        'FROM usuarios u JOIN perfiles p ON u.id_perfil = p.id_perfil '
        'WHERE u.usuario = ?', 
        (username,)
    ).fetchone()
    db.close()
    return user

def get_auditoria_asignada_hoy():
    """
    [TEMPORAL] Simula la asignación de UBT/Familia para la prueba.
    En el futuro, esta función contendrá el algoritmo de scheduling.
    """
    db = get_db()
    
    # Asignamos la primera UBT/Familia que encontramos para la demostración:
    # UBT 305-2, A2LL DRIVER.
    asignacion = db.execute(
        'SELECT u.id_ubt, u.nombre_ubt, f.id_familia, f.nombre_arnes, f.programa, s.nombre AS supervisor_nombre '
        'FROM familias_arnes f '
        'JOIN ubts u ON f.id_ubt = u.id_ubt '
        'JOIN usuarios s ON u.id_supervisor = s.id_usuario '
        'WHERE f.id_familia = 1' # Selecciona el ID de la primera familia de ejemplo
    ).fetchone()
    db.close()
    return asignacion

# Bloque de ejecución principal para inicializar la DB si se ejecuta directamente
if __name__ == '__main__':
    print("Inicializando Base de Datos...")
    init_db()
    print("Base de Datos inicializada con éxito.")
    
    # Prueba: Imprime los nombres de usuario para confirmar la conexión
    print("Probando conexión (Usuarios creados):")
    db = get_db()
    usuarios = db.execute('SELECT usuario, nombre, planta, id_perfil FROM usuarios').fetchall()
    db.close()
    for user in usuarios:
        print(f"- Usuario: {user['usuario']}, Nombre: {user['nombre']}, Planta: {user['planta']}")