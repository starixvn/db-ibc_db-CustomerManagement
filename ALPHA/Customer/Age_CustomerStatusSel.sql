 /*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02" executers="bodbdownlineNet,bodbdownlineNetView" viewers="" isFunction="0"></info>*/
 ALTER PROCEDURE [dbo].[Age_CustomerStatusSel]
	@custid INT,
	@subAccID INT= 0,
	@isActive BIT = 0 OUTPUT,
	@Locked TINYINT = 0 OUTPUT	
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
			- 20210408@Tina: Lock account & indirect close account [redmine: #148600]

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
			SELECT @isActive = CASE WHEN cs.CloseInfo > 0 OR ci.[Enabled] = 0 THEN 0 ELSE 1 END
			FROM CustInfo ci WITH(NOLOCK)
				INNER JOIN CustProductStatus cs WITH (NOLOCK) ON ci.custid = cs.CustID
			WHERE ci.custid = @custid
		END
	END
	ELSE
	BEGIN
		SELECT @isActive = CASE WHEN cs.CloseInfo > 0 OR ci.[Enabled] = 0 THEN 0 ELSE 1 END
		FROM CustInfo ci WITH(NOLOCK)
			INNER JOIN CustProductStatus cs WITH (NOLOCK) ON ci.custid = cs.CustID
		WHERE ci.custid = @custid	
		
		SELECT @Locked = Locked
		FROM CustProductStatus ps WITH (NOLOCK)	
		WHERE custid = @custid
	END
	
	SELECT @isActive = ISNULL(@isActive,0)
	SET @Locked = ISNULL(@Locked,0)
END

GO
