ALTER PROCEDURE [dbo].[Acc_CustOverrideUpdHR] 
	@custid int,

	@minv151positiontaking_31 smallmoney = 0,
	@minv151positiontaking_32 smallmoney = 0,
	@minv151positiontaking_41 smallmoney = 0,
	@minv151positiontaking_42 smallmoney = 0,

	@maxv151positiontaking_31 smallmoney = 0.5,
	@maxv151positiontaking_32 smallmoney = 0.5,
	@maxv151positiontaking_41 smallmoney = 0.5,
	@maxv151positiontaking_42 smallmoney = 0.5,

	@CheckPermission bit = 1,
	@UpdateMinPos bit = 1,
	@UpdateMaxPos bit = 1,
	@language varchar(2) = 'E',
	@UserID int = 0,
	@SubAccID int = 0, --Sub-AccountID
	@WriteLog bit = 1,
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20080514@Thien
Task : Update CustOverride for HR
DB: DB02.bodb02
Original: 

Revisions:
    - 20090701@Phuc: remove dbo.IsAllowChangePositiontaking.
					Write log subaccname instead of subaccid.
	- 20090801@Shifu: check disabled user
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end
Declare @maxpos smallmoney 
Declare @roleid int, @srecommend int, @mrecommend int, @recommend int
select @roleid = roleid, @srecommend=srecommend, @mrecommend=mrecommend, @recommend=recommend from customer with (NOLOCK) where custid = @custid
select @maxpos = 0.5 --Max posistion for finance = 0.5
----------------------------------------------------------------------------------------------------
declare @IsValid bit
declare @ErrAcc varchar(4000)


 --Disable on Weekend's peak hour, from 7PM - 2AM (GMT+8)
if @roleid = 4 and datename(weekday, getdate()) in ('Saturday','Sunday') and datepart(hour, getdate()) between 7 and 14
BEGIN
	Select @ErrCode = 100, @ErrMsg = 'Function is not available. Please contact IT.'
	RETURN
END

/*
if not exists (select 1 from custinfo with (nolock) where custid = @custid and srecommend in (181940,197461))
BEGIN
--	declare @ErrMsg varchar(200)
	Select @ErrMsg = 'Sorry, please try again later.'
	RaisError (@ErrMsg, 16, 1)
	return
END
*/

--Check Old_minmax <> New_minmax
Declare 	 
	@old_minv151positiontaking_31 smallmoney,
	@old_minv151positiontaking_32 smallmoney,
	@old_minv151positiontaking_41 smallmoney,
	@old_minv151positiontaking_42 smallmoney,

	--v151
	@old_maxv151positiontaking_31 smallmoney,
	@old_maxv151positiontaking_32 smallmoney,
	@old_maxv151positiontaking_41 smallmoney,
	@old_maxv151positiontaking_42 smallmoney
	--Get Old data
	select @old_minv151positiontaking_31 = minpositiontaking, @old_maxv151positiontaking_31 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 31
	select @old_minv151positiontaking_32 = minpositiontaking, @old_maxv151positiontaking_32 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 32
	select @old_minv151positiontaking_41 = minpositiontaking, @old_maxv151positiontaking_41 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 41
	select @old_minv151positiontaking_42 = minpositiontaking, @old_maxv151positiontaking_42 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 42

--Check Old_minmax = New_minmax
IF (@UpdateMinPos = 0 or 
		(
			@minv151positiontaking_31 = @old_minv151positiontaking_31 and
			@minv151positiontaking_32 = @old_minv151positiontaking_32 and
			@minv151positiontaking_41 = @old_minv151positiontaking_41 and
			@minv151positiontaking_42 = @old_minv151positiontaking_42 
		)
	)
	and 
	( @UpdateMaxPos = 0 or
		(
			@maxv151positiontaking_31 = @old_maxv151positiontaking_31 and
			@maxv151positiontaking_32 = @old_maxv151positiontaking_32 and
			@maxv151positiontaking_41 = @old_maxv151positiontaking_41 and
			@maxv151positiontaking_42 = @old_maxv151positiontaking_42 
		)
	)
BEGIN
	return
END


--Check param

--1.Check values:
if @UpdateMinPos = 0
BEGIN
	--v151
	select @minv151positiontaking_31 = minpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 31
	select @minv151positiontaking_32 = minpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 32
	select @minv151positiontaking_41 = minpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 41
	select @minv151positiontaking_42 = minpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 42
END
if @UpdateMaxPos = 0
BEGIN
	--v151
	select @maxv151positiontaking_31 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 31
	select @maxv151positiontaking_32 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 32
	select @maxv151positiontaking_41 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 41
	select @maxv151positiontaking_42 = maxpositiontaking from CustOverride3rd with (NOLOCK) where custid = @custid and sporttype=151 and bettype = 42
END


Select @isvalid = 1
if @UpdateMinPos=1
BEGIN
	if 
		--v151
		@minv151positiontaking_31 <0 or @minv151positiontaking_31 > @maxpos
		or @minv151positiontaking_32 <0 or @minv151positiontaking_32 > @maxpos
		or @minv151positiontaking_41 <0 or @minv151positiontaking_41 > @maxpos
		or @minv151positiontaking_42 <0 or @minv151positiontaking_42 > @maxpos
	BEGIN
		select @isvalid = 0, @ErrCode = 1
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong min position taking.'
							when 'CS' then N'最低占成数不正确.'
							when 'CT' then N'最低佔成數不正確.'
							when 'TH' then N'การกำหนดจำนวนเงินต่ำสุดไม่ถูกต้อง.'
							when 'J' then N'Wrong min position taking.'
							else N'Wrong min position taking.'
					end
		return
	END
END

if @UpdateMaxPos=1
BEGIN
	if @maxv151positiontaking_31 <0 or @maxv151positiontaking_31 > @maxpos
		or @maxv151positiontaking_32 <0 or @maxv151positiontaking_32 > @maxpos
		or @maxv151positiontaking_41 <0 or @maxv151positiontaking_41 > @maxpos
		or @maxv151positiontaking_42 <0 or @maxv151positiontaking_42 > @maxpos
	BEGIN
		select @isvalid = 0, @ErrCode = 2
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong max position taking.'
							when 'CS' then N'占成数不正确.'
							when 'CT' then N'佔成數不正確.'
							when 'TH' then N'การกำหนดจำนวนเงินต่ำสุดไม่ถูกต้อง.'
							when 'J' then N'Wrong max position taking.'
							else N'Wrong max position taking.'
					end
		return
	END
END

if @minv151positiontaking_31 > @maxv151positiontaking_31 
	or @minv151positiontaking_32 > @maxv151positiontaking_32
	or @minv151positiontaking_41 > @maxv151positiontaking_41 
	or @minv151positiontaking_42 > @maxv151positiontaking_42
BEGIN
	select @isvalid = 0, @ErrCode = 3
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong min/max position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดจำนวนเงินต่ำสุดไม่ถูกต้อง.'
						when 'J' then N'Wrong min/max position taking.'
						else N'Wrong min/max position taking.'
				end
	return
END
IF @roleid = 4 
BEGIN
if @UpdateMinPos = 1
BEGIN
	--check s4 >= new_n4
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		customer as c with (NOLOCK) 
		inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
							select 	151 as sporttype, 31 as bettype, @minv151positiontaking_31 as minpositiontaking
				union all select 	151 as sporttype, 32 as bettype, @minv151positiontaking_32 as minpositiontaking
				union all select 	151 as sporttype, 41 as bettype, @minv151positiontaking_41 as minpositiontaking
				union all select 	151 as sporttype, 42 as bettype, @minv151positiontaking_42 as minpositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where cs.custid = @custid and (cs.spositiontaking<b.minpositiontaking )
	group by username
	if @ErrAcc<>''
	BEGIN
		select @isvalid = 0, @ErrCode = 404
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
							when 'CS' then N'现有占成数设定不符合新的最低占成数设定 ('+@ErrAcc+').'
							when 'CT' then N'現有佔成數設定不符合新的最低佔成數設定 ('+@ErrAcc+').'
							when 'TH' then N'จำนวนเงินในการเล่นของบัญชีปัจจุบัน ไม่สอดคล้องกับ  ขั้นต่ำจำกัดของจำนวนเงินในการเล่นใหม่ที่กำหนดไว้ ('+@ErrAcc+').'
							when 'J' then N'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
							when 'KO' then N'현재 계정의 거래 조건에 위반됩니다 새로운 최소 거래조건을 설정해주시기 바랍니다 ('+@ErrAcc+').'
							else N'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
					end
		return
	END
END

END
IF @roleid = 3
BEGIN
	if @UpdateMaxPos = 1
	BEGIN
		--check all (n2)<=l3
		select @ErrAcc = ''
		select top 100 @ErrAcc = @ErrAcc + username +', '
		from 
			customer as c with (NOLOCK) 
			inner join CustOverride3rd as aco with (NOLOCK) on c.custid = aco.custid
			inner join (
								select 	151 as sporttype, 31 as bettype, @maxv151positiontaking_31 as maxpositiontaking
					union all select 	151 as sporttype, 32 as bettype, @maxv151positiontaking_32 as maxpositiontaking
					union all select 	151 as sporttype, 41 as bettype, @maxv151positiontaking_41 as maxpositiontaking
					union all select 	151 as sporttype, 42 as bettype, @maxv151positiontaking_42 as maxpositiontaking
				) as b on aco.sporttype=b.sporttype and aco.bettype = b.bettype
		where c.mrecommend = @custid and c.roleid = 2 and (aco.minpositiontaking>b.maxpositiontaking )
		group by username
		if @ErrAcc<>''
		BEGIN
			select @isvalid = 0, @ErrCode = 301
			Select @ErrMsg = 	case @Language 
								when 'E' then 'Existing agents (minimum positiontaking) exceeded new maximum positiontaking ('+@ErrAcc+').'
								when 'CS' then N'现有代理(最低占成数)超出新的最高占成数设定 ('+@ErrAcc+').'
								when 'CT' then N'現有代理(最低佔成數)超出新的最高佔成數設定 ('+@ErrAcc+').'
								when 'TH' then N'จำนวนตัวแทนที่มี่อยู่ในขณะนี้  ( ขั้นต่ำที่กำหนดไว้ ) มีเกินกว่า จำนวนสูงสุดของบริษัทที่กำหนดใหม่ ('+@ErrAcc+').'
								when 'J' then N'Existing agents (minimum positiontaking) exceeded new maximum positiontaking ('+@ErrAcc+').'
								when 'KO' then N'현재 에이전트의 최소 거래조건이새로운 최대 거래조건을 초과 했습니다 ('+@ErrAcc+').'
								else N'Existing agents (minimum positiontaking) exceeded new maximum positiontaking ('+@ErrAcc+').'
						end
			return
		END
	END
	if @UpdateMinPos = 1
	BEGIN
		--check m3>=n3
		select @ErrAcc = ''
		--select top 100 @ErrAcc = @ErrAcc + username +' sporttype: '+ convert(varchar(10),b.sporttype) + ', bet type: ' + convert(varchar(10),b.bettype) + ', '
		select top 100 @ErrAcc = @ErrAcc + username + ', '
		from 
			customer as c with (NOLOCK) 
			inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
			inner join (
								select 	151 as sporttype, 31 as bettype, @minv151positiontaking_31 as minpositiontaking
					union all select 	151 as sporttype, 32 as bettype, @minv151positiontaking_32 as minpositiontaking
					union all select 	151 as sporttype, 41 as bettype, @minv151positiontaking_41 as minpositiontaking
					union all select 	151 as sporttype, 42 as bettype, @minv151positiontaking_42 as minpositiontaking
				) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
		where cs.custid = @custid and (cs.mpositiontaking<b.minpositiontaking )
		group by username
		if @ErrAcc<>''
		BEGIN
			select @isvalid = 0, @ErrCode = 304
			Select @ErrMsg = 	case @Language 
								when 'E' then 'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
								when 'CS' then N'现有占成数设定不符合新的最低占成数设定 ('+@ErrAcc+').'
								when 'CT' then N'現有佔成數設定不符合新的最低佔成數設定 ('+@ErrAcc+').'
								when 'TH' then N'จำนวนเงินในการเล่นของบัญชีปัจจุบัน ไม่สอดคล้องกับ  ขั้นต่ำจำกัดของจำนวนเงินในการเล่นใหม่ที่กำหนดไว้ ('+@ErrAcc+').'
								when 'J' then N'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
								when 'KO' then N'현재 계정의 거래 조건에 위반됩니다 새로운 최소 거래조건을 설정해주시기 바랍니다 ('+@ErrAcc+').'
								else N'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
						end
			return
		END
	END
END
IF @roleid = 2
BEGIN
	if @UpdateMinPos = 1
	BEGIN
		--check l3 >= n2
		select @ErrAcc = ''
		select top 100 @ErrAcc = @ErrAcc + username +', '
		from 
			customer as c with (NOLOCK) 
			inner join CustOverride3rd as mco with (NOLOCK) on c.custid = mco.custid
			inner join (
								select 	151 as sporttype, 31 as bettype, @minv151positiontaking_31 as minpositiontaking
					union all select 	151 as sporttype, 32 as bettype, @minv151positiontaking_32 as minpositiontaking
					union all select 	151 as sporttype, 41 as bettype, @minv151positiontaking_41 as minpositiontaking
					union all select 	151 as sporttype, 42 as bettype, @minv151positiontaking_42 as minpositiontaking
				) as b on mco.sporttype=b.sporttype and mco.bettype = b.bettype
		where
			c.custid = (select mrecommend from customer with (NOLOCK) where custid = @custid) and c.roleid=3
			and (mco.maxpositiontaking<b.minpositiontaking )
		group by username
		if @ErrAcc<>''
		BEGIN
			select @isvalid = 0, @ErrCode = 151
			Select @ErrMsg = 	case @Language 
								when 'E' then 'Master maximum positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
								when 'CS' then N'总代理占成数设定不符合新的最低占成数设定 ('+@ErrAcc+').'
								when 'CT' then N'總代理佔成數設定不符合新的最低佔成數設定 ('+@ErrAcc+').'
								when 'TH' then N'จำนวนตัวแทนหลักที่กำหนดไว้ ไม่สอดคล้องกับจำนวนต่ำสุดที่กำหนดไว้จากบริษัท ('+@ErrAcc+').'
								when 'J' then N'Master maximum positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
								when 'KO' then N'마스터의 최대 거래조건에 위반됩니다 새로운 최소 거래조건을 설정해 주시기 바랍니다 ('+@ErrAcc+').'
								else N'Master maximum positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
						end
			return
		END

		--check a2 >= n2
		select @ErrAcc = ''
		select top 100 @ErrAcc = @ErrAcc + username +', '
		from 
			customer as c with (NOLOCK) 
			inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
			inner join (
								select 	151 as sporttype, 31 as bettype, @minv151positiontaking_31 as minpositiontaking
					union all select 	151 as sporttype, 32 as bettype, @minv151positiontaking_32 as minpositiontaking
					union all select 	151 as sporttype, 41 as bettype, @minv151positiontaking_41 as minpositiontaking
					union all select 	151 as sporttype, 42 as bettype, @minv151positiontaking_42 as minpositiontaking
				) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
		where cs.custid = @custid and (cs.apositiontaking<b.minpositiontaking)
		group by username
		if @ErrAcc<>''
		BEGIN
			select @isvalid = 0, @ErrCode = 203
			Select @ErrMsg = 	case @Language 
								when 'E' then 'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
								when 'CS' then N'现有占成数设定不符合新的最低占成数设定 ('+@ErrAcc+').'
								when 'CT' then N'現有佔成數設定不符合新的最低佔成數設定 ('+@ErrAcc+').'
								when 'TH' then N'จำนวนเงินในการเล่นของบัญชีปัจจุบัน ไม่สอดคล้องกับ  ขั้นต่ำจำกัดของจำนวนเงินในการเล่นใหม่ที่กำหนดไว้ ('+@ErrAcc+').'
								when 'J' then N'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
								when 'KO' then N'현재 계정의 거래 조건에 위반됩니다 새로운 최소 거래조건을 설정해주시기 바랍니다 ('+@ErrAcc+').'
								else N'Current account positiontaking violates new minimum positiontaking setting ('+@ErrAcc+').'
						end
			return
		END
	END
END

--End check param
if @ErrCode <> 0
BEGIN
	return
END

----------------------------------------------------------------------------------------------------
declare @logdata nvarchar(300)

if @UpdateMinPos = 1
BEGIN
	
	Update CustOverride3rd with (ROWLOCK, UPDLOCK) set minpositiontaking = b.minpositiontaking
	from CustOverride3rd as co inner join 	
			(
						  select 	@custid as custid,  151 as sporttype, 31 as bettype, @minv151positiontaking_31 as minpositiontaking
				union all select 	@custid as custid,  151 as sporttype, 32 as bettype, @minv151positiontaking_32 as minpositiontaking
				union all select 	@custid as custid,  151 as sporttype, 41 as bettype, @minv151positiontaking_41 as minpositiontaking
				union all select 	@custid as custid,  151 as sporttype, 42 as bettype, @minv151positiontaking_42 as minpositiontaking
			) as b on co.custid = b.custid and co.sporttype=b.sporttype and co.bettype = b.bettype
	where co.custid = @custid
END

if @UpdateMaxPos = 1
BEGIN

	Update CustOverride3rd with (ROWLOCK, UPDLOCK) set maxpositiontaking = b.maxpositiontaking
	from CustOverride3rd as co inner join 	
			(
							select 	@custid as custid,  151 as sporttype, 31 as bettype, @maxv151positiontaking_31 as maxpositiontaking
				union all select 	@custid as custid,  151 as sporttype, 32 as bettype, @maxv151positiontaking_32 as maxpositiontaking
				union all select 	@custid as custid,  151 as sporttype, 41 as bettype, @maxv151positiontaking_41 as maxpositiontaking
				union all select 	@custid as custid,  151 as sporttype, 42 as bettype, @maxv151positiontaking_42 as maxpositiontaking
			) as b on co.custid = b.custid and co.sporttype=b.sporttype and co.bettype = b.bettype
	where co.custid = @custid
	
END

if @roleid = 2
BEGIN
	EXEC dbo.Acc_CustomerUpdAgentHR_MinMaxPositiontaking @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
	-- The minimum position taking value of agent was modified by agent's upline
	EXEC DB03.On_User.dbo.Age_MessageNoticeUpd @custID = @custid, @userID = @UserID
END
else if @roleid = 3
BEGIN
	EXEC dbo.Acc_CustomerUpdMasterHR_MinMaxPositiontaking @mrecommend = @mrecommend, @srecommend = @srecommend
END
else if @roleid= 4 and @WriteLog = 1 and @UpdateMinPos = 1
BEGIN
	EXEC dbo.Acc_CustomerUpdSuperHR_MinPositiontaking @srecommend = @srecommend
END
else if @roleid= 4 and @WriteLog = 1 and @UpdateMaxPos = 1
BEGIN
	EXEC dbo.Acc_CustomerUpdSuperHR_MaxPositiontaking @srecommend = @srecommend
END


if @WriteLog = 1
BEGIN
	Declare @LogSPData varchar(5000)
	Select @LogSPData = '<info>custid='+ coalesce(cast(@custid as varchar(50)),space(1)) + ',
	CheckPermission='+ coalesce(cast(@CheckPermission as varchar(50)),space(1)) + ',
	UpdMinPos='+ coalesce(cast(@UpdateMinPos as varchar(50)),space(1)) + ',
	UpdMaxPos='+ coalesce(cast(@UpdateMaxPos as varchar(50)),space(1)) + ',
	language='+ coalesce(cast(@language as varchar(2)),space(1))+',
	UserID='+ coalesce(cast(@UserID as varchar(50)),space(1)) + ',
	SubAccName='+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + ',
	WriteLog='+ coalesce(cast(@WriteLog as varchar(50)),space(1)) + ',
	IP='+ coalesce(cast(@IP as varchar(15)),space(1))+',
	ErrCode='+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + ' O,
	ErrMsg='+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+' O,</info>
	minv151pt_31='+ coalesce(cast(@minv151positiontaking_31 as varchar(50)),space(1)) + ',
	minv151pt_32='+ coalesce(cast(@minv151positiontaking_32 as varchar(50)),space(1)) + ',
	minv151pt_41='+ coalesce(cast(@minv151positiontaking_41 as varchar(50)),space(1)) + ',
	minv151pt_42='+ coalesce(cast(@minv151positiontaking_42 as varchar(50)),space(1)) + ',
	maxv151pt_31='+ coalesce(cast(@maxv151positiontaking_31 as varchar(50)),space(1)) + ',
	maxv151pt_32='+ coalesce(cast(@maxv151positiontaking_32 as varchar(50)),space(1)) + ',
	maxv151pt_41='+ coalesce(cast(@maxv151positiontaking_41 as varchar(50)),space(1)) + ',
	maxv151pt_42='+ coalesce(cast(@maxv151positiontaking_42 as varchar(50)),space(1)) 
	--Write log
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID,
		@CustID = @CustID,
		@SpName = 'Acc_CustOverrideUpdHR',
		@Doing = @LogSPData
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustOverrideUpdHR] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustOverrideUpdHR] TO [bodbDownlineNet]
Go
GRANT VIEW DEFINITION ON [dbo].[Acc_CustOverrideUpdHR] TO vnteam