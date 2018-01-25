/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_HouseTOByBettypeSelect]
(
	@CustID INT,
	@matchid INT,
	@IsGroupHeadline BIT = 0,
	@EventDate DATETIME
)	
AS

/*
	Created: Helen
	Date: 2017-09-21
	Task: Retrieve balance information - [Redmine:75557]
	DB: DBAGE.bodb02
	
	Revisions:
		- 20171215@Helen: Implement some change request from OPS Team - [Redmine: 85638]
		
	Parameter's explaination: 
	
		
*/
BEGIN
	SET NOCOUNT ON
	-- Process for Headline Level
	IF @IsGroupHeadline = 1
	BEGIN
		EXEC dbo.NAP_TOControl_HouseTOByBettypeForHeadlineLevelSelect @CustID= @CustID,@matchid = @matchid,@IsGroupHeadline = 1, @EventDate = @EventDate 
	END
	-- Process for Super/Master/Agent Level
	ELSE 
	BEGIN
		EXEC dbo.NAP_TOControl_HouseTOByBettypeForSMALevelSelect @CustID= @CustID,@matchid = @matchid,@IsGroupHeadline = 0, @EventDate = @EventDate 
	END		
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_HouseTOByBettypeSelect] TO [bodbAdminNet]
GO
