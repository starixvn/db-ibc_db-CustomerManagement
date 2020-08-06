/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_CustomerUpdFollowParent   
	 @CustIDList VARCHAR(max)
	,@Sporttype INT
AS  
/*  
	Created:	
	Task:		Update VR follow Parent for Customers
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200805@Eden: First commit [#138168]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_CustomerUpdFollowParent @CustIDList = '1,2'
		,@Sporttype = 2
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @Input_CustTbl TABLE ( CustID INT)
	DECLARE @Update_CustTbl TABLE ( CustID INT, IsLog BIT DEFAULT 0)

	INSERT INTO @Input_CustTbl(CustID)
	SELECT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)
	  
	DECLARE @NewVirtualMultiplier VARCHAR(MAX) =  '<Root></Root>' --Update to Follow Parents
	DECLARE @CustID INT
		, @ErrCode INT = 0
		, @ErrMsg NVARCHAR(200) = ''
		, @LevelID INT
		, @ValueID_0 INT
		, @Update_CustIDList VARCHAR(MAX) = ''

	SELECT @LevelID = levelID
	FROM VRSettingHierarchy  WITH(NOLOCK)
	WHERE SportType = @Sporttype
		AND VRLeagueGroupID = -1
		AND BetType = -1

	SELECT @ValueID_0 = ValueID
	FROM VRValueMapping WITH(NOLOCK)
	WHERE Value = 1.00

	--> Scan all members with Status = 2 and basketball VR = 0 (at basketball level)
	INSERT INTO @Update_CustTbl(CustID)
	SELECT v.custid
	FROM VRCustAutoAdjustment v WITH(NOLOCK)
		 INNER JOIN @Input_CustTbl t ON v.CustID = t.CustID
		 INNER JOIN VRCustSetting vr WITH(NOLOCK)
		   ON v.custid = vr.CustID
			  AND vr.LevelID = @LevelID
			  AND vr.ValueIDLIVE = @ValueID_0
			  AND vr.ValueIDNonLIVE = @ValueID_0
	WHERE v.SportType = @Sporttype
		AND v.[Status] = 2

	DELETE vr
	FROM VRCustSetting vr WITH(ROWLOCK)
		INNER JOIN @Update_CustTbl t ON vr.CustID = t.CustID 
	WHERE vr.LevelID = @LevelID

	--Log for each Customer
	DECLARE @LogData VARCHAR(MAX)

	WHILE 1 = 1
	BEGIN
		UPDATE TOP (1) @Update_CustTbl
		SET IsLog = 1,
			@CustID = CustID
		WHERE IsLog = 0

		IF @@ROWCOUNT = 0
			BREAK;

		SELECT @LogData = '<R '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(50)),space(1)) + '" ' 
						+ ' />'
		
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= 0,
			@CustID             = @CustID,
			@ActionId			= 816,
			@TrackingValue		= @LogData,
			@Duration			= @Duration

		SELECT @Update_CustIDList = @Update_CustIDList + ',' + CONVERT(varchar,@CustID)

	END
	
	SELECT @Update_CustIDList = STUFF(@Update_CustIDList,1,1,'')

	--> Update Status = 3 : done update VR follow parent
	UPDATE v
	SET v.Status = 3
	FROM VRCustAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @Input_CustTbl t ON v.CustID = t.CustID
	WHERE v.SportType = @Sporttype

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = '<R '
						+ 'InputCustIDList="'+ coalesce(cast(@CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'UpdatedCustIDList="'+ coalesce(cast(@Update_CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(50)),space(1)) + '" ' 
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 815,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
