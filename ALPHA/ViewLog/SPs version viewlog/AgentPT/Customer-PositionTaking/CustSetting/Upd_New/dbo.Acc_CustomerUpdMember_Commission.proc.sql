ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_Commission]
	@custid int,-- MemberId
	
	@playerdiscount DECIMAL(9,8),
	@playerdiscountcs DECIMAL(9,8),	
	@playerdiscount1x2 DECIMAL(9,8)=0,
	@updatecomm_old bit = 1,
	@SubAccID int = 0, --Sub-AccountID
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080514@Thien
Task : Update Member's Commission
DB: DB02.bodb02
Original:

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
					Write log subaccname instead of subaccid.
    - 20090514@PhuongDao: Add 1x2 Commission
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON

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
		@discount DECIMAL(9,8), @discountcs DECIMAL(9,8), @discount1x2 DECIMAL(9,8),@ugroup VARCHAR(10)
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
	
	--1x2
	SELECT @discount1x2 = discount
	FROM custsetting WITH (NOLOCK)
	WHERE custid = @recommend and sporttype = 1 and bettype = 5

	--@playerdiscount>g2?g2:@playerdiscount 
	--@playerdiscountcs>a2?a2:@playerdiscountcs
	SELECT 
		@playerdiscount = CASE WHEN @playerdiscount>@discount THEN @discount ELSE @playerdiscount END,
		@playerdiscountcs = CASE WHEN @playerdiscountcs>@discountcs THEN @discountcs ELSE @playerdiscountcs END,
		@playerdiscount1x2 = CASE WHEN @playerdiscount1x2>@discount1x2 THEN @discount1x2 ELSE @playerdiscount1x2 END		
	---------------------------------------
	UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
	SET	
		playerdiscount = CASE WHEN bettype IN (1,2,3,7,8) and sporttype <> 201 THEN @playerdiscount 
							  WHEN bettype = 5 THEN @playerdiscount1x2  
							  WHEN bettype IN (4,6,9,10,20,21,22) THEN @playerdiscountcs else playerdiscount end  
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

end

Declare @LogSPData varchar(5000)
Select @LogSPData = '<Acc_CustomerUpdMember_Commission custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'playerdiscount="'+ coalesce(cast(@playerdiscount as varchar(50)),space(1)) + '" ' +
'playerdiscountcs="'+ coalesce(cast(@playerdiscountcs as varchar(50)),space(1)) + '" ' +
'playerdiscount1x2="'+ coalesce(cast(@playerdiscount1x2 as varchar(50)),space(1)) + '" ' +
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
	@ActionID = 207,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Commission] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Commission] TO [bodbDownlineNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMember_Commission] TO vnteam 

