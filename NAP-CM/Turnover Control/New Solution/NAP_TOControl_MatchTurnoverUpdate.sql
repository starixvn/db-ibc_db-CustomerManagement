/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_MatchTurnoverUpdate]
	@CustID INT,
	@MatchID INT,
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Don
	Date: 2017-03-23
	Task: Update MaxTurnover for Super/Master/Agent
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @PercentageUsed MONEY
	DECLARE @LogData NVARCHAR(4000)
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID, @funcname='[TurnoverMonitor]', @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF EXISTS (SELECT 1 FROM DBAGE.bodb02.dbo.match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'completed')
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'You are not allowed to update max turnover of a settled match.'
		RETURN
	END

	IF @MaxTurnover = 0
	BEGIN
		UPDATE dbo.TOControl_Setting WITH(ROWLOCK, UPDLOCK)
		SET 
			MaxTurnover = @MaxTurnover,
			IsNotified = 0
		WHERE CustID = @CustID AND matchid = @MatchID
	END
	ELSE
	BEGIN
		UPDATE dbo.TOControl_Setting WITH(ROWLOCK, UPDLOCK)
		SET 
			@PercentageUsed = (HouseTurnOver*100/@MaxTurnover),
			MaxTurnover = @MaxTurnover,
			IsNotified = 
				CASE	
					WHEN @MaxTurnover > MaxTurnover THEN   --- reset isNotified only in case of increasing MaxTurnover
						CASE	
							WHEN @PercentageUsed >= 100 THEN 100
							WHEN @PercentageUsed >= 80 THEN 80
							WHEN @PercentageUsed >= 60 THEN 60
							WHEN @PercentageUsed >= 40 THEN 40
							ELSE 0
						END 
					ELSE IsNotified 
				END
		WHERE CustID = @CustID AND matchid = @MatchID
	END

	SELECT @LogData = '<NAP_TOControl_MatchTurnoverUpdate MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" '
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
							
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @UserID,
		@Custid = @CustID,
		@ActionID = 671,
		@TrackingValue = @LogData,
		@Duration = @duration				
						
END
GO