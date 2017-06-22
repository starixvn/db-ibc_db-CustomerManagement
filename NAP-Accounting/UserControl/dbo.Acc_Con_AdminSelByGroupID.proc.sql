ALTER PROCEDURE [dbo].[Acc_Con_AdminSelByGroupID]
	@Groupid INT = NULL, 
	@UserID int = 0,
	@ShowInternalGroup bit = 1,
	@Username VARCHAR (30)='%', 
	@FirstChar NVARCHAR (6)='%', 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Get inform of group by Name in User Control
	DB: DB03.BODB02
 
	Revisions:
		- 20110526@Tom: Remove condition @System 
		- 20120828@Elodie: IT admin are only be seen by IT department users.
		- 20121129@Johnson: hard code to hide some ABS's users
		- 20140109@Lukas: exclude user admin in external group
	Explain @Param
		--Search username: '%username%'
		--Search first char:
		--A: 'A%'
		--B: 'B%'
		--0-9: '[0-9]%'
		--@ShowInternalGroup: 
			1: Show all departments with all users
			0: Show IT department with only IT department users (GroupID of IT department = 1)
*/
SET NOCOUNT ON

DECLARE @ABS TABLE (custid int)

INSERT INTO @ABS(custid)
SELECT 5452637 --ABS014
UNION SELECT 5452639 --ABS015
UNION SELECT 5519908 --ABS016
UNION SELECT 5519911 --ABS017
UNION SELECT 5519914 --ABS018
UNION SELECT 5519916 --ABS019
UNION SELECT 5519917 --ABS020
UNION SELECT 5519919 --ABS021
UNION SELECT 5519921 --ABS022
UNION SELECT 5519922 --ABS023
UNION SELECT 5519924 --ABS024
UNION SELECT 5519926 --ABS025
UNION SELECT 5848823 --ABS026
UNION SELECT 6081162 --ABSJackyTING.

IF(@ShowInternalGroup = 0)
begin
	Declare @UserGroupID int
	select @UserGroupID = GroupID
	from accCustomer_1 with (NOLOCK)	
	where custid = @UserID
end


IF @Groupid IS NULL
    BEGIN
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
        WHERE    c.username LIKE @Username AND 
				 c.username LIKE @FirstChar and				 
				 ac.GroupID <> CASE WHEN @UserGroupID = 1 or @ShowInternalGroup = 1 THEN 0 ELSE 1 end AND
				 ac.custid NOT IN (SELECT custid FROM @ABS)
				 AND gi.groupid NOT IN (
											128	, --ACCTHAI
											134	, --ACCINDO
											136	, --ACCYEN
											137	, --ACCNTD
											140	, --ACCYEN789
											141	, --ACCYEN889
											142	, --ACCDDD
											148	, --ACCIRR
											152	, --ACCUUS
											154	, --ACCUSD
											155	, --ACCUT
											156	  --AccYen668
										)
        ORDER BY isnull(ci.closed, 0), c.username, ac.groupid
    END
ELSE
    BEGIN
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
                 (SELECT custid,
						groupid,
						creator,
                         createdate
                  FROM   acccustomer_1 WITH (NOLOCK)
                  WHERE  groupid = @groupid
						AND custid NOT IN (SELECT custid FROM @ABS)
					) AS ac
                 ON c.custid = ac.custid
                 INNER JOIN
                 acc_groupinfo_1 AS gi WITH (NOLOCK)
                 ON ac.groupid = gi.groupid
                 LEFT OUTER JOIN
                 customer AS ct WITH (NOLOCK)
                 ON ac.creator = ct.custid
        WHERE    c.username LIKE @Username
                 AND c.username LIKE @FirstChar and
				 ac.GroupID <> CASE WHEN @UserGroupID = 1 or @ShowInternalGroup = 1 THEN 0 ELSE 1 end 	
				 AND gi.groupid NOT IN (
											128	, --ACCTHAI
											134	, --ACCINDO
											136	, --ACCYEN
											137	, --ACCNTD
											140	, --ACCYEN789
											141	, --ACCYEN889
											142	, --ACCDDD
											148	, --ACCIRR
											152	, --ACCUUS
											154	, --ACCUSD
											155	, --ACCUT
											156	  --AccYen668
										)			 
        ORDER BY isnull(ci.closed, 0), c.username, ac.groupid
    END
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminSelByGroupID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelByGroupID] TO [vnteam] AS [dbo]