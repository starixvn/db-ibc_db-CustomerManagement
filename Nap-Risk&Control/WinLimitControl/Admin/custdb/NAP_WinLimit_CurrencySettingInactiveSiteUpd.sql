
/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingInactiveSiteUpd] 
	@ProductId         INT, 
	@GroupId           INT, 
	@LevelId           INT, 
	@MaxWinLimit       MONEY = 0, 
	@ExchangeID        INT   = 0, 
	@IsBlockedPlaceBet BIT   = 0, 
	@IsBlockedTransfer BIT   = 0
AS

/*
Created: Robert	
Date: 2022-06-07
Task: 20220522@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page

DB: DBCUST/CustDB

Revisions:
    - 20220522@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page
	- 20240927@Tacy: New currency BTS [Redmine: 209780]

Parameters Explanation:	
   @ProductId: Product ID.
   @GroupId: Bettype ID.      
   @LevelId: Level ID.
   @MaxWinLimit: Max Win Limit amount.
   @IsBlockedPlaceBet: Is block place bet.
   @IsBlockedTransfer: Is block transfer.   
*/

    BEGIN
	   SET NOCOUNT ON;

	   UPDATE s
		SET 
		    s.MaxWinLimit_RM = @MaxWinLimit, 
		    s.IsBlockedPlaceBet = @IsBlockedPlaceBet, 
		    s.IsBlockedTransfer = CASE
								WHEN st.isDeposit = 0
								THEN 0
								ELSE @IsBlockedTransfer
							 END, 
		    s.MaxWinLimit = CASE
						    WHEN s.ExchangeID IN (20, 218)
						    THEN @MaxWinLimit
						    ELSE ROUND(@MaxWinLimit / e.actualrate, 2)
						END
	   FROM dbo.WinLimit_ProductSettingDetail s WITH (ROWLOCK, UPDLOCK)
		   INNER JOIN dbo.Site st WITH(ROWLOCK) ON s.SiteID = st.siteid
		   INNER JOIN dbo.exchange e WITH(NOLOCK) ON e.ExchangeId = s.ExchangeID
	   WHERE 
		    s.ProductID = @ProductId
		    AND CASE
				  WHEN @GroupId > 0
				  THEN s.GroupId
				  ELSE @GroupId
			   END = @GroupId
		    AND s.LevelID = @LevelId
		    AND st.isActive = 0
		    AND CASE
				  WHEN @ExchangeID > 0
				  THEN s.ExchangeID
				  ELSE @ExchangeID
			   END = @ExchangeID;


    END;