/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_SMATurnoverUpd]
	@CustID INT,
	@MatchID INT,
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Update max turnover for SMA
	DB: DBAGE/bodb02

	Revisions:
		- 20140630@Lukas: add 1 more specific level for notification - 95% [Redmine:#18384]
		- 20141001@Dom: Change House TO
		- 20170313@Don: add more specific levels for notification - [Redmine:#72812]

	Parameter's explaination: 
	
*/
SET NOCOUNT ON
BEGIN
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[TurnoverMonitor]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
		
	IF EXISTS (SELECT 1 FROM match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'completed')
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'You are not allowed to update max turnover of a settled match.'
		RETURN
	END

	UPDATE DownlineTurnover_Setting WITH(ROWLOCK,UPDLOCK)
	SET MaxTurnover = @MaxTurnover,
		IsNotified = CASE	WHEN @MaxTurnover <> 0 AND @MaxTurnover > MaxTurnover THEN   --- reset isNotified only in case of increasing maxturnover
								CASE	WHEN (HouseTurnOver/@MaxTurnover)*100 >= 100 THEN 100
										WHEN (HouseTurnOver/@MaxTurnover)*100 >= 80 THEN 80
										WHEN (HouseTurnOver/@MaxTurnover)*100 >= 60 THEN 60
										WHEN (HouseTurnOver/@MaxTurnover)*100 >= 40 THEN 40
										ELSE 0
								END 
							ELSE IsNotified 
					END
	WHERE CustID = @CustID AND matchid = @MatchID
	
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnoverUpd MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" '
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
							
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @UserID,
		@Custid = @CustID,
		@ActionID = 637,
		@TrackingValue = @LogData,
		@Duration = @duration				
						
END

