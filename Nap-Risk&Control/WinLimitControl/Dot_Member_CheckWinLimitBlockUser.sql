/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_intg,Dot_Member,API_Vender" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_CheckWinLimitBlockUser]  
(  
	 @custID  INT ,  
	 @Bettype INT = NULL  
)  
AS  
/*  
	Created: 20151023@Victor  
	Task: when Place bet/Transfer -withdraw :  check user is WinLimit BlockUser/block transfer or not  
	DB: DBCUST/CUSTDB  
    
	Revisions:  
		- 20160617@Helen: CWL - phase 2 - BlockUser/block transfer - [Redmine: 57722]
		- 20170623@Helen: CWL - Block Transferred cannot run - [Redmine: 78851]
		
*/  
BEGIN  
	SET NOCOUNT ON   

	DECLARE @IsBlockedPlaceBet BIT
			,@IsBlockedTransfer BIT
			
	DECLARE @Max_level VARCHAR(50)
	
	SET @Max_level = ISNULL((SELECT TOP 1 LevelName FROM Winlimit_LevelSetting WITH (NOLOCK)
							ORDER BY LevelID DESC),'')
	
	IF @Bettype IS NOT NULL	-- For PlaceBet	
	BEGIN
		SELECT @IsBlockedPlaceBet=ISNULL(IsBlockedPlaceBet,0)
		FROM dbo.WinLimit_CustGameStatus WITH (NOLOCK) 
		WHERE CustID = @custID 
			AND BettypeID = @Bettype
		
		SELECT ISNULL(@IsBlockedPlaceBet,0) AS IsBlockedPlaceBet
		
	END
	ELSE -- For Withdraw/Transfer
	BEGIN
		IF EXISTS(SELECT 1 FROM WinLimit_CustGameStatus (NOLOCK) WHERE CustID = @custID)
		BEGIN
			SELECT CS.ProductID,CS.BettypeID,CASE WHEN CS.IsBlockedTransfer = 1 THEN @Max_level ELSE LS.LevelName END AS 'CWL status',CS.IsBlockedTransfer
			FROM dbo.WinLimit_CustGameStatus CS WITH (NOLOCK) 
				 CROSS APPLY (SELECT TOP 1 CM_1.LevelID   
								FROM WinLimit_CustGameMonitoring CM_1 WITH (NOLOCK)   
									INNER JOIN Winlimit_GameGroupSetting GGS WITH (NOLOCK) ON GGS.GroupID =CM_1.GroupID 
																							AND CM_1.ProductID = GGS.ProductID 
																							AND CS.BettypeID = GGS.BetTypeID
								WHERE CS.CustID = CM_1.CustID AND CS.ProductID = CM_1.ProductID 
								ORDER BY CM_1.ModifiedDate DESC  
								) CM  
				INNER JOIN Winlimit_LevelSetting LS WITH (NOLOCK) ON LS.LevelID = CM.LevelID
			WHERE cs.CustID = @custID 
		END
		ELSE
		BEGIN
			SELECT NULL AS ProductID,NULL AS BettypeID,NULL AS 'CWL status', 0 AS IsBlockedTransfer
		END
	END
	
END  
GO
GRANT EXECUTE ON [dbo].[Dot_Member_CheckWinLimitBlockUser] TO [Dot_intg]
GO
GRANT EXECUTE ON [dbo].[Dot_Member_CheckWinLimitBlockUser] TO Dot_Member
GO
GRANT EXECUTE ON [dbo].[Dot_Member_CheckWinLimitBlockUser] TO [API_Vender] 
GO




