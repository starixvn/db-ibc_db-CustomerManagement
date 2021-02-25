/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_VR_MemberBigStake_WhiteList_Upd   
	 @CustIDList VARCHAR(max)
	,@Type TINYINT
	,@IsUpdateByCredit BIT = 0
AS  
/*  
	Created:	20210219@Eden:	
	Task:		Update Status = 1 (white list) of customers in VRMemberBigStake table 
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20210219@Eden: First commit [#150298]

	Param's Explanation:  
		@Type = 
			1: All VR sport exclude BasketBall and Esport

		@IsUpdateByCredit =
			0: Update status = 1 when check performance
			1: Update when check Credit <= config credit

	Examples:
		EXEC Acc_VR_MemberBigStake_WhiteList_Upd @CustIDList = '1,4935,5029,5052'
			,@Type = 1
	
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @CustTbl TABLE ( CustID INT PRIMARY KEY)
	DECLARE @UpdatedTbl TABLE (CustID INT PRIMARY KEY, IsLog BIT Default 0)

	INSERT INTO @CustTbl(CustID)
	SELECT DISTINCT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)

	--> Update Status = 1
	UPDATE v
	SET v.Status = 1
	OUTPUT deleted.CustID INTO @UpdatedTbl( CustID)
	FROM VRMemberBigStake v WITH(ROWLOCK)
		INNER JOIN @CustTbl t ON v.CustID = t.CustID
	WHERE v.Type = @Type
		AND v.Status <> 1
		AND v.FirstBetDate IS NOT NULL

	IF NOT EXISTS ( SELECT 1 FROM @UpdatedTbl)
		RETURN

	DECLARE @NewLogData VARCHAR(MAX)
	DECLARE @custID INT

	--Log Update VR for each customer
	WHILE 1 = 1
	BEGIN
		UPDATE TOP(1)  c
		SET c.islog = 1,
			@custID = c.CustID
		FROM @UpdatedTbl c
		WHERE Islog = 0

		IF @@ROWCOUNT = 0 BREAK;

		SELECT @NewLogData = '<R '
							+ 'Type="'
									+ CASE	WHEN @Type = 1 THEN 'Sportsbook except Basketball and Esports' 
											ELSE space(1) 
										END+ '" '
							+ 'Reason="'
									+ CASE	WHEN @IsUpdateByCredit = 1 THEN 'Credit' 
											ELSE 'Winloss'
										END+ '" '
							+ ' />'
	
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= 0,
			@custID				= @custID,
			@ActionId			= 828,
			@TrackingValue		= @NewLogData
	END

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 

	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT  CustID AS '@CustID',
						@Type AS '@Type', 
						@IsUpdateByCredit AS '@IsUpdateByCredit'
				FROM @UpdatedTbl
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
		)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 827,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
