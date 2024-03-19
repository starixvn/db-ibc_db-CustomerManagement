/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,wsv_nap" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermSelGroupByUsername]
	@username VARCHAR(30)
AS
/*	Creator: Percy
	Date: 2016-01-13
	Task: Select Group Headerline by Username
	DB: DBAGE/bodb02

	Revisions:		
		- 20160113@Percy: Credit term change request [Redmine: #50431]
	Param's Explanation:
		- @groupID IS NULL : not found group

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @groupID INT,
			@custID INT

	SELECT
		@groupID = ca.groupID,
		@custId = ca.custid
	FROM customer c with (nolock)
		inner join custAccount ca with (nolock) on c.custid = ca.custid
	WHERE c.username = @username

	SELECT 	@custID AS CustID,
			@groupID AS GroupID
END
GO