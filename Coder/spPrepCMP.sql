IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spPrepCMP')
	DROP PROCEDURE dbo.spPrepCMP
GO

-- EXEC spPrepCMP

CREATE PROCEDURE dbo.spPrepCMP
(
    @raveToken INT
)
AS
BEGIN

	--TRUNCATE TABLE QMCMP

	INSERT INTO QMCMP (
		[CodingElementId],
		[UUID],
		[CodingContextUri],
		[ToMigrate],
		[ToRequeue],
		[ToDeactivate],
		[DeactivationReason],
		[ReferenceCodingElementId],
		[RaveToken])
	SELECT 
		P.CodingElementId,
		CASE WHEN P.Deactivate = 0 THEN rce.UUID ELSE '' END,
		CASE WHEN P.Deactivate = 0 THEN ISNULL(rce.CodingContextURI, '') ELSE '' END,
		F.UpgradeUUIDTask,
		F.RequeueCodingDecision,
		F.DeActivateTask,
		P.DeactivationReason,
		P.ReferenceCodingElementId,
		P.RaveToken
	FROM PreQMCMP P
		JOIN ctRaveCoderExtract rce
			ON rce.RaveCoderExtractId = P.RaveCoderExtractId
		CROSS APPLY
		(
			SELECT
				--Requeue Coding Decisions if & only if
				-- the task is not to be deactivated
				-- the data is current, but the codingpaths are different
				RequeueCodingDecision = ~P.Deactivate & ~P.CodingDecisionMatch & P.DataMatch,
				DeActivateTask        = P.Deactivate,
				-- Upgrade Task if & only if
				-- the task is not to be deactivated
				-- and the task is not already with UUID
				UpgradeUUIDTask       = ~P.Deactivate & ~P.IsMigrated
		) F
	WHERE
		P.RaveToken=@RaveToken AND 
		(F.DeActivateTask       = 1 OR
		F.UpgradeUUIDTask       = 1 OR 
		F.RequeueCodingDecision = 1)
		
	-- also the ones not reconciled!
	INSERT INTO QMCMP (
		[CodingElementId],
		[UUID],
		[CodingContextUri],
		[ToMigrate],
		[ToRequeue],
		[ToDeactivate],
		[DeactivationReason],
		[ReferenceCodingElementId],
		[RaveToken])
	SELECT 
		P.CodingElementId,
		'',
		'',
		0,
		0,
		1,
		3, -- not matched
		0,
		P.RaveToken
	FROM PreQMCMP P
	WHERE P.RaveCoderExtractId < 1
		-- only non-UUID tasks
		AND P.UUID = ''
		AND P.RaveToken=@RaveToken
END