 USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Alter PROCEDURE [dbo].[Acc_CustomerSelQuery]
	@query varchar(50)
AS

/*
Created: 20090611@nahuy
Task : Select list of customer based on query string. Used for AutoComplete by "Account Info".
DB: DB05.bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    

Param's Explanation:
• @query: a beginning part of cusertomer's username.
*/

SET NOCOUNT ON

	SELECT top 10 username
	from customer with (nolock)
	where username like @query  + '%'
	order by username

GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelQuery] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelQuery] TO [vnteam]