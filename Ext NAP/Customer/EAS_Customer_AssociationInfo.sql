/*<info serverAlias="DBAGE-BODB02" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[EAS_Customer_AssociationInfo] 
	 @GroupName VARCHAR(25)
	,@AssociationList VARCHAR(MAX) = '' 
	,@PageSize INT = 50
	,@PageIndex INT = 0
	,@TotalRows INT = 0 OUTPUT
	,@TotalAccount INT = 0 OUTPUT
	,@ErrCode		INT				= 0		OUTPUT
	,@ErrMsg		NVARCHAR(200)	= ''	OUTPUT
AS
/*
	Created by:Winfred.Pham	
	Date:2020-07-21
	Task: get list customers with association  
	DB: DBAGE/BODB02
	
	Revisions:
		- 20200721@winfred: initial sp [redmine: #137009]
		- 20210505@Tina: Lock account & indirect close account [redmine: #148600]

	Parameter's Explanation:
		- @AssociationList
		<ROOT>
				<Association
						CustId="1329939"
						Date="20200721" 
				/>
		</ROOT>
*/
BEGIN
	SET NOCOUNT ON;
	CREATE TABLE #Result (
			ID INT IDENTITY (1,1),
			CustId INT,
			Roleid TINYINT,
			username NVARCHAR(50),
			reject BIT,
			closed BIT,
			[Enabled] BIT,
			[Date] SMALLDATETIME )
	CREATE TABLE #Input (CustId INT,CustSubId INT,[Date] SMALLDATETIME)
	
	DECLARE @rowstart INT,@rowend INT, @iDoc			INT
	SELECT @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 
	
	--Check if XML is null or empty
	IF @AssociationList IS NULL OR @AssociationList = ''
		RETURN
	-- Input Data
	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @AssociationList
		INSERT #Input(CustId,CustSubId,[Date])
		SELECT CustId,CustSubId,[Date]
		FROM OPENXML(@iDoc,'/Root/Association',1) WITH (
				CustId	INT,
				CustSubId INT,
				[Date]	SMALLDATETIME
			)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	-- Total row input
	SELECT @TotalAccount = COUNT(1)
	FROM #Input
	-- Check Data not Sub 
	INSERT INTO #Result (CustId,username,Roleid,reject,closed,[Enabled],[Date])
	SELECT DISTINCT
	i.CustID
	,c.username
	,c.roleid
	,cps.reject
	,cps.closed
	,c.Enabled
	,i.[Date]
	FROM #Input i WITH(NOLOCK)
		INNER JOIN Custinfo c WITH(NOLOCK) on i.custid = c.custid
		INNER JOIN Acc_CustGroup ca WITH (NOLOCK) on c.srecommend = ca.custid
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cps
	WHERE ca.GroupName = @GroupName AND  i.CustSubId = 0
	-- Check Data Sub 
	INSERT INTO #Result (CustId,username,Roleid,reject,closed,[Enabled],[Date])
	SELECT  DISTINCT
	i.CustID
	,c.username
	,c.roleid
	,cps.reject
	,cps.closed
	,c.Enabled
	,i.[Date]
	FROM #Input i WITH(NOLOCK)
	INNER JOIN Custinfo c WITH(NOLOCK) on i.CustSubId = c.custid
	INNER JOIN Acc_CustGroup ca WITH (NOLOCK) on c.srecommend = ca.custid
	CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cps
	WHERE ca.GroupName = @GroupName AND  i.CustSubId <> 0
	-- Show Pages
	SELECT @TotalRows = COUNT(1)
	FROM #Result
	
	SELECT custid,username,roleid,reject  AS suspended,closed,enabled,[date]
	FROM #Result
	WHERE ID BETWEEN @RowStart AND @RowEnd
	ORDER BY [Enabled] desc,closed,reject,username
	
END
GO

