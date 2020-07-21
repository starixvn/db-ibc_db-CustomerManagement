/*<info serverAlias="DBAGE-BODB02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
USE bodb02
GO
ALTER PROCEDURE [dbo].[Acc_Customer_AssociationInfo] 
	-- Add the parameters for the stored procedure here
	 @HeadlineID SMALLINT
	,@AssociationList VARCHAR(MAX) = '' 
	,@PageSize INT = 50
	,@PageIndex INT = 0
	,@TotalRows INT = 0 OUTPUT
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
			username NVARCHAR(50),
			[Level] nvarchar(30),
			reject BIT,
			closed BIT,
			[Enabled] BIT,
			[Date] SMALLDATETIME )
	CREATE TABLE #Input (CustId INT,[Date] SMALLDATETIME, PRIMARY KEY(CustId))
	
	DECLARE @rowstart INT,@rowend INT, @iDoc			INT
	SELECT @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 
	
	--Check if XML is null or empty
	IF @AssociationList IS NULL OR @AssociationList = ''
		RETURN
	-- Input Data
	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @AssociationList
		INSERT #Input(CustId,[Date])
		SELECT CustId,[Date]
		FROM OPENXML(@iDoc,'/Root/Association',1) WITH (
				CustId	INT,
				[Date]	SMALLDATETIME
			)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	-- Check Data
	INSERT INTO #Result (CustId,username,[Level],reject,closed,[Enabled],[Date])
	SELECT  
	i.CustID
	,c.username
	,CASE c.RoleID WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' END [Level]
	,c.closed
	,c.reject
	,c.Enabled
	,i.[Date]
	FROM #Input i WITH(NOLOCK)
	INNER JOIN custaccount ca WITH (NOLOCK) on i.custid = ca.custid
	INNER JOIN Custinfo c WITH(NOLOCK) on i.custid = c.custid
	WHERE ca.groupID = @HeadlineID
	
	-- Show Pages
	SELECT @TotalRows = COUNT(1)
	FROM #Result
	
	SELECT CustId,username,[Level],reject,closed,[Enabled],[Date]
	FROM #Result
	WHERE ID BETWEEN @RowStart AND @RowEnd
	
END
GO

