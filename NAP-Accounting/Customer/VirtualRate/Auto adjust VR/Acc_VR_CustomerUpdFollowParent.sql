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

	DECLARE @CustTbl TABLE ( CustID INT, IsFinish BIT DEFAULT 0)
	INSERT INTO @CustTbl(CustID)
	SELECT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)
	  
	DECLARE @NewVirtualMultiplier VARCHAR(MAX) =  '<Root></Root>' --Update to Follow Parents
	DECLARE @CustID INT
		, @ErrCode INT = 0
		, @ErrMsg NVARCHAR(200) = ''
			
	WHILE 1 = 1
	BEGIN
		UPDATE TOP (1) @CustTbl
		SET IsFinish = 1,
			@CustID = CustID
		WHERE IsFinish = 0

		IF @@ROWCOUNT = 0
			BREAK;

		EXEC [Acc_CustVirtualMultiplier_Upd]
			  @CustID = @CustID
			, @SportType = @Sporttype
			, @VirtualMultiplier = @NewVirtualMultiplier
			, @UserID  = 0
			, @IP  = ''
			, @ErrCode = @ErrCode OUT
			, @ErrMsg = @ErrMsg OUT
	END
	
	--> Update Status = 3 : done update VR follow parent
	UPDATE v
	SET v.Status = 3
	FROM VRCustAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @CustTbl t ON v.CustID = t.CustID
	WHERE v.SportType = @Sporttype

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = '<R '
						+ 'CustIDList="'+ coalesce(cast(@CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(50)),space(1)) + '" ' 
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 99999,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
