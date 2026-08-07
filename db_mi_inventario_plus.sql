
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'db_mi_inventario_plus_web')
BEGIN
    CREATE DATABASE db_mi_inventario_plus_web;
END
GO

USE db_mi_inventario_plus_web;
GO

-- ============================================================
-- TABLAS
-- ============================================================
CREATE TABLE Categoria (
    CategoriaId      INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria  VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Categoria_Nombre UNIQUE (NombreCategoria)
);
GO


CREATE TABLE Usuario (
    UsuarioId        INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario    VARCHAR(100) NOT NULL,
    ApellidoUsuario  VARCHAR(100) NOT NULL,
    CorreoUsuario    VARCHAR(150) NOT NULL,
    Contrasenia      VARCHAR(100) NOT NULL,
    Rol              VARCHAR(20) NOT NULL DEFAULT 'Operador',
    CONSTRAINT UQ_Usuario_NombreUsuario UNIQUE (NombreUsuario),
    CONSTRAINT UQ_Usuario_Correo UNIQUE (CorreoUsuario),
    CONSTRAINT CK_Usuario_Rol CHECK (Rol IN ('Admin', 'Operador'))
);
GO

CREATE TABLE Producto (
    ProductoId           INT IDENTITY(1,1) PRIMARY KEY,
    NombreProducto       VARCHAR(150) NOT NULL,
    DescripcionProducto  VARCHAR(500) NULL,
    Precio               DECIMAL(10,2) NOT NULL,
    Stock                INT NOT NULL DEFAULT 0,
    CategoriaId          INT NOT NULL,
    ImagenUrl            VARCHAR(300) NULL,
    Activo               BIT NOT NULL DEFAULT 1,
    FechaCreacion        DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Producto_Categoria FOREIGN KEY (CategoriaId)
        REFERENCES Categoria(CategoriaId),
    CONSTRAINT CK_Producto_Precio CHECK (Precio > 0),
    CONSTRAINT CK_Producto_Stock CHECK (Stock >= 0)
);
GO

CREATE INDEX IX_Producto_CategoriaId ON Producto(CategoriaId);
GO

CREATE TABLE Movimiento (
    MovimientoId    INT IDENTITY(1,1) PRIMARY KEY,
    ProductoId      INT NOT NULL,
    UsuarioId       INT NOT NULL,
    TipoMovimiento  VARCHAR(10) NOT NULL,
    Cantidad        INT NOT NULL,
    Motivo          VARCHAR(200) NULL,
    Fecha           DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Movimiento_Producto FOREIGN KEY (ProductoId)
        REFERENCES Producto(ProductoId),
    CONSTRAINT FK_Movimiento_Usuario FOREIGN KEY (UsuarioId)
        REFERENCES Usuario(UsuarioId),
    CONSTRAINT CK_Movimiento_Tipo CHECK (TipoMovimiento IN ('Entrada', 'Salida')),
    CONSTRAINT CK_Movimiento_Cantidad CHECK (Cantidad > 0)
);
GO

-- Acelera el listado de movimientos por producto y el reporte por rango de fechas
CREATE INDEX IX_Movimiento_ProductoId_Fecha ON Movimiento(ProductoId, Fecha);
GO

-- ============================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ============================================================

CREATE OR ALTER PROCEDURE sp_Categoria_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoriaId, NombreCategoria FROM Categoria ORDER BY NombreCategoria;
END
GO

CREATE OR ALTER PROCEDURE sp_Producto_ListarPaginado
    @Pagina       INT = 1,
    @TamanoPagina INT = 10,
    @Filtro       VARCHAR(150) = NULL,
    @CategoriaId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Inicio INT = (@Pagina - 1) * @TamanoPagina;

    SELECT
        p.ProductoId, p.NombreProducto, p.DescripcionProducto, p.Precio, p.Stock,
        p.CategoriaId, c.NombreCategoria AS CategoriaNombre,
        p.ImagenUrl, p.Activo
    FROM Producto p
    INNER JOIN Categoria c ON c.CategoriaId = p.CategoriaId
    WHERE p.Activo = 1
        AND (@Filtro IS NULL OR p.NombreProducto LIKE '%' + @Filtro + '%')
        AND (@CategoriaId IS NULL OR p.CategoriaId = @CategoriaId)
    ORDER BY p.NombreProducto
    OFFSET @Inicio ROWS FETCH NEXT @TamanoPagina ROWS ONLY;

    SELECT COUNT(*) AS Total
    FROM Producto p
    WHERE p.Activo = 1
        AND (@Filtro IS NULL OR p.NombreProducto LIKE '%' + @Filtro + '%')
        AND (@CategoriaId IS NULL OR p.CategoriaId = @CategoriaId);
END
GO

CREATE OR ALTER PROCEDURE sp_Producto_InsertarActualizar
    @Id           INT = NULL,
    @Nombre       VARCHAR(150),
    @Descripcion  VARCHAR(500) = NULL,
    @Precio       DECIMAL(10,2),
    @Stock        INT,
    @CategoriaId  INT,
    @ImagenUrl    VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id IS NULL OR @Id = 0
    BEGIN
        INSERT INTO Producto (NombreProducto, DescripcionProducto, Precio, Stock, CategoriaId, ImagenUrl)
        VALUES (@Nombre, @Descripcion, @Precio, @Stock, @CategoriaId, @ImagenUrl);

        SELECT SCOPE_IDENTITY() AS NuevoId;
    END
    ELSE
    BEGIN
        UPDATE Producto
        SET NombreProducto = @Nombre,
            DescripcionProducto = @Descripcion,
            Precio = @Precio,
            CategoriaId = @CategoriaId,
            ImagenUrl = COALESCE(@ImagenUrl, ImagenUrl)
        WHERE ProductoId = @Id;
    END
END
GO

CREATE OR ALTER PROCEDURE sp_Movimiento_RegistrarConTransaccion
    @ProductoId INT,
    @UsuarioId  INT,
    @Tipo       VARCHAR(10),
    @Cantidad   INT,
    @Motivo     VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @StockActual INT;

    SELECT @StockActual = Stock
    FROM Producto WITH (UPDLOCK, HOLDLOCK)
    WHERE ProductoId = @ProductoId;

    IF @Tipo = 'Salida' AND @StockActual < @Cantidad
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('Stock insuficiente para registrar la salida.', 16, 1);
        RETURN;
    END

    INSERT INTO Movimiento (ProductoId, UsuarioId, TipoMovimiento, Cantidad, Motivo)
    VALUES (@ProductoId, @UsuarioId, @Tipo, @Cantidad, @Motivo);

    UPDATE Producto
    SET Stock = CASE
                    WHEN @Tipo = 'Entrada' THEN Stock + @Cantidad
                    ELSE Stock - @Cantidad
                END
    WHERE ProductoId = @ProductoId;

    COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE sp_Reporte_MovimientosPorRango
    @FechaInicio DATETIME,
    @FechaFin    DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        m.MovimientoId, m.Fecha, m.TipoMovimiento, m.Cantidad, m.Motivo,
        p.NombreProducto AS ProductoNombre,
        u.NombreUsuario
    FROM Movimiento m
    INNER JOIN Producto p ON p.ProductoId = m.ProductoId
    INNER JOIN Usuario u ON u.UsuarioId = m.UsuarioId
    WHERE m.Fecha BETWEEN @FechaInicio AND @FechaFin
    ORDER BY m.Fecha DESC;
END
GO

-- ------------------------------------------------------------
-- sp_Usuario_ValidarLogin
-- Recibe el correo y el HASH de la contraseña (el hash se calcula
-- en C#, nunca se compara la contraseña en texto plano)
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_Usuario_ValidarLogin
    @CorreoUsuario   VARCHAR(150),
    @ContraseniaHash VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT UsuarioId, NombreUsuario, ApellidoUsuario, CorreoUsuario, Rol
    FROM Usuario
    WHERE CorreoUsuario = @CorreoUsuario
      AND Contrasenia = @ContraseniaHash;
END
GO

-- ------------------------------------------------------------
-- sp_Usuario_Registrar
-- Devuelve -1 si el correo ya existe, o el nuevo Id si se creó
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_Usuario_Registrar
    @NombreUsuario   VARCHAR(100),
    @ApellidoUsuario VARCHAR(100),
    @CorreoUsuario   VARCHAR(150),
    @ContraseniaHash VARCHAR(100),
    @Rol             VARCHAR(20) = 'Operador'
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Usuario WHERE CorreoUsuario = @CorreoUsuario)
    BEGIN
        SELECT -1 AS NuevoId;
        RETURN;
    END

    INSERT INTO Usuario (NombreUsuario, ApellidoUsuario, CorreoUsuario, Contrasenia, Rol)
    VALUES (@NombreUsuario, @ApellidoUsuario, @CorreoUsuario, @ContraseniaHash, @Rol);

    SELECT SCOPE_IDENTITY() AS NuevoId;
END
GO

/*
ALTER DATABASE db_mi_inventario_plus_web SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
DROP DATABASE db_mi_inventario_plus_web;
GO
*/