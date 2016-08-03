
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'FS' AND name = 'Decompress')
	DROP FUNCTION dbo.Decompress
GO


create FUNCTION dbo.Decompress( @deflated nvarchar(max) )
RETURNS nvarchar(max)
AS
EXTERNAL NAME [Medidata.SQLCLR].[Medidata.SQLCLR.UserDefinedFunctions].Decompress
GO
