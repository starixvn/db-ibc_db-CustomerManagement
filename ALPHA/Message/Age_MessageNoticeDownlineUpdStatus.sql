/*<info serverAlias="DBONUSER-On_User" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
USE [On_User]
GO

ALTER PROCEDURE [dbo].[Age_MessageNoticeDownlineUpdStatus] 
	@custID		int,
	@isViewed	BIT, -- 1: Status is viewed.
	@TypeID		TINYINT
AS
/*
    Created: 2070417@Elodie
    Task: Set value of field "isViewed" in table “MESSAGE_NOTICE”
    DB: DBONUSER/On_User
    Original:
    Revisions:
		- 2070417@Elodie: Set value of field "isViewed" in table “MESSAGE_NOTICE”

    Param's Explanation:
        . @CustID: ID of agent whose status value has been changed
        . @isViewed: status will be updated
*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	CREATE TABLE #TmpTable (CustID INT PRIMARY KEY)
	DECLARE @RoleID TINYINT

	SELECT @RoleID = roleid FROM bodb02.dbo.CustInfo WITH (NOLOCK) WHERE custid = @CustID 
	IF @RoleID = 4
	BEGIN
		--Super who has downlines
		INSERT #TmpTable (CustID)
		SELECT TOP 1 @CustID
		FROM bodb02.dbo.CustInfo WITH (NOLOCK)
		WHERE srecommend = @CustID AND roleid = 3

		IF @@ROWCOUNT <> 0 
		BEGIN
			--Master who has downlines
			INSERT #TmpTable (CustID)
			SELECT ci.mrecommend
			FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN bodb02.dbo.custInfo dl WITH (NOLOCK) ON ci.mrecommend = dl.mrecommend AND dl.roleid = 2 --AND ci.srecommend = dl.srecommend no need 
			WHERE ci.srecommend = @CustID AND ci.roleid = 3
			GROUP BY ci.mrecommend

			IF @@ROWCOUNT <> 0
			BEGIN
				--Agent who has downlines
				INSERT #TmpTable (CustID)
				SELECT ci.recommend
				FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
					INNER JOIN bodb02.dbo.custInfo dl WITH (NOLOCK) ON ci.recommend = dl.recommend AND dl.roleid = 1
				WHERE ci.srecommend = @CustID AND ci.roleid = 2
				GROUP BY ci.recommend
			END
		END
	END
	ELSE IF @RoleID = 3
	BEGIN
		--Master who has downlines
		INSERT #TmpTable (CustID)
		SELECT TOP 1 @CustID
		FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
		WHERE ci.mrecommend = @CustID AND ci.roleid = 2

		IF @@ROWCOUNT <> 0
		BEGIN
			--Agent who has downlines
			INSERT #TmpTable (CustID)
			SELECT ci.recommend
			FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
				INNER JOIN bodb02.dbo.custInfo dl WITH (NOLOCK) ON ci.recommend = dl.recommend AND dl.roleid = 1
			WHERE ci.mrecommend = @CustID AND ci.roleid = 2
			GROUP BY ci.recommend
		END
	END
	ELSE 
	BEGIN
		--Agent who has downlines
		INSERT #TmpTable (CustID)
		SELECT TOP 1 @CustID
		FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
		WHERE ci.recommend = @CustID AND ci.roleid = 1
	END

    -- Update statements for procedure here
	UPDATE msg
	SET isViewed = @isViewed
	FROM MESSAGE_NOTICE msg WITH(ROWLOCK)
		INNER JOIN #TmpTable tmp ON msg.custID = tmp.CustID 	
	WHERE TypeID = @TypeID
END
GO