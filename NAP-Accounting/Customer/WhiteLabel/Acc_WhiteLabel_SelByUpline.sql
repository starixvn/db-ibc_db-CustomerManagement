/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_WhiteLabel_SelByUpline
	-- Add the parameters for the stored procedure here
	 @Usernames	VARCHAR(MAX)	
AS
/*
	Created: Tacy
	Task: CreditTerm - WhiteLabel list by uplines
	DB: DBCUST-CustDB

	Revisions:
		- 20241119@Tacy: Create SP [Redmine: #209807]

	Param's Explanation:

*/
BEGIN 
	SET NOCOUNT ON;

	IF ISNULL(@Usernames,'')=''
		RETURN

	CREATE TABLE #tmpUpline 
    (
        CustID		INT PRIMARY KEY
      , Username	VARCHAR(30)
    )

	DECLARE @today DATETIME
	
	SELECT  @today = CONVERT(DATE, GETDATE())

	INSERT INTO #tmpUpline(CustID, Username)
	SELECT DISTINCT c.custid, c.username
	FROM Customer c WITH (NOLOCK)
		CROSS APPLY (SELECT TRIM(ss.value) AS headline
					 FROM STRING_SPLIT(@Usernames,',') ss
					 WHERE TRIM(ss.value)=c.username) t

	SELECT wi.CustID, c.username
			, u.CustID UplineID
			, u.Username Upline
	FROM WhiteLabelInfo wi WITH (NOLOCK)
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=wi.CustID
	CROSS APPLY (SELECT TOP 1 1 AS val
				 FROM WhiteLabelSetting wls WITH (NOLOCK)
				 WHERE wls.CustID=c.CustID
				 AND wls.ToDate > @today) wls
	CROSS APPLY (SELECT t.CustID, t.Username 
				 FROM #tmpUpline t
				 WHERE t.CustID IN (c.custid, c.recommend, c.mrecommend, c.srecommend)) u
	ORDER BY c.username
END
GO