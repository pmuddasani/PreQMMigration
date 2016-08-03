
if object_id('fnGetInfoFromHash') is not null
	drop function fnGetInfoFromHash
go
create function fnGetInfoFromHash (@hash bigint)
returns @info table (hash nvarchar(max), sourcesystemid int, url nvarchar(max), segmentname nvarchar(max), raveversion nvarchar(max), servername nvarchar(max), dbname nvarchar(max))
as
begin
	declare @ssid int

	select @ssid = ssid from codersupport.perm.CoderRaveMap 
	where hash = @hash

	insert @info select top 1 @hash, ssid, url, segmentname, raveversion, servername, dbname 
	from codersupport.perm.coderravemap
	where hash = @hash

	if @@rowcount = 0
		insert @info select @hash, -1, '', '', '', '', ''
	return
end
go

/*
select * from codersupport.perm.coderravemap
*/

