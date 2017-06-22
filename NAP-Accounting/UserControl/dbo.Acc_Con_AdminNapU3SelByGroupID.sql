ALTER PROCEDURE [dbo].[Acc_Con_AdminNapU3SelByGroupID]
	@Groupid VARCHAR(500) = ''
AS
/*
	Created by: Johnson
	Date: 2015-01-08
	Task: Get inform of group by Name in User Control for NAPU3 site[Redmine: #28516]
	DB: DBPOLICY/BODB02
	
 
	Revisions:
		
	Explain @Param
		-@groupid = '125' if user of Unit3 view
				= '1,125' if IT view
*/
SET NOCOUNT ON
	DECLARE @tmpGroup TABLE(groupID INT)
	
	IF @groupID = '' RETURN
	
	INSERT INTO @tmpGroup
	SELECT val
	FROM strSplit(@groupid,',')

    SELECT   gi.groupname,
             ac.groupid,
             c.custid,
             c.username,
             c.firstname,
             c.lastname,
             ci.closed,
             ac.createdate,
             ct.username AS creator
    FROM     customer AS c WITH (NOLOCK)
             INNER JOIN
             custinfo AS ci WITH (NOLOCK)
             ON c.custid = ci.custid
             INNER JOIN
             acccustomer_1 AS ac WITH (NOLOCK)
             ON c.custid = ac.custid
             INNER JOIN
             acc_groupinfo_1 AS gi WITH (NOLOCK)
             ON ac.groupid = gi.groupid
             LEFT OUTER JOIN
             customer AS ct WITH (NOLOCK)
             ON ac.creator = ct.custid
    WHERE   ac.groupid IN (SELECT groupid FROM @tmpGroup)
    ORDER BY isnull(ci.closed, 0), c.username, ac.groupid

GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminNapU3SelByGroupID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminNapU3SelByGroupID] TO [vnteam] AS [dbo] 