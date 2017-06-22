ALTER PROCEDURE [dbo].[DBA_ArchiveAccount2_ClearBalance]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
--Pre-check needed:
	--+Closed status
	--+Active transactions: bet, transfer
--Post-check needed:
	--+Check the REAL total balance of super: need to be clear also by Ah Wan
	--+For DIRECT Master: transfer to Parent Currency. Then need to ask Ah Wan to clear the Currency Super Agent

--Updated@2009-11-07: new version just support to archive AGENT account.
    --+ And just clear MEMBER BALANCE. SKIP Agent Balance
print  'Start:' + convert(varchar(50), getdate(), 113)

Declare @roleid int, @AgentID int, @Amount MONEY,
		@custid int, @recommend int, @mrecommend int, @srecommend int, 
		@currency int, @actualrate float, @currencyName nvarchar(10),
		@membername varchar(50), @agentname varchar(50), @mastername varchar(50), @supername varchar(50),
		@memberBalance MONEY, @agentBalance MONEY, @masterBalance MONEY

Declare @refno bigint, @grefno int, @Now datetime, @Enabled bit


SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid <> 2 or @Enabled = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101	
	return
END

if exists (
		select 1
		from bettrans (nolock)
		where custid = @AgentID
		having count(*) > 2
		)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'There is active transactions. Please re-check!!', @ErrCode = 101
	return
END

--==========================================================
--CREATING TEMP TABLES
--==========================================================

CREATE TABLE #Member 
(
	custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int, 
	currency int, actualrate float, currencyName nvarchar(10),
	membername varchar(50), agentname varchar(50), mastername varchar(50), supername varchar(50), 
	memberBalance MONEY default 0
)

IF @roleid <> 2 RETURN 0
	
IF @roleid = 2
BEGIN
	INSERT INTO #Member 
	      (custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
		   membername, agentname, mastername, supername)
	SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, c.currency,e.actualrate, e.currency,
			c.username, ag.username, mag.username, sag.username
	FROM custinfo c (nolock)
		inner join custinfo ag (nolock) on c.recommend = ag.custid
		inner join custinfo mag (nolock) on c.mrecommend = mag.custid
		inner join custinfo sag (nolock) on c.srecommend = sag.custid
		inner join exchange e  (nolock) on c.currency = e.exchangeid 
	WHERE  c.recommend = @AgentID AND c.roleid = 1
	
END	

print @AccName +':'+ 'Temp Table Done:' + convert(varchar(50), getdate(), 113)	

Update #Member set memberBalance = b.MemberBalance
from #Member
	inner join (
		Select custid, isnull(SUM(isnull(case when ruben=0 then 0 else winlost-actual_stake+playercomm end, 0)), 0) as MemberBalance
		From bettrans with (NOLOCK)
		group by custid
		) b on #Member.custid = b.custid	

print @AccName +':'+ 'Member Balance Done:' + convert(varchar(50), getdate(), 113)	

-- Start Transfer (CURSOR Loop) 
SET @Now = CURRENT_TIMESTAMP

--------------------------START:MEMBER-AGENT-------------------------------

DECLARE CS_custid
	CURSOR FOR
	SELECT custid, recommend, mrecommend, srecommend, currency, actualrate, currencyName,
		   membername, agentname, memberBalance
	FROM #Member
	WHERE memberBalance <> 0		

OPEN CS_custid
FETCH NEXT FROM CS_custid INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName, 
							   @membername, @agentname, @memberBalance

WHILE @@FETCH_STATUS = 0
BEGIN		
	
	print @AccName +':'+ 'MEMBER-AGENT-->Member:' + @membername + ' ' + cast(@memberBalance as varchar(30))
	
		UPDATE ref with (rowlock, UPDLOCK)  SET   @grefno=transcode=transcode+1
		WHERE  refid='acc'
		if @@Error <> 0
		BEGIN
			delete bettrans where refno = @refno and matchid = 0
			return
		END
		select @refno=200000000000+@grefno
	
		IF (@memberBalance > 0) 
		BEGIN
			INSERT INTO bettrans 
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				comstatus, status, ruben, winlostdate, currency, actualrate, currencyName, 
				recommend, mrecommend, srecommend, scomm, swinlost,ip)
			VALUES (0, @UserID, @recommend, @agentname, @refno, @Now, 104, 'For Delete Account - From Customer::'+@membername, @memberBalance, 0, 
				@refno, '', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,'')
			if @@Error <> 0
			BEGIN
				RaisError (@ErrMsg, 16, 1)
				delete bettrans where refno = @refno and matchid = 0
				return
			END
			
			INSERT INTO bettrans
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				comstatus, status, ruben, winlostdate, currency, actualrate, currencyName,
				recommend, mrecommend, srecommend, scomm, swinlost,ip)
			VALUES 
			   (0, @UserID, @custid, @membername, @refno, @Now, 104, 'For Delete Account - To Customer::'+@agentname, 0, @memberBalance,
				@refno, '', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,'')
			if @@Error <> 0
			BEGIN
				RaisError (@ErrMsg, 16, 1)
				delete bettrans where refno = @refno and matchid = 0
				return
			END
							
		END
		ELSE if (@memberBalance<0) 
		BEGIN
			SET @memberBalance = abs(@memberBalance) 			
			INSERT INTO bettrans 
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				comstatus, status, ruben, winlostdate, currency, actualrate, currencyName, 
				recommend, mrecommend, srecommend, scomm, swinlost,ip)
			VALUES 
			   (0, @UserID, @recommend, @agentname, @refno, CURRENT_TIMESTAMP, 104, 'For Delete Account - To Customer::'+@membername, 0, @memberBalance,
				@refno, '', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,'')
			if @@Error <> 0
			BEGIN
				RaisError (@ErrMsg, 16, 1)
				delete bettrans where refno = @refno and matchid = 0
				return
			END
			
			INSERT INTO bettrans
			   (matchid, creator, custid, username, refno, transdate, bettype, transdesc, winlost, actual_stake, 
				comstatus, status, ruben, winlostdate, currency, actualrate, currencyName,
				recommend, mrecommend, srecommend, scomm, swinlost,ip)
			VALUES 
			   (0, @UserID, @custid, @membername, @refno, CURRENT_TIMESTAMP, 104, 'For Delete Account - From Customer::'+@agentname, @memberBalance, 0,
				@refno, '', 1, convert(nvarchar(10), @Now,120), @currency, @actualrate, @currencyName,
				@recommend, @MRecommend, @srecommend, 0, 0,'')
			if @@Error <> 0
			BEGIN
				RaisError (@ErrMsg, 16, 1)
				delete bettrans where refno = @refno and matchid = 0
				return
			END
			
		END		
		
	FETCH NEXT FROM CS_custid INTO @custid, @recommend, @mrecommend, @srecommend, @currency, @actualrate, @currencyName,
								   @membername, @agentname, @memberBalance
END

CLOSE CS_custid
DEALLOCATE CS_custid
--------------------------END:MEMBER-AGENT-------------------------------	
print @AccName +':'+ 'Member cursor Done:' + convert(varchar(50), getdate(), 113)

DROP TABLE #Member

------------------
declare @LogSPData varchar(5000)

Select @LogSPData = '<DBA_ArchiveAccount2_ClearBalance AccName="'+ coalesce(cast(@AccName as varchar(50)),space(1))+ '" ' +
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+ '" ' +
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))  + '"/>'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1502,
	@TrackingValue = @LogSPData
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount2_ClearBalance] TO [vnTeam]
