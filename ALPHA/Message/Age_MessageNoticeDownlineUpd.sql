/*<info serverAlias="DBONUSER-On_User" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [ON_USER]
GO

ALTER PROCEDURE [dbo].[Age_MessageNoticeDownlineUpd] 
	@CustID			INT, 	
	@UserID			INT,
	@TypeID			INT, -- 3: Status
	@IsDisabled		VARCHAR(MAX) = NULL
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
    CREATE TABLE #Result (CustID INT PRIMARY KEY)
	CREATE TABLE #TmpTable (srecommend INT, mrecommend INT)

	SET @isViewed = 0
	SET @modifiedDate = GETDATE()
	SELECT @RoleID = roleid FROM bodb02.dbo.CustInfo WITH (NOLOCK) WHERE custid = @CustID 
	
	IF @TypeID = 3
	BEGIN
		CREATE TABLE #NewDisableStatTbl(
					SportType			SMALLINT,
					BetType				SMALLINT,
					IsDisabled			BIT,
					UpdateAllMasters	BIT,
					UpdateAllAgents		BIT,
					UpdateAllMembers	BIT,
					DisableAllMasters	BIT,
					DisableAllAgents	BIT,
					DisableAllMembers	BIT
				)
		
		--Parse XML	
		DECLARE @iDoc INT
					
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @IsDisabled
		
		INSERT INTO #NewDisableStatTbl
		SELECT *
		FROM OPENXML (@iDoc, '/ROOT/ProductStatus',1) 
		WITH(SportType smallint,BetType smallint,IsDisabled BIT,UpdateAllMasters BIT,UpdateAllAgents BIT,UpdateAllMembers BIT,DisableAllMasters BIT,DisableAllAgents BIT,DisableAllMembers BIT)	
		
		EXEC sp_xml_removedocument @iDoc
	
		SELECT ps.bitmapOrder
		INTO #BitmapOrder
		FROM bodb02.dbo.ProductStatusProfile ps WITH (NOLOCK)
			INNER JOIN #NewDisableStatTbl ds ON ds.BetType = ps.Bettype AND ds.SportType = ps.Sporttype
		WHERE UpdateAllMembers = 1

		IF @RoleID = 4
		BEGIN
			--Agent has downlines who is disabled
			INSERT #Result (CustID)
			SELECT ci.custid
			FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
			WHERE ci.srecommend = @CustID AND ci.roleid = 2 
				AND EXISTS (SELECT 1 
							FROM bodb02.dbo.custInfo dl WITH (NOLOCK)
								INNER JOIN bodb02.dbo.CustProductStatus cs WITH (NOLOCK) ON dl.custid = cs.custid
								CROSS JOIN #BitmapOrder
							WHERE dl.recommend = ci.custid 
								AND roleid = 1
								AND (SELECT value FROM bodb02.dbo.f_CustSetting_ProductStatusSel(cs.bitmapIsDisabled, bitmapOrder)) = 1)

			IF @@ROWCOUNT <> 0 
			BEGIN
				INSERT #TmpTable (srecommend, mrecommend)
				SELECT ci.srecommend, ci.mrecommend
				FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
					INNER JOIN #Result t ON t.CustID = ci.custid
				GROUP BY ci.srecommend, ci.mrecommend

				--Master 
				INSERT #Result (CustID)
				SELECT DISTINCT mrecommend
				FROM #TmpTable
			
				--Super
				INSERT #Result (CustID)
				SELECT DISTINCT srecommend
				FROM #TmpTable
			END
		END
		ELSE IF @RoleID = 3
		BEGIN
			--Agent has downlines who is disabled
			INSERT #Result (CustID)
			SELECT ci.custid
			FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
			WHERE ci.mrecommend = @CustID AND ci.roleid = 2 
				AND EXISTS (SELECT 1 
							FROM bodb02.dbo.custInfo dl WITH (NOLOCK)
								INNER JOIN bodb02.dbo.CustProductStatus cs WITH (NOLOCK) ON dl.custid = cs.custid
								CROSS JOIN #BitmapOrder
							WHERE dl.recommend = ci.custid 
								AND roleid = 1
								AND (SELECT value FROM bodb02.dbo.f_CustSetting_ProductStatusSel(cs.bitmapIsDisabled, bitmapOrder)) = 1)

			IF @@ROWCOUNT <> 0 
			BEGIN
				--Master
				INSERT #Result (CustID)
				SELECT ci.mrecommend
				FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
					INNER JOIN #Result t ON t.CustID = ci.custid
				GROUP BY ci.mrecommend
			END
		END
		ELSE 
		BEGIN
			--Agent has downlines who is disabled
			INSERT #Result (CustID)
			SELECT ci.custid
			FROM bodb02.dbo.CustInfo ci WITH (NOLOCK)
			WHERE ci.recommend = @CustID AND ci.roleid = 2 
				AND EXISTS (SELECT 1 
							FROM bodb02.dbo.custInfo dl WITH (NOLOCK)
								INNER JOIN bodb02.dbo.CustProductStatus cs WITH (NOLOCK) ON dl.custid = cs.custid
								CROSS JOIN #BitmapOrder
							WHERE dl.recommend = ci.custid 
								AND roleid = 1
								AND (SELECT value FROM bodb02.dbo.f_CustSetting_ProductStatusSel(cs.bitmapIsDisabled, bitmapOrder)) = 1)
		END;

		MERGE dbo.MESSAGE_NOTICE AS TARGET
		USING (SELECT CustID, @UserID, @TypeID FROM #Result) AS SOURCE (CustID, UserID, TypeID)
			ON (TARGET.CustID = SOURCE.CustID AND TARGET.TypeID = SOURCE.TypeID)
		WHEN MATCHED THEN 
				UPDATE SET	TARGET.modifiedDate = @modifiedDate,
							TARGET.isViewed = @isViewed
		WHEN NOT MATCHED THEN	
			INSERT (CustID, TypeID, modifiedDate, userID, isViewed)
			VALUES (SOURCE.CustID, SOURCE.TypeID, @modifiedDate, SOURCE.userID, @isViewed);
	END
END
