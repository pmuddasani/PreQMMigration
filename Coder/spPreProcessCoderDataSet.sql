IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spPreProcessCoderDataSet')
	DROP PROCEDURE dbo.spPreProcessCoderDataSet
GO

-- EXEC spPreProcessCoderDataSet 2

CREATE PROCEDURE dbo.spPreProcessCoderDataSet
(
    @raveToken INT
)
AS
BEGIN

	--IF EXISTS (SELECT NULL FROM sys.indexes
	--	WHERE name = 'IX_PreQMCMP_ToMigrate')
	--	DROP INDEX PreQMCMP.IX_PreQMCMP_ToMigrate

	--TRUNCATE TABLE [dbo].PreQMCMP

	-- Process Coder Data
	;WITH resolvedSDVs AS
	(
		SELECT 
			DISTINCT(RC.StudyDictionaryVersionID) AS StudyDictionaryVersionID
		FROM ctRaveCoderExtract RC
		WHERE raveToken = @raveToken
	)
	,taskSemiMatching AS
	(
		SELECT 
			RC.StudyDictionaryVersionId,
			CE.CodingElementId,
			ISNULL(CE.UUID, '') AS UUID,
			ce.SourceSubject,
			ce.SourceField,
			ce.SourceForm
		FROM resolvedSDVs RC
			JOIN CodingElements CE
				ON ce.StudyDictionaryVersionId = RC.StudyDictionaryVersionId
				AND ce.IsInvalidTask = 0
	)
	,taskSuppMatching AS
	(
		SELECT 
			RC.*, 
			ISNULL(STUFF([supplementals].query('keys').value('/', 'NVARCHAR(MAX)'), 1, 1, ''), '') AS SuppsKey,
			ISNULL(STUFF([supplementals].query('data').value('/', 'NVARCHAR(MAX)'), 1, 1, ''), '') AS SuppsData
		FROM taskSemiMatching RC		
			CROSS APPLY ( 
					SELECT 
						(SELECT ':' + su.SupplementTermKey AS keys , 
								':' + LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(su.SupplementalValue, CHAR(10),' '), CHAR(13),' '), CHAR(9),' '))) AS data
						FROM  CodingSourceTermSupplementals su 
						WHERE su.codingsourcetermid = RC.CodingElementId
						ORDER BY su.SupplementTermKey
						FOR XML PATH(''), TYPE ) AS [supplementals]
					) [supplementals]
	) 

	IF NOT EXISTS (SELECT NULL FROM sys.indexes WHERE name = 'IX_PreQMCMP_RaveToken')
		CREATE NONCLUSTERED INDEX [IX_PreQMCMP_RaveToken]
		ON [dbo].[PreQMCMP] (RaveToken)

	INSERT INTO PreQMCMP(
			CodingElementId,
			UUID,
			StudyDictionaryVersionId,
			FullKeyMapId,
			SuppsKey,
			SuppKeyMapId,
			SuppsData,
				
			-- CMP related results
			RaveCoderExtractID,
			DataMatch,
			CodingDecisionMatch,
			IsMigrated,
			Deactivate,
			DeactivationReason,
			ReferenceCodingElementId,
			--Rave Token
			RaveToken
			)
	SELECT 
		CodingElementId,
		UUID,
		StudyDictionaryVersionId,
		0,
		SuppsKey, CASE WHEN ISNULL(SuppsKey, '') = '' THEN -1 ELSE 0 END, SuppsData,

		0, 0, 0, 0, 0, 0, 0, @RaveToken
	FROM taskSuppMatching t

	UPDATE pq
	SET pq.SuppKeyMapId = sm.SuppKeyMapId
	FROM PreQMCMP pq
		JOIN SuppKeyMap sm
			ON sm.SuppKey = pq.SuppsKey and sm.RaveToken=pq.RaveToken
	where pq.RaveToken=@RaveToken

END


