ALTER PROCEDURE [dbo].[Acc_CustomerUpdMaxPerMatch]
	@custid int,
	@maxpermatch money,
	@maxpermatchv2 money,
	@maxpermatchv3 money,
	@maxpermatchv5 money,
	@maxpermatchv8 money,
	@maxpermatchv10 money,
	@maxpermatchv11 money,
	@maxpermatchv99 money,
	@UpdateMultiple bit = 0,	
	@UpdateMinMaxBet bit = 1,
	@UpdateMinMaxBetv2 bit = 1,
	@UpdateMinMaxBetv3 bit = 1,
	@UpdateMinMaxBetv5 bit = 1,
	@UpdateMinMaxBetv8 bit = 1,
	@UpdateMinMaxBetv10 bit = 1,
	@UpdateMinMaxBetv11 bit = 1,
	@UpdateMinMaxBetv99 bit = 1,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--Update Maxpermatch in db
/*
Created: 20081118@Phuc
Task : Update Maxpermatch
DB: DB02.bodb02
Original:

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

update custinfo with (ROWLOCK, UPDLOCK)
set 	
	MaxPerMatch=case when @UpdateMultiple = 0 or @UpdateMinMaxBet=1 then @MaxPerMatch else MaxPerMatch end,
	MaxPerMatch2=case when @UpdateMultiple = 0 or @UpdateMinMaxBetv2=1 then @MaxPerMatchv2 else MaxPerMatch2 end,
	MaxPerMatch3=case when @UpdateMultiple = 0 or @UpdateMinMaxBetv3=1 then @MaxPerMatchv3 else MaxPerMatch3 end,
	MaxPerMatch5=case when @UpdateMultiple = 0 or @UpdateMinMaxBetv5=1 then @MaxPerMatchv5 else MaxPerMatch5 end,
	MaxPerMatch8=case when @UpdateMultiple = 0 or @UpdateMinMaxBetv8=1 then @MaxPerMatchv8 else MaxPerMatch8 end,
	MaxPerMatch10=case when @UpdateMultiple = 0 or @UpdateMinMaxBetv10=1 then @MaxPerMatchv10 else MaxPerMatch10 end,
	MaxPerMatch11=case when @UpdateMultiple = 0 or @UpdateMinMaxBetv11=1 then @MaxPerMatchv11 else MaxPerMatch11 end,
	MaxPerMatch99=case when @UpdateMultiple = 0 or @UpdateMinMaxBetv99=1 then @MaxPerMatchv99 else MaxPerMatch99 end
where custid = @custid 
if (@@error <> 0)
begin
	Select @ErrMsg = case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 115
	return
end

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaxPerMatch] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaxPerMatch] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMaxPerMatch] TO vnteam