/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelUsedCredit_Ag]
	@UplineID		INT		-- SMA Input
    , @ServiceType	TINYINT = 0
AS
/*	Created by: 
	Task: Get Used Credit for agent 
	DB: DBCUST.CustDB 
	Original: \account\hAgentUsedCredit.asp

	Revisions: 
		- 20210505@Tina: Lock account & indirect close account [redmine: #148600]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 7 [redmine: #233474]

	exec Acc_CustomerSelUsedCredit_Ag @agentID=187900621
	exec Acc_CustomerSelUsedCredit_Ag @agentID=187900621 , @superID = 179806625
	exec Acc_CustomerSelUsedCredit_Ag @agentID=187900621 , @masterID = 179806626
	exec Acc_CustomerSelUsedCredit_Ag @agentID=0 , @superID = 0 , @masterID = 0
*/
BEGIN
SET NOCOUNT ON

DECLARE @IsDeposit BIT = 0 , @IsDirectMember INT = 0

IF EXISTS (SELECT 1 FROM custInfo i WITH (NOLOCK) WHERE i.custid = @UplineID AND i.roleid = 2)
BEGIN
	SELECT @IsDeposit = 1
	FROM Customer c WITH (NOLOCK)
		INNER JOIN Dep_CustSuper DS WITH (NOLOCK) ON c.srecommend = DS.custid
	WHERE C.custid = @UplineID

END
-- Get Used Credit For Deposit
IF @IsDeposit = 1
BEGIN
	SELECT c.username, c.firstname, c.lastname, ci.credit, ci.closed
	FROM customer c WITH (NOLOCK)
		inner join custInfo ci WITH (NOLOCK) on c.custid = ci.custid
	WHERE c.recommend = @UplineID
		AND c.roleid = 1
	ORDER BY
		ci.closed ASC, 
		c.Username
END
-- Get Used Credit For Credit
ELSE
BEGIN
	SELECT TOP 1 @IsDirectMember = i.recommend FROM Custinfo i WITH (NOLOCK) WHERE i.srecommend = @UplineID AND i.recommend = -4 AND i.roleid = 1
	SELECT TOP 1 @IsDirectMember = i.recommend FROM Custinfo i WITH (NOLOCK) WHERE i.mrecommend = @UplineID AND i.recommend = -3 AND i.roleid = 1
	SELECT TOP 1 @IsDirectMember = i.recommend FROM Custinfo i WITH (NOLOCK) WHERE i.recommend = @UplineID  AND i.recommend NOT IN (-3,-4) AND i.roleid = 1


	IF @IsDirectMember  = -4
	BEGIN
		SELECT c.username, c.firstname, c.lastname, ci.credit, CASE WHEN cps.CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END closed
		FROM customer c WITH (NOLOCK)
			INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = c.custid
		WHERE ci.roleid = 1 AND c.srecommend = @UplineID AND c.recommend = -4	
		ORDER BY
			CASE WHEN cps.CloseInfo > 0 THEN 1 ELSE 0 END ASC, 
			c.Username
	END
	ELSE IF @IsDirectMember  = -3
	BEGIN
		SELECT c.username, c.firstname, c.lastname, ci.credit, CASE WHEN cps.CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END closed
		FROM customer c WITH (NOLOCK)
			INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = c.custid
		WHERE ci.roleid = 1 AND c.mrecommend = @UplineID AND c.recommend = -3	
		ORDER BY
			CASE WHEN cps.CloseInfo > 0 THEN 1 ELSE 0 END ASC, 
			c.Username
	END
	ELSE IF @IsDirectMember  NOT IN (-3,-4)
	BEGIN
		IF @ServiceType = 0 -- get Credit Member 
		BEGIN
			SELECT c.username, c.firstname, c.lastname, ci.credit, CASE WHEN cps.CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END closed
			FROM customer c WITH (NOLOCK)
				INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
				INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = c.custid
			WHERE ci.roleid = 1 AND c.recommend = @UplineID AND cps.ServiceType = @ServiceType
			ORDER BY
				CASE WHEN cps.CloseInfo > 0 THEN 1 ELSE 0 END ASC, 
				c.Username
		END
		IF @ServiceType = 1 -- get Cash Member 
		BEGIN
			SELECT c.username, c.firstname, c.lastname, ISNULL(cac.AccumCreditReturn , 0) AS credit, CASE WHEN cps.CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END closed
			FROM customer c WITH (NOLOCK)
				LEFT JOIN CashAccumCredit cac WITH (NOLOCK) ON c.custid = cac.CustID
				INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = c.custid				
			WHERE c.roleid = 1 AND c.recommend = @UplineID AND cps.ServiceType = @ServiceType
			ORDER BY
				CASE WHEN cps.CloseInfo > 0 THEN 1 ELSE 0 END ASC, 
				c.Username
		END

		
	END

END

END
GO
