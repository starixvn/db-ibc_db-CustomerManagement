ALTER PROCEDURE [dbo].[Acc_Dep_CustomerCheckMoveMaster]
	@supername	VARCHAR(40),
	@mastername VARCHAR(40),
	@userid		INT,	
	@ErrCode	INT = 0				OUTPUT,
	@ErrMsg		NVARCHAR(200) = ''	OUTPUT
AS
/*
	Created: Johnson
	Date: 2012-04-03
	Task : Check moving a master to another super
	DB: DBCUST.CustDB
	
	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
		Max errorcode 136
	• @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
	
	DECLARE @srecommend			INT, 
			@mrecommend			INT,
			@srecommend_old		INT, 
			@scurrency			TINYINT, 
			@mcurrency			TINYINT,
			@sdisable151_31		BIT,-- @sdisableHR -> @sdisable151_31 
			@mDisable151_31		BIT,-- @mdisableHR -> @mDisable151_31 
			@sdisableFI			BIT, 
			@mdisableFI			BIT,
			@sSyncCasino		BIT,
			@mSyncCasino		BIT,
			@sSyncBingo			BIT,
			@mSyncBingo			BIT,
			@sSyncLiveCasino	BIT,
			@mSyncLiveCasino	BIT,
			@sIsInternal		BIT,
			@mIsInternal		BIT,
			@sDisableOutright	BIT,
			@mDisableOutright	BIT,
			@sDisableCasino		BIT,
			@mDisableCasino		BIT,
			@sDisableLiveCasino	BIT,
			@mDisableLiveCasino BIT,
			@mDisable151_41		BIT,-- @mDisableOpenTote -> @mDisable151_41
			@sDisable151_41		BIT,-- @sDisableOpenTote -> @sDisable151_41
			@mDisable151_51		BIT,
			@sDisable151_51		BIT,
			@mDisable152_41		BIT,
			@sDisable152_41		BIT,
			@mDisable152_51		BIT,
			@sDisable152_51		BIT,
			@mDisable153_51		BIT,
			@sDisable153_51		BIT,
			@sDisableNumber		BIT,
			@mDisableNumber		BIT,
			@sDisableBingo		BIT,
			@mDisableBingo		BIT,
			@sClosed			BIT,	
			@mClosed			BIT,
			@sSuspended			BIT,	
			@mSuspended			BIT,
			@sMaxTransferP2P	MONEY,
			@mMaxTransferP2P	MONEY,
			@sIsAutoResetP2P	BIT,
			@mIsAutoResetP2P	BIT,
			@sDisableP2P		BIT, 
			@mDisableP2P		BIT, 
			@sDisableFunP2P		BIT,
			@mDisableFunP2P		BIT

	SELECT	@srecommend			= custid, 
			@scurrency			= currency, 
			@sdisable151_31		= DisableHorseracing, 
			@sdisableFI			= DisableFinancial,
			@sSyncCasino		= SyncCasino,
			@sSyncBingo			= SyncBingo,
			@sSyncLiveCasino	= SyncLiveCasino,
			@sDisableOutright	= DisableOutright,
			@sDisableCasino		= DisableCasino,
			@sDisableLiveCasino = DisableLiveCasino,
			@sDisable151_41		= DisableOpenTote ,
			@sDisable151_51		= Disable151_AU,
			@sDisable152_41		= Disable152_UK,
			@sDisable152_51		= Disable152_AU,
			@sDisable153_51		= Disable153_AU,
			@sDisableBingo		= DisableBingo,
			@sDisableNumber		= DisableNumber,
			@sClosed			= closed,
			@sSuspended			= reject,
			@sMaxTransferP2P	= MaxTransferP2P, 
			@sIsAutoResetP2P	= IsAutoResetP2P, 
			@sDisableP2P		= DisableP2P, 
			@sDisableFunP2P		= DisableFunP2P 		
	FROM	custinfo WITH (NOLOCK) 
	WHERE	username = @supername AND roleid = 4

	SELECT	@mrecommend			= custid, 
			@srecommend_old		= srecommend, 
			@mcurrency			= currency, 
			@mDisable151_31		= DisableHorseracing, 
			@mdisableFI			= DisableFinancial,
			@mSyncCasino		= SyncCasino,
			@mSyncLiveCasino	= SyncLiveCasino,
			@mSyncBingo			= SyncBingo,
			@mDisableOutright	= DisableOutright,
			@mDisableCasino		= DisableCasino,
			@mDisableLiveCasino = DisableLiveCasino,
			@mDisable151_41		= DisableOpenTote,
			@mDisable151_51		= Disable151_AU,
			@mDisable152_41		= Disable152_UK,
			@mDisable152_51		= Disable152_AU,
			@mDisable153_51		= Disable153_AU,
			@mDisableBingo		= DisableBingo,
			@mDisableNumber		= DisableNumber,
			@mSuspended			= reject,
			@mClosed			= closed,
			@mMaxTransferP2P	= MaxTransferP2P, 
			@mIsAutoResetP2P	= IsAutoResetP2P, 
			@mDisableP2P		= DisableP2P, 
			@mDisableFunP2P		= DisableFunP2P 		
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
		SELECT @ErrMsg = 'The master '+ @mastername +' already belongs to super '+ @supername +'.',
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
		SELECT @ErrMsg = 'Currency of super and master does not match.',
			@ErrCode = 104					 
		RETURN
	END

	--Check Internal status
	SELECT @sIsInternal = IsInternal FROM CustSuper with (nolock) WHERE custid = @srecommend
	SELECT @mIsInternal = IsInternal FROM CustMaster with (nolock) WHERE custid = @mrecommend
	IF ISNULL(@sIsInternal, 0) = 1 AND ISNULL(@mIsInternal, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move normal(betting) master to new internal super.',
			@ErrCode = 105					 
		RETURN
	END

	-- check is closed
	IF @sClosed = 1
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move to closed super.',
			@ErrCode = 106					 
		RETURN
	END

	--Check Horse, FI status:
	IF @sdisable151_31 = 1 AND @mDisable151_31 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled SA Racing but new super not enabled SA Racing.',
			@ErrCode = 107					 
		RETURN
	END

	--Check OpenTote
	IF @sDisable151_41 = 1 AND @mDisable151_41 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled UK/IRish Racing but new super not enabled UK/IRish Racing.',
			@ErrCode = 108				 
		RETURN
	END

	--Check Horse Racing for AU Tote
	IF @sDisable151_51 = 1 AND @mDisable151_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled Aust Racing but new super not enabled Aust Racing.',
			@ErrCode = 109			 
		RETURN
	END

	--Check Greyhound for UK Tote
	IF @sDisable152_41 = 1 AND @mDisable152_41 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled UK Greyhound but new super not enabled UK Greyhound.',
			@ErrCode = 110		 
		RETURN
	END

	--Check Greyhound for AU Tote
	IF @sDisable152_51 = 1 AND @mDisable152_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Aust Greyhound but new super not enabled Aust Greyhound.',
			@ErrCode = 111			 
		RETURN
	END

	--Check Harness for AU Tote
	IF @sDisable153_51 = 1 AND @mDisable153_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled Aust Harness but new super not enabled Aust Harness.',
			@ErrCode = 112			 
		RETURN
	END

	IF @sdisableFI = 1 AND @mdisableFI = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Finance but new super is not enabled Finance.',
			@ErrCode = 113
		RETURN
	END

	--Check Casino sync:
	IF @sSyncCasino = 0 AND @mSyncCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Casino but new super is not synchronized Casino.',
			@ErrCode = 114					 
		RETURN
	END
	/*
	--Check Casino enable status
	IF @sDisableCasino = 1 AND (@mDisableCasino = 0)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enable Casino but new super is not enable Casino.',
			@ErrCode = 115
		RETURN
	END
	*/
	--Check Bingo sync
	IF @sSyncBingo = 0 AND @mSyncBingo = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Bingo but new super is not synchronized Bingo',
			@ErrCode = 115				 
		RETURN
	END

	--Check Casino sync:
	IF @sSyncLiveCasino = 0 AND @mSyncLiveCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Casino but new super is not synchronized Casino.',
			@ErrCode = 116					 
		RETURN
	END

	--Check Bingo & Number status:
	IF @sdisableBingo = 1 AND @mdisableBingo = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Bingo but new super is not enabled Bingo.',
			@ErrCode = 117					 
		RETURN
	END


	IF @sdisableNumber = 1 AND @mdisableNumber = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Number Game but new super is not enabled Number Game.',
			@ErrCode = 118
		RETURN
	END


	--Check Horse, FI, Casino sync status:
	--no need to check for Horse
	/*IF EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 151)
		AND NOT EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 151)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Horse Racing setting.',
			@ErrCode = 110					 
		RETURN
	END*/
	--no need to check for Financial
	/*IF EXISTS(SELECT 1 FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 201)
		AND NOT EXISTS(SELECT 1 FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 201)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Finance setting.',
			@ErrCode = 200					 
		RETURN
	END*/

	--Check Number Game
	IF EXISTS(SELECT 1 FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 161)
		AND NOT EXISTS(SELECT 1 FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 161)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Number Game setting.',
			@ErrCode = 201					 
		RETURN
	END

	--check commission for 3rd party
	IF EXISTS (
			SELECT 1 
			FROM dep_custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN dep_custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend 
															AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype 
			WHERE scs.sdiscount<mcs.adiscount
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super commission is less than master commission.',
			@ErrCode = 203				 
		RETURN
	END

	--Check commission for live casino 
	IF EXISTS(
			SELECT 1 
			FROM CustSettingGame AS scs WITH(NOLOCK)
				INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND scs.sporttype = mcs.sporttype AND scs.bettype = mcs.bettype
			WHERE scs.custid = @srecommend AND scs.sporttype = 162 AND scs.bettype = 1101
				 AND scs.sdiscount < mcs.adiscount
	)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': super commission is less than master commission.',
				@ErrCode = 204
		RETURN	
	END

	--Check Position Taking
		--n4<=s3+m3<=s4		if i3=0
		--m3<=s4 and u3<=s4	if i3=1
		--u3+m3>=n4 if i3=1
		--m3<=m4

	IF EXISTS (
			SELECT 1 FROM 
				dep_custsetting AS scs WITH (NOLOCK)
				INNER JOIN dep_custsetting AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
																AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
			WHERE	
			--n4<=s3+m3<=s4	if i3=0
			(mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking AND scs.islive = 0)
			OR
			(mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND mcs.islive = 1 AND (mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking)
			--m3<=m4
			OR
			(mcs.mpositiontaking > scs.mpositiontaking AND mcs.islive=0)
			OR
			(mcs.sporttype =1 AND mcs.islive = 1 AND (mcs.bettype IN (1,3,7,8)) AND (mcs.mpositiontaking > scs.mpositiontaking))
				
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super positiontaking.',
			@ErrCode = 205				 
		RETURN
	END

	--Check Position Taking for 3rd party
		--n4<=s3+m3<=s4		if i3=0
		--m3<=s4 and u3<=s4	if i3=1
		--u3+m3>=n4 if i3=1
		--m3<=m4

	IF EXISTS (
			SELECT 1 FROM 
				dep_custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN dep_custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
																AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
			WHERE
			--n4<=s3+m3<=s4	if i3=0
			(mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking AND mcs.islive = 0)
			OR
			(mcs.sporttype =161 AND mcs.islive = 1 AND mcs.bettype IN (85,86,87,89,90) AND mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking)
			--m3<=m4
			OR
			(mcs.mpositiontaking > scs.mpositiontaking AND mcs.islive = 0)
			OR
			(mcs.sporttype =161 AND mcs.islive = 1 AND mcs.bettype IN (85,86,87,89,90) AND mcs.mpositiontaking > scs.mpositiontaking)
					
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super positiontaking.',
			@ErrCode = 206				 
		RETURN
	END

	--Check Position Taking	
		--all a2<=a4
		--all a1<=a4
	IF EXISTS (
			SELECT 1 FROM 
				dep_custsetting AS scs WITH (NOLOCK)
				INNER JOIN dep_custsetting AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
																AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
				INNER JOIN customer AS c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) 
														AND c.mrecommend = @mrecommend --get member and agent			
			WHERE
			--all a<=a4
			
				((acs.apositiontaking > scs.apositiontaking) AND acs.islive = 0)
				OR
				((acs.sporttype =1) AND acs.islive = 1 AND (acs.bettype IN (1,3,7,8)) AND (acs.apositiontaking > scs.apositiontaking))
					
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super positiontaking.',
			@ErrCode = 208				 
		RETURN
	END

	--Check Position Taking	for 3rd party
		--all a2<=a4
		--all a1<=a4
	IF EXISTS (
			SELECT 1 FROM 
				dep_custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN dep_custsetting3rd AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
																AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
				INNER JOIN customer AS c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) 
														AND c.mrecommend = @mrecommend --get member and agent			
			WHERE 
			(	(acs.apositiontaking > scs.apositiontaking AND acs.islive = 0)
				OR
				((acs.sporttype =161) AND acs.islive = 1 AND (acs.bettype IN (85,86,87,89,90)) AND (acs.apositiontaking > scs.apositiontaking))
			)
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super positiontaking.',
			@ErrCode = 209					 
		RETURN
	END

	--Check P2P :Game Comm
	IF exists(
		SELECT TOP 1 1
		FROM dbo.P2PGROUPCOMM s WITH(NOLOCK)
			INNER JOIN dbo.P2PGROUPCOMM m WITH(NOLOCK)
				ON m.GroupID = s.GroupID
			WHERE  s.custid = @srecommend AND m.custid = @mrecommend
					AND (s.sdiscount < m.adiscount )
	)
	BEGIN
		Select @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': P2P''s commission of master is greater than P2P''s commission of new super.',
			@ErrCode = 210
		return
	END

END



GO
GRANT EXECUTE ON [dbo].[Acc_Dep_CustomerCheckMoveMaster] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Dep_CustomerCheckMoveMaster] TO [vnteam] AS [dbo]