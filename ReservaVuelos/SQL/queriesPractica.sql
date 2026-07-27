select * from Usuarios

select * from Vuelos

select * from Pasajeros

select * from Usuarios

select * from IntegridadDVV

update Usuarios
set rol = 'Administrador'
where IdUsuario = 3

SELECT v.IdVuelo, v.Origen, v.Destino, v.FechaSalida
FROM dbo.Vuelos v
WHERE NOT EXISTS (SELECT 1 FROM dbo.ReservaDetalle rd WHERE rd.IdVuelo = v.IdVuelo)
ORDER BY v.IdVuelo;

-- 1) Agregar un usuario directamente por SQL (sin pasar por la app: el DVH
--    queda en 0 por defecto, no en el valor que le correspondería).
INSERT INTO dbo.Usuarios (Nombre, Email, PasswordHash, PasswordSalt, Rol, Activo, FechaAlta)
VALUES (N'Usuario De Prueba', N'prueba.contingencia@test.com', N'hash-ficticio', N'salt-ficticio', N'Usuario', 1, GETDATE());

-- 2) Eliminar un vuelo directamente por SQL (poné un IdVuelo de la consulta anterior)
DELETE FROM dbo.Vuelos WHERE IdVuelo = 2;

-- 2) Actualizar vuelo
UPDATE dbo.Vuelos
SET Precio = Precio + 100
WHERE IdVuelo = 99; --