/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DormantAccountList_InsertUpdate] (
	 @CustID		INT
	,@RoleID		TINYINT
	,@StageID		TINYINT 
	,@ProcessedDate DATETIME = NULL
	,@ArchivedDate	DATE = NULL
	,@IsOverwrite	BIT = 0
)
AS
/*
	Created: 20201209@Eden
	Task : Insert data to Cust_ArchiveAccount by archive process.
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
	- 20201209@Eden: Alpha Site | Implement Dormant Account List [RedmineID: #144903]
	- 20210617@Eden: Enhance the archiving account process on Stage 4 [RedmineID: #157123]
	- 20210614@Eden: All sites - Dormant SMA Account List [RedmineID: #155969]

	Parameter Definition

	Example: 
		EXEC Acc_DormantAccountList_InsertUpdate 
			@CustId = 46773170,
			@RoleID = 2,
			@StageID = 1,
			@ProcessedDate = '2020/12/01 10:00:00',
			@ArchivedDate = '2020/12/01'
	
	*/
BEGIN
	SET NOCOUNT ON

	IF @StageID NOT IN (1,2,3,4)
		RETURN

	DECLARE @TotalDownline INT

	--> Process for S4
	IF @StageID = 4 
	BEGIN
		IF @RoleID = 2
		BEGIN
			UPDATE c
			SET AccountDeletedDate = @ProcessedDate,
				ArchivedDate = @ArchivedDate,
				StageID = @StageID
			FROM Cust_ArchiveAccount c WITH(ROWLOCK)
			WHERE c.recommend = @CustID
				AND c.roleid IN (1,2)
		END
		ELSE
		BEGIN
			UPDATE c
			SET AccountDeletedDate = @ProcessedDate,
				ArchivedDate = @ArchivedDate,
				StageID = @StageID
			FROM Cust_ArchiveAccount c WITH(ROWLOCK)
			WHERE c.CustID = @CustID
		END

		RETURN
	END

	--> Process for S1/S2/S3
	IF @RoleID = 2
	BEGIN
		SELECT @TotalDownline = COUNT(c1.custid)
		FROM custinfo c1 WITH(NOLOCK)
		WHERE c1.roleid = 1
			AND c1.recommend = @CustID

		UPDATE c
		SET ClosedDate = CASE WHEN @StageID = 1 AND (@IsOverwrite = 1 OR c.ClosedDate IS NULL) THEN @ProcessedDate ELSE c.ClosedDate END,
			DisabledDate = CASE WHEN @StageID = 2 AND (@IsOverwrite = 1 OR c.DisabledDate IS NULL) THEN @ProcessedDate ELSE c.DisabledDate END, 
			SettingDeletedDate = CASE WHEN @StageID = 3 AND (@IsOverwrite = 1 OR c.SettingDeletedDate IS NULL) THEN @ProcessedDate ELSE c.SettingDeletedDate END,
			StageID = CASE WHEN @StageID > c.StageID THEN @StageID ELSE c.StageID END,
			TotalDownline = CASE WHEN c.RoleID = 2 THEN @TotalDownline ELSE 0 END,
			ReducedCredit = CASE WHEN @StageID = 2 AND c.ReducedCredit IS NULL THEN ci.credit ELSE c.ReducedCredit END,
			ArchivedDate = @ArchivedDate,
			recommend = ci.recommend,
			mrecommend = ci.mrecommend,
			srecommend = ci.srecommend,
			Username = CASE WHEN @StageID = 3 THEN ci.username ELSE c.Username END,
			Lastlogged = CASE WHEN @StageID = 3 THEN cu.Lastlogged ELSE c.Lastlogged END
		FROM Cust_ArchiveAccount c WITH(ROWLOCK)
			INNER JOIN custInfo ci WITH(NOLOCK) ON c.CustID = ci.custid
			INNER JOIN Customer cu WITH(NOLOCK) ON c.CustID = cu.custid
		WHERE ci.recommend = @CustID
			AND ci.roleid IN (1,2)

		IF @StageID = 1
		BEGIN
			INSERT INTO Cust_ArchiveAccount(
				CustID, 
				StageID, 
				ClosedDate, 
				TotalDownline,
				RoleID,
				ArchivedDate,
				recommend,
				mrecommend,
				srecommend
			)
			SELECT c.CustID, 
				StageID = @StageID, 
				ClosedDate = @ProcessedDate, 
				TotalDownline = CASE WHEN c.roleid = 2 THEN @TotalDownline ELSE 0 END,
				c.roleid,
				@ArchivedDate,
				c.recommend,
				c.mrecommend,
				c.srecommend 
			FROM custinfo c WITH(NOLOCK)
			WHERE c.recommend = @CustID
				AND c.roleid IN (1,2)
				AND NOT EXISTS( SELECT 1 FROM Cust_ArchiveAccount WITH(NOLOCK) WHERE CustID = c.custid)
		END
	END
	IF @RoleID IN (3, 4)
	BEGIN
		IF @RoleID = 3
		BEGIN
			SELECT @TotalDownline = COUNT(c1.custid) 
			FROM custinfo c1 WITH(NOLOCK)
			WHERE c1.roleid IN (1,2)
				AND c1.mrecommend = @CustID
		END
		ELSE IF @RoleID = 4
		BEGIN
			SELECT @TotalDownline = COUNT(c1.custid) 
			FROM custinfo c1 WITH(NOLOCK)
			WHERE c1.roleid IN (1,2,3)
				AND c1.srecommend = @CustID
		END

		IF NOT EXISTS( SELECT 1 FROM Cust_ArchiveAccount WITH(NOLOCK) WHERE CustID = @CustID) AND @StageID = 1
		BEGIN
			INSERT INTO Cust_ArchiveAccount(
				CustID, 
				StageID, 
				ClosedDate, 
				TotalDownline,
				RoleID,
				ArchivedDate,
				recommend,
				mrecommend,
				srecommend
			)
			SELECT c.CustID, 
				StageID = @StageID, 
				ClosedDate = CASE WHEN @StageID = 1 THEN @ProcessedDate END, 
				TotalDownline = @TotalDownline,
				c.roleid,
				@ArchivedDate,
				c.recommend,
				c.mrecommend,
				c.srecommend 
			FROM custinfo c WITH(NOLOCK)
			WHERE c.custid = @CustID
		END
		ELSE
		BEGIN
			UPDATE c
			SET ClosedDate = CASE WHEN @StageID = 1 AND (@IsOverwrite = 1 OR c.ClosedDate IS NULL) THEN @ProcessedDate ELSE c.ClosedDate END,
				DisabledDate = CASE WHEN @StageID = 2 AND (@IsOverwrite = 1 OR c.DisabledDate IS NULL) THEN @ProcessedDate ELSE c.DisabledDate END, 
				SettingDeletedDate = CASE WHEN @StageID = 3 AND (@IsOverwrite = 1 OR c.SettingDeletedDate IS NULL) THEN @ProcessedDate ELSE c.SettingDeletedDate END,
				StageID = CASE WHEN @StageID > c.StageID THEN @StageID ELSE c.StageID END,
				TotalDownline = @TotalDownline,
				ReducedCredit = CASE WHEN @StageID = 2 AND c.ReducedCredit IS NULL THEN ci.credit ELSE c.ReducedCredit END,
				ArchivedDate = @ArchivedDate,
				recommend = ci.recommend,
				mrecommend = ci.mrecommend,
				srecommend = ci.srecommend,
				Username = CASE WHEN @StageID = 3 THEN ci.username ELSE c.Username END,
				Lastlogged = CASE WHEN @StageID = 3 THEN cu.Lastlogged ELSE c.Lastlogged END
			FROM Cust_ArchiveAccount c WITH(ROWLOCK)
				INNER JOIN custinfo ci WITH(NOLOCK) ON ci.custid = c.CustID
				INNER JOIN Customer cu WITH(NOLOCK) ON c.CustID = cu.custid
			WHERE c.custid = @CustID
		END
	END
END
GO


