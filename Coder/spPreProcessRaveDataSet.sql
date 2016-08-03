IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spPreProcessRaveDataSet')
	DROP PROCEDURE dbo.spPreProcessRaveDataSet
GO

-- EXEC spPreProcessRaveDataSet 2

CREATE PROCEDURE dbo.spPreProcessRaveDataSet
(
    @raveToken INT
)
AS
BEGIN

	--IF EXISTS (SELECT NULL FROM sys.indexes
	--	WHERE name = 'IX_RaveCoderExtract_FullKey')
	--	DROP INDEX RaveCoderExtract.IX_RaveCoderExtract_FullKey

	--IF EXISTS (SELECT NULL FROM sys.indexes
	--	WHERE name = 'IX_RaveCoderExtract_UUID')
	--	DROP INDEX RaveCoderExtract.IX_RaveCoderExtract_UUID

		-- speed up the matching works
	IF NOT EXISTS (SELECT NULL FROM sys.indexes WHERE name = 'IX_RaveCoderExtract_FullKey')
		CREATE NONCLUSTERED INDEX [IX_RaveCoderExtract_FullKey]
		ON [dbo].[ctRaveCoderExtract] (RaveCoderExtractID, StudyDictionaryVersionId, FullKeyMapId, SuppKeyMapId)

	IF NOT EXISTS (SELECT NULL FROM sys.indexes WHERE name = 'IX_RaveCoderExtract_UUID')
		CREATE NONCLUSTERED INDEX [IX_RaveCoderExtract_UUID]
		ON [dbo].[ctRaveCoderExtract] (RaveCoderExtractID, StudyDictionaryVersionId, UUID)

	
	IF NOT EXISTS (SELECT NULL FROM sys.indexes WHERE name = 'IX_RaveCoderExtract_RaveToken')
		CREATE NONCLUSTERED INDEX [IX_RaveCoderExtract_RaveToken]
		ON [dbo].[ctRaveCoderExtract] (RaveToken)

	IF NOT EXISTS (SELECT NULL FROM sys.indexes WHERE name = 'IX_RaveCoderExtract_hash')
		CREATE NONCLUSTERED INDEX [IX_RaveCoderExtract_RaveDBHash]
		ON [dbo].[ctRaveCoderExtract] (RaveDBHash)

	-- reset resolved SDVs if rerun
	UPDATE ctRaveCoderExtract
	SET StudyDictionaryVersionID = -1
	WHERE RaveToken	= @RaveToken

	-- 1. context matching
	-- ensure that Rave DPs match a single SDV
	;WITH matchedRegistrations AS
	(
		SELECT rc.RaveCoderExtractID, sdv.StudyDictionaryVersionID, COUNT(1) AS MatchCount
		FROM ctRaveCoderExtract rc
			JOIN TrackableObjects tr 
				ON tr.ExternalObjectId         = rc.ExternalObjectId
				AND rc.RaveToken               = @RaveToken
			JOIN StudyDictionaryVersion sdv 
				ON sdv.StudyID                 = tr.trackableobjectid 
				AND sdv.RegistrationName       = rc.RegistrationName
			JOIN SynonymMigrationMngmt smm 
				ON smm.SynonymMigrationMngmtID = sdv.synonymManagementID
			CROSS APPLY
			(
				SELECT Locale = dbo.fnGetLocaleFromDictionaryVersionLocaleKey(smm.MedicalDictionaryVersionLocaleKey)
			) AS SynLocale
		WHERE RaveToken						= @RaveToken		
			AND rc.StudyDictionaryVersionID < 0 -- not set yet
			-- locale comparison
			AND ( 
					(rc.Locale = 'eng' AND '-English'  = SynLocale.Locale)
					OR 
					(rc.Locale = 'jpn' AND '-Japanese' = SynLocale.Locale)
				)
		GROUP BY rc.RaveCoderExtractID, sdv.StudyDictionaryVersionID
	)

	UPDATE rc
	SET rc.StudyDictionaryVersionID = 
		CASE WHEN MatchCount = 1 THEN MR.StudyDictionaryVersionID ELSE 0 END
	FROM matchedRegistrations MR
		JOIN ctRaveCoderExtract rc
			ON MR.RaveCoderExtractID = rc.RaveCoderExtractID

	UPDATE ctRaveCoderExtract
	SET FullKey = dbo.fnGetCompositeKey(
				SourceSubject,
				FormOID+'.'+SourceField,
				FolderOID,
				SiteNumber,
				
				RecordPosition,
				--InstanceRepeatNumber,
				NestedFolderPath,
				PageRepeatNumber)

	IF NOT EXISTS (SELECT NULL FROM sys.indexes WHERE name = 'IX_FullKeyMap_FullKey')
		CREATE NONCLUSTERED INDEX [IX_FullKeyMap_FullKey]
		ON [dbo].[FullKeyMap] ([FullKey])

	IF NOT EXISTS (SELECT NULL FROM sys.indexes WHERE name = 'IX_FullKeyMap_RaveToken')
		CREATE NONCLUSTERED INDEX [IX_FullKeyMap_RaveToken]
		ON [dbo].[FullKeyMap] (FullKey, RaveToken)

	---TRUNCATE TABLE [dbo].FullKeyMap

	INSERT INTO FullKeyMap (FullKey,RaveToken)
	SELECT DISTINCT FullKey, @raveToken
	FROM ctRaveCoderExtract
	WHERE RaveToken = @raveToken
		AND StudyDictionaryVersionID > 0
	ORDER BY FullKey

	

	UPDATE rce
	SET rce.FullKeyMapId = fm.FullKeyMapId
	FROM ctRaveCoderExtract rce
		JOIN FullKeyMap fm
			ON fm.FullKey = rce.FullKey and fm.RaveToken=rce.RaveToken
	WHERE rce.RaveToken = @raveToken

	---TRUNCATE TABLE [dbo].SuppKeyMap

	INSERT INTO SuppKeyMap (SuppKey,RaveToken)
	SELECT DISTINCT SupplementalTermKey ,@raveToken
	FROM ctRaveCoderExtract
	WHERE RaveToken = @raveToken
		AND SupplementalTermKey IS NOT NULL
	ORDER BY SupplementalTermKey

	UPDATE rce
	SET rce.SuppKeyMapId = sm.SuppKeyMapId
	FROM ctRaveCoderExtract rce
		JOIN SuppKeyMap sm
			ON sm.SuppKey = rce.SupplementalTermKey and sm.RaveToken=rce.RaveToken
	WHERE rce.RaveToken = @raveToken



END
