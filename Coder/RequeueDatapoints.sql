IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'RequeueDatapoints')
BEGIN

	CREATE TABLE [dbo].RequeueDatapoints(
		[UUID]					[CHAR](36) NOT NULL,
		[IsDatapointInCoder]	[BIT] NOT NULL CONSTRAINT [DF_RequeueDatapoints_IsDatapointInCoder]  DEFAULT (1),
		[RaveToken]				[INT] NOT NULL
	)
	

END