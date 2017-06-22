
ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoSel]
	@GroupID int = null,
	@UserID int = 0,
	@ShowInternalGroup bit = 1,
	@System nvarchar(50) = 'ACCOUNTING'
AS 
/*
	Created by: []
	Task: Get group info in User Control 
	DB: DB03.BODB02
 
	Revisions:
		- 20110526@Tom: Remove condition @System 
		- 20120828@Elodie: IT department are only be seen by IT department users.
		- 20121129@Johnson: hard code to hide some ABS's users
		- 20121219@Johnson: Fix to show department which not have users
		- 20140109@Lukas: exclude external group 

	Param's explanation:
		- @ShowInternalGroup: 
			1: Show all departments with all users
			0: Show IT department with only IT department users (GroupID of IT department = 1)

*/

SET NOCOUNT ON  
IF(@ShowInternalGroup = 0)
begin
	Declare @UserGroupID int
	select @UserGroupID = GroupID
	from accCustomer_1 with (NOLOCK)	
	where custid = @UserID
end


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

IF @groupid is null
BEGIN						
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from acc_groupinfo_1  gi with(nolock)
			LEFT JOIN AccCustomer_1 ac with(nolock) on ac.groupid=gi.groupid
		where system = @System and
			gi.GroupID <> CASE WHEN @UserGroupID = 1 or @ShowInternalGroup = 1 THEN 0 ELSE 1 end and
			ISNULL(ac.custid,0) NOT IN (SELECT custid FROM @ABS)
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
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.displayorder ,gi.groupname 	
END
ELSE
BEGIN
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from acc_groupinfo_1  gi with(nolock)
			LEFT JOIN AccCustomer_1 ac with(nolock) on gi.groupid=ac.groupid	
   		WHERE gi.groupid=@groupid and
   			gi.GroupID <> CASE WHEN @UserGroupID = 1 or @ShowInternalGroup = 1 THEN 0 ELSE 1 end AND
   			ISNULL(ac.custid,0) NOT IN (SELECT custid FROM @ABS)
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
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.displayorder ,gi.groupname
END


GO
GRANT EXECUTE ON [dbo].[Acc_Con_GroupInfoSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoSel] TO [vnteam] AS [dbo]

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoSel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].Acc_Con_GroupInfoSel TO [bodbAdminNet]