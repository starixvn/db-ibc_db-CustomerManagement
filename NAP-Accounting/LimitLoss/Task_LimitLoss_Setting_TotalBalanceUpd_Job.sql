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
	DECLARE @BalanceCust TABLE (CustID INT, NewTotalBalance MONEY, NewLevelID TINYINT)
	DECLARE @Cust_tmp TABLE (srecommend INT, mrecommend INT, recommend INT, roleid TINYINT)
	DECLARE @MaxLevel TINYINT, @i TINYINT
	SELECT @i = min(LevelID), @MaxLevel = max(LevelID) FROM LimitLoss_ActionConfig WITH (NOLOCK)

	INSERT INTO @Cust_tmp (srecommend, mrecommend, recommend, roleid)
	SELECT c.srecommend, c.mrecommend, c.recommend, c.roleid
	FROM LimitLoss_Setting s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON s.custid = c.custid

	INSERT INTO @BalanceCust (CustID, NewTotalBalance, NewLevelID)
	SELECT srecommend, sum(superCash + masterCash + agentCash + memberCash)	AS TotalBalance, 0
	FROM
		(
			SELECT	b.srecommend, b.mrecommend, b.recommend,
					sum(case when b.custid=b.srecommend then winlost-actual_stake else swinlost+scomm-acomm end) superCash,
					sum(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm-comm end) masterCash,
					sum(case when b.custid=b.recommend  then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
					sum(case when b.custid <> b.recommend and b.custid <> b.mrecommend and b.custid <> b.srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND t.roleid = 4)
			GROUP BY b.srecommend, b.mrecommend, b.recommend
		)Balance
	GROUP BY srecommend

	UNION ALL
	SELECT mrecommend, sum(superCash + masterCash + agentCash + memberCash)	AS TotalBalance, 0
	FROM
		(
			SELECT	b.srecommend, b.mrecommend, b.recommend,
					sum(case when b.custid=b.srecommend then winlost-actual_stake else swinlost+scomm-acomm end) superCash,
					sum(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm-comm end) masterCash,
					sum(case when b.custid=b.recommend  then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
					sum(case when b.custid <> b.recommend and b.custid <> b.mrecommend and b.custid <> b.srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND t.roleid = 3)
			GROUP BY b.srecommend, b.mrecommend, b.recommend
		)Balance
	GROUP BY mrecommend

	UNION ALL
	SELECT recommend, sum(superCash + masterCash + agentCash + memberCash)	AS TotalBalance, 0
	FROM
		(
			SELECT	b.srecommend, b.mrecommend, b.recommend,
					sum(case when b.custid=b.srecommend then winlost-actual_stake else swinlost+scomm-acomm end) superCash,
					sum(case when b.custid=b.mrecommend then winlost-actual_stake else mwinlost+acomm-comm end) masterCash,
					sum(case when b.custid=b.recommend  then winlost-actual_stake else awinlost+comm-playercomm end) agentCash,
					sum(case when b.custid <> b.recommend and b.custid <> b.mrecommend and b.custid <> b.srecommend and ruben=1 then winlost-actual_stake+playercomm else 0 end) memberCash
	
			FROM bodb02.dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN @Cust_tmp t ON (b.srecommend = t.srecommend AND b.mrecommend = t.mrecommend AND b.recommend = t.recommend AND t.roleid = 2)
			GROUP BY b.srecommend, b.mrecommend, b.recommend
	)Balance
	GROUP BY recommend

	WHILE (@i<@MaxLevel)
	BEGIN
		UPDATE b
		SET NewLevelID = @i
		FROM @BalanceCust b
			INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
		WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i)
			AND CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) < (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i+1)

		SET @i = @i+1
	END

	UPDATE b
	SET NewLevelID = @MaxLevel
	FROM @BalanceCust b
		INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
	WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @MaxLevel)

	UPDATE l
	SET TotalBalance = b.NewTotalBalance,
		LevelID = b.NewLevelID
	FROM LimitLoss_Setting l WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @BalanceCust b ON l.CustID = b.CustID
END