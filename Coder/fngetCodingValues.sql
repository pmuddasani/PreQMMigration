
create function getCodingValues(@CodingPath varchar(500))
RETURNS @CodingValues TABLE(
	ID int,
	CodingValue varchar(100)
	)
AS
BEGIN
;WITH SplitString as (
    SELECT
     -1 as ID, LEFT(@CodingPath,CHARINDEX('/',@CodingPath)) AS Part
            ,RIGHT(@CodingPath,LEN(@CodingPath)-CHARINDEX('/',@CodingPath)) AS Remainder
    UNION ALL
    SELECT
        SplitString.ID+1 AS ID, LEFT(Remainder,CHARINDEX('/',Remainder)-1)
           ,RIGHT(Remainder,LEN(Remainder)-CHARINDEX('/',Remainder))
        FROM SplitString
        WHERE Remainder IS NOT NULL AND CHARINDEX('/',Remainder)>0
    UNION ALL
    SELECT
       SplitString.ID+1, Remainder,null
        FROM SplitString
        WHERE Remainder IS NOT NULL AND CHARINDEX('/',Remainder)=0
)

INSERT INTO @CodingValues
SELECT ID,Part FROM SplitString 
WHERE ID >=0
RETURN;
END

--select * from codingpatterns where codingpatternid=168133

--select * from getCodingValues('/10040785/10014982/10012435/10012442/10035776')