IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'QMCMP')
BEGIN

	CREATE TABLE [dbo].QMCMP(
		[CodingElementId]			[BIGINT] NOT NULL,
		[UUID]						[VARCHAR](36) NOT NULL,
		[CodingContextUri]			[NVARCHAR](1000) NOT NULL,

		-- CMP actions
		[ToMigrate]					[BIT] NOT NULL,
		[ToRequeue]					[BIT] NOT NULL,
		[ToDeactivate]				[BIT] NOT NULL,
		[DeactivationReason]		[TINYINT] NOT NULL,
		[ReferenceCodingElementId]	[BIGINT] NOT NULL,
		[RaveToken]					[INT] NOT NULL,
	CONSTRAINT [PK_QMCMP] PRIMARY KEY CLUSTERED 
	(
		[CodingElementId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	)

END

-- NOTE : this table won't be dropped until the CMP process is complete
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'CoderQMCMPLog')
BEGIN

	CREATE TABLE [dbo].CoderQMCMPLog(
		[CodingElementId]			[BIGINT] NOT NULL,
		[UUID]						[VARCHAR](36) NOT NULL,
		[CodingContextUri]			[NVARCHAR](1000) NOT NULL,

		-- CMP actions
		[ToMigrate]					[BIT] NOT NULL,
		[ToRequeue]					[BIT] NOT NULL,
		[ToDeactivate]				[BIT] NOT NULL,
		[DeactivationReason]		[TINYINT] NOT NULL,
		[ReferenceCodingElementId]	[BIGINT] NOT NULL,

		-- execution details
		[Created]					[DATETIME] NOT NULL CONSTRAINT [DF_CoderQMCMPLog_Created]  DEFAULT (GETUTCDATE()),
 		[RaveToken] 				[INT] NOT NULL,

	CONSTRAINT [PK_CoderQMCMPLog] PRIMARY KEY CLUSTERED 
	(
		[CodingElementId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	)

END

GO