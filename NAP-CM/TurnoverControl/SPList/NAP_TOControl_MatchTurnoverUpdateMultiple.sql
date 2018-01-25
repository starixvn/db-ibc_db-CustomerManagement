/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_MatchTurnoverUpdateMultiple]
(
	@GlobalSetting VARCHAR(MAX) = '',
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: Helen
	Date: 2017-09-20
	Task: Update multiple MaxTurnover for Super/Master/Agent
	DB: DBCUST.CustDB

	Revisions:
		- 20171115@Vicky: change location check permission [RedmineID: #86455]
		- 20171215@Helen: Implement some change request from OPS Team - [Redmine: 85638]
		
	Parameter's explaination:
	
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #GlobalSettingTbl (ID INT IDENTITY(1,1) PRIMARY KEY,CustID INT, IsGroupHeadline BIT, MaxTurnover MONEY, MatchID INT,SportType SMALLINT)
	
	CREATE TABLE #ExistingGlobalSettingTbl (ID INT IDENTITY(1,1) PRIMARY KEY, CustID INT, IsGroupHeadline BIT, MaxTurnover MONEY, MatchID INT, SportType SMALLINT)
	
	--Parse XML	
	DECLARE @iDoc INT, @start INT, @end INT, @MaxTurnover MONEY, @IsGroupHeadline BIT, @CustID INT, @MatchID INT,@SportType SMALLINT
	
	SET @start = 1
	SET @MaxTurnover = 0 
	SET @IsGroupHeadline = 0
	
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @GlobalSetting

	INSERT #GlobalSettingTbl (CustId,MatchId,IsGroupHeadline,MaxTurnover,SportType)
	SELECT CustId,MatchId,IsGroupHeadline,MaxTurnover,SportType
	FROM OPENXML(@iDoc, '/ROOT/GlobalSetting', 1) WITH (CustId INT,MatchId INT, IsGroupHeadline	BIT, MaxTurnover MONEY,SportType SMALLINT)

	EXEC sp_xml_removedocument @iDoc	
	
	INSERT #ExistingGlobalSettingTbl (CustID,IsGroupHeadline,MaxTurnover,MatchID,SportType)
	SELECT custid,IsGroupHeadline,MaxTurnover,MatchID,SportType
	FROM #GlobalSettingTbl GS_tmp WITH (NOLOCK)
	WHERE EXISTS (	SELECT 1 
						FROM dbo.TOControl_GlobalSetting GS WITH (NOLOCK) 
						WHERE gs.CustID = GS_tmp.custid 
							AND GS_tmp.IsGroupHeadline = GS.IsGroupHeadLine
							AND GS_tmp.MaxTurnover <> GS.MaxTurnOver
							AND GS_tmp.SportType = GS.Sporttype
					)
	
	-- Process for UPDATE multiple MaxTurnOver
	IF EXISTS (SELECT 1 FROM #ExistingGlobalSettingTbl)
	BEGIN
		SET @end = (SELECT MAX(ID) FROM #ExistingGlobalSettingTbl WITH (NOLOCK))
		
		WHILE @start <= @end
		BEGIN
	
			SELECT @CustID = CustID, @MaxTurnover = MaxTurnover, @IsGroupHeadline = IsGroupHeadline, @MatchID = MatchID,@SportType = SportType FROM #ExistingGlobalSettingTbl WITH (NOLOCK) WHERE ID = @start
			
			EXEC dbo.NAP_TOControl_MatchTurnoverUpdate @CustID = @CustID, @UserID=@UserID,@SportType = @SportType, @IP=@IP,@MaxTurnover=@MaxTurnover,@IsGroupHeadline = @IsGroupHeadline,@MatchID = @MatchID,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
			
			IF @ErrCode <> 0 
				BREAK
			
			SET @start = @start + 1
		END
	END
	ELSE
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'No action occured.'
		
		RETURN
	END
	
	DROP TABLE #ExistingGlobalSettingTbl
	DROP TABLE #GlobalSettingTbl
						
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_MatchTurnoverUpdateMultiple] TO [bodbAdminNet]
GO
