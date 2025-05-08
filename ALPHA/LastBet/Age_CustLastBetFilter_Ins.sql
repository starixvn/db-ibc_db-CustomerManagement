/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustLastBetFilter_Ins]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @SubAccId		INT = 0
	, @FilterName	NVARCHAR(50)=''
	, @Bettype		VARCHAR(MAX)=''
	, @Stake		INT=NULL
	, @InputList	VARCHAR(MAX)=''	-- input members
	, @WatchList	VARCHAR(MAX)=''	-- watchlist members
	, @IsWatchList	TINYINT
	, @SporttypeList VARCHAR(MAX)=''	-- none selection
	, @IsLive		TINYINT
	, @IsDefault	BIT=0
	, @IsNotify		BIT
	, @Language		VARCHAR(2) = 'E'
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(200)	= ''	OUTPUT
	, @IP			VARCHAR(20)		= ''
	, @RoleId		TINYINT
AS
/*
	Creator: 20230608@Tacy  
	Task : Add new filter on Last Bet func
	DB: DBCUST/CustDB

	Revisions:  
		- 20230608@Tacy: Alpha - Bet List - Enhance Last bet function [Redmine:#186142]
		- 20240223@Luke: Telegram Chatbot - Notify Member Last bets [Redmine: #193689]
		- 20241108@Virgil: Alpha - Offer Last Bets function for Super/Master [Redmine: #213315]
		- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]

	Param's Explanation: 
		- @IsLive : 0 ~ Non-Live
					1 ~ Live
					2 ~ Mix (for Parlay)
					3 ~ All

		- @IsWatchList : 0 ~ specific or not include watchlist members
						 1 ~ all watchlist members with filter by specific members option
						 2 ~ all watchlist members with filter by All members option

		- @SporttypeList = '<SportList>
								<Sport s="3,4,5" l="0" m="0"	 h="0"  a="0"  iN="0"/>
								<Sport s="2"	 l="20,10" m="0" h="0"  a="0"  iN="0"/>
								<Sport s="1"	 l="4" m="0"	 h="0"  a="0"  iN="0"/>
								<Sport s="1"	 l="3" m="123"   h="20" a="22" iN="0"/>
								<Sport s="1"	 l="3" m="345"   h="30" a="25" iN="1"/>
							</SportList>'

			@st ~ stake
			@b ~ bettype
			@s ~ sporttype
			@l ~ league
			@m ~ match
			@h ~ home
			@a ~ away
			@iN ~ isNeutral
			@iL ~ isLive
			@wl ~ watchlist members
			
			* BetType	 = "0" ~ All bettype, "" ~ NONE
			* SportType  = "0" ~ All sports
			* League	 = "0" ~ All leagues
			* Match		 = "0" ~ All matches
			* InputList  = "0" ~ All members, "" ~ NONE
			* WatchList  = "0" ~ All members, "" ~ NONE

	***FilterValue:
		<Filter b="0" st="800" members="2260001,2269855,2269865" wl="11927001,11927018" iWL="0" iL="0">
			  <Sport s="47,48" l="0" m="0" h="0" a="0" iN="0" />
			  <Sport s="34" l="58003,58118,100965" m="0" h="0" a="0" iN="0" />
			  <Sport s="1" l="9415,44" m="0" h="0" a="0" iN="0" />
			  <Sport s="2" l="88155" m="64005553" h="661627" a="662924" iN="0" />
			  <Sport s="1" l="230" m="63039168" h="778093" a="41492" iN="1" />
		</Filter>
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	  @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)
	
	DECLARE	  @XML			 XML
			, @xml_SportList XML
			, @FilterValue	 VARCHAR(MAX)
	
	SET @StartRun=GETDATE()

	--Not input bettype
	IF @Bettype=''
	BEGIN
		SELECT @ErrCode=90024
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Please select Bettype' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90024,@Language)    
												 END 
		RETURN
	END

	--Not input Stake
	IF @Stake IS NULL
	BEGIN
		SELECT @ErrCode=90025
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Please enter Stake' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90025,@Language)    
												 END 
		RETURN
	END

	-- none selection for sport/members:
	IF @SporttypeList=''
	BEGIN
		SELECT @ErrCode=90022
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Please select sport(s)' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90022,@Language)    
												 END 
		RETURN
	END

	--remove: not be agent' downline
	IF @InputList NOT IN ('', '0')	--NONE/All member
	BEGIN
		SELECT @InputList = STUFF((SELECT ',' + CAST(ci.custid AS VARCHAR)
									FROM custInfo ci WITH (NOLOCK)
									CROSS APPLY (SELECT TOP 1 1 AS val FROM STRING_SPLIT(@InputList,',')
												 WHERE TRIM(value)<>''
												 AND CAST(TRIM(value) AS INT)=ci.custid) t
									WHERE (recommend = @CustID AND @RoleId = 2)
										OR (mrecommend = @CustID AND @RoleId = 3)
										OR (srecommend = @CustID AND @RoleId = 4)
										AND roleid=1
									FOR XML PATH (''))
									,1,1,''
								)
	END

	IF @WatchList NOT IN ('', '0') AND @RoleId = 2 --NONE/All members
	BEGIN
		--Exclude: Not be agent's member
		SELECT @WatchList = STUFF((SELECT ',' + CAST(ci.custid AS VARCHAR)
									FROM custInfo ci WITH (NOLOCK)
									CROSS APPLY (SELECT TOP 1 1 AS val FROM STRING_SPLIT(@WatchList,',')
												 WHERE TRIM(value)<>''
												 AND CAST(TRIM(value) AS INT)=ci.custid) t
									WHERE recommend=@CustID AND roleid=1
									FOR XML PATH (''))
									,1,1,''
								)
	END

	IF ISNULL(@InputList,'')='' AND ISNULL(@WatchList,'')=''
	BEGIN
		SELECT @ErrCode=90021
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Please enter Member username(s) or select Member(s)' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90021,@Language)    
												 END 
		RETURN
	END

	--Not input filter name
	IF @FilterName=''
	BEGIN
		SELECT @ErrCode=90023
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Please enter filter name' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90023,@Language)    
												 END 
		RETURN
	END

	--Exists Filter
	IF EXISTS (SELECT 1 FROM Cust_LastBetFilter WITH (NOLOCK) WHERE CustID=@CustID AND SubAccId=@SubAccId AND FilterName=@FilterName)
	BEGIN
		SELECT @ErrCode=90020
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Filter name already exists.' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90020,@Language)    
												 END 
		RETURN
	END

	--Check if enable Telegram notification for more than 3 filters 
	IF @IsNotify = 1 
		AND EXISTS (
			SELECT COUNT(1) AS NotifyCount
			FROM Cust_LastBetFilter WITH (NOLOCK)
			WHERE CustID = @CustID AND SubAccID = @SubAccId AND IsNotify = 1
			HAVING COUNT(1) > 2
		)
	BEGIN
		SELECT @ErrCode = 90027
				,@ErrMsg = CASE @Language WHEN 'E' THEN 'The number of notification filters has exceeded the maximum limit of 3.' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90027,@Language)    
												 END 
		RETURN
	END

	SELECT @xml_SportList=CAST(@SporttypeList AS xml)

	SELECT @FilterValue = CONVERT(VARCHAR(MAX),
									(SELECT	@Bettype	 AS '@b'
											,@Stake		 AS '@st'
											,@InputList	 AS '@members'
											,@WatchList  AS '@wl'
											,@IsWatchList AS '@iWL'
											,@IsLive	 AS '@iL'
											,(SELECT t.s.value('@s','VARCHAR(MAX)') AS '@s'
													,t.s.value('@l','VARCHAR(MAX)')	AS '@l'
													--,t.s.value('@m','INT')			AS '@m'
													--,t.s.value('@h','INT')			AS '@h'
													--,t.s.value('@a','INT')			AS '@a'
													--,t.s.value('@iN','BIT')			AS '@iN'
											  FROM @xml_SportList.nodes('SportList/Sport') t(s)
											  FOR XML PATH('Sport'), TYPE)
									FOR XML PATH('Filter'), TYPE))

	BEGIN TRY
		IF @IsDefault=1
		AND EXISTS (SELECT 1 FROM Cust_LastBetFilter WITH (NOLOCK) WHERE CustID=@CustID AND SubAccId=@SubAccId AND IsDefault=1)
		BEGIN
			UPDATE Cust_LastBetFilter WITH (ROWLOCK, UPDLOCK)
			SET  IsDefault=0
				,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE CustID=@CustID AND SubAccId=@SubAccId AND IsDefault=1
		END

		INSERT INTO Cust_LastBetFilter ([CustID], [SubAccID], [FilterName], [FilterValue], [IsDefault], [IsNotify],[RepUpdateTime])
		SELECT @CustID, @SubAccId, @FilterName, @FilterValue, @IsDefault, @IsNotify,dbo.f_GetDateTime2()
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	--Write Log:
	SELECT @logSpData = (
		SELECT @CustID AS CustID
			, @SubAccId AS SubAccId
			, @FilterName AS FilterName
			, @FilterValue AS FilterValue
			, @IsDefault AS IsDefault
			, @IsNotify AS IsNotify
			, COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FOR XML RAW('Root'))

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 6103,
					@TrackingValue = @LogSPData,
					@duration = @Duration
END
GO