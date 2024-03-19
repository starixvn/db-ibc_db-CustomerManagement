/*<info serverAlias="DBCUST-CustDB" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserCheckBelonging]
	@GroupName		VARCHAR(100) = '',	
	@UserID			INT = 0,
	@custid			INT = 0,
	@username 		VARCHAR(30)='',
	@IsBelonging	BIT = 0 OUTPUT
AS
	/*
		Created: 20201116@Johnson		
		Task: check belonging of user on external group
		DB: DBCUST/CustDB
		
		Revisions:
			- 20201116@Johnson: initial sp [Redmine: #126459]
		
		Parameter's Explanations:
			- @GroupName: main group of admin belong
			- @userid: admin login
			- @custid: custid of SMA need to check belonging
			- @username: username of SMA
	*/ 
BEGIN	
	SET NOCOUNT ON
	
	SET @IsBelonging = 0
	
	DECLARE @GroupID INT 
	
	SELECT @GroupID = GroupID 
	FROM NAP_UserControl.dbo.eaUserInfo WITH(NOLOCK)
	WHERE userid = @userid	
	
	IF EXISTS(SELECT 1
		FROM NAP_UserControl.dbo.eaGroup WITH(NOLOCK)
		WHERE GroupName = @GroupName 
			AND (GroupID = @GroupID OR ParentID = @GroupID)
	)
	SELECT @IsBelonging = 1	
	
	
	IF (ISNULL(@custid,0)=0 AND ISNULL(@username,'')='')
		RETURN;
		
	IF ISNULL(@custid,0)=0	
		SELECT @custid = custid FROM customer WITH(NOLOCK) WHERE username = @username
	
	DECLARE @srecommend INT 
	
	SELECT @srecommend = srecommend
	FROM dbo.customer WITH(NOLOCK) 
	WHERE custid = @custid
	
	-- check belong to group for SMA
	IF NOT EXISTS (SELECT 1 FROM Acc_CustGroup WITH(NOLOCK) WHERE CustID = @srecommend AND GroupName = @GroupName)
	BEGIN
		SELECT @IsBelonging = 0
	END	
END	
GO

