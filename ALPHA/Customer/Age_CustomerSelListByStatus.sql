/*<info serverAlias="DBACC-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelListByStatus]
	@CustId INT,
	@RoleId TINYINT,
	@Status TINYINT,
	@PageSize INT = 500,
	@PageIndex INT = 1
AS
/*
	Creator: 20181108@Elodie
	Task: Get downline list by status in left panel (Put on DB06 to 
														- Use index IX_custinfo for master and IX_custinfo_1 for agent  
														- Use CustLoginInfo and CustLoginInfo_Member in DB06 )
	DB: DBACC/bodb02
	
	Revisions:	
		- 20181108@Elodie: Get downline list by status in left panel [RedmineID: #58776]	

	Explanation: 
		@Status:1: Active
				2: Closed
				3: Suppend

	Example: EXEC Age_CustomerSelListByStatus @CustID=24471545, @Status = 1
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RowCount int, @RowStart int, @RowEnd INT, @TotalPages INT
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

	DECLARE @CustList TABLE (Username NVARCHAR(30), CustId INT)		

	IF @RoleId = 2
	BEGIN	
		IF @Status = 1 --Active
		BEGIN
			INSERT INTO @CustList(username,Custid)
			SELECT c.username,c.Custid
			FROM custinfo c WITH (NOLOCK)
			WHERE c.roleid = 1 and c.recommend = @custid
				AND c.closed = 0 AND ISNULL(reject,0) = 0
			ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
		END
		ELSE IF @Status = 2 --Closed
		BEGIN
			INSERT INTO @CustList(username,Custid)
			SELECT c.username,c.Custid
			FROM custinfo c WITH (NOLOCK)
			WHERE c.roleid = 1 and c.recommend = @custid
				AND c.closed = 1
			ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
		END
		ELSE IF @Status = 3 --Suppend
		BEGIN
			INSERT INTO @CustList(username,Custid)
			SELECT c.username,c.Custid
			FROM custinfo c WITH (NOLOCK)
			WHERE c.roleid = 1 and c.recommend = @custid
				AND c.closed = 0 AND ISNULL(reject,0) = 1
			ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
		END
	END
	ELSE IF @RoleId = 3
	BEGIN
		IF @Status = 1 --Active
		BEGIN
			INSERT INTO @CustList(username,Custid)		
			SELECT  c.username,c.Custid
			FROM custinfo c WITH (NOLOCK)
			WHERE c.roleid = 2 and c.mrecommend = @custid
				AND c.closed = 0 AND ISNULL(reject,0) = 0
			ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
		END
		ELSE IF @Status = 2 --Closed
		BEGIN
			INSERT INTO @CustList(username,Custid)		
			SELECT  c.username,c.Custid
			FROM custinfo c WITH (NOLOCK)
			WHERE c.roleid = 2 and c.mrecommend = @custid
				AND c.closed = 1
			ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
		END
		ELSE IF @Status = 3 --Suppend
		BEGIN
			INSERT INTO @CustList(username,Custid)		
			SELECT  c.username,c.Custid
			FROM custinfo c WITH (NOLOCK)
			WHERE c.roleid = 2 and c.mrecommend = @custid
				AND c.closed = 0 AND ISNULL(reject,0) = 1
			ORDER BY c.enabled DESC, c.closed, c.reject, c.username	
		END
	END	

	--Paging
	IF @TotalPages = 0
	BEGIN
		SELECT 
			@TotalPages = COUNT(1),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
		FROM @CustList c 
	END
		
	SELECT UserName,Custid INTO #tmpList
	FROM 
	(
		SELECT 
			UserName,Custid,
			ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RowNumber 
		FROM @CustList 
	) c
	WHERE c.RowNumber BETWEEN @RowStart AND @RowEnd

	SELECT @TotalPages AS TotalPages

	IF @RoleId = 2
		SELECT UserName,cl.ClosedReason
		FROM #tmpList c
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	ELSE IF @RoleId = 3
		SELECT UserName,cl.ClosedReason
		FROM #tmpList c
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	
END

GO
