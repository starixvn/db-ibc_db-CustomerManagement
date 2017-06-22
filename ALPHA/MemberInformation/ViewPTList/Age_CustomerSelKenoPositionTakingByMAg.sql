ALTER PROCEDURE [dbo].[Age_CustomerSelKenoPositionTakingByMAg]
(
	@MRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
	Created: 20140611@Logan - [Redmine:#17174]
	Date:  
	Task : Select Keno PT Info of Agentss
	DB: DBCUST.CustDB
	Original: Age_CustomerSelKenoPositionTakingBySAg

	Revisions: 
		- 20141205@Johnson: Add new country Korea (bettype=1514)for Keno [Redmine: #26647]
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20160919@Helen: Page list navigation disappears when select small page size number of Keno product in Position Talking (%) - [Redmine:59432]
		- 20161116@Winnie: Show MaxKeno 2, Hide Massac,Malta [RedmineID: #66058]
		- 20170622@Winnie: Color for closed accounts  [RedmineID: #74494]
	Param's Explanation:
	• @MRecommend: Master Agent ID
*/
BEGIN
	SET NOCOUNT ON

	----- 20150610@Kos -------------------
	DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)	

	BEGIN TRY
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK)
	END TRY
	BEGIN CATCH
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
	END CATCH
	-----20150610@Kos -------------------

	SELECT @TotalPages = COUNT(ci.custid),
	       @TotalPages = @TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	  FROM custinfo AS ci WITH(NOLOCK)		
	 WHERE 1 = 1
	   and ci.mrecommend = @MRecommend
	   AND ci.roleid = 2

	SELECT *
	  FROM (SELECT ROW_NUMBER() OVER(ORDER BY CASE 
	                                            WHEN ISNULL(ci.enabled, 0) = 0 THEN 3
											    WHEN ISNULL(ci.closed, 0) = 1 THEN 2
											    WHEN ISNULL(ci.reject, 0) = 1 THEN 1
											    ELSE 0
										      END, ci.username
									) AS RowNumber,
		           ci.closed,
		           ci.enabled,
		           ISNULL(ci.reject, 0) AS suspended,
	               ci.username,
		           ci.custid,
		           MAX(CASE WHEN cg.bettype = 1501 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1501,
		           --MAX(CASE WHEN cg.bettype = 1502 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1502,
		           MAX(CASE WHEN cg.bettype = 1503 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1503,
		           MAX(CASE WHEN cg.bettype = 1504 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1504,
		           MAX(CASE WHEN cg.bettype = 1505 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1505,
		           --MAX(CASE WHEN cg.bettype = 1506 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1506,
		           --MAX(CASE WHEN cg.bettype = 1507 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1507,
		           MAX(CASE WHEN cg.bettype = 1508 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1508,
		           --MAX(CASE WHEN cg.bettype = 1509 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1509,
		           MAX(CASE WHEN cg.bettype = 1511 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1511,
		           MAX(CASE WHEN cg.bettype = 1513 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1513,
		           MAX(CASE WHEN cg.bettype = 1514 AND cg.sporttype = 202 THEN cg.mpositiontaking ELSE 0 END) AS mpositiontaking_1514,
		           
		           MAX(CASE WHEN cg.bettype = 1501 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1501,
		           --MAX(CASE WHEN cg.bettype = 1502 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1502,
		           MAX(CASE WHEN cg.bettype = 1503 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1503,
		           MAX(CASE WHEN cg.bettype = 1504 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1504,
		           MAX(CASE WHEN cg.bettype = 1505 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1505,
		           --MAX(CASE WHEN cg.bettype = 1506 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1506,
		           --MAX(CASE WHEN cg.bettype = 1507 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1507,
		           MAX(CASE WHEN cg.bettype = 1508 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1508,
		           --MAX(CASE WHEN cg.bettype = 1509 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1509,
		           MAX(CASE WHEN cg.bettype = 1511 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1511,
		           MAX(CASE WHEN cg.bettype = 1513 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1513,
		           MAX(CASE WHEN cg.bettype = 1514 AND cg.sporttype = 202 THEN cg.apositiontaking ELSE 0 END) AS apositiontaking_1514,
				   ISNULL(cl.ClosedReason,0) AS ClosedReason
	          FROM custinfo ci with(nolock)
					INNER JOIN CustSettingGame cg with(nolock) on ci.custid = cg.custid
					INNER JOIN CustGameType ct with(nolock) on ci.custid = ct.CustID
					INNER JOIN @tmp_GameType gt on gt.GameTypeID = ct.GameTypeID and gt.IBCBetTypeID = cg.Bettype
					LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		     WHERE 1 = 1
		       and ci.mrecommend = @MRecommend
		       AND ci.roleid = 2
		       AND cg.sporttype = 202
		  GROUP BY ci.enabled, ci.closed, ci.reject, ci.username, ci.custid,cl.ClosedReason
	       ) t
	 WHERE RowNumber >= (@PageIndex - 1) * @PageSize + 1 AND RowNumber <= @PageIndex * @PageSize

END




GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelKenoPositionTakingByMAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelKenoPositionTakingByMAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelKenoPositionTakingByMAg] TO [VNTeam]
GO  