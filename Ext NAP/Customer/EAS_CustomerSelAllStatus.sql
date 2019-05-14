/*<info serverAlias="DBAGE-bodb02" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[EAS_CustomerSelAllStatus]
	@custid INT
AS
/*
	Created: 20180628@Elodie
	DB: DBAGE/bodb02
	Task: Left menu of ExtNap - Search customer - All Status

	Revisions:
		- 20180628@Elodie: Left menu of ExtNap - Search customer - All Status [Redmine: #58776]
		
	Param's Explanation:
	
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @HasDownline BIT = 0, @uplineid INT = -1
    
	--Downline/Upline status 
    DECLARE @upLineDisableCasino			BIT   
		  , @uplineSyncCasino				BIT    		   
          , @uplineDisabledNumber			BIT
		  , @uplineHideGoldDeluxe			BIT   
		  , @uplineDisableGoldDeluxe		BIT		  
		  , @uplineDisableColossusBet		BIT
		  , @DisableDownlinesColossusBet	BIT = 0  
		  
	DECLARE @upLineDisableOutright	BIT
          , @upLineClosed			BIT
          , @upLineSuspend			BIT
          , @uplineDoubleCommLosing BIT        
          , @DisableAutoMPT			BIT  
		  
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
				,	@uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)

				,	@uplineid = custid
	     FROM custinfo WITH(NOLOCK)
	     WHERE custID = @recommend	
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
				,	@uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
				
				,	@uplineid = custid
	     FROM custinfo WITH(NOLOCK)
	     WHERE custID = @mrecommend		

		 SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1
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
				,	@uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
				
				,	@uplineid = custid
	     FROM custinfo WITH(NOLOCK)
	     WHERE custID = @srecommend		
		 
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
	    SELECT @DisableAutoMPT = DisableAutoMPT FROM CustMaster (NOLOCK) WHERE CustID = @custID
    END
    
	-------------------------------------------------------------------------	    
	--Non product status
	SELECT	@HasDownline AS HasDownline,
			ci.closed,
			ci.reject AS suspended,
			ci.DoubleCommLosing, 
			@DisableAutoMPT AS DisableAutoMPT,
			@upLineClosed AS upLineClosed,
			@upLineSuspend AS upLineSuspend,
			@uplineDoubleCommLosing AS uplineDoubleCommLosing,
			ci.DisableOutright,
			@upLineDisableOutright AS upLineDisableOutright
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid

	--Product Status
	SELECT	ci.SyncCasino,
			ci.DisableCasino,
			@upLineDisableCasino AS uplineDisableCasino,
			@uplineSyncCasino AS uplineSyncCasino,
			ci.DisableNumber,
			@uplineDisabledNumber AS uplineDisabledNumber,
			ci.DisableColossusBet,
			ci.HideColossusBet,
			@uplineDisableColossusBet AS uplineDisableColossusBet,
			@uplineHideGoldDeluxe AS uplineHideGoldDeluxe,
			@uplineDisableGoldDeluxe AS uplineDisableGoldDeluxe,
			ci.DisableGoldDeluxe,
			ci.HideGoldDeluxe,
			ci.HideKeno	
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid

	-- For Product DCS
		EXEC Acc_CustSetting_StatusSelect @CustID = @custid,@roleid = @roleid
END