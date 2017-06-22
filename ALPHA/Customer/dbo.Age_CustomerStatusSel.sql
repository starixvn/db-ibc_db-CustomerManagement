 ALTER PROCEDURE [dbo].[Age_CustomerStatusSel]
	@custid INT,
	@subAccID INT= 0,
	@isActive BIT = 0 OUTPUT	
AS
	/*
		Created: Johnson
		Date: 2015-02-27
		Task: check status of account(sub account& main account login)
				 at currently is closed or not
		DB: DBCUST.CustDB
		
		Revisions:
			- 20150303@Johnson: check status of sub-account by main account also
			- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]

		Parameter's Explanation:
			- @custid: id of main account
			- @subAccID: id of sub-account
	*/
BEGIN
	SET NOCOUNT ON
	
	-- SELECT @isActive  = 1
	-- return 
	
	
	--check sub-account status
	IF @subAccID <> 0
	BEGIN
		SELECT @isActive =  CASE WHEN closed = 1 THEN 0 ELSE 1 END
		FROM CustSub WITH(NOLOCK)
		WHERE subAccID = @SubAccID AND custid = @custid
		
		--check status with main account
		IF @isActive = 1
		BEGIN
			--get sub-account status by main account status
			SELECT @isActive = CASE WHEN closed = 1 OR Enabled = 0 THEN 0 ELSE 1 END
			FROM CustInfo WITH(NOLOCK)
			WHERE custid = @custid
		END
	END
	ELSE
	BEGIN
		SELECT @isActive = CASE WHEN closed = 1 OR Enabled = 0 THEN 0 ELSE 1 END
		FROM CustInfo WITH(NOLOCK)
		WHERE custid = @custid		
	END
	
	SELECT @isActive = ISNULL(@isActive,0)
END

GO
GRANT EXECUTE ON [dbo].[Age_CustomerStatusSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerStatusSel] TO [bodbDownlineNetView] AS [dbo]