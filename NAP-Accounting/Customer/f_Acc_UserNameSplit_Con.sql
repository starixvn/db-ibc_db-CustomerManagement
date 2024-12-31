/*<info serverAlias="DBCUST-CustDB" selecters="wsv_nap" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Acc_UserNameSplit_Con]
(
	@string NVARCHAR(MAX),
	@splitter CHAR(1)='>'
)
RETURNS @res TABLE 
( 
	UserName VARCHAR(100)
)
AS
/*
	Created: Tacy@20241231
	Task: function support to split string 
	DB: DBCUST/CustDB
		
	Revisions:
		- 20240704@Tacy: Create function [Redmine: #206291]
		
	Parameter's Explanation:
		-@string : string need to split ex: 'SJK2A>Q'
		-@splitter1: character to separate substring ex: '>'
*/
BEGIN
	DECLARE @subName VARCHAR(100)
		,@pos INT, @i INT = 1
		,@iStart INT, @IsNum BIT
		,@MinChar SMALLINT, @MaxChar SMALLINT

	INSERT INTO @res (UserName)
	SELECT TOP 1 TRIM(value) 
	FROM STRING_SPLIT(@string,@splitter)
	WHERE TRIM(value)<>''

	SELECT @pos=CHARINDEX('>', @string)
		, @IsNum = ISNUMERIC(SUBSTRING(@string, @pos+1, LEN(@string)))

	IF @IsNum=0 AND CAST(PATINDEX('%[0-9]%',SUBSTRING(@string, @pos+1, LEN(@string))) AS BIT)=1
		RETURN
	
	IF @IsNum=1	
		SET @iStart = PATINDEX('%[0-9]%', @string)

	SELECT @MinChar=CASE WHEN @IsNum=0 THEN ASCII(UPPER(SUBSTRING(@string, @pos-1, 1))) 
						 ELSE SUBSTRING(@string, @iStart, @pos-@iStart)
					END
		, @MaxChar=CASE WHEN @IsNum=0 THEN ASCII(UPPER(SUBSTRING(@string, @pos+1, 1))) 
						 ELSE SUBSTRING(@string, @pos+1, @pos-@iStart)
					END

	SELECT @MaxChar = CASE WHEN @MinChar > @MaxChar THEN @MinChar ELSE @MaxChar END
		, @i += @MinChar

	-- Representative Username
	SELECT @subName=SUBSTRING(t.UserName, 1, LEN(t.UserName)-LEN(CASE WHEN @IsNum = 0 THEN CHAR(@MinChar) ELSE CAST(@MinChar AS varchar(5)) END))
	FROM @res t 

	WHILE (@i<=@MaxChar)
	BEGIN
		INSERT INTO @res (UserName)
		SELECT @subName 
			+ CASE WHEN @IsNum = 0 THEN CHAR(@i) ELSE CAST(@i AS varchar(5)) END
			
		SET @i += 1
	END
	
	RETURN;
END
GO