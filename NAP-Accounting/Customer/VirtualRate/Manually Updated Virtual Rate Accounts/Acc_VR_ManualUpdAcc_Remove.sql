/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_ManualUpdAcc_Remove]
	@SportType INT = NULL,
	@CustIDs VARCHAR(MAX)
AS
/*    
	Created: 20200310@Eden    
	Task :  Remove Manually Updated Virtual Rate Accounts
	DB: CustDB/DBCUST
	    
	Revisions:    
		- 20200310@Eden : First commit [Redmind: #128749]
  
*/ 
BEGIN
	CREATE TABLE #CustIDs(CustID INT)

	INSERT INTO #CustIDs(CustID)
	SELECT val 
	FROM dbo.f_StringSplit(@CustIDs,',') 
	OPTION (MAXRECURSION 0)

	DELETE vr
	FROM [dbo].[VRSettingManualUpdAcc] vr WITH(NOLOCK)
	WHERE vr.SportType = @SportType
		AND vr.CustID IN ( SELECT CustID FROM #CustIDs)
END