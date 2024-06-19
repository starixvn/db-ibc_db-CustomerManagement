/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerDateLimitSel] 
	@userName VARCHAR(30) = ''
	,@UserID INT
	,@PageSize INT = 0
	,@PageIndex INT = 0
	,@TotalRecords INT = 0 OUTPUT
AS
/*
	Created: 20180429@Razor
	DB: DBCUST-CUSTDB
	Task: 

	Revisions:
		- 20180429@Razor: init - [Readmine: #96025]
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		- 20240529@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		
	Param's Explanation:	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RowStart INT
		,@RowEnd INT
	DECLARE @temp TABLE (
		CustId INT
		,UserName NVARCHAR(100)
		,LimitDays INT
		,MinDate DATETIME
		,RowNum INT
		)

	SELECT @PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	SELECT @userName = ISNULL(@userName, '')

	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	--get deny site
	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	SELECT siteid , site,SpecialGroup 
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser( @Userid)
		
	--get deny currency
	INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
	SELECT exchangeID, Currency, OfferSite 
	FROM NAP_UserControl.dbo.f_GetDeniedCurrencyByUser(@Userid)

	INSERT INTO @temp (
		CustId
		,UserName
		,LimitDays
		,MinDate
		,RowNum
		)
	SELECT c.custId
		,c.UserName
		,l.LimitDays
		,l.MinDate
		,ROW_NUMBER() OVER (
			ORDER BY c.UserName
			) AS RowNum
	FROM dbo.Age_CustDateLimit l WITH (NOLOCK)
		INNER JOIN [dbo].[Customer] c WITH (NOLOCK) ON c.custId = l.custId
	WHERE c.UserName LIKE '%' + @userName + '%'
		AND c.Site NOT IN (SELECT Site FROM @tmp)
		AND c.currency NOT IN (SELECT exchangeID FROM @tmpExchange)

	SELECT UserName, CustId, MinDate, LimitDays
	FROM @temp
	WHERE RowNum BETWEEN @RowStart AND @RowEnd

	SELECT @TotalRecords = COUNT(CustId)
	FROM @temp
END
GO


