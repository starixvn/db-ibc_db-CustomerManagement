/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_CustomerUpdFirstBetDate   
	@CustIDList VARCHAR(max)
	,@Sporttype INT
	,@BetDate	DATE
AS  
/*  
	Created:	
	Task:		Update FirstBetDate of VRCustAutoAdjustment table
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200805@Eden: First commit [#138168]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_CustomerUpdFirstBetDate @CustIDList = '1,2'
		,@Sporttype = 2
		,@BetDate = '2020/08/05'
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @CustTbl TABLE ( CustID INT)
	INSERT INTO @CustTbl(CustID)
	SELECT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)
	  
	UPDATE v
	SET v.FirstBetDate = @BetDate
	FROM VRCustAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @CustTbl t ON v.CustID = t.CustID
	WHERE v.SportType = @Sporttype
		AND v.FirstBetDate IS NULL

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = '<R '
						+ 'CustIDList="'+ coalesce(cast(@CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(50)),space(1)) + '" ' 
						+ 'BetDate="' + coalesce(cast(@BetDate as varchar(50)),space(1)) + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 814,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
