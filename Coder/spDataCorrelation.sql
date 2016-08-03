IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spDataCorrelation')
	DROP PROCEDURE dbo.spDataCorrelation
GO

-- EXEC spDataCorrelation

CREATE PROCEDURE dbo.spDataCorrelation
(
    @raveToken INT
)
AS
BEGIN

	-- deactive multiples
	-- pick first the ones that are already with UUID (migrated)
	-- or the ones that were last entered in Coder (highest codingElementId)
	;WITH multipleRCE AS
	(
		SELECT CodingElementId, RCE.UUID, RCE.StudyDictionaryVersionId, 
			ROW_NUMBER() OVER (
				PARTITION BY RCE.UUID, RCE.StudyDictionaryVersionId
				ORDER BY IsMigrated DESC, RCE.LastUpdated DESC, CodingElementId DESC) AS RowNumBer
		FROM PreQMCMP P
			JOIN ctRaveCoderExtract RCE
				ON P.RaveCoderExtractID = RCE.RaveCoderExtractID and
				   P.RaveToken=RCE.RaveToken
		WHERE P.RaveCoderExtractID > 0
			  and P.RaveToken=@RaveToken
	),
	withDuplicateId AS
	(
		SELECT m1.CodingElementId AS ToKeepId, m2.CodingElementId AS ToDeactivateId
		FROM multipleRCE m1
			JOIN multipleRCE m2
				ON m1.UUID = m2.UUID
				AND m1.StudyDictionaryVersionId = m2.StudyDictionaryVersionId
				AND m2.RowNumBer > 1
				AND m1.RowNumBer = 1
	)

	UPDATE P
	SET P.Deactivate         = 1,
		P.DeactivationReason = 2, -- duplicates
		P.ReferenceCodingElementId = M.ToKeepId
	FROM PreQMCMP P
		JOIN withDuplicateId M
			ON P.CodingElementId = M.ToDeactivateId
		-- only non-UUID tasks
	WHERE P.UUID = '' 
		AND P.RaveToken=@RaveToken

	-- deactivate no matches
	UPDATE P
	SET P.Deactivate         = 1,
		P.DeactivationReason = 3 -- no matches
	FROM PreQMCMP P
	WHERE P.RaveCoderExtractID = 0
		-- only non-UUID tasks
		AND P.UUID = ''
		AND P.RaveToken=@RaveToken

	UPDATE CTSK
	SET CTSK.DataMatch           = Flags.DataMatch,
		CTSK.CodingDecisionMatch = CD.IsDecisionMatch
	FROM PreQMCMP CTSK
		JOIN CodingElements ce
			ON CTSK.CodingElementId = ce.CodingElementId
		JOIN ctRaveCoderExtract rce
			ON CTSK.RaveCoderExtractID = rce.RaveCoderExtractID
		CROSS APPLY
		(
			SELECT 
				Verbatim     = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(ce.VerbatimTerm      , ''), CHAR(10),' '), CHAR(13),' '), CHAR(9),' '))),
				SuppData     = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(CTSK.SuppsData       , ''), CHAR(10),' '), CHAR(13),' '), CHAR(9),' '))),
				RaveVerbatim = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(rce.VerbatimTerm     , ''), CHAR(10),' '), CHAR(13),' '), CHAR(9),' '))),
				SuppValue    = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(rce.SupplementalValue, ''), CHAR(10),' '), CHAR(13),' '), CHAR(9),' ')))
		) AS T
		CROSS APPLY
		(
			SELECT 
				DataMatch = CASE 
 					WHEN Verbatim = RaveVerbatim AND SuppData = SuppValue AND rce.SuppKeyMapId = CTSK.SuppKeyMapId THEN 1 
 					ELSE 0 END
		) AS Flags
		CROSS APPLY
		(
			SELECT ISNULL(MIN(IsDecisionMatch), 1) AS IsDecisionMatch
			FROM
			(
				SELECT 
					IsDecisionMatch = CASE WHEN 
						CHARINDEX(
							REVERSE(ISNULL(rce.codingpath, '')),
							REVERSE(ISNULL(CP.CodingPath , ''))) = 1 THEN 1 ELSE 0 END
				FROM SegmentedGroupCodingPatterns SGCP
					JOIN CodingPatterns CP
						ON SGCP.CodingPatternId = CP.CodingPatternId
				WHERE SGCP.SegmentedGroupCodingPatternId = CE.AssignedSegmentedGroupCodingPatternId
					AND CE.WorkflowStateId = 5 -- only completed state!
			) AS XI
		) AS CD
	WHERE CTSK.RaveCoderExtractID > 0
		AND CTSK.Deactivate       = 0
		AND CTSK.RaveToken=@RaveToken

	-- Deactivate tasks with empty corresponding datapoints
	UPDATE CTSK
	SET CTSK.Deactivate         = 1,
		CTSK.DeactivationReason = 1 -- empty verbatims
	FROM PreQMCMP CTSK
		JOIN ctRaveCoderExtract rce
			ON CTSK.RaveCoderExtractID = rce.RaveCoderExtractID
		CROSS APPLY
		(
			SELECT 
				RaveVerbatim = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(ISNULL(rce.VerbatimTerm     , ''), CHAR(10), ''), CHAR(13), ''), CHAR(9), '')))
		) AS T
	WHERE CTSK.Deactivate   = 0
		AND CTSK.IsMigrated = 0
		AND T.RaveVerbatim  = ''
		-- only non-UUID tasks
		AND CTSK.UUID = ''
		AND CTSK.RaveToken=@RaveToken
END
