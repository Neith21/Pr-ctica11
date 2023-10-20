CREATE DATABASE Paqueteria21;
GO
USE Paqueteria21;
GO

--TABLAS--

CREATE TABLE Clientes(
	id_cliente INT PRIMARY KEY IDENTITY(1, 1),
	nombre_cliente NVARCHAR(100),
	correo_electronico NVARCHAR(50),
	telefono INT,
	DUI INT
);
GO
CREATE TABLE Paquetes(
	id_paquete INT PRIMARY KEY IDENTITY(1, 1),
	id_cliente INT FOREIGN KEY REFERENCES Clientes(id_cliente),
	peso_lb FLOAT,
	descripcion NVARCHAR(250),
	fecha_paquete_dado_a_paqueteria21 DATE
);
GO
CREATE TABLE Envios(
	id_envio NVARCHAR(10) PRIMARY KEY,
	id_paquete INT FOREIGN KEY REFERENCES Paquetes(id_paquete),
	costo FLOAT,
	destino NVARCHAR(100),
	nombre_destinatario NVARCHAR(100),
	entregado BIT
);
GO

--PROCESOS ALMACENADOS PARA INSERT--

CREATE OR ALTER PROCEDURE sp_insert_clientes
	@nombre_cliente NVARCHAR(100),
	@correo_electronico NVARCHAR(50),
	@telefono INT,
	@DUI INT
AS
BEGIN
	INSERT INTO Clientes(nombre_cliente, correo_electronico, telefono, DUI)
	VALUES(@nombre_cliente, @correo_electronico, @telefono, @DUI);
END;
GO

EXEC sp_insert_clientes 'Ariel', 'ariel@email.com', 72004090, 063940586;
GO

CREATE OR ALTER PROCEDURE sp_insert_paquetes
	@id_cliente INT,
	@peso_lb FLOAT,
	@descripcion NVARCHAR(250)
AS
BEGIN
	INSERT INTO Paquetes(id_cliente, peso_lb, descripcion, fecha_paquete_dado_a_paqueteria21)
	VALUES(@id_cliente, @peso_lb, @descripcion, GETDATE());
END;
GO

EXEC sp_insert_paquetes 1, 2.5, 'PC no Gaming';
GO

CREATE OR ALTER PROCEDURE sp_insert_envios
	@id_envio NVARCHAR(10),
	@id_paquete INT,
	@destino NVARCHAR(100),
	@nombre_destinatario NVARCHAR(100)
AS
BEGIN
	INSERT INTO Envios(id_envio, id_paquete, costo, destino, nombre_destinatario, entregado)
	VALUES(@id_envio, @id_paquete, ((SELECT p.peso_lb FROM Paquetes p WHERE id_paquete = @id_paquete) * 3), @destino, @nombre_destinatario, 0);
END;
GO

EXEC sp_insert_envios 'U69TEN', 3, 'San Salvador', 'Pedro';
GO

--PROCESOS ALMACENADOS PARA UPDATE--

CREATE OR ALTER PROCEDURE sp_update_clientes
	@id_cliente INT,
	@nombre_cliente NVARCHAR(100),
	@correo_electronico NVARCHAR(50),
	@telefono INT,
	@DUI INT
AS
BEGIN
	UPDATE Clientes SET nombre_cliente = @nombre_cliente, correo_electronico = @correo_electronico, telefono = @telefono, DUI = @DUI
	WHERE id_cliente = @id_cliente;
END;
GO

EXEC sp_update_clientes 1, 'Cristian', 'ariel@email.com', 72004090, 063940586;
GO

CREATE OR ALTER PROCEDURE sp_update_paquetes
	@id_paquete INT,
	@id_cliente INT,
	@peso_lb FLOAT,
	@descripcion NVARCHAR(250)
AS
BEGIN
	UPDATE Paquetes SET id_cliente = @id_cliente, peso_lb = @peso_lb, descripcion = @descripcion
	WHERE id_paquete = @id_paquete;
END;
GO

EXEC sp_update_paquetes 2, 1, 2.5, 'PC Gaming';
GO

CREATE OR ALTER PROCEDURE sp_update_envios
	@id_envio NVARCHAR(10),
	@id_paquete INT,
	@destino NVARCHAR(100),
	@nombre_destinatario NVARCHAR(100),
	@entregado BIT
AS
BEGIN
	UPDATE Envios SET id_paquete = @id_paquete, costo = ((SELECT p.peso_lb FROM Paquetes p WHERE id_paquete = @id_paquete) * 3), destino = @destino, nombre_destinatario = @nombre_destinatario, entregado = @entregado
	WHERE id_envio = @id_envio;
END;
GO

EXEC sp_update_envios 'U69OCH', 2, 'San Salvador', 'Juliana', 0;
GO

SELECT * FROM Clientes;
GO
SELECT * FROM Paquetes;
GO
SELECT * FROM Envios;
GO

--CREACIÓN DEL TRIGGER--

CREATE OR ALTER TRIGGER tg_evaluacion_envios
ON Envios
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @cantidad_envios INT;
	SELECT @cantidad_envios = (SELECT COUNT(p.fecha_paquete_dado_a_paqueteria21) 
								FROM Envios e
								INNER JOIN Paquetes p ON e.id_paquete = p.id_paquete
								INNER JOIN Clientes c ON p.id_cliente = c.id_cliente
								WHERE c.id_cliente = (SELECT c.id_cliente FROM inserted i
														INNER JOIN Paquetes p ON i.id_paquete = p.id_paquete
														INNER JOIN Clientes c ON p.id_cliente = c.id_cliente)
								AND CAST(p.fecha_paquete_dado_a_paqueteria21 AS DATE) = CAST(GETDATE() AS DATE));
	IF @cantidad_envios >= 4
	BEGIN
		PRINT 'Capacidad de envíos llenos';
	END;
	ELSE
	BEGIN
		INSERT INTO Envios(id_envio, id_paquete, costo, destino, nombre_destinatario, entregado)
		SELECT id_envio, id_paquete, ((SELECT p.peso_lb FROM Paquetes p WHERE id_paquete = inserted.id_paquete) * 3), destino, nombre_destinatario, 0  FROM inserted
	END;
END;
GO

EXEC sp_insert_envios 'U691a', 5, 'San Salvador', 'Pedro';
GO