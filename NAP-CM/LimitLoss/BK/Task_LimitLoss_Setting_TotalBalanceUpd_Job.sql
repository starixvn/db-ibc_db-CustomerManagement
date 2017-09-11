ALTER PROCEDURE [dbo].[Task_LimitLoss_Setting_TotalBalanceUpd_Job]
AS
/*
	Created: Elodie
	Date: 20140522
	Task : Update total balance
	DB: DBAGE/bodb_AGE

	Revisions:
	
	Parameter's explaination: 
		
*/
BEGIN
	DECLARE @Setting_tmp TABLE (CustID INT, MaxLoss MONEY, OldLevelID TINYINT, OldHighestLevel TINYINT, OldHighestLevelLastUpd DATETIME)
	DECLARE @BalanceCust TABLE (CustID INT, NewTotalBalance MONEY, NewLevelID TINYINT)
	DECLARE @MaxLevel TINYINT, @i TINYINT
	SELECT @i = min(LevelID), @MaxLevel = max(LevelID) FROM LimitLoss_ActionConfig WITH (NOLOCK)

	INSERT INTO @Setting_tmp (CustID, MaxLoss, OldLevelID, OldHighestLevel, OldHighestLevelLastUpd)
	SELECT CustID, MaxLoss, LevelID, HighestLevel, HighestLevelLastUpd
	FROM LimitLoss_Setting WITH (NOLOCK)

	INSERT INTO @BalanceCust (CustID, NewTotalBalance, NewLevelID)
	SELECT CustID, sum(winlost - actual_stake + playercomm), 0
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE custid IN (SELECT CustID FROM @Setting_tmp)
	GROUP BY CustID

	WHILE (@i<@MaxLevel)
	BEGIN
		UPDATE b
		SET NewLevelID = @i
		FROM @BalanceCust b
			INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
		WHERE -b.NewTotalBalance/l.MaxLoss*100 >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i)
			AND -b.NewTotalBalance/l.MaxLoss*100 < (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i+1)

		SET @i = @i+1
	END

	UPDATE b
	SET NewLevelID = @MaxLevel
	FROM @BalanceCust b
		INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
	WHERE -b.NewTotalBalance/l.MaxLoss*100 >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @MaxLevel)

	UPDATE l
	SET TotalBalance = b.NewTotalBalance,
		LevelID = b.NewLevelID,
		IsDone = CASE WHEN b.NewLevelID > s.OldLevelID AND b.NewLevelID > s.OldHighestLevel THEN 0 ELSE IsDone END,
		HighestLevel = CASE WHEN (b.NewLevelID <> s.OldLevelID AND b.NewLevelID > s.OldHighestLevel) OR (s.OldHighestLevelLastUpd - getdate() >=5) THEN b.NewLevelID ELSE l.HighestLevel END,
		HighestLevelLastUpd = CASE WHEN (b.NewLevelID <> s.OldLevelID AND b.NewLevelID > s.OldHighestLevel) OR (s.OldHighestLevelLastUpd - getdate() >=5) THEN getdate() ELSE l.HighestLevelLastUpd END
	FROM LimitLoss_Setting l WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @BalanceCust b ON l.CustID = b.CustID
		INNER JOIN @Setting_tmp s ON l.CustID = s.CustID

END