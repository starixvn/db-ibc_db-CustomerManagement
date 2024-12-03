/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_MaxMemberLimitBySuperUpd]
	@SuperNames		NVARCHAR(MAX),
	@MaxMemberLimit	INT,
	@UserID			INT,
	@DeniedList		NVARCHAR(MAX)=NULL,
	@Ip				VARCHAR(50),
	@Remark			NVARCHAR(300) = NULL,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created by: 20180924@Phillip
	Task: Limit max members creation per Super: #101994
	DB: DBCUST/CustDB
	Original:	
	
	Revisions:
		- 20180924@Phillip: Init
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20240122@Johnson: check permission for 777 [redmineID: #197160]	
		- 20240419@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20241125@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
	Param's Explanation:
	- @SuperName: Searched Super's name
	- @MaxMemberLimit: Max Member Limit
	- @UserID: User Id
	- @Ip: User's IP
	- @Remark: Remark
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @startRun datetime,
			@endRun datetime,
			@duration INT
    SET @startRun = GETDATE()
    
	DECLARE @resultTbl TABLE(
		CustId		INT,
		UserName	NVARCHAR(30),
		Site		VARCHAR(30),
		Currency	INT,
		ErrCode		INT,
		ErrMessage	VARCHAR(200)
	)
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)
	
	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmp (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	INSERT INTO @resultTbl(UserName)
    SELECT DISTINCT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@SuperNames,',') WHERE value <> ''
	
	DECLARE @updatedTbl TABLE(
		CustId				INT,
		MaxMemberLimit_Old	INT,
		Remark_Old			NVARCHAR(300),
		MaxMemberLimit		INT,
		Remark				NVARCHAR(300),
		Processed			BIT
	)
	
	
	UPDATE rs
	SET rs.CustId		= c.CustId, 
		rs.Site			= c.Site,
		rs.Currency		= c.currency,
		rs.ErrCode		= CASE WHEN c.CustId IS NULL THEN 1 ELSE 0 END,
		rs.ErrMessage	= CASE WHEN c.CustId IS NULL THEN 'Invalid account.' ELSE '' END
	FROM @resultTbl rs 
	LEFT OUTER JOIN dbo.Customer c 
		ON	rs.UserName	= c.UserName 
			AND c.roleid = 4
			AND c.Custid NOT IN (
				SELECT CustId
				FROM dbo.Acc_CustDirect WITH (NOLOCK)
			)
			AND c.CustId NOT IN (
				SELECT CustId
				FROM dbo.Dep_CustSuper WITH (NOLOCK)
			)
	
	UPDATE rs
	SET	rs.ErrCode = 2, rs.ErrMessage = 'There is no change to be updated.'
	FROM @resultTbl rs INNER JOIN dbo.CustSuper cs ON rs.CustId = cs.CustId
	WHERE	ISNULL(cs.MaxMember, 0)				= ISNULL(@MaxMemberLimit, 0)
			AND ISNULL(cs.MaxMemberRemark, '')	= ISNULL(@Remark, '')
	
	DECLARE @strCust VARCHAR(MAX) = ''
	
	SELECT @strCust = @strCust + ',' + CAST(username as VARCHAR(50)) 
	FROM @resultTbl
	WHERE Site IN (SELECT site FROM @tmp)
		OR Currency IN (SELECT exchangeID FROM @tmpExchange)

	SELECT @strCust = STUFF(@strCust,1,1,'')
	
	IF @strCust <> ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg ='You don''t have permission to access: ' + @strCust
		RETURN
	END
	
	UPDATE cs WITH (ROWLOCK, UPDLOCK)
	SET cs.MaxMember		= @MaxMemberLimit,
		cs.MaxMemberRemark	= @Remark,
		RepUpdateTime 		= dbo.f_GetDateTime2()
	OUTPUT 
		deleted.CustId, 
		deleted.MaxMember		AS MaxMemberLimit_Old, 
		deleted.MaxMemberRemark	AS Remark_Old, 
		inserted.MaxMember		AS MaxMemberLimit, 
		inserted.MaxMemberRemark AS Remark,
		0 AS Processed
	INTO @updatedTbl
	FROM dbo.CustSuper cs INNER JOIN @resultTbl rs 
		ON cs.CustId = rs.CustId AND rs.ErrCode = 0
	WHERE	ISNULL(cs.MaxMember, 0)				<> ISNULL(@MaxMemberLimit, 0)
			OR ISNULL(cs.MaxMemberRemark, '')	<> ISNULL(@Remark, '')
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND, @startRun, @endRun)
	WHILE (SELECT Count(*) FROM @updatedTbl WHERE Processed = 0) > 0
	BEGIN
		DECLARE @CustId				INT,
				@MaxMemberLimit_Old	INT,
				@Remark_Old			NVARCHAR(300),
				@MaxMemberLimit_New	INT,
				@Remark_New			NVARCHAR(300),
				@TrackingValueNew	NVARCHAR(MAX),
				@TrackingValueOld	NVARCHAR(MAX)
		
		SELECT 	TOP 1
				@CustId = CustId,
				@MaxMemberLimit_Old = MaxMemberLimit_Old,
				@Remark_Old = Remark_Old,
				@MaxMemberLimit_New = MaxMemberLimit,
				@Remark_New = Remark
		FROM	@updatedTbl
		WHERE	Processed = 0
		
		
		BEGIN TRY
			SELECT @TrackingValueOld = '<Acc_MaxMemberLimitBySuperUpd MaxMembers="'+ COALESCE(CASE WHEN @MaxMemberLimit_Old = -1 THEN 'Unlimited' ELSE CAST(@MaxMemberLimit_Old AS VARCHAR(50)) END, SPACE(1)) + '" ' +
				'IP="'+ COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
				'Remark="'+ dbo.f_EncodeXMLValue(COALESCE(@Remark_Old, SPACE(1))) + '" />'
			SELECT @TrackingValueNew = '<Acc_MaxMemberLimitBySuperUpd MaxMembers="'+ COALESCE(CASE WHEN @MaxMemberLimit_New = -1 THEN 'Unlimited' ELSE CAST(@MaxMemberLimit_New AS VARCHAR(50)) END, SPACE(1)) + '" ' +
				'IP="'+ COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
				'Remark="'+ dbo.f_EncodeXMLValue(COALESCE(@Remark_New, SPACE(1))) + '" />'
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 678,
					@TrackingValue = @TrackingValueNew,
					@TrackingValue2 = @TrackingValueOld,
					@duration = @duration
		END TRY
		BEGIN CATCH
			SELECT @TrackingValueOld = '<Acc_MaxMemberLimitBySuperUpd MaxMembers="'+ COALESCE(CASE WHEN @MaxMemberLimit_Old = -1 THEN 'Unlimited' ELSE CAST(@MaxMemberLimit_Old AS VARCHAR(50)) END, SPACE(1)) + '" ' +
				'IP="'+ COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
				'Remark="'+ dbo.f_EncodeXMLValue(COALESCE(@Remark_Old, SPACE(1))) + '" ' +
				'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1)) + '" />'
			SELECT @TrackingValueNew = '<Acc_MaxMemberLimitBySuperUpd MaxMembers="'+ COALESCE(CASE WHEN @MaxMemberLimit_New = -1 THEN 'Unlimited' ELSE CAST(@MaxMemberLimit_New AS VARCHAR(50)) END, SPACE(1)) + '" ' +
				'IP="'+ COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
				'Remark="'+ dbo.f_EncodeXMLValue(COALESCE(@Remark_New, SPACE(1))) + '" ' +
				'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1)) + '" />'
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 678,
					@TrackingValue = @TrackingValueNew,
					@TrackingValue2 = @TrackingValueOld,
					@duration = @duration
		END CATCH
				
		UPDATE @updatedTbl SET Processed = 1 WHERE CustId = @CustId
	END
	
	SELECT CustId, UserName, ErrCode, ErrMessage FROM @resultTbl
END
