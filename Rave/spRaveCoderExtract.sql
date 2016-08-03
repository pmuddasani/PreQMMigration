--********************************************************************************************************
-- *Description: Extract RAVE data to compare values on CODER and map RAVE terms with CODER tasks
--********************************************************************************************************
 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET QUOTED_IDENTIFIER ON

IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = 'cspRaveCoderExtract')
	DROP PROCEDURE dbo.cspRaveCoderExtract
GO
-- DBCC DROPCLEANBUFFERS
-- EXEC spRaveCoderExtract

CREATE PROCEDURE dbo.cspRaveCoderExtract
AS
BEGIN

		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		SET QUOTED_IDENTIFIER ON


		print getutcdate()
		raiserror ('start', 0, 1) with nowait


		declare @RaveDBHash bigint
		select @RaveDBHash = cast(hashbytes('sha1', lower(@@servername) + ':' + lower(db_name())) as bigint)
		
		IF OBJECT_ID('tempdb..#ASCRs') IS NOT NULL drop table #ASCRs

		create table #ASCRs  (
			auditsubcategoryid int,
			tns_forverbatims bit,
			tns_forsupplementals bit,
			auditsubcategoryname nvarchar(max)
		)

		insert #ASCRs values 
		  (252, 1, 1, 'AcceptedDefaultValue'),
		  (002, 1, 1, 'Entered'),			 
		  (001, 0, 1, 'EnteredEmpty'),
		  (187, 0, 1, 'EnteredEmptyWithChangeCode'),	 
		  (182, 1, 1, 'EnteredInForeignLocale'), 
		  (183, 1, 1, 'EnteredInForeignLocaleWithChangeCode'), 
		  (003, 1, 1, 'EnteredNonConformant'), 
		  (180, 1, 1, 'EnteredWithChangeCode'), 
		  (231, 1, 1, 'EnteredWithChangeCodeMissingCode'), 
		  (184, 1, 1, 'EnteredWithMissingCode')


		if object_id('tempdb..#coderfields') is not null drop table #coderfields

		select distinct ccfg.fieldid, ccfg.locale, clfc.linkedfieldid supplemental_fieldid
		into #coderfields
		from coderconfigurations ccfg 
		left join coderlinkedfieldconfigurations clfc on clfc.coderfieldconfigurationid = ccfg.id

		create clustered index idx0 on #coderfields (fieldid)
		create index idx1 on #coderfields (supplemental_fieldid)
 
		print getutcdate()
		raiserror ('#coderfields', 0, 1) with nowait




		if object_id('tempdb..#main') is not null drop table #main

		select distinct
			dbo.fnlocaldefault(st.environmentnameid) AS EnvironmentName,
			st.UUID AS ExternalObjectId,
			REPLACE(REPLACE(REPLACE(si.sitenumber, CHAR(10),' '), CHAR(13),' '), CHAR(9),' ') AS SiteNumber,
			REPLACE(REPLACE(REPLACE(s.subjectname, CHAR(10),' '), CHAR(13),' '), CHAR(9),' ')  AS SourceSubject,
			isnull(fl.OID, '-') AS FolderOID,
			isnull(dbo.fnlocaldefault(fl.foldername), '-') as FolderName,
			isnull(dbo.fnWebServicesGetNestedFolderPath(dpg.instanceid),'') AS NestedFolderPath,
			fo.OID AS FormOID,
			isnull(dbo.fnlocaldefault(fo.formname), '-') as FormName,
			dpg.PageRepeatNumber,
			fi.OID AS SourceField,
			r.RecordPosition,
			dpt.GUID AS UUID,
			dpt.DatapointID,
			case when ctch.datapointid is null then 0 else 1 end AS HasContextHash,
			ctch.ContextHash as CodingContextUri,
			cf.locale AS Locale,
			cdict.dictionaryname AS RegistrationName,
		-- Active/deleted flags
			dpt.dataactive,
			dpt.istouched,
			r.recordactive,
			st.studyactive,
			ss.studysiteactive,
			s.subjectactive,
			p.projectactive,
			dpt.isvisible,
			dpt.ishidden,
			dpt.deleted,
			r.deleted AS RecordDeleted,
			dpg.DataPageActive,
		-- Active/deleted flags END
			v.IsUsingCoder,
			REPLACE(REPLACE(REPLACE(CASE WHEN de.UserDataStringID IS NULL 
				THEN dpt.data
				ELSE dbo.fnLocalDefault(de.UserDataStringID)
			END , CHAR(10),' '), CHAR(13),' '), CHAR(9),' ')  AS VerbatimTerm,
			dpt.Updated LastUpdated
		into #main
		from variables v
		join fields fi on fi.variableid = v.variableid
		join #coderfields cf on cf.fieldid = fi.fieldid
		join datapoints dpt on dpt.fieldid = fi.fieldid
		join subjects s on s.subjectid = dpt.subjectid
		join studysites ss on ss.studysiteid = s.studysiteid
		join studies st on st.studyid = ss.studyid
		join sites si on si.siteid = ss.siteid
		join forms fo on fo.formid = fi.formid
		join records r on r.recordid = dpt.recordid
		join datapages dpg on dpg.datapageid = r.datapageid
		left join instances i on i.instanceid = dpg.instanceid
		left join folders fl on fl.folderid = i.folderid
		left join codingtermcontexthash ctch on ctch.datapointid = dpt.datapointid
		join codingdictionaries cdict on cdict.codingdictionaryid = v.codingdictionaryid
		join projects p on p.projectid = st.projectid
		LEFT JOIN DataDictionaryEntries de ON de.DataDictionaryEntryID = dpt.DataDictEntryID
		where
			v.isusingcoder = 1
			and dpt.istouched = 1
			and dpt.ishidden = 0
			and dpt.dataactive = 1
			and dpt.deleted = 0
			and st.teststudy = 0
		option (force order)
 

		print getutcdate()
		raiserror ('#main', 0, 1) with nowait

		if object_id('tempdb..#coderdatapoints') is not null drop table #coderdatapoints

		select distinct datapointid 
		into #coderdatapoints from #main

		print getutcdate()
		raiserror ('#coderdatapoints', 0, 1) with nowait

-- START: Get max audit time based on verbatim change audit
		if object_id('tempdb.dbo.#verbatimaudits') is not null drop table #verbatimaudits

		select cd.datapointid, max(a.auditid) auditid
		into #verbatimaudits 
		from audits a
		join #coderdatapoints cd on cd.datapointid = a.objectid and a.objecttypeid = 1
		join #ASCRs t on t.auditsubcategoryid = a.auditsubcategoryid
		where
			t.tns_forverbatims = 1
		group by cd.datapointid

		print getutcdate()
		raiserror ('#verbatimaudits', 0, 1) with nowait

		
		if object_id('tempdb..#suppaudits') is not null drop table #suppaudits

		select 
			cd.datapointid, max(a.auditid) auditid
		into #suppaudits
		from #coderdatapoints cd
		join datapoints dpt on dpt.datapointid = cd.datapointid
		join #coderfields cf on cf.fieldid = dpt.fieldid
		join datapoints supdpt on supdpt.recordid = dpt.recordid and supdpt.fieldid = cf.supplemental_fieldid
		join audits a on a.objecttypeid = 1 and a.objectid = supdpt.datapointid
		join #ASCRS t on t.auditsubcategoryid = a.auditsubcategoryid
		where t.tns_forsupplementals = 1
		group by cd.datapointid

		print getutcdate()
		raiserror ('#suppaudits', 0, 1) with nowait
		

		if object_id('tempdb..#maxauditids') is not null drop table #maxauditids
		
		select
			datapointid, max(auditid) auditid
		into #maxauditids
		from
			(select * from #verbatimaudits union all select * from #suppaudits) u
		group by datapointid

		if object_id('tempdb..#maxaudits') is not null drop table #maxaudits

		select
			ma.datapointid, ma.auditid, a.audittime, a.auditsubcategoryid
		into #maxaudits
		from #maxauditids ma
		join audits a on a.auditid = ma.auditid

		print getutcdate()
		raiserror ('#maxaudits', 0, 1) with nowait

-- END: Get max audit time based on verbatim change audit


		if object_id('tempdb..#supplementalkeys') is not null drop table #supplementalkeys

		select distinct fieldid, stuff(SupplementalTermKey, 1, 1, '') SupplementalTermKey
		into #supplementalkeys
		from #coderfields cf1
		cross apply
		(
			select 
				':' + fo2.oid + '.' + fi2.oid
			from fields fi2
			join #coderfields cf2 on cf2.supplemental_fieldid = fi2.fieldid and cf2.fieldid = cf1.fieldid
			join forms fo2 ON fi2.formID = fo2.formID
			order by fi2.oid
			for xml path ('')
		) supplementals (SupplementalTermKey)

		print getutcdate()
		raiserror ('#supplementalkeys', 0, 1) with nowait


		if object_id('tempdb..#supplementaldatapoints') is not null drop table #supplementaldatapoints

		select t.datapointid, dpt2.datapointid supplemental_datapointid
		into #supplementaldatapoints
		from #coderdatapoints t
		join datapoints dpt on dpt.datapointid = t.datapointid
		join #coderfields cf on cf.fieldid = dpt.fieldid
		join datapoints dpt2 on dpt2.fieldid = cf.supplemental_fieldid and dpt2.recordid = dpt.recordid

		
 
		print getutcdate()
		raiserror ('#supplementaldatapoints', 0, 1) with nowait


		if object_id('tempdb..#supplementaldata') is not null drop table #supplementaldata

		select t.datapointid, t.supplemental_datapointid, fi.oid fieldoid, 
			case when dde.UserDataStringID is null then dpt.data
			else dbo.fnLocalDefault(dde.UserDataStringID)
			end data
		into #supplementaldata
		from #supplementaldatapoints t
		join datapoints dpt on dpt.datapointid = t.supplemental_datapointid
		join fields fi on fi.fieldid = dpt.fieldid
		left join DataDictionaryEntries dde on dde.DataDictionaryEntryID = dpt.DataDictEntryID
		
		

		print getutcdate()
		raiserror ('#supplementaldata', 0, 1) with nowait

		create clustered index idx0 on #supplementaldata (datapointid)

 
		if object_id('tempdb..#supplementalvalues') is not null drop table #supplementalvalues

		select distinct t.datapointid, s.SupplementalValues
		into #supplementalvalues
		from #supplementaldata t
		cross apply ( 
		   select stuff( 
				(select ':' + rtrim(ltrim(REPLACE(REPLACE(REPLACE(sd.data, CHAR(10),' '), CHAR(13),' '), CHAR(9),' ')))
				from #supplementaldata sd
				where
					sd.datapointid = t.datapointid
					order by sd.fieldoid
				for xml path(''),type).value('.','nvarchar(max)'),1,1,''))  s(SupplementalValues)
		

		

		print getutcdate()
		raiserror ('#supplementalvalues', 0, 1) with nowait


		if object_id('tempdb..#codingdecisions') is not null drop table #codingdecisions

		select t.datapointid, cd.created CodedDate, 
			case when x.codingpath is not null then 1 else 0 end IsCoded,
			cast(x.codingpath as nvarchar(max)) CodingPath,
			cast(y.codingterm as nvarchar(max)) CodingTerm
		into #codingdecisions
		from #coderdatapoints t
		left join coderdecisions cd on cd.datapointid = t.datapointid and cd.deleted = 0
		cross apply (
			select '/'+ ltrim(rtrim(cv.Value))
			from codervalues cv
			where cv.coderdecisionid=cd.coderdecisionid and cv.deleted=0
			order by cv.codingcolumnid,cv.codervalueid
			for xml path ('')
		) x (codingpath)
		cross apply (
			select  cc.codingcolumnname+' '+ltrim(rtrim(cv.Value))+' '+ltrim(rtrim(cv.Term))+'|'
			from codervalues cv
			inner join codingcolumns cc on cc.codingcolumnid=cv.codingcolumnid
			where cv.coderdecisionid=cd.coderdecisionid and cv.deleted=0
			order by cv.codingcolumnid,cv.codervalueid
			for xml path ('')
		) y (codingterm)
 
		print getutcdate()
		raiserror ('#codingdecisions', 0, 1) with nowait
 


		INSERT INTO ctRaveCoderExtract
				(RaveDBHash,EnvironmentName,ExternalObjectId,SiteNumber,SourceSubject,FolderOID,FolderName,
				--ParentInstance,InstanceName,
				NestedFolderPath,FormOID,FormName,PageRepeatNumber,SourceField,RecordPosition,UUID,DatapointID,HasContexthash,CodingContextURI,Locale,
				RegistrationName,Dataactive,Istouched,RecordActive,StudyActive,StudysiteActive,SubjectActive,projectactive,IsVisible,IsHidden,
				Deleted,RecordDeleted,DataPageActive,IsUsingCoder,VerbatimTerm,SupplementalTermkey,SupplementalValue,CodedDate,IsCoded,
				Codingpath,CodingTerm,Created, AuditID, AuditTime, AuditSubcategoryID)

		select distinct @RaveDBHash, m.EnvironmentName,m.ExternalObjectId,m.SiteNumber,m.SourceSubject,m.FolderOID,m.FolderName,m.NestedFolderPath,m.FormOID,m.FormName,m.PageRepeatNumber,m.SourceField,
				m.RecordPosition,m.UUID,m.DatapointID,m.HasContexthash,m.CodingContextURI,m.Locale,m.RegistrationName,m.Dataactive,m.Istouched,m.RecordActive,m.StudyActive,
				m.StudysiteActive,m.SubjectActive,m.projectactive,m.IsVisible,m.IsHidden,m.Deleted,m.RecordDeleted,m.DataPageActive,m.IsUsingCoder,m.VerbatimTerm,
				sk.SupplementalTermKey, sv.SupplementalValues,cd.CodedDate,cd.IsCoded,cd.codingpath,cd.codingterm, getdate() as created,ma.auditid, ma.audittime, ma.auditsubcategoryid
		from #main m
		join datapoints dpt on dpt.datapointid = m.datapointid
		join #coderdatapoints cdpt on cdpt.datapointid = m.datapointid
		join #maxaudits ma on ma.datapointid = dpt.datapointid
		left join #supplementalkeys sk on sk.fieldid = dpt.fieldid
		left join #supplementalvalues sv on sv.datapointid = m.datapointid
		left join #codingdecisions cd on cd.datapointid = m.datapointid

END



 