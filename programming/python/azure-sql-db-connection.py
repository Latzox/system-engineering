from flask import Flask, jsonify
import pyodbc
import os
import msal

app = Flask(__name__)

# Database connection parameters
server = os.getenv('SQL_SERVER')
database = os.getenv('SQL_DATABASE')

def get_db_connection():
    # Use Managed Identity to get a token for Azure SQL
    connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server}.database.windows.net;PORT=1433;DATABASE={database};Authentication=ActiveDirectoryMsi'
    return pyodbc.connect(connection_string)

@app.route('/employees', methods=['GET'])
def get_employees():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT ID, Name, Position, Salary FROM Employees')
    rows = cursor.fetchall()
    conn.close()

    # Convert data to a list of dictionaries.
    employees = []
    for row in rows:
        employees.append({
            'ID': row.ID,
            'Name': row.Name,
            'Position': row.Position,
            'Salary': row.Salary
        })

    return jsonify(employees)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)