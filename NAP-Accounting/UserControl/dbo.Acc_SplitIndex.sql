/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Acc_SplitIndex]
 (@string NVARCHAR(4000), @splitter CHAR, @index INT)  
RETURNS NVARCHAR(4000) AS  
/*  
 Created by: N/A
 Task:  
 DB: DBCUST/NAP_UserControl
  
 Revisions:  
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]					 
     
 Explain @Paramater  
  -- Format of @GroupPolicys: @FuncID,@Policy@FuncID,@Policy ...   
*/  

BEGIN 

	IF SUBSTRING(@string, len(@string), 1) <> @splitter
		SET @string = @string + @splitter

	DECLARE @word NVARCHAR(4000) SET @word = ''
	DECLARE @start INT SET @start = 1
	DECLARE @i INT SET @i = 1
	DECLARE @charindex INT SET @charindex = CHARINDEX(@splitter, @string, @start)

	WHILE (@charindex <> 0)
	BEGIN
          SET @word= SUBSTRING(@string, @start, @charindex - @start)
          SET @start= @charindex + 1
          SET @charindex= CHARINDEX(@splitter, @string, @start)
		  IF @i = @index RETURN @word
          SET @i=@i+1
    END

	Return @string

END
GO
GRANT EXECUTE ON [dbo].[Acc_SplitIndex] TO [bodbAdminNet]
GO