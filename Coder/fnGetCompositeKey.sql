
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'FN' AND name = 'fnGetCompositeKey')
	DROP FUNCTION dbo.fnGetCompositeKey
GO
CREATE FUNCTION dbo.fnGetCompositeKey
(
	@SourceSubject			NVARCHAR(50),
	@SourceFormField		VARCHAR(101),
	@Event					VARCHAR(50),
	@SiteNumber				NVARCHAR(50),

	@Line					INT,
	--@StudyEventRepeatKey	INT,
	@StudyEventRepeatKey	VARCHAR(255),
	@FormRepeatKey			INT
)
RETURNS NVARCHAR(265)
WITH SCHEMABINDING
AS
BEGIN

    RETURN 
		LTRIM(RTRIM(ISNULL(@SourceSubject       , '')))+' '+
		LTRIM(RTRIM(ISNULL(@SourceFormField     , '')))+' '+
		LTRIM(RTRIM(ISNULL(@Event               , '')))+' '+
		LTRIM(RTRIM(ISNULL(@SiteNumber          , '')))
		+ CAST(@Line AS VARCHAR) 
		--+ CAST(@StudyEventRepeatKey AS VARCHAR) 
		+ @StudyEventRepeatKey
		+ CAST(@FormRepeatKey AS VARCHAR)

END