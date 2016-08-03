IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'PreQMCMP')
BEGIN
	
	CREATE TABLE [dbo].PreQMCMP(
		[CodingElementId]						[BIGINT] NOT NULL,
		[UUID]									[VARCHAR](36) NOT NULL,
		[StudyDictionaryVersionId]				[INT] NOT NULL,
		[FullKeyMapId]							[INT] NOT NULL,
		[SuppsKey]								[VARCHAR](MAX) NOT NULL,
		[SuppKeyMapId]							[INT] NOT NULL,
		[SuppsData]								[NVARCHAR](MAX) NOT NULL,

		-- CMP related results
		[RaveCoderExtractID]					[BIGINT] NOT NULL,
		[DataMatch]								[BIT] NOT NULL,
		[CodingDecisionMatch]					[BIT] NOT NULL,
		[IsMigrated]							[BIT] NOT NULL,
		[Deactivate]							[BIT] NOT NULL,
		[DeactivationReason]					[TINYINT] NOT NULL,
		[ReferenceCodingElementId]				[BIGINT] NOT NULL,
		[RaveToken]								[INT] NOT NULL,
	CONSTRAINT [PK_PreQMCMP] PRIMARY KEY CLUSTERED 
	(
		[CodingElementId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	)

END

IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'FullKeyMap')
BEGIN
	CREATE TABLE [dbo].FullKeyMap(
		[FullKeyMapId]		[INT]  IDENTITY(1,1) NOT NULL,
		[FullKey]			[NVARCHAR](450) NOT NULL,
		[RaveToken]			[INT] NOT NULL,
	CONSTRAINT [PK_FullKeyMap] PRIMARY KEY CLUSTERED 
	(
		[FullKeyMapId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	)
END

IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'SuppKeyMap')
BEGIN

	CREATE  TABLE [dbo].SuppKeyMap(
		[SuppKeyMapId]		[INT]  IDENTITY(1,1) NOT NULL,
		[SuppKey]			[VARCHAR](MAX) NOT NULL,
		[RaveToken]			[INT] NOT NULL,
	CONSTRAINT [PK_SuppKeyMap] PRIMARY KEY CLUSTERED 
	(
		[SuppKeyMapId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	)

END

IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'TmpODM')
BEGIN
	
	CREATE TABLE [dbo].TmpODM(
		[CodingElementId]		[BIGINT] NOT NULL,
		[SourceIdentifier]		[NVARCHAR](100) NOT NULL,
		[XmlContent]			[XML] NOT NULL,
		[FullKeyMapId]			[INT] NOT NULL,
		[RaveToken]				[INT] NOT NULL,
	CONSTRAINT [PK_TmpODM] PRIMARY KEY CLUSTERED 
	(
		[CodingElementId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	)

END