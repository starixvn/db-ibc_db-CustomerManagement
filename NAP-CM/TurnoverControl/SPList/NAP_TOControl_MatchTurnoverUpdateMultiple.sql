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

	Parameter's explaination:
	
*/
BEGIN
	SET NOCOUNT ON

	SET NOCOUNT ON

	CREATE TABLE #GlobalSettingTbl (ID INT IDENTITY(1,1) PRIMARY KEY,CustID INT, IsGroupHeadline BIT, MaxTurnover MONEY, MatchID INT)
	
	CREATE TABLE #ExistingGlobalSettingTbl (ID INT IDENTITY(1,1) PRIMARY KEY, CustID INT, IsGroupHeadline BIT, MaxTurnover MONEY, MatchID INT)
	
	--Parse XML	
	DECLARE @iDoc INT, @start INT, @end INT, @MaxTurnover MONEY, @IsGroupHeadline BIT, @CustID INT, @MatchID INT
	
	SET @start = 1
	SET @MaxTurnover = 0 
	SET @IsGroupHeadline = 0
	
	
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @GlobalSetting

	INSERT #GlobalSettingTbl (CustID,IsGroupHeadline,MaxTurnover,MatchID)
	SELECT CustID,IsGroupHeadline,MaxTurnover,MatchID
	FROM OPENXML(@iDoc, '/ROOT/GlobalSetting', 1) WITH (CustID INT, IsGroupHeadline	BIT, MaxTurnover MONEY, MatchID INT)

	EXEC sp_xml_removedocument @iDoc	
	
	INSERT #ExistingGlobalSettingTbl (CustID,IsGroupHeadline,MaxTurnover,MatchID)
	SELECT custid,IsGroupHeadline,MaxTurnover,MatchID
	FROM #GlobalSettingTbl GS_tmp WITH (NOLOCK)
	WHERE EXISTS (	SELECT 1 
						FROM dbo.TOControl_GlobalSetting GS WITH (NOLOCK) 
						WHERE gs.CustID = GS_tmp.custid 
							AND GS_tmp.IsGroupHeadline = GS.IsGroupHeadLine
							AND GS_tmp.MaxTurnover <> GS.MaxTurnOver
					)
	
	-- Process for UPDATE multiple MaxTurnOver
	IF EXISTS (SELECT 1 FROM #ExistingGlobalSettingTbl)
	BEGIN
		SET @end = (SELECT MAX(ID) FROM #ExistingGlobalSettingTbl WITH (NOLOCK))
		
		WHILE @start <= @end
		BEGIN
	
			SELECT @CustID = CustID, @MaxTurnover = MaxTurnover, @IsGroupHeadline = IsGroupHeadline, @MatchID = MatchID FROM #ExistingGlobalSettingTbl WITH (NOLOCK) WHERE ID = @start
			
			EXEC dbo.NAP_TOControl_MatchTurnoverUpdate @CustID = @CustID, @UserID=@UserID,@IP=@IP,@MaxTurnover=@MaxTurnover,@IsGroupHeadline = @IsGroupHeadline,@MatchID = @MatchID,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
			
			IF @ErrCode <> 0 
				BREAK
			
			SET @start = @start + 1
		END
	END
	
	DROP TABLE #ExistingGlobalSettingTbl
	DROP TABLE #GlobalSettingTbl
						
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_MatchTurnoverUpdateMultiple] TO [bodbAdminNet]
GO