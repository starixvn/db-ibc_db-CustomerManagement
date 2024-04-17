/*<info serverAlias="DBONUSER-ON_USER" executers="wsv_alp, bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_Customer_OnlineUserList_Sel]
	@CustId INT,
	@SubAccId INT,
	@IsAllDownline BIT, 
	@pageSize INT = 50,
	@pageIndex INT = 0,
	@totalRows INT = 0 OUTPUT
AS
/*
	Created: 20190304@Johnson
	DB: DBONUSER/ON_USER
	Task: get online users list member level only

	Revisions:
		- 20190304@Johnson: Initialize SP [RedmineID: #105338]
		- 20190715@Elodie: Sub account management [Redmine:#116825] 
*/

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @roleid INT
	CREATE TABLE #tblOnlineList (custid INT, username VARCHAR(50), Name NVARCHAR(50), lastlogin DATETIME)
	
	SELECT @roleid = roleid
	FROM bodb02.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @custid	

	IF @IsAllDownline = 1 OR @SubAccId = 0
	BEGIN
		IF @roleid = 4
		BEGIN
			INSERT INTO #tblOnlineList(custid,username,name,lastlogin)
			SELECT c.custid, username, firstname, lastlogged
			FROM bodb02.dbo.customer c WITH(NOLOCK)
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON c.custid = o.custid
			WHERE srecommend = @custid 
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 3
		BEGIN
			INSERT INTO #tblOnlineList(custid,username,name,lastlogin)
			SELECT c.custid, username, firstname, lastlogged
			FROM bodb02.dbo.customer c WITH(NOLOCK)
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON c.custid = o.custid
			WHERE mrecommend = @custid 
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 2
		BEGIN
			INSERT INTO #tblOnlineList(custid,username,name,lastlogin)
			SELECT c.custid, c.username, firstname, lastlogged
			FROM bodb02.dbo.customer c WITH(NOLOCK)
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON c.custid = o.custid
			WHERE c.recommend = @custid 
				AND c.roleid = 1
				AND o.iskickedout = 0
		END
	END
	ELSE
	BEGIN
		IF @roleid = 4
		BEGIN
			INSERT INTO #tblOnlineList(custid,username,name,lastlogin)
			SELECT c.custid, username, firstname, lastlogged
			FROM bodb02.dbo.customer c WITH(NOLOCK)
				INNER JOIN bodb02.dbo.CS_SubAccManagement sm WITH (NOLOCK) ON c.mrecommend = sm.DownlineId
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON c.custid = o.custid
			WHERE srecommend = @custid AND sm.SubAccId = @SubAccId
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 3
		BEGIN
			INSERT INTO #tblOnlineList(custid,username,name,lastlogin)
			SELECT c.custid, username, firstname, lastlogged
			FROM bodb02.dbo.customer c WITH(NOLOCK)
				INNER JOIN bodb02.dbo.CS_SubAccManagement sm WITH (NOLOCK) ON c.recommend = sm.DownlineId
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON c.custid = o.custid
			WHERE mrecommend = @custid AND sm.SubAccId = @SubAccId
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 2
		BEGIN
			INSERT INTO #tblOnlineList(custid,username,name,lastlogin)
			SELECT c.custid, c.username, firstname, lastlogged
			FROM bodb02.dbo.customer c WITH(NOLOCK)
				INNER JOIN bodb02.dbo.CS_SubAccManagement sm WITH (NOLOCK) ON c.custid = sm.DownlineId
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON c.custid = o.custid
			WHERE c.recommend = @custid AND sm.SubAccId = @SubAccId
				AND c.roleid = 1
				AND o.iskickedout = 0
		END
	END

	DECLARE @RowCount int, @RowStart int, @RowEnd int  
	SELECT	@PageIndex = @PageIndex - 1, 
			@RowStart = @PageSize * @PageIndex + 1, 
			@RowEnd = @RowStart + @PageSize - 1   

	SELECT @TotalRows = count(1)
	FROM #tblOnlineList c
	
	SELECT custid,username,name,lastlogin
	FROM (
		SELECT *, ROW_NUMBER() OVER(ORDER BY LastLogin) rn 
		FROM #tblOnlineList
	)t
	WHERE rn BETWEEN @RowStart AND @RowEnd
END