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
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
		- 20230410@Bobby: AutoJob clear balance downlines IsAllowAutoTransfer [RedmineID: #182071]

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
    DECLARE @uplineDisableEsports			BIT 
		  
	DECLARE @upLineDisableOutright	BIT
          , @upLineClosed			BIT
          , @upLineSuspend			BIT
          , @uplineDoubleCommLosing BIT        
          , @DisableAutoMPT			BIT  
		  , @isDirectSuspend 		BIT = 0
		  , @isDirectClosed 		BIT = 0
		  , @Locked					TINYINT
		  , @IsProtectedMode		BIT
		  , @IsAllowAutoTransfer	BIT = 0

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
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)
				,	@uplineid = custid
	     FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
	     WHERE ci.custID = @recommend	

		-- TODO: IsAllowAutoTransfer
		SET @ExecuteSQL = CONCAT(N'
			SELECT @IsAllowAutoTransfer = IsAllowAutoTransfer
			FROM OPENQUERY(DBCUST,''SELECT 1 AS IsAllowAutoTransfer FROM CustDB.dbo.Age_ClearBalanceCust_Setting WITH(NOLOCK) WHERE FromCustId = ', @recommend,' AND ToCustID= ',@custid, ''')')
		;
		EXEC sys.sp_executesql @ExecuteSQL, N'@IsAllowAutoTransfer BIT OUT', @IsAllowAutoTransfer OUT;
    END 
    ELSE IF @roleID = 2 --for agent
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = ISNULL(cs.reject, 0)
				,	@upLineClosed = ISNULL(cs.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				,	@uplineDisableEsports = ISNULL(DisableEsports, 0)
				
				,	@uplineid = custid
	     FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
	     WHERE ci.custID = @mrecommend		

		 SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1;

		 -- TODO: IsAllowAutoTransfer
		SET @ExecuteSQL = CONCAT(N'
			SELECT @IsAllowAutoTransfer = IsAllowAutoTransfer
			FROM OPENQUERY(DBCUST,''SELECT 1 AS IsAllowAutoTransfer FROM CustDB.dbo.Age_ClearBalanceCust_Setting WITH(NOLOCK) WHERE FromCustId = ', @mrecommend,' AND ToCustID= ',@custid, ''')')
		;
		EXEC sys.sp_executesql @ExecuteSQL, N'@IsAllowAutoTransfer BIT OUT', @IsAllowAutoTransfer OUT;
    END
    ELSE IF @roleID = 3 --for master
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = ISNULL(cs.reject, 0)
				,	@upLineClosed = ISNULL(cs.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
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
	    SELECT @DisableAutoMPT = DisableAutoMPT, @IsAllDayBalTransfer = IsAllDayBalTransfer FROM CustMaster (NOLOCK) WHERE CustID = @custID;

		-- TODO: IsAllowAutoTransfer
		SET @ExecuteSQL = CONCAT(N'
			SELECT @IsAllowAutoTransfer = IsAllowAutoTransfer
			FROM OPENQUERY(DBCUST,''SELECT 1 AS IsAllowAutoTransfer FROM CustDB.dbo.Age_ClearBalanceCust_Setting WITH(NOLOCK) WHERE FromCustId = ', @srecommend,' AND ToCustID= ',@custid, ''')')
		;
		EXEC sys.sp_executesql @ExecuteSQL, N'@IsAllowAutoTransfer BIT OUT', @IsAllowAutoTransfer OUT;
    END
    
	--check suspend status is direct or not
	SELECT @isDirectSuspend = (SELECT suspendInfo FROM dbo.f_GetSuspendInfoStatus(@roleid,SuspendInfo)),
		   @isDirectClosed = (SELECT suspendInfo FROM dbo.f_GetSuspendInfoStatus(@roleid,CloseInfo)),
		   @Locked = ISNULL(Locked,0)
	FROM dbo.CustProductStatus WITH(NOLOCK)
	WHERE custid = @custid
	
	SELECT	@IsProtectedMode = ISNULL(IsProtectedMode,0) 
	FROM DBACC.bodb02.dbo.CustLoginInfo cl WITH (NOLOCK) 
	WHERE custid = @custid
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
			@Locked AS Locked,
			@IsProtectedMode AS IsProtectedMode,
			@IsAllowAutoTransfer AS IsAllowAutoTransfer
	FROM custinfo ci WITH (NOLOCK)
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
    WHERE ci.custid = @custid
	
	--Product Status
	SELECT	ci.DisableEsports, 
			@uplineDisableEsports AS uplineDisableEsports			
	FROM custinfo ci WITH (NOLOCK)
    WHERE ci.custid = @custid

	-- For Product DCS
	EXEC Acc_CustSetting_StatusSelect @CustID = @custid,@roleid = @roleid, @SettingStatus = @SettingStatus
END
GO