/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_CM_SVIPMaxBetPlayerCheck] 
	  @UserName		VARCHAR(MAX) =	''
	, @SportTypes	VARCHAR(300) = '0'
	, @Bettypes 	VARCHAR(100) = '0'
	, @Multiplier	DECIMAL(9,2) = 1
	, @IsTest		TINYINT		 = 0
	, @ErrCode		TINYINT		 = 0  OUTPUT
	, @ErrMsg		NVARCHAR(MAX)= '' OUTPUT
AS
/*
	Created: Winfred
	Date: 20250224
	Task : [NAP CM] Customer - Increase Bet Limit
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20250224@Winfred: [NAP CM] Customer - Increase Bet Limit [RedmineID: #218073] 

	Param's Explanation:

	Example: exec NAP_CM_SVIPMaxBetPlayerCheck @UserName = '', @SportTypes = '0', @Bettypes = '0', @Multiplier = 0, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #tempCust(custid INT, username VARCHAR(500), siteid INT , SportType smallint, Bettype smallint)
	CREATE CLUSTERED INDEX CIX_tempCust ON #tempCust(custid, siteid, SportType, Bettype)
	
	INSERT INTO #tempCust(username, SportType, Bettype) 
	SELECT DISTINCT u.VALUE AS username , s.SportType , b.Bettype
	FROM STRING_SPLIT(@UserName,',')  u
		CROSS APPLY ( SELECT VALUE AS SportType FROM STRING_SPLIT(@SportTypes,',') WHERE VALUE <> '' ) s  
		CROSS APPLY ( SELECT VALUE AS Bettype FROM STRING_SPLIT(@Bettypes,',') WHERE VALUE <> '' ) b
	WHERE u.VALUE <> ''
	
	IF EXISTS (SELECT TOP 1 1 FROM #tempCust WHERE LEN(username)> 30)
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg = STRING_AGG(username,', ') WITHIN GROUP (ORDER BY username)
		FROM #tempCust
		WHERE custid IS NULL

		SELECT @ErrMsg =  N'Username does not exist. Please verify or remove it from the list. ' + @ErrMsg 
		RETURN
	END

	Update a
	SET a.custid = c.custid ,
		a.siteid = s.siteid
	FROM #tempCust a
	 CROSS APPLY (SELECT TOP 1 custid, Site FROM Customer WITH(NOLOCK) WHERE username = CAST(a.username AS VARCHAR(30))) c
	 CROSS APPLY (SELECT TOP 1 SiteID FROM site WITH(NOLOCK) WHERE site = c.site ) s
	 
	IF EXISTS (SELECT TOP 1 1 FROM #tempCust WHERE custid IS NULL)
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg = STRING_AGG(username,', ') WITHIN GROUP (ORDER BY username)
		FROM #tempCust
		WHERE custid IS NULL

		SELECT @ErrMsg =  N'Username does not exist. Please verify or remove it from the list. ' + @ErrMsg 
		RETURN
	END

	IF EXISTS ( SELECT TOP 1 1 
				FROM #tempCust c
					CROSS APPLY (SELECT TOP 1 custid FROM SVIPMaxBetPlayer WITH(NOLOCK) WHERE siteid = c.siteid
								 AND custid = c.custid AND SportType = c.SportType AND Bettype = c.Bettype) v)
		 OR EXISTS ( SELECT TOP 1 1 FROM #tempCust c GROUP BY custid, siteid , SportType, Bettype  HAVING COUNT(1) > 1)
	BEGIN
		SELECT @ErrCode = 102,
			@ErrMsg = STRING_AGG(c.username,', ') WITHIN GROUP (ORDER BY c.username)
		FROM (
			SELECT DISTINCT username
			FROM ( SELECT username
				   FROM #tempCust c
					CROSS APPLY (SELECT TOP 1 custid FROM SVIPMaxBetPlayer WITH(NOLOCK) WHERE siteid = c.siteid
											AND custid = c.custid AND SportType = c.SportType AND Bettype = c.Bettype) v
				 UNION ALL
				 SELECT username
				 FROM #tempCust c GROUP BY custid, siteid , username , SportType, Bettype HAVING COUNT(1) > 1 ) kq) c


		SELECT @ErrMsg =  N'This member already has a Bet Limit Increase. Please edit the existing rule instead of creating a new one. ' + @ErrMsg 
		RETURN
	END

	SELECT custid, username, siteid, SportType, Bettype
	FROM #tempCust

	DROP TABLE #tempCust
END
GO
