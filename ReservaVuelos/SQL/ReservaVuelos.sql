USE master;
GO

IF DB_ID(N'ReservaVuelosDB') IS NOT NULL
BEGIN
    ALTER DATABASE ReservaVuelosDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ReservaVuelosDB;
END
GO

CREATE DATABASE ReservaVuelosDB;
GO

USE ReservaVuelosDB;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE dbo.Usuarios
(
    IdUsuario INT IDENTITY(1,1) NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    PasswordSalt NVARCHAR(MAX) NOT NULL,
    Rol NVARCHAR(30) NOT NULL CONSTRAINT DF_Usuarios_Rol DEFAULT (N'Usuario'),
    Activo BIT NOT NULL CONSTRAINT DF_Usuarios_Activo DEFAULT (1),
    FechaAlta DATETIME2(0) NOT NULL CONSTRAINT DF_Usuarios_FechaAlta DEFAULT (GETDATE()),
    DVH INT NOT NULL CONSTRAINT DF_Usuarios_DVH DEFAULT (0),
    CONSTRAINT PK_Usuarios PRIMARY KEY CLUSTERED (IdUsuario),
    CONSTRAINT UQ_Usuarios_Email UNIQUE (Email),
    CONSTRAINT CK_Usuarios_Rol CHECK (Rol IN (N'Administrador', N'Usuario'))
);
GO

CREATE TABLE dbo.Clientes
(
    IdCliente INT IDENTITY(1,1) NOT NULL,
    IdUsuario INT NOT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    Documento NVARCHAR(50) NULL,
    Telefono NVARCHAR(MAX) NULL,
    Direccion NVARCHAR(MAX) NULL,
    FechaAlta DATETIME2(0) NOT NULL CONSTRAINT DF_Clientes_FechaAlta DEFAULT (GETDATE()),
    FechaActualizacion DATETIME2(0) NULL,
    DVH INT NOT NULL CONSTRAINT DF_Clientes_DVH DEFAULT (0),
    CONSTRAINT PK_Clientes PRIMARY KEY CLUSTERED (IdCliente),
    CONSTRAINT FK_Clientes_Usuarios FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuarios(IdUsuario),
    CONSTRAINT UQ_Clientes_IdUsuario UNIQUE (IdUsuario),
    CONSTRAINT CK_Clientes_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0),
    CONSTRAINT CK_Clientes_Email CHECK (LEN(LTRIM(RTRIM(Email))) > 0)
);
GO

CREATE TABLE dbo.Pasajeros
(
    IdPasajero INT IDENTITY(1,1) NOT NULL,
    IdUsuario INT NULL,
    Nombre NVARCHAR(100) NOT NULL,
    Apellido NVARCHAR(100) NULL,
    Email NVARCHAR(150) NULL,
    Documento NVARCHAR(50) NOT NULL,
    Nacionalidad NVARCHAR(MAX) NULL,
    FechaNacimiento DATE NULL,
    FechaAlta DATETIME2(0) NOT NULL CONSTRAINT DF_Pasajeros_FechaAlta DEFAULT (GETDATE()),
    FechaActualizacion DATETIME2(0) NULL,
    DVH INT NOT NULL CONSTRAINT DF_Pasajeros_DVH DEFAULT (0),
    CONSTRAINT PK_Pasajeros PRIMARY KEY CLUSTERED (IdPasajero),
    CONSTRAINT FK_Pasajeros_Usuarios FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuarios(IdUsuario),
    CONSTRAINT UQ_Pasajeros_Documento UNIQUE (Documento),
    CONSTRAINT CK_Pasajeros_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0),
    CONSTRAINT CK_Pasajeros_Documento CHECK (LEN(LTRIM(RTRIM(Documento))) > 0)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_Pasajeros_Email_Unique
ON dbo.Pasajeros(Email)
WHERE Email IS NOT NULL;
GO

CREATE TABLE dbo.Vuelos
(
    IdVuelo INT IDENTITY(1,1) NOT NULL,
    Origen NVARCHAR(100) NOT NULL,
    Destino NVARCHAR(100) NOT NULL,
    FechaSalida DATE NOT NULL,
    HoraSalida TIME(0) NOT NULL,
    FechaHoraSalida AS DATETIME2FROMPARTS(
        YEAR(FechaSalida),
        MONTH(FechaSalida),
        DAY(FechaSalida),
        DATEPART(HOUR, HoraSalida),
        DATEPART(MINUTE, HoraSalida),
        DATEPART(SECOND, HoraSalida),
        0,
        0
    ) PERSISTED,
    Precio DECIMAL(18,2) NOT NULL,
    CuposDisponibles INT NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_Vuelos_Activo DEFAULT (1),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Vuelos_FechaCreacion DEFAULT (GETDATE()),
    FechaActualizacion DATETIME2(0) NULL,
    DVH INT NOT NULL CONSTRAINT DF_Vuelos_DVH DEFAULT (0),
    CONSTRAINT PK_Vuelos PRIMARY KEY CLUSTERED (IdVuelo),
    CONSTRAINT CK_Vuelos_Origen CHECK (LEN(LTRIM(RTRIM(Origen))) > 0),
    CONSTRAINT CK_Vuelos_Destino CHECK (LEN(LTRIM(RTRIM(Destino))) > 0),
    CONSTRAINT CK_Vuelos_OrigenDestino CHECK (Origen <> Destino),
    CONSTRAINT CK_Vuelos_Precio CHECK (Precio >= 0),
    CONSTRAINT CK_Vuelos_Cupos CHECK (CuposDisponibles >= 0)
);
GO

CREATE TABLE dbo.ReservaCabecera
(
    IdReservaCabecera INT IDENTITY(1,1) NOT NULL,
    IdCliente INT NOT NULL,
    IdUsuarioCreador INT NOT NULL,
    FechaReserva DATETIME2(0) NOT NULL CONSTRAINT DF_ReservaCabecera_FechaReserva DEFAULT (GETDATE()),
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_ReservaCabecera_Estado DEFAULT (N'Activa'),
    MontoTotal DECIMAL(18,2) NOT NULL CONSTRAINT DF_ReservaCabecera_MontoTotal DEFAULT (0),
    FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_ReservaCabecera_FechaCreacion DEFAULT (GETDATE()),
    FechaActualizacion DATETIME2(0) NULL,
    FechaCancelacion DATETIME2(0) NULL,
    IdUsuarioCancela INT NULL,
    DVH INT NOT NULL CONSTRAINT DF_ReservaCabecera_DVH DEFAULT (0),
    CONSTRAINT PK_ReservaCabecera PRIMARY KEY CLUSTERED (IdReservaCabecera),
    CONSTRAINT FK_ReservaCabecera_Clientes FOREIGN KEY (IdCliente) REFERENCES dbo.Clientes(IdCliente),
    CONSTRAINT FK_ReservaCabecera_UsuariosCreador FOREIGN KEY (IdUsuarioCreador) REFERENCES dbo.Usuarios(IdUsuario),
    CONSTRAINT FK_ReservaCabecera_UsuariosCancela FOREIGN KEY (IdUsuarioCancela) REFERENCES dbo.Usuarios(IdUsuario),
    CONSTRAINT CK_ReservaCabecera_Estado CHECK (Estado IN (N'Activa', N'Cancelada')),
    CONSTRAINT CK_ReservaCabecera_MontoTotal CHECK (MontoTotal >= 0)
);
GO

CREATE TABLE dbo.ReservaDetalle
(
    IdReservaDetalle INT IDENTITY(1,1) NOT NULL,
    IdReservaCabecera INT NOT NULL,
    IdVuelo INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(18,2) NOT NULL,
    SubTotal DECIMAL(18,2) NOT NULL,
    Estado NVARCHAR(30) NOT NULL CONSTRAINT DF_ReservaDetalle_Estado DEFAULT (N'Activo'),
    DVH INT NOT NULL CONSTRAINT DF_ReservaDetalle_DVH DEFAULT (0),
    CONSTRAINT PK_ReservaDetalle PRIMARY KEY CLUSTERED (IdReservaDetalle),
    CONSTRAINT FK_ReservaDetalle_ReservaCabecera FOREIGN KEY (IdReservaCabecera) REFERENCES dbo.ReservaCabecera(IdReservaCabecera),
    CONSTRAINT FK_ReservaDetalle_Vuelos FOREIGN KEY (IdVuelo) REFERENCES dbo.Vuelos(IdVuelo),
    CONSTRAINT CK_ReservaDetalle_Cantidad CHECK (Cantidad >= 1),
    CONSTRAINT CK_ReservaDetalle_PrecioUnitario CHECK (PrecioUnitario >= 0),
    CONSTRAINT CK_ReservaDetalle_SubTotal CHECK (SubTotal >= 0),
    CONSTRAINT CK_ReservaDetalle_Estado CHECK (Estado IN (N'Activo', N'Cancelado'))
);
GO

CREATE TABLE dbo.ReservaPasajero
(
    IdReservaPasajero INT IDENTITY(1,1) NOT NULL,
    IdReservaCabecera INT NOT NULL,
    IdPasajero INT NOT NULL,
    DVH INT NOT NULL CONSTRAINT DF_ReservaPasajero_DVH DEFAULT (0),
    CONSTRAINT PK_ReservaPasajero PRIMARY KEY CLUSTERED (IdReservaPasajero),
    CONSTRAINT FK_ReservaPasajero_ReservaCabecera FOREIGN KEY (IdReservaCabecera) REFERENCES dbo.ReservaCabecera(IdReservaCabecera),
    CONSTRAINT FK_ReservaPasajero_Pasajeros FOREIGN KEY (IdPasajero) REFERENCES dbo.Pasajeros(IdPasajero),
    CONSTRAINT UQ_ReservaPasajero UNIQUE (IdReservaCabecera, IdPasajero)
);
GO

CREATE TABLE dbo.Bitacora
(
    IdBitacora INT IDENTITY(1,1) NOT NULL,
    Fecha DATETIME2(0) NOT NULL CONSTRAINT DF_Bitacora_Fecha DEFAULT (GETDATE()),
    Usuario NVARCHAR(150) NULL,
    Accion NVARCHAR(500) NOT NULL,
    Criticidad INT NOT NULL,
    Pantalla NVARCHAR(100) NULL,
    DVH INT NOT NULL CONSTRAINT DF_Bitacora_DVH DEFAULT (0),
    CONSTRAINT PK_Bitacora PRIMARY KEY CLUSTERED (IdBitacora),
    CONSTRAINT CK_Bitacora_Criticidad CHECK (Criticidad BETWEEN 1 AND 4)
);
GO

CREATE TABLE dbo.IntegridadDVV
(
    IdIntegridadDVV INT IDENTITY(1,1) NOT NULL,
    NombreTabla NVARCHAR(100) NOT NULL,
    ValorDVV BIGINT NOT NULL,
    FechaCalculo DATETIME2(0) NOT NULL,
    CONSTRAINT PK_IntegridadDVV PRIMARY KEY CLUSTERED (IdIntegridadDVV),
    CONSTRAINT UQ_IntegridadDVV_NombreTabla UNIQUE (NombreTabla)
);
GO

CREATE TABLE dbo.IntegridadError
(
    IdError INT IDENTITY(1,1) NOT NULL,
    Fecha DATETIME2(0) NOT NULL,
    TipoError NVARCHAR(10) NOT NULL,
    TipoOperacion NVARCHAR(20) NULL,
    NombreTabla NVARCHAR(100) NOT NULL,
    IdRegistroAfectado NVARCHAR(100) NULL,
    ValorEsperado NVARCHAR(100) NULL,
    ValorCalculado NVARCHAR(100) NULL,
    Estado NVARCHAR(20) NOT NULL,
    IdUsuarioAdministrador INT NULL,
    AccionTomada NVARCHAR(500) NULL,
    CONSTRAINT PK_IntegridadError PRIMARY KEY CLUSTERED (IdError),
    CONSTRAINT CK_IntegridadError_Tipo CHECK (TipoError IN (N'DVH', N'DVV')),
    CONSTRAINT CK_IntegridadError_Estado CHECK (Estado IN (N'Activo', N'Resuelto')),
    CONSTRAINT FK_IntegridadError_Usuarios FOREIGN KEY (IdUsuarioAdministrador) REFERENCES dbo.Usuarios(IdUsuario)
);
GO

CREATE TABLE dbo.IntegridadRegistro
(
    IdIntegridadRegistro INT IDENTITY(1,1) NOT NULL,
    NombreTabla NVARCHAR(100) NOT NULL,
    IdRegistro NVARCHAR(100) NOT NULL,
    ValorDVH INT NOT NULL,
    FechaCalculo DATETIME2(0) NOT NULL,
    CONSTRAINT PK_IntegridadRegistro PRIMARY KEY CLUSTERED (IdIntegridadRegistro),
    CONSTRAINT UQ_IntegridadRegistro_TablaRegistro UNIQUE (NombreTabla, IdRegistro)
);
GO

CREATE TABLE dbo.ConfiguracionSistema
(
    IdConfiguracion INT NOT NULL,
    ModoContingencia BIT NOT NULL,
    FechaUltimaValidacion DATETIME2(0) NULL,
    MotivoContingencia NVARCHAR(500) NULL,
    CONSTRAINT PK_ConfiguracionSistema PRIMARY KEY CLUSTERED (IdConfiguracion)
);
GO

CREATE NONCLUSTERED INDEX IX_Clientes_Email ON dbo.Clientes(Email);
CREATE NONCLUSTERED INDEX IX_Pasajeros_IdUsuario ON dbo.Pasajeros(IdUsuario) WHERE IdUsuario IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Vuelos_Busqueda ON dbo.Vuelos(Activo, FechaSalida, HoraSalida, CuposDisponibles);
CREATE NONCLUSTERED INDEX IX_ReservaCabecera_Cliente_Fecha ON dbo.ReservaCabecera(IdCliente, FechaReserva DESC);
CREATE NONCLUSTERED INDEX IX_ReservaCabecera_Estado ON dbo.ReservaCabecera(Estado, FechaReserva DESC);
CREATE NONCLUSTERED INDEX IX_ReservaDetalle_Reserva ON dbo.ReservaDetalle(IdReservaCabecera, Estado);
CREATE NONCLUSTERED INDEX IX_ReservaDetalle_Vuelo ON dbo.ReservaDetalle(IdVuelo, Estado);
CREATE NONCLUSTERED INDEX IX_ReservaPasajero_Reserva ON dbo.ReservaPasajero(IdReservaCabecera);
CREATE NONCLUSTERED INDEX IX_Bitacora_Fecha ON dbo.Bitacora(Fecha DESC);
CREATE NONCLUSTERED INDEX IX_IntegridadError_Estado ON dbo.IntegridadError(Estado, Fecha DESC);
CREATE NONCLUSTERED INDEX IX_IntegridadRegistro_Tabla ON dbo.IntegridadRegistro(NombreTabla, IdRegistro);
GO

INSERT INTO dbo.ConfiguracionSistema
    (IdConfiguracion, ModoContingencia, FechaUltimaValidacion, MotivoContingencia)
VALUES
    (1, 0, NULL, NULL);
GO

SET IDENTITY_INSERT dbo.Usuarios ON;
GO

INSERT INTO dbo.Usuarios
    (IdUsuario, Nombre, Email, PasswordHash, PasswordSalt, Rol, Activo, FechaAlta, DVH)
VALUES
    (1, N'Steven', N'williams.steven@outlook.com',
     N'hS5OL3HiF0ZPkDWggjqR1p8hHBnSwacygi7+ZuVTU7o=',
     N'9uKmuNr6+7s+Kl5n6ojtGQ==',
     N'Administrador', 1, CONVERT(DATETIME2(0), '2026-07-12T20:04:41'), 109);
GO

SET IDENTITY_INSERT dbo.Usuarios OFF;
GO

INSERT INTO dbo.Vuelos
    (Origen, Destino, FechaSalida, HoraSalida, Precio, CuposDisponibles, Activo, FechaCreacion, DVH)
VALUES
    (N'Buenos Aires', N'Cordoba',      CAST(DATEADD(DAY,  5, GETDATE()) AS DATE), CAST(N'07:30:00' AS TIME),  95000.00, 40, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Cordoba',      CAST(DATEADD(DAY,  5, GETDATE()) AS DATE), CAST(N'18:15:00' AS TIME), 102000.00, 32, 1, GETDATE(), 0),
    (N'Cordoba',      N'Buenos Aires', CAST(DATEADD(DAY,  6, GETDATE()) AS DATE), CAST(N'09:10:00' AS TIME),  91000.00, 35, 1, GETDATE(), 0),
    (N'Cordoba',      N'Buenos Aires', CAST(DATEADD(DAY,  7, GETDATE()) AS DATE), CAST(N'20:40:00' AS TIME), 110000.00, 28, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Mendoza',      CAST(DATEADD(DAY,  8, GETDATE()) AS DATE), CAST(N'08:00:00' AS TIME), 125000.00, 45, 1, GETDATE(), 0),
    (N'Mendoza',      N'Buenos Aires', CAST(DATEADD(DAY, 10, GETDATE()) AS DATE), CAST(N'17:30:00' AS TIME), 130000.00, 39, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Bariloche',    CAST(DATEADD(DAY, 12, GETDATE()) AS DATE), CAST(N'06:45:00' AS TIME), 180000.00, 30, 1, GETDATE(), 0),
    (N'Bariloche',    N'Buenos Aires', CAST(DATEADD(DAY, 15, GETDATE()) AS DATE), CAST(N'19:20:00' AS TIME), 188000.00, 30, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Iguazu',       CAST(DATEADD(DAY, 14, GETDATE()) AS DATE), CAST(N'10:00:00' AS TIME), 150000.00, 36, 1, GETDATE(), 0),
    (N'Iguazu',       N'Buenos Aires', CAST(DATEADD(DAY, 18, GETDATE()) AS DATE), CAST(N'16:50:00' AS TIME), 155000.00, 34, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Salta',        CAST(DATEADD(DAY, 11, GETDATE()) AS DATE), CAST(N'11:25:00' AS TIME), 142000.00, 37, 1, GETDATE(), 0),
    (N'Salta',        N'Buenos Aires', CAST(DATEADD(DAY, 17, GETDATE()) AS DATE), CAST(N'21:05:00' AS TIME), 148000.00, 33, 1, GETDATE(), 0),
    (N'Rosario',      N'Mendoza',      CAST(DATEADD(DAY, 13, GETDATE()) AS DATE), CAST(N'13:15:00' AS TIME), 135000.00, 25, 1, GETDATE(), 0),
    (N'Mendoza',      N'Rosario',      CAST(DATEADD(DAY, 16, GETDATE()) AS DATE), CAST(N'15:45:00' AS TIME), 137000.00, 25, 1, GETDATE(), 0),
    (N'Cordoba',      N'Salta',        CAST(DATEADD(DAY,  9, GETDATE()) AS DATE), CAST(N'12:00:00' AS TIME), 118000.00, 29, 1, GETDATE(), 0),
    (N'Salta',        N'Cordoba',      CAST(DATEADD(DAY, 19, GETDATE()) AS DATE), CAST(N'08:35:00' AS TIME), 120000.00, 29, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Montevideo',   CAST(DATEADD(DAY,  6, GETDATE()) AS DATE), CAST(N'09:30:00' AS TIME), 165000.00, 42, 1, GETDATE(), 0),
    (N'Montevideo',   N'Buenos Aires', CAST(DATEADD(DAY,  9, GETDATE()) AS DATE), CAST(N'18:30:00' AS TIME), 168000.00, 42, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Santiago',     CAST(DATEADD(DAY, 20, GETDATE()) AS DATE), CAST(N'07:55:00' AS TIME), 210000.00, 38, 1, GETDATE(), 0),
    (N'Santiago',     N'Buenos Aires', CAST(DATEADD(DAY, 24, GETDATE()) AS DATE), CAST(N'22:10:00' AS TIME), 215000.00, 38, 1, GETDATE(), 0),
    (N'Cordoba',      N'Bariloche',    CAST(DATEADD(DAY, 21, GETDATE()) AS DATE), CAST(N'14:15:00' AS TIME), 175000.00, 22, 1, GETDATE(), 0),
    (N'Bariloche',    N'Cordoba',      CAST(DATEADD(DAY, 27, GETDATE()) AS DATE), CAST(N'10:40:00' AS TIME), 178000.00, 22, 1, GETDATE(), 0),
    (N'Mendoza',      N'Iguazu',       CAST(DATEADD(DAY, 23, GETDATE()) AS DATE), CAST(N'06:20:00' AS TIME), 190000.00, 18, 1, GETDATE(), 0),
    (N'Iguazu',       N'Mendoza',      CAST(DATEADD(DAY, 29, GETDATE()) AS DATE), CAST(N'19:00:00' AS TIME), 194000.00, 18, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Ushuaia',      CAST(DATEADD(DAY, 30, GETDATE()) AS DATE), CAST(N'05:50:00' AS TIME), 260000.00, 26, 1, GETDATE(), 0),
    (N'Ushuaia',      N'Buenos Aires', CAST(DATEADD(DAY, 36, GETDATE()) AS DATE), CAST(N'16:25:00' AS TIME), 268000.00, 26, 1, GETDATE(), 0),
    (N'Rosario',      N'Bariloche',    CAST(DATEADD(DAY, 32, GETDATE()) AS DATE), CAST(N'12:30:00' AS TIME), 185000.00, 20, 1, GETDATE(), 0),
    (N'Bariloche',    N'Rosario',      CAST(DATEADD(DAY, 38, GETDATE()) AS DATE), CAST(N'20:15:00' AS TIME), 187000.00, 20, 1, GETDATE(), 0),
    (N'Buenos Aires', N'Mar del Plata',CAST(DATEADD(DAY,  4, GETDATE()) AS DATE), CAST(N'08:20:00' AS TIME),  70000.00, 50, 1, GETDATE(), 0),
    (N'Mar del Plata',N'Buenos Aires', CAST(DATEADD(DAY,  8, GETDATE()) AS DATE), CAST(N'19:10:00' AS TIME),  72000.00, 50, 1, GETDATE(), 0);
GO

-- Inicializacion de DVH/DVV:
-- El usuario administrador se inserta con IdUsuario = 1 para conservar el DVH 109.
-- Los vuelos se insertan con DVH = 0 porque contienen fechas relativas a GETDATE().
-- En el primer inicio de la aplicacion, IntegrityService detecta IntegridadDVV vacia,
-- recalcula todos los DVH con el algoritmo centralizado de C# y carga los DVV.
-- Si IntegridadDVV ya tiene registros, la app no acepta los datos automaticamente.
GO
