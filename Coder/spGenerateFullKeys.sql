IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spGenerateFullKeys')
	DROP PROCEDURE dbo.spGenerateFullKeys
GO

-- EXEC spGenerateFullKeys

CREATE PROCEDURE dbo.spGenerateFullKeys
(
    @raveToken INT
)
AS
BEGIN

	-- Process Coder Data
	--TRUNCATE TABLE TmpODM

	-- fast <2 minutes on AZ1 data (350k)
	INSERT INTO TmpODM(CodingElementId, SourceIdentifier, XmlContent, FullKeyMapId,RaveToken)
	SELECT CTSK.CodingElementId, X.SourceIdentifier, X.XmlContent, -1,@raveToken
	FROM PreQMCMP CTSK
		CROSS APPLY
		(
			SELECT 
				ce.SourceIdentifier,
				CONVERT(XML,
						-- 1. a cast to NVARCHAR cause NTEXT can't be cast to xml
						-- 1.b simplify the XML into one schema and reduce the meta
						N'<ODM xmlns:mdsol="~">'+substring(cast(RawXmlContent as nvarchar(max)), patindex('%<ClinicalData%',RawXmlContent), DataLength(RawXmlContent))
					) AS XmlContent
			FROM CodingElements ce
				CROSS APPLY
				(
					SELECT RawXmlContent =
						CASE WHEN CR.IsXmlCompressed = 0 
							THEN CR.XmlContent
							ELSE /*clr*/dbo.Decompress(CR.XmlContent) 
						END
					FROM CodingRequests CR
					WHERE CR.CodingRequestId = ce.CodingRequestId
				) DC
			WHERE CTSK.CodingElementId = ce.CodingElementId
				AND DATALENGTH(RawXmlContent) > 0
		) AS X
	WHERE IsMigrated           = 0
		AND RaveCoderExtractID = 0
		AND RaveToken= @RaveToken

	SET ROWCOUNT 100
	DECLARE @affectedRows INT = 1

	WHILE (@affectedRows > 0)
	BEGIN

		-- very very slow
		UPDATE M
		SET M.FullKeyMapId = X.FullKeyMapId
		FROM TmpODM M
			CROSS APPLY
			(
				SELECT 
					FullKeyMapId = ISNULL(MAX(FullKeyMapId), 0),
					fullKey      = ISNULL(MAX(fullKey), '')
				FROM 
				(
					SELECT FullKeyMapId, fullKey
					FROM XmlContent.nodes('declare namespace mdsol="~";/ODM/ClinicalData/SubjectData/StudyEventData/FormData/ItemGroupData/ItemData/mdsol:QueueItem') T(n)
						CROSS APPLY
						(
							SELECT TOP 1 *
							FROM
							(
								SELECT
									SubjectKey			 =LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(
										ISNULL(T.n.value('(../../../../../@SubjectKey)[1]'      ,'NVARCHAR(50)'), '')
										, CHAR(10),' '), CHAR(13),' '), CHAR(9),' ')))
									,SiteOID			 =LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(
										T.n.value('(../../../../../SiteRef/@LocationOID)[1]'    ,'NVARCHAR(50)')
										, CHAR(10),' '), CHAR(13),' '), CHAR(9),' ')))
									,StudyEventOID		 =ISNULL(T.n.value('(../../../../@StudyEventOID)[1]'      ,'VARCHAR(100)'), '')
									,StudyEventRepeatKey =ISNULL(T.n.value('(../../../../@StudyEventRepeatKey)[1]','VARCHAR(101)'), '')
									,FormRepeatKey		 =ISNULL(T.n.value('(../../../@FormRepeatKey)[1]'         ,'SMALLINT'), 1) - 1
									,recordOrdinal		 =ISNULL(T.n.value('(../../@ItemGroupRepeatKey)[1]'       ,'SMALLINT'), 0)
									,ItemOID			 =ISNULL(T.n.value('(../@ItemOID)[1]','VARCHAR(100)')     , '')
									,SourceIdentifier    =ISNULL(T.n.value('(@OID)[1]','NVARCHAR(100)')           , '')
							) AS odm
							WHERE odm.SourceIdentifier = M.SourceIdentifier
						) AS odm
						CROSS APPLY
						(
							SELECT 
								StudyEventRepeatKey = CASE WHEN ISNUMERIC(odm.StudyEventRepeatKey) = 1 
																THEN odm.StudyEventOID+'['+odm.StudyEventRepeatKey+']'
																ELSE odm.StudyEventRepeatKey 
													  END
						) AS odmE
						CROSS APPLY
						(
							SELECT
							dbo.fnGetCompositeKey(
								odm.SubjectKey,
								odm.ItemOID,
								odm.StudyEventOID,
								odm.SiteOID,
								odm.recordOrdinal,
								odmE.StudyEventRepeatKey,
								odm.FormRepeatKey
							) AS fullKey
						) AS F
						CROSS APPLY
						(
							SELECT TOP 1 fm.FullKeyMapId
							FROM FullKeyMap fm
							WHERE fm.FullKey = F.FullKey
								and fm.RaveToken=@RaveToken
						) AS X
				) AS Y
			) AS X
		WHERE M.FullKeyMapId = -1
		and M.RaveToken=@RaveToken

		SET @affectedRows = @@ROWCOUNT

	END

	SET ROWCOUNT 0

	UPDATE pq
	SET pq.FullKeyMapId = fm.FullKeyMapId
	FROM PreQMCMP pq
		JOIN TmpODM fm
			ON fm.CodingElementId = pq.CodingElementId
	where pq.RaveToken=@RaveToken
END
