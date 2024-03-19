/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Task_Winlimit_CustWinlostGameDel]	
AS
/*   
	Create: 20220829@Johnson
	Task : Delete history data winlimit game - [Redmine:175278]
	DB: DBCUST/CUSTDB
	
	Revisions:
		- 20220829@Johnson: Initial sp [Redmine: 175278]
		
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Winlostdate SMALLDATETIME
	
	SELECT @Winlostdate =  DATEADD(DAY,-7,GETDATE())
	
	WHILE(1=1)
	BEGIN
		DELETE TOP (5000) WinLimit_CustWinlostGame WITH(ROWLOCK)
		WHERE Winlostdate < @Winlostdate
		
		IF @@ROWCOUNT = 0
			BREAK;
	END
	
END	