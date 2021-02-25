/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_VR_MemberBigStake_Ins   
AS  
/*  
	Created:	20210219@Eden:	
	Task:		Insert new agent to VRMemberBigStake table
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20210219@Eden: First commit [#150298]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_MemberBigStake_Ins
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	DECLARE @NewLogData VARCHAR(MAX)
	SET @startRun = getdate()

	DECLARE @Inserted_Cust TABLE (CustID INT, Type TINYINT,Islog BIT DEFAULT 0)

	CREATE TABLE #TblCust (CustID INT, Type TINYINT)

	INSERT INTO #TblCust(CustID,Type)
	SELECT c.custid, p.Type
	FROM Customer c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
		INNER JOIN dbo.f_GetVRBigStakeConfig(NULL) p ON p.site = c.site
		INNER JOIN exchange e WITH(NOLOCK) On ci.currency = e.ExchangeId
		LEFT JOIN VRMemberBigStake v WITH(NOLOCK) ON v.custid = c.custid AND v.Type = p.Type
	WHERE c.roleid = 1
		AND v.CustID IS NULL
		AND c.creatdate > = p.ReleasedDate
		AND c.creatdate BETWEEN DATEADD(hh,-25,GETDATE()) AND GETDATE()

	WHILE 0 = 0
	BEGIN
		DELETE FROM @Inserted_Cust

		DELETE TOP(10000) t
		OUTPUT deleted.CustID,deleted.Type INTO @Inserted_Cust(CustID,Type)
		FROM #TblCust t

		IF @@ROWCOUNT = 0 
			BREAK

		INSERT INTO VRMemberBigStake(CustID,Type,Status)
		SELECT t.custid, t.Type, 0 AS Status
		FROM @Inserted_Cust t
			LEFT JOIN VRMemberBigStake v WITH(NOLOCK) ON v.custid = t.custid AND v.Type = t.Type
		WHERE v.CustID IS NULL

		SET @endRun = getdate()  
		SET @duration  = datediff (millisecond,@startRun,@endRun) 
	
		SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
				(	SELECT CustID AS '@CustID',
							Type AS '@Type' 
					FROM @Inserted_Cust
					FOR XML PATH('Row'), ROOT ('R'), TYPE)
			)

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= 0,
				@ActionId			= 825,
				@TrackingValue		= @NewLogData,
				@Duration			= @Duration
		
		END
END
GO
