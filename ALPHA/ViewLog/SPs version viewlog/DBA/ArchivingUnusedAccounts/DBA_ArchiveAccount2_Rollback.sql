ALTER PROCEDURE [dbo].[DBA_ArchiveAccount2_Rollback]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: Theo
	Date:	2009-08-13
	Task: Rollback in STAGE 2 
	DB: DB02.BODB02
	Revisions:
		- 20091229@Jamie: Edit Rollback together with Custsetting and Custsetting3rd
	NOTE: 
	--Review the SP again once executing as maybe new fields were added to customer or custinfo table
	--Generate and Run custsetting data manually, by using Local 204 Db or ask the backup DB from Joe
		--+Script can be done by SQL Studio for SQL Server - DB Extract for SQL server
	--Delete manually from bodb_Customer.dbo.customer_old and bodb_Customer.dbo.custinfo_old

*/

Declare @roleid int, @AgentID int, @Now datetime, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2,3,4)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has NOT been archived!!', @ErrCode = 101
	print @ErrMsg
	return
END

print  @AccName +':'+ 'Start:' + convert(varchar(50), getdate(), 113)


--==========================================================
--CREATING TEMP TABLES
--==========================================================

	CREATE TABLE #Member (custid int PRIMARY KEY, recommend int, mrecommend int, srecommend int)
	CREATE TABLE #Agent (recommend int PRIMARY KEY, mrecommend int, srecommend int)
	
	CREATE TABLE #Master (mrecommend int PRIMARY KEY, srecommend int)
		
	IF @roleid NOT IN (2,3,4) RETURN 0
		
	IF @roleid = 2
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM bodb_Customer.dbo.custinfo_old c (nolock)			
		WHERE  c.recommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend 
		FROM custinfo c (nolock)			
		WHERE  c.recommend = @AgentID AND c.roleid = 2		
		
	END
	IF @roleid = 3
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM bodb_Customer.dbo.custinfo_old c (nolock)		
		WHERE c.mrecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend 
		FROM custinfo c (nolock)
		WHERE  c.mrecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend)
		SELECT distinct c.mrecommend, c.srecommend
		FROM custinfo c (nolock)
		WHERE  c.mrecommend = @AgentID AND c.roleid = 3
		
	END
	IF @roleid = 4
	BEGIN
		INSERT INTO #Member (custid, recommend, mrecommend, srecommend)
		SELECT c.custid, c.recommend, c.mrecommend, c.srecommend
		FROM bodb_Customer.dbo.custinfo_old c (nolock)
		WHERE c.srecommend = @AgentID AND c.roleid = 1
		
		INSERT INTO #Agent (recommend, mrecommend, srecommend)
		SELECT distinct c.recommend, c.mrecommend, c.srecommend 
		FROM custinfo c (nolock)
		WHERE  c.srecommend = @AgentID AND c.roleid = 2
		
		INSERT INTO #Master (mrecommend, srecommend)
		SELECT distinct c.mrecommend, c.srecommend
		FROM custinfo c (nolock)
		WHERE  c.srecommend = @AgentID AND c.roleid = 3
	END
	

-----------------------------------------
--=============================
--PERFORM ROLLING BACK MEMBERS
--=============================
DECLARE	@Step INT, @minCustID INT, @maxCustID INT, @index INT
SELECT	@index = 0 
SELECT  @minCustID = MIN(CustID), @maxCustID = MAX(CustID) FROM #Member WITH (NOLOCK)
SELECT	@Step = 1000
--Copy back the customer and custinfo
WHILE (@minCustID + @Step*@index <= @maxCustID )
BEGIN
	SET IDENTITY_INSERT customer ON
		insert into customer (
			custid, firstname, lastname, address, postal, city, state, country, phone, mobilephone, 
			fax, email, birthday, refcode1, refcode2, remark, creatdate, creator, username, currency, 
			userpwd, lastlogged, pwdexpiry, roleid, mrecommend, recommend, ugroup, logincount, on_sessionid, site, 
			iplogin, important, srecommend, question, answer, positiontakingallowday, positiontakingallowtime1,
			positiontakingallowtime2, Gender, UTN, username2, transferoption
		)
		select 
			custid, firstname, lastname, address, postal, city, state, country, phone, mobilephone, 
			fax, email, birthday, refcode1, refcode2, remark, creatdate, creator, username, currency, 
			userpwd, lastlogged, pwdexpiry, roleid, mrecommend, recommend, ugroup, logincount, on_sessionid, site, 
			iplogin, important, srecommend, question, answer, positiontakingallowday, positiontakingallowtime1,
			positiontakingallowtime2, Gender, UTN, username2, transferoption
		from	bodb_Customer.dbo.customer_old (nolock)
		where	custid IN (	select	custid from #Member WITH (NOLOCK) 
							where	custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
						)
	SET IDENTITY_INSERT customer OFF

	insert into custinfo (
			username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, 
			autosuspend, reject, credit, closed, MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, 
			maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12, maxpermatch99, AffiliateID,					MaxCredit, [Enabled])
	SELECT  username, custid, currency, roleid, srecommend, mrecommend, recommend, dangercust, 
			autosuspend, reject, credit, closed, MatchLimit, VirtualMultiplier, maxpermatch, maxpermatch2, 
			maxpermatch3, maxpermatch5, maxpermatch8, maxpermatch10, maxpermatch11, maxpermatch12, maxpermatch99, AffiliateID,
			MaxCredit, [Enabled]
	from	bodb_Customer.dbo.custinfo_old (nolock)
	where	custid IN (	select	custid from #Member WITH (NOLOCK) 
						where	custid between @minCustID + @Step*@index and (@minCustID - 1) + @Step*(@index + 1)	
					)
	SELECT	@index = @index + 1 
	WAITFOR DELAY '000:00:02'
END 

-----------------------
--Update back the enabled to 1
-----------------------
update custinfo set enabled = 1 where custid IN(select recommend from #Agent)

if @roleid >= 3 
	update custinfo set enabled = 1 where custid IN(select mrecommend from #Master)
	
if @roleid = 4
BEGIN
	update custinfo set enabled = 1 where custid IN(select distinct srecommend from #Master)
	
	IF @@ROWCOUNT = 0
		update custinfo set enabled = 1 where custid = @AgentID
END
---------------------------
--ROLLBACK CustSetting and CustSetting3rd 
---------------------------
SELECT	@Step = 20,@index = 0 
WHILE (@minCustID + @Step*@index <= @MaxCustID )
BEGIN
	INSERT INTO CustSetting(
		custid, 
		bettype, 
		sporttype, 
		apositiontaking, 
		mpositiontaking, 
		spositiontaking, 
		alivepositiontaking, 
		mlivepositiontaking, 
		slivepositiontaking,
		playerdiscount, 
		discount, 
		adiscount, 
		sdiscount, 
		groupa, 
		groupb, 
		groupc, 
		groupd, 
		groupe, 
		groupf, 
		minbet, 
		maxbet, 
		autopositiontaking,
		autolivepositiontaking, 
		isautopositiontaking, 
		isautolivepositiontaking, 
		autompositiontaking, 
		autolivempositiontaking, 
		isautompositiontaking,
		isautolivempositiontaking
	)
	SELECT	custid, 
			bettype, 
			sporttype, 
			apositiontaking, 
			mpositiontaking, 
			spositiontaking, 
			alivepositiontaking, 
			mlivepositiontaking, 
			slivepositiontaking,
			playerdiscount, 
			discount, 
			adiscount, 
			sdiscount, 
			groupa, 
			groupb, 
			groupc, 
			groupd, 
			groupe, 
			groupf, 
			minbet, 
			maxbet, 
			autopositiontaking,
			autolivepositiontaking, 
			isautopositiontaking, 
			isautolivepositiontaking, 
			autompositiontaking, 
			autolivempositiontaking, 
			isautompositiontaking,
			isautolivempositiontaking
	FROM	bodb_Customer.dbo.CustSetting_old WITH (NOLOCK)
	WHERE	custid IN (	SELECT	custid FROM #Member WITH (NOLOCK)
						WHERE	custid BETWEEN @minCustID + @Step*@index AND (@minCustID - 1) + @Step*(@index + 1)) 

	INSERT INTO CustSetting3rd(
	   [custid]
	  ,[bettype]
	  ,[sporttype]
	  ,[apositiontaking]
	  ,[mpositiontaking]
	  ,[spositiontaking]
	  ,[playerdiscount]
	  ,[discount]
	  ,[adiscount]
	  ,[sdiscount]
	  ,[minbet]
	  ,[maxbet]
	  ,[autopositiontaking]
	  ,[isautopositiontaking]
	  ,[autompositiontaking]
	  ,[isautompositiontaking]
	)
	SELECT [custid]
		  ,[bettype]
		  ,[sporttype]
		  ,[apositiontaking]
		  ,[mpositiontaking]
		  ,[spositiontaking]
		  ,[playerdiscount]
		  ,[discount]
		  ,[adiscount]
		  ,[sdiscount]
		  ,[minbet]
		  ,[maxbet]
		  ,[autopositiontaking]
		  ,[isautopositiontaking]
		  ,[autompositiontaking]
		  ,[isautompositiontaking]
	FROM	bodb_Customer.dbo.CustSetting3rd_Old WITH (NOLOCK)
	WHERE	custid IN (	SELECT	custid FROM #Member WITH (NOLOCK)
						WHERE	custid BETWEEN @minCustID + @Step*@index AND (@minCustID - 1) + @Step*(@index + 1)) 
	SELECT	@index = @index + 1
	WAITFOR DELAY '000:00:02'
END
------------------
declare @LogSPData varchar(4000)
Select @LogSPData = '<DBA_ArchiveAccount2_Rollback AccName="' + convert(varchar(30),@AccName)
					 + '" UserID="' + convert(varchar(30), @UserID) 
					 + '" ErrMsg="' + convert(varchar(400), @ErrMsg)
					 + '" ErrCode="' + convert(varchar(30),@ErrCode) + '"/>'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1504,
	@TrackingValue = @LogSPData	

GO
GRANT EXECUTE ON [dbo].[DBA_ArchiveAccount2_Rollback] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount2_Rollback] TO [vnTeam]
GO