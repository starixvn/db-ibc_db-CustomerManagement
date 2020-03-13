/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_AutoUpdateVirtualRate_ByExcel_InsTmp]
	 @SportType INT = 43
	,@SessionID UNIQUEIDENTIFIER = NULL
	,@UserID INT = NULL
	,@XML VARCHAR(MAX) = NULL
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
	,@ValidUser_Count INT = NULL OUTPUT
AS
/*   
	Create: 20200310@Eden
	Task : Import data from Excel file to VRSetting_AutoUpdate_ByExcel table
	DB: DBCUST/CustDB
	Revisions:
		- 20200310@Eden: Initial version [Redmine:#128749]
		
	Param's Explanation:
		@XML = '<Rt>
					<R UN="master1" Cell="A2" Mul="0.5" LId="1" BTGId="-1" BTId="9001" Live="1" />
				</Rt>'
	
*/
BEGIN
	SET NOCOUNT ON
	-- Delete trash data
	DELETE FROM VRSetting_AutoUpdate_ByExcel WITH(ROWLOCK) WHERE SessionID <> @SessionID AND ImportedBy = @UserID

	-- Insert from XML
	CREATE TABLE #VRSetting_AutoUpdate_ByExcel(
		CustId            INT, 
		Username          VARCHAR(30),
		CellID			  VARCHAR(10),
		VirtualMultiplier SMALLMONEY,
		VRLeagueGroupId   INT, 
		VRBettypeGroupId  INT, 
		Bettype           INT, 
		IsLive            BIT
	)

	DECLARE @DocHandler INT	

	--Parse input XML
	IF @XML <> ''
	BEGIN		
		BEGIN TRY		
			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @XML

			INSERT INTO #VRSetting_AutoUpdate_ByExcel (Username, CellID, VirtualMultiplier, VRLeagueGroupId, VRBettypeGroupId, Bettype, IsLive) 
			SELECT	 UN		
					,Cell	
					,NULLIF(Mul,0)
					,LId	
					,BTGId	
					,BTId	
					,Live	
			FROM OPENXML (@DocHandler, '/Rt/R',1) 
			WITH (
				UN		VARCHAR(30),
				Cell	VARCHAR(10),
				Mul		SMALLMONEY,
				LId		INT, 
				BTGId	INT, 
				BTId	INT, 
				Live	BIT
			) AS Data
		EXEC sp_xml_removedocument @DocHandler

		END TRY
		BEGIN CATCH
			SELECT @ErrMsg = N'Invalid XML format'
				, @ErrCode = 3  
			RETURN  
		END CATCH
	END	

	CREATE TABLE #Error(
		Username VARCHAR(30),
		CellID	VARCHAR(10),
		[Rule] VARCHAR(50),
		[Reason] VARCHAR(50)
	)

	-- Validate Data
	UPDATE tmp
	SET CustId = c.custid
	FROM #VRSetting_AutoUpdate_ByExcel tmp
		INNER JOIN customer c WITH(NOLOCK)
			ON c.username = tmp.Username

	DELETE a
	OUTPUT deleted.Username,deleted.CellID,'Invalid','Invalid username' INTO #Error(Username,CellID,[Rule],[Reason])
	FROM #VRSetting_AutoUpdate_ByExcel a
	WHERE CustId IS NULL

	DELETE a
	OUTPUT deleted.Username,deleted.CellID,'Exist in manually updated list','Manually updated account' INTO #Error(Username,CellID,[Rule],[Reason])
	FROM #VRSetting_AutoUpdate_ByExcel a
		INNER JOIN VRSettingManualUpdAcc vr WITH(NOLOCK)
			ON vr.[CustID] = a.CustId
			AND vr.SportType = @SportType

	;WITH TMP AS (
		SELECT Username,
			CellID,
			ROW_NUMBER() OVER(PARTITION BY Username ORDER BY CellID) AS RowNum
		FROM #Error
	)
	DELETE a 
	FROM #Error a
		INNER JOIN TMP b ON a.Username = b.Username
		AND a.CellID = b.CellID
	WHERE b.RowNum <> 1


	DECLARE @MinValue SMALLMONEY,@MaxValue SMALLMONEY
	SELECT @MinValue = MIN(Value),@MaxValue = MAX(Value) FROM VRValueMapping vrv WITH(NOLOCK)

	DELETE a
	OUTPUT deleted.Username,deleted.CellID,'Not in allowed VR value list','Invalid value' INTO #Error(Username,CellID,[Rule],[Reason])
	FROM #VRSetting_AutoUpdate_ByExcel a
	WHERE VirtualMultiplier < @MinValue OR VirtualMultiplier > @MaxValue

	SELECT * FROM #Error

	INSERT INTO VRSetting_AutoUpdate_ByExcel(
			SessionID, 
			CustId, 
			IsLive, 
			SportType, 
			LevelID, 
			VirtualMultiplier, 
			ImportedBy
	)
	SELECT @SessionID, 
			t.CustId, 
			t.IsLive, 
			@SportType, 
			h.LevelID,
			t.VirtualMultiplier, 
			@UserID
	FROM #VRSetting_AutoUpdate_ByExcel t
		INNER JOIN VRSettingHierarchy h WITH(NOLOCK)	
			ON t.VRLeagueGroupId = h.VRLeagueGroupID
			AND t.VRBettypeGroupId = h.VRBetTypeGroupID
			AND t.Bettype = h.BetType
			AND h.SportType = @SportType

	
	SELECT @ValidUser_Count = COUNT(DISTINCT CustID)
	FROM #VRSetting_AutoUpdate_ByExcel
	
	DROP TABLE #VRSetting_AutoUpdate_ByExcel
	DROP TABLE #Error

END
GO
