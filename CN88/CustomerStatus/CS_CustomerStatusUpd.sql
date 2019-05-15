/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_CustomerStatusUpd]
	@CustID INT,
	@Mode TINYINT --1: A to I, 2: I to A, 3: A to S, 4: S to A, 5: A to V, 6: V to A
AS
/*  
	Created by: Paul  
	Date: 2019-05-14
	Task: 
	DB: DBCUST/CustDB
	Original SP:
	Revisions:
		- 20190514@Paul: Create new SP [RedmineID: #113198]
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @Pos TINYINT,
			@NewVal BIT,
			@RoleID TINYINT,
			@DirectDownlineRoleID TINYINT;

	CREATE TABLE #TempCust (CustID INT PRIMARY KEY, RoleID TINYINT);

	SELECT	@Pos = CASE roleid
				WHEN 0 THEN 4
				WHEN 4 THEN 3
				WHEN 3 THEN 2
				WHEN 2 THEN 1
				WHEN 1 THEN 0
			END,
			@RoleID = roleid,
			@DirectDownlineRoleID = CASE roleid
				WHEN 0 THEN 4
				WHEN 4 THEN 3
				WHEN 3 THEN 2
				WHEN 2 THEN 1
			END
	FROM custInfo WITH(NOLOCK)
	WHERE CustID = @CustID;

	IF @Mode IN (1, 3, 5)
	BEGIN
		SELECT @NewVal = 1;
	END

	IF @Mode IN (2, 4, 6)
	BEGIN
		SELECT @NewVal = 0;
	END

	--Headline
	IF @RoleID = 0
	BEGIN
		INSERT INTO #TempCust (CustID, RoleID)
		SELECT @CustID, 0

		UNION ALL

		SELECT custid, roleid
		FROM custInfo c WITH(NOLOCK)
		WHERE EXISTS (
				SELECT 1
				FROM CustSuper cs WITH(NOLOCK)
				WHERE c.srecommend = cs.custid
					AND cs.UplineId = @CustID
			);
	END
	
	--Super
	IF @RoleID = 4
	BEGIN
		INSERT INTO #TempCust (CustID, RoleID)
		SELECT custid, roleid
		FROM custInfo c WITH(NOLOCK)
		WHERE srecommend = @CustID;
	END

	--Master
	IF @RoleID = 3
	BEGIN
		INSERT INTO #TempCust (CustID, RoleID)
		SELECT custid, roleid
		FROM custInfo c WITH(NOLOCK)
		WHERE mrecommend = @CustID;
	END

	--Agent
	IF @RoleID = 2
	BEGIN
		INSERT INTO #TempCust (CustID, RoleID)
		SELECT custid, roleid
		FROM custInfo c WITH(NOLOCK)
		WHERE recommend = @CustID;
	END

	--Member
	IF @RoleID = 1
	BEGIN
		INSERT INTO #TempCust (CustID, RoleID)
		SELECT @CustID, 1;
	END

	IF @Mode IN (1, 2)
	BEGIN
		--Update bit value of user and his downlines at his bit
		UPDATE cs
		SET InactiveInfo = (SELECT Val FROM f_SetBit(InactiveInfo, @Pos, @NewVal))
		FROM CS_CustomerStatus cs WITH(ROWLOCK, UPDLOCK)
		WHERE EXISTS (
				SELECT 1
				FROM #TempCust c
				WHERE cs.CustID = c.CustID
			);

		IF @Mode = 1
		BEGIN
			--Remove View Only and Suspended status of user
			UPDATE cs
			SET SuspendedInfo = (SELECT Val FROM f_SetBit(SuspendedInfo, @Pos, 0)),
				ViewOnlyInfo = (SELECT Val FROM f_SetBit(ViewOnlyInfo, @Pos, 0))
			FROM CS_CustomerStatus cs WITH(ROWLOCK, UPDLOCK)
			WHERE EXISTS (
					SELECT 1
					FROM #TempCust c
					WHERE cs.CustID = c.CustID
				);
		END

		IF @Mode = 2 AND @RoleID <> 1
		BEGIN
			--Update downlines to inactive
			UPDATE cs
			SET InactiveInfo = (SELECT Val FROM f_SetBit(InactiveInfo, @Pos - 1, 1)),
				SuspendedInfo = (SELECT Val FROM f_SetBit(SuspendedInfo, @Pos - 1, 0)),
				ViewOnlyInfo = (SELECT Val FROM f_SetBit(ViewOnlyInfo, @Pos - 1, 0))
			FROM CS_CustomerStatus cs WITH(ROWLOCK, UPDLOCK)
			WHERE EXISTS (
					SELECT 1
					FROM #TempCust c
					WHERE cs.CustID = c.CustID
						AND c.RoleID = @DirectDownlineRoleID
				);
		END
	END

	IF @Mode IN (3, 4)
	BEGIN
		UPDATE cs
		SET SuspendedInfo = (SELECT Val FROM f_SetBit(SuspendedInfo, @Pos, @NewVal))
		FROM CS_CustomerStatus cs WITH(ROWLOCK, UPDLOCK)
		WHERE EXISTS (
				SELECT 1
				FROM #TempCust c
				WHERE cs.CustID = c.CustID
			);
	END

	IF @Mode IN (5, 6)
	BEGIN
		UPDATE cs
		SET ViewOnlyInfo = (SELECT Val FROM f_SetBit(ViewOnlyInfo, @Pos, @NewVal))
		FROM CS_CustomerStatus cs WITH(ROWLOCK, UPDLOCK)
		WHERE EXISTS (
				SELECT 1
				FROM #TempCust c
				WHERE cs.CustID = c.CustID
			);
	END

	SET NOCOUNT OFF;
END
GO