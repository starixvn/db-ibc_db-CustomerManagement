ALTER PROCEDURE [dbo].[DBA_ArchiveAccount2_UpdateMove]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: []
	Date: []
	Task: Archive unused Account in Stage 2 
	DB: DB02.BODB02 
	
	Revisions:
		- 20091224@Jamie: Separate 3rd CustSetting 
		- 20100107@Kiwi: Amend writing log.

	Note: Review the SP again once executing as maybe new fields were added to customer or custinfo table.
*/
SET NOCOUNT ON

Declare @roleid int, @AgentID int, @Now datetime, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid <> 2 or @Enabled = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END


print  @AccName +':'+ 'Start:' + convert(varchar(50), getdate(), 113)

--==========================================================
--CREATING TEMP TABLES
--==========================================================

CREATE TABLE #Member 
(
	custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int,
	membername varchar(50), agentname varchar(50), mastername varchar(50), supername varchar(50), 
	transCount int default 0
)
		
IF @roleid = 2
BEGIN
	INSERT INTO #Member (custid, recommend, mrecommend, srecommend, 
						membername, agentname, mastername, supername)
	SELECT c.custid, c.recommend, c.mrecommend, c.srecommend, 
			c.username, ag.username, mag.username, sag.username
	FROM custinfo c (nolock)
		inner join custinfo ag (nolock) on c.recommend = ag.custid
		inner join custinfo mag (nolock) on c.mrecommend = mag.custid
		inner join custinfo sag (nolock) on c.srecommend = sag.custid
	WHERE  c.recommend = @AgentID AND c.roleid = 1
	
END
		
--==========================================================
--CHECK TransCOUNT FIRST, MAKE SURE ALL BALANCE ARE CLEARED
--==========================================================

-- CHECK MEMBER BALANCE	
Update #Member set transCount = b.transCount
from #Member
	inner join (
		Select custid, count(*) as transCount
		From bettrans with (NOLOCK)
		group by custid
		) b on #Member.custid = b.custid	

--select * from #Member
if exists(select 1 from #Member where transCount > 0)
BEGIN
	print @AccName +':'+ 'Error: Unlcleared member''s TransCOUNT exist!'
	Select @ErrMsg = @AccName +':'+ 'Unlcleared member''s TransCOUNT exist!', @ErrCode = 101
	return
END	

print @AccName +':'+ 'Check members TransCOUNT done:' + convert(varchar(50), getdate(), 113)	
	

--=============================
--PERFORM MOVING MEMBERS
--=============================

select @Now = current_timestamp

--Copy members'info to bodb_Customer before delete
insert into bodb_Customer.dbo.customer_old(
	   [custid],[firstname],[lastname],[address] ,[postal],[city]
      ,[state] ,[country]  ,[phone]   ,[mobilephone] ,[fax]
      ,[email] ,[birthday] ,[refcode1],[refcode2],[remark]
      ,[creatdate],[creator],[username],[currency],[userpwd]
      ,[lastlogged],[pwdexpiry],[roleid],[mrecommend],[recommend]
      ,[ugroup],[logincount],[on_sessionid],[site],[iplogin]
      ,[important],[srecommend],[question],[answer],[positiontakingallowday]
      ,[positiontakingallowtime1],[positiontakingallowtime2],[Gender],[UTN],[username2]
      ,[transferoption]
)
select [custid],[firstname],[lastname],[address] ,[postal],[city]
      ,[state] ,[country]  ,[phone]   ,[mobilephone] ,[fax]
      ,[email] ,[birthday] ,[refcode1],[refcode2],[remark]
      ,[creatdate],[creator],[username],[currency],[userpwd]
      ,[lastlogged],[pwdexpiry],[roleid],[mrecommend],[recommend]
      ,[ugroup],[logincount],[on_sessionid],[site],[iplogin]
      ,[important],[srecommend],[question],[answer],[positiontakingallowday]
      ,[positiontakingallowtime1],[positiontakingallowtime2],[Gender],[UTN],[username2]
      ,[transferoption] 
from	customer (nolock) where custid IN (select custid from #Member with (nolock))
IF @@Error<>0
BEGIN
	Select	@ErrMsg = 'Failed INSERT from CUSTOMER table to CUSTOMER_OLD table', 
			@ErrCode = 102
	return
END 

insert into bodb_Customer.dbo.custinfo_old(
	   [ArchiveDate]
	  ,[username],[custid],[currency],[roleid],[srecommend]
      ,[mrecommend],[recommend],[dangercust],[autosuspend],[reject]
      ,[credit],[closed],[MatchLimit],[VirtualMultiplier],[maxpermatch]
      ,[maxpermatch2],[maxpermatch3],[maxpermatch5],[maxpermatch8],[maxpermatch10]
      ,[maxpermatch11],[maxpermatch12],[maxpermatch99],[AffiliateID],[MaxCredit]
      ,[Enabled],[danger],[maxpermatch151],[maxpermatch201],[DisableHorseRacing]
      ,[DisableFinancial],[DisableCasino],[SyncCasino],[danger2],[danger3]
      ,[DisableOutright]
)
select	@Now, 
	   [username],[custid],[currency],[roleid],[srecommend]
      ,[mrecommend],[recommend],[dangercust],[autosuspend],[reject]
      ,[credit],[closed],[MatchLimit],[VirtualMultiplier],[maxpermatch]
      ,[maxpermatch2],[maxpermatch3],[maxpermatch5],[maxpermatch8],[maxpermatch10]
      ,[maxpermatch11],[maxpermatch12],[maxpermatch99],[AffiliateID],[MaxCredit]
      ,[Enabled],[danger],[maxpermatch151],[maxpermatch201],[DisableHorseRacing]
      ,[DisableFinancial],[DisableCasino],[SyncCasino],[danger2],[danger3]
      ,[DisableOutright]  
from	custinfo (nolock) where custid IN (select custid from #Member with (nolock))
IF @@Error<>0
BEGIN
	Select	@ErrMsg = 'Failed INSERT from CUSTINFO table to CUSTINFO_OLD table', 
			@ErrCode = 103
	return
END 
Exec Acc_ExecRep_01 @AgentID = @AgentID, @Type = 1 

print @AccName +':'+ 'Move members done:' + convert(varchar(50), getdate(), 113)	
----------------------------------------------------------------
DROP TABLE #Member
--------------
declare @LogSPData varchar(2000)

Select @LogSPData = '<DBA_ArchiveAccount2_UpdateMove AccName="' + convert(varchar(30),@AccName)
					 + '" UserID="' + convert(varchar(30), @UserID) 
					 + '" ErrMsg="' + convert(varchar(400), @ErrMsg)
					 + '" ErrCode="' + convert(varchar(30),@ErrCode) + '"/>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1501,
	@TrackingValue = @LogSPData	

GO 
GRANT EXECUTE ON [dbo].[DBA_ArchiveAccount2_UpdateMove] TO [VNTeam]
GO
GRANT EXECUTE ON [dbo].[DBA_ArchiveAccount2_UpdateMove] TO [bodbAdminNet]