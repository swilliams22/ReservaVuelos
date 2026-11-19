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
    IdIdioma INT NULL,
    CONSTRAINT PK_Usuarios PRIMARY KEY CLUSTERED (IdUsuario),
    CONSTRAINT UQ_Usuarios_Email UNIQUE (Email),
    CONSTRAINT CK_Usuarios_Rol CHECK (Rol IN (N'Administrador', N'WebMaster', N'Usuario'))
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

CREATE TABLE dbo.Idioma
(
    IdIdioma INT IDENTITY(1,1) NOT NULL,
    Codigo NVARCHAR(10) NOT NULL,
    Nombre NVARCHAR(50) NOT NULL,
    EsDefault BIT NOT NULL CONSTRAINT DF_Idioma_EsDefault DEFAULT (0),
    Activo BIT NOT NULL CONSTRAINT DF_Idioma_Activo DEFAULT (1),
    CONSTRAINT PK_Idioma PRIMARY KEY CLUSTERED (IdIdioma),
    CONSTRAINT UQ_Idioma_Codigo UNIQUE (Codigo),
    CONSTRAINT CK_Idioma_Codigo CHECK (LEN(LTRIM(RTRIM(Codigo))) > 0),
    CONSTRAINT CK_Idioma_Nombre CHECK (LEN(LTRIM(RTRIM(Nombre))) > 0)
);
GO

-- Solo puede existir un idioma por defecto
CREATE UNIQUE NONCLUSTERED INDEX UX_Idioma_Default ON dbo.Idioma(EsDefault) WHERE EsDefault = 1;
GO

CREATE TABLE dbo.Etiqueta
(
    IdEtiqueta INT IDENTITY(1,1) NOT NULL,
    Clave NVARCHAR(100) NOT NULL,
    Pantalla NVARCHAR(50) NOT NULL,
    Descripcion NVARCHAR(200) NULL,
    CONSTRAINT PK_Etiqueta PRIMARY KEY CLUSTERED (IdEtiqueta),
    CONSTRAINT UQ_Etiqueta_Clave UNIQUE (Clave),
    CONSTRAINT CK_Etiqueta_Clave CHECK (LEN(LTRIM(RTRIM(Clave))) > 0)
);
GO

CREATE TABLE dbo.Traduccion
(
    IdIdioma INT NOT NULL,
    IdEtiqueta INT NOT NULL,
    Texto NVARCHAR(500) NOT NULL,
    CONSTRAINT PK_Traduccion PRIMARY KEY CLUSTERED (IdIdioma, IdEtiqueta),
    CONSTRAINT FK_Traduccion_Idioma FOREIGN KEY (IdIdioma) REFERENCES dbo.Idioma(IdIdioma) ON DELETE CASCADE,
    CONSTRAINT FK_Traduccion_Etiqueta FOREIGN KEY (IdEtiqueta) REFERENCES dbo.Etiqueta(IdEtiqueta) ON DELETE CASCADE
);
GO

-- Idioma preferido del usuario (no forma parte del DVH de Usuarios)
ALTER TABLE dbo.Usuarios
    ADD CONSTRAINT FK_Usuarios_Idioma FOREIGN KEY (IdIdioma) REFERENCES dbo.Idioma(IdIdioma);
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
     N'Administrador', 1, CONVERT(DATETIME2(0), '2026-07-12T20:04:41'), 109),
    (2, N'WebMaster', N'webmaster@aerolink.com',
     N'N+bMUkYHvDQf9Ffq9RiXn8MW+7s0Fo4/E3jJmGIqCNo=',
     N'hwvdf8ZZG4jR58osfvEGDg==',
     N'WebMaster', 1, CONVERT(DATETIME2(0), '2026-10-15T15:00:00'), 0),
    (3, N'Administrador', N'admin@aerolink.com',
     N'sHr4ZyRUJeQmSTOxzkUDhbdlM1ZA7sRM/S2c5AwYoeg=',
     N'kINAR2fylJmUxeG3nipXng==',
     N'Administrador', 1, CONVERT(DATETIME2(0), '2026-10-15T15:00:00'), 0),
    (4, N'Serenela', N'sere@gmail.com',
     N'QfpeYJBLjv9B7EzyoBso71A91CCotfPbQaR+f+NtBqc=',
     N'kkuy3Cq8kqQyZC3eD07+yA==',
     N'Usuario', 1, CONVERT(DATETIME2(0), '2026-10-15T15:00:00'), 0);
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

-- ============================================================================
-- IDIOMAS Y TEXTOS DE LA INTERFAZ
-- Clave de cada texto: pantalla.tipo.nombre. Al migrar una pantalla se agregan sus filas aca.
-- Esta seccion se puede ejecutar sola (sobre ReservaVuelosDB) las veces que haga falta:
-- solo agrega lo que falta y NO modifica traducciones ya cargadas o editadas.
-- ============================================================================
USE ReservaVuelosDB;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Idioma WHERE Codigo = N'es-AR')
    INSERT INTO dbo.Idioma (Codigo, Nombre, EsDefault, Activo) VALUES (N'es-AR', N'Español', 1, 1);

IF NOT EXISTS (SELECT 1 FROM dbo.Idioma WHERE Codigo = N'en-US')
    INSERT INTO dbo.Idioma (Codigo, Nombre, EsDefault, Activo) VALUES (N'en-US', N'English', 0, 1);

DECLARE @Seed TABLE
(
    Clave NVARCHAR(100),
    Pantalla NVARCHAR(50),
    Descripcion NVARCHAR(200),
    Es NVARCHAR(500),
    En NVARCHAR(500)
);

INSERT INTO @Seed (Clave, Pantalla, Descripcion, Es, En)
VALUES
-- Menu
(N'menu.buscarVuelos', N'Menú', N'Menú: buscar vuelos', N'Buscar vuelos', N'Search flights'),
(N'menu.misReservas', N'Menú', N'Menú: mis reservas', N'Mis reservas', N'My bookings'),
(N'menu.misDatos', N'Menú', N'Menú: mis datos', N'Mis datos', N'My details'),
(N'menu.admin', N'Menú', N'Menú: administración de vuelos', N'Administración', N'Administration'),
(N'menu.integridad', N'Menú', N'Menú: gestión de integridad', N'Integridad', N'Integrity'),
(N'menu.backup', N'Menú', N'Menú: backups', N'Backups', N'Backups'),
(N'menu.bitacora', N'Menú', N'Menú: bitácora', N'Bitácora', N'Audit log'),
(N'menu.login', N'Menú', N'Menú: iniciar sesión', N'Login', N'Log in'),
(N'menu.registro', N'Menú', N'Menú: registrarse', N'Registro', N'Sign up'),
(N'menu.logout', N'Menú', N'Menú: cerrar sesión', N'Logout', N'Log out'),
-- Login
(N'login.titulo', N'Login', N'Título de la pantalla y de la pestaña', N'Login', N'Log in'),
(N'login.lbl.email', N'Login', N'Etiqueta del campo email', N'Email', N'Email'),
(N'login.lbl.password', N'Login', N'Etiqueta del campo contraseña', N'Contraseña', N'Password'),
(N'login.chk.mostrarPassword', N'Login', N'Casilla para ver la contraseña', N'Mostrar contraseña', N'Show password'),
(N'login.btn.entrar', N'Login', N'Botón de ingreso', N'Entrar', N'Sign in'),
(N'login.msg.credencialesInvalidas', N'Login', N'Mensaje: email o contraseña incorrectos', N'Usuario o contraseña incorrectos.', N'Incorrect email or password.'),
(N'login.msg.errorIniciarSesion', N'Login', N'Mensaje: prefijo de error al ingresar (se le agrega el detalle)', N'Error al iniciar sesión', N'Sign-in error'),
-- Buscar vuelos
(N'buscar.titulo', N'Buscar vuelos', N'Titulo de la pestana', N'Buscar vuelos', N'Search flights'),
(N'buscar.hero.titulo', N'Buscar vuelos', N'Banner: titulo', N'VOLA EN CUOTAS', N'FLY IN INSTALLMENTS'),
(N'buscar.hero.acento', N'Buscar vuelos', N'Banner: texto destacado', N'POR ARGENTINA', N'ACROSS ARGENTINA'),
(N'buscar.tab.vuelos', N'Buscar vuelos', N'Pestana vuelos', N'VUELOS', N'FLIGHTS'),
(N'buscar.tab.checkin', N'Buscar vuelos', N'Pestana check-in', N'CHECK-IN', N'CHECK-IN'),
(N'buscar.tab.estado', N'Buscar vuelos', N'Pestana estado de vuelo', N'ESTADO DE VUELO', N'FLIGHT STATUS'),
(N'buscar.tab.miReserva', N'Buscar vuelos', N'Pestana mi reserva', N'MI RESERVA', N'MY BOOKING'),
(N'buscar.rb.ida', N'Buscar vuelos', N'Opcion solo ida', N'Ida', N'One way'),
(N'buscar.rb.idaVuelta', N'Buscar vuelos', N'Opcion ida y vuelta', N'Ida y vuelta', N'Round trip'),
(N'buscar.rb.multidestino', N'Buscar vuelos', N'Opcion multidestino (deshabilitada)', N'Multidestino', N'Multi-city'),
(N'buscar.tip.proximamente', N'Buscar vuelos', N'Tooltip de multidestino', N'Próximamente', N'Coming soon'),
(N'buscar.lbl.origen', N'Buscar vuelos', N'Etiqueta origen', N'Origen', N'Origin'),
(N'buscar.lbl.destino', N'Buscar vuelos', N'Etiqueta destino', N'Destino', N'Destination'),
(N'buscar.lbl.salida', N'Buscar vuelos', N'Etiqueta fecha de salida', N'Salida', N'Departure'),
(N'buscar.lbl.regreso', N'Buscar vuelos', N'Etiqueta fecha de regreso', N'Regreso', N'Return'),
(N'buscar.lbl.pasajeros', N'Buscar vuelos', N'Etiqueta cantidad de pasajeros', N'Cantidad de pasajeros', N'Number of passengers'),
(N'buscar.ph.origen', N'Buscar vuelos', N'Placeholder origen', N'Ciudad de origen', N'Origin city'),
(N'buscar.ph.destino', N'Buscar vuelos', N'Placeholder destino', N'Ciudad de destino', N'Destination city'),
(N'buscar.tip.intercambiar', N'Buscar vuelos', N'Tooltip del boton intercambiar', N'Intercambiar origen y destino', N'Swap origin and destination'),
(N'buscar.btn.buscar', N'Buscar vuelos', N'Boton buscar', N'BUSCAR VUELOS', N'SEARCH FLIGHTS'),
(N'buscar.nota.titulo', N'Buscar vuelos', N'Aclaracion: titulo', N'Aclaración:', N'Note:'),
(N'buscar.nota.texto', N'Buscar vuelos', N'Aclaracion: texto', N'Las reservas se realizan por tramo. Para un viaje de ida y vuelta, reserve primero el vuelo de ida y luego el vuelo de vuelta.', N'Bookings are made per leg. For a round trip, book the outbound flight first and then the return flight.'),
(N'buscar.grid.ida', N'Buscar vuelos', N'Titulo de la grilla de ida', N'Vuelos - Ida', N'Flights - Outbound'),
(N'buscar.grid.vuelta', N'Buscar vuelos', N'Titulo de la grilla de vuelta', N'Vuelos - Vuelta', N'Flights - Return'),
(N'buscar.col.id', N'Buscar vuelos', N'Grilla: columna Id', N'Id', N'Id'),
(N'buscar.col.origen', N'Buscar vuelos', N'Grilla: columna Origen', N'Origen', N'Origin'),
(N'buscar.col.destino', N'Buscar vuelos', N'Grilla: columna Destino', N'Destino', N'Destination'),
(N'buscar.col.fecha', N'Buscar vuelos', N'Grilla: columna Fecha', N'Fecha', N'Date'),
(N'buscar.col.hora', N'Buscar vuelos', N'Grilla: columna Hora', N'Hora', N'Time'),
(N'buscar.col.precio', N'Buscar vuelos', N'Grilla: columna Precio', N'Precio', N'Price'),
(N'buscar.col.cupos', N'Buscar vuelos', N'Grilla: columna Cupos', N'Cupos', N'Seats'),
(N'buscar.btn.reservar', N'Buscar vuelos', N'Grilla: boton Reservar', N'Reservar', N'Book'),
(N'buscar.btn.verVueltas', N'Buscar vuelos', N'Grilla: boton Ver vueltas', N'Ver vueltas', N'View returns'),
(N'buscar.msg.confirmarReserva', N'Buscar vuelos', N'Confirmacion antes de reservar', N'¿Confirma reservar este vuelo?', N'Do you want to book this flight?'),
(N'buscar.msg.fechaVueltaPosterior', N'Buscar vuelos', N'Error: fecha de vuelta', N'La fecha de vuelta debe ser posterior a la fecha de ida.', N'The return date must be after the departure date.'),
(N'buscar.msg.fechaVueltaPosteriorSeleccionada', N'Buscar vuelos', N'Error: fecha de vuelta vs vuelo elegido', N'La fecha de vuelta debe ser posterior a la fecha de ida seleccionada.', N'The return date must be after the selected departure date.'),
(N'buscar.msg.cantidadInvalida', N'Buscar vuelos', N'Error: cantidad de pasajeros', N'Debe indicar una cantidad de pasajeros válida.', N'Please enter a valid number of passengers.'),
(N'buscar.msg.sinVuelos', N'Buscar vuelos', N'Aviso: busqueda sin resultados', N'No se encontraron vuelos para la búsqueda seleccionada.', N'No flights were found for your search.'),
(N'buscar.msg.sinVuelosVuelta', N'Buscar vuelos', N'Aviso: sin vuelos de vuelta', N'No se encontraron vuelos de vuelta disponibles.', N'No return flights are available.'),
(N'buscar.msg.vueloNoObtenido', N'Buscar vuelos', N'Error: vuelo no encontrado', N'No se pudo obtener el vuelo seleccionado.', N'The selected flight could not be retrieved.'),
-- Gestion de idiomas
(N'menu.idiomas', N'Menú', N'Menú: gestión de idiomas', N'Idiomas', N'Languages'),
(N'idiomas.titulo', N'Gestión de idiomas', N'Título de la pantalla y de la pestaña', N'Gestión de idiomas', N'Language management'),
(N'idiomas.ayuda', N'Gestión de idiomas', N'Texto de ayuda', N'Cree un idioma, cargue sus traducciones y actívelo para que los usuarios puedan elegirlo en el selector. Los textos que queden sin traducir se muestran en el idioma por defecto.', N'Create a language, load its translations and activate it so users can pick it in the selector. Texts left untranslated are shown in the default language.'),
(N'idiomas.nuevo.titulo', N'Gestión de idiomas', N'Subtítulo: nuevo idioma', N'Nuevo idioma', N'New language'),
(N'idiomas.lbl.codigo', N'Gestión de idiomas', N'Etiqueta del código', N'Código (ej: pt-BR)', N'Code (e.g. pt-BR)'),
(N'idiomas.lbl.nombre', N'Gestión de idiomas', N'Etiqueta del nombre', N'Nombre (ej: Português)', N'Name (e.g. Português)'),
(N'idiomas.btn.crear', N'Gestión de idiomas', N'Botón crear', N'Crear idioma', N'Create language'),
(N'idiomas.lista.titulo', N'Gestión de idiomas', N'Subtítulo: lista', N'Idiomas', N'Languages'),
(N'idiomas.col.codigo', N'Gestión de idiomas', N'Columna código', N'Código', N'Code'),
(N'idiomas.col.nombre', N'Gestión de idiomas', N'Columna nombre', N'Nombre', N'Name'),
(N'idiomas.col.estado', N'Gestión de idiomas', N'Columna estado', N'Estado', N'Status'),
(N'idiomas.col.progreso', N'Gestión de idiomas', N'Columna avance', N'Traducido', N'Translated'),
(N'idiomas.col.acciones', N'Gestión de idiomas', N'Columna acciones', N'Acciones', N'Actions'),
(N'idiomas.estado.default', N'Gestión de idiomas', N'Estado: idioma por defecto', N'Por defecto', N'Default'),
(N'idiomas.estado.activo', N'Gestión de idiomas', N'Estado: activo', N'Activo', N'Active'),
(N'idiomas.estado.inactivo', N'Gestión de idiomas', N'Estado: inactivo', N'Inactivo', N'Inactive'),
(N'idiomas.btn.editar', N'Gestión de idiomas', N'Botón editar textos', N'Editar textos', N'Edit texts'),
(N'idiomas.btn.activar', N'Gestión de idiomas', N'Botón activar', N'Activar', N'Activate'),
(N'idiomas.btn.desactivar', N'Gestión de idiomas', N'Botón desactivar', N'Desactivar', N'Deactivate'),
(N'idiomas.edit.titulo', N'Gestión de idiomas', N'Título del panel de edición', N'Traducciones de:', N'Translations of:'),
(N'idiomas.lbl.pantalla', N'Gestión de idiomas', N'Filtro pantalla', N'Pantalla', N'Screen'),
(N'idiomas.todas', N'Gestión de idiomas', N'Opción todas las pantallas', N'Todas', N'All'),
(N'idiomas.chk.pendientes', N'Gestión de idiomas', N'Filtro solo pendientes', N'Solo pendientes', N'Pending only'),
(N'idiomas.btn.filtrar', N'Gestión de idiomas', N'Botón filtrar', N'Filtrar', N'Filter'),
(N'idiomas.col.pantalla', N'Gestión de idiomas', N'Columna pantalla', N'Pantalla', N'Screen'),
(N'idiomas.col.clave', N'Gestión de idiomas', N'Columna clave', N'Clave', N'Key'),
(N'idiomas.col.textoBase', N'Gestión de idiomas', N'Columna texto base', N'Texto base', N'Base text'),
(N'idiomas.col.traduccion', N'Gestión de idiomas', N'Columna traducción', N'Traducción', N'Translation'),
(N'idiomas.btn.guardar', N'Gestión de idiomas', N'Botón guardar', N'Guardar traducciones', N'Save translations'),
(N'idiomas.btn.cerrar', N'Gestión de idiomas', N'Botón cerrar', N'Cerrar', N'Close'),
(N'idiomas.msg.creado', N'Gestión de idiomas', N'Mensaje: idioma creado', N'Idioma creado. Queda inactivo hasta que lo active; cargue las traducciones abajo.', N'Language created. It stays inactive until you activate it; load the translations below.'),
(N'idiomas.msg.crear.codigo', N'Gestión de idiomas', N'Error: código inválido', N'El código no es válido. Use el formato idioma o idioma-REGIÓN, por ejemplo pt-BR.', N'The code is not valid. Use the format language or language-REGION, e.g. pt-BR.'),
(N'idiomas.msg.crear.nombre', N'Gestión de idiomas', N'Error: nombre requerido', N'Ingrese el nombre del idioma (hasta 50 caracteres).', N'Enter the language name (up to 50 characters).'),
(N'idiomas.msg.crear.existe', N'Gestión de idiomas', N'Error: código repetido', N'Ya existe un idioma con ese código.', N'A language with that code already exists.'),
(N'idiomas.msg.activado', N'Gestión de idiomas', N'Mensaje: idioma activado', N'Idioma activado.', N'Language activated.'),
(N'idiomas.msg.desactivado', N'Gestión de idiomas', N'Mensaje: idioma desactivado', N'Idioma desactivado.', N'Language deactivated.'),
(N'idiomas.msg.noDesactivarDefault', N'Gestión de idiomas', N'Error: idioma por defecto', N'El idioma por defecto no se puede desactivar.', N'The default language cannot be deactivated.'),
(N'idiomas.msg.guardado', N'Gestión de idiomas', N'Mensaje: traducciones guardadas', N'Traducciones guardadas.', N'Translations saved.'),
(N'idiomas.msg.error', N'Gestión de idiomas', N'Error: prefijo (se le agrega el detalle)', N'Ocurrió un error', N'An error occurred'),
-- Mis datos, Mis reservas y Detalle de reserva
(N'misdatos.titulo', N'Mis datos', N'Título de la pantalla y de la pestaña', N'Mis datos', N'My details'),
(N'misdatos.sec.cliente', N'Mis datos', N'Sección: cliente titular', N'Cliente titular', N'Account holder'),
(N'misdatos.sec.pasajero', N'Mis datos', N'Sección: pasajero asociado', N'Pasajero asociado', N'Linked passenger'),
(N'misdatos.lbl.nombre', N'Mis datos', N'Etiqueta nombre', N'Nombre', N'Name'),
(N'misdatos.lbl.email', N'Mis datos', N'Etiqueta email', N'Email', N'Email'),
(N'misdatos.lbl.documento', N'Mis datos', N'Etiqueta documento', N'Documento', N'ID number'),
(N'misdatos.lbl.telefono', N'Mis datos', N'Etiqueta teléfono', N'Teléfono', N'Phone'),
(N'misdatos.lbl.direccion', N'Mis datos', N'Etiqueta dirección', N'Dirección', N'Address'),
(N'misdatos.lbl.apellido', N'Mis datos', N'Etiqueta apellido', N'Apellido', N'Last name'),
(N'misdatos.lbl.nacionalidad', N'Mis datos', N'Etiqueta nacionalidad', N'Nacionalidad', N'Nationality'),
(N'misdatos.lbl.fechaNacimiento', N'Mis datos', N'Etiqueta fecha de nacimiento', N'Fecha de nacimiento', N'Date of birth'),
(N'misdatos.btn.guardar', N'Mis datos', N'Botón guardar', N'Guardar cambios', N'Save changes'),
(N'misdatos.msg.guardado', N'Mis datos', N'Mensaje: datos guardados', N'Datos actualizados correctamente.', N'Details updated successfully.'),
(N'misdatos.msg.errorGuardar', N'Mis datos', N'Error: prefijo al guardar (se le agrega el detalle)', N'Error al guardar datos', N'Error saving details'),
(N'misreservas.titulo', N'Mis reservas', N'Título de la pantalla y de la pestaña', N'Mis reservas', N'My bookings'),
(N'misreservas.lbl.reserva', N'Mis reservas', N'Encabezado de cada reserva (se le agrega el número)', N'Reserva #', N'Booking #'),
(N'misreservas.estado.activa', N'Mis reservas', N'Estado de la reserva', N'Activa', N'Active'),
(N'misreservas.estado.cancelada', N'Mis reservas', N'Estado de la reserva', N'Cancelada', N'Cancelled'),
(N'misreservas.lbl.fechaCreacion', N'Mis reservas', N'Etiqueta fecha de creación', N'Fecha de creación:', N'Creation date:'),
(N'misreservas.lbl.montoTotal', N'Mis reservas', N'Etiqueta monto total', N'Monto total:', N'Total amount:'),
(N'misreservas.lbl.fechaCancelacion', N'Mis reservas', N'Etiqueta fecha de cancelación', N'Fecha de cancelación:', N'Cancellation date:'),
(N'misreservas.sec.vuelos', N'Mis reservas', N'Sección: vuelos de la reserva', N'Vuelos:', N'Flights:'),
(N'misreservas.sec.pasajeros', N'Mis reservas', N'Sección: pasajeros de la reserva', N'Pasajeros:', N'Passengers:'),
(N'misreservas.lbl.cantidad', N'Mis reservas', N'Etiqueta cantidad', N'Cantidad:', N'Quantity:'),
(N'misreservas.lbl.precioUnitario', N'Mis reservas', N'Etiqueta precio unitario', N'Precio unitario:', N'Unit price:'),
(N'misreservas.lbl.subtotal', N'Mis reservas', N'Etiqueta subtotal', N'Subtotal:', N'Subtotal:'),
(N'misreservas.lbl.doc', N'Mis reservas', N'Etiqueta documento del pasajero', N'Doc:', N'ID:'),
(N'misreservas.lbl.email', N'Mis reservas', N'Etiqueta email del pasajero', N'Email:', N'Email:'),
(N'misreservas.btn.cancelar', N'Mis reservas', N'Botón cancelar reserva', N'Cancelar Reserva', N'Cancel booking'),
(N'misreservas.msg.confirmarCancelar', N'Mis reservas', N'Confirmación al cancelar', N'¿Confirma cancelar esta reserva?', N'Do you want to cancel this booking?'),
(N'misreservas.msg.sinReservas', N'Mis reservas', N'Mensaje: sin reservas', N'Aún no tiene reservas registradas.', N'You have no bookings yet.'),
(N'misreservas.msg.errorCargar', N'Mis reservas', N'Error: prefijo al cargar (se le agrega el detalle)', N'Error al cargar reservas', N'Error loading bookings'),
(N'misreservas.msg.cancelada', N'Mis reservas', N'Mensaje: reserva cancelada', N'Reserva cancelada correctamente.', N'Booking cancelled successfully.'),
(N'misreservas.msg.yaCancelada', N'Mis reservas', N'Error: reserva ya cancelada o inexistente', N'La reserva ya estaba cancelada o no se encontró.', N'The booking was already cancelled or was not found.'),
(N'misreservas.msg.errorCancelar', N'Mis reservas', N'Error: prefijo al cancelar (se le agrega el detalle)', N'Error al cancelar reserva', N'Error cancelling booking'),
(N'detallereserva.tituloPagina', N'Detalle de reserva', N'Título de la pestaña', N'Detalle de Reserva', N'Booking details'),
(N'detallereserva.titulo', N'Detalle de reserva', N'Título de la pantalla', N'Confirmar Reserva', N'Confirm booking'),
(N'detallereserva.sec.vuelos', N'Detalle de reserva', N'Sección: vuelos seleccionados', N'Vuelos seleccionados', N'Selected flights'),
(N'detallereserva.sec.titular', N'Detalle de reserva', N'Sección: titular de la reserva', N'Datos del titular de la reserva', N'Booking holder details'),
(N'detallereserva.lbl.nombre', N'Detalle de reserva', N'Etiqueta nombre del titular', N'Nombre:', N'Name:'),
(N'detallereserva.lbl.email', N'Detalle de reserva', N'Etiqueta email del titular', N'Email:', N'Email:'),
(N'detallereserva.lbl.documentoOpcional', N'Detalle de reserva', N'Etiqueta documento del titular', N'Documento (opcional):', N'ID number (optional):'),
(N'detallereserva.sec.pasajeros', N'Detalle de reserva', N'Sección: pasajeros', N'Pasajeros', N'Passengers'),
(N'detallereserva.lbl.cantidadDeclarada', N'Detalle de reserva', N'Etiqueta cantidad declarada', N'Cantidad declarada:', N'Declared quantity:'),
(N'detallereserva.txt.cantidadExacta', N'Detalle de reserva', N'Aclaración sobre la cantidad de pasajeros', N'Debe cargar exactamente esa cantidad para confirmar la reserva.', N'You must add exactly that number of passengers to confirm the booking.'),
(N'detallereserva.col.nombre', N'Detalle de reserva', N'Grilla de pasajeros: columna nombre', N'Nombre', N'Name'),
(N'detallereserva.col.documento', N'Detalle de reserva', N'Grilla de pasajeros: columna documento', N'Documento', N'ID number'),
(N'detallereserva.col.email', N'Detalle de reserva', N'Grilla de pasajeros: columna email', N'Email', N'Email'),
(N'detallereserva.col.nacionalidad', N'Detalle de reserva', N'Grilla de pasajeros: columna nacionalidad', N'Nacionalidad', N'Nationality'),
(N'detallereserva.btn.eliminar', N'Detalle de reserva', N'Botón eliminar pasajero', N'Eliminar', N'Remove'),
(N'detallereserva.sec.agregarPasajero', N'Detalle de reserva', N'Sección: agregar pasajero', N'Agregar Pasajero', N'Add passenger'),
(N'detallereserva.lbl.nombreReq', N'Detalle de reserva', N'Etiqueta nombre del pasajero (obligatorio)', N'Nombre *:', N'Name *:'),
(N'detallereserva.lbl.apellido', N'Detalle de reserva', N'Etiqueta apellido del pasajero', N'Apellido:', N'Last name:'),
(N'detallereserva.lbl.documentoReq', N'Detalle de reserva', N'Etiqueta documento del pasajero (obligatorio)', N'Documento *:', N'ID number *:'),
(N'detallereserva.lbl.nacionalidad', N'Detalle de reserva', N'Etiqueta nacionalidad del pasajero', N'Nacionalidad:', N'Nationality:'),
(N'detallereserva.lbl.fechaNacimiento', N'Detalle de reserva', N'Etiqueta fecha de nacimiento del pasajero', N'Fecha Nacimiento:', N'Date of birth:'),
(N'detallereserva.btn.agregar', N'Detalle de reserva', N'Botón agregar pasajero', N'Agregar Pasajero', N'Add passenger'),
(N'detallereserva.sec.resumen', N'Detalle de reserva', N'Sección: resumen', N'Resumen', N'Summary'),
(N'detallereserva.lbl.cantidadPasajeros', N'Detalle de reserva', N'Etiqueta cantidad de pasajeros', N'Cantidad de pasajeros:', N'Number of passengers:'),
(N'detallereserva.lbl.montoTotal', N'Detalle de reserva', N'Etiqueta monto total', N'Monto Total:', N'Total amount:'),
(N'detallereserva.btn.confirmar', N'Detalle de reserva', N'Botón confirmar reserva', N'CONFIRMAR RESERVA', N'CONFIRM BOOKING'),
(N'detallereserva.btn.cancelar', N'Detalle de reserva', N'Botón cancelar', N'Cancelar', N'Cancel'),
(N'detallereserva.msg.confirmar', N'Detalle de reserva', N'Confirmación al confirmar la reserva', N'¿Confirma la reserva?', N'Do you want to confirm the booking?'),
(N'detallereserva.fmt.cantidadDe', N'Detalle de reserva', N'Formato: cargados de declarados ({0} de {1})', N'{0} de {1}', N'{0} of {1}'),
(N'detallereserva.msg.nombreRequerido', N'Detalle de reserva', N'Error: nombre requerido', N'El nombre del pasajero es requerido.', N'The passenger name is required.'),
(N'detallereserva.msg.documentoRequerido', N'Detalle de reserva', N'Error: documento requerido', N'El documento del pasajero es requerido.', N'The passenger ID number is required.'),
(N'detallereserva.msg.documentoDuplicado', N'Detalle de reserva', N'Error: documento repetido', N'Ya existe un pasajero con ese documento en la lista.', N'A passenger with that ID number is already in the list.'),
(N'detallereserva.msg.cantidadAlcanzada', N'Detalle de reserva', N'Error: cantidad máxima alcanzada', N'Ya alcanzó la cantidad de pasajeros declarada para esta reserva.', N'You have already reached the declared number of passengers for this booking.'),
(N'detallereserva.msg.pasajeroAgregado', N'Detalle de reserva', N'Mensaje: pasajero agregado', N'Pasajero agregado correctamente.', N'Passenger added successfully.'),
(N'detallereserva.msg.pasajeroEliminado', N'Detalle de reserva', N'Mensaje: pasajero eliminado', N'Pasajero eliminado.', N'Passenger removed.'),
(N'detallereserva.msg.cantidadInvalida', N'Detalle de reserva', N'Error: cantidad declarada inválida', N'La cantidad de pasajeros declarada es inválida.', N'The declared number of passengers is not valid.'),
(N'detallereserva.msg.cantidadExacta', N'Detalle de reserva', N'Error: faltan pasajeros ({0} = cantidad)', N'Debe cargar exactamente {0} pasajero(s) para continuar.', N'You must add exactly {0} passenger(s) to continue.'),
(N'detallereserva.msg.reservaCreada', N'Detalle de reserva', N'Mensaje: reserva creada (se muestra en Mis reservas)', N'Reserva creada exitosamente.', N'Booking created successfully.'),
(N'detallereserva.msg.errorCrear', N'Detalle de reserva', N'Error: prefijo al crear la reserva (se le agrega el detalle)', N'Error al crear la reserva', N'Error creating the booking'),
-- Comun
(N'comun.footer', N'Común', N'Pie de pagina de la Master', N'Mi aplicación ASP.NET', N'My ASP.NET application'),
(N'comun.btn.cancelar', N'Común', N'Modal de confirmacion: boton cancelar', N'Cancelar', N'Cancel'),
(N'comun.btn.confirmar', N'Común', N'Modal de confirmacion: boton confirmar', N'Confirmar', N'Confirm');

INSERT INTO dbo.Etiqueta (Clave, Pantalla, Descripcion)
SELECT s.Clave, s.Pantalla, s.Descripcion
FROM @Seed s
WHERE NOT EXISTS (SELECT 1 FROM dbo.Etiqueta e WHERE e.Clave = s.Clave);

INSERT INTO dbo.Traduccion (IdIdioma, IdEtiqueta, Texto)
SELECT i.IdIdioma, e.IdEtiqueta, CASE i.Codigo WHEN N'es-AR' THEN s.Es ELSE s.En END
FROM @Seed s
JOIN dbo.Etiqueta e ON e.Clave = s.Clave
JOIN dbo.Idioma i ON i.Codigo IN (N'es-AR', N'en-US')
WHERE NOT EXISTS (SELECT 1 FROM dbo.Traduccion t WHERE t.IdIdioma = i.IdIdioma AND t.IdEtiqueta = e.IdEtiqueta);
GO

-- Inicializacion de DVH/DVV:
-- El usuario administrador se inserta con IdUsuario = 1 para conservar el DVH 109.
-- Los usuarios de prueba (webmaster@aerolink.com, admin@aerolink.com, sere@gmail.com, clave Admin123*)
-- y los vuelos se insertan con DVH = 0; la app los recalcula en el primer inicio.
-- Los vuelos se insertan con DVH = 0 porque contienen fechas relativas a GETDATE().
-- En el primer inicio de la aplicacion, IntegrityService detecta IntegridadDVV vacia,
-- recalcula todos los DVH con el algoritmo centralizado de C# y carga los DVV.
-- Si IntegridadDVV ya tiene registros, la app no acepta los datos automaticamente.
GO
USE ReservaVuelosDB;
GO
-- Migración aditiva e idempotente. No modifica Usuarios.Rol ni DVH/DVV.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.Permisos', N'U') IS NULL
BEGIN
 CREATE TABLE dbo.Permisos (
  IdPermiso INT IDENTITY PRIMARY KEY,
  Codigo NVARCHAR(100) NOT NULL UNIQUE,
  EsGrupo BIT NOT NULL
 );
 CREATE TABLE dbo.PermisoRelacion (
  IdPadre INT NOT NULL REFERENCES dbo.Permisos(IdPermiso),
  IdHijo INT NOT NULL REFERENCES dbo.Permisos(IdPermiso),
  CONSTRAINT PK_PermisoRelacion PRIMARY KEY (IdPadre, IdHijo),
  CONSTRAINT CK_PermisoRelacion_NoPropio CHECK (IdPadre <> IdHijo)
 );
END;
-- No pisa una configuración existente al volver a ejecutar.
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos)
BEGIN
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'OperacionesUsuario', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'GestionVuelos', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'GestionTecnica', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Usuario', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Administrador', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'WebMaster', 1);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Reservas.Crear', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Reservas.VerPropias', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Reservas.CancelarPropias', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Datos.VerPropios', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Datos.EditarPropios', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Administrar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Crear', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.DarBaja', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Importar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Vuelos.Exportar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Validar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Resolver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Integridad.Recalcular', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Backup.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Backup.Crear', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Backup.Restaurar', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Bitacora.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Idiomas.Ver', 0);
 INSERT dbo.Permisos(Codigo, EsGrupo) VALUES (N'Idiomas.Editar', 0);
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Reservas.Crear';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Reservas.VerPropias';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Reservas.CancelarPropias';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Datos.VerPropios';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'OperacionesUsuario' AND h.Codigo=N'Datos.EditarPropios';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Administrar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Crear';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.DarBaja';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Importar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionVuelos' AND h.Codigo=N'Vuelos.Exportar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Validar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Resolver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Integridad.Recalcular';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Backup.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Backup.Crear';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Backup.Restaurar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Bitacora.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Idiomas.Ver';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'GestionTecnica' AND h.Codigo=N'Idiomas.Editar';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'Usuario' AND h.Codigo=N'OperacionesUsuario';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'Administrador' AND h.Codigo=N'GestionVuelos';
 INSERT dbo.PermisoRelacion(IdPadre, IdHijo) SELECT p.IdPermiso, h.IdPermiso FROM dbo.Permisos p CROSS JOIN dbo.Permisos h WHERE p.Codigo=N'WebMaster' AND h.Codigo=N'GestionTecnica';
END;
COMMIT;
GO
CREATE OR ALTER TRIGGER dbo.TR_PermisoRelacion_Validar
ON dbo.PermisoRelacion AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 DECLARE @Total INT;
 SELECT @Total=COUNT(*) FROM dbo.Permisos WITH (TABLOCKX, HOLDLOCK);
 IF EXISTS (SELECT 1 FROM dbo.PermisoRelacion r JOIN dbo.Permisos p ON p.IdPermiso=r.IdPadre WHERE p.EsGrupo=0)
  THROW 50001, 'Un permiso simple no puede contener hijos.', 1;
 DECLARE @Ciclo BIT=0;
 ;WITH Camino AS (
  SELECT r.IdHijo AS Actual,
   CAST('/'+CONVERT(VARCHAR(12),r.IdPadre)+'/'+CONVERT(VARCHAR(12),r.IdHijo)+'/' AS VARCHAR(MAX)) AS Ruta,
   CAST(0 AS BIT) AS Ciclo
  FROM dbo.PermisoRelacion r
  UNION ALL
  SELECT r.IdHijo, CAST(c.Ruta+CONVERT(VARCHAR(12),r.IdHijo)+'/' AS VARCHAR(MAX)),
   CAST(CASE WHEN CHARINDEX('/'+CONVERT(VARCHAR(12),r.IdHijo)+'/', c.Ruta)>0 THEN 1 ELSE 0 END AS BIT)
  FROM Camino c JOIN dbo.PermisoRelacion r ON r.IdPadre=c.Actual WHERE c.Ciclo=0
 )
 SELECT TOP (1) @Ciclo=1 FROM Camino WHERE Ciclo=1 OPTION (MAXRECURSION 100);
 IF @Ciclo=1 THROW 50002, 'La estructura de permisos no puede contener ciclos.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.TR_Permisos_ValidarTipo
ON dbo.Permisos AFTER UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (SELECT 1 FROM inserted i JOIN dbo.PermisoRelacion r ON r.IdPadre=i.IdPermiso WHERE i.EsGrupo=0)
  THROW 50003, 'Un grupo con hijos no puede convertirse en permiso simple.', 1;
END;
GO
USE ReservaVuelosDB;
GO
/*
Perfiles administrables desde la aplicación.
Requiere MigracionPermisosComposite.sql. Es aditiva e idempotente: se puede repetir.
- Agrega las hojas Perfiles.Ver, Perfiles.Editar, Usuarios.Ver y Usuarios.AsignarRol
  dentro de GestionTecnica (WebMaster). Si se quitan desde la pantalla, no se reponen.
- Carga los textos (es-AR y en-US) de las pantallas de perfiles y usuarios.
- Reemplaza el CHECK fijo de Usuarios.Rol por triggers: el rol de un usuario debe ser
  un grupo existente de Permisos, y no se puede borrar un grupo asignado a usuarios.
No modifica Usuarios ni DVH/DVV.
*/
SET XACT_ABORT ON;
IF OBJECT_ID(N'dbo.Permisos', N'U') IS NULL OR OBJECT_ID(N'dbo.PermisoRelacion', N'U') IS NULL
 THROW 50020, 'Ejecutar antes MigracionPermisosComposite.sql.', 1;
IF EXISTS (SELECT 1 FROM dbo.Usuarios u WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = u.Rol AND p.EsGrupo = 1))
 THROW 50021, 'Hay usuarios con un rol que no existe como grupo en Permisos.', 1;
BEGIN TRANSACTION;
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Usuarios_Rol' AND parent_object_id = OBJECT_ID(N'dbo.Usuarios'))
 ALTER TABLE dbo.Usuarios DROP CONSTRAINT CK_Usuarios_Rol;

DECLARE @Tecnica INT = (SELECT IdPermiso FROM dbo.Permisos WHERE Codigo = N'GestionTecnica' AND EsGrupo = 1);
DECLARE @Nuevas TABLE (IdPermiso INT NOT NULL);
-- Sólo se cuelgan de GestionTecnica las hojas creadas en esta ejecución.
INSERT dbo.Permisos (Codigo, EsGrupo)
OUTPUT inserted.IdPermiso INTO @Nuevas (IdPermiso)
SELECT v.Codigo, 0
FROM (VALUES (N'Perfiles.Ver'), (N'Perfiles.Editar'), (N'Usuarios.Ver'), (N'Usuarios.AsignarRol')) v (Codigo)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = v.Codigo);
IF @Tecnica IS NOT NULL
 INSERT dbo.PermisoRelacion (IdPadre, IdHijo) SELECT @Tecnica, IdPermiso FROM @Nuevas;
COMMIT;
GO
CREATE OR ALTER TRIGGER dbo.TR_Usuarios_ValidarRol
ON dbo.Usuarios AFTER INSERT, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT UPDATE(Rol) RETURN;
 IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = i.Rol AND p.EsGrupo = 1))
  THROW 50004, 'El rol asignado debe ser un perfil existente.', 1;
END;
GO
CREATE OR ALTER TRIGGER dbo.TR_Permisos_ProtegerRolEnUso
ON dbo.Permisos AFTER DELETE, UPDATE
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS (
  SELECT 1 FROM dbo.Usuarios u
  WHERE u.Rol IN (SELECT Codigo FROM deleted)
    AND NOT EXISTS (SELECT 1 FROM dbo.Permisos p WHERE p.Codigo = u.Rol AND p.EsGrupo = 1))
  THROW 50005, 'El perfil está asignado a usuarios.', 1;
END;
GO
-- Textos de las pantallas de perfiles y usuarios (no pisa traducciones editadas).
IF OBJECT_ID(N'dbo.Etiqueta', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.Traduccion', N'U') IS NOT NULL
BEGIN
 DECLARE @Seed TABLE (Clave NVARCHAR(100), Pantalla NVARCHAR(50), Descripcion NVARCHAR(200), Es NVARCHAR(500), En NVARCHAR(500));
 INSERT INTO @Seed (Clave, Pantalla, Descripcion, Es, En)
 VALUES
    (N'menu.perfiles', N'Menú', N'Menú: gestión de perfiles', N'Perfiles', N'Profiles'),
    (N'menu.usuarios', N'Menú', N'Menú: gestión de usuarios', N'Usuarios', N'Users'),
    (N'perfiles.titulo', N'Gestión de perfiles', N'Título de la pantalla y de la pestaña', N'Gestión de perfiles', N'Profile management'),
    (N'perfiles.ayuda', N'Gestión de perfiles', N'Texto de ayuda', N'Un perfil agrupa permisos. A un perfil se le pueden asignar permisos simples y otros perfiles. Los permisos simples están definidos por el sistema y no se crean desde esta pantalla.', N'A profile groups permissions. A profile can be given simple permissions and other profiles. Simple permissions are defined by the system and cannot be created from this screen.'),
    (N'perfiles.nuevo.titulo', N'Gestión de perfiles', N'Subtítulo: nuevo perfil', N'Nuevo perfil', N'New profile'),
    (N'perfiles.lbl.nombre', N'Gestión de perfiles', N'Etiqueta del nombre', N'Nombre (hasta 30 caracteres)', N'Name (up to 30 characters)'),
    (N'perfiles.btn.crear', N'Gestión de perfiles', N'Botón crear', N'Crear perfil', N'Create profile'),
    (N'perfiles.lista.titulo', N'Gestión de perfiles', N'Subtítulo: lista', N'Perfiles', N'Profiles'),
    (N'perfiles.col.nombre', N'Gestión de perfiles', N'Columna nombre', N'Nombre', N'Name'),
    (N'perfiles.col.usuarios', N'Gestión de perfiles', N'Columna usuarios asignados', N'Usuarios asignados', N'Assigned users'),
    (N'perfiles.col.acciones', N'Gestión de perfiles', N'Columna acciones', N'Acciones', N'Actions'),
    (N'perfiles.col.permiso', N'Gestión de perfiles', N'Columna permiso', N'Permiso', N'Permission'),
    (N'perfiles.col.tipo', N'Gestión de perfiles', N'Columna tipo', N'Tipo', N'Type'),
    (N'perfiles.tipo.simple', N'Gestión de perfiles', N'Tipo: permiso simple', N'Simple', N'Simple'),
    (N'perfiles.tipo.compuesto', N'Gestión de perfiles', N'Tipo: perfil (compuesto)', N'Compuesto', N'Composite'),
    (N'perfiles.btn.ver', N'Gestión de perfiles', N'Botón ver/editar', N'Ver / editar', N'View / edit'),
    (N'perfiles.btn.eliminar', N'Gestión de perfiles', N'Botón eliminar', N'Eliminar', N'Delete'),
    (N'perfiles.btn.quitar', N'Gestión de perfiles', N'Botón quitar permiso', N'Quitar', N'Remove'),
    (N'perfiles.btn.agregar', N'Gestión de perfiles', N'Botón agregar permiso', N'Agregar', N'Add'),
    (N'perfiles.btn.cerrar', N'Gestión de perfiles', N'Botón cerrar', N'Cerrar', N'Close'),
    (N'perfiles.detalle.titulo', N'Gestión de perfiles', N'Subtítulo del detalle', N'Perfil:', N'Profile:'),
    (N'perfiles.arbol.titulo', N'Gestión de perfiles', N'Subtítulo del árbol', N'Permisos efectivos (árbol completo)', N'Effective permissions (full tree)'),
    (N'perfiles.asignados.titulo', N'Gestión de perfiles', N'Subtítulo de asignados', N'Asignados directamente', N'Directly assigned'),
    (N'perfiles.agregar.titulo', N'Gestión de perfiles', N'Subtítulo de agregar', N'Agregar permiso o perfil', N'Add permission or profile'),
    (N'perfiles.sinAsignados', N'Gestión de perfiles', N'Grilla vacía', N'Este perfil todavía no tiene permisos.', N'This profile has no permissions yet.'),
    (N'perfiles.sinDisponibles', N'Gestión de perfiles', N'Lista de disponibles vacía', N'No hay más permisos para agregar', N'No more permissions to add'),
    (N'perfiles.msg.creado', N'Gestión de perfiles', N'Mensaje: perfil creado', N'Perfil creado.', N'Profile created.'),
    (N'perfiles.msg.agregado', N'Gestión de perfiles', N'Mensaje: permiso agregado', N'Permiso agregado.', N'Permission added.'),
    (N'perfiles.msg.quitado', N'Gestión de perfiles', N'Mensaje: permiso quitado', N'Permiso quitado.', N'Permission removed.'),
    (N'perfiles.msg.eliminado', N'Gestión de perfiles', N'Mensaje: perfil eliminado', N'Perfil eliminado.', N'Profile deleted.'),
    (N'perfiles.msg.confirmarEliminar', N'Gestión de perfiles', N'Confirmación al eliminar', N'¿Eliminar este perfil?', N'Delete this profile?'),
    (N'perfiles.msg.error', N'Gestión de perfiles', N'Error: prefijo', N'Error', N'Error'),
    (N'usuarios.titulo', N'Gestión de usuarios', N'Título de la pantalla y de la pestaña', N'Gestión de usuarios', N'User management'),
    (N'usuarios.ayuda', N'Gestión de usuarios', N'Texto de ayuda', N'Elija el perfil de cada usuario. El cambio se aplica en su próxima acción, sin cerrar su sesión. No puede cambiar su propio perfil.', N'Choose each user''s profile. The change applies on their next action, without closing their session. You cannot change your own profile.'),
    (N'usuarios.col.nombre', N'Gestión de usuarios', N'Columna nombre', N'Nombre', N'Name'),
    (N'usuarios.col.email', N'Gestión de usuarios', N'Columna email', N'Email', N'Email'),
    (N'usuarios.col.estado', N'Gestión de usuarios', N'Columna estado', N'Estado', N'Status'),
    (N'usuarios.col.rol', N'Gestión de usuarios', N'Columna perfil', N'Perfil', N'Profile'),
    (N'usuarios.col.acciones', N'Gestión de usuarios', N'Columna acciones', N'Acciones', N'Actions'),
    (N'usuarios.estado.activo', N'Gestión de usuarios', N'Estado: activo', N'Activo', N'Active'),
    (N'usuarios.estado.inactivo', N'Gestión de usuarios', N'Estado: inactivo', N'Inactivo', N'Inactive'),
    (N'usuarios.usted', N'Gestión de usuarios', N'Marca del usuario actual', N'(usted)', N'(you)'),
    (N'usuarios.btn.asignar', N'Gestión de usuarios', N'Botón asignar perfil', N'Asignar', N'Assign'),
    (N'usuarios.msg.asignado', N'Gestión de usuarios', N'Mensaje: perfil asignado', N'Perfil asignado.', N'Profile assigned.'),
    (N'usuarios.msg.error', N'Gestión de usuarios', N'Error: prefijo', N'Error', N'Error');
 INSERT INTO dbo.Etiqueta (Clave, Pantalla, Descripcion)
 SELECT s.Clave, s.Pantalla, s.Descripcion FROM @Seed s
 WHERE NOT EXISTS (SELECT 1 FROM dbo.Etiqueta e WHERE e.Clave = s.Clave);
 INSERT INTO dbo.Traduccion (IdIdioma, IdEtiqueta, Texto)
 SELECT i.IdIdioma, e.IdEtiqueta, CASE i.Codigo WHEN N'es-AR' THEN s.Es ELSE s.En END
 FROM @Seed s
 JOIN dbo.Etiqueta e ON e.Clave = s.Clave
 JOIN dbo.Idioma i ON i.Codigo IN (N'es-AR', N'en-US')
 WHERE NOT EXISTS (SELECT 1 FROM dbo.Traduccion t WHERE t.IdIdioma = i.IdIdioma AND t.IdEtiqueta = e.IdEtiqueta);
END;
GO

-- BEGIN MigracionIdiomasCompletar.sql (mantener sincronizado con SQL/MigracionIdiomasCompletar.sql)
USE ReservaVuelosDB;
GO
-- Traducciones faltantes: aditiva, repetible y sin sobrescribir textos editados.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Textos TABLE (Clave NVARCHAR(100), Pantalla NVARCHAR(50), Descripcion NVARCHAR(500), Es NVARCHAR(500), En NVARCHAR(500));
INSERT INTO @Textos (Clave, Pantalla, Descripcion, Es, En) VALUES
 (N'validacion.perfiles.proteger', N'Validaciones', N'Protección del acceso propio', N'No se puede eliminar {0}: su propio perfil perdería el acceso a la administración de perfiles.', N'Cannot delete {0}: your own profile would lose access to profile management.'),
 (N'ui.adminvuelos.001', N'AdminVuelos', N'Administración de vuelos', N'Administración de vuelos', N'Flight management'),
 (N'ui.adminvuelos.002', N'AdminVuelos', N'Origen', N'Origen', N'Origin'),
 (N'ui.adminvuelos.003', N'AdminVuelos', N'Destino', N'Destino', N'Destination'),
 (N'ui.adminvuelos.004', N'AdminVuelos', N'Precio', N'Precio', N'Price'),
 (N'ui.adminvuelos.005', N'AdminVuelos', N'Cupos', N'Cupos', N'Available seats'),
 (N'ui.adminvuelos.006', N'AdminVuelos', N'Crear', N'Crear', N'Create'),
 (N'ui.adminvuelos.007', N'AdminVuelos', N'Confirma crear este vuelo?', N'Confirma crear este vuelo?', N'Create this flight?'),
 (N'ui.adminvuelos.008', N'AdminVuelos', N'Exportar vuelos a XML', N'Exportar vuelos a XML', N'Export flights to XML'),
 (N'ui.adminvuelos.009', N'AdminVuelos', N'Importar vuelos desde XML', N'Importar vuelos desde XML', N'Import flights from XML'),
 (N'ui.adminvuelos.010', N'AdminVuelos', N'Confirma importar los vuelos del archivo XML?', N'Confirma importar los vuelos del archivo XML?', N'Import the flights from this XML file?'),
 (N'ui.adminvuelos.011', N'AdminVuelos', N'Baja', N'Baja', N'Deactivate'),
 (N'ui.adminvuelos.012', N'AdminVuelos', N'Administración de vuelos', N'Administración de vuelos', N'Flight management'),
 (N'ui.adminvuelos.013', N'AdminVuelos', N'Crear vuelo', N'Crear vuelo', N'Create flight'),
 (N'ui.adminvuelos.014', N'AdminVuelos', N'Filtro', N'Filtro', N'Filter'),
 (N'ui.adminvuelos.015', N'AdminVuelos', N'Vuelos', N'Vuelos', N'Flights'),
 (N'ui.adminvuelos.016', N'AdminVuelos', N'Todos', N'Todos', N'All'),
 (N'ui.adminvuelos.017', N'AdminVuelos', N'Activos', N'Activos', N'Active'),
 (N'ui.adminvuelos.018', N'AdminVuelos', N'Dados de baja', N'Dados de baja', N'Deactivated'),
 (N'ui.adminvuelos.019', N'AdminVuelos', N'Id', N'Id', N'ID'),
 (N'ui.adminvuelos.020', N'AdminVuelos', N'Origen', N'Origen', N'Origin'),
 (N'ui.adminvuelos.021', N'AdminVuelos', N'Destino', N'Destino', N'Destination'),
 (N'ui.adminvuelos.022', N'AdminVuelos', N'Fecha', N'Fecha', N'Date'),
 (N'ui.adminvuelos.023', N'AdminVuelos', N'Hora', N'Hora', N'Time'),
 (N'ui.adminvuelos.024', N'AdminVuelos', N'Precio', N'Precio', N'Price'),
 (N'ui.adminvuelos.025', N'AdminVuelos', N'Cupos', N'Cupos', N'Available seats'),
 (N'ui.adminvuelos.026', N'AdminVuelos', N'Estado', N'Estado', N'Status'),
 (N'ui.backup.001', N'Backup', N'Backups', N'Backups', N'Backups'),
 (N'ui.backup.002', N'Backup', N'Los backups se almacenan en la carpeta C:\AeroLink\backups\ del equipo donde se ejecuta SQL Server', N'Los backups se almacenan en la carpeta C:\AeroLink\backups\ del equipo donde se ejecuta SQL Server', N'Backups are stored in C:\AeroLink\backups\ on the computer running SQL Server'),
 (N'ui.backup.003', N'Backup', N'Generar backup', N'Generar backup', N'Create backup'),
 (N'ui.backup.004', N'Backup', N'Confirma generar un backup de base de datos?', N'Confirma generar un backup de base de datos?', N'Create a database backup?'),
 (N'ui.backup.005', N'Backup', N'Actualizar lista', N'Actualizar lista', N'Refresh list'),
 (N'ui.backup.006', N'Backup', N'Seleccionar', N'Seleccionar', N'Select'),
 (N'ui.backup.007', N'Backup', N'Restaurar backup', N'Restaurar backup', N'Restore backup'),
 (N'ui.backup.008', N'Backup', N'Confirma restaurar el backup seleccionado? Esta acción reemplazará el estado actual de la base.', N'Confirma restaurar el backup seleccionado? Esta acción reemplazará el estado actual de la base.', N'Restore the selected backup? This will replace the current database.'),
 (N'ui.backup.009', N'Backup', N'Backups', N'Backups', N'Backups'),
 (N'ui.backup.010', N'Backup', N'Generación de backup', N'Generación de backup', N'Backup creation'),
 (N'ui.backup.011', N'Backup', N'Nombre del archivo:', N'Nombre del archivo:', N'File name:'),
 (N'ui.backup.012', N'Backup', N'Fecha y hora:', N'Fecha y hora:', N'Date and time:'),
 (N'ui.backup.013', N'Backup', N'Ruta completa:', N'Ruta completa:', N'Full path:'),
 (N'ui.backup.014', N'Backup', N'Resultado:', N'Resultado:', N'Result:'),
 (N'ui.backup.015', N'Backup', N'Mensaje:', N'Mensaje:', N'Message:'),
 (N'ui.backup.016', N'Backup', N'Restauración de backup', N'Restauración de backup', N'Backup restoration'),
 (N'ui.backup.017', N'Backup', N'Archivo seleccionado:', N'Archivo seleccionado:', N'Selected file:'),
 (N'ui.backup.018', N'Backup', N'Resultado restauración:', N'Resultado restauración:', N'Restoration result:'),
 (N'ui.backup.019', N'Backup', N'Mensaje restauración:', N'Mensaje restauración:', N'Restoration message:'),
 (N'ui.backup.020', N'Backup', N'Restaurar un backup reemplazará el estado actual de la base de datos. Los cambios posteriores a la copia seleccionada pueden perderse.', N'Restaurar un backup reemplazará el estado actual de la base de datos. Los cambios posteriores a la copia seleccionada pueden perderse.', N'Restoring a backup will replace the current database. Changes made after the selected backup may be lost.'),
 (N'ui.backup.021', N'Backup', N'La ruta mostrada corresponde al equipo donde corre SQL Server.', N'La ruta mostrada corresponde al equipo donde corre SQL Server.', N'The displayed path refers to the computer running SQL Server.'),
 (N'ui.backup.022', N'Backup', N'Nombre', N'Nombre', N'Name'),
 (N'ui.backup.023', N'Backup', N'Fecha', N'Fecha', N'Date'),
 (N'ui.backup.024', N'Backup', N'Tamaño', N'Tamaño', N'Size'),
 (N'ui.backup.025', N'Backup', N'Ruta', N'Ruta', N'Path'),
 (N'ui.backup.026', N'Backup', N'Seleccionar', N'Seleccionar', N'Select'),
 (N'ui.bitacora.001', N'Bitacora', N'Bitácora', N'Bitácora', N'Audit log'),
 (N'ui.bitacora.002', N'Bitacora', N'Filtrar', N'Filtrar', N'Filter'),
 (N'ui.bitacora.003', N'Bitacora', N'Limpiar filtros', N'Limpiar filtros', N'Clear filters'),
 (N'ui.bitacora.004', N'Bitacora', N'Bitácora', N'Bitácora', N'Audit log'),
 (N'ui.bitacora.005', N'Bitacora', N'Leyenda de criticidad: 1 = Información, 2 = Advertencia, 3 = Error, 4 = Crítica.', N'Leyenda de criticidad: 1 = Información, 2 = Advertencia, 3 = Error, 4 = Crítica.', N'Severity: 1 = Information, 2 = Warning, 3 = Error, 4 = Critical.'),
 (N'ui.bitacora.006', N'Bitacora', N'Fecha desde:', N'Fecha desde:', N'Start date:'),
 (N'ui.bitacora.007', N'Bitacora', N'Fecha hasta:', N'Fecha hasta:', N'End date:'),
 (N'ui.bitacora.008', N'Bitacora', N'Criticidad:', N'Criticidad:', N'Severity:'),
 (N'ui.bitacora.009', N'Bitacora', N'Pantalla:', N'Pantalla:', N'Page:'),
 (N'ui.bitacora.010', N'Bitacora', N'Usuario:', N'Usuario:', N'User:'),
 (N'ui.bitacora.011', N'Bitacora', N'Todas', N'Todas', N'All'),
 (N'ui.bitacora.012', N'Bitacora', N'1 - Información', N'1 - Información', N'1 - Information'),
 (N'ui.bitacora.013', N'Bitacora', N'2 - Advertencia', N'2 - Advertencia', N'2 - Warning'),
 (N'ui.bitacora.014', N'Bitacora', N'3 - Error', N'3 - Error', N'3 - Error'),
 (N'ui.bitacora.015', N'Bitacora', N'4 - Crítica', N'4 - Crítica', N'4 - Critical'),
 (N'ui.bitacora.016', N'Bitacora', N'Fecha', N'Fecha', N'Date'),
 (N'ui.bitacora.017', N'Bitacora', N'Usuario', N'Usuario', N'User'),
 (N'ui.bitacora.018', N'Bitacora', N'Acción', N'Acción', N'Action'),
 (N'ui.bitacora.019', N'Bitacora', N'Criticidad', N'Criticidad', N'Severity'),
 (N'ui.bitacora.020', N'Bitacora', N'Pantalla', N'Pantalla', N'Page'),
 (N'ui.bitacora.021', N'Bitacora', N'Fecha desde:', N'Fecha desde:', N'Start date:'),
 (N'ui.bitacora.022', N'Bitacora', N'Fecha hasta:', N'Fecha hasta:', N'End date:'),
 (N'ui.bitacora.023', N'Bitacora', N'Usuario:', N'Usuario:', N'User:'),
 (N'ui.bitacora.024', N'Bitacora', N'Criticidad:', N'Criticidad:', N'Severity:'),
 (N'ui.bitacora.025', N'Bitacora', N'Pantalla:', N'Pantalla:', N'Page:'),
 (N'ui.gestionintegridad.001', N'GestionIntegridad', N'Gestión de Integridad', N'Gestión de Integridad', N'Integrity management'),
 (N'ui.gestionintegridad.002', N'GestionIntegridad', N'Volver a validar', N'Volver a validar', N'Validate again'),
 (N'ui.gestionintegridad.003', N'GestionIntegridad', N'Validar y salir de contingencia', N'Validar y salir de contingencia', N'Validate and exit contingency mode'),
 (N'ui.gestionintegridad.004', N'GestionIntegridad', N'Recalcular DVH/DVV', N'Recalcular DVH/DVV', N'Recalculate DVH/DVV'),
 (N'ui.gestionintegridad.005', N'GestionIntegridad', N'Recalcular los dígitos verificadores aceptará como válido el estado actual de los datos. Utilice esta opción únicamente después de revisar y corregir la causa de la inconsistencia. ¿Confirma el recálculo?', N'Recalcular los dígitos verificadores aceptará como válido el estado actual de los datos. Utilice esta opción únicamente después de revisar y corregir la causa de la inconsistencia. ¿Confirma el recálculo?', N'Recalculating check digits will accept the current data as valid. Use this option only after reviewing and fixing the inconsistency. Confirm recalculation?'),
 (N'ui.gestionintegridad.006', N'GestionIntegridad', N'Gestión de Integridad', N'Gestión de Integridad', N'Integrity management'),
 (N'ui.gestionintegridad.007', N'GestionIntegridad', N'Modo contingencia:', N'Modo contingencia:', N'Contingency mode:'),
 (N'ui.gestionintegridad.008', N'GestionIntegridad', N'Última validación:', N'Última validación:', N'Last validation:'),
 (N'ui.gestionintegridad.009', N'GestionIntegridad', N'Motivo:', N'Motivo:', N'Reason:'),
 (N'ui.gestionintegridad.010', N'GestionIntegridad', N'Backups', N'Backups', N'Backups'),
 (N'ui.gestionintegridad.011', N'GestionIntegridad', N'Bitácora', N'Bitácora', N'Audit log'),
 (N'ui.gestionintegridad.012', N'GestionIntegridad', N'Operacion', N'Operacion', N'Operation'),
 (N'ui.gestionintegridad.013', N'GestionIntegridad', N'Falla', N'Falla', N'Failure'),
 (N'ui.gestionintegridad.014', N'GestionIntegridad', N'Tabla', N'Tabla', N'Table'),
 (N'ui.gestionintegridad.015', N'GestionIntegridad', N'Registro', N'Registro', N'Record'),
 (N'ui.registro.001', N'Registro', N'Registro', N'Registro', N'Registration'),
 (N'ui.registro.002', N'Registro', N'Nombre', N'Nombre', N'Name'),
 (N'ui.registro.003', N'Registro', N'Email', N'Email', N'Email'),
 (N'ui.registro.004', N'Registro', N'Contraseña', N'Contraseña', N'Password'),
 (N'ui.registro.005', N'Registro', N'Registrarme', N'Registrarme', N'Register'),
 (N'ui.registro.006', N'Registro', N'Confirma crear este usuario?', N'Confirma crear este usuario?', N'Create this user?'),
 (N'ui.registro.007', N'Registro', N'Registro', N'Registro', N'Registration'),
 (N'ui.registro.008', N'Registro', N'Mostrar Contraseña', N'Mostrar Contraseña', N'Show password'),
 (N'ui.registro.009', N'Registro', N'Mostrar Contraseña', N'Mostrar Contraseña', N'Show password'),
 (N'ui.mantenimiento.001', N'Mantenimiento', N'Mantenimiento', N'Mantenimiento', N'Maintenance'),
 (N'ui.mantenimiento.002', N'Mantenimiento', N'Mantenimiento', N'Mantenimiento', N'Maintenance'),
 (N'ui.mantenimiento.003', N'Mantenimiento', N'La aplicación se encuentra temporalmente en mantenimiento debido a una verificación de integridad. Comuníquese con el WebMaster.', N'La aplicación se encuentra temporalmente en mantenimiento debido a una verificación de integridad. Comuníquese con el WebMaster.', N'The application is temporarily under maintenance due to an integrity check. Please contact the WebMaster.'),
 (N'ui.enconstruccion.001', N'EnConstruccion', N'Proximamente', N'Proximamente', N'Coming soon'),
 (N'ui.enconstruccion.002', N'EnConstruccion', N'POR ARGENTINA', N'POR ARGENTINA', N'ACROSS ARGENTINA'),
 (N'ui.enconstruccion.003', N'EnConstruccion', N'Página en construcción', N'Página en construcción', N'Page under construction'),
 (N'ui.enconstruccion.004', N'EnConstruccion', N'Esta sección todavía no está disponible. Estamos trabajando para tenerla lista pronto.', N'Esta sección todavía no está disponible. Estamos trabajando para tenerla lista pronto.', N'This section is not available yet. We are working to make it available soon.'),
 (N'ui.enconstruccion.005', N'EnConstruccion', N'VOLVER A BUSCAR VUELOS', N'VOLVER A BUSCAR VUELOS', N'BACK TO FLIGHT SEARCH'),
 (N'ui.enconstruccion.006', N'EnConstruccion', N'VOLA EN CUOTAS', N'VOLA EN CUOTAS', N'FLY IN INSTALLMENTS'),
 (N'ui.enconstruccion.007', N'EnConstruccion', N'VOLA EN CUOTAS', N'VOLA EN CUOTAS', N'FLY IN INSTALLMENTS'),
 (N'ui.default.001', N'Default', N'Inicio', N'Inicio', N'Home'),
 (N'ui.default.002', N'Default', N'Bienvenido al Sistema de Reserva de Vuelos', N'Bienvenido al Sistema de Reserva de Vuelos', N'Welcome to the Flight Reservation System'),
 (N'ui.default.003', N'Default', N'Esta aplicación académica permite buscar vuelos, registrarse, reservar y administrar vuelos según permisos.', N'Esta aplicación académica permite buscar vuelos, registrarse, reservar y administrar vuelos según permisos.', N'This academic application lets you search flights, register, book and manage flights according to your permissions.'),
 (N'ui.default.004', N'Default', N'Buscar vuelos', N'Buscar vuelos', N'Search flights'),
 (N'ui.about.001', N'About', N'Acerca de', N'Acerca de', N'About'),
 (N'ui.about.002', N'About', N'Acerca de', N'Acerca de', N'About'),
 (N'ui.about.003', N'About', N'Descripción de la aplicación.', N'Descripción de la aplicación.', N'Application description.'),
 (N'ui.about.004', N'About', N'Sistema académico para buscar vuelos y gestionar reservas.', N'Sistema académico para buscar vuelos y gestionar reservas.', N'Academic system for searching flights and managing reservations.'),
 (N'ui.contact.001', N'Contact', N'Contacto', N'Contacto', N'Contact'),
 (N'ui.contact.002', N'Contact', N'Contacto', N'Contacto', N'Contact'),
 (N'ui.contact.003', N'Contact', N'Información de contacto.', N'Información de contacto.', N'Contact information.'),
 (N'ui.contact.004', N'Contact', N'Soporte:', N'Soporte:', N'Support:'),
 (N'ui.contact.005', N'Contact', N'Marketing:', N'Marketing:', N'Marketing:'),
 (N'ui.logout.001', N'Logout', N'Logout', N'Logout', N'Sign out'),
 (N'ui.logout.002', N'Logout', N'Logout', N'Logout', N'Sign out'),
 (N'ui.adminvuelos.msg027', N'AdminVuelos', N'Vuelo dado de baja correctamente.', N'Vuelo dado de baja correctamente.', N'Flight deactivated successfully.'),
 (N'ui.adminvuelos.msg028', N'AdminVuelos', N' Reservas canceladas: ', N' Reservas canceladas: ', N' Reservations cancelled: '),
 (N'ui.adminvuelos.msg029', N'AdminVuelos', N'No se encontró el vuelo.', N'No se encontró el vuelo.', N'Flight not found.'),
 (N'ui.adminvuelos.msg030', N'AdminVuelos', N'Error: ', N'Error: ', N'Error: '),
 (N'ui.adminvuelos.msg031', N'AdminVuelos', N'Vuelo creado.', N'Vuelo creado.', N'Flight created.'),
 (N'ui.adminvuelos.msg032', N'AdminVuelos', N'Cierre sesión y vuelva a ingresar para usar el web service.', N'Cierre sesión y vuelva a ingresar para usar el web service.', N'Sign out and sign in again to use the web service.'),
 (N'ui.adminvuelos.msg033', N'AdminVuelos', N'Error al exportar: ', N'Error al exportar: ', N'Export failed: '),
 (N'ui.adminvuelos.msg034', N'AdminVuelos', N'Seleccione un archivo XML.', N'Seleccione un archivo XML.', N'Select an XML file.'),
 (N'ui.adminvuelos.msg035', N'AdminVuelos', N'El archivo supera el máximo de ', N'El archivo supera el máximo de ', N'The file exceeds the maximum size of '),
 (N'ui.adminvuelos.msg036', N'AdminVuelos', N'Error al importar: ', N'Error al importar: ', N'Import failed: '),
 (N'ui.adminvuelos.importacion.resumen', N'AdminVuelos', N'Vuelos en el archivo: {0}. Importados: {1}. Rechazados: {2}.', N'Vuelos en el archivo: {0}. Importados: {1}. Rechazados: {2}.', N'Flights in file: {0}. Imported: {1}. Rejected: {2}.'),
 (N'ui.backup.msg027', N'Backup', N'No se pudo crear/verificar la carpeta en SQL Server. ', N'No se pudo crear/verificar la carpeta en SQL Server. ', N'Could not create or check the folder on SQL Server. '),
 (N'ui.backup.msg028', N'Backup', N'Error al generar backup. ', N'Error al generar backup. ', N'Backup creation failed. '),
 (N'ui.backup.msg029', N'Backup', N'Backup generado, pero no se pudo verificar con RESTORE VERIFYONLY. ', N'Backup generado, pero no se pudo verificar con RESTORE VERIFYONLY. ', N'Backup created, but verification with RESTORE VERIFYONLY failed. '),
 (N'ui.backup.msg030', N'Backup', N'Backup generado y verificado correctamente.', N'Backup generado y verificado correctamente.', N'Backup created and verified successfully.'),
 (N'ui.backup.msg031', N'Backup', N'Backup generado con advertencias de permisos/configuración.', N'Backup generado con advertencias de permisos/configuración.', N'Backup created with permission or configuration warnings.'),
 (N'ui.backup.msg032', N'Backup', N'No se pudo generar el backup.', N'No se pudo generar el backup.', N'Could not create the backup.'),
 (N'ui.backup.msg033', N'Backup', N'Error inesperado al ejecutar backup. ', N'Error inesperado al ejecutar backup. ', N'Unexpected backup error. '),
 (N'ui.backup.msg034', N'Backup', N'Éxito', N'Éxito', N'Success'),
 (N'ui.backup.msg035', N'Backup', N'Advertencia', N'Advertencia', N'Warning'),
 (N'ui.backup.msg036', N'Backup', N'Error', N'Error', N'Error'),
 (N'ui.backup.msg037', N'Backup', N'Restauración completada correctamente con el archivo ', N'Restauración completada correctamente con el archivo ', N'Restoration completed successfully using file '),
 (N'ui.backup.msg038', N'Backup', N'Backup restaurado, pero persisten inconsistencias de integridad. El modo de contingencia permanece activo.', N'Backup restaurado, pero persisten inconsistencias de integridad. El modo de contingencia permanece activo.', N'Backup restored, but integrity inconsistencies remain. Contingency mode is still active.'),
 (N'ui.backup.msg039', N'Backup', N'Error al restaurar backup. ', N'Error al restaurar backup. ', N'Backup restoration failed. '),
 (N'ui.backup.msg040', N'Backup', N'Advertencia: no se pudo asegurar MULTI_USER. ', N'Advertencia: no se pudo asegurar MULTI_USER. ', N'Warning: could not ensure MULTI_USER mode. '),
 (N'ui.backup.msg041', N'Backup', N'No se pudo leer la carpeta de backups: ', N'No se pudo leer la carpeta de backups: ', N'Could not read the backup folder: '),
 (N'ui.backup.msg042', N'Backup', N'Debe seleccionar un archivo de backup de la lista.', N'Debe seleccionar un archivo de backup de la lista.', N'Select a backup file from the list.'),
 (N'ui.backup.msg043', N'Backup', N'Ruta inválida.', N'Ruta inválida.', N'Invalid path.'),
 (N'ui.backup.msg044', N'Backup', N'No se permite usar rutas externas a la carpeta de backups.', N'No se permite usar rutas externas a la carpeta de backups.', N'Paths outside the backup folder are not allowed.'),
 (N'ui.backup.msg045', N'Backup', N'El archivo seleccionado no es un .bak válido.', N'El archivo seleccionado no es un .bak válido.', N'The selected file is not a valid .bak file.'),
 (N'ui.backup.msg046', N'Backup', N'El archivo seleccionado no existe.', N'El archivo seleccionado no existe.', N'The selected file does not exist.'),
 (N'ui.gestionintegridad.msg016', N'GestionIntegridad', N'Validación correcta.', N'Validación correcta.', N'Validation successful.'),
 (N'ui.gestionintegridad.msg017', N'GestionIntegridad', N'Se detectaron inconsistencias. El modo de contingencia permanece activo.', N'Se detectaron inconsistencias. El modo de contingencia permanece activo.', N'Inconsistencies detected. Contingency mode is still active.'),
 (N'ui.gestionintegridad.msg018', N'GestionIntegridad', N'Integridad validada. Modo contingencia desactivado.', N'Integridad validada. Modo contingencia desactivado.', N'Integrity validated. Contingency mode disabled.'),
 (N'ui.gestionintegridad.msg019', N'GestionIntegridad', N'Persisten inconsistencias. No se puede salir de contingencia.', N'Persisten inconsistencias. No se puede salir de contingencia.', N'Inconsistencies remain. Cannot exit contingency mode.'),
 (N'ui.gestionintegridad.msg020', N'GestionIntegridad', N'Recalculo finalizado y validado.', N'Recalculo finalizado y validado.', N'Recalculation completed and validated.'),
 (N'ui.gestionintegridad.msg021', N'GestionIntegridad', N'No se pudo recalcular la integridad: ', N'No se pudo recalcular la integridad: ', N'Could not recalculate integrity: '),
 (N'ui.gestionintegridad.msg022', N'GestionIntegridad', N'Activo', N'Activo', N'Active'),
 (N'ui.gestionintegridad.msg023', N'GestionIntegridad', N'Inactivo', N'Inactivo', N'Inactive'),
 (N'ui.registro.msg010', N'Registro', N'Usuario creado correctamente. Inicie sesión.', N'Usuario creado correctamente. Inicie sesión.', N'User created successfully. Please sign in.'),
 (N'ui.registro.msg011', N'Registro', N'Error al registrar: ', N'Error al registrar: ', N'Registration failed: '),
 (N'ui.vuelos.estado.activo', N'AdminVuelos', N'Activo', N'Activo', N'Active'),
 (N'ui.vuelos.estado.baja', N'AdminVuelos', N'Dado de baja', N'Dado de baja', N'Deactivated'),
 (N'validacion.password.5', N'Validaciones', N'La contraseña debe contener al menos un carácter especial.', N'La contraseña debe contener al menos un carácter especial.', N'The password must contain at least one special character.'),
 (N'validacion.password.4', N'Validaciones', N'La contraseña debe contener al menos un número.', N'La contraseña debe contener al menos un número.', N'The password must contain at least one number.'),
 (N'validacion.password.3', N'Validaciones', N'La contraseña debe contener al menos una letra minúscula.', N'La contraseña debe contener al menos una letra minúscula.', N'The password must contain at least one lowercase letter.'),
 (N'validacion.password.2', N'Validaciones', N'La contraseña debe contener al menos una letra mayúscula.', N'La contraseña debe contener al menos una letra mayúscula.', N'The password must contain at least one uppercase letter.'),
 (N'validacion.password.1', N'Validaciones', N'La contraseña debe tener al menos 8 caracteres.', N'La contraseña debe tener al menos 8 caracteres.', N'The password must contain at least 8 characters.'),
 (N'validacion.general.001', N'Validaciones', N'El vuelo es requerido.', N'El vuelo es requerido.', N'A flight is required.'),
 (N'validacion.general.002', N'Validaciones', N'El origen del vuelo es requerido.', N'El origen del vuelo es requerido.', N'Flight origin is required.'),
 (N'validacion.general.003', N'Validaciones', N'El destino del vuelo es requerido.', N'El destino del vuelo es requerido.', N'Flight destination is required.'),
 (N'validacion.general.004', N'Validaciones', N'El origen y destino del vuelo deben ser diferentes.', N'El origen y destino del vuelo deben ser diferentes.', N'Flight origin and destination must be different.'),
 (N'validacion.general.005', N'Validaciones', N'El precio del vuelo no puede ser negativo.', N'El precio del vuelo no puede ser negativo.', N'Flight price cannot be negative.'),
 (N'validacion.general.006', N'Validaciones', N'Los cupos disponibles no pueden ser negativos.', N'Los cupos disponibles no pueden ser negativos.', N'Available seats cannot be negative.'),
 (N'validacion.general.007', N'Validaciones', N'No se pueden crear vuelos con fecha y hora pasada.', N'No se pueden crear vuelos con fecha y hora pasada.', N'Cannot create flights with a departure date and time in the past.'),
 (N'validacion.general.008', N'Validaciones', N'El cliente es inválido.', N'El cliente es inválido.', N'Invalid customer.'),
 (N'validacion.general.009', N'Validaciones', N'El cliente es requerido.', N'El cliente es requerido.', N'A customer is required.'),
 (N'validacion.general.010', N'Validaciones', N'El nombre del cliente es requerido.', N'El nombre del cliente es requerido.', N'Customer name is required.'),
 (N'validacion.general.011', N'Validaciones', N'El email del cliente es requerido.', N'El email del cliente es requerido.', N'Customer email is required.'),
 (N'validacion.general.012', N'Validaciones', N'El pasajero es inválido.', N'El pasajero es inválido.', N'Invalid passenger.'),
 (N'validacion.general.013', N'Validaciones', N'El pasajero es requerido.', N'El pasajero es requerido.', N'A passenger is required.'),
 (N'validacion.general.014', N'Validaciones', N'El nombre del pasajero es requerido.', N'El nombre del pasajero es requerido.', N'Passenger name is required.'),
 (N'validacion.general.015', N'Validaciones', N'El documento del pasajero es requerido.', N'El documento del pasajero es requerido.', N'Passenger document number is required.'),
 (N'validacion.general.016', N'Validaciones', N'Sólo puede crear reservas para su propio cliente.', N'Sólo puede crear reservas para su propio cliente.', N'You can only create reservations for your own customer.'),
 (N'validacion.general.017', N'Validaciones', N'El ID del cliente es requerido.', N'El ID del cliente es requerido.', N'Customer ID is required.'),
 (N'validacion.general.018', N'Validaciones', N'Debe seleccionar al menos un vuelo.', N'Debe seleccionar al menos un vuelo.', N'Select at least one flight.'),
 (N'validacion.general.019', N'Validaciones', N'Debe registrar al menos un pasajero.', N'Debe registrar al menos un pasajero.', N'Register at least one passenger.'),
 (N'validacion.general.020', N'Validaciones', N'El usuario actual es requerido.', N'El usuario actual es requerido.', N'The current user is required.'),
 (N'validacion.general.021', N'Validaciones', N'La cantidad de pasajeros debe ser mayor o igual a 1.', N'La cantidad de pasajeros debe ser mayor o igual a 1.', N'The number of passengers must be at least 1.'),
 (N'validacion.general.022', N'Validaciones', N'La cantidad de pasajeros de la reserva no coincide con los pasajeros cargados.', N'La cantidad de pasajeros de la reserva no coincide con los pasajeros cargados.', N'The reservation passenger count does not match the registered passengers.'),
 (N'validacion.general.023', N'Validaciones', N'El precio unitario no puede ser negativo.', N'El precio unitario no puede ser negativo.', N'Unit price cannot be negative.'),
 (N'validacion.general.024', N'Validaciones', N'El subtotal de la reserva es inválido.', N'El subtotal de la reserva es inválido.', N'Invalid reservation subtotal.'),
 (N'validacion.general.025', N'Validaciones', N'Usuario inválido para cancelar la reserva.', N'Usuario inválido para cancelar la reserva.', N'Invalid user for cancelling the reservation.'),
 (N'validacion.general.026', N'Validaciones', N'Ingrese el nombre del perfil.', N'Ingrese el nombre del perfil.', N'Enter a profile name.'),
 (N'validacion.general.027', N'Validaciones', N'El nombre del perfil admite hasta {0} caracteres.', N'El nombre del perfil admite hasta {0} caracteres.', N'Profile names can contain up to {0} characters.'),
 (N'validacion.general.028', N'Validaciones', N'El nombre del perfil sólo admite letras, números, espacios, guiones y guiones bajos.', N'El nombre del perfil sólo admite letras, números, espacios, guiones y guiones bajos.', N'Profile names may contain only letters, numbers, spaces, hyphens and underscores.'),
 (N'validacion.general.029', N'Validaciones', N'Ya existe un perfil o permiso con ese nombre.', N'Ya existe un perfil o permiso con ese nombre.', N'A profile or permission with that name already exists.'),
 (N'validacion.general.030', N'Validaciones', N'El permiso seleccionado no existe.', N'El permiso seleccionado no existe.', N'The selected permission does not exist.'),
 (N'validacion.general.031', N'Validaciones', N'No se puede agregar {0} a {1} porque ya lo contiene (se formaría un ciclo).', N'No se puede agregar {0} a {1} porque ya lo contiene (se formaría un ciclo).', N'Cannot add {0} to {1} because it already contains it (this would create a cycle).'),
 (N'validacion.general.032', N'Validaciones', N'{0} ya tiene asignado {1}.', N'{0} ya tiene asignado {1}.', N'{0} already has {1} assigned.'),
 (N'validacion.general.033', N'Validaciones', N'No se puede agregar {0} a {1} porque se formaría un ciclo.', N'No se puede agregar {0} a {1} porque se formaría un ciclo.', N'Cannot add {0} to {1} because this would create a cycle.'),
 (N'validacion.general.034', N'Validaciones', N'Un permiso simple no puede contener otros permisos.', N'Un permiso simple no puede contener otros permisos.', N'A simple permission cannot contain other permissions.'),
 (N'validacion.general.035', N'Validaciones', N'El permiso no está asignado a {0}.', N'El permiso no está asignado a {0}.', N'The permission is not assigned to {0}.'),
 (N'validacion.general.036', N'Validaciones', N'No se puede quitar {0} de {1}: su propio perfil perdería el acceso a la administración de perfiles.', N'No se puede quitar {0} de {1}: su propio perfil perdería el acceso a la administración de perfiles.', N'Cannot remove {0} from {1}: your own profile would lose access to profile management.'),
 (N'validacion.general.037', N'Validaciones', N'No se puede eliminar {0}: está asignado a {1} usuario(s).', N'No se puede eliminar {0}: está asignado a {1} usuario(s).', N'Cannot delete {0}: it is assigned to {1} user(s).'),
 (N'validacion.general.038', N'Validaciones', N'No se puede eliminar {0}: está asignado a usuarios.', N'No se puede eliminar {0}: está asignado a usuarios.', N'Cannot delete {0}: it is assigned to users.'),
 (N'validacion.general.039', N'Validaciones', N'El perfil seleccionado no existe.', N'El perfil seleccionado no existe.', N'The selected profile does not exist.'),
 (N'validacion.general.040', N'Validaciones', N'Debe iniciar sesión.', N'Debe iniciar sesión.', N'Please sign in.'),
 (N'validacion.general.041', N'Validaciones', N'No puede cambiar su propio rol.', N'No puede cambiar su propio rol.', N'You cannot change your own role.'),
 (N'validacion.general.042', N'Validaciones', N'El usuario no existe.', N'El usuario no existe.', N'The user does not exist.'),
 (N'validacion.general.043', N'Validaciones', N'{0} ya tiene el rol {1}.', N'{0} ya tiene el rol {1}.', N'{0} already has the role {1}.'),
 (N'validacion.general.044', N'Validaciones', N'El usuario fue modificado mientras tanto. Vuelva a cargar la lista e intente de nuevo.', N'El usuario fue modificado mientras tanto. Vuelva a cargar la lista e intente de nuevo.', N'The user has changed. Refresh the list and try again.'),
 (N'validacion.general.045', N'Validaciones', N'Usuario o contraseña incorrectos.', N'Usuario o contraseña incorrectos.', N'Incorrect email or password.'),
 (N'validacion.general.046', N'Validaciones', N'Indique al menos un vuelo.', N'Indique al menos un vuelo.', N'Select at least one flight.'),
 (N'validacion.general.047', N'Validaciones', N'La cantidad de pasajeros debe ser mayor a cero.', N'La cantidad de pasajeros debe ser mayor a cero.', N'The number of passengers must be greater than zero.'),
 (N'validacion.general.048', N'Validaciones', N'No existe el vuelo {0}.', N'No existe el vuelo {0}.', N'Flight {0} does not exist.'),
 (N'validacion.general.049', N'Validaciones', N'El vuelo {0} está dado de baja.', N'El vuelo {0} está dado de baja.', N'Flight {0} is deactivated.'),
 (N'validacion.general.050', N'Validaciones', N'El XML está vacío.', N'El XML está vacío.', N'The XML file is empty.'),
 (N'validacion.general.051', N'Validaciones', N'El XML supera el máximo de {0} KB.', N'El XML supera el máximo de {0} KB.', N'The XML exceeds the maximum size of {0} KB.'),
 (N'validacion.general.052', N'Validaciones', N'El elemento raíz debe ser <vuelos>.', N'El elemento raíz debe ser <vuelos>.', N'The root element must be <vuelos>.'),
 (N'validacion.general.053', N'Validaciones', N'Hay un dato con formato inválido (fecha yyyy-MM-dd, hora HH:mm, precio y cupos numéricos).', N'Hay un dato con formato inválido (fecha yyyy-MM-dd, hora HH:mm, precio y cupos numéricos).', N'Invalid data format (date yyyy-MM-dd, time HH:mm, numeric price and seat count).'),
 (N'validacion.general.054', N'Validaciones', N'Falta el campo <{0}>.', N'Falta el campo <{0}>.', N'Missing field <{0}>.'),
 (N'validacion.general.055', N'Validaciones', N'Vuelo {0}: {1}', N'Vuelo {0}: {1}', N'Flight {0}: {1}'),
 (N'validacion.general.056', N'Validaciones', N'El archivo no es un XML válido: {0}', N'El archivo no es un XML válido: {0}', N'The file is not valid XML: {0}'),
 (N'validacion.general.057', N'Validaciones', N'Token inválido o vencido. Inicie sesión nuevamente.', N'Token inválido o vencido. Inicie sesión nuevamente.', N'Invalid or expired token. Please sign in again.'),
 (N'validacion.general.058', N'Validaciones', N'No tiene permiso para esta operación.', N'No tiene permiso para esta operación.', N'You do not have permission for this operation.'),
 (N'validacion.general.059', N'Validaciones', N'Operación no disponible durante contingencia.', N'Operación no disponible durante contingencia.', N'This operation is unavailable in contingency mode.'),
 (N'ui.bitacora.criticidad.1', N'Bitacora', N'1 - Información', N'1 - Información', N'1 - Information'),
 (N'ui.bitacora.criticidad.2', N'Bitacora', N'2 - Advertencia', N'2 - Advertencia', N'2 - Warning'),
 (N'ui.bitacora.criticidad.3', N'Bitacora', N'3 - Error', N'3 - Error', N'3 - Error'),
 (N'ui.bitacora.criticidad.4', N'Bitacora', N'4 - Crítica', N'4 - Crítica', N'4 - Critical');
INSERT dbo.Etiqueta (Clave, Pantalla, Descripcion)
SELECT s.Clave, s.Pantalla, LEFT(s.Descripcion, 200) FROM @Textos s
WHERE NOT EXISTS (SELECT 1 FROM dbo.Etiqueta e WHERE e.Clave = s.Clave);
INSERT dbo.Traduccion (IdIdioma, IdEtiqueta, Texto)
SELECT i.IdIdioma, e.IdEtiqueta, CASE i.Codigo WHEN N'es-AR' THEN s.Es ELSE s.En END
FROM @Textos s JOIN dbo.Etiqueta e ON e.Clave = s.Clave
JOIN dbo.Idioma i ON i.Codigo IN (N'es-AR', N'en-US')
WHERE NOT EXISTS (SELECT 1 FROM dbo.Traduccion t WHERE t.IdIdioma = i.IdIdioma AND t.IdEtiqueta = e.IdEtiqueta);
COMMIT;
GO
-- END MigracionIdiomasCompletar.sql

-- BEGIN MigracionGrillasIntegridad.sql
USE ReservaVuelosDB;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
-- Filtros traducibles. No reemplaza textos editados.
DECLARE @Filtros TABLE (Clave nvarchar(100), Es nvarchar(500), En nvarchar(500));
INSERT @Filtros VALUES (N'grillas.buscar', N'Buscar en la tabla', N'Search table'), (N'grillas.filtrar', N'Filtrar', N'Filter'), (N'grillas.limpiar', N'Limpiar', N'Clear'), (N'grillas.fecha', N'Fecha', N'Date'), (N'grillas.estado', N'Estado', N'Status'), (N'grillas.activo', N'Activo', N'Active'), (N'grillas.resuelto', N'Resuelto', N'Resolved');
INSERT dbo.Etiqueta(Clave,Pantalla,Descripcion) SELECT Clave,N'Grillas',Es FROM @Filtros f WHERE NOT EXISTS(SELECT 1 FROM dbo.Etiqueta e WHERE e.Clave=f.Clave);
INSERT dbo.Traduccion(IdIdioma,IdEtiqueta,Texto) SELECT i.IdIdioma,e.IdEtiqueta,CASE i.Codigo WHEN N'es-AR' THEN f.Es ELSE f.En END FROM @Filtros f JOIN dbo.Etiqueta e ON e.Clave=f.Clave JOIN dbo.Idioma i ON i.Codigo IN(N'es-AR',N'en-US') WHERE NOT EXISTS(SELECT 1 FROM dbo.Traduccion t WHERE t.IdIdioma=i.IdIdioma AND t.IdEtiqueta=e.IdEtiqueta);
GO
USE ReservaVuelosDB;
GO
SET XACT_ABORT ON;
GO
CREATE OR ALTER FUNCTION dbo.CalcularDVHAmpliado(@texto nvarchar(max)) RETURNS int AS
BEGIN
 DECLARE @i int=1,@n int=DATALENGTH(@texto)/2,@s bigint=0,@p int;
 WHILE @i<=@n
 BEGIN
  SET @p=CASE (@i-1)%25 WHEN 0 THEN 2 WHEN 1 THEN 3 WHEN 2 THEN 5 WHEN 3 THEN 7 WHEN 4 THEN 11 WHEN 5 THEN 13 WHEN 6 THEN 17 WHEN 7 THEN 19 WHEN 8 THEN 23 WHEN 9 THEN 29 WHEN 10 THEN 31 WHEN 11 THEN 37 WHEN 12 THEN 41 WHEN 13 THEN 43 WHEN 14 THEN 47 WHEN 15 THEN 53 WHEN 16 THEN 59 WHEN 17 THEN 61 WHEN 18 THEN 67 WHEN 19 THEN 71 WHEN 20 THEN 73 WHEN 21 THEN 79 WHEN 22 THEN 83 WHEN 23 THEN 89 ELSE 97 END;
  SET @s=@s+CONVERT(bigint,UNICODE(SUBSTRING(@texto COLLATE Latin1_General_100_BIN2,@i,1)))*@p*@i;
  SET @i=@i+1;
 END;
 RETURN CONVERT(int,@s%251);
END;
GO
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.Idioma','DVH') IS NULL ALTER TABLE dbo.Idioma ADD DVH int NOT NULL CONSTRAINT DF_Idioma_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Idioma AS SELECT CONVERT(nvarchar(100),IdIdioma) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdIdioma]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Codigo]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Nombre]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[EsDefault]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Activo]),N'')))) AS Calculado FROM dbo.Idioma;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Idioma')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Idioma') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Idioma t JOIN dbo.DV_Idioma v ON v.IdRegistro=CONVERT(nvarchar(100),IdIdioma);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Idioma',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Idioma;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Idioma',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Idioma;
END;
GO
IF COL_LENGTH('dbo.Etiqueta','DVH') IS NULL ALTER TABLE dbo.Etiqueta ADD DVH int NOT NULL CONSTRAINT DF_Etiqueta_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Etiqueta AS SELECT CONVERT(nvarchar(100),IdEtiqueta) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdEtiqueta]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Clave]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Pantalla]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Descripcion]),N'')))) AS Calculado FROM dbo.Etiqueta;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Etiqueta')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Etiqueta') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Etiqueta t JOIN dbo.DV_Etiqueta v ON v.IdRegistro=CONVERT(nvarchar(100),IdEtiqueta);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Etiqueta',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Etiqueta;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Etiqueta',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Etiqueta;
END;
GO
IF COL_LENGTH('dbo.Traduccion','DVH') IS NULL ALTER TABLE dbo.Traduccion ADD DVH int NOT NULL CONSTRAINT DF_Traduccion_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Traduccion AS SELECT CONVERT(nvarchar(100),CONCAT(IdIdioma, ':', IdEtiqueta)) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdIdioma]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdEtiqueta]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Texto]),N'')))) AS Calculado FROM dbo.Traduccion;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Traduccion')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Traduccion') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Traduccion t JOIN dbo.DV_Traduccion v ON v.IdRegistro=CONVERT(nvarchar(100),CONCAT(IdIdioma, ':', IdEtiqueta));
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Traduccion',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Traduccion;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Traduccion',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Traduccion;
END;
GO
IF COL_LENGTH('dbo.Permisos','DVH') IS NULL ALTER TABLE dbo.Permisos ADD DVH int NOT NULL CONSTRAINT DF_Permisos_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_Permisos AS SELECT CONVERT(nvarchar(100),IdPermiso) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdPermiso]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Codigo]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[EsGrupo]),N'')))) AS Calculado FROM dbo.Permisos;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Permisos')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'Permisos') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.Permisos t JOIN dbo.DV_Permisos v ON v.IdRegistro=CONVERT(nvarchar(100),IdPermiso);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Permisos',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_Permisos;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'Permisos',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.Permisos;
END;
GO
IF COL_LENGTH('dbo.PermisoRelacion','DVH') IS NULL ALTER TABLE dbo.PermisoRelacion ADD DVH int NOT NULL CONSTRAINT DF_PermisoRelacion_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_PermisoRelacion AS SELECT CONVERT(nvarchar(100),CONCAT(IdPadre, ':', IdHijo)) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdPadre]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdHijo]),N'')))) AS Calculado FROM dbo.PermisoRelacion;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'PermisoRelacion')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'PermisoRelacion') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.PermisoRelacion t JOIN dbo.DV_PermisoRelacion v ON v.IdRegistro=CONVERT(nvarchar(100),CONCAT(IdPadre, ':', IdHijo));
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'PermisoRelacion',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_PermisoRelacion;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'PermisoRelacion',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.PermisoRelacion;
END;
GO
IF COL_LENGTH('dbo.ConfiguracionSistema','DVH') IS NULL ALTER TABLE dbo.ConfiguracionSistema ADD DVH int NOT NULL CONSTRAINT DF_ConfiguracionSistema_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_ConfiguracionSistema AS SELECT CONVERT(nvarchar(100),IdConfiguracion) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdConfiguracion]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[ModoContingencia]),N'')))+N'|'+ISNULL(CONVERT(nvarchar(19),[FechaUltimaValidacion],126),N'')+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[MotivoContingencia]),N'')))) AS Calculado FROM dbo.ConfiguracionSistema;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'ConfiguracionSistema')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'ConfiguracionSistema') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.ConfiguracionSistema t JOIN dbo.DV_ConfiguracionSistema v ON v.IdRegistro=CONVERT(nvarchar(100),IdConfiguracion);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'ConfiguracionSistema',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_ConfiguracionSistema;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'ConfiguracionSistema',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.ConfiguracionSistema;
END;
GO
IF COL_LENGTH('dbo.IntegridadError','DVH') IS NULL ALTER TABLE dbo.IntegridadError ADD DVH int NOT NULL CONSTRAINT DF_IntegridadError_DVH DEFAULT(0);
GO
CREATE OR ALTER VIEW dbo.DV_IntegridadError AS SELECT CONVERT(nvarchar(100),IdError) AS IdRegistro,dbo.CalcularDVHAmpliado(LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdError]),N'')))+N'|'+ISNULL(CONVERT(nvarchar(19),[Fecha],126),N'')+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[TipoError]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[TipoOperacion]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[NombreTabla]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdRegistroAfectado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[ValorEsperado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[ValorCalculado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[Estado]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[IdUsuarioAdministrador]),N'')))+N'|'+LTRIM(RTRIM(ISNULL(CONVERT(nvarchar(max),[AccionTomada]),N'')))) AS Calculado FROM dbo.IntegridadError;
GO
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Usuarios') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'IntegridadError')
BEGIN
 IF EXISTS(SELECT 1 FROM dbo.IntegridadRegistro WHERE NombreTabla=N'IntegridadError') THROW 50040,'Falta el DVV de una tabla ya protegida; revisar integridad.',1;
 UPDATE t SET DVH=v.Calculado FROM dbo.IntegridadError t JOIN dbo.DV_IntegridadError v ON v.IdRegistro=CONVERT(nvarchar(100),IdError);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'IntegridadError',IdRegistro,Calculado,SYSDATETIME() FROM dbo.DV_IntegridadError;
 INSERT dbo.IntegridadDVV(NombreTabla,ValorDVV,FechaCalculo) SELECT N'IntegridadError',ISNULL(SUM(CONVERT(bigint,DVH)),0),SYSDATETIME() FROM dbo.IntegridadError;
END;
GO
COMMIT;
GO
BEGIN TRANSACTION;
DECLARE @CambiosEtiqueta int=0,@CambiosTraduccion int=0;
IF EXISTS(SELECT 1 FROM dbo.IntegridadDVV WHERE NombreTabla=N'Etiqueta')
BEGIN
 UPDATE e SET DVH=v.Calculado FROM dbo.Etiqueta e JOIN dbo.DV_Etiqueta v ON v.IdRegistro=CONVERT(nvarchar(100),e.IdEtiqueta) WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Etiqueta' AND r.IdRegistro=v.IdRegistro);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Etiqueta',v.IdRegistro,v.Calculado,SYSDATETIME() FROM dbo.DV_Etiqueta v JOIN dbo.Etiqueta e ON CONVERT(nvarchar(100),e.IdEtiqueta)=v.IdRegistro WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Etiqueta' AND r.IdRegistro=v.IdRegistro);
 SET @CambiosEtiqueta=@@ROWCOUNT;
 UPDATE t SET DVH=v.Calculado FROM dbo.Traduccion t JOIN dbo.DV_Traduccion v ON v.IdRegistro=CONCAT(t.IdIdioma,':',t.IdEtiqueta) JOIN dbo.Etiqueta e ON e.IdEtiqueta=t.IdEtiqueta WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Traduccion' AND r.IdRegistro=v.IdRegistro);
 INSERT dbo.IntegridadRegistro(NombreTabla,IdRegistro,ValorDVH,FechaCalculo) SELECT N'Traduccion',v.IdRegistro,v.Calculado,SYSDATETIME() FROM dbo.DV_Traduccion v JOIN dbo.Traduccion t ON CONCAT(t.IdIdioma,':',t.IdEtiqueta)=v.IdRegistro JOIN dbo.Etiqueta e ON e.IdEtiqueta=t.IdEtiqueta WHERE e.Clave IN(N'grillas.buscar',N'grillas.filtrar',N'grillas.limpiar',N'grillas.fecha',N'grillas.estado',N'grillas.activo',N'grillas.resuelto') AND NOT EXISTS(SELECT 1 FROM dbo.IntegridadRegistro r WHERE r.NombreTabla=N'Traduccion' AND r.IdRegistro=v.IdRegistro);
 SET @CambiosTraduccion=@@ROWCOUNT;
 UPDATE dbo.IntegridadDVV SET ValorDVV=(SELECT ISNULL(SUM(CONVERT(bigint,DVH)),0) FROM dbo.Etiqueta) WHERE NombreTabla=N'Etiqueta' AND @CambiosEtiqueta>0;
 UPDATE dbo.IntegridadDVV SET ValorDVV=(SELECT ISNULL(SUM(CONVERT(bigint,DVH)),0) FROM dbo.Traduccion) WHERE NombreTabla=N'Traduccion' AND @CambiosTraduccion>0;
END;
COMMIT;
GO
-- END MigracionGrillasIntegridad.sql

-- BEGIN ActivarTDE.sql
-- TDE opcional. Configurar SESSION_CONTEXT en la misma conexión antes de ejecutar.
-- No guardar contraseñas ni archivos .cer/.pvk en el repositorio.
USE master;
GO
IF ISNULL(TRY_CONVERT(bit, SESSION_CONTEXT(N'ReservaVuelos.ActivarTDE')), 0) = 1
BEGIN
    DECLARE @Edicion int = CONVERT(int, SERVERPROPERTY('EngineEdition'));
    DECLARE @Version int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
    IF NOT (@Edicion = 3 OR (@Edicion = 2 AND @Version >= 15))
        THROW 50100, 'Esta edición/version de SQL Server no está contemplada para TDE.', 1;
    IF DB_ID(N'ReservaVuelosDB') IS NULL
        THROW 50101, 'La base ReservaVuelosDB debe existir antes de activar TDE.', 1;

    DECLARE @ClaveMaestra nvarchar(128) = CONVERT(nvarchar(128), SESSION_CONTEXT(N'ReservaVuelos.ClaveMaestraTDE'));
    DECLARE @ClaveRespaldo nvarchar(128) = CONVERT(nvarchar(128), SESSION_CONTEXT(N'ReservaVuelos.ClaveRespaldoTDE'));
    DECLARE @RutaCertificado nvarchar(4000) = CONVERT(nvarchar(4000), SESSION_CONTEXT(N'ReservaVuelos.RutaCertificadoTDE'));
    DECLARE @RutaPrivada nvarchar(4000) = CONVERT(nvarchar(4000), SESSION_CONTEXT(N'ReservaVuelos.RutaPrivadaTDE'));
    DECLARE @Sql nvarchar(max);

    IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'##MS_DatabaseMasterKey##')
    BEGIN
        IF NULLIF(@ClaveMaestra, N'') IS NULL
            THROW 50102, 'Falta ClaveMaestraTDE para crear la clave maestra de master.', 1;
        SET @Sql = N'CREATE MASTER KEY ENCRYPTION BY PASSWORD = ' + QUOTENAME(@ClaveMaestra, '''') + N';';
        EXEC sys.sp_executesql @Sql;
    END;

    IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'CertificadoTDE_ReservaVuelos')
        EXEC(N'CREATE CERTIFICATE CertificadoTDE_ReservaVuelos WITH SUBJECT = ''TDE ReservaVuelosDB'';');

    -- Respaldo obligatorio antes de crear/activar la DEK. No sobreescribe archivos.
    IF EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'CertificadoTDE_ReservaVuelos' AND (pvt_key_last_backup_date IS NULL OR ISNULL(TRY_CONVERT(bit,SESSION_CONTEXT(N'ReservaVuelos.RespaldarTDE')),0)=1))
    BEGIN
        IF NULLIF(@ClaveRespaldo, N'') IS NULL OR NULLIF(@RutaCertificado, N'') IS NULL OR NULLIF(@RutaPrivada, N'') IS NULL
            THROW 50103, 'Configurar la contraseña y rutas del respaldo del certificado y clave privada TDE.', 1;
        SET @Sql = N'BACKUP CERTIFICATE CertificadoTDE_ReservaVuelos TO FILE = N''' + REPLACE(@RutaCertificado, '''', '''''') +
            N''' WITH PRIVATE KEY (FILE = N''' + REPLACE(@RutaPrivada, '''', '''''') +
            N''', ENCRYPTION BY PASSWORD = ' + QUOTENAME(@ClaveRespaldo, '''') + N');';
        EXEC sys.sp_executesql @Sql;
    END;

    DECLARE @Huella varbinary(64) = (SELECT thumbprint FROM sys.certificates WHERE name = N'CertificadoTDE_ReservaVuelos');
    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND encryptor_thumbprint <> @Huella)
        THROW 50104, 'La base ya tiene una clave protegida por otro certificado. No se modificó su configuración TDE.', 1;

    IF NOT EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB'))
        EXEC(N'USE ReservaVuelosDB; CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE CertificadoTDE_ReservaVuelos;');

    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND (key_algorithm <> 'AES' OR key_length <> 256))
        THROW 50106, 'La clave existente no es AES-256. Revisar antes de cambiar su algoritmo.', 1;
    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND encryption_state = 5)
        THROW 50105, 'Hay un descifrado en curso. Esperar antes de activar TDE.', 1;
    IF EXISTS (SELECT 1 FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB') AND encryption_state = 1)
        EXEC(N'ALTER DATABASE ReservaVuelosDB SET ENCRYPTION ON;');

    SELECT DB_NAME(database_id) AS Base, encryption_state AS Estado, percent_complete AS Porcentaje
    FROM sys.dm_database_encryption_keys WHERE database_id = DB_ID(N'ReservaVuelosDB');
    PRINT 'Estado 2: cifrado en curso. Estado 3: cifrado completo. Conservar certificado, clave privada y contraseña fuera del equipo.';
END
ELSE
    PRINT 'TDE omitido: habilitar ReservaVuelos.ActivarTDE en SESSION_CONTEXT para ejecutarlo.';
GO
USE ReservaVuelosDB;
GO

/*
-- CONSULTA PARA DEMOSTRAR EL CIFRADO TDE (copiar y ejecutar en SSMS).
-- Se deja comentada: no se ejecuta con el script.
SELECT
    DB_NAME(database_id) AS BaseDeDatos,
    CASE encryption_state
        WHEN 2 THEN 'Cifrado en curso'
        WHEN 3 THEN 'Cifrado completo'
        ELSE 'Otro estado'
    END AS Estado,
    key_algorithm AS Algoritmo,
    key_length AS Bits
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID(N'ReservaVuelosDB');
-- Resultado esperado: ReservaVuelosDB | Cifrado completo | AES | 256.
*/
-- END ActivarTDE.sql
