/*<info serverAlias="DBONUSER-On_User" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [ON_USER]
GO

ALTER PROCEDURE [dbo].[Age_MessageNoticeDownlineUpd] 
	@CustID			INT, 	
	@UserID			INT,
	@TypeID			INT -- 3: Status
AS
/*
    Created: 2070417@Elodie
    Task: Update table "MESSAGE_NOTICE" when one upline enable product for downlines.
    DB: DBONUSER/On_User
    Original:
    Revisions:
    
    Param's Explanation:
        . @CustID: ID of agent whose status value has been changed
        . @UserID: ID of master or admin who made it
*/
BEGIN   
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

	DECLARE @isViewed BIT, @RoleID TINYINT
	DECLARE @modifiedDate DATETIME
    CREATE TABLE #TmpTable (CustID INT PRIMARY KEY)

	SET @isViewed = 0
	SET @modifiedDate = GETDATE()
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

	MERGE dbo.MESSAGE_NOTICE AS TARGET
	USING (SELECT CustID, @UserID, @TypeID FROM #TmpTable) AS SOURCE (CustID, UserID, TypeID)
		ON (TARGET.CustID = SOURCE.CustID AND TARGET.UserID = SOURCE.UserID AND TARGET.TypeID = SOURCE.TypeID)
	WHEN MATCHED THEN 
			UPDATE SET	TARGET.modifiedDate = @modifiedDate,
						TARGET.isViewed = @isViewed
	WHEN NOT MATCHED THEN	
		INSERT (CustID, TypeID, modifiedDate, userID, isViewed)
		VALUES (SOURCE.CustID, SOURCE.TypeID, @modifiedDate, SOURCE.userID, @isViewed);

END
