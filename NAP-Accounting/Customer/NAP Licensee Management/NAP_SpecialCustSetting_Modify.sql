/*<info serverAlias="DBCUST-CustDB" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0"></info>*/ 

USE CustDB
GO

ALTER PROCEDURE NAP_SpecialCustSetting_Modify
	@Licensee NVARCHAR(100),
	@CurrencyID INT,
	@AgentID INT = NULL,
	@Settings XML,
	@ErrCode INT = 0  OUTPUT,
	@ErrMsg NVARCHAR(MAX)=''  OUTPUT,
	@IP NVARCHAR(20),
	@UserID INT
AS
/*
	Created: Dom
	Date: 2014-09-03
	Task: 
	DB: DBCUST/CustDB
		
	Revisions:
		- 20180924@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]

*/

BEGIN
	IF(
		NOT EXISTS(SELECT TOP 1 1 FROM [Dep_CustBetLimit_Special] cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR (AgentID = @AgentID)) ) AND
		NOT EXISTS(SELECT TOP 1 1 FROM [Dep_CustBetLimitGameType_Special] cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND @AgentID IS NULL)
	)
	BEGIN
		EXEC [NAP_SpecialCustSetting_Add]
			@Licensee = @Licensee,
			@CurrencyID = @CurrencyID,
			@AgentID = @AgentID,
			@Settings = @Settings,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT,
			@IP = @IP,
			@UserID = @UserID
	END
	ELSE 
	BEGIN
		EXEC [NAP_SpecialCustSetting_Upd]
			@Licensee = @Licensee,
			@CurrencyID = @CurrencyID,
			@AgentID = @AgentID,
			@Settings = @Settings,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT,
			@IP = @IP,
			@UserID = @UserID
	END
END
GO
