FROM python:3.13-slim

COPY . /app
WORKDIR /app

# Install Microsoft ODBC Driver 17 for SQL Server and dependencies
RUN apt-get update \
 && apt-get install -y gnupg curl apt-transport-https \
 && curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc \
 && echo "deb [arch=amd64] https://packages.microsoft.com/debian/11/prod bullseye main" | tee /etc/apt/sources.list.d/mssql-release.list \
 && apt-get update \
 && ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev \
 && apt-get install -y build-essential \
 && apt-get clean -y

# Install Python dependencies
RUN pip install -r requirements.txt

EXPOSE 80

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "app:app"]
