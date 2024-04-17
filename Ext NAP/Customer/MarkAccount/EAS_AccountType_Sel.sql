/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_AccountType_Sel]
	@GroupName		VARCHAR(50)
	,@UserName		NVARCHAR(50)=''
	,@RoleID		VARCHAR(10) = '0'
	,@TypeID		VARCHAR(10) = '0'
	,@ExportData	INT	=	0
	,@PageSize		INT	=	50
	,@PageIndex		INT	=	0
	,@TotalRows 	INT	=	0 OUTPUT
AS
/*
	Creator: 20230525@Tacy  
	Task : Select marked account
	DB: DBCUST/CustDB

	Revisions:  
		- 20230525@Tacy: Ext NAP - Function for Headline to provide customer class based on their knowledge [Redmine:#188025]
	
	Param's Explanation:
		* @RoleID : 0 ~ all (SMA, Member)
					1 ~ member
					2 ~ agent
					3 ~ master
					4 ~ super

		* TypeID :  0 ~ All
					1 ~ VIP
					2 ~ Suspcious
					3 ~ Problem
	Example:	
*/		
BEGIN
    SET NOCOUNT ON

	DECLARE @rowstart	INT,
			@rowend		INT

	SELECT	@RowStart = @PageSize * @PageIndex + 1, 
			@RowEnd = @RowStart + @PageSize - 1 
	
	CREATE TABLE #tbMarkedAcc (
		RowID		INT NOT NULL IDENTITY(1,1),
		CustID		INT,
		Username	VARCHAR(50),
		RoleID		TINYINT,
		TypeID		TINYINT,
		MarkedDate	SMALLDATETIME,
		Remark		NVARCHAR(2000)
	)

	IF @UserName<>''
	BEGIN
		INSERT INTO #tbMarkedAcc (CustID, Username, RoleID, TypeID, MarkedDate, Remark)
		SELECT c.custid, c.username, C.roleid, ct.TypeID, ct.MarkedDate, ct.remark
		FROM Acc_CustType ct WITH (NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ct.custid
		INNER JOIN Acc_CustGroup cg WITH (NOLOCK) ON cg.CustID=c.srecommend 
												  AND cg.GroupName=@GroupName
		WHERE c.username LIKE @username + '%'
			AND (@RoleID='0' OR c.roleid IN (SELECT CAST(TRIM(value) AS INT) FROM STRING_SPLIT(@RoleID,',') WHERE TRIM(value)<>''))
			AND (@TypeID='0' OR ct.TypeID IN (SELECT CAST(TRIM(value) AS INT) FROM STRING_SPLIT(@TypeID,',') WHERE TRIM(value)<>''))
		ORDER BY ct.MarkedDate DESC, c.Username ASC
	END
	ELSE
	BEGIN
		INSERT INTO #tbMarkedAcc (CustID, Username, RoleID, TypeID, MarkedDate, Remark)
		SELECT c.custid, c.username, C.roleid, ct.TypeID, ct.MarkedDate, ct.remark
		FROM Acc_CustType ct WITH (NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ct.custid
		INNER JOIN Acc_CustGroup cg WITH (NOLOCK) ON cg.CustID=c.srecommend 
												  AND cg.GroupName=@GroupName
		WHERE (@RoleID='0' OR c.roleid IN (SELECT CAST(TRIM(value) AS INT) FROM STRING_SPLIT(@RoleID,',') WHERE TRIM(value)<>''))
			AND (@TypeID='0' OR ct.TypeID IN (SELECT CAST(TRIM(value) AS INT) FROM STRING_SPLIT(@TypeID,',') WHERE TRIM(value)<>''))
		ORDER BY ct.MarkedDate DESC, c.Username ASC
	END
	
	SELECT @TotalRows = COUNT(1)
	FROM #tbMarkedAcc

	SELECT CustID, Username, RoleID, TypeID, MarkedDate, Remark
	FROM #tbMarkedAcc
	WHERE RowID BETWEEN @rowstart AND @rowend
	ORDER BY RowID
END
GO