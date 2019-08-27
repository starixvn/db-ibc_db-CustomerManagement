/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[CS_DynamicCustSetting_01]
	@CustId						INT,
	@RoleId						TINYINT,
	@ReasonId					TINYINT = NULL,
	@Comment					NVARCHAR(300) = NULL,

	@Action						VARCHAR(50),
	@AbnomalBetMember			VARCHAR(MAX) = NULL,
	@DirectMarkedCust			VARCHAR(MAX) = NULL,
	@ExcludeAbnormalMember		BIT = 0,
	@ExcludeDirectMark			BIT = 0,
	@IsSuccess					BIT = 1 OUTPUT,
	@SuccessDownlineList		VARCHAR(MAX) = '' OUTPUT
AS
/*
	Created: 20190808@Elodie
	DB: DBCUST/CustDB
	Task: Execrep SP

	Revisions:
		- 20190808@Elodie: Initial SP [Redmine:#116814]

	Param's Explanation:
		@Action: MarkProblem, RemoveReduceBetLimit
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @SetBit1 INT, @Pos TINYINT
	CREATE TABLE #DownlineCust (CustID INT PRIMARY KEY, RoleID TINYINT)
	CREATE TABLE #DownlineSuccess (CustID INT)
	CREATE TABLE #DirectMarkCust (CustID INT, RoleID TINYINT)

	IF dbo.f_CheckRepTable('custInfo') = 0 RETURN
	IF dbo.f_CheckRepTable('CS_ProblemAccount') = 0 RETURN
	
	IF @RoleID = 4 --Super			
	BEGIN
		INSERT INTO #DownlineCust (CustID, RoleID)
		SELECT custid, roleid
		FROM custInfo c WITH(NOLOCK)
		WHERE srecommend = @CustID AND c.custid <> @CustId
	END
	ELSE IF @RoleID = 3 --Master
	BEGIN
		INSERT INTO #DownlineCust (CustID, RoleID)
		SELECT custid, roleid
		FROM custInfo c WITH(NOLOCK)
		WHERE mrecommend = @CustID AND c.custid <> @CustId
	END
	ELSE IF @RoleID = 2 --Agent
	BEGIN
		INSERT INTO #DownlineCust (CustID, RoleID)
		SELECT custid, roleid
		FROM custInfo c WITH(NOLOCK)
		WHERE recommend = @CustID AND c.custid <> @CustId
	END	

	IF @Action = 'MarkProblem'
	BEGIN
		SELECT	@Pos = CASE @RoleId WHEN 4 THEN 3
									WHEN 3 THEN 2
									WHEN 2 THEN 1
									WHEN 1 THEN 0 END					
			
		SELECT @SetBit1 = POWER(2, @Pos)								

		BEGIN TRY			
			INSERT INTO dbo.CS_ProblemAccount (CustId, ProblemStatus, ReasonId, Comment, MaxBet, MaxPerEvent, CreatedDate, IsReviewed, IsAbnormalMember)
			SELECT @CustId, @SetBit1, @ReasonId, @Comment, NULL, NULL, GETDATE(), 0, 0
			WHERE NOT EXISTS (SELECT 1 FROM CS_ProblemAccount WHERE CustId = @CustId)

			IF @@ROWCOUNT = 0
			BEGIN
				UPDATE pa 
				SET pa.ProblemStatus = ProblemStatus | @SetBit1,
					pa.ReasonId = @ReasonId,
					pa.Comment = @Comment
				FROM dbo.CS_ProblemAccount pa WITH (ROWLOCK)
				WHERE CustId = @CustId
			END

			SELECT @IsSuccess = 1	
		END TRY
		BEGIN CATCH
			SELECT @IsSuccess = 0
			RETURN			
		END CATCH

		UPDATE pa 		
		SET pa.ProblemStatus = ProblemStatus | @SetBit1
		OUTPUT Inserted.CustId INTO #DownlineSuccess
		FROM dbo.CS_ProblemAccount pa WITH (ROWLOCK)
			INNER JOIN #DownlineCust t ON t.CustID = pa.CustId

		INSERT INTO dbo.CS_ProblemAccount (CustId, ProblemStatus, ReasonId, Comment, MaxBet, MaxPerEvent, CreatedDate, IsReviewed, IsAbnormalMember)
		OUTPUT Inserted.CustId INTO #DownlineSuccess
		SELECT CustId, @SetBit1, NULL, NULL, NULL, NULL, GETDATE(), 0, 0
		FROM #DownlineCust t
		WHERE NOT EXISTS (SELECT 1 FROM CS_ProblemAccount WHERE CustId = t.CustId)

		SELECT @SuccessDownlineList = STUFF((SELECT ','+ CAST(l.CustID AS VARCHAR(20))
											FROM #DownlineSuccess l
											FOR XML PATH('')),1,1,'')		
	END	
	ELSE IF @Action = 'RemoveReduceBetLimit'
	BEGIN
		UPDATE pa 
		SET pa.MaxBet = NULL,
			pa.MaxPerEvent = NULL
		FROM dbo.CS_ProblemAccount pa WITH (ROWLOCK)
			INNER JOIN #DownlineCust t ON t.CustId = pa.CustId		
	END
	ELSE IF @Action = 'UpdateReviewStatus'
	BEGIN
		UPDATE pa 		
		SET pa.IsReviewed = 1
		OUTPUT Inserted.CustId INTO #DownlineSuccess
		FROM dbo.CS_ProblemAccount pa WITH (ROWLOCK)
			INNER JOIN #DownlineCust t ON t.CustID = pa.CustId
		WHERE pa.IsReviewed = 0

		SELECT @SuccessDownlineList = STUFF((SELECT ','+ CAST(l.CustID AS VARCHAR(20))
											FROM #DownlineSuccess l
											FOR XML PATH('')),1,1,'')
	END
	ELSE IF @Action = 'UnmarkProblem'
	BEGIN
		IF @ExcludeAbnormalMember = 1
		BEGIN
			DELETE c 
			FROM #DownlineCust c
				INNER JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON pa.CustId = c.CustID
			WHERE pa.IsAbnormalMember = 1
		END	
		IF @ExcludeDirectMark = 1
		BEGIN
			INSERT INTO #DirectMarkCust (CustID, RoleID)
			SELECT c.CustID, c.RoleID
			FROM #DownlineCust c
				INNER JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON pa.CustId = c.CustID
			WHERE pa.ReasonId IS NOT NULL

			DELETE c 
			FROM #DownlineCust c
				INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.CustId = c.CustID
				INNER JOIN #DirectMarkCust dm WITH (NOLOCK) ON dm.CustId = CASE WHEN c.RoleID = 3 THEN ci.mrecommend
																				WHEN c.RoleID = 2 THEN ci.recommend END
				
			DELETE c 
			FROM #DownlineCust c
				INNER JOIN #DirectMarkCust dm WITH (NOLOCK) ON dm.CustID = c.CustID
		END	

		DELETE pa 
		OUTPUT Deleted.CustId INTO #DownlineSuccess
		FROM dbo.CS_ProblemAccount pa WITH (ROWLOCK)
			INNER JOIN #DownlineCust c ON c.CustID = pa.CustId

		SELECT @SuccessDownlineList = STUFF((SELECT ','+ CAST(l.CustID AS VARCHAR(20))
											FROM #DownlineSuccess l
											FOR XML PATH('')),1,1,'')
	END
	DROP TABLE #DownlineCust
END
GO