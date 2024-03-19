/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_CustomerUpdAutoAdjustmentStatus   
	 @CustIDList VARCHAR(max)
	,@Sporttype INT
	,@IsTest BIT = 0
AS  
/*  
	Created:	
	Task:		Update VRCustAutoAdjustment.Status = 4 (Keep VR)
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200811@Eden: First commit [#139229]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_CustomerUpdAutoAdjustmentStatus
		 @CustIDList = '1,2'
		,@Sporttype = 99
		,@IsTest = 1
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @Input_CustTbl TABLE ( CustID INT)

	INSERT INTO @Input_CustTbl(CustID)
	SELECT p.value
	FROM STRING_SPLIT(@CustIDList,',') p
	WHERE value <> ''

	IF @IsTest = 1 -- UUS only 
	BEGIN
		DELETE t
		FROM @Input_CustTbl t
			INNER JOIN custInfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		WHERE ci.currency <> 20
	END

	--> Update Status = 4 : Keep VR
	UPDATE v
	SET v.Status = 4
	FROM VRCustAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @Input_CustTbl t ON v.CustID = t.CustID
	WHERE v.SportType = @Sporttype
		AND v.[Status] = 2

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = '<R '
						+ 'CustIDList="'+ coalesce(cast(@CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(50)),space(1)) + '" ' 
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 817,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
