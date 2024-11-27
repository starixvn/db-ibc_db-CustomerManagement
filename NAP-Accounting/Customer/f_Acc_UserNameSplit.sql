/*<info serverAlias="DBCUST-CustDB" selecters="wsv_nap" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Acc_UserNameSplit]
(
	@string NVARCHAR(MAX),
	@splitter1 CHAR(1),
	@splitter2 CHAR(1),
	@splitter3 CHAR(1)=''
)
RETURNS @res TABLE 
( 
	UserName VARCHAR(100)
)
AS
/*
	Created: Tacy@20240704
	Task: function support to split string 
	DB: DBCUST/CustDB
		
	Revisions:
		- 20240704@Tacy: Create function [Redmine: #206291]
		
	Parameter's Explanation:
		-@string : string need to split ex: 'SJK2P-Q-,R-S-T-U-V-W-X-Y'
		-@splitter1: character to separate substring ex: ','
		-@splitter2: character to separate UserName ex: '-'
*/
BEGIN
	DECLARE @tmp TABLE (RowID INT IDENTITY(1,1)
						,val VARCHAR(200)
						,IsFinished BIT DEFAULT(0))

	DECLARE @subName VARCHAR(100), @batch INT = 1000
	DECLARE @splitter VARCHAR(1), @pos INT

	SELECT @pos=LEN(@string)
	
	--Choose: first char to split
	SELECT @pos=CASE WHEN CHARINDEX(@splitter1, @string) BETWEEN 1 AND @pos AND ISNULL(@splitter1,'')<>''
					THEN CHARINDEX(@splitter1, @string) ELSE @pos 
				END
		,@splitter=CASE WHEN CHARINDEX(@splitter1, @string) BETWEEN 1 AND @pos AND ISNULL(@splitter1,'')<>''
						THEN @splitter1 ELSE @splitter 
					END

	SELECT @pos=CASE WHEN CHARINDEX(@splitter2, @string) BETWEEN 1 AND @pos AND ISNULL(@splitter2,'')<>''
					THEN CHARINDEX(@splitter2, @string) ELSE @pos 
				END
		,@splitter=CASE WHEN CHARINDEX(@splitter2, @string) BETWEEN 1 AND @pos AND ISNULL(@splitter2,'')<>''
						THEN @splitter2 ELSE @splitter 
					END


	SELECT @splitter=CASE WHEN CHARINDEX(@splitter3, @string) BETWEEN 1 AND @pos AND ISNULL(@splitter3,'')<>''
						THEN @splitter3 ELSE @splitter 
					END

	-- @string does not include a character to split the text
	IF ISNULL(@splitter,'')='' 
	BEGIN
		INSERT INTO @res(UserName)
		SELECT @string

		RETURN
	END

	INSERT INTO @tmp (val)
	SELECT TRIM(value) 
	FROM STRING_SPLIT(@string,@splitter)
	WHERE TRIM(value)<>''
	
	-- @splitter1
	INSERT INTO @tmp (val)
	SELECT TRIM(value)
	FROM @tmp t
	CROSS APPLY STRING_SPLIT(t.val,@splitter1) ss
	WHERE t.val LIKE '%'+@splitter1+'%'
		AND TRIM(value)<>''

	DELETE FROM @tmp
	WHERE val LIKE '%'+@splitter1+'%'
	
	-- @splitter2
	IF ISNULL(@splitter2,'')<>''
	BEGIN
		INSERT INTO @tmp (val)
		SELECT TRIM(value)
		FROM @tmp t
		CROSS APPLY STRING_SPLIT(t.val,@splitter2) ss
		WHERE t.val LIKE '%'+@splitter2+'%'
			AND TRIM(value)<>''

		DELETE FROM @tmp
		WHERE val LIKE '%'+@splitter2+'%'
	END

	-- @splitter3
	IF ISNULL(@splitter3,'')<>''
	BEGIN
		INSERT INTO @tmp (val)
		SELECT TRIM(value)
		FROM @tmp t
		CROSS APPLY STRING_SPLIT(t.val,@splitter3) ss
		WHERE t.val LIKE '%'+@splitter3+'%'
			AND TRIM(value)<>''
	END

	DELETE FROM @tmp
	WHERE val LIKE '%'+@splitter3+'%'

	-- Representative Username
	DECLARE @mRowID INT
	
	SELECT @mRowID=MIN(RowID) FROM @tmp
	
	INSERT INTO @res (UserName)
	SELECT val FROM @tmp t 
	WHERE RowID=@mRowID

	SELECT @subName=SUBSTRING(t.val, 1, LEN(t.val)-1)
	FROM @tmp t 
	WHERE RowID=@mRowID

	WHILE EXISTS (SELECT TOP 1 1 FROM @tmp WHERE IsFinished=0)
	BEGIN
		UPDATE TOP (@batch) t
		SET t.val=@subName+t.val
			,t.IsFinished=1
		FROM @tmp t
		WHERE RowID>@mRowID AND IsFinished=0
		
		IF @@ROWCOUNT=0
			BREAK

		INSERT INTO @res (UserName)
		SELECT val
		FROM @tmp t
		 LEFT JOIN @res r ON r.UserName=t.val
		WHERE IsFinished=1 AND r.UserName IS NULL
	END
	
	RETURN;
END
GO