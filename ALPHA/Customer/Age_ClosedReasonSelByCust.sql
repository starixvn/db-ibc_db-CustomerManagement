/*<info serverAlias="DBACC-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ClosedReasonSelByCust]
	@custid int,
	@RoleID TINYINT
/*
	Created: 20230925@Tacy
	Task: Get Closed Reason and Protection Mode info
	DB: DBACC/bodb02

	Revisions:
		- 20230925@Tacy: Create SP [Redmine: #194274]
*/
AS
BEGIN
    SET NOCOUNT ON

	IF @roleid=1
		SELECT ISNULL(ClosedReason,0) AS ClosedReason, NULL AS IsProtectedMode
		FROM CustLoginInfo_Member WITH(NOLOCK) 
		WHERE Custid = @custid
	ELSE
		SELECT	ISNULL(ClosedReason,0) AS ClosedReason, 
				ISNULL(IsProtectedMode,0) AS IsProtectedMode
		FROM CustLoginInfo WITH(NOLOCK) 
		WHERE Custid = @custid	
END
GO