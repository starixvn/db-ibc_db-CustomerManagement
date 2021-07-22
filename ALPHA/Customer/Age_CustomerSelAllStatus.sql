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
		- 20201209@winfred: get Disable Keno for customer list smartphone [redmine: #137130]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		
	Param's Explanation:
		- @username: username of customer that need to be viewed.   
		- @uplineId: the ID of the upline.
		- @SettingStatus: 0: Pro, 1: UAT
*/
BEGIN
    SET NOCOUNT ON
    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @HasDownline BIT = 0, @uplineid INT = -1

	DECLARE @IsAllDayBalTransfer BIT,@ExecuteSQL NVARCHAR(MAX) = '',@query NVARCHAR(MAX) = '',@Param NVARCHAR(MAX) 	
    
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
		  , @isDirectClosed 		BIT = 0
		  , @DisableKeno			BIT
		  , @Locked					TINYINT
		  
    SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid 

    IF @roleID=1 --for member
    BEGIN	
	    --Upline
		SELECT		@upLineSuspend = ISNULL(cs.reject, 0)
				,	@upLineClosed = ISNULL(cs.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				
				,	@uplineDisableCS = ISNULL(DisableCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)	
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)

				,	@uplineid = custid
	     FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
	     WHERE ci.custID = @recommend	
    END 
    ELSE IF @roleID = 2 --for agent
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = ISNULL(cs.reject, 0)
				,	@upLineClosed = ISNULL(cs.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				
				,	@uplineDisableCS = ISNULL(DisableCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)	
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)
				
				,	@uplineid = custid
	     FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
	     WHERE ci.custID = @mrecommend		

		 SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1
    END
    ELSE IF @roleID = 3 --for master
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = ISNULL(cs.reject, 0)
				,	@upLineClosed = ISNULL(cs.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				
				,	@uplineDisableCS = ISNULL(DisableCasino, 0)
				,	@uplineDisabledNumber = ISNULL(DisableNumber, 0)
				,	@uplineHideGoldDeluxe = ISNULL(HideGoldDeluxe, 0)
				,	@uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)	
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)
				
				,	@uplineid = custid
	     FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
	     WHERE ci.custID = @srecommend		
		 
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
	    SELECT @DisableAutoMPT = DisableAutoMPT, @IsAllDayBalTransfer = IsAllDayBalTransfer FROM CustMaster (NOLOCK) WHERE CustID = @custID
    END
    
	--check suspend status is direct or not
	SELECT @isDirectSuspend = (SELECT suspendInfo FROM dbo.f_GetSuspendInfoStatus(@roleid,SuspendInfo)),
		   @isDirectClosed = (SELECT suspendInfo FROM dbo.f_GetSuspendInfoStatus(@roleid,CloseInfo)),
		   @Locked = ISNULL(Locked,0)
	FROM dbo.CustProductStatus WITH(NOLOCK)
	WHERE custid = @custid
	
	------------------------Keno-----------------------
	SELECT  @query = N''		
	SELECT	@query = @query + N'
	SET @DisableKeno = ISNULL((SELECT TOP 1 cg.IsDisabled AS DisableKeno
	FROM dbo.CustGameType cg WITH (NOLOCK)  
		INNER JOIN dbo.GameType g WITH (NOLOCK) ON g.GameTypeID = cg.GameTypeID
	WHERE cg.custid = @custid AND g.IBCBetTypeID BETWEEN 1501 AND 1599 AND g.IsDisabled = 0 AND cg.IsDisabled = 1),0)
	'
	SELECT	@ExecuteSQL = N'
	EXECUTE DBACC.bodb02.dbo.sp_executesql @query, N''@custid INT, @DisableKeno BIT OUTPUT'',@custid,@DisableKeno OUTPUT'

	-- Result
	EXECUTE	sys.sp_executesql @ExecuteSQL, N'@query NVARCHAR(MAX), @custid INT,@DisableKeno BIT OUTPUT', @query, @custid,@DisableKeno OUTPUT
	-------------------------------------------------------------------------
	DECLARE @TransferOption VARCHAR(8)
    EXEC DBCUST.CustDB.dbo.Acc_CustomerSelTransferOption @uplineid, @TransferOption OUTPUT
    
	--Non product status
	SELECT	@HasDownline AS HasDownline,
			cs.closed,
			cs.reject AS suspended,
			ISNULL(@isDirectSuspend,0) as isDirectSuspend,
			ISNULL(@isDirectClosed,0) as isDirectClosed,
			@TransferOption AS TransferOption,
			ci.DoubleCommLosing, 
			@DisableAutoMPT AS DisableAutoMPT,
			@upLineClosed AS upLineClosed,
			@upLineSuspend AS upLineSuspend,
			@uplineDoubleCommLosing AS uplineDoubleCommLosing,
			ci.DisableOutright,
			@upLineDisableOutright AS upLineDisableOutright,
			ISNULL(@IsAllDayBalTransfer, 0) AS IsAllDayBalTransfer,
			@Locked AS Locked
	FROM custinfo ci WITH (NOLOCK)
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
    WHERE ci.custid = @custid
	
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
			@DisableKeno AS DisableKeno,
			ci.HideKeno
	FROM custinfo ci WITH (NOLOCK)
    WHERE ci.custid = @custid

	-- For Product DCS
	EXEC Acc_CustSetting_StatusSelect @CustID = @custid,@roleid = @roleid, @SettingStatus = @SettingStatus
END
GO