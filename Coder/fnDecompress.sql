
--********************************************************************************************************
-- * Author: Prathyusha M
-- * Create Date: Aug 3 2016
-- * Rave Version Developed For:
-- * URL: 
-- * Module: 
--	 DT# (if applicable): 
--********************************************************************************************************

/**********************************************************************************************************
 *Description: Decompress ODMs for generating composite key on coder and comparing with Rave values
***********************************************************************************************************/

-------------------------------------------------------
--STEP 1: Add assembly to the database
-------------------------------------------------------

Declare @location Varchar(1000) ='C:\Medidata.SQLCLR.dll' 
CREATE ASSEMBLY [Medidata.SQLCLR] from @location WITH PERMISSION_SET = SAFE

--------------------------------------------------------------------
--STEP 2: Create a user defined function that calls the CLR Function
---------------------------------------------------------------------

/****** Object:  UserDefinedFunction [dbo].[Decompress]    Script Date: 5/19/2016 1:38:09 PM ******/

IF EXISTS (SELECT * FROM sysobjects  WHERE id = object_id(N'dbo.Decompress') and type = 'FS')
	DROP FUNCTION [dbo].[Decompress]
	

/****** Object:  UserDefinedFunction [dbo].[Decompress]    Script Date: 5/19/2016 1:38:09 PM ******/
SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.Decompress( @deflated nvarchar(max) )
RETURNS nvarchar(max)
AS
EXTERNAL NAME [Medidata.SQLCLR].[Medidata.SQLCLR.UserDefinedFunctions].Decompress
GO
