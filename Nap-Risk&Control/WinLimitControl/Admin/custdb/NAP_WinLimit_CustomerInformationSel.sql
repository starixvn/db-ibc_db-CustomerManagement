/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/ 

ALTER PROCEDURE [dbo].[NAP_WinLimit_CustomerInformationSel] 
		@CustId INT
AS
	
/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2
	DB: DBCUST/CustDB

	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20250110@Tacy: Offer direct member for super/master [Redmine: #215809]

	Example: 
		EXEC [NAP_WinLimit_CustomerInformationSel] @CustId = 807023
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @srecommend INT
		,@mrecommend INT
		,@recommend INT
     
    -- Upline information
    SELECT @srecommend = srecommend
		,@mrecommend = mrecommend
		,@recommend = recommend
	FROM dbo.customer WITH (NOLOCK)
	WHERE custid = @CustId;
   
    -- Query
    SELECT	c.custid,
			c.username,
			c.roleid,
			c.site AS SiteName,
			CASE
				WHEN s.isDeposit = 0 THEN 1
				ELSE 0
			END IsCreditUser
	FROM Customer c WITH (NOLOCK)
	INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
	WHERE CustID IN (@srecommend, @mrecommend, @recommend, @CustId)
	ORDER BY roleid;
END
GO