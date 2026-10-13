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
-- Los vuelos se insertan con DVH = 0 porque contienen fechas relativas a GETDATE().
-- En el primer inicio de la aplicacion, IntegrityService detecta IntegridadDVV vacia,
-- recalcula todos los DVH con el algoritmo centralizado de C# y carga los DVV.
-- Si IntegridadDVV ya tiene registros, la app no acepta los datos automaticamente.
GO
