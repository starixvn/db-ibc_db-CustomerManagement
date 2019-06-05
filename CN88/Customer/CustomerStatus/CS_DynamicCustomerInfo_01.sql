/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[CS_DynamicCustomerInfo_01]
	@CustId			INT,
	@RoleId			TINYINT,
	@Action			VARCHAR(50),
	@Mode			TINYINT = 0
AS

/*
	Created: 20181218@Percy
	DB: DBCUST/CustDB
	Task: Execrep SP

	Revisions:
		- 20181218@Percy: Initialize SP: Update status customer whole line [RedmineID: #105338]
		- 20190527@Elodie: New account status for CN88 [Redmine: 113198]

	Param's Explanation:
		@Mode: 1: A to I, 2: I to A, 3: A to S, 4: S to A, 5: A to V, 6: V to A
		
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SetBit0 INT, @SetBit1 INT, @SetBit0Downline INT, @SetBit1Downline INT, @Pos TINYINT
	CREATE TABLE #TempCust (CustID INT PRIMARY KEY, RoleID TINYINT);

	IF dbo.f_CheckRepTable('custInfo') = 1
	BEGIN
		IF @Action = 'UpdateStatus'
		BEGIN
			SELECT	@Pos = CASE @RoleId WHEN 0 THEN 4
										WHEN 4 THEN 3
										WHEN 3 THEN 2
										WHEN 2 THEN 1
										WHEN 1 THEN 0 END 
			
			SELECT @SetBit1 = POWER(2, @Pos)			
			SELECT @SetBit0 = (~POWER(2, @Pos))

			SELECT @SetBit1Downline = POWER(2, @Pos-1)		 	
			SELECT @SetBit0Downline = (~POWER(2, @Pos-1))

			IF @RoleID = 0 --Headline
			BEGIN
				INSERT INTO #TempCust (CustID, RoleID)
				SELECT @CustID, 0
				UNION ALL
				SELECT c.custid, c.roleid
				FROM custInfo c WITH(NOLOCK)
					INNER JOIN CustSuper cs WITH(NOLOCK) ON c.srecommend = cs.custid
				WHERE cs.UplineId = @CustID
			END
			ELSE IF @RoleID = 4 --Super			
			BEGIN
				INSERT INTO #TempCust (CustID, RoleID)
				SELECT custid, roleid
				FROM custInfo c WITH(NOLOCK)
				WHERE srecommend = @CustID
			END
			ELSE IF @RoleID = 3 --Master
			BEGIN
				INSERT INTO #TempCust (CustID, RoleID)
				SELECT custid, roleid
				FROM custInfo c WITH(NOLOCK)
				WHERE mrecommend = @CustID
			END
			ELSE IF @RoleID = 2 --Agent
			BEGIN
				INSERT INTO #TempCust (CustID, RoleID)
				SELECT custid, roleid
				FROM custInfo c WITH(NOLOCK)
				WHERE recommend = @CustID
			END
			ELSE IF @RoleID = 1 --Member
			BEGIN
				INSERT INTO #TempCust (CustID, RoleID)
				SELECT @CustID, 1
			END

			
			IF @Mode = 1 --1: A to I
			BEGIN
				UPDATE cs WITH (ROWLOCK)
				SET cs.InactiveInfo = cs.InactiveInfo | @SetBit1, 
					cs.SuspendedInfo = cs.SuspendedInfo & @SetBit0,
					cs.ViewOnlyInfo = cs.ViewOnlyInfo & @SetBit0
				FROM dbo.CS_CustomerStatus cs
					INNER JOIN #TempCust tc ON cs.custid = tc.custid
			END
			ELSE IF @Mode = 2 --2: I to A
			BEGIN
				UPDATE cs WITH (ROWLOCK)
				SET cs.InactiveInfo = cs.InactiveInfo & @SetBit0
				FROM dbo.CS_CustomerStatus cs
				WHERE cs.CustId = @CustId

				IF @RoleId <> 1
				BEGIN
					UPDATE cs WITH (ROWLOCK)
					SET cs.InactiveInfo = cs.InactiveInfo & @SetBit0 | @SetBit1Downline,
						cs.SuspendedInfo = cs.SuspendedInfo & @SetBit0Downline,
						cs.ViewOnlyInfo = cs.ViewOnlyInfo & @SetBit0Downline
					FROM dbo.CS_CustomerStatus cs
						INNER JOIN #TempCust tc ON cs.custid = tc.custid
					WHERE cs.CustId <> @CustId					
				END				
			END
			ELSE IF @Mode = 3 --3: A to S
			BEGIN
				UPDATE cs WITH (ROWLOCK)
				SET cs.SuspendedInfo = cs.SuspendedInfo | @SetBit1
				FROM dbo.CS_CustomerStatus cs
					INNER JOIN #TempCust tc ON cs.custid = tc.custid
			END
			ELSE IF @Mode = 4 --4: S to A
			BEGIN
				UPDATE cs WITH (ROWLOCK)
				SET cs.SuspendedInfo = cs.SuspendedInfo & @SetBit0
				FROM dbo.CS_CustomerStatus cs
					INNER JOIN #TempCust tc ON cs.custid = tc.custid
			END
			ELSE IF @Mode = 5 --5: A to V
			BEGIN
				UPDATE cs WITH (ROWLOCK)
				SET cs.ViewOnlyInfo = cs.ViewOnlyInfo | @SetBit1
				FROM dbo.CS_CustomerStatus cs
					INNER JOIN #TempCust tc ON cs.custid = tc.custid
			END
			ELSE IF @Mode = 6 --6: V to A
			BEGIN
				UPDATE cs WITH (ROWLOCK)
				SET cs.ViewOnlyInfo = cs.ViewOnlyInfo & @SetBit0
				FROM dbo.CS_CustomerStatus cs
					INNER JOIN #TempCust tc ON cs.custid = tc.custid
			END

			DROP TABLE #TempCust
		END
	END
END
GO