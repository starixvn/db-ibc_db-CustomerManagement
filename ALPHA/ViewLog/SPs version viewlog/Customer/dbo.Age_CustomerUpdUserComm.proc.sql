ALTER PROCEDURE [dbo].[Age_CustomerUpdUserComm]	
	@custid int, --customer to be updated
	@playerdiscount decimal(9,8),
	@playerdiscountcs decimal(9,8),
	@playerdiscount1x2 decimal(9,8),
	
	@userid int, --updater Id	
	@subaccid int = 0, --Sub-AccountID
	@language varchar(2) = 'E',
	@IP varchar(15)='',	
	@errcode int = 0 OUTPUT,
	@errmsg nvarchar(200) = '' OUTPUT
AS
 /*
Created: 20090213@nqminh
Task : Update commission of specific customer
DB: DB02.bodb02
Original:

Revisions:    
    - 20090318@Hanh: add Korean language
    - 20090411@Minh: remove constraint: if upline is disabled financial then do not update FI
	- 20090429@Phuc: remove code for calling sp Acc_CustomerUpdMember_Commission.
	- 20090526@Minh: add code for updating 1x2 group commission.
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @custid: custid that need to be viewed.   
• @playerdiscount: Player discount for group			(sportype = 1 and bettype = 1)
• @playerdiscountcs: Player discount for other types.	(sportype = 1 and bettype = 4)
• @playerdiscount1x2: Player discount for 1x2 bettype   (sportype = 1 and bettype = 5)

• @userid: updater id
• @subaccid: subaccId if any
• @language: updater's language
• @ip: updater's ip
• @errcode: error code
• @errmsg: error message if errcode > 0
*/

SET NOCOUNT ON

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

--Do update
Declare	@playerdiscount_old DECIMAL(9,8),
		@playerdiscountcs_old DECIMAL(9,8),		
		@playerdiscount1x2_old DECIMAL(9,8)
Declare @updatecomm_old bit

select @playerdiscount_old = playerdiscount
from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 1

select @playerdiscountcs_old = playerdiscount
from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 4

select @playerdiscount1x2_old = playerdiscount
from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 5

if @playerdiscount_old <> @playerdiscount or @playerdiscountcs_old <> @playerdiscountcs or @playerdiscount1x2 <> @playerdiscount1x2_old
	set @updatecomm_old = 1
else 
	set @updatecomm_old = 0
	
if @updatecomm_old = 0
	return

--Check Param
if	@playerdiscount<0 or @playerdiscount>0.2
	or @playerdiscountcs<0 or @playerdiscountcs>0.2
	or @playerdiscount1x2<0 or @playerdiscount1x2>0.2
BEGIN	
	Select @ErrMsg = case @Language 
						when 'E' then 'Wrong discount.'
						when 'CS' then N'折扣不正确.'
						when 'CT' then N'折扣不正確.'
						when 'TH' then N'การให้ส่วนลดไม่ถูกต้อง.'
						when 'J' then N'Wrong discount.'
						when 'KO' then N'잘못된 수수료.'
						else N'Wrong discount.'
					end, @ErrCode = 101
	return
END

---------------------------------------
Declare @username varchar(40), @recommend int,
		@discount DECIMAL(9,8), @discountcs DECIMAL(9,8), @ugroup VARCHAR(10),@discount1x2_max DECIMAL(9,8)
Select @UserName  = username,
		@recommend = recommend,
		@ugroup = c.ugroup
from customer c with (NOLOCK) where CustID = @CustID

if @updatecomm_old = 1
begin
	--Get g2
	SELECT 
		@discount = CASE WHEN @ugroup IN ('a','hka') THEN groupa 
						 WHEN @ugroup IN ('b','hkb') THEN groupb 
						 WHEN @ugroup IN ('c','hkc') THEN groupc 
						 WHEN @ugroup IN ('d','hkd') THEN groupd ELSE groupa END
	FROM custsetting WITH (NOLOCK)
	WHERE custid = @recommend AND bettype=1 AND sporttype=1
	--Get a2
	SELECT @discountcs = discount
	FROM custsetting WITH (NOLOCK)
	WHERE custid = @recommend and sporttype = 1 and bettype = 4

	--@playerdiscount>g2?g2:@playerdiscount 
	--@playerdiscountcs>a2?a2:@playerdiscountcs
	SELECT 
		@playerdiscount = CASE WHEN @playerdiscount>@discount THEN @discount ELSE @playerdiscount END,
		@playerdiscountcs = CASE WHEN @playerdiscountcs>@discountcs THEN @discountcs ELSE @playerdiscountcs END
		
	---------------------------------------
	UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
	SET	
		playerdiscount = CASE WHEN bettype IN (1,2,3,7,8) and sporttype <> 201 THEN @playerdiscount 
							  WHEN bettype IN (4,5,6,9,10,20,21,22) THEN @playerdiscountcs else playerdiscount end  
	WHERE custid=@custid
	
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
	
---- Update 1x2 commision ---------------------------------------------------------------------
	--Get a2
	SELECT @discount1x2_max = discount
	FROM custsetting WITH (NOLOCK)
	WHERE custid = @recommend and sporttype = 1 and bettype = 5

	SELECT @playerdiscount1x2 = case when @playerdiscount1x2 > @discount1x2_max then @discount1x2_max else @playerdiscount1x2 end		
	
	UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
	SET	
		playerdiscount = @playerdiscount1x2
	WHERE custid=@custid and sporttype = 1 and bettype = 5
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
end

	
--Error return
IF (@ErrCode > 0)
BEGIN
	Select @ErrMsg =
					case @language 
						when 'E' then 'Update process is unsuccessful.'
						when 'CS' then N'更新程序不成功。'
						when 'CT' then N'更新程序不成功。'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful.'
					end	, @ErrCode = 102
	return
END


------------------------
--Write log file

declare @LogSPData varchar(4000)
Select @LogSPData = '<Age_CustomerUpdUserComm CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1))+ '" ' +
'PlayerDiscount="'+ coalesce(cast(@playerdiscount as nvarchar(50)),space(1))+ '" ' +
'PlayerDiscountcs="'+ coalesce(cast(@playerdiscountcs as nvarchar(50)),space(1))+ '" ' +
'playerdiscount1x2="'+ coalesce(cast(@playerdiscount1x2 as nvarchar(50)),space(1))+ '" ' +
'IP="' + coalesce(cast(@IP as varchar(15)),space(1))+ '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1))+ '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1))+ '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+ '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1))+ '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 213,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdUserComm] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerUpdUserComm] TO vnteam