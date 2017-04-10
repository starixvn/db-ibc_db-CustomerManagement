/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,API_Vender" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Dot_Member_Credit_Match_Check_cust]
	@custid int,
	@matchid int,
	@sporttype int,
	@isLicensee bit = 1, ----Identify deposit customer
	@recommend int,
	@mrecommend int,
	@srecommend int,
	@currency int
AS
BEGIN
	SET NOCOUNT ON;	
	
	-- 20120506@vivi: get balance from new table
	-- 20121023@vivi: coz will launch new balance for credit first only, so add @isLicensee parameter to split query data from bettrans or new balance table
	-- 20121202@TWJoe: set @isLicensee = 1 , switch control at SP
	
	-- 20130226@Vivi: if need get balance from bettrans table, plesae remove this comment -- set @isLicensee = 1
	-- 20130723@Vivi: add select max turnover on super on the match from DownlineTurnOver_Setting
	-- 20130926@TWJoe: remove custinfo for custdb
	-- 20131128@TWJoe: remove exchange for custdb
	-- 20140219@TWJoe: lic for keno
	-- 20140502@TWJoe: change maxTurnover rule
	-- 20140604@Lukas: performance tunning, [DownlineTurnOver_Setting] this function only support for credit customer, remove licensee checking.
	-- 20141121@TWJOE: change column totalTurnover to HouseTurnover
	-- 20150622@TWJOE: add check translog for superlive
	-- 20151014@TWJoe(DBTRANS): new balance
	-- 20151014@TWJoe(DBTRANS): Get Lic Balance exec Dot_Intg_TransGroup_GetFinalBalance
	-- 20151204@TWJoe(DBTRANS): Lic using new balance
	-- 20160107@TWJoe(DBTRANS): Hotfix for superlive,sum translog totalbet ticket only running ticket
	-- 20170410@Don(DBTRANS): Remove code block to get Max Turnover on Super/Master/Agent
	


	DECLARE @Balance money, @totalbetpermatch money,@totalbetpermatch_translog money
	
	-- deposit using bettrans to query balance
	/*
	IF @isLicensee = 1
	BEGIN
		-- 101:reject, 102:void
		Set @Balance = 0

		select	
				--@Balance=(isnull(sum(b.winlost-b.actual_stake+b.playercomm),0)),
				@totalbetpermatch=IsNull(SUM(case when (b.matchid=@matchid and b.statusID not in (101, 102)) then (CASE WHEN b.odds < -1 THEN ABS(b.odds) ELSE 1 END * b.stake) else 0 end),0)
		from	
				bettrans b with (nolock) 
				where b.custid=@custid

		select	
				@totalbetpermatch_translog=IsNull(SUM(case when (t.eventID=@matchid and t.statusID not in (101, 102)) then (CASE WHEN t.odds < -1 THEN ABS(t.odds) ELSE 1 END * t.stake) else 0 end),0)
		from	
				translog t with (nolock) 
				where t.custid=@custid

		--select 
		--		@Balance = @Balance-isnull(sum(isnull(actual_stake,0)) ,0)
		--from
		--		translog with (nolock) 
		--		where custid=@custid
		--		and statusID=0
		EXEC Dot_Intg_TransGroup_GetFinalBalance_Test @custid, @Balance out, @OutStanding out, @MaxTrans out
	END
	ELSE IF @isLicensee = 0 --credit site using new balance
	BEGIN
		SET @OutStanding=0
		-- get balance from new table
		--SELECT @BalanceCredit = Balance FROM BalanceCredit with (nolock) WHERE custid = @custid
		--SELECT @BalanceDebit = Balance FROM BalanceDebit WHERE custid = @custid
		--SELECT @Balance = IsNull(@BalanceCredit,0) - IsNull(@BalanceDebit,0)
		EXEC Dot_BalanceMemberSel @custid, @Balance out
		-- get totalbetpermatch from bettrans
		SELECT @totalbetpermatch = IsNull(SUM(CASE WHEN odds < -1 THEN ABS(odds) ELSE 1 END * stake),0)
		FROM bettrans with (nolock)
		WHERE matchid = @matchid and custid = @custid and statusID not in (101, 102) -- 101:reject,102:void

		SELECT @totalbetpermatch_translog = IsNull(SUM(CASE WHEN odds < -1 THEN ABS(odds) ELSE 1 END * stake),0)
		FROM translog with (nolock)
		WHERE eventID = @matchid and custid = @custid and statusID not in (101, 102) -- 101:reject,102:void

	END
	*/

	EXEC Dot_BalanceMemberSel @custid, @Balance out
	SELECT @totalbetpermatch = IsNull(SUM(CASE WHEN odds < -1 THEN ABS(odds) ELSE 1 END * stake),0)
	FROM bettrans with (nolock)
	WHERE matchid = @matchid and custid = @custid and statusID not in (101, 102) -- 101:reject,102:void

	SELECT @totalbetpermatch_translog = IsNull(SUM(CASE WHEN odds < -1 THEN ABS(odds) ELSE 1 END * stake),0)
	FROM translog with (nolock)
	WHERE eventID = @matchid and custid = @custid and statusID = 0
	
	SELECT	
		@Balance as finalbalance,
		@totalbetpermatch + @totalbetpermatch_translog as totalbetpermatch

END
GO