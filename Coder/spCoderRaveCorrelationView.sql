IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spCoderRaveCorrelationView')
	DROP PROCEDURE dbo.spCoderRaveCorrelationView
GO

-- EXEC spCoderRaveCorrelationView 2

CREATE PROCEDURE dbo.spCoderRaveCorrelationView
(
    @raveToken INT
)
AS
BEGIN

	;WITH coderMatches AS 
	(
		SELECT
			StudyDictionaryVersionId,
			M.IsMigrated,
			M.ToDeactivateOne,
			M.ToDeactivateTwo,
			M.ToDeactivateThree,
			M.CanMigrate,
			N.RequiresRaveRequeue,
			N.RequiresCoderRequeue,
			M.NoMatches,
			Total = M.IsMigrated + M.ToDeactivateOne+M.ToDeactivateTwo+M.ToDeactivateThree+ + M.CanMigrate + M.NoMatches
		FROM PreQMCMP P
			CROSS APPLY
			(
				SELECT 
					IsMigrated        = CASE WHEN IsMigrated = 1 AND Deactivate = 0                            THEN 1 ELSE 0 END,
					ToDeactivateOne   = CASE WHEN Deactivate = 1 AND DeactivationReason = 1                    THEN 1 ELSE 0 END, 
					ToDeactivateTwo   = CASE WHEN Deactivate = 1 AND DeactivationReason = 2                    THEN 1 ELSE 0 END, 
					ToDeactivateThree = CASE WHEN Deactivate = 1 AND DeactivationReason = 3                    THEN 1 ELSE 0 END, 
					CanMigrate        = CASE WHEN IsMigrated = 0 AND Deactivate = 0 AND RaveCoderExtractId > 0 THEN 1 ELSE 0 END,
					NoMatches         = CASE WHEN IsMigrated = 0 AND Deactivate = 0 AND RaveCoderExtractId = 0 THEN 1 ELSE 0 END
			) AS M
			CROSS APPLY
			(
				SELECT 
					RequiresRaveRequeue  = CASE WHEN Deactivate = 0 AND P.DataMatch = 0 AND RaveCoderExtractId > 0 THEN 1 ELSE 0 END,
					RequiresCoderRequeue = CASE WHEN Deactivate = 0 AND P.DataMatch = 1 AND P.CodingDecisionMatch = 0 AND RaveCoderExtractId > 0 THEN 1 ELSE 0 END
			) AS N
		WHERE P.RaveToken=@RaveToken
	),
	bySDV AS
	(
		SELECT 
			StudyDictionaryVersionId,
			SUM(IsMigrated)           AS IsMigrated,
			SUM(ToDeactivateOne)      AS ToDeactivateOne,
			SUM(ToDeactivateTwo)      AS ToDeactivateTwo,
			SUM(ToDeactivateThree)    AS ToDeactivateThree,
			SUM(CanMigrate)           AS CanMigrate,
			SUM(RequiresRaveRequeue)  AS RequiresRaveRequeue,
			SUM(RequiresCoderRequeue) AS RequiresCoderRequeue,
			SUM(NoMatches)            AS NoMatches,
			SUM(Total)                AS Total
		FROM coderMatches
		GROUP BY StudyDictionaryVersionId
	)

	SELECT b.*, tos.IsTestStudy, tos.ExternalObjectName, sdv.RegistrationName
	FROM bySDV b
		JOIN StudyDictionaryVersion SDV
			ON B.StudyDictionaryVersionId = SDV.StudyDictionaryVersionId
		JOIN TrackableObjects tos
			ON Tos.TrackableObjectID = SDV.StudyID
	ORDER BY B.StudyDictionaryVersionId ASC

END
