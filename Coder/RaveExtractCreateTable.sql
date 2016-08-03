
IF NOT EXISTS (SELECT NULL FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'ctRaveCoderExtract')
BEGIN

	CREATE TABLE [dbo].[ctRaveCoderExtract](
		[RaveCoderExtractID]						[BIGINT] IDENTITY(1,1) NOT NULL,
		[RaveDBHash] 								[bigint] NOT NULL,
		[EnvironmentName] 							[nvarchar](200) NULL,
		[ExternalObjectId] 							[varchar](36) NULL,
		[SiteNumber] 								[nvarchar](50) NULL,
		[SourceSubject] 							[nvarchar](50) NULL,
		[FolderOID] 								[varchar](50) NULL,
		[FolderName]								[nvarchar](500) NULL,
		[NestedFolderPath]	 						[varchar](255) NULL,
		[FormOID] 									[varchar](50) NULL,
		[FormName]									[nvarchar](500) NULL,
		[PageRepeatNumber] 							[int] NULL,
		[SourceField] 								[varchar](50) NULL,
		[RecordPosition] 							[int] NULL,
		[UUID] 										[char](36) NULL,
		[DatapointID] 								[int] NULL,
		[HasContexthash] 							[bit] NULL,
		[CodingContextURI] 							[nvarchar](1000) NULL,
		[Locale]									[nvarchar](20) NULL,
		[RegistrationName]							[nvarchar](100) NULL,
		[Dataactive] 								[bit] NULL,
		[Istouched] 								[bit] NULL,
		[RecordActive] 								[bit] NULL,
		[StudyActive] 								[bit] NULL,
		[StudysiteActive] 							[bit] NULL,
		[SubjectActive]								[bit] NULL,
		[ProjectActive]								[bit] NULL,
		[IsVisible]									[bit] NULL,
		[IsHidden]									[bit] NULL,
		[Deleted]									[bit] NULL,
		[RecordDeleted]								[bit] NULL,
		[DataPageActive]							[bit] NULL,
		[IsUsingCoder]								[bit] NULL,
		[CRExists]									[bit] NULL,
		[VerbatimTerm] 								[nvarchar](2000) NULL,
		[SupplementalTermkey] 						[varchar](max) NULL,
		[SupplementalValue] 						[NVarchar](max) NULL,
		[CodedDate] 								[datetime] NULL,
		[IsCoded] 									[bit] NULL,
		[Codingpath] 								[nvarchar](max) NULL,
		[CodingTerm]								[nvarchar](max) NULL,
		[Created]									[datetime] NOT NULL CONSTRAINT [DF_RaveCoderExtract_Created]  DEFAULT (getutcdate()),
		[AuditID]									[bigint] NULL,   
		[AuditTime]									[datetime] NULL,
		[AuditSubcategoryID]						[smallint] NULL,
		-- Correlation Columns
		[StudyDictionaryVersionID]					INT NOT NULL CONSTRAINT [DF_RaveCoderExtract_StudyDictionaryVersionID]  DEFAULT (-1),
		[FullKey]									[NVARCHAR](425) NOT NULL CONSTRAINT [DF_RaveCoderExtract_FullKey]  DEFAULT (N''),
		[FullKeyMapId]								[INT] NOT NULL CONSTRAINT [DF_RaveCoderExtract_FullKeyMapId]  DEFAULT (-1),
		[SuppKeyMapId]								[INT] NOT NULL CONSTRAINT [DF_RaveCoderExtract_SuppKeyMapId]  DEFAULT (-1),
		[RaveToken] 								[int] NOT NULL CONSTRAINT [DF_RaveCoderExtract_RaveToken]  DEFAULT (-1),
	CONSTRAINT [PK_RaveCoderExtract] PRIMARY KEY CLUSTERED 
	(
		[RaveCoderExtractID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	)
	

END


