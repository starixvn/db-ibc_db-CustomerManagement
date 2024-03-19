/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_ManualUpdAcc_Sel]
	@SportType INT = NULL,
	@UserName NVARCHAR(50) = NULL
AS
/*    
	Created: 20200310@Eden    
	Task :  Select Manually Updated Virtual Rate Accounts
	DB: CustDB/DBCUST
	    
	Revisions:    
		- 20200310@Eden : First commit [Redmind: #128749]
  
*/ 
BEGIN
	DECLARE @CustID INT

	SELECT vr.CustID
		,c.Username
		,[Level] = CASE WHEN c.RoleID = 1 THEN 'Member'
						WHEN c.RoleID = 2 THEN 'Agent'
						WHEN c.RoleID = 3 THEN 'Master'
						WHEN c.RoleID = 4 THEN 'Super'
					END
	FROM [dbo].[VRSettingManualUpdAcc] vr WITH(NOLOCK)
		INNER JOIN custinfo c WITH(NOLOCK)
			ON vr.CustID = c.CustID
	WHERE SportType = @SportType
		AND c.UserName = ISNULL(NULLIF(@UserName,''),c.UserName)
	ORDER BY c.Username
END