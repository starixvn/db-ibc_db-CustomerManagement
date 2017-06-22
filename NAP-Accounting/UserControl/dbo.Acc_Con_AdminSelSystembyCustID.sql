ALTER PROCEDURE [dbo].[Acc_Con_AdminSelSystembyCustID]
	@CustID INT, 
	@System VARCHAR (50)='ACCOUNTING' OUTPUT
AS
/*	Created by: Jamie 
	Date: 20101202
	Task: Get System by CustID [Group Site]
	DB: DBPOLICY/BODB02
		
	Revision:
		- 20110304@Amy: Add 2 groups ACCYEN and ACCNTD
		- 20110908@Johnson: Add 2 groups ACCYEN789 and ACCYEN889
		- 20111122@Johnson: Add group ACCDDD
		- 20120104@Jamie: Add ABS group 
		- 20120809@Elodie: Add ACCIRR group
		- 20130404@Jamie: Change the way to retrieve the Group Name of External Group 
		
*/
BEGIN
    SET NOCOUNT ON;
    SELECT @System = CASE	WHEN GroupName = 'ABS' OR GroupName LIKE 'ACC%' THEN GroupName   --ACCTHAI, ACCYEN,...
							ELSE 'ACCOUNTING' END
    FROM   dbo.AccCustomer_1 AS c WITH (NOLOCK)
           INNER JOIN
           dbo.Acc_GroupInfo_1 AS cg WITH (NOLOCK)
           ON c.GroupID = cg.GroupID
    WHERE  c.custid = @custid
           AND cg.system = 'ACCOUNTING';
END

GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminSelSystembyCustID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelSystembyCustID] TO [vnteam]