/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,bodbDownlineNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
USE [IPDB]
GO
/****** Object:  UserDefinedFunction [dbo].[strSplit]    Script Date: 03/23/2018 09:22:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  User Defined Function dbo.strSplit    Script Date: 12/5/2013 4:31:58 PM ******/

/****** Object:  User Defined Function dbo.strSplit    Script Date: 8/5/2013 4:08:39 PM ******/
ALTER FUNCTION [dbo].[strSplit](@string [nvarchar](MAX), @splitter [char](1))
RETURNS @res TABLE (
    [id] [int] NOT NULL,
    [rank] [int] NULL,
    [val] [nvarchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
    [id] ASC
)
) WITH EXECUTE AS CALLER
AS 
begin
	 
     if substring ( @string, len ( @string), 1)<>@splitter
          set @string= @string+@splitter
     declare @start int, @word nvarchar(max), @charindex int, @i int
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

