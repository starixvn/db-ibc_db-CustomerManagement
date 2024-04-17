/*<info serverAlias="DBTXN-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO

ALTER PROCEDURE [dbo].[CS_Member_TotalBetStake_Sel]
	@CustId INT
AS

/*
	Created: 20190214@Percy
	DB: DBTXN.bodb02
	Task: Get Member bet stake

	Revisions:
		- 20190214@Percy: Initialize SP [RedmineID: #105338]
		- 20190531@Percy: Return YesterdayBetStake [RedmineID: #112225]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @today SMALLDATETIME, @yesterday SMALLDATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())
	SELECT  @yesterday = DATEADD(DAY, -1, @today)

	DECLARE @TotalBetStake MONEY = 0, @YesterdayBetStake MONEY, @ErrCode INT = 0

	/*
	-- for local testing
	DELETE dbo.DailyBetStake WITH (ROWLOCK, UPDLOCK)
	WHERE  CustId = @CustId AND Date BETWEEN @yesterday AND @today
	*/
	
	/* today */
	EXEC dbo.Dot_Member_CalcDailyBetStake @CustId = @CustId, @Date = @today, @Stake = 0, @TotalBetStake = @TotalBetStake OUTPUT, @ErrCode = @ErrCode OUTPUT

	-- try again for case violation of primary key when insert action
	IF @ErrCode <> 0
		EXEC dbo.Dot_Member_CalcDailyBetStake @CustId = @CustId, @Date = @today, @Stake = 0, @TotalBetStake = @TotalBetStake OUTPUT, @ErrCode = @ErrCode OUTPUT

	/* yesterday */
	EXEC dbo.Dot_Member_CalcDailyBetStake @CustId = @CustId, @Date = @yesterday, @Stake = 0, @TotalBetStake = @YesterdayBetStake OUTPUT, @ErrCode = @ErrCode OUTPUT

	-- try again for case violation of primary key when insert action
	IF @ErrCode <> 0
		EXEC dbo.Dot_Member_CalcDailyBetStake @CustId = @CustId, @Date = @yesterday, @Stake = 0, @TotalBetStake = @YesterdayBetStake OUTPUT, @ErrCode = @ErrCode OUTPUT
	
	/* Return data */
	SELECT @TotalBetStake AS TotalBetStake, @YesterdayBetStake AS YesterdayBetStake
END
GO