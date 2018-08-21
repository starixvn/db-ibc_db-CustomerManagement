/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbExtAccNet,BODBDownlineNet,BODBDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerIsInternalAdmin]
	@CustID INT,
	@IsInternalAdmin BIT = 0 OUTPUT, 
	@IsAllowAccess BIT = 0 OUTPUT 
AS
/*
	Created: 20160901@Elodie
	Task: check if the account is an internal admin and has permission to access special site
	Database: DBCUST/CUSTDB
	
	Revision:
		- 20161111@Elodie: Remove hardcode statrix, add list username who has permission to access special site		
		- 20161205@Winnie: Remove hardcode like statrix [RedmineID:#67772]
		- 20170816@Elodie: Add more starix account [Redmine: #81730]
		- 20180808@Helen: DB05.DBPOLICY migration  - Move to DBCUST [Redmine:99462]
		
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserName NVARCHAR(50)
	SELECT @IsInternalAdmin = 0, @IsAllowAccess = 1

	IF EXISTS (	SELECT 1 
				FROM NAP_UserControl.dbo.acccustomer ac WITH (NOLOCK)
					INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = ac.custid
				WHERE ci.roleid > 4 AND ac.custid = @CustID )
	BEGIN
		SELECT @IsInternalAdmin = 1
		SELECT @UserName=UserName FROM dbo.custInfo WITH(NOLOCK) WHERE custid=@CustID
		
		IF @CustID NOT IN (	360418		--starix1
							,15471134	--starix10
							,15477066	--starix11
							,15477075	--starix12
							,862400		--starix2
							,15512861	--starix20
							,15512891	--starix21
							,15513549	--starix23
							,15552859	--starix26
							,15560315	--starix27
							,169368		--starix3
							,16994226	--starix37
							,1070340	--starix4
							,22040268	--starix59
							,22040272	--starix60
							,22040275	--starix61
							,24103343	--starix65
							,15470946	--starix7
							,15470969	--starix8
							,15471129	--starix9
							,10278938	--starixIT
							/*-- 20170816@Elodie: Add more starix account*/
							,26870995	--starix68
							,26871005	--starix69
							,26871009	--starix70
							,26879871	--starix71
							,16492113	--starix33
						) AND @UserName LIKE 'starix%'			
			SELECT @IsAllowAccess = 0
	END
END


GO
GRANT EXECUTE ON [Acc_CustomerIsInternalAdmin] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [Acc_CustomerIsInternalAdmin] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [Acc_CustomerIsInternalAdmin] TO BODBDownlineNet
GO
GRANT EXECUTE ON [Acc_CustomerIsInternalAdmin] TO BODBDownlineNetView
GO
 
GRANT VIEW DEFINITION ON [Acc_CustomerIsInternalAdmin] TO [vnteam]

