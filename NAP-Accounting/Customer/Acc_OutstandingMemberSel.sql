/*<info serverAlias="DBBOF-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_OutstandingMemberSel]
	@CustId			INT
	,@Outstanding	MONEY = 0 OUTPUT
AS

/*
	Created: 20190723@Percy
	DB: DBBOF.bodb02
	Task: Get a specific member's outstanding
		
	Revisions:
		- 20190723@Percy: Initialize SP [RedmineID: #117334]
		- 20201005@Danny: Change to use alias DBBOF alternative to DB042 [RedmineID: #139516]
		
*/

BEGIN
	SET NOCOUNT ON

	-- bettransRnG
	SELECT @Outstanding = ISNULL(@Outstanding, 0) + ISNULL(SUM(ABS(actual_stake)), 0)
	FROM dbo.bettransRnG WITH (NOLOCK)
	WHERE custid = @CustId
		AND statusID IN (0, 1)

	-- bettransLC
	SELECT @Outstanding = ISNULL(@Outstanding, 0) + ISNULL(SUM(ABS(actual_stake)), 0)
	FROM dbo.bettransLC WITH (NOLOCK)
	WHERE custid = @CustId
		AND statusID IN (0, 1)

	-- translog
	SELECT @Outstanding = ISNULL(@Outstanding, 0) + ISNULL(SUM(ABS(actual_stake)), 0)
	FROM dbo.translog WITH (NOLOCK)
	WHERE custid = @CustId
		AND statusID IN (0, 1)

	-- bettrans
	SELECT @Outstanding = ISNULL(@Outstanding, 0) + ISNULL(SUM(ABS(actual_stake)), 0)
	FROM dbo.bettrans b WITH (NOLOCK)
	WHERE custid = @CustId
		AND statusID IN (0, 1)
		AND NOT EXISTS (SELECT 1 FROM dbo.SportBettypeMatrix s WITH (NOLOCK) WHERE b.bettype = s.bettype AND s.RefTable <> 0)
	
	-- Return data
	SELECT @Outstanding = ISNULL(@Outstanding, 0)
END
GO