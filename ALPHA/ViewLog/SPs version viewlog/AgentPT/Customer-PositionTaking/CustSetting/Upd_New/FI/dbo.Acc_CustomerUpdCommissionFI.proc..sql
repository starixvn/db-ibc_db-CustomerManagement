ALTER PROCEDURE [dbo].[Acc_CustomerUpdCommissionFI]
	@custid int,
	@roleid tinyint,
	--v201
	@v201discount decimal(9,8),
	@SubAccID int = 0, --Sub-AccountID
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090415@Phuc
Task : Update FI's Commission
DB: DB02.bodb02

Revisions:
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON
if @v201discount<0 or @v201discount>0.2
BEGIN	
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong discount.'
						when 'CS' then N'折扣不正确.'
						when 'CT' then N'折扣不正確.'
						when 'TH' then N'การให้ส่วนลดไม่ถูกต้อง.'
						when 'J' then N'Wrong discount.' 
						when 'KO' then N'잘못된 수수료'
						else N'Wrong discount.'
				end, @ErrCode = 101
	return
END

Declare @username nvarchar(20), 
		@srecommend int, 
		@mrecommend int, 
		@recommend int, 
		@v201discount_max DECIMAL(9,8)

Select @UserName  = username,
		@recommend = case when @RoleID = 1 then recommend else 0 end,
		@mrecommend = case when @RoleID = 2 then mrecommend else 0 end,
		@srecommend = case when @RoleID = 3 then srecommend else 0 end
from custinfo with (NOLOCK) 
where CustID = @CustID and RoleID = @RoleID

--------------------------------------------------------------------------
-----------------------------  Member  -----------------------------------
--------------------------------------------------------------------------
IF @roleid = 1
BEGIN
	--Get a2
	SELECT @v201discount_max = discount
	FROM CustSetting3rd WITH (NOLOCK)
	WHERE custid = @recommend and sporttype = 201 and bettype = 3

	--@playerdiscount>g2?g2:@playerdiscount 
	--@playerdiscountcs>a2?a2:@playerdiscountcs
	SELECT 
		@v201discount = case when @v201discount > @v201discount_max then @v201discount_max else @v201discount end
		
	---------------------------------------
	UPDATE CustSetting3rd WITH (ROWLOCK, UPDLOCK)
	SET	
		playerdiscount = @v201discount 
	WHERE custid=@custid and sporttype = 201 and bettype in ( 2, 3)
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 102
		return
	end
END


--------------------------------------------------------------------------
-----------------------------  Agent   -----------------------------------
--------------------------------------------------------------------------
IF @roleid = 2
BEGIN

	--Get a2=m3 if a2>m3
	Select 	
		@v201discount = case when @v201discount > adiscount then adiscount else @v201discount end
	from CustSetting3rd as cs with (nolock) 
	where custid = @mrecommend and bettype =3  and sporttype = 201

	---------------------------------------

	---------------------------------------
	--Update @Master: g2, a2
	update CustSetting3rd with (ROWLOCK, UPDLOCK)
	set
		discount = @v201discount
	where custid=@custid and sporttype = 201 and bettype in (2, 3)
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 102
		return
	end

	---------------------------------------
	--Update a2 at Member level
	UPDATE cs
	SET 	cs.discount = @v201discount 
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as ci with (NOLOCK) on cs.custid = ci.custid
	WHERE ci.recommend = @custid AND ci.roleid = 1 and sporttype = 201 and bettype in (2, 3)
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
							case @Language 
								when 'E' then 'Update process is unsuccessful !'
								when 'CS' then N'更新程序不成功 !'
								when 'CT' then N'更新程序不成功 !'
								when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
								when 'J' then N'アップデート出来ません。'
								when 'KO' then N'업데이트에 실패했습니다.'
								else N'Update process is unsuccessful !'
							end, @ErrCode = 103
		return
	end

	---------------------------------------
	--At member level, update playerdiscount = discount  if playerdiscount > discount
	UPDATE cs
	SET
		cs.playerdiscount = cs.discount 
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (nolock) on cs.custid = c.custid
	WHERE c.recommend = @custid AND c.roleid = 1 AND cs.playerdiscount > cs.discount and sporttype = 201 and bettype in (2, 3)
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 104
		return
	end
END

--------------------------------------------------------------------------
-----------------------------  Master  -----------------------------------
--------------------------------------------------------------------------
IF @roleid = 3
BEGIN
	--Get m3=s4 if m3>s4 for 201 sporttype 
	Select @v201discount = case when @v201discount > sdiscount then sdiscount else @v201discount end
	from CustSetting3rd as cs with (nolock) 
	where custid = @srecommend and bettype =3 and sporttype = 201
	--Update @Master: g3, m3
	update CustSetting3rd with (ROWLOCK, UPDLOCK)
	set
		adiscount = @v201discount 
	where custid=@custid and sporttype = 201 and  bettype in ( 2,3)
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 102
		return
	end
	---------------------------------------
	--Update a2 = m3 if a2>m3
	UPDATE cs
	SET 	
		discount = @v201discount 
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as ci with (NOLOCK) on cs.custid = ci.custid
	WHERE ci.mrecommend = @custid AND ci.roleid = 2 and sporttype = 201 and  bettype in ( 2,3) and discount>@v201discount 
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 104				 
		
		return
	end
	---------------------------------------
	--Update m3 @ member level
	UPDATE cs
	SET 	
		adiscount = @v201discount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.mrecommend = @custid AND c.roleid = 1 and sporttype = 201 and  bettype in ( 2,3)
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 106
		return
	end
	---------------------------------------
	--At member level, update discount = adiscount  if discount > adiscount
	UPDATE cs
	SET 	
		discount = adiscount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.mrecommend = @custid AND c.roleid = 1 and cs.discount>cs.adiscount and sporttype = 201 and  bettype in ( 2,3)
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end	, @ErrCode = 107
		return
	end

	---------------------------------------
	--At member level, update playerdiscount = discount if playerdiscount > discount
	UPDATE CustSetting3rd with (ROWLOCK, UPDLOCK) 
	SET 	
		playerdiscount = discount
	From CustSetting3rd as cs inner join customer as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.mrecommend = @custid AND c.roleid = 1 and cs.playerdiscount>cs.discount and sporttype = 201 and  bettype in ( 2,3)
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
						case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 108
		return
	end

END

--------------------------------------------------------------------------
-----------------------------  Super   -----------------------------------
--------------------------------------------------------------------------
IF @roleid = 4 
BEGIN
	---------------------------------------------------
	--Update @Super: s4(Financial)
	update CustSetting3rd with (ROWLOCK, UPDLOCK)
	set
		sdiscount = @v201discount 
	where custid = @custid and sporttype = 201 and bettype in (3,2)
	---------------------------------------------------
	--Update m3=s4 if m3>s4
	UPDATE cs 
	SET 	
		adiscount = @v201discount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as ci with (NOLOCK) on cs.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid = 3 and sporttype = 201 and bettype in (2,3) and adiscount>@v201discount
	if (@@error <> 0)
	begin
		Select @ErrMsg = @UserName + ': '+
			case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 106	
		return
	end

	---------------------------------------------------
	--Update a2=s4 if a2>s4
	UPDATE cs 
		SET discount = @v201discount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as ci with (NOLOCK) on cs.custid = ci.custid
	WHERE ci.srecommend = @custid AND ci.roleid = 2  and sporttype = 201 and bettype in (2, 3) and discount>@v201discount
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
			case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 107	
		return
	end

	---------------------------------------------------
	--Update s4 to member level
	UPDATE cs 
	SET 	
		sdiscount =  @v201discount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and sporttype = 201 and bettype in (2,3)  
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
			case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 105	
		return
	end

	---------------------------------------------------
	--At member level, update adiscount = sdiscount  if adiscount > sdiscount
	UPDATE cs
	SET 	
		adiscount = sdiscount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join customer as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and cs.adiscount>cs.sdiscount and sporttype = 201 and bettype in (2, 3)
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
			case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 108
		return
	end

	---------------------------------------------------
	--At member level, update discount = adiscount  if discount > adiscount
	UPDATE cs
	SET 	
		discount = adiscount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and cs.discount>cs.adiscount and sporttype = 201 and bettype in(2,3)
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
			case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 109	
		return
	end

	---------------------------------------------------
	--At member level, update playerdiscount = discount  if playerdiscount > discount
	UPDATE cs
	SET 	
		playerdiscount = discount
	From CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	WHERE c.srecommend = @custid AND c.roleid = 1 and cs.playerdiscount>cs.discount and sporttype = 201 and bettype in (2,3)
	if (@@error <> 0)
	begin
		
		Select @ErrMsg = @UserName + ': '+
			case @Language 
							when 'E' then 'Update process is unsuccessful !'
							when 'CS' then N'更新程序不成功 !'
							when 'CT' then N'更新程序不成功 !'
							when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น !'
							when 'J' then N'アップデート出来ません。'
							when 'KO' then N'업데이트에 실패했습니다.'
							else N'Update process is unsuccessful !'
						end, @ErrCode = 110	
		return
	end

END

Declare @LogSPData varchar(5000)
Select @LogSPData = '<Acc_CustomerUpdCommissionFI custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'v201discount="'+ coalesce(cast(@v201discount as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ '" />'

--Log customer info 
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 208,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdCommissionFI] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdCommissionFI] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdCommissionFI] TO vnteam