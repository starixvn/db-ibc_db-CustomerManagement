/*<info serverAlias="DBCust-CustDB" executers="bodbadminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Dep_CustomerCheckMoveAgent]
	@mastername		varchar(40),
	@agentname		varchar(40),
	@userid			int,
	@IP				varchar(15)='',
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Move a agent to another master
DB: DBCUST.CustDB
Original:

Revisions:
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]  
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    Max errorcode: 142
• @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON

	declare	@srecommend			int, 
			@mrecommend			int, 
			@recommend			int,
			@srecommend_old		int, 
			@mrecommend_old		int, 
			@scurrency			tinyint, 
			@mcurrency			tinyint, 
			@acurrency			tinyint,		
			@mdisableFI			bit, 
			@adisableFI			bit,
			@DisableAutoMPT		bit,
			@DisableAutoMPT_old bit,
			@mIsInternal		BIT,
			@aIsInternal		BIT,
			@mDisableOutright	BIT,
			@aDisableOutright	BIT,
			@mSyncCasino		BIT,
			@aSyncCasino		BIT,			
		
			@mDisableCasino		BIT,
			@aDisableCasino		BIT,		
			
			@mDisableNumber		BIT,
			@aDisableNumber		BIT,		
			@aClosed			BIT,	
			@mClosed			BIT,
			@aSuspended			BIT,	
			@mSuspended			BIT
		


	select	@srecommend			= srecommend, 
			@mrecommend			= custid, 
			@mcurrency			= currency, 
			@scurrency			= currency, 			
		
			@mDisableOutright	= DisableOutright,
			@mSyncCasino		= syncCasino,		
		
			@mDisableNumber		= DisableNumber,
			@mDisableCasino		= disableCasino,			
			@mClosed			= closed,
			@mSuspended			= reject
	from	custinfo with (nolock) 
	where	username = @mastername and roleid = 3

	select	@recommend			= custid, 
			@srecommend_old		= srecommend, 
			@mrecommend_old		= mrecommend, 
			@acurrency			= currency, 		
			
			@aDisableOutright	= DisableOutright,
			@aSyncCasino		= syncCasino,			
		
			@aDisableNumber		= DisableNumber,
			@aDisableCasino		= disableCasino,			
			@aClosed			= closed,
			@aSuspended			= reject
	from	custinfo with (NOLOCK) 
	where	username = @agentname and roleid = 2

	select	@DisableAutoMPT = DisableAutoMPT 
	from	custMaster with (nolock)
	where	custid = @mrecommend

	select	@DisableAutoMPT_old = DisableAutoMPT 
	from	custMaster with (nolock)
	where	custid = @mrecommend_old 

	if isnull(@mrecommend, 0) = 0 or isnull(@srecommend, 0) = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master not found.',
			@ErrCode = 101					 
		return
	END

	if isnull(@recommend, 0) = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent not found.',
			@ErrCode = 102					 
		return
	END

	if isnull(@mrecommend_old, 0) = @mrecommend
	BEGIN
		Select @ErrMsg = 'The agent '+ @agentname +' already belongs to master '+ @mastername +'.',
			@ErrCode = 103					 
		return
	END

	--Check an account disabled or not 
	EXEC dbo.Acc_CustomerSelCheckEnable @username = @mastername, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	if @ErrCode <>0		return 

	EXEC dbo.Acc_CustomerSelCheckEnable @username = @agentname, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	if @ErrCode <>0		return 

	if @mcurrency <> @acurrency
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': currency of master and agent does not match.',
			@ErrCode = 104					 
		return
	END

	--Check Internal status
	SELECT @mIsInternal = IsInternal FROM CustMaster with (nolock) WHERE custid = @mrecommend
	SELECT @aIsInternal = IsInternal FROM CustAgent with (nolock) WHERE custid = @recommend
	IF ISNULL(@mIsInternal, 0) = 1 AND ISNULL(@aIsInternal, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move normal(betting) agent to new internal master.',
			@ErrCode = 105					 
		RETURN
	END

	-- check is closed
	IF @mClosed = 1
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move to closed master.',
			@ErrCode = 106					 
		RETURN
	END

	if @mdisableFI = 1 and @adisableFI = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Finance but new master is not enabled Finance.',
			@ErrCode = 113
		return
	END

	--Check SyncCasino between Master and Agent 
	IF @mSyncCasino = 0 AND @aSyncCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is synchronized Casino but new master is not synchronized Casino.',
			@ErrCode = 114					 
		RETURN
	END

	/*
	--Check Casino enable status
	IF @mDisableCasino = 1 AND (@aDisableCasino = 0)
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Casino but new master is not enabled Casino.',
			@ErrCode = 115					
		RETURN
	END
	*/


	--Check Number Game + Bingo enable status
	if @mdisableNumber = 1 and @adisableNumber = 0
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Number Game but new master is not enabled Number Game.',
			@ErrCode = 117					 
		return
	END

	


	--Check identical auto master PT 
	if (@DisableAutoMPT_old = 0 and @DisableAutoMPT = 1)
	begin
		Select @ErrMsg = 'Error master ' + @Mastername + ': Auto Master Position Taking of new master is not allowed yet',
			@ErrCode = 119					 
		return
	end

	--Number Game
	if exists(select 1 from dep_custsetting3rd with (nolock) where custid = @recommend and sporttype = 161)
		AND not exists(select 1 from dep_custsetting3rd with (nolock) where custid = @mrecommend and sporttype = 161)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master does not have Number Game setting.',
			@ErrCode = 122					 
		return
	END

	--Check casino Syn
	--Remove checking Casino 
	--if exists(select 1 from custinfo with (nolock) where custid = @recommend and SyncCasino = 1)
	--BEGIN
	--	Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is already Casino-synchronized.',
	--		@ErrCode = 112					 
	--	return
	--END

	--Check commission 

	--Check commission for 3rd party
	if exists (
			select 1 
			from dep_custsetting3rd as mcs with (NOLOCK)
				inner join dep_custsetting3rd as acs with (NOLOCK) on mcs.custid = @mrecommend and acs.custid = @recommend 
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype 
			where mcs.adiscount<acs.discount
		)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master commission is less than agent commission.',
			@ErrCode = 201					 
		return
	END

	--Check Position Taking
		--check m3_master_old <= m3_master_new

	if exists (
		select 1 from 
			dep_custsetting as mcs_old with (nolock)
			inner join dep_custsetting as mcs_new with (nolock) on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and
			((mcs_old.mpositiontaking > mcs_new.mpositiontaking AND mcs_old.islive = 0 AND mcs_new.islive = 0)
			or (mcs_old.bettype in (1,3,7,8) and mcs_old.sporttype =1 and mcs_old.mpositiontaking > mcs_new.mpositiontaking AND mcs_old.islive = 1 AND mcs_new.islive = 1))
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 206					 
		return
	END

	--Check Position Taking for 3rd Party
		--check m3_master_old <= m3_master_new

	if exists (
		select 1 from 
			dep_custsetting3rd as mcs_old with (nolock)
			inner join dep_custsetting3rd as mcs_new with (nolock) on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and ((mcs_old.mpositiontaking > mcs_new.mpositiontaking AND mcs_old.islive = 0 AND mcs_new.islive = 0)
			or (mcs_old.bettype in (85,86,87,89,90) and mcs_old.sporttype =161 and mcs_old.mpositiontaking > mcs_new.mpositiontaking AND mcs_old.islive = 1 AND mcs_new.islive = 1)
			)
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 207					 
		return
	END

	--Check Position Taking for live casino
		--check m3_master_old <= m3_master_new

		--m2+a2<=m3
		--n3<=m2+a2<=l3
	if exists (
		select 1 from 
			dep_custsetting as mcs with (nolock)
			inner join dep_custsetting as acs with (nolock) on mcs.custid = @mrecommend and acs.custid = @recommend
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype
		where
		--m2+a2<=m3
		(acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking AND acs.islive = 0)
		or
		((mcs.sporttype =1) and (mcs.bettype in (1,3,7,8)) AND mcs.islive = 1 and (acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking))
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master positiontaking.',
			@ErrCode = 209					 
		return
	END

		--Check for 3rd party
		--m2+a2<=m3
		--n3<=m2+a2<=l3
	if exists (
		select 1 from 
			dep_custsetting3rd as mcs with (nolock)
			inner join dep_custsetting3rd as acs with (nolock) on mcs.custid = @mrecommend and acs.custid = @recommend
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype
			
		where
		--m2+a2<=m3
		(
			(acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking AND acs.islive=0)
			or
			((mcs.sporttype =161) and (mcs.bettype in (85,86,87,89,90)) AND acs.islive=1 and (acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking))
		)	
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master positiontaking.',
			@ErrCode = 210					 
		return
	END

		--Check for live casino
		--m2+a2<=m3
		--n3<= im = 0? m2+a2 : um2 + a2

	--Check Position Taking	
		--all a2<=a4
		--all a1<=a4
	if exists (
			select 1 from 
				dep_custsetting as scs with (nolock)
				inner join dep_custsetting as acs with (nolock) on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				inner join customer as c with (nolock) on c.custid = acs.custid and c.roleid in (1,2) 
														and c.recommend = @recommend --get member and agent			
			where
			--all a<=a4
			(
				(acs.apositiontaking > scs.apositiontaking AND acs.islive = 0)
				or
				((acs.sporttype =1) and (acs.bettype in (1,3,7,8)) AND acs.islive=1 and (acs.apositiontaking > scs.apositiontaking))
			)
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super positiontaking.',
			@ErrCode = 212					 

		return
	END

	--Check Position Taking	for 3rd party
		--all a2<=a4
		--all a1<=a4
	if exists (
			select 1 from 
				dep_custsetting3rd as scs with (nolock)
				inner join dep_custsetting3rd as acs with (nolock) on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				inner join customer as c with (nolock) on c.custid = acs.custid and c.roleid in (1,2) 
														and c.recommend = @recommend --get member and agent			
			where 
			(acs.apositiontaking > scs.apositiontaking AND acs.islive = 0)
			or
			((acs.sporttype =161) and (acs.bettype in (85,86,87,89,90)) AND acs.islive=1 and (acs.apositiontaking > scs.apositiontaking))
	)
	BEGIN	
		Select @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super positiontaking.',
			@ErrCode = 213				 

		return
	END

	--Check P2P :Game Comm
	IF exists(
		SELECT TOP 1 1
		FROM dbo.P2PGROUPCOMM m WITH(NOLOCK)
			INNER JOIN dbo.P2PGROUPCOMM a WITH(NOLOCK)
				ON a.GroupID = M.GroupID
			WHERE  m.custid = @mrecommend AND A.custid = @recommend
					AND (m.adiscount < a.discount )
	)
	BEGIN
		Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': P2P''s commission of agent is is greater than P2P''s commission of new master .',
			@ErrCode = 214
		return
	END
END



GO
GRANT EXECUTE ON [dbo].[Acc_Dep_CustomerCheckMoveAgent] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Dep_CustomerCheckMoveAgent] TO [vnteam] AS [dbo]