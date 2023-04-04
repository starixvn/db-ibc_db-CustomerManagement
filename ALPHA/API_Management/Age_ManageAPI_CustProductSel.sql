/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_CustProductSel]
	-- Add the parameters for the stored procedure here
	  @CustID	INT=NULL,
	  @UserName	VARCHAR(100)=NULL,
	  @SettingStatus TINYINT = 0
AS
/*
	Task : Alpha - API Management - Support data through API
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20221205@Tacy: Create SP [Redmine: #171247]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @CustID IS NULL AND @UserName IS NULL RETURN

	SELECT ci.custid, ci.roleid, c.site, ci.currency
	FROM custInfo ci WITH (NOLOCK)
		INNER JOIN Customer c WITH(NOLOCK) ON c.custid=ci.custid
	WHERE ci.username=@UserName
		OR ci.custid=@CustID

	IF @CustID<>0
	BEGIN
		DECLARE @roleid TINYINT

		CREATE TABLE #CustSetting_StatusSelect (
				RealProductID		TINYINT,
				ProductID			TINYINT,
				SportType			SMALLINT,
				Bettype				SMALLINT,
				IsSync				BIT DEFAULT(0),
				isHidden			BIT DEFAULT(0),
				isDisabled			BIT DEFAULT(0),
				isSyncedUpline		BIT DEFAULT(0),
				isHiddenUpline		BIT DEFAULT(0),
				isDisabledUpline	BIT DEFAULT(0),
				HasDownline			BIT DEFAULT(1)
		)

		SELECT @roleid=roleid
		FROM custInfo WITH (NOLOCK)
		WHERE custid=@CustID

		--Non DSC Products
		INSERT INTO #CustSetting_StatusSelect(RealProductID,ProductID,SportType,BetType,isHidden)
		SELECT 8,8,202,1501, HideKeno
		FROM custInfo WITH(NOLOCK)
		WHERE custid=@CustID


		--DSC Products
		INSERT INTO #CustSetting_StatusSelect(RealProductID,ProductID,SportType,BetType,IsSync,isHidden,isDisabled,isSyncedUpline,isHiddenUpline,isDisabledUpline,HasDownline)
		EXEC Acc_CustSetting_StatusSelect @CustID = @custid, @roleid = @roleid, @SettingStatus = @SettingStatus


		SELECT *
		FROM #CustSetting_StatusSelect
		ORDER BY RealProductID
	END
END
GO