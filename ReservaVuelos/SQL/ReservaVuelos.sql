-- Script de creación de la base de datos ReservaVuelosDB y tablas para SQL Server
-- Ajustar el nombre del servidor o ejecutar en la instancia deseada

IF DB_ID('ReservaVuelosDB') IS NULL
BEGIN
    CREATE DATABASE ReservaVuelosDB;
END
GO

USE ReservaVuelosDB;
GO

-- Tabla Usuarios
IF OBJECT_ID('Usuarios') IS NOT NULL DROP TABLE Usuarios;
CREATE TABLE Usuarios(
    IdUsuario INT IDENTITY PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    PasswordSalt NVARCHAR(MAX) NOT NULL,
    Rol NVARCHAR(30) NOT NULL,
    Activo BIT NOT NULL DEFAULT 1,
    FechaAlta DATETIME NOT NULL
);
GO

-- Tabla Vuelos
IF OBJECT_ID('Vuelos') IS NOT NULL DROP TABLE Vuelos;
CREATE TABLE Vuelos(
    IdVuelo INT IDENTITY PRIMARY KEY,
    Origen NVARCHAR(100) NOT NULL,
    Destino NVARCHAR(100) NOT NULL,
    FechaSalida DATE NOT NULL,
    HoraSalida TIME NOT NULL,
    Precio DECIMAL(18,2) NOT NULL,
    CuposDisponibles INT NOT NULL,
    Activo BIT NOT NULL DEFAULT 1
);
GO

-- Tabla Reservas
IF OBJECT_ID('Reservas') IS NOT NULL DROP TABLE Reservas;
CREATE TABLE Reservas(
    IdReserva INT IDENTITY PRIMARY KEY,
    IdUsuario INT NOT NULL,
    IdVuelo INT NOT NULL,
    FechaReserva DATETIME NOT NULL,
    Estado NVARCHAR(30) NOT NULL,
    CONSTRAINT FK_Reservas_Usuarios FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Reservas_Vuelos FOREIGN KEY (IdVuelo) REFERENCES Vuelos(IdVuelo)
);
GO

-- Tabla Bitacora
IF OBJECT_ID('Bitacora') IS NOT NULL DROP TABLE Bitacora;
CREATE TABLE Bitacora(
    IdBitacora INT IDENTITY PRIMARY KEY,
    Fecha DATETIME NOT NULL,
    Usuario NVARCHAR(150) NULL,
    Accion NVARCHAR(200) NULL,
    Criticidad NVARCHAR(50) NULL,
    Pantalla NVARCHAR(100) NULL
);
GO

-- Datos de prueba: crear un Administrador y un Usuario
-- Las contraseñas deben generarse con PBKDF2; a modo de ejemplo aquí se insertan valores que se deben reemplazar
-- Se recomienda crear usuarios mediante la app una vez desplegada; sin embargo se incluyen instrucciones para crear usuarios manualmente.

-- Ejemplo: crear usuario administrador (recomiendo registrar desde la app para generar hash/salt correctos)
-- INSERT INTO Usuarios (Nombre,Email,PasswordHash,PasswordSalt,Rol,Activo,FechaAlta) VALUES ('Admin','admin@local','<PasswordHash>','<PasswordSalt>','Administrador',1,GETDATE());

-- Datos de vuelos de ejemplo
INSERT INTO Vuelos (Origen,Destino,FechaSalida,HoraSalida,Precio,CuposDisponibles,Activo) VALUES
('Buenos Aires','Santiago','2026-06-30','08:00',150.00,50,1),
('Buenos Aires','Montevideo','2026-07-01','12:30',120.00,40,1),
('Cordoba','Buenos Aires','2026-07-02','09:15',80.00,30,1);
GO

-- Fin del script
