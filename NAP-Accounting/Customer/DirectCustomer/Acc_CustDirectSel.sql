/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE Acc_CustDirectSel
(
	@CustID INT
)
AS
/*
	Created: 20170419@Helen
	Task: Add Extra information for Direct Accounts, for NAP only - [Redmine:72339]
	DB: DBAGE/BODB02

	Revisions:
		- 20170515@Helen:  Add Extra information for Direct Accounts, for NAP only Change Request - [Redmine:72339]
		- 20171026@Elodie:  Add MaxLoss of headline - [Redmine:82892]
*/
BEGIN
	DECLARE @IsGroupHeadline BIT
	SELECT @IsGroupHeadline = IsGroupHeadLine FROM dbo.custAccount WITH (NOLOCK) WHERE custid = @CustID

	SELECT 
		cda.CustID AS CustID
		, ISNULL(cr.Username,'') AS  CreatedBy
		, ISNULL(cda.ProcessedBy,'') AS ProcessedBy
		, ISNULL(cda.Boss,'') AS Boss
		, ISNULL(cda.RequestedBy,'') AS RequestBy
		, ISNULL(cda.ApprovedBy,'') AS ApprovedBy
		, ISNULL(c.mobilephone,'') AS Mobilephone
		, ls.MaxLoss AS MaxLoss
		, hs.MaxLoss AS MaxLossHeadline
		, CASE WHEN e.ExchangeID = 20 THEN 'UUS' ELSE e.Currency END AS Currency
		, ISNULL(@IsGroupHeadline,0) AS IsGroupHeadline				
	FROM dbo.CustDirectAccount cda WITH (NOLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON cda.CustID = c.CustID
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON e.ExchangeID = c.Currency
		LEFT JOIN dbo.Customer cr WITH (NOLOCK) ON c.creator = cr.CustID
		LEFT JOIN custaccount AS GroupHeadline WITH (NOLOCK) ON GroupHeadline.CUSTID = @CustID AND GroupHeadline.GroupID > 0 
		LEFT JOIN bodb_Age.dbo.LimitLoss_HeadlineSetting hs ON GroupHeadline.groupID = hs.GroupHeadlineID
		LEFT JOIN bodb_Age.dbo.LimitLoss_Setting ls WITH (NOLOCK) ON cda.Custid = ls.CustID
	WHERE cda.Custid = @CustID
	
END
GO