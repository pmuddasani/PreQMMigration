IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spFullCorrelateCoderTasks')
	DROP PROCEDURE dbo.spFullCorrelateCoderTasks
GO

-- EXEC spFullCorrelateCoderTasks

CREATE PROCEDURE dbo.spFullCorrelateCoderTasks
(
    @raveToken INT
)
AS
BEGIN

	UPDATE CTSK
	SET CTSK.RaveCoderExtractID = d.RaveCoderExtractID
	FROM PreQMCMP CTSK
		CROSS APPLY
		(
			SELECT
				RaveCoderExtractID = MAX(S.RaveCoderExtractID), 
				TC                 = COUNT(1)
			FROM 
			(
				SELECT 
					RC.RaveCoderExtractID
				FROM ctRaveCoderExtract RC
				WHERE CTSK.StudyDictionaryVersionId = RC.StudyDictionaryVersionId
					AND CTSK.FullKeyMapId           = RC.FullKeyMapId
					-- AV: Note: ignore the supplemental keys
					--AND CTSK.SuppKeyMapId           = RC.SuppKeyMapId
					
			) AS S
		) AS RC_FullKeys
		CROSS APPLY
		(
			SELECT
				CASE 
					WHEN RC_FullKeys.TC = 1 THEN RC_FullKeys.RaveCoderExtractID
					WHEN RC_FullKeys.TC > 1 THEN -1
					ELSE                      0
				END AS RaveCoderExtractID
		) AS d
	WHERE CTSK.IsMigrated           = 0
		AND CTSK.RaveCoderExtractID = 0
		AND CTSK.RaveToken= @RaveToken

	-- migrate also the multiple matches based on the latest update from Rave
	UPDATE CTSK
	SET CTSK.RaveCoderExtractID = RC.RaveCoderExtractID
	FROM PreQMCMP CTSK
		CROSS APPLY
		(
			SELECT TOP 1
				RC.RaveCoderExtractID
			FROM ctRaveCoderExtract RC
			WHERE CTSK.StudyDictionaryVersionId = RC.StudyDictionaryVersionId
				AND CTSK.FullKeyMapId           = RC.FullKeyMapId
				AND CTSK.SuppKeyMapId           = RC.SuppKeyMapId
			ORDER BY RC.LastUpdated DESC
		) AS RC
	WHERE CTSK.IsMigrated           = 0
		AND CTSK.RaveCoderExtractID < 0
		AND CTSK.RaveToken=@RaveToken

END
