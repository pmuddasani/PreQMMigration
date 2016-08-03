IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spRunCMP')
	DROP PROCEDURE dbo.spRunCMP
GO

-- EXEC spRunCMP 407

CREATE PROCEDURE dbo.spRunCMP
(
    @sourceSystemId INT
)
AS
BEGIN

	DECLARE @UtcTime DATETIME                   = GETUTCDATE()
	DECLARE @qmMigrationComment NVARCHAR(50)    = 'Migrating task to QM'
	DECLARE @qmDeactivationComment NVARCHAR(50) = 'Deactivating task due to QM migration'

	-- 1. Tasks already migrated will not be touched
	-- 2. Tasks that have a positive migration path will be migrated
	-- 3. Tasks that were not matched will be de-activated.
	BEGIN TRY
	BEGIN TRANSACTION

		-- mark for deactivation the ones flagged for migration
		-- if a newer task with their UUID is now present (transmission delay)
		UPDATE  P
		SET P.ToDeactivate       = 1,
			P.DeactivationReason = 2, -- duplicate,
			P.ReferenceCodingElementId = CE_New.CodingElementId
		FROM QMCMP P
			JOIN CodingElements CE
				ON P.CodingElementId = CE.CodingElementId				
			CROSS APPLY
			(
				SELECT TOP 1 CE_New.CodingElementId
				FROM  CodingElements CE_New
				WHERE CE.StudyDictionaryVersionId = CE_New.StudyDictionaryVersionId
					AND CE.UUID = CE_New.UUID
					AND CE_New.InInvalidTask = 0
					AND CE.CodingElementId < CE_New.CodingElementId
			) AS CE_New

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
			CASE 
				WHEN P.ToDeactivate = 1 THEN @qmDeactivationComment+CAST(ReferenceCodingElementId AS VARCHAR)
				ELSE @qmMigrationComment END,
			@UtcTime, 
			CE.SegmentId, 
			NULL,
			CE.CodingElementGroupID,
			0
		FROM QMCMP P
			JOIN CodingElements ce
				ON P.CodingElementId  = ce.CodingElementId
				AND ce.IsInvalidTask  = 0
		WHERE P.ToDeactivate = 1 OR P.ToMigrate = 1

		-- deactivate part
		UPDATE ce
		SET 
			ce.IsInvalidTask              = 1,
			ce.IsClosed                   = 1,
			ce.Updated                    = @UtcTime,
			ce.CacheVersion               = ce.CacheVersion + 2
		FROM QMCMP P
			JOIN CodingElements ce
				ON P.CodingElementId      = ce.CodingElementId
				AND ce.IsInvalidTask      = 0
		WHERE P.ToDeactivate = 1

		-- migrate part
		UPDATE ce
		SET 
			ce.UUID                       = P.UUID,
			ce.CodingContextURI           = P.CodingContextURI,
			ce.Updated                    = @UtcTime,
			ce.CacheVersion               = ce.CacheVersion + 2
		FROM QMCMP P
			JOIN CodingElements ce
				ON P.CodingElementId      = ce.CodingElementId
				AND ce.IsInvalidTask      = 0
		WHERE P.ToMigrate = 1

		-- Cleanup invalid duplicate tasks (safe!)
		UPDATE CE
		SET CE.UUID                           = '',
			ce.Updated                        = @UtcTime,
			ce.CacheVersion                   = ce.CacheVersion + 2		
		FROM QMCMP P
			JOIN CodingElements c
				ON P.CodingElementId          = c.CodingElementId
			JOIN CodingElements ce
				ON c.StudyDictionaryVersionID = ce.StudyDictionaryVersionId
				AND P.UUID                    = ce.UUID
				AND ce.IsInvalidTask          = 1
				AND P.ToMigrate               = 1

		-- AV Note - product going back&forth on this, currently off of Phase1
		---- retransmit coding decisions
		--;WITH ToRequeue AS 
		--(
		--	SELECT TQI.TransmissionQueueItemID
		--	FROM QMCMP P
		--		JOIN CodingElements ce
		--			ON P.CodingElementId   = ce.CodingElementId
		--			AND ce.IsInvalidTask   = 0
		--			AND ce.WorkflowStateId = 5
		--			AND P.ToRequeue        = 1
		--		CROSS APPLY
		--		(
		--			SELECT TOP 1 CA.CodingAssignmentID
		--			FROM CodingAssignment CA
		--			WHERE CA.CodingElementId  = P.CodingElementId
		--				AND CA.SegmentedGroupCodingPatternID = ce.AssignedSegmentedGroupCodingPatternId
		--			ORDER BY CA.CodingAssignmentID DESC
		--		) AS CA
		--		CROSS APPLY
		--		(
		--			SELECT TOP 1 *
		--			FROM TransmissionQueueItems TQI 
		--			WHERE TQI.ObjectId        = CA.CodingAssignmentID 
		--				AND TQI.ObjectTypeID  = 2251
		--			ORDER BY TQI.TransmissionQueueItemID DESC
		--		) AS TQI
		--	)

		--UPDATE TQI  
		--SET 
		--	CumulativeFailCount        = TQI.CumulativeFailCount + TQI.FailureCount,   
		--	FailureCount               = 0,    
		--	SuccessCount               = 0,  
		--	ServiceWillContinueSending = 1,
		--	Updated                    = @UtcTime
		--FROM ToRequeue T
		--	JOIN TransmissionQueueItems TQI
		--		ON T.TransmissionQueueItemID = TQI.TransmissionQueueItemID

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
			[UUID],
			[CodingContextUri],
			[ToMigrate],
			[ToRequeue],
			[ToDeactivate],
			[DeactivationReason],
			@sourceSystemId
		FROM QMCMP

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