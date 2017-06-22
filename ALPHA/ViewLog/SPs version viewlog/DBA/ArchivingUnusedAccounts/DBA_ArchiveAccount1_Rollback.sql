ALTER PROCEDURE [dbo].[DBA_ArchiveAccount1_Rollback]
	@AccName varchar(50),	
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
/*
Created: 20090813@[Thien]
Task : The SP to rollback (restored) archived agent with member downline
DB: DB02.bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]  
	- 20091224@Jamie: Separate 3rd Custsetting 
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

--REVIEW THIS SP WHEN THERE IS NEW CUSTSETTING DATA ADDED


Declare @roleid int, @AgentID int, @Now datetime, @Enabled bit, @custID int --member's custID

SELECT	@roleid = roleid, @AgentID = custid, @Enabled = Enabled
FROM	custinfo WITH (NOLOCK)
WHERE	username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has NOT been archived or has been RESTORED BACK already!!', @ErrCode = 101
	print @ErrMsg
	return
END

CREATE TABLE #Setting (isBase bit, SettingType tinyint, bettype tinyint, sporttype tinyint)

CREATE TABLE #Setting3rd (isBase bit, SettingType tinyint, bettype tinyint, sporttype tinyint)


INSERT INTO #Setting (isBase, SettingType, bettype, sporttype)
select 
	case when (sporttype = 1 and bettype = 1)
			  or(sporttype = 1 and bettype = 4)
              or(sporttype = 1 and bettype = 5)  then 1
		 else 0
		 end ,
	case when bettype in (1,2,3,7,8) then 1
		when bettype in (4,6,9,10,20,21,22) then 2
		when bettype = 5 then 3
		else 0
		end ,
	bettype,
	sporttype
from	custsetting with (nolock) where custid = 73104
order by sporttype, bettype

INSERT INTO #Setting3rd (isBase, SettingType, bettype, sporttype)
select 
	case when	(sporttype = 151 and bettype = 31)
				or (sporttype = 151 and bettype = 41)
				or (sporttype = 201 and bettype = 3)  then 1
		 else 0
		 end,
	case when bettype in (31, 32) and sporttype = 151 then 4
		 when bettype in (41, 42) and sporttype = 151 then 5
		 when sporttype = 201 then 6
		 else 0
		 end,
	bettype,
	sporttype
from custsetting3rd with (nolock) where custid = 73104
order by sporttype, bettype

print  @AccName +':'+ 'Start:' + convert(varchar(50), getdate(), 113)

-----------------------------------------
--=============================
--PERFORM ROLLING BACK MEMBERS
--=============================
-----------------------
--Update back the enabled to 1
-----------------------
WHILE (1=1)
BEGIN
	UPDATE TOP(10000) custinfo WITH (UPDLOCK,ROWLOCK) SET [enabled] = 1 WHERE recommend = @AgentID and [enabled] = 0
	IF @@ROWCOUNT < 10000
		BREAK
END 

DECLARE Member_Cursor CURSOR  FOR
SELECT custid
FROM   custinfo c WITH (NOLOCK)	
WHERE  c.recommend = @AgentID AND c.roleid = 1

OPEN Member_Cursor
FETCH NEXT FROM Member_Cursor INTO @custid

WHILE @@FETCH_STATUS = 0
BEGIN
   INSERT INTO dbo.custSetting (
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
			isautolivempositiontaking )
	SELECT  /*cs.bettype, cs.sporttype, s.SettingType,*/ 
			custid, 
			s.bettype, 
			s.sporttype, 
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
    FROM	custSetting cs WITH (NOLOCK),
			#Setting s WITH (NOLOCK),
			#Setting s_base WITH (NOLOCK)	
    WHERE	s.SettingType = s_base.SettingType
			AND s_base.isBase = 1
			AND custid = @custid
			AND cs.bettype = s_base.bettype
			AND cs.sporttype = s_base.sporttype 
			AND NOT (s.bettype = s_base.bettype AND s.sporttype = s_base.sporttype)
    ORDER BY s.settingType
	
	--3rd CustSetting
   INSERT INTO dbo.custSetting3rd (
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
	SELECT 	custid, 
			s.bettype, 
			s.sporttype, 
			apositiontaking, 
			mpositiontaking, 
			spositiontaking, 
            playerdiscount, 
			discount, 
			adiscount, 
			sdiscount, 
			minbet, 
			maxbet, 
			autopositiontaking,
			isautopositiontaking, 
			autompositiontaking, 
			isautompositiontaking
    FROM	custSetting3rd cs WITH (NOLOCK),
			#Setting3rd s WITH (NOLOCK),
			#Setting3rd s_base WITH (NOLOCK)	
    WHERE	s.SettingType = s_base.SettingType
			AND s_base.isBase = 1
			AND custid = @custid
			AND cs.bettype = s_base.bettype
			AND cs.sporttype = s_base.sporttype 
			AND NOT (s.bettype = s_base.bettype AND s.sporttype = s_base.sporttype)
    ORDER BY s.settingType
 
    FETCH NEXT FROM Member_Cursor INTO @custid
END
CLOSE Member_Cursor

DEALLOCATE Member_Cursor
--------------

declare @LogSPData varchar(2000)
Select @LogSPData = '<DBA_ArchiveAccount1_Rollback AccName="' + convert(varchar(30),@AccName)
					 + '" UserID="' + convert(varchar(30), @UserID) 
					 + '" ErrMsg="' + convert(varchar(400), @ErrMsg)
					 + '" ErrCode="' + convert(varchar(30),@ErrCode) + '"/>'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1503,
	@TrackingValue = @LogSPData

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount1_Rollback] TO [vnteam]
GO
