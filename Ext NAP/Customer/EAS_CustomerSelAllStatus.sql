/*<info serverAlias="DBCUST-CustDB" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelAllStatus]
	@custid INT
	, @SettingStatus TINYINT = 0
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
		- 20200713@Eden: Integrate 3 new bet types for Keno [Redmine: #137475]
		- 20201012@Tina: Add new parameter @SettingStatus [Redmine: #143077]
		- 20201209@winfred: get Disable Keno for customer list smartphone [redmine: #137130]
		- 20210323@Johnson: hide setting GoldDeluxe [redmine:#151188]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220728@Eden: Ext NAP - Error messge is not clear when searching a disabled account [RedmineID: #175938]
		- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
	Param's Explanation:
		- @SettingStatus: 0: Pro, 1: UAT
	
*/
BEGIN
    SET NOCOUNT ON
    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @HasDownline BIT = 0, @uplineid INT = -1, @Locked TINYINT
		    	
		  
	DECLARE @upLineDisableOutright	BIT
          , @upLineClosed			BIT
          , @upLineSuspend			BIT
          , @uplineDoubleCommLosing BIT      
		  , @UplineHasSecurityCode	BIT = 0  
          , @DisableAutoMPT			BIT  
		  , @HasSecurityCode		BIT = 0
		  , @TransferOption			BIT
		  , @IsProtectedMode		BIT
		  
    SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid 

    IF @roleID=1 --for member
    BEGIN	
	    --Upline
		SELECT		@upLineSuspend = ISNULL(ps.reject, 0)
				,	@upLineClosed = ISNULL(ps.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)	
				,	@uplineid = custid
		FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps
		WHERE ci.custID = @recommend	

		SELECT @HasSecurityCode = 1 FROM dbo.CustLoginInfo_Member WITH (NOLOCK) WHERE CustID = @custID AND SecurityCode IS NOT NULL
		SELECT @UplineHasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @recommend AND SecurityCode IS NOT NULL
		SELECT @TransferOption = CASE WHEN TransferOption = 0 THEN 0 ELSE 1 END FROM dbo.CustAgent WITH(NOLOCK) WHERE custid = @recommend
    END 
    ELSE IF @roleID = 2 --for agent
    BEGIN
	    --Upline
		SELECT		@upLineSuspend = ISNULL(ps.reject, 0)
				,	@upLineClosed = ISNULL(ps.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				,	@uplineid = custid
		FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps
		WHERE custID = @mrecommend		

		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1

		SELECT	@HasSecurityCode = CASE WHEN SecurityCode IS NOT NULL THEN 1 ELSE 0 END,
				@IsProtectedMode = ISNULL(IsProtectedMode,0)
		FROM CustLoginInfo WITH (NOLOCK) 
		WHERE CustID = @custID

		SELECT @UplineHasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @mrecommend AND SecurityCode IS NOT NULL
		SELECT @TransferOption = CASE WHEN TransferOption = 0 THEN 0 ELSE 1 END FROM dbo.CustMaster WITH(NOLOCK) WHERE custid = @mrecommend
    END
    ELSE IF @roleID = 3 --for master
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = ISNULL(ps.reject, 0)
				,	@upLineClosed = ISNULL(ps.closed, 0)
				,	@upLineDisableOutright = ISNULL(DisableOutright, 0)
				,	@uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
				,	@uplineid = custid
	    FROM custinfo ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps
	    WHERE custID = @srecommend		
		 
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
	    SELECT @DisableAutoMPT = DisableAutoMPT FROM CustMaster (NOLOCK) WHERE CustID = @custID
		SELECT @TransferOption = CASE WHEN TransferOption = 0 THEN 0 ELSE 1 END FROM dbo.CustSuper WITH(NOLOCK) WHERE custid = @srecommend
		SELECT	@HasSecurityCode = CASE WHEN SecurityCode IS NOT NULL THEN 1 ELSE 0 END,
				@IsProtectedMode = ISNULL(IsProtectedMode,0)
		FROM CustLoginInfo WITH (NOLOCK) 
		WHERE CustID = @custID
		SELECT @UplineHasSecurityCode = 1 FROM CustLoginInfo WITH (NOLOCK) WHERE CustID = @srecommend AND SecurityCode IS NOT NULL
    END
    ELSE IF @roleID = 4 --for super
    BEGIN
	    --Upline
	    SELECT		@upLineSuspend = 0
				,	@upLineClosed = 0
				,	@upLineDisableOutright = 0
				,	@uplineDoubleCommLosing = 1

				
		SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE srecommend = @custid AND roleid = 3		
	    SELECT	@HasSecurityCode = CASE WHEN SecurityCode IS NOT NULL THEN 1 ELSE 0 END,
				@IsProtectedMode = ISNULL(IsProtectedMode,0)
		FROM CustLoginInfo WITH (NOLOCK) 
		WHERE CustID = @custID
		SELECT @UplineHasSecurityCode = 1
    END
	
	-------------------------------------------------------------------------	    
	--Non product status
	SELECT	@HasDownline AS HasDownline,
			ps.closed,
			ps.reject AS suspended,
			ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,ps.SuspendInfo)),0) as isDirectSuspend,
			ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,ps.CloseInfo)),0) as isDirectClosed,
			ci.DoubleCommLosing, 
			@DisableAutoMPT AS DisableAutoMPT,
			@upLineClosed AS upLineClosed,
			@upLineSuspend AS upLineSuspend,
			@uplineDoubleCommLosing AS uplineDoubleCommLosing,
			ci.DisableOutright,
			@TransferOption AS DisableTransfer,
			@upLineDisableOutright AS upLineDisableOutright,
			@HasSecurityCode AS HasSecurityCode, 
			@UplineHasSecurityCode AS UplineHasSecurityCode,
			ISNULL(ps.Locked,0) AS Locked,
			@IsProtectedMode AS IsProtectedMode
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid
	    CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
										, SuspendInfo
										, CloseInfo
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS ps	
    WHERE c.custid = @custid	

	-- For Product DCS
	EXEC Acc_CustSetting_StatusSelect @CustID = @custid,@roleid = @roleid, @SettingStatus = @SettingStatus
END
GO
