/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelKenoPositionTakingBySAg]
(
	@SRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
	Created: 20140611@Logan - [Redmine:#17174]
	Date:  
	Task : Select Keno PT Info of Masters
	DB: DBCUST.CustDB
	Original: Age_CustomerSelLiveCSPositionTakingBySAg

	Revisions: 
		- 20141205@Johnson: Add new country Korea (bettype=1514)for Keno [Redmine: #26647]
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20161116@Winnie: Show MaxKeno 2, Hide Massac,Malta [RedmineID: #66058]
		- 20170622@Winnie: Color for closed accounts  [RedmineID: #74494]
		- 20200826@Eden: Keno - Hide un-used bettype (country) of Keno [Redmine: #138657]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20230327@Tacy: Alpha - Enhance to show First/Last name in reports [RedmineID: #185313]

	Param's Explanation:
	• @SRecommend: Super Agent ID
*/
BEGIN
	SET NOCOUNT ON

	----- 20150610@Kos -------------------
	DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)	

	BEGIN TRY
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK) WHERE IsDisabled = 0 AND GameTypeID BETWEEN 1 AND 99
	END TRY
	BEGIN CATCH
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK) WHERE IsDisabled = 0 AND GameTypeID BETWEEN 1 AND 99
	END CATCH
	-----20150610@Kos -------------------

	SELECT @TotalPages = COUNT(ci.custid),
	       @TotalPages = @TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	  FROM custinfo AS ci WITH(NOLOCK)		
	 WHERE 1 = 1
	   and ci.SRecommend = @SRecommend
	   AND ci.roleid = 3

	SELECT *
	  FROM (SELECT ROW_NUMBER() OVER(ORDER BY CASE 
	                                            WHEN ISNULL(ci.enabled, 0) = 0 THEN 3
											    WHEN ISNULL(ps.closed, 0) = 1 THEN 2
											    WHEN ISNULL(ps.reject, 0) = 1 THEN 1
											    ELSE 0
										      END, ci.username
									) AS RowNumber,
		           ps.closed,
		           ci.enabled,
		           ISNULL(ps.reject, 0) AS suspended,
	               ci.username,
				   c.firstname,
				   c.lastname,
		           ci.custid,
		           MAX(CASE WHEN cg.bettype = 1501 AND cg.sporttype = 202 THEN cg.spositiontaking ELSE 0 END) AS spositiontaking_1501,
				   ISNULL(cl.ClosedReason,0) AS ClosedReason,
				   ISNULL(ps.Locked,0) Locked
	    FROM custinfo ci WITH(NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ci.custid
        INNER JOIN CustSettingGame cg WITH(NOLOCK) ON ci.custid = cg.custid
        INNER JOIN CustGameType ct WITH(NOLOCK) ON ci.custid = ct.CustID
        INNER JOIN @tmp_GameType gt ON gt.GameTypeID = ct.GameTypeID and gt.IBCBetTypeID = cg.Bettype
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS closed
							, CASE WHEN SuspendInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS reject
							, Locked
						FROM dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS ps
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		     WHERE 1 = 1
		       and ci.SRecommend = @SRecommend
		       AND ci.roleid = 3
		       AND cg.sporttype = 202
		  GROUP BY ci.enabled, ps.closed, ps.reject, ci.username, c.firstname, c.lastname, ci.custid,cl.ClosedReason,ps.Locked
	       ) t
	 WHERE RowNumber >= (@PageIndex - 1) * @PageSize + 1
	   AND RowNumber <= @PageIndex * @PageSize

END
GO
