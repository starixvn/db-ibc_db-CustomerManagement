/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustLastBetFilter_Sel]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @SubAccId		INT = 0
AS
/*
	Creator: 20230608@Tacy  
	Task : Get all users' filter on Last Bet func
	DB: DBCUST/CustDB

	Revisions:  
		- 20230608@Tacy: Alpha - Bet List - Enhance Last bet function [Redmine:#186142]
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @tbFilter TABLE (FilterID INT PRIMARY KEY, FilterValue XML)

	DECLARE @tbUsername TABLE (
				CustID INT, 
				username VARCHAR(30), 
				FilterID INT,
				IsWatchList BIT DEFAULT(0),
				PRIMARY KEY (CustID, FilterID, IsWatchList))

	INSERT INTO @tbFilter (FilterID, FilterValue)
	SELECT [FilterID], CONVERT(XML, [FilterValue])
	FROM  Cust_LastBetFilter WITH (NOLOCK) 
	WHERE CustID=@CustID AND SubAccId=@SubAccId

	--Input members
	INSERT INTO @tbUsername (FilterID, username, CustID)
	SELECT t.FilterID, c.username, c.custid
	FROM @tbFilter t
	CROSS APPLY (SELECT t.f.value('@members','VARCHAR(MAX)') AS MemberList
					FROM FilterValue.nodes('Filter') t(f)) m
	CROSS APPLY (SELECT CAST(value AS INT) AS CustID
					FROM STRING_SPLIT(m.MemberList,',')) ci
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ci.CustID

	--Watchlist members & exclude Input members
	INSERT INTO @tbUsername (FilterID, username, CustID, IsWatchList)
	SELECT t.FilterID, c.username, c.custid, 1
	FROM @tbFilter t
	CROSS APPLY (SELECT t.f.value('@wl','VARCHAR(MAX)') AS MemberList
					FROM FilterValue.nodes('Filter') t(f)) m
	CROSS APPLY (SELECT CAST(value AS INT) AS CustID
					FROM STRING_SPLIT(m.MemberList,',')) ci
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ci.CustID

	SELECT f.[FilterID], [FilterName], [FilterValue], [IsDefault], [CreatedDate]
		, STUFF ((SELECT ',' + t.username
                FROM @tbUsername t
				WHERE t.FilterID=f.FilterID AND IsWatchList=1
                FOR XML PATH('')),1,1,'') as WatchList
		, STUFF ((SELECT ',' + t.username
                FROM @tbUsername t
				WHERE t.FilterID=f.FilterID AND IsWatchList=0
                FOR XML PATH('')),1,1,'') as InputList
	FROM  Cust_LastBetFilter f WITH (NOLOCK)
	WHERE CustID=@CustID AND SubAccId=@SubAccId
	ORDER BY CreatedDate, FilterName
END
GO