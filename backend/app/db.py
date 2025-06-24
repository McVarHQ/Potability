import os
import json
import asyncpg
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

async def get_db_connection():
    return await asyncpg.connect(DATABASE_URL)

async def init_db():
    conn = await get_db_connection()
    await conn.execute("""
        CREATE TABLE IF NOT EXISTS logs (
            timestamp TEXT,
            inputs JSONB,
            result TEXT
        );
    """)
    await conn.close()

async def insert_log(log_dict):
    conn = await get_db_connection()
    await conn.execute("""
        INSERT INTO logs (timestamp, inputs, result)
        VALUES ($1, $2::jsonb, $3);
    """, log_dict["timestamp"], json.dumps(log_dict["inputs"]), log_dict["result"])
    await conn.close()

async def get_all_logs():
    conn = await get_db_connection()
    rows = await conn.fetch("SELECT * FROM logs ORDER BY timestamp DESC;")
    await conn.close()
    return [dict(row) for row in rows]
