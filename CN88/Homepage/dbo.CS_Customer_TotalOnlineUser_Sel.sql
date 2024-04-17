/*<info serverAlias="DBONUSER-ON_USER" executers="wsv_alp, wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_Customer_TotalOnlineUser_Sel]
	@CustId INT,
	@SubAccId INT, 
	@IsAllDownline BIT
AS
/*
	Created: 20190304@Johnson
	DB: DBONUSER/ON_USER
	Task: count total online users member level only

	Revisions:
		- 20190304@Johnson: Initialize SP [RedmineID: #105338]
		- 20190715@Elodie: Sub account management [Redmine:#116825] 
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @cntOnUsers INT, @roleid TINYINT
			
	SELECT @roleid = roleid
	FROM bodb02.dbo.custinfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @IsAllDownline = 1 OR @SubAccId = 0
	BEGIN
		IF @roleid = 4
		BEGIN
			SELECT @cntOnUsers = count(1)
			FROM bodb02.dbo.custinfo ci WITH(NOLOCK)
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON ci.custid = o.custid
			WHERE srecommend = @custid 
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 3
		BEGIN
			SELECT @cntOnUsers = count(1)
			FROM bodb02.dbo.custinfo ci WITH(NOLOCK)
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON ci.custid = o.custid
			WHERE mrecommend = @custid 
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 2
		BEGIN
			SELECT @cntOnUsers = count(1)
			FROM bodb02.dbo.custinfo ci WITH(NOLOCK)
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON ci.custid = o.custid
			WHERE recommend = @custid 
				AND roleid = 1
				AND o.iskickedout = 0
		END
	END
	ELSE
	BEGIN
		IF @roleid = 4
		BEGIN
			SELECT @cntOnUsers = count(1)
			FROM bodb02.dbo.custinfo ci WITH(NOLOCK)
				INNER JOIN bodb02.dbo.CS_SubAccManagement sm WITH (NOLOCK) ON ci.mrecommend = sm.DownlineId
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON ci.custid = o.custid
			WHERE srecommend = @custid AND sm.SubAccId = @SubAccId
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 3
		BEGIN
			SELECT @cntOnUsers = count(1)
			FROM bodb02.dbo.custinfo ci WITH(NOLOCK)
				INNER JOIN bodb02.dbo.CS_SubAccManagement sm WITH (NOLOCK) ON ci.recommend = sm.DownlineId
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON ci.custid = o.custid
			WHERE mrecommend = @custid AND sm.SubAccId = @SubAccId 
				AND roleid = 1
				AND o.iskickedout = 0
		END
		ELSE IF @roleid = 2
		BEGIN
			SELECT @cntOnUsers = count(1)
			FROM bodb02.dbo.custinfo ci WITH(NOLOCK)
				INNER JOIN bodb02.dbo.CS_SubAccManagement sm WITH (NOLOCK) ON ci.custid = sm.DownlineId
				INNER JOIN dbo.On_user o WITH(NOLOCK) ON ci.custid = o.custid
			WHERE recommend = @custid AND sm.SubAccId = @SubAccId 
				AND roleid = 1
				AND o.iskickedout = 0
		END
	END

	SELECT ISNULL(@cntOnUsers,0) as cntOnUsers
END	