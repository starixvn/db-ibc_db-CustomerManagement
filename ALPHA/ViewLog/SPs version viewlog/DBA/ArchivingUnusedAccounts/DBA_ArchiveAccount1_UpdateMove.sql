ALTER PROCEDURE [dbo].[DBA_ArchiveAccount1_UpdateMove]
	@AccName varchar(50),
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
	Created by: Theo
	Date: 2009-30-07
	Task: Moving data from custsetting to custsetting_old 
	DB: DB02.BODB02
	
	Revisions:
		- 20091222@Jamie: separate 3rd custsetting to custsetting3rd_old 
		- 20100107@Kiwi: Amend writing log.
*/
    
SET NOCOUNT ON

Declare @roleid int, @AgentID int, @Enabled bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 0
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has been archived!!', @ErrCode = 101
	print @ErrMsg
	return
END

print  @AccName +':'+ 'START:' + convert(varchar(50), getdate(), 113)
--=============================
--PERFORM MOVING MEMBERS
--=============================


--Copy custSetting data to bodb_Customer before delete
insert into bodb_Customer.dbo.custSetting_old(
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
select 	custid, 
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
from	custSetting (nolock) 
where	custid IN (	select custid from custinfo with (nolock) where roleid = 1 and recommend = @AgentID)

--Copy custSetting3rd data to bodb_Customer 
INSERT INTO bodb_Customer.dbo.custSetting3rd_old(
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
SELECT	[custid]
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
FROM	CustSetting3rd WITH (NOLOCK)
WHERE	custid IN (SELECT custid FROM custInfo WITH (NOLOCK) WHERE roleid = 1 and recommend = @AgentID)		

Exec Acc_ExecRep_01 @AgentID = @AgentID, @Type = 0 
----------------------------------------------------------------
print  @AccName +':'+ 'END:' + convert(varchar(50), getdate(), 113)

------------------
declare @LogSPData varchar(2000)

Select @LogSPData = '<DBA_ArchiveAccount1_UpdateMove AccName="' + convert(varchar(30),@AccName)
					 + '" UserID="' + convert(varchar(30), @UserID) 
					 + '" ErrMsg="' + convert(varchar(400), @ErrMsg)
					 + '" ErrCode="' + convert(varchar(30),@ErrCode) + '"/>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1501,
	@TrackingValue = @LogSPData	

GO 
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount1_UpdateMove] TO [vnteam]
GO 