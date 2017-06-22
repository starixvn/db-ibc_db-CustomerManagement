ALTER PROCEDURE [dbo].[Acc_CustomerSelStatus]	
	@CustID int,
	@AdminID int = 0,
	@username  VARCHAR(50) = ''
AS 
/*
Created: 20090125@nqminh
Task : Select customer's status
DB: DBAGE/bodb02
Original:

Revisions:
    - 20090411@PhuongDoan: Add casino status    
    - 20090731@nqminh: Add outright status    
	- 20090806@huynguyen: Add closed, autosuspend, isautopositiontaking
	- 20090829@[Shifu]: Add IsInternal
	- 20100223@[Ryan]: Add IsAdminCanViewVNIP
	- 20100227@Jamie: Change the way to check permission 
	- 20100402@Lee: Add mrecommend, arecommend 
	- 20100504@Huynguyen: Add DisableOpenTote
	- 20100828@SonPhan: Add DisableBingo, DisableNumber, SyncBingo
	- 20101015@Ethan: Get Limited Per IP value @LimitPerIP + SelectedBetting
	- 20110914@Tom: Add column DisableP2P
	- 20120131@Johnson: - Add Parameter @username support get by username
						- Add DisableLiveCasino, SyncLiveCasino
	- 20120808@Sophia: Add DisableVirtualSports, HideVirtualSports	
	- 20120927@Sophia: Get DoubleCommLosing	
	- 20130719@Elodie: Get DisableCasinoBonus field  
	- 20130723@Jamie: Change Alias DB03 to DBPOLICY
						
Param's Explanation:
• @CustID: customer id. 
  
*/

SET NOCOUNT ON
DECLARE @agentid INT, @roleid TINYINT, @IsInternal BIT, @IsAdminCanViewVNIP BIT,  @LimitPerIP tinyint, @SelectedBetting bit

IF ISNULL(@username,'') <> ''
	SELECT @roleid = roleid, @agentid = recommend, @custid = custid
	FROM custinfo WITH (NOLOCK)
	WHERE username = @username
ELSE 
	SELECT @roleid = roleid, @agentid = recommend
	FROM custinfo WITH (NOLOCK)
	WHERE custid = @CustID
	
SET @LimitPerIP = 0
SET @SelectedBetting = 0
SET @IsInternal = 0

IF @roleid = 4 --super
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) ,
		@LimitPerIP =  isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0)
	FROM custSuper WITH (NOLOCK) WHERE custid = @custid
END
ELSE IF @roleid = 3 --master
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) ,
		@LimitPerIP =  isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0)
	FROM custMaster WITH (NOLOCK) WHERE custid = @custid
END
ELSE IF @roleid = 2 --agent
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) ,
		@LimitPerIP =  isnull(LimitPerIP, 0),
		@SelectedBetting =  isnull(SelectedBetting, 0)
	FROM custAgent WITH (NOLOCK) WHERE custid = @custid
END
ELSE IF @roleid = 1 --member
BEGIN
	SELECT 
		@IsInternal = isnull(IsInternal, 0) 
	FROM custAgent WITH (NOLOCK) WHERE custid = @agentid
END

--Get Internal status
/*
SELECT @IsInternal = CASE @roleid WHEN 4 THEN (SELECT isnull(IsInternal, 0) FROM custSuper WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 3 THEN (SELECT isnull(IsInternal, 0) FROM custMaster WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 2 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @custid)
								  WHEN 1 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @agentid)
								  ELSE 0 END 
*/								  
		

SELECT @IsAdminCanViewVNIP = 1
IF (@AdminID > 0) 
BEGIN
	DECLARE @ErrCode INT
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission_All @custid=@AdminID,@funcname='[ViewIPVN]',@ErrCode=@ErrCode OUTPUT
	IF @ErrCode<> 0 SELECT @IsAdminCanViewVNIP = 0 ELSE SELECT @IsAdminCanViewVNIP = 1     
END

SELECT ISNULL(reject,0) AS Suspend,
	   ISNULL (closed,0) As Closed,
	   ISNULL (autosuspend,0) As AutoSuspend,	
	   ISNULL (cm.DisableAutoMPT ,0) As DisableAutoMPT,	
	   ISNULL(DisableHorseracing,0) AS DisableHorseracing,
	   ISNULL(DisableOpenTote,0) AS DisableOpenTote,
	   ISNULL(DisableFinancial,0) AS DisableFI,
	   ISNULL(SyncCasino,0) AS SyncCasino,
	   ISNULL(DisableCasino,0) AS DisableCasino,
	   ISNULL(DisableOutright,0) AS DisableOutright,
	   ISNULL(DisableBingo,0) AS DisableBingo,
	   ISNULL(DisableNumber,0) AS DisableNumber,
	   ISNULL(DisableP2P,0) AS DisableP2P,	   
	   ISNULL(SyncBingo,0) AS SyncBingo,
	   ISNULL(DisableLiveCasino,0) AS DisableLiveCasino,
	   ISNULL(SyncLiveCasino,0) AS SyncLiveCasino,
	   ISNULL(srecommend, 0) AS SRecommend,
	   ISNULL(mrecommend, 0) AS MRecommend,
	   ISNULL(recommend, 0) as ARecommend,
	   ISNULL(@IsAdminCanViewVNIP,1) AS IsAdminCanViewVNIP,
	   @LimitPerIP as LimitPerIP,
	   @SelectedBetting as SelectedBetting,
	   @IsInternal AS IsInternal,
	   ISNULL(DisableVirtualSports,0) as DisableVirtualSports,
	   ISNULL(HideVirtualSports,0) as HideVirtualSports,
	   ISNULL(DisableCasinoBonus,0) as DisableCasinoBonus,  
	   ISNULL(DoubleCommLosing,0) as DoubleCommLosing
FROM custinfo AS ci WITH (nolock)
	LEFT JOIN CustMaster AS cm WITH (NOLOCK) ON ci.CustID = cm.custid
WHERE ci.CustID = @CustID

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelStatus] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelStatus] TO [vnteam] AS [dbo]