/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelAllStatus]
	@custid INT
	, @SettingStatus TINYINT = 0
AS
/*
	Created: 20180608@Elodie
	DB: DBAGE/bodb02
	Task: Left menu of ALPHA - Search customer - All Status

	Revisions:
		- 20180608@Elodie: Left menu of ALPHA - Search customer [Redmine: #58776]
		- 20190412@Johnson: add suspendInfo [redmine:#105587]
		- 20190926@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20200310@Percy: Return IsAllDayBalTransfer [RedmineID: #130091]
		- 20201012@Tina: Add new parameter @SettingStatus [Redmine: #143077]

	Param's Explanation:
		• @username: username of customer that need to be viewed.   
		• @uplineId: the ID of the upline.
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @HasDownline BIT = 0, @uplineid INT = -1

	DECLARE @IsAllDayBalTransfer BIT
    
	--Downline/Upline status 
    DECLARE @upLineDisableCS				BIT       
          , @uplineDisabledNumber			BIT
		  , @uplineHideGoldDeluxe			BIT   
		  , @uplineDisableGoldDeluxe		BIT		
          , @uplineDisableEsports			BIT 
		  
	DECLARE @upLineDisableOutright	BIT
          , @upLineClosed			BIT
          , @upLineSuspend			BIT
          , @uplineDoubleCommLosing BIT        
          , @DisableAutoMPT			BIT  
		  , @isDirectSuspend 		BIT = 0
		  
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
				
				,	@uplineDisableCS = ISNULL(DisableCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)	
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)

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
				
				,	@uplineDisableCS = ISNULL(DisableCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)	
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)
				
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
				
				,	@uplineDisableCS = ISNULL(DisableCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)	
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)
				
				,	@uplineid = custid
	     FROM custinfo WITH(NOLOCK)
	     WHERE custID = @srecommend		
		 
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
	    SELECT @DisableAutoMPT = DisableAutoMPT, @IsAllDayBalTransfer = IsAllDayBalTransfer FROM CustMaster (NOLOCK) WHERE CustID = @custID
    END
    
	--check suspend status is direct or not
	SELECT @isDirectSuspend = (SELECT suspendInfo FROM dbo.f_GetSuspendInfoStatus(@roleid,SuspendInfo))
	FROM dbo.CustProductStatus WITH(NOLOCK)
	WHERE custid = @custid
	
	-------------------------------------------------------------------------
	DECLARE @TransferOption VARCHAR(8)
    EXEC DBCUST.CustDB.dbo.Acc_CustomerSelTransferOption @uplineid, @TransferOption OUTPUT
    
	--Non product status
	SELECT	@HasDownline AS HasDownline,
			ci.closed,
			ci.reject AS suspended,
			ISNULL(@isDirectSuspend,0) as isDirectSuspend,
			@TransferOption AS TransferOption,
			ci.DoubleCommLosing, 
			@DisableAutoMPT AS DisableAutoMPT,
			@upLineClosed AS upLineClosed,
			@upLineSuspend AS upLineSuspend,
			@uplineDoubleCommLosing AS uplineDoubleCommLosing,
			ci.DisableOutright,
			@upLineDisableOutright AS upLineDisableOutright,
			ISNULL(@IsAllDayBalTransfer, 0) AS IsAllDayBalTransfer
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid

	--Product Status
	SELECT	ci.SyncCasino,
			ci.DisableCasino,
			@upLineDisableCS AS uplineDisableCS,
			ci.DisableNumber,
			@uplineDisabledNumber AS uplineDisabledNumber,
			@uplineHideGoldDeluxe AS uplineHideGoldDeluxe,
			@uplineDisableGoldDeluxe AS uplineDisableGoldDeluxe,
			ci.DisableGoldDeluxe,
			ci.HideGoldDeluxe,
			ci.DisableEsports, 
			@uplineDisableEsports AS uplineDisableEsports,
			ci.HideKeno
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid

	-- For Product DCS
	EXEC Acc_CustSetting_StatusSelect @CustID = @custid,@roleid = @roleid, @SettingStatus = @SettingStatus
END
GO