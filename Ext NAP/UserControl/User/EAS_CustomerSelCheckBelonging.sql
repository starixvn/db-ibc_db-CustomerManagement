/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelCheckBelonging]
	@GroupName		VARCHAR(100) = '',	
	@custid			INT = 0,
	@username 		VARCHAR(30)='',
	@IsBelonging	BIT = 0 OUTPUT
AS
	/*
		Created: 20240805@Tacy		
		Task: check belonging of customer on external group
		DB: DBCUST/CustDB
		
		Revisions:
			- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		
		Parameter's Explanations:
			- @GroupName: main group of admin belong
			- @custid: custid of SMA need to check belonging
			- @username: username of SMA
	*/ 
BEGIN	
	SET NOCOUNT ON
	
	SET @IsBelonging = 0
	
	IF (ISNULL(@custid,0)=0 AND ISNULL(@username,'')='')
		RETURN;
		
	IF ISNULL(@custid,0)=0	
		SELECT @custid = custid FROM customer WITH(NOLOCK) WHERE username = @username
	
	DECLARE @srecommend INT 
	
	SELECT @srecommend = srecommend
	FROM dbo.customer WITH(NOLOCK) 
	WHERE custid = @custid
	
	-- check belong to group for SMA
	IF EXISTS (SELECT 1 FROM Acc_CustGroup WITH(NOLOCK) WHERE CustID = @srecommend AND GroupName = @GroupName)
	BEGIN
		SELECT @IsBelonging = 1
	END	
END	
GO