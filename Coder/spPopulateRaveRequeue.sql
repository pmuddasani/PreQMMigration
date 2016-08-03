IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spPopulateRaveRequeue')
	DROP PROCEDURE dbo.spPopulateRaveRequeue
GO

-- EXEC spPopulateRaveRequeue 407

CREATE PROCEDURE dbo.spPopulateRaveRequeue
(
    @raveToken INT
)
AS
BEGIN

	--TRUNCATE TABLE RequeueDatapoints

	-- 1. the UUIDs that exist in Coder
	INSERT INTO RequeueDatapoints (UUID, IsDatapointInCoder,RaveToken)
	SELECT rce.UUID, 1, CTSK.RaveToken
	FROM PreQMCMP CTSK
		JOIN ctRaveCoderExtract rce
			ON CTSK.RaveCoderExtractID = rce.RaveCoderExtractID
	WHERE CTSK.Deactivate = 0 AND CTSK.DataMatch = 0 and CTSK.RaveToken=@raveToken

	-- 2. the UUIDs that do not exist in Coder
	INSERT INTO RequeueDatapoints (UUID, IsDatapointInCoder,RaveToken)
	SELECT DISTINCT(rce.UUID), 0 , @raveToken
	FROM ctRaveCoderExtract rce
		LEFT JOIN PreQMCMP CTSK
			ON CTSK.RaveCoderExtractID = rce.RaveCoderExtractID
	WHERE CTSK.RaveCoderExtractID IS NULL
		AND rce.RaveToken = @raveToken

END