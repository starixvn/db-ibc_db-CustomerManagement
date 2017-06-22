ALTER PROCEDURE [dbo].[DBA_CustomerUpdMoveMaster]
	@supername	VARCHAR(40),
	@mastername VARCHAR(40),
	@userid		INT,
	@IP			VARCHAR(15)='',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(500) = '' OUTPUT
AS
/*
REMEMBER TO DEPLOY DBA_CustomerUpdMoveMaster_ExecRep_06 FIRST

Created: Thien @ 2009-12-08
Task : Move a master to another super
DB: DB02.bodb02
Original:

Revisions:
    - 20090525@Daniel: add check contraints for Horse & Finance
	- 20090528@Daniel: remove groupe, groupf when checking commission
	- 20090917@Phuc: Write log to dblog	
	- 20090923@Shifu: Remove check master synchronized casino constrain
	- 20090924@Jamie:  Not allowing moving master see if the total tickets under master exceed 20000
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091102@Kiwi: Remove RaisError and change to check total tickets from db02 to db052
	- 20091104@Jamie: Remove the input param @update out 
	- 20091107@Daniel: use @temp table to cache custids for updating.
	- 20091110@Daniel: Add check internal contraint
	- 20091112@Jamie: Check DisableOutright before moving
	- 200911224@Ken: Use loop to update in case number of tickets is huge
	- 20100109@Lewin: Change SP format data
	- 20091219@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).

Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    
• @ErrMsg: Error description.
*/

BEGIN
SET NOCOUNT ON


DECLARE @srecommend			INT, 
		@mrecommend			INT,
		@srecommend_old		INT, 
		@scurrency			TINYINT, 
		@mcurrency			TINYINT,
		@sdisableHR			BIT, 
		@mdisableHR			BIT, 
		@sdisableFI			BIT, 
		@mdisableFI			BIT,
		@sSyncCasino		BIT,
		@mSyncCasino		BIT,
		@sIsInternal		BIT,
		@mIsInternal		BIT,
		@sDisableOutright	BIT,
		@mDisableOutright	BIT
		

SELECT	@srecommend = custid, 
		@scurrency	= currency, 
		@sdisableHR = DisableHorseracing, 
		@sdisableFI = DisableFinancial,
		@sSyncCasino = SyncCasino,
		@sDisableOutright = DisableOutright 
FROM	custinfo WITH (NOLOCK) 
WHERE	username = @supername AND roleid = 4

SELECT	@mrecommend = custid, 
		@srecommend_old = srecommend, 
		@mcurrency	=	currency, 
		@mdisableHR = DisableHorseracing, 
		@mdisableFI = DisableFinancial,
		@mSyncCasino = SyncCasino,
		@mDisableOutright = DisableOutright
FROM	custinfo WITH (NOLOCK) 
WHERE	username = @mastername AND roleid = 3


IF ISNULL(@srecommend, 0) = 0
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super not found.',
		@ErrCode = 101					 
	RETURN
END

IF ISNULL(@mrecommend, 0) = 0
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master not found.',
		@ErrCode = 102					 	
	RETURN
END

IF ISNULL(@srecommend_old, 0) = @srecommend
BEGIN
	SELECT @ErrMsg = 'Error occurs. The master '+ @mastername +' already belongs to super '+ @supername +'.',
		@ErrCode = 103					 
	RETURN
END

IF ISNULL(@srecommend_old, 0) = @srecommend
BEGIN
	SELECT @ErrMsg = 'Error occurs. The master '+ @mastername +' already belongs to super '+ @supername +'.',
		@ErrCode = 103					 
	RETURN
END

--Check an account disabled or not 
EXEC dbo.Acc_CustomerSelCheckEnable @username = @mastername, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT 
IF @ErrCode <>0		RETURN 

EXEC dbo.Acc_CustomerSelCheckEnable @username = @supername, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT 
IF @ErrCode <>0		RETURN 


IF @scurrency <> @mcurrency
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': currency of super and master does not match.',
		@ErrCode = 104					 
	RETURN
END

--Check Internal status
SELECT @sIsInternal = IsInternal FROM CustSuper with (nolock) WHERE custid = @srecommend
SELECT @mIsInternal = IsInternal FROM CustMaster with (nolock) WHERE custid = @mrecommend
IF ISNULL(@sIsInternal, 0) = 1 AND ISNULL(@mIsInternal, 0) = 0
BEGIN
	SELECT @ErrMsg = 'Error occurs. Cannot move normal(betting) master to new internal super.',
		@ErrCode = 103					 
	RETURN
END

--Check Horse, FI status:
IF @sdisableHR = 1 AND @mdisableHR = 0
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Horse Racing but new super is not enabled Horse Racing.',
		@ErrCode = 108					 
	RETURN
END

--Check Casino sync:
IF @sSyncCasino = 0 AND @mSyncCasino = 1
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Casino but new super is not synchronized Casino.',
		@ErrCode = 108					 
	RETURN
END

IF @sdisableFI = 1 AND @mdisableFI = 0
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Finance but new super is not enabled Finance.',
		@ErrCode = 109
	RETURN
END


--Check Horse, FI, Casino sync status:
IF EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 151)
	AND NOT EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 151)
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Horse Racing setting.',
		@ErrCode = 110					 
	RETURN
END

IF EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 201)
	AND NOT EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 201)
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Finance setting.',
		@ErrCode = 111					 
	RETURN
END
--Check Casino Syn
if exists(select 1 from custinfo with (nolock) where custid = @mrecommend and SyncCasino = 1)
BEGIN
	Select @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is already Casino-synchronized.',
		@ErrCode = 112					 
	return
END

IF EXISTS (
		SELECT 1 
		FROM custsetting AS scs WITH (NOLOCK)
			INNER JOIN custsetting AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend 
														AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype 
		WHERE 
			(scs.bettype IN (1,2,3,7,8) AND ((scs.groupa<mcs.groupa) OR (scs.groupb<mcs.groupb) 
			OR (scs.groupc<mcs.groupc) OR (scs.groupd<mcs.groupd)))
			OR (scs.bettype NOT IN (1,2,3,7,8) AND scs.sdiscount<mcs.adiscount)
	)
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super commission is less than master commission.',
		@ErrCode = 105					 
	RETURN
END

--check commission for 3rd party
IF EXISTS (
		SELECT 1 
		FROM custsetting3rd AS scs WITH (NOLOCK)
			INNER JOIN custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend 
														AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype 
		WHERE scs.sdiscount<mcs.adiscount
	)
BEGIN
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super commission is less than master commission.',
		@ErrCode = 105					 
	RETURN
END

IF EXISTS (
		SELECT 1 FROM 
			custsetting AS scs WITH (NOLOCK)
			INNER JOIN custsetting AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
															AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
			INNER JOIN custoverride AS sco WITH (NOLOCK) ON scs.custid = sco.custid AND scs.sporttype = sco.sporttype AND scs.bettype = sco.bettype
		WHERE	
		--n4<=s3+m3<=s4	if i3=0
		(
			((mcs.isautopositiontaking=0) AND ((mcs.spositiontaking + mcs.mpositiontaking < sco.minpositiontaking) OR (mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking)))
			OR
			((mcs.isautolivepositiontaking=0) AND (mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND ((mcs.slivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking) OR (mcs.slivepositiontaking + mcs.mlivepositiontaking > scs.slivepositiontaking)))
		)
		--m3<=s4 and u3<=s4	if i3=1
		--u3+m3>=n4 if i3=1
		OR
		(
			((mcs.isautopositiontaking=1) AND ((mcs.mpositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking + mcs.mpositiontaking < sco.minpositiontaking)))
			OR
			((mcs.isautolivepositiontaking=1) AND (mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND ((mcs.mlivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking)))
		)	
		--m3<=m4
		OR
		(
			(mcs.mpositiontaking > scs.mpositiontaking)
			OR
			((mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND (mcs.mlivepositiontaking > scs.mlivepositiontaking))
		)	
)
BEGIN
	
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super positiontaking.',
		@ErrCode = 106				 
	RETURN
END

--Check Position Taking for 3rd party
	--n4<=s3+m3<=s4		if i3=0
	--m3<=s4 and u3<=s4	if i3=1
	--u3+m3>=n4 if i3=1
	--m3<=m4

IF EXISTS (
		SELECT 1 FROM 
			custsetting3rd AS scs WITH (NOLOCK)
			INNER JOIN custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
															AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
			INNER JOIN custoverride3rd AS sco WITH (NOLOCK) ON scs.custid = sco.custid AND scs.sporttype = sco.sporttype AND scs.bettype = sco.bettype
		WHERE
		--n4<=s3+m3<=s4	if i3=0
		(
			(mcs.isautopositiontaking=0) AND ((mcs.spositiontaking + mcs.mpositiontaking < sco.minpositiontaking) OR (mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking))
		)
		--m3<=s4 and u3<=s4	if i3=1
		--u3+m3>=n4 if i3=1
		OR
		(
			(mcs.isautopositiontaking=1) AND ((mcs.mpositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking + mcs.mpositiontaking < sco.minpositiontaking))
		)	
		--m3<=m4
		OR
		(
			mcs.mpositiontaking > scs.mpositiontaking
		)		
			
)
BEGIN
	
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super positiontaking.',
		@ErrCode = 106				 
	RETURN
END

--Check Position Taking	
	--all a2<=a4
	--all a1<=a4
IF EXISTS (
		SELECT 1 FROM 
			custsetting AS scs WITH (NOLOCK)
			INNER JOIN custsetting AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
															AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
			INNER JOIN custinfo AS c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) 
													AND c.mrecommend = @mrecommend --get member and agent			
		WHERE
		--all a<=a4
		(
			(acs.apositiontaking > scs.apositiontaking)
			OR
			((acs.sporttype =1) AND (acs.bettype IN (1,3,7,8)) AND (acs.alivepositiontaking > scs.alivepositiontaking))
		)		
)
BEGIN
	
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super positiontaking.',
		@ErrCode = 107					 
	RETURN
END

--Check Position Taking	for 3rd party
	--all a2<=a4
	--all a1<=a4
IF EXISTS (
		SELECT 1 FROM 
			custsetting3rd AS scs WITH (NOLOCK)
			INNER JOIN custsetting3rd AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
															AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
			INNER JOIN custinfo AS c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) 
													AND c.mrecommend = @mrecommend --get member and agent			
		WHERE acs.apositiontaking > scs.apositiontaking	
)
BEGIN
	
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super positiontaking.',
		@ErrCode = 107					 
	RETURN
END

--Declare @temp table to contain customer info before update.
DECLARE @CustInfo TABLE (CustID INT PRIMARY KEY)

INSERT INTO @CustInfo
SELECT custid FROM custinfo (NOLOCK)
WHERE mrecommend = @mrecommend

--customer table
UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend 
WHERE custid IN (SELECT CustID FROM @CustInfo)
IF @@ERROR <> 0 
BEGIN
    --ROLLBACK TRANSACTION MANUALLY
	UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
	WHERE mrecommend = @mrecommend
	
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (customer).',
		@ErrCode = 108					 
	RETURN
END

--custinfo table
UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend 
WHERE custid IN (SELECT CustID FROM @CustInfo)
IF @@ERROR <> 0 
BEGIN
     --ROLLBACK TRANSACTION MANUALLY
	UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
	WHERE mrecommend = @mrecommend
	
	UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
	WHERE mrecommend = @mrecommend
	
	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
		@ErrCode = 109					 
	RETURN
END

IF @sDisableOutright = 1 AND (@sDisableOutright <> @mDisableOutright)
BEGIN

	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET	DisableOutright = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
		SELECT	@ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
				@ErrCode = 115
	RETURN

END

--Check & update n4<=s1+m1+a1<=l4
EXEC dbo.Acc_CustomerUpdMaster_MinMaxPositiontaking @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdMasterFI_MinMaxPositiontaking @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdMasterHR_MinMaxPositiontaking @mrecommend = @mrecommend, @srecommend = @srecommend

--when separate code we must update db07.bodb02.dbo.custsetting 
update custsetting with (ROWLOCK, UPDLOCK) set sdiscount=adiscount 
where custid in (select custid from customer with (NOLOCK) where mrecommend = @mrecommend and roleid=1) and isnull(sdiscount, 0) < adiscount

update custsetting3rd with (ROWLOCK, UPDLOCK) set sdiscount=adiscount 
where custid in (select custid from custinfo with (NOLOCK) where mrecommend = @mrecommend and roleid=1) and isnull(sdiscount, 0) < adiscount

--Apply ExeReplication
-- call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
EXEC dbo.Acc_ExecRep_00 
	@custid = 0,
	@recommend = 0,
	@recommend_old = 0,
	@mrecommend = @mrecommend,
	@mrecommend_old = 0,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 3,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <>0 RETURN

EXEC dbo.Acc_ExecRep_00 
	@custid = 0,
	@recommend = 0,
	@recommend_old = 0,
	@mrecommend = @mrecommend,
	@mrecommend_old = 0,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 3,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <>0 RETURN
	
DECLARE @LogSPData VARCHAR(2000)

SELECT  @LogSPData = '<DBA_CustomerUpdMoveMaster  MasterName="' + @mastername 
        + '" OldSuperId="' + CONVERT(VARCHAR(20), @srecommend_old) 
		+ '" NewSuperName="' + @supername 
		+ '" NewSuperId="' + CONVERT(VARCHAR(20), @srecommend) + '" ' + '
		UserId="' + COALESCE(CAST(@userid AS VARCHAR(20)), SPACE(1)) + '" IP="' + @IP + '" />'
		
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
    @CustID = @mrecommend, 
	@ActionID = 613, 
	@TrackingValue = @LogSPData

END
GO
GRANT EXECUTE ON [dbo].[DBA_CustomerUpdMoveMaster] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[DBA_CustomerUpdMoveMaster] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_CustomerUpdMoveMaster] TO [vnteam]