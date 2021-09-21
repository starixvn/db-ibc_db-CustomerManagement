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
		- 20210301@Eden: If member soccer hdp vr < site value, then insert the members into the VRMemberBigStake [#150298]
		- 20210914@Eden: Amendment on Virtual Rate by Big stake request [#156824]

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
	DECLARE @custID INT, @Type TINYINT, @LogData_member VARCHAR(MAX) --log each member
	SET @startRun = getdate()

	DECLARE @Inserted_Cust TABLE (CustID INT, Type TINYINT, IsWL BIT, Islog BIT DEFAULT 0)

	CREATE TABLE #TblCust (CustID INT, Type TINYINT, IsWL BIT)

	INSERT INTO #TblCust(CustID,Type,IsWL)
	SELECT c.custid, p.Type,
		IsWL = CASE WHEN dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) < p.VRValue THEN 0 ELSE 1 END
	FROM Customer c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
		INNER JOIN dbo.f_GetVRBigStakeConfig(NULL) p ON p.site = c.site
		LEFT JOIN VRMemberBigStake v WITH(NOLOCK) ON v.custid = c.custid AND v.Type = p.Type
		INNER JOIN CustVirtualSetting cvs WITH(NOLOCK)
			ON cvs.custid = ci.custid
		INNER JOIN  ProfileVirtualSetting pvs WITH(NOLOCK)
			ON  cvs.seqNo = pvs.seqNo
	WHERE c.roleid = 1
		AND v.CustID IS NULL
		AND c.creatdate > = p.ReleasedDate
		AND c.creatdate BETWEEN DATEADD(hh,-25,GETDATE()) AND GETDATE()
		AND pvs.isActive = 1
		AND pvs.sporttype = 1 AND pvs.bettype = 1 AND pvs.islive = 1
		--AND dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) < p.VRValue

	--Insert members to queue
	WHILE 0 = 0
	BEGIN
		DELETE FROM @Inserted_Cust

		DELETE TOP(10000) t
		OUTPUT deleted.CustID,deleted.Type,deleted.IsWL INTO @Inserted_Cust(CustID,Type,IsWL)
		FROM #TblCust t

		IF @@ROWCOUNT = 0 
			BREAK

		INSERT INTO VRMemberBigStake(CustID,Type,Status)
		SELECT t.custid, t.Type, 0 AS Status
		FROM @Inserted_Cust t
			LEFT JOIN VRMemberBigStake v WITH(NOLOCK) ON v.custid = t.custid AND v.Type = t.Type
		WHERE v.CustID IS NULL

		--Log for each member if not White list
		BEGIN
			WHILE 1 = 1
			BEGIN
				UPDATE TOP(1) c
				SET c.islog = 1,
					@custID = c.CustID,
					@Type = c.Type
				FROM @Inserted_Cust c
				WHERE Islog = 0
					--AND c.IsWL = 0

				IF @@ROWCOUNT = 0 BREAK;

				SELECT @LogData_member = '<R '
									+ 'Type="'
											+ CASE	WHEN @Type = 1 THEN 'Sportsbook except Basketball and Esports' 
													ELSE space(1) 
												END+ '" '
									+ ' />'
	
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserId				= 0,
					@custID				= @custID,
					@ActionId			= 836,
					@TrackingValue		= @LogData_member
			END
		END

		SET @endRun = getdate()  
		SET @duration  = datediff (millisecond,@startRun,@endRun) 
	
		SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
				(	SELECT CustID AS '@CustID',
							Type AS '@Type',
							IsWL AS '@IsWL'
					FROM @Inserted_Cust
					FOR XML PATH('Row'), ROOT ('R'), TYPE)
			)

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= 0,
				@ActionId			= 825,
				@TrackingValue		= @NewLogData,
				@Duration			= @Duration
		
	END

	--Whitelist by High VR
	DECLARE @UpdateWL_CustIDList VARCHAR(MAX) = ''

	DECLARE @TypeTbl TABLE (Type TINYINT, IsUpdated BIT default(0))

	INSERT INTO @TypeTbl(Type)
	SELECT DISTINCT Type FROM  dbo.f_GetVRBigStakeConfig(NULL)

	WHILE 1 = 1
	BEGIN
		UPDATE TOP(1) c
		SET c.IsUpdated = 1,
			@Type = c.Type
		FROM @TypeTbl c
		WHERE IsUpdated = 0

		IF @@ROWCOUNT = 0 BREAK;

		SET @UpdateWL_CustIDList =  ''

		SELECT @UpdateWL_CustIDList = @UpdateWL_CustIDList + ',' + CONVERT(varchar,c.custid) 
		FROM Customer c WITH(NOLOCK)
			INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
			INNER JOIN dbo.f_GetVRBigStakeConfig(NULL) p ON p.site = c.site AND p.Type = @Type
			INNER JOIN VRMemberBigStake v WITH(NOLOCK) ON v.custid = c.custid AND v.Type = p.Type
			INNER JOIN CustVirtualSetting cvs WITH(NOLOCK)
				ON cvs.custid = ci.custid
			INNER JOIN  ProfileVirtualSetting pvs WITH(NOLOCK)
				ON  cvs.seqNo = pvs.seqNo
		WHERE pvs.isActive = 1
			AND pvs.sporttype = 1 AND pvs.bettype = 1 AND pvs.islive = 1
			AND dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) >= p.VRValue
			AND v.Status <> 1
		
		SELECT @UpdateWL_CustIDList = ISNULL(STUFF(@UpdateWL_CustIDList,1,1,''),'')

		IF @UpdateWL_CustIDList <> ''
			EXEC Acc_VR_MemberBigStake_WhiteList_Upd 
				@CustIDList = @UpdateWL_CustIDList,
				@Type = @Type,
				@UpdateType = 3 --by High VR
	END
END
GO
