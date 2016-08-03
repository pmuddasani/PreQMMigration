IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'spCorrelateCoderTasks')
	DROP PROCEDURE dbo.spCorrelateCoderTasks
GO

-- EXEC spCorrelateCoderTasks 2

CREATE PROCEDURE dbo.spCorrelateCoderTasks
(
    @raveToken INT
)
AS
BEGIN

	-- 1. Process Rave Data  
	-- 3 minutes on AZ2 test data
	-- 1.30 minutes on AZ1
	EXEC spPreProcessRaveDataSet      @raveToken

	-- 2. Process Coder Data 
	-- <1 minutes on AZ2 test data
	-- 1.10 on AZ1
	EXEC spPreProcessCoderDataSet     @raveToken

	-- 3. correlate first on UUIDs (already migrated)
	-- very fast (~0.1 minutes on AZ test data)
	EXEC spPartialCorrelateCoderTasks @raveToken

	-- speed up the matching works
	CREATE NONCLUSTERED INDEX [IX_PreQMCMP_ToMigrate]
	ON [dbo].[PreQMCMP] ([RaveCoderExtractID],[IsMigrated])

	-- 4. decompress & parse ODMs
	-- Slowest process
	-- 0.3 hours on AZ2 test data
	-- 0.9 hours for AZ1 test data
	EXEC spGenerateFullKeys @raveToken

	-- 5. correlation on ODM structure
	-- very fast (~0.1 minute on AZ test data)
	EXEC spFullCorrelateCoderTasks @raveToken

	-- 6. post-Processing to check if data match for matched keys
	-- ~1 minute on AZ test data
	EXEC spDataCorrelation @raveToken

	-- 7. ready for CMP
	EXEC spPrepCMP @raveToken

	-- 8. ready Rave requeues
	EXEC spPopulateRaveRequeue @raveToken

	-- 9. generate correlation view
	EXEC spCoderRaveCorrelationView   @raveToken

END
