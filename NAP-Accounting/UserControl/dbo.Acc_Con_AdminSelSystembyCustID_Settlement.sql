
ALTER PROCEDURE [dbo].[Acc_Con_AdminSelSystembyCustID_Settlement]
	@CustID INT, 
	@System VARCHAR (50)='ACCOUNTING' OUTPUT
AS
/*	Created by: Jamie 
	Date: 20101202
	Task: Get System by CustID [Group Site]
	DB: DB03.BODB02
		
	Revision:
		- 20110304@Amy: Add 2 groups ACCYEN and ACCNTD
		- 20110908@Johnson: Add 2 groups ACCYEN789 and ACCYEN889
		- 20111122@Johnson: Add group ACCDDD
		- 20120104@Jamie: Add ABS group 
		- 20120719@Kevin: Add Settlement group 
*/
BEGIN
    SET NOCOUNT ON;
    SELECT @System = CASE WHEN 
								  GroupName = 'SETTLEMENT'
							   OR GroupName = 'ABS'
							   OR GroupName = 'ACCTHAI'
                               OR GroupName = 'ACCINDO'
                               OR GroupName = 'ACCYEN'
                               OR GroupName = 'ACCYEN789'
                               OR GroupName = 'ACCYEN889'
                               OR GroupName = 'ACCDDD'
                               OR GroupName = 'ACCNTD' THEN GroupName ELSE 'ACCOUNTING' END
    FROM   dbo.AccCustomer_1 AS c WITH (NOLOCK)
           INNER JOIN
           dbo.Acc_GroupInfo_1 AS cg WITH (NOLOCK)
           ON c.GroupID = cg.GroupID
    WHERE  c.custid = @custid
           AND cg.system = 'ACCOUNTING';
END


GO
GRANT EXECUTE
    ON [dbo].[Acc_Con_AdminSelSystembyCustID_Settlement] TO [bodbAdminNet];


GO
GRANT VIEW DEFINITION
    ON [dbo].[Acc_Con_AdminSelSystembyCustID_Settlement] TO [vnteam];

 