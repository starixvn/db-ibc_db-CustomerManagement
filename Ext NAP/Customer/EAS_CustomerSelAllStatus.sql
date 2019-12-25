/*<info serverAlias="DBCUST-CustDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[EAS_CustomerSelAllStatus]
	@custid INT
AS
/*
	Created: 20180628@Elodie
	DB: DBCUST/CustDB
	Task: Left menu of ExtNap - Search customer - All Status

	Revisions:
		- 20180628@Elodie: Left menu of ExtNap - Search customer - All Status [Redmine: #58776]
		- 20190513@Johnson: add suspendinfo [redmine: #105587]
		- 20190926@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20181112@Elodie: Rewrite SP for function customer list - [Redmine: #104570]

	Param's Explanation:
	
*/
BEGIN
    SET NOCOUNT ON
	DECLARE @GameType TABLE (GameTypeID INT, IBCBetTypeID INT)
    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @HasDownline BIT = 0, @uplineid INT = -1
		    	
	--Downline/Upline status 
    DECLARE @upLineDisableCasino			BIT   
		  , @uplineSyncCasino				BIT    		   
          , @uplineDisabledNumber			BIT
		  , @uplineHideGoldDeluxe			BIT   
		  , @uplineDisableGoldDeluxe		BIT		  
		  
	DECLARE @upLineDisableOutright	BIT
          , @upLineClosed			BIT
          , @upLineSuspend			BIT
          , @uplineDoubleCommLosing BIT      
		  , @UplineHasSecurityCode	BIT = 0  
          , @DisableAutoMPT			BIT  
		  , @isDirectSuspend		BIT = 0
		  , @HasSecurityCode		BIT = 0
		  , @TransferOption			BIT
		  
    SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid 

    IF @roleID=1 --for member
    BEGIN	
	    --Upline
		SELECT		@upLineSuspend = ISNULL(reject, 0)
				,	@upLineClosed = ISNULL(closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				
				,	@upLineDisableCasino = ISNULL(DisableCasino, 0)
				,	@uplineSyncCasino = ISNULL(SyncCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)				

				,	@uplineid = custid
		FROM custinfo WITH(NOLOCK)
		WHERE custID = @recommend	

		SELECT @HasSecurityCode = 1 FROM dbo.CustLoginInfo_Member WITH (NOLOCK) WHERE CustID = @custID AND SecurityCode IS NOT NULL
		SELECT @UplineHasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @recommend AND SecurityCode IS NOT NULL
		SELECT @TransferOption = CASE WHEN TransferOption = 0 THEN 0 ELSE 1 END FROM dbo.CustAgent WITH(NOLOCK) WHERE custid = @recommend
    END 
    ELSE IF @roleID = 2 --for agent
    BEGIN
	    --Upline
		SELECT		@upLineSuspend = ISNULL(reject, 0)
				,	@upLineClosed = ISNULL(closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				
				,	@upLineDisableCasino = ISNULL(DisableCasino, 0)
				,	@uplineSyncCasino = ISNULL(SyncCasino, 0)				
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)				
				
				,	@uplineid = custid
		FROM custinfo WITH(NOLOCK)
		WHERE custID = @mrecommend		

		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1
		SELECT @HasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @custID AND SecurityCode IS NOT NULL
		SELECT @UplineHasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @mrecommend AND SecurityCode IS NOT NULL
		SELECT @TransferOption = CASE WHEN TransferOption = 0 THEN 0 ELSE 1 END FROM dbo.CustMaster WITH(NOLOCK) WHERE custid = @mrecommend
    END
    ELSE IF @roleID = 3 --for master
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = ISNULL(reject, 0)
				,	@upLineClosed = ISNULL(closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				
				,	@upLineDisableCasino = ISNULL(DisableCasino, 0)
				,	@uplineSyncCasino = ISNULL(SyncCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)
				
				,	@uplineid = custid
	    FROM custinfo WITH(NOLOCK)
	    WHERE custID = @srecommend		
		 
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
	    SELECT @DisableAutoMPT = DisableAutoMPT FROM CustMaster (NOLOCK) WHERE CustID = @custID
		SELECT @TransferOption = CASE WHEN TransferOption = 0 THEN 0 ELSE 1 END FROM dbo.CustSuper WITH(NOLOCK) WHERE custid = @srecommend
		SELECT @HasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @custID AND SecurityCode IS NOT NULL
		SELECT @UplineHasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @srecommend AND SecurityCode IS NOT NULL
    END
    ELSE IF @roleID = 4 --for super
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = 0
				,	@upLineClosed = 0
				,	@upLineDisableOutright = 0
				,	@uplineDoubleCommLosing = 1
				
				,	@upLineDisableCasino = 0
				,	@uplineSyncCasino = 0
				,	@uplineDisabledNumber = 0
				,	@uplineHideGoldDeluxe = 0
				,	@uplineDisableGoldDeluxe = 0				
		 
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3		
	    SELECT @HasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @custID AND SecurityCode IS NOT NULL
		SELECT @UplineHasSecurityCode = 1
    END
	--check suspend status is direct or not
	SELECT @isDirectSuspend = (SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,SuspendInfo))
	FROM dbo.CustProductStatus WITH(NOLOCK)
	WHERE custid = @custid
	
	-------------------------------------------------------------------------	    
	--Non product status
	SELECT	@HasDownline AS HasDownline,
			ci.closed,
			ci.reject AS suspended,
			ISNULL(@isDirectSuspend,0) as isDirectSuspend,
			ci.DoubleCommLosing, 
			@DisableAutoMPT AS DisableAutoMPT,
			@upLineClosed AS upLineClosed,
			@upLineSuspend AS upLineSuspend,
			@uplineDoubleCommLosing AS uplineDoubleCommLosing,
			ci.DisableOutright,
			@TransferOption AS DisableTransfer,
			@upLineDisableOutright AS upLineDisableOutright,
			@HasSecurityCode AS HasSecurityCode, 
			@UplineHasSecurityCode AS UplineHasSecurityCode
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid	

	INSERT INTO @GameType (GameTypeID, IBCBetTypeID)
	SELECT GameTypeID, IBCBetTypeID FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK) WHERE IBCBetTypeID BETWEEN 1501 AND 1599 AND IsDisabled = 0

	--Product Status
	SELECT	ci.SyncCasino,
			ci.DisableCasino,
			@upLineDisableCasino AS uplineDisableCasino,
			@uplineSyncCasino AS uplineSyncCasino,
			ci.DisableNumber,
			@uplineDisabledNumber AS uplineDisabledNumber,
			@uplineHideGoldDeluxe AS uplineHideGoldDeluxe,
			@uplineDisableGoldDeluxe AS uplineDisableGoldDeluxe,
			ci.DisableGoldDeluxe,
			ci.HideGoldDeluxe,
			ci.HideKeno,
			MIN(CASE WHEN cg.GameTypeID IN (1,3,4,5,8,11,13,14,15,16,17,19,20,21,22,24,25,26) THEN cg.IsDisabled ELSE 1 END) AS DisableKeno
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
		INNER JOIN dbo.CustGameType cg WITH (NOLOCK) ON c.custid = cg.custid	
		INNER JOIN @GameType g ON g.GameTypeID = cg.GameTypeID
    WHERE c.custid = @custid
	GROUP BY ci.SyncCasino, ci.DisableCasino, ci.DisableNumber, ci.DisableGoldDeluxe, ci.HideGoldDeluxe, ci.HideKeno

	-- For Product DCS
	EXEC Acc_CustSetting_StatusSelect @CustID = @custid,@roleid = @roleid
END
GO
