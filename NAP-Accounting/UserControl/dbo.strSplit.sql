/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="1" isNested="0"></info>*/
ALTER function  [dbo].[strSplit] ( @string nvarchar( 4000), @splitter char( 1) )
returns @res table ( id int primary key, rank int, val nvarchar( 4000) )
as
/*  
 Created by: N/A
 Task:  
 DB: DBCUST/NAP_UserControl
  
 Revisions:  
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]					 
*/  
begin
     if substring ( @string, len ( @string), 1)<>@splitter
          set @string= @string+@splitter
     declare @start int, @word nvarchar(4000), @charindex int, @i int
     set @i=1
     set @start=1
     set @charindex= charindex( @splitter, @string, @start)
     while (@charindex <> 0)begin
          set @word= substring( @string, @start, @charindex - @start)
          set @start= @charindex +1
          set @charindex= charindex( @splitter, @string, @start)
          insert into @res  values ( @start, @i, @word)
          set @i=@i+1
     end
     return
end
GO


