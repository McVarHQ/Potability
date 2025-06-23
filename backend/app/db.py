import os
import psycopg2
import json
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    return psycopg2.connect(os.getenv("DATABASE_URL"), cursor_factory=RealDictCursor)

def insert_log(log_dict):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS logs (timestamp TEXT, inputs JSON, result TEXT);")
    cur.execute("INSERT INTO logs (timestamp, inputs, result) VALUES (%s, %s, %s)",
                (log_dict["timestamp"], json.dumps(log_dict["inputs"]), log_dict["result"]))
    conn.commit()
    conn.close()

def get_all_logs():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM logs ORDER BY timestamp DESC;")
    rows = cur.fetchall()
    conn.close()
    return rows
