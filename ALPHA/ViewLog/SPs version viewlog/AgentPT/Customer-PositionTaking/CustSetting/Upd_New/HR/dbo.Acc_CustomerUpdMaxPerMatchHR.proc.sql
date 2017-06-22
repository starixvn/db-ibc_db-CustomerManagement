ALTER PROCEDURE [dbo].[Acc_CustomerUpdMaxPerMatchHR]
	@custid int,
	@MaxPerMatch money,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
	SET NOCOUNT ON
	update custinfo with (ROWLOCK, UPDLOCK)
	set 	
		MaxPerMatch151= @MaxPerMatch
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
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaxPerMatchHR] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaxPerMatchHR] TO [bodbDownlineNet]