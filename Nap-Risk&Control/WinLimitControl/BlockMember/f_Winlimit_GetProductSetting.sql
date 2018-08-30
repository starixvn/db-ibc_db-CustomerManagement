/*<info serverAlias="DBTXN-bodb02" executers="" viewers="vnteam" isFunction="1"></info>*/
USE [bodb02]
GO

ALTER FUNCTION [dbo].[f_Winlimit_GetProductSetting] ()
RETURNS @ProductSetting TABLE (ProductId TINYINT, ProductName VARCHAR(50), BetType SMALLINT, IsActive_SMA BIT, IsActive_Company BIT)
AS
/*
	Created: 2015107@Patrick	
	Task: Setting SMA & Company have check max winning or not
	DB: DBTRANS/BODB02
	Revisions:
		- 20151224@Patrick: Support RnG Casino [Redmine: #49803]
		- 20160511@Dominic: Support Voidbridge [Redmine: #57151]
		- 20160524@Helen: Support OneRnG [Redmine: #57680]
		- 20161019@Winnie: Fishing World [Redmine:#62547]
		- 20161011@Helen: CWL - Phase 3 [Redmine:61220]
		- 20170611@Helen: CWL Phase 3 - Apply for Virtual Sport [Redmine:72603]
		- 20170707@Elodie: Apply SMA Winlimit for Lottery [Redmine:#77927]
		- 20170710@Helen: Keno Lottery, BetradarVS into CWL [Redmine:77567,77564]
		- 20171027@Johnson: Add Lucky 3 [Redmine: #75883]
		- 20171001@Elodie: Apply SMA Winlimit and Company Win Limit for BullFighting [Redmine:#81664]
		- 20180125@Vicky: Apply SMA Winlimit for Virtual Sport [Redmine:#89284]
		- 20180319@Robert: CWL - Pragmatic Integration [Redmine:#91762]
		- 20180703@Elodie: Apply SMA Winlimit and CWL for Poker Games Product - [Redmine: #97675]

	Parameters Explanation:	
*/
BEGIN
	INSERT INTO @ProductSetting(ProductId, ProductName, BetType, IsActive_SMA, IsActive_Company)
	(
		SELECT a.ProductId, p.ProductName, a.BetType, a.IsActive_SMA, a.IsActive_Company
		FROM (
			
			SELECT 4 AS ProductId, 1101 AS BetType, 1 AS IsActive_SMA, 1 AS IsActive_Company 
			UNION ALL
			SELECT 6, 2101, 1, 1 -- RNG Casino
			UNION ALL
			SELECT 12, 1701, 1, 1 -- Gold Deluxe
			UNION ALL
			SELECT 13, 2001, 0, 1 -- Microgaming - Live Casino
			UNION ALL 
			SELECT 17, 2008, 0, 1 -- Microgaming - RNG Casino
			UNION ALL
			SELECT 22, 4001, 1, 1 -- Macau Games
			UNION ALL
			SELECT 21, 2401, 1, 1 -- Allbet
			UNION ALL
			SELECT 24, 1011, 1, 1 -- Fishing World
			UNION ALL
			-- Phase 3: add more
			SELECT 3, 81, 0, 1 --Number Game
			UNION ALL				
			SELECT 5, 1201, 1, 1 --Virtual Sports
			UNION ALL
			SELECT 8, 1501, 0, 1  -- Keno
			UNION ALL		
			SELECT 28, 1021, 1, 1  -- Lottery 
			--UNION ALL
			--SELECT 14, 1900, 0, 1  -- Macau
			
			UNION ALL
			SELECT 27, 2701, 0, 1  -- BetradarVS
									
			UNION ALL
			SELECT 26, 1600, 0,1 --Lucky 3
			UNION ALL
			SELECT 30, 1004, 1, 1  -- BullFighting
			UNION ALL 
			SELECT 32, 4101, 0, 1 --Pragmatic Integration
			UNION ALL 
			SELECT 33, 1401, 1, 1 --PockerGames

		) a INNER JOIN DBPRO.bodb02.dbo.Products p WITH(NOLOCK) ON a.ProductId = p.ProductID
	)

	RETURN
END
GO
