/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_OnUser_ForceKickedout]
	@CustID INT,
	@roleid TINYINT,
	@SubAccID INT = 0, 
	@Log NVARCHAR(500) = '' OUTPUT
AS
/*
	Created: 20190612@Johnson
	Task : force kick out user after upline change pwd [RedmineID: #114566]
	DB: DBONUSER/ON_USER
	Original:

	Revisions:
		- 20190612@Johnson: initial sp [redmine:#114566]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	IF @roleid = 1
	BEGIN
		DELETE FROM dbo.ON_USER with (rowlock)
		WHERE custid = @custid
		
		-- delete use nickname login user
		DELETE FROM dbo.tmp_Username2 with (rowlock)
		WHERE custid = @custid
	END
	ELSE 
	BEGIN
		UPDATE dbo.on_user_agent WITH (ROWLOCK, UPDLOCK)
		SET iskickedout = 1,
			kickOutReason = 1
		WHERE custid = @CustID AND subaccid = @SubAccID
	END
END
GO