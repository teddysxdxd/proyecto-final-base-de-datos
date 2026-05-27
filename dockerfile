FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias de sistema para pyodbc
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev \
    && apt-get clean

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]