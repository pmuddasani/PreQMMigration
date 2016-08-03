
if object_id('CoderSupport.perm.BatchStatus') is not null
	drop table CoderSupport.perm.BatchStatus
go

create table CoderSupport.perm.BatchStatus (
	segmentname nvarchar(max), 
	sourcesystemid int,
	status nvarchar(max), 
	startdt datetime,
	enddt datetime,
	hash nvarchar(max)
)
go

/*

select * from CoderSupport.perm.BatchStatus

*/