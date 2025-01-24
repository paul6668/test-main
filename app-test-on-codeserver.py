import psycopg2
import time
from datetime import datetime
import os

# Load secrets from Vault-injected files
def load_secret(file_path, default_value=None):
    try:
        with open(file_path, 'r') as file:
            return file.read().strip()
    except FileNotFoundError:
        print(f"Secret file not found: {file_path}")
        return default_value

# Database connection parameters
DB_HOST = os.getenv("DB_HOST", "psql-single-1-rw")
DB_PORT = int(os.getenv("DB_PORT", 5432))
DB_NAME = os.getenv("DB_NAME", "test")
DB_USER = load_secret("/vault/secrets/db_username", "app")  # Load DB_USER from secret file
DB_PASSWORD = load_secret("/vault/secrets/db_password", "abc123")  # Load DB_PASSWORD from secret file

# Debugging: Print connection parameters
print("DB_HOST:", DB_HOST)
print("DB_PORT:", DB_PORT)
print("DB_USER:", DB_USER)
print("DB_PASSWORD:", "***hidden***")  # Avoid printing sensitive information

def connect_to_db():
    try:
        connection = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        print("Successfully connected to the database")
        return connection
    except Exception as e:
        print(f"Failed to connect to the database: {e}")
        return None

def insert_record(cursor):
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    query = "INSERT INTO test_table (data) VALUES (CURRENT_TIMESTAMP);"
    cursor.execute(query)
    print(f"Inserted record with timestamp: {current_time}")

def main():
    connection = connect_to_db()
    if not connection:
        return

    cursor = connection.cursor()

    try:
        while True:
            insert_record(cursor)
            connection.commit()  # Commit transaction to the database
            time.sleep(5)  # Wait for 5 seconds

    except Exception as e:
        print(f"An error occurred: {e}")

    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

if __name__ == "__main__":
    main()
