/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_Configuration_Ins]
	 @UserId		INT = 0
	,@IP			VARCHAR(15) = ''
	,@FunctionType	TINYINT
	,@ProductID		TINYINT
	,@SportType		SMALLINT
	,@SettingType	TINYINT
	,@SiteID		INT
	,@Currency		INT
	,@UserNames		VARCHAR(MAX) = ''
	,@BeginTime		SMALLDATETIME
	,@EndTime		SMALLDATETIME
	,@ShowTime		SMALLDATETIME
	,@LockAddingNew BIT = 0
	,@Bettype		SMALLINT = 0
	,@IsLive		BIT = 0	
AS
BEGIN
/*
	Created: 20201002@Eden
	Task :  Insert UMConfig
	DB: DBCUST.CustDB
	Revisions:	
		- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]

	Param's Explanation:   
		
	Examples : 
		EXEC [Acc_UMTool_Configuration_Ins] 
			@UserID			= 8
			@FunctionType	= 1, 
			@ProductID		= 1,
			@SportType		= 0	,
			@SettingType	= 0,
			@SiteID			= 1,
			@Currency		= 20,
			@UserNames		= 'supertest1,supertest2,master1,Member01,HI,SA-RM',
			@BeginTime		= '2020/10/03 01:15:00',
			@EndTime		= '2020/10/05 16:17:00',
			@ShowTime		= '2020/10/01 20:15:20',
			@LockAddingNew	= 1 ,
			@Bettype		= 0,
			@IsLive			= 0
*/
SET NOCOUNT ON	
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
	SET @StartRun = GETDATE()

	DECLARE @UMConfig TABLE (
		--[RowID] INT IDENTITY,
		[UserName] [varchar](30),
		[FunctionType] [tinyint],
		[ProductID] [tinyint] ,
		[SportType] [smallint] ,
		[BetType] [smallint] default 0,
		[IsLive] [bit] default 0,
		[SettingType] [tinyint],
		[SiteID] [int],
		[Currency] [int],
		[SuperID] [int]
	)

	DECLARE @SuperTbl TABLE ( 
		[UserName] [varchar](30),
		[SuperID] [int],
		[S_SiteID] [int],
		[S_Currency] [int]
	)

	DECLARE @ErrorTbl TABLE (UserName VARCHAR(30),ErrorCode INT , ErrorMsg VARCHAR(200))

	IF (@FunctionType IN (2,101) AND (@ProductID <> 0 OR  @SportType <> 0 OR @SettingType <> 0 ))
	BEGIN
		INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		SELECT '',11,'Must Config for All Product/Sport/SettingType' 

		GOTO ReturnErrorTbl;
	END

	IF (@ProductID IN (0,1,6,8,12) AND (@SportType <> 0 OR @SettingType <> 0 ))
	BEGIN
		INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		SELECT '',12,'Must Config for All Sport/SettingType' 

		GOTO ReturnErrorTbl;
	END

	IF NOT EXISTS (SELECT 1 FROM Site WITH(NOLOCK) WHERE SiteID = @SiteID ) AND @SiteID <> 0
	BEGIN
		INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		SELECT '',13,'Invalid Site' 

		GOTO ReturnErrorTbl;
	END

	IF NOT EXISTS (SELECT 1 FROM exchange WITH(NOLOCK) WHERE ExchangeId = @Currency ) AND @Currency <> 0
	BEGIN
		INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		SELECT '',14,'Invalid Currency' 

		GOTO ReturnErrorTbl;
	END

	IF NOT EXISTS (	SELECT 1 
					FROM ProductSettingDetail WITH(NOLOCK) 
					WHERE ProductID = @ProductID 
						AND (SportType = @SportType OR @SportType = 0)
						AND ( SettingType = @SettingType OR @SettingType = 0)
						AND SettingStatus = 0
					) 
		AND @ProductID NOT IN (0,1,6,8,12)
	BEGIN
		INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		SELECT '',15,'Product/Sport/SettingType does not exist' 

		GOTO ReturnErrorTbl;
	END

	IF @BeginTime >= @EndTime OR @ShowTime >= @BeginTime
	BEGIN
		INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		SELECT '',16,'The Begin Time must be less than End Time and The Show Time must be less than Begin Time.' 

		GOTO ReturnErrorTbl;
	END

	IF ISNULL(@UserNames,'')  <> ''
	BEGIN
		INSERT INTO @SuperTbl (UserName)
		SELECT DISTINCT p.val
		FROM dbo.f_StringSplit(@UserNames,',') p
		OPTION (MAXRECURSION 0)

		UPDATE t
			SET t.SuperID = c.custid,
				t.S_Currency = c.currency,
				t.S_SiteID = s.siteid
		FROM @SuperTbl t
			INNER JOIN Customer c WITH(NOLOCK) ON t.UserName = c.username AND c.roleid = 4
			INNER JOIN Site s WITH(NOLOCK) ON s.site = c.site 

		DELETE t
		OUTPUT deleted.UserName,1,'Invalid Super(s)' INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		FROM @SuperTbl t
		WHERE SuperID IS NULL

		INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
		SELECT t.UserName,2,'Site does not belong with the Super(s)' 
		FROM @SuperTbl t
		WHERE S_SiteID <> @SiteID AND @SiteID <> 0
		UNION ALL
		SELECT t.UserName,3,'Currency does not belong with the Super(s) '
		FROM @SuperTbl t
		WHERE S_Currency <> @Currency AND @Currency <> 0

		DELETE t
		FROM @SuperTbl t
		WHERE S_SiteID <> @SiteID AND @SiteID <> 0

		DELETE t
		FROM @SuperTbl t
		WHERE S_Currency <> @Currency AND @Currency <> 0
	END
	ELSE
	BEGIN
		INSERT INTO @SuperTbl (UserName,SuperID) SELECT NULL,0
	END

	INSERT INTO @UMConfig(FunctionType,ProductID,SportType,BetType,IsLive,SettingType,SiteID,Currency,SuperID,UserName)
	SELECT @FunctionType,@ProductID,@SportType,@BetType,@IsLive,@SettingType,@SiteID,@Currency,SuperID,UserName
	FROM @SuperTbl

	INSERT INTO @ErrorTbl(Username,ErrorCode,ErrorMsg)
	SELECT ISNULL(t.UserName,'All Supers'),4,'Super(s)''s configuration is existing in System'
	FROM @UMConfig t
		INNER JOIN UMConfig c WITH(NOLOCK) 
			ON t.ProductID		=	c.ProductID
			AND t.SportType 	=	c.SportType
			AND t.SettingType 	=	c.SettingType
			AND t.FunctionType	=	c.FunctionType
			AND t.Currency		=	c.Currency
			AND t.SiteID		=	c.SiteID
			AND t.SuperID		=	c.SuperID

	--Convert time from GMT +8 to GMT -4
	SELECT @ShowTime = DATEADD(hh,-12,@ShowTime)
	SELECT @BeginTime = DATEADD(hh,-12,@BeginTime)
	SELECT @EndTime = DATEADD(hh,-12,@EndTime)
	
	IF NOT EXISTS( SELECT 1 FROM @ErrorTbl)
	BEGIN
		INSERT INTO UMConfig(ProductID,SportType,BetType,IsLive,SettingType,FunctionType,SiteID,Currency,SuperID,BeginTime,EndTime,ShowTime,LockAddingNew)
		SELECT ProductID,SportType,BetType,IsLive,SettingType,FunctionType,SiteID,Currency,SuperID,@BeginTime,@EndTime,@ShowTime,@LockAddingNew
		FROM @UMConfig

		SET @EndRun = GETDATE()
		SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

		DECLARE @SuperIDs VARCHAR(MAX) = ''

		SELECT @SuperIDs = @SuperIDs + ',' + CONVERT(VARCHAR(15),SuperID)
		FROM @UMConfig

		SELECT @SuperIDs = STUFF(@SuperIDs,1,1,'')

		DECLARE @LogData VARCHAR(MAX)
		SELECT  @LogData = '<R '
							+ 'FunctionType="'+ coalesce(cast(@FunctionType as varchar(50)),space(1)) + '" ' 
							+ 'ProductID="'+ coalesce(cast(@ProductID as varchar(50)),space(1)) + '" '
							+ 'SportType="'+ coalesce(cast(@SportType as varchar(50)),space(1)) + '" ' 
							+ 'BetType="'+ coalesce(cast(@BetType as varchar(50)),space(1)) + '" ' 
							+ 'IsLive="'+ coalesce(cast(@IsLive as varchar(50)),space(1)) + '" ' 
							+ 'SettingType="'+ coalesce(cast(@SettingType as varchar(50)),space(1)) + '" '
							+ 'SiteID="'+ coalesce(cast(@SiteID as varchar(50)),space(1)) + '" ' 
							+ 'Currency="'+ coalesce(cast(@Currency as varchar(50)),space(1)) + '" ' 
							+ 'SuperIDs="'+ coalesce(cast(@SuperIDs as varchar(50)),space(1)) + '" ' 
							+ 'BeginTime="'+ coalesce(cast(@BeginTime as varchar(50)),space(1)) + '" '
							+ 'EndTime="'+ coalesce(cast(@EndTime as varchar(50)),space(1)) + '" ' 
							+ 'ShowTime="'+ coalesce(cast(@ShowTime as varchar(50)),space(1)) + '" ' 
							+ 'LockAddingNew="'+ coalesce(cast(@LockAddingNew as varchar(50)),space(1)) + '" ' 
							+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
							+ ' />'

		--Write log:
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserId				= @UserId,
					@CustId				= 0,
					@ActionId			= 210001,
					@TrackingValue		= @LogData,
					@Duration			= @Duration
	END

	ReturnErrorTbl:

	SELECT * FROM @ErrorTbl
END
GO