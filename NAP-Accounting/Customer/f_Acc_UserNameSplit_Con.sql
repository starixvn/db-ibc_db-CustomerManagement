/*<info serverAlias="DBCUST-CustDB" selecters="wsv_nap" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Acc_UserNameSplit_Con]
(
	@string NVARCHAR(MAX),
	@splitter CHAR(1)='>'
)
RETURNS @res TABLE 
( 
	UserName VARCHAR(100)
	,ErrCode INT
	,ErrMsg VARCHAR(2000)
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
		,@pos INT, @i INT
		,@iNumStart INT
		,@IsNum_Bf BIT, @IsNum_Af BIT	--value before/after splitter is all numberic?
		,@MinChar SMALLINT, @MaxChar SMALLINT

	SELECT @pos=CHARINDEX('>', @string)
	
	SELECT @IsNum_Bf = ISNUMERIC(SUBSTRING(@string, @pos-1, 1))
		, @IsNum_Af = ISNUMERIC(SUBSTRING(@string, @pos+1, LEN(@string)))

	IF @IsNum_Bf<>@IsNum_Af
	BEGIN	
		INSERT INTO @res(UserName,ErrCode, ErrMsg)
		SELECT @string, 11, 'Cannot generate sequence. Please use format like ''AA1>5'' or ''AAA>C'''
		RETURN
	END

	IF @IsNum_Bf=1
	BEGIN
		SET @i=@pos-1
		SET @iNumStart = @i

		WHILE ISNUMERIC(SUBSTRING(@string, @i, 1))=1
		BEGIN
			SET @iNumStart = @i
			SET @i-=1
		END
	END

	SELECT @MinChar=CASE WHEN @IsNum_Bf=0 THEN ASCII(UPPER(SUBSTRING(@string, @pos-1, 1))) 
						 ELSE SUBSTRING(@string, @iNumStart, @pos-@iNumStart)
					END
		, @MaxChar=CASE WHEN @IsNum_Bf=0 THEN ASCII(UPPER(SUBSTRING(@string, @pos+1, 1))) 
						 ELSE SUBSTRING(@string, @pos+1, LEN(@string) - @pos)
					END
		, @i=0

	IF @MinChar>@MaxChar
	BEGIN	
		INSERT INTO @res(UserName,ErrCode, ErrMsg)
		SELECT @string, 12, 'Cannot generate sequence. Please use format like ''AA1>5'' or ''AAA>C'''
		RETURN
	END

	INSERT INTO @res (UserName)
	SELECT TOP 1 TRIM(value) 
	FROM STRING_SPLIT(@string,@splitter)
	WHERE TRIM(value)<>''

	SELECT @i += @MinChar

	-- Representative Username
	SELECT @subName=SUBSTRING(t.UserName, 1, LEN(t.UserName)-LEN(CASE WHEN @IsNum_Af = 0 THEN CHAR(@MinChar) ELSE CAST(@MinChar AS varchar(5)) END))
	FROM @res t 

	WHILE (@i<=@MaxChar)
	BEGIN
		IF @IsNum_Bf = 0
			INSERT INTO @res (UserName)
			SELECT @subName + CHAR(@i)
		ELSE
			INSERT INTO @res (UserName)
			SELECT @subName + CAST(@i AS varchar(5))

		SET @i += 1
	END
	
	RETURN;
END
GO