/*<info serverAlias="DBCUST-CUSTDB" executers="bodbadminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[CS_CommMatrix_Sel]
   @UserName VARCHAR(30) = '',
   @ErrCode INT = 0 OUTPUT,
   @ErrMsg VARCHAR(100) ='' OUTPUT
AS  
/*  
 Created: 20190813@Johnson
 Task : Get PT Matrix for cn88
 DB:  DBCUST/CustDB  
 Original:  

 Revision:
    - 20190813@Johnson: initial sp [redmine:#116691]
 Param's Explanation:  

 */  
BEGIN  
	SET NOCOUNT ON
	
	CREATE TABLE #CommResult (sporttype INT,bettype INT, isLive BIT, roleid TINYINT, GroupName VARCHAR(10), Comm DECIMAL(9,8))
	
	DECLARE @custid INT,
		@roleid TINYINT,
		@Srecommend INT,
		@mrecommend INT,
		@recommend INT,	
		@site VARCHAR(10),
		@uGroup VARCHAR(3),
		@IsGroupComm BIT
	
	SELECT @custid = custid,
		@roleid = roleid,
		@site = site,
		@srecommend = srecommend,
		@mrecommend = mrecommend,
		@recommend = recommend
	FROM dbo.customer WITH(NOLOCK)
	WHERE username = @username
	
	IF @@rowcount = 0  
	BEGIN  
		SELECT @ErrCode = 101, @ErrMsg ='Invalid UserName!'
		RETURN  
	END 
	
	IF @site <> 'CN88'
	BEGIN  
		SELECT @ErrCode = 102, @ErrMsg ='Invalid account!'
		RETURN  
	END 
	
	SELECT t.* INTO #SportBettypeFilter2
	FROM dbo.f_CS_SportBetTypeSettingSelect(null, 2, 0) t
	
	IF @roleid IN (4,3,2,1)
	BEGIN
		INSERT INTO #CommResult(sporttype,bettype,isLive,roleid,GroupName,Comm)
		SELECT cs.sporttype, cs.bettype, cs.isLive, 4, gc.GroupName, cs.Discount
		FROM dbo.f_CS_GetDiscount_Agent(@srecommend) cs
			INNER JOIN #SportBettypeFilter2 ft ON cs.SportType = ft.SportType AND cs.BetType = ft.BetType AND cs.IsLive = ft.IsLive
			LEFT JOIN dbo.CS_GroupConfig gc ON gc.SportType = ft.SportType AND gc.BetType = ft.BetType AND gc.IsLive = ft.IsLive AND  gc.GroupId = cs.GroupId
	END
	
	IF @roleid IN (3,2,1)
	BEGIN
		INSERT INTO #CommResult(sporttype,bettype,isLive,roleid,GroupName,Comm)
		SELECT cs.sporttype, cs.bettype, cs.isLive, 3, gc.GroupName, cs.Discount
		FROM dbo.f_CS_GetDiscount_Agent(@mrecommend) cs
			INNER JOIN #SportBettypeFilter2 ft ON cs.SportType = ft.SportType AND cs.BetType = ft.BetType AND cs.IsLive = ft.IsLive
			LEFT JOIN dbo.CS_GroupConfig gc ON gc.SportType = ft.SportType AND gc.BetType = ft.BetType AND gc.IsLive = ft.IsLive AND  gc.GroupId = cs.GroupId
	END
	
	IF @roleid IN (2,1)
	BEGIN
		INSERT INTO #CommResult(sporttype,bettype,isLive,roleid,GroupName,Comm)
		SELECT cs.sporttype, cs.bettype, cs.isLive, 2, gc.GroupName, cs.Discount
		FROM dbo.f_CS_GetDiscount_Agent(@recommend) cs
			INNER JOIN #SportBettypeFilter2 ft ON cs.SportType = ft.SportType AND cs.BetType = ft.BetType AND cs.IsLive = ft.IsLive
			LEFT JOIN dbo.CS_GroupConfig gc ON gc.SportType = ft.SportType AND gc.BetType = ft.BetType AND gc.IsLive = ft.IsLive AND  gc.GroupId = cs.GroupId
	END
	
	IF @roleid = 1
	BEGIN
		SELECT @uGroup = ugroup FROM dbo.customer WITH (NOLOCK) WHERE custid = @CustID
		SELECT @IsGroupComm = IsGroupComm FROM dbo.CS_CustSettingMode WITH (NOLOCK) WHERE custid = @CustID
		
		IF @IsGroupComm = 1
		BEGIN
			INSERT INTO #CommResult(sporttype,bettype,isLive,roleid,GroupName,Comm)
			SELECT cs.sporttype, cs.bettype, cs.isLive, 1, cs.uGroup, cs.PlayerDiscount
			FROM dbo.f_CS_GetGroupDiscount_Member(@recommend) cs
				INNER JOIN #SportBettypeFilter2 ft ON cs.SportType = ft.SportType AND cs.BetType = ft.BetType AND cs.IsLive = ft.IsLive
		END
		ELSE
		BEGIN
			INSERT INTO #CommResult(sporttype,bettype,isLive,roleid,GroupName,Comm)
			SELECT cs.sporttype, cs.bettype, cs.isLive, 1, gc.GroupName, cs.PlayerDiscount
			FROM dbo.f_CS_GetDiscount_Member(@CustID) cs
				INNER JOIN #SportBettypeFilter2 ft ON cs.SportType = ft.SportType AND cs.BetType = ft.BetType AND cs.IsLive = ft.IsLive
				LEFT JOIN dbo.CS_GroupConfig gc ON gc.SportType = ft.SportType AND gc.BetType = ft.BetType AND gc.IsLive = ft.IsLive 
			WHERE (gc.uGroup = @uGroup OR gc.GroupId IS NULL) 
		END
	END
	
	SELECT *
	FROM #CommResult
END
GO