

if object_id('spRunBatch') is not null drop procedure spRunBatch
go

create procedure spRunBatch
as
begin
	declare @hash bigint
	declare @sourcesystemid int
	declare @url nvarchar(max), @segmentname nvarchar(max), @raveversion nvarchar(max), @servername nvarchar(max), @dbname nvarchar(max)

	set nocount on

	select @hash = min(ravedbhash) from ctRaveCoderExtract where ravedbhash not in 
		(select hash from CoderSupport.Perm.BatchStatus where status in ('processing', 'processed'))

	if @hash is not null
		begin
			select @sourcesystemid = sourcesystemid, @url = url, @segmentname = segmentname, @raveversion = raveversion, @servername = servername, @dbname = dbname
			from fnGetInfoFromHash(@hash)

			declare @dt datetime = getutcdate()

			if exists (select * from CoderSupport.Perm.BatchStatus where hash = @hash)
				update CoderSupport.Perm.BatchStatus set segmentname = @segmentname, sourcesystemid = @sourcesystemid, status = 'processing', startdt = @dt where hash = @hash
			else
				insert CoderSupport.Perm.BatchStatus (hash, segmentname, sourcesystemid, status, startdt) select @hash, @segmentname, @sourcesystemid, 'processing', @dt
	
			print 'hash=' + cast(@hash as nvarchar(max)) + ' segment=' + @segmentname + ' sourcesystemid=' + cast(@sourcesystemid as nvarchar(max)) + ' status=processing startdt=' + cast(@dt as nvarchar(max))
		
			Update ctRaveCoderExtract
			set RaveToken=@sourcesystemid
			where ravedbhash=@hash

			exec spCorrelateCoderTasks @sourcesystemid

			update CoderSupport.Perm.BatchStatus set status = 'processed', enddt = getutcdate() where hash = @hash
			
		end
	else
		print 'Nothing is pending.'
end
go


/*
exec spRunBatch 
update ctRaveCoderExtract set RaveDBHash = -8392051912038022742
select  min(ravedbhash)  from ctRaveCoderExtract
select * from  CoderSupport.Perm.BatchStatus
delete CoderSupport.perm.BatchStatus

*/