/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_WhiteLabel_SelCustInfo] 
	 @CustID INT
AS
/*
	Created: Tacy
	Task : Get User Information
	DB: DBCUST.CustDB

	Revisions:
		- 20220911@Tacy: Create SP [RedmineID: #209807]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrCode		INT				= 0	
			,@ErrMsg		NVARCHAR(4000)	= '' 

	EXEC Acc_WhiteLabelSetting_Check
		@Username		= @CustID
		,@CheckCustId	= 1
		,@ErrCode		= @ErrCode	OUTPUT
		,@ErrMsg		= @ErrMsg	OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	DECLARE @CustHeadlineID INT

	SELECT @CustHeadlineID = CASE WHEN cda.CustID IS NOT NULL THEN cda.CustID ELSE c.srecommend END
	FROM Customer c WITH (NOLOCK)
	OUTER APPLY (SELECT TOP 1 cda.CustID
				 FROM CustDirectAccount cda WITH (NOLOCK)
				 WHERE cda.CustID in (c.custid, c.mrecommend, c.srecommend, c.recommend)
				) cda
	WHERE c.custid=@CustID
	
	SELECT c.custid, c.username, c.site
		, a.username [Agent] 
		, m.username [Master] 
		, s.username [Super]
		, ISNULL(Headline.username,'') AS Headline	
	FROM Customer c with (nolock)
		LEFT JOIN Customer a with (nolock) ON a.custid=c.recommend
		LEFT JOIN Customer m with (nolock) ON m.custid=c.mrecommend
		LEFT JOIN Customer s with (nolock) ON s.custid=c.srecommend
		LEFT JOIN custaccount AS GroupHeadline WITH (NOLOCK) ON GroupHeadline.CUSTID = @CustHeadlineID AND GroupHeadline.GroupID > 0
		OUTER APPLY (SELECT C.username
					 FROM dbo.custaccount ca WITH (NOLOCK)
						INNER JOIN Customer C ON CA.custid = C.custid 
					 WHERE ca.GroupID = GroupHeadline.GroupID AND ca.IsGroupHeadLine = 1
					) AS Headline
	WHERE c.custid = @CustID
END
GO