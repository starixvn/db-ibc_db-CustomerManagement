/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_AdminSelSystembyCustID]
	@CustID INT, 
	@System VARCHAR (50)='ACCOUNTING' OUTPUT
AS
/*	Created by: Jamie 
	Date: 20101202
	Task: Get System by CustID [Group Site]
	DB: DBCUST/NAP_UserControl
		
	Revision:
		- 20110304@Amy: Add 2 groups ACCYEN and ACCNTD
		- 20110908@Johnson: Add 2 groups ACCYEN789 and ACCYEN889
		- 20111122@Johnson: Add group ACCDDD
		- 20120104@Jamie: Add ABS group 
		- 20120809@Elodie: Add ACCIRR group
		- 20130404@Jamie: Change the way to retrieve the Group Name of External Group 
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/
BEGIN
    SET NOCOUNT ON;
    SELECT @System = CASE	WHEN GroupName = 'ABS' OR GroupName LIKE 'ACC%' THEN GroupName   --ACCTHAI, ACCYEN,...
							ELSE 'ACCOUNTING' END
    FROM   dbo.AccCustomer AS c WITH (NOLOCK)
           INNER JOIN
           dbo.Acc_GroupInfo AS cg WITH (NOLOCK)
           ON c.GroupID = cg.GroupID
    WHERE  c.custid = @custid
           AND cg.system = 'ACCOUNTING';
END

GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminSelSystembyCustID] TO [bodbAdminNet,wsv_nap]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelSystembyCustID] TO [vnteam]