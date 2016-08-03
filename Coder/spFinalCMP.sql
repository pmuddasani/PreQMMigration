IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spFinalCMP')
	DROP PROCEDURE dbo.spFinalCMP
GO

-- EXEC spFinalCMP

CREATE PROCEDURE dbo.spFinalCMP
AS
BEGIN

	DECLARE @UtcTime DATETIME                   = GETUTCDATE()
	DECLARE @qmDeactivationComment NVARCHAR(50) = 'Deactivating task due to QM migration'

	-- 1. Tasks already migrated will not be touched
	-- 2. Tasks that have a positive migration path will be migrated
	-- 3. Tasks that were not matched will be de-activated.
	BEGIN TRY
	BEGIN TRANSACTION

		-- Note down in history
		INSERT INTO dbo.WorkflowTaskHistory
			( WorkflowTaskID ,
			  WorkflowStateID ,
			  WorkflowActionID ,
			  WorkflowSystemActionID ,
			  UserID ,
			  WorkflowReasonID ,
			  Comment ,
			  Created ,
			  SegmentId ,
			  CodingAssignmentId ,
			  CodingElementGroupId,
			  QueryId
			)
	   SELECT CE.CodingElementId, 
			CE.WorkflowStateID, NULL, NULL, -2, NULL, 
			@qmDeactivationComment,
			@UtcTime, 
			CE.SegmentId, 
			NULL,
			CE.CodingElementGroupID,
			0
		FROM CodingElements ce
		WHERE ce.IsInvalidTask  = 0
			AND ISNULL(ce.UUID, '') = ''
			AND ce.SourceSystemId <> 2 -- non-MEV ones

		-- deactivate
		UPDATE ce
		SET 
			ce.IsInvalidTask              = 1,
			ce.IsClosed                   = 1,
			ce.Updated                    = @UtcTime,
			ce.CacheVersion               = ce.CacheVersion + 2
		FROM CodingElements ce
		WHERE ce.IsInvalidTask  = 0
			AND ISNULL(ce.UUID, '') = '' --preQM mode
			AND ce.SourceSystemId <> 2 -- non-MEV ones

		-- NOTE in the log
		INSERT INTO  CoderQMCMPLog(
			[CodingElementId],
			[UUID],
			[CodingContextUri],
			[ToMigrate],
			[ToRequeue],
			[ToDeactivate],
			[DeactivationReason],
 			[RaveToken] )
		SELECT 
			[CodingElementId],
			'',
			'',
			0,
			0,
			1,
			4,
			SourceSystemId
		FROM CodingElements ce
		WHERE ce.IsInvalidTask  = 0
			AND ISNULL(ce.UUID, '') = '' --preQM mode
			AND ce.SourceSystemId <> 2 -- non-MEV ones

	    COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION

		DECLARE @errorString NVARCHAR(MAX)
		SET @errorString = N'ERROR: Transaction Error Message - ' + ERROR_MESSAGE()
		PRINT @errorString
		RAISERROR(@errorString, 16, 1)
	END CATCH

END