/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap,wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustInfoMiniUpdMoveSite]
	@UserId			INT,
	@CustId			INT	,
	@Site			varchar(50),
	@ErrCode		INT OUTPUT,
	@ErrMsg			varchar(200) OUTPUT

AS
/*	Created by: Helen
	Date: 20241010@Helen
	Task: Move Site for customer
	DB: DBGLOB-GLOBCUSTDB

	Revisions:		
		- 20241010@Helen: move site for CREDIT - [Redmine:#212007]

	Param's Explanation:
		@CustID: Custid of customer want to move site. We allow to move all customers
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #SMAList ([CustID] INT)
	CREATE TABLE #SMAList_Update ([CustID] INT PRIMARY KEY)
	CREATE TABLE #MemberTemp ([CustID] INT)
	CREATE TABLE #MemberUpdated ([CustID] INT PRIMARY KEY)
	
	DECLARE @RoleId TINYINT

	SELECT @RoleId = ISNULL(roleid,0) 
	FROM CustInfoMini (NOLOCK) 
	WHERE custid=@CustId

	IF @RoleId = 4 -- For Super
	BEGIN
		INSERT INTO #SMAList (CustID)
		SELECT C.custid
		FROM CustInfoMini C WITH (NOLOCK)
		WHERE C.srecommend = @custid AND C.roleid IN (4,3,2)

		INSERT INTO #MemberTemp(CustID)
		SELECT C.custid
		FROM CustInfoMini C WITH (NOLOCK)
		WHERE C.srecommend = @custid AND C.roleid IN (1)
	END
	ELSE IF @RoleId = 3 -- For Master
	BEGIN
		INSERT INTO #SMAList (CustID)
		SELECT C.custid
		FROM CustInfoMini C WITH (NOLOCK)
		WHERE C.mrecommend = @custid AND C.roleid IN (3,2)

		INSERT INTO #MemberTemp(CustID)
		SELECT C.custid
		FROM CustInfoMini C WITH (NOLOCK)
		WHERE C.mrecommend = @custid AND C.roleid IN (1)
	END
	ELSE IF @RoleId = 2 -- For Agent
	BEGIN
		INSERT INTO #SMAList (CustID)
		SELECT C.custid
		FROM CustInfoMini C WITH (NOLOCK)
		WHERE C.recommend = @custid AND C.roleid IN (2)

		INSERT INTO #MemberTemp(CustID)
		SELECT C.custid
		FROM CustInfoMini C WITH (NOLOCK)
		WHERE C.recommend = @custid AND C.roleid IN (1)
	END
	ELSE IF @RoleId = 1 -- For Member
	BEGIN
		INSERT INTO #MemberTemp(CustID)
		SELECT C.custid
		FROM CustInfoMini C WITH (NOLOCK)
		WHERE C.custid = @custid AND C.roleid IN (1)
	END

	--Update for SMA
	IF @roleid IN (4,3,2)
	BEGIN
		WHILE (1 = 1)
		BEGIN
			TRUNCATE TABLE #SMAList_Update

			DELETE TOP (2000) #SMAList
			OUTPUT deleted.CustID
			INTO #SMAList_Update (CustID)
	
			IF @@ROWCOUNT = 0 BREAK
	
			BEGIN TRY
				UPDATE C 
					SET C.[site] = @site
				FROM #SMAList_Update mu
					INNER JOIN CustinfoMini C WITH (ROWLOCK, UPDLOCK) ON mu.CustID = C.custid
			END TRY
			BEGIN CATCH
				SET @ErrCode = 110
				RETURN
			END CATCH
		END
	END

	--Update for member
	WHILE (1 = 1)
	BEGIN
		TRUNCATE TABLE #MemberUpdated

		DELETE TOP (2000) 
		#MemberTemp
		OUTPUT deleted.CustID
		INTO #MemberUpdated(CustID)
	
		IF @@ROWCOUNT = 0 BREAK
	
		BEGIN TRY
			UPDATE C SET C.[site] = @site
			FROM #MemberUpdated mu
				INNER JOIN CustinfoMini C WITH (ROWLOCK, UPDLOCK) ON mu.CustID = C.custid
		END TRY 
		BEGIN CATCH
			SET @ErrCode = 110
			RETURN
		END CATCH
	END

	DROP TABLE #MemberTemp
	DROP TABLE #MemberUpdated
	DROP TABLE #SMAList
	DROP TABLE #SMAList_Update
END

GO

