
IF EXISTS (SELECT * FROM sysobjects WHERE type = 'FN' AND name = 'fnWebServicesGetNestedFolderPath')
	DROP FUNCTION dbo.fnWebServicesGetNestedFolderPath
GO

CREATE FUNCTION dbo.fnWebServicesGetNestedFolderPath
(
	@InstanceID		int
)
RETURNS VARCHAR(255)
AS
BEGIN
	  DECLARE @parentInstanceID int, @InstanceRepeatNumber int, @FolderOid varchar(255), @outputString varchar(255)
      IF ISNULL(@instanceID, 0)<>0
      BEGIN
            SELECT @parentInstanceID=i.ParentInstanceID, @FolderOid=f.Oid, @InstanceRepeatNumber=i.InstanceRepeatNumber + 1
            FROM Instances i JOIN Folders f ON f.FolderId = i.FolderId
            WHERE i.InstanceID=@instanceID

            IF ISNULL(@parentInstanceID, 0)<>0
            BEGIN
                  SET @outputString=dbo.fnWebServicesGetNestedFolderPath( @parentInstanceID ) +'/'+@FolderOid+'['+CAST( @instanceRepeatNumber  AS varchar(50))+']'
            END
            ELSE
            BEGIN
                 -- @NestedFolderPath + @FolderOid + '[' + i.InstanceRepeatNumber + '] / '
                  SET @outputString=@FolderOid+'['+CAST(@instanceRepeatNumber AS varchar(50))+']'
            END
      END
      ELSE SET @outputString=NULL

      RETURN @outputString

END