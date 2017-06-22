 ALTER PROCEDURE [dbo].[Acc_CustomerSelAutoTransferAgent]
	@username	VARCHAR(50) = '',
	@status		VARCHAR(30) = '',
	@TotalRows	INT = 0 OUTPUT,
	@PageSize	INT = 50,
	@PageIndex	INT = 1
AS
	/*
		Created: Johnson
		Date: 2014-09-23
		Task: Select automate transfer list agent
		DB: DBTXN/CustDB
		
		Revisions:
		
		Parameter's Explanation:
			-@username = '': get all agents
			-@status = '' : get all status
	*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @RowStart INT, @RowEnd INT  
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT ci.custid
		,ci.username 
		,c.transferType
		,CASE ci.roleid WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' END as role
		,CASE WHEN ci.roleid IN (2,3) THEN ISNULL(super.username,'') ELSE '' END as super
		,CASE WHEN ci.roleid = 2 THEN ISNULL(master.username,'') ELSE '' END as master
		,c.status
		,c.lastTransfer	
	INTO #tmp	
	FROM Acc_ClearBalanceList c WITH(NOLOCK) 
		INNER JOIN Customer ci WITH(NOLOCK) ON c.custid = ci.custid
		LEFT JOIN customer super WITH(NOLOCK) ON ci.srecommend = super.custid
		LEFT JOIN customer master WITH(NOLOCK) ON ci.mrecommend = master.custid
	WHERE ci.username = ISNULL(NULLIF(@username,''),ci.username)
		AND c.status = ISNULL(NULLIF(@status,''),c.status)
	
	SELECT @TotalRows = @@ROWCOUNT
	
	SELECT custid
			,username
			,transferType
			,role
			,super
			,master
			,status
			,lastTransfer
	FROM (
		SELECT ROW_NUMBER() OVER (ORDER BY username) rn
			,custid
			,username
			,transferType
			,role
			,super
			,master
			,status
			,lastTransfer
		FROM #tmp
		)A
	WHERE A.rn between @RowStart AND @RowEnd
	
	DROP TABLE #tmp
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelAutoTransferAgent] TO [bodbAdminNet]