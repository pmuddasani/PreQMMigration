IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spPartialCorrelateCoderTasks')
	DROP PROCEDURE dbo.spPartialCorrelateCoderTasks
GO

-- EXEC spPartialCorrelateCoderTasks

CREATE PROCEDURE dbo.spPartialCorrelateCoderTasks
(
    @raveToken INT
)
AS
BEGIN

	-- update the UUID matching ones
	UPDATE CTSK
	SET CTSK.RaveCoderExtractID = d.RaveCoderExtractID,
		CTSK.IsMigrated         = d.IsMigrated
	FROM PreQMCMP CTSK
		CROSS APPLY
		(
			SELECT
				RaveCoderExtractID = MAX(S.RaveCoderExtractID), 
				TC                 = COUNT(1)
			FROM 
			(
				SELECT RC.RaveCoderExtractID
				FROM ctRaveCoderExtract RC
				WHERE CTSK.StudyDictionaryVersionId = RC.StudyDictionaryVersionId
					AND RC.UUID                     = CTSK.UUID
					and RC.RaveToken=@RaveToken
			) AS S
		) AS RC_UUID
		CROSS APPLY
		(
			SELECT
				CASE 
					WHEN RC_UUID.TC = 1 THEN RC_UUID.RaveCoderExtractID
					WHEN RC_UUID.TC > 1 THEN -1
					ELSE                      0
				END AS RaveCoderExtractID,
				CASE 
					WHEN RC_UUID.TC = 1 THEN  1
					ELSE                      0
				END AS IsMigrated
		) AS d
	WHERE CTSK.UUID <> ''
		AND CTSK.StudyDictionaryVersionId > 0
		AND CTSK.RaveToken=@RaveToken


	-- migrate also the multiple matches based on the latest update from Rave
	UPDATE CTSK
	SET CTSK.RaveCoderExtractID = RC.RaveCoderExtractID,
		CTSK.IsMigrated = 1
	FROM PreQMCMP CTSK
		CROSS APPLY
		(
			SELECT TOP 1
				RC.RaveCoderExtractID
			FROM ctRaveCoderExtract RC
			WHERE CTSK.StudyDictionaryVersionId = RC.StudyDictionaryVersionId
				AND RC.UUID                     = CTSK.UUID
				and RC.RaveToken=@RaveToken
			ORDER BY RC.LastUpdated DESC
		) AS RC
	WHERE CTSK.UUID <> ''
		AND CTSK.StudyDictionaryVersionId > 0
		AND CTSK.IsMigrated               = 0
		AND CTSK.RaveCoderExtractID       < 0
		AND CTSK.RaveToken=@RaveToken
END
