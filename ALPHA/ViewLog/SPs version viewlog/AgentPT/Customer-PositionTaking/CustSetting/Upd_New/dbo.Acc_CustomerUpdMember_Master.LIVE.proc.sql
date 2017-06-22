ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_Master_xtest] 
	@CustID int,--memberid
	@Closed bit,
	@suspended bit =null,
	@mpositiontaking_1 smallmoney OUTPUT,
	@mpositiontaking_2 smallmoney OUTPUT,
	@mpositiontaking_3 smallmoney OUTPUT,
	@mpositiontaking_4 smallmoney OUTPUT,
	@mpositiontaking_5 smallmoney OUTPUT,
	@mpositiontaking_6 smallmoney OUTPUT,
	@mpositiontaking_7 smallmoney OUTPUT,
	@mpositiontaking_8 smallmoney OUTPUT,
	@mpositiontaking_9 smallmoney OUTPUT,
	@mpositiontaking_10 smallmoney OUTPUT,
	@mlivepositiontaking_1 smallmoney OUTPUT,
	@mlivepositiontaking_3 smallmoney OUTPUT,
	@mlivepositiontaking_7 smallmoney OUTPUT,
	@mlivepositiontaking_8 smallmoney OUTPUT,
	
	@v2mpositiontaking_1 smallmoney OUTPUT,
	@v2mpositiontaking_2 smallmoney OUTPUT,
	@v2mpositiontaking_3 smallmoney OUTPUT,
	@v2mpositiontaking_7 smallmoney OUTPUT,
	@v2mpositiontaking_8 smallmoney OUTPUT,
	@v2mpositiontaking_9 smallmoney OUTPUT,
	@v2mpositiontaking_20 smallmoney OUTPUT,

	@v3mpositiontaking_1 smallmoney OUTPUT,
	@v3mpositiontaking_2 smallmoney OUTPUT,
	@v3mpositiontaking_3 smallmoney OUTPUT,
	@v3mpositiontaking_20 smallmoney OUTPUT,

	@v5mpositiontaking_1 smallmoney OUTPUT,
	@v5mpositiontaking_2 smallmoney OUTPUT,
	@v5mpositiontaking_3 smallmoney OUTPUT,
	@v5mpositiontaking_20 smallmoney OUTPUT,

	@v8mpositiontaking_1 smallmoney OUTPUT,
	@v8mpositiontaking_3 smallmoney OUTPUT,
	@v8mpositiontaking_20 smallmoney OUTPUT,

	@v10mpositiontaking_1 smallmoney OUTPUT,
	@v10mpositiontaking_2 smallmoney OUTPUT,
	@v10mpositiontaking_3 smallmoney OUTPUT,
	@v10mpositiontaking_20 smallmoney OUTPUT,

	@v11mpositiontaking_1 smallmoney OUTPUT,
	@v11mpositiontaking_20 smallmoney OUTPUT,

	--v201
	@v201mpositiontaking_3 smallmoney OUTPUT,

	@v99mpositiontaking_1 smallmoney OUTPUT,
	@v99mpositiontaking_2 smallmoney OUTPUT,
	@v99mpositiontaking_3 smallmoney OUTPUT,
	@v99mpositiontaking_20 smallmoney OUTPUT,
	--i2
	@isauto_mpositiontaking_1 bit = 0,
	@isauto_mpositiontaking_2 bit = 0,
	@isauto_mpositiontaking_3 bit = 0,
	@isauto_mpositiontaking_4 bit = 0,
	@isauto_mpositiontaking_5 bit= 0,
	@isauto_mpositiontaking_6 bit = 0,
	@isauto_mpositiontaking_7 bit = 0,
	@isauto_mpositiontaking_8 bit = 0,
	@isauto_mpositiontaking_9 bit = 0,
	@isauto_mpositiontaking_10 bit = 0,
	@isauto_mlivepositiontaking_1 bit = 0,
	@isauto_mlivepositiontaking_3 bit = 0,
	@isauto_mlivepositiontaking_7 bit = 0,
	@isauto_mlivepositiontaking_8 bit = 0,
	
	@isauto_v2mpositiontaking_1 bit = 0,
	@isauto_v2mpositiontaking_2 bit = 0,
	@isauto_v2mpositiontaking_3 bit = 0,
	@isauto_v2mpositiontaking_7 bit = 0,
	@isauto_v2mpositiontaking_8 bit = 0,
	@isauto_v2mpositiontaking_9 bit = 0,
	@isauto_v2mpositiontaking_20 bit = 0,
	
	@isauto_v3mpositiontaking_1 bit = 0,
	@isauto_v3mpositiontaking_2 bit = 0,
	@isauto_v3mpositiontaking_3 bit = 0,
	@isauto_v3mpositiontaking_20 bit = 0,
	
	@isauto_v5mpositiontaking_1 bit = 0,
	@isauto_v5mpositiontaking_2 bit = 0,
	@isauto_v5mpositiontaking_3 bit = 0,
	@isauto_v5mpositiontaking_20 bit = 0,
	
	@isauto_v8mpositiontaking_1 bit = 0,
	@isauto_v8mpositiontaking_3 bit = 0,
	@isauto_v8mpositiontaking_20 bit = 0,
	
	@isauto_v10mpositiontaking_1 bit = 0,
	@isauto_v10mpositiontaking_2 bit = 0,
	@isauto_v10mpositiontaking_3 bit = 0,
	@isauto_v10mpositiontaking_20 bit = 0,
	
	@isauto_v11mpositiontaking_1 bit = 0,
	@isauto_v11mpositiontaking_20 bit = 0,
	--v201
	@isauto_v201mpositiontaking_3 bit = 0,

	@isauto_v99mpositiontaking_1 bit = 0,
	@isauto_v99mpositiontaking_2 bit = 0,
	@isauto_v99mpositiontaking_3 bit = 0,
	@isauto_v99mpositiontaking_20 bit = 0,	
	
	@UserID int,--masterid	
	@UpdateMultiple bit =0, 
	@allowupdatepositiontaking bit = 1 OUTPUT,
	@Language varchar(2) = 'E',
	@SubAccID int = 0, --Sub-AccountID
	@IP varchar(15)='',
	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
--Original:???
--Master edits Member
--AGENT SITE
--Original SP: [Acc_CustomerUpdMaster_Member]


SET NOCOUNT ON
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

--Hard code copy PT for 201 from 2 sporttype will remove when deploy FI
Select	@v201mpositiontaking_3= @v2mpositiontaking_1,
	@isauto_v201mpositiontaking_3 = @isauto_v2mpositiontaking_1


/*
if not exists (select 1 from custinfo with (nolock) where custid = @custid and srecommend in (181940,197461))
BEGIN
	declare @ErrMsg varchar(200)
	Select @ErrMsg = 'Sorry, please try again later.'
	RaisError (@ErrMsg, 16, 1)
	return
END
*/
Declare @UplineClosed bit 
select @UplineClosed = isnull(closed,0) from custinfo where custid =@UserID 
IF @UplineClosed = 1 
BEGIN
	SELECT @ErrMsg =  CASE @Language 
						WHEN 'E' THEN 'Your account was closed. Cannot edit member.'
						WHEN 'CS' THEN N'您的账号已关闭，无法更改会员.'
						WHEN 'CT' THEN N'您的帳戶已關閉. 無法更改會員.'
						WHEN 'TH' THEN N'บัญชีของคุณถูกระงับใช้ ไม่สามารถแก้ไข.'
						WHEN 'J' THEN N'貴方のアカウントは閉鎖されています。新規メンバーの受付はできません。'
						ELSE N'Your account was closed. Cannot edit member.'
					END, @ErrCode = 119
	return
END 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check parameter

declare @IsValid bit

Select @isvalid = 1
if 
	@mpositiontaking_1  <0
	or @mpositiontaking_2  <0
	or @mpositiontaking_3  <0
	or @mpositiontaking_4  <0
	or @mpositiontaking_5  <0
	or @mpositiontaking_6  <0
	or @mpositiontaking_7  <0
	or @mpositiontaking_8  <0
	or @mpositiontaking_9  <0
	or @mpositiontaking_10 <0
	or @mlivepositiontaking_1  <0
	or @mlivepositiontaking_3  <0
	or @mlivepositiontaking_7  <0
	or @mlivepositiontaking_8  <0
	or @mpositiontaking_1  >0.9
	or @mpositiontaking_2  >0.9
	or @mpositiontaking_3  >0.9
	or @mpositiontaking_4  >0.9
	or @mpositiontaking_5  >0.9
	or @mpositiontaking_6  >0.9
	or @mpositiontaking_7  >0.9
	or @mpositiontaking_8  >0.9
	or @mpositiontaking_9  >0.9
	or @mpositiontaking_10 >0.9
	or @mlivepositiontaking_1  >0.9
	or @mlivepositiontaking_3  >0.9
	or @mlivepositiontaking_7  >0.9
	or @mlivepositiontaking_8  >0.9
	
	
	or @v2mpositiontaking_1 <0
	or @v2mpositiontaking_2 <0
	or @v2mpositiontaking_3 <0
	or @v2mpositiontaking_7 <0
	or @v2mpositiontaking_8 <0
	or @v2mpositiontaking_9 <0
	or @v2mpositiontaking_20 <0

	or @v3mpositiontaking_1 <0
	or @v3mpositiontaking_2 <0
	or @v3mpositiontaking_3 <0
	or @v3mpositiontaking_20 <0

	or @v5mpositiontaking_1 <0
	or @v5mpositiontaking_2 <0
	or @v5mpositiontaking_3 <0
	or @v5mpositiontaking_20 <0

	or @v8mpositiontaking_1 <0
	or @v8mpositiontaking_3 <0
	or @v8mpositiontaking_20 <0

	or @v10mpositiontaking_1 <0
	or @v10mpositiontaking_2 <0
	or @v10mpositiontaking_3 <0
	or @v10mpositiontaking_20 <0

	or @v11mpositiontaking_1 <0
	or @v11mpositiontaking_20 <0
	--v201
	or @v201mpositiontaking_3 <0

	or @v99mpositiontaking_1 <0
	or @v99mpositiontaking_2 <0
	or @v99mpositiontaking_3 <0
	or @v99mpositiontaking_20 <0
	
	or @v2mpositiontaking_1 >0.9
	or @v2mpositiontaking_2 >0.9
	or @v2mpositiontaking_3 >0.9
	or @v2mpositiontaking_7 >0.9
	or @v2mpositiontaking_8 >0.9
	or @v2mpositiontaking_9 >0.9
	or @v2mpositiontaking_20 >0.9

	or @v3mpositiontaking_1 >0.9
	or @v3mpositiontaking_2 >0.9
	or @v3mpositiontaking_3 >0.9
	or @v3mpositiontaking_20 >0.9

	or @v5mpositiontaking_1 >0.9
	or @v5mpositiontaking_2 >0.9
	or @v5mpositiontaking_3 >0.9
	or @v5mpositiontaking_20 >0.9

	or @v8mpositiontaking_1 >0.9
	or @v8mpositiontaking_3 >0.9
	or @v8mpositiontaking_20 >0.9

	or @v10mpositiontaking_1 >0.9
	or @v10mpositiontaking_2 >0.9
	or @v10mpositiontaking_3 >0.9
	or @v10mpositiontaking_20 >0.9

	or @v11mpositiontaking_1 >0.9
	or @v11mpositiontaking_20 >0.9
	--v201
	or @v201mpositiontaking_3 >0.9

	or @v99mpositiontaking_1 >0.9
	or @v99mpositiontaking_2 >0.9
	or @v99mpositiontaking_3 >0.9
	or @v99mpositiontaking_20 >0.9
BEGIN
	select @isvalid = 0, @ErrCode = 5
	Select @ErrMsg = 	case @Language 
						when 'E' then 'Wrong position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดไม่ถูกต้อง.'
						when 'J' then N'Wrong position taking.'
						else N'Wrong position taking.'
				end
	return
END

if @IsValid = 0
BEGIN
	RaisError (@ErrMsg, 16, 1)
	return
END


-- End check param
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


declare 
	@apositiontaking_1 smallmoney,
	@apositiontaking_2 smallmoney,
	@apositiontaking_3 smallmoney,
	@apositiontaking_4 smallmoney,
	@apositiontaking_5 smallmoney,
	@apositiontaking_6 smallmoney,
	@apositiontaking_7 smallmoney,
	@apositiontaking_8 smallmoney,
	@apositiontaking_9 smallmoney,
	@apositiontaking_10 smallmoney,
	@alivepositiontaking_1 smallmoney,
	@alivepositiontaking_3 smallmoney,
	@alivepositiontaking_7 smallmoney,
	@alivepositiontaking_8 smallmoney,
	
	@v2apositiontaking_1 smallmoney,
	@v2apositiontaking_2 smallmoney,
	@v2apositiontaking_3 smallmoney,
	@v2apositiontaking_7 smallmoney,
	@v2apositiontaking_8 smallmoney,
	@v2apositiontaking_9 smallmoney,
	@v2apositiontaking_20 smallmoney,

	@v3apositiontaking_1 smallmoney,
	@v3apositiontaking_2 smallmoney,
	@v3apositiontaking_3 smallmoney,
	@v3apositiontaking_20 smallmoney,

	@v5apositiontaking_1 smallmoney,
	@v5apositiontaking_2 smallmoney,
	@v5apositiontaking_3 smallmoney,
	@v5apositiontaking_20 smallmoney,

	@v8apositiontaking_1 smallmoney,
	@v8apositiontaking_3 smallmoney,
	@v8apositiontaking_20 smallmoney,

	@v10apositiontaking_1 smallmoney,
	@v10apositiontaking_2 smallmoney,
	@v10apositiontaking_3 smallmoney,
	@v10apositiontaking_20 smallmoney,

	@v11apositiontaking_1 smallmoney,
	@v11apositiontaking_20 smallmoney,
	--v201
	@v201apositiontaking_3 smallmoney,
	
	@v99apositiontaking_1 smallmoney,
	@v99apositiontaking_2 smallmoney,
	@v99apositiontaking_3 smallmoney,
	@v99apositiontaking_20 smallmoney,
	
	@old_mpositiontaking_1 smallmoney,
	@old_mpositiontaking_2 smallmoney,
	@old_mpositiontaking_3 smallmoney,
	@old_mpositiontaking_4 smallmoney,
	@old_mpositiontaking_5 smallmoney,
	@old_mpositiontaking_6 smallmoney,
	@old_mpositiontaking_7 smallmoney,
	@old_mpositiontaking_8 smallmoney,
	@old_mpositiontaking_9 smallmoney,
	@old_mpositiontaking_10 smallmoney,
	
	@old_mlivepositiontaking_1 smallmoney,
	@old_mlivepositiontaking_3 smallmoney,
	@old_mlivepositiontaking_7 smallmoney,
	@old_mlivepositiontaking_8 smallmoney,
	
	@old_v2mpositiontaking_1 smallmoney,
	@old_v2mpositiontaking_2 smallmoney,
	@old_v2mpositiontaking_3 smallmoney,
	@old_v2mpositiontaking_7 smallmoney,
	@old_v2mpositiontaking_8 smallmoney,
	@old_v2mpositiontaking_9 smallmoney,
	@old_v2mpositiontaking_20 smallmoney,

	@old_v3mpositiontaking_1 smallmoney,
	@old_v3mpositiontaking_2 smallmoney,
	@old_v3mpositiontaking_3 smallmoney,
	@old_v3mpositiontaking_20 smallmoney,

	@old_v5mpositiontaking_1 smallmoney,
	@old_v5mpositiontaking_2 smallmoney,
	@old_v5mpositiontaking_3 smallmoney,
	@old_v5mpositiontaking_20 smallmoney,

	@old_v8mpositiontaking_1 smallmoney,
	@old_v8mpositiontaking_3 smallmoney,
	@old_v8mpositiontaking_20 smallmoney,

	@old_v10mpositiontaking_1 smallmoney,
	@old_v10mpositiontaking_2 smallmoney,
	@old_v10mpositiontaking_3 smallmoney,
	@old_v10mpositiontaking_20 smallmoney,

	@old_v11mpositiontaking_1 smallmoney,
	@old_v11mpositiontaking_20 smallmoney,
	--v201
	@old_v201mpositiontaking_3 smallmoney,

	@old_v99mpositiontaking_1 smallmoney,
	@old_v99mpositiontaking_2 smallmoney,
	@old_v99mpositiontaking_3 smallmoney,
	@old_v99mpositiontaking_20 smallmoney,
	
	@old_closed bit,
	@old_suspended bit,
	@username varchar(30),
--	@maxpos smallmoney,
	@auto_spositiontaking_1 smallmoney,
	@auto_spositiontaking_2 smallmoney,
	@auto_spositiontaking_3 smallmoney,
	@auto_spositiontaking_4 smallmoney,
	@auto_spositiontaking_5 smallmoney,
	@auto_spositiontaking_6 smallmoney,
	@auto_spositiontaking_7 smallmoney,
	@auto_spositiontaking_8 smallmoney,
	@auto_spositiontaking_9 smallmoney,
	@auto_spositiontaking_10 smallmoney,
	
	@auto_slivepositiontaking_1 smallmoney,
	@auto_slivepositiontaking_3 smallmoney,
	@auto_slivepositiontaking_7 smallmoney,
	@auto_slivepositiontaking_8 smallmoney,
	
	@auto_v2spositiontaking_1 smallmoney,
	@auto_v2spositiontaking_2 smallmoney,
	@auto_v2spositiontaking_3 smallmoney,
	@auto_v2spositiontaking_7 smallmoney,
	@auto_v2spositiontaking_8 smallmoney,
	@auto_v2spositiontaking_9 smallmoney,
	@auto_v2spositiontaking_20 smallmoney,

	@auto_v3spositiontaking_1 smallmoney,
	@auto_v3spositiontaking_2 smallmoney,
	@auto_v3spositiontaking_3 smallmoney,
	@auto_v3spositiontaking_20 smallmoney,

	@auto_v5spositiontaking_1 smallmoney,
	@auto_v5spositiontaking_2 smallmoney,
	@auto_v5spositiontaking_3 smallmoney,
	@auto_v5spositiontaking_20 smallmoney,

	@auto_v8spositiontaking_1 smallmoney,
	@auto_v8spositiontaking_3 smallmoney,
	@auto_v8spositiontaking_20 smallmoney,

	@auto_v10spositiontaking_1 smallmoney,
	@auto_v10spositiontaking_2 smallmoney,
	@auto_v10spositiontaking_3 smallmoney,
	@auto_v10spositiontaking_20 smallmoney,

	@auto_v11spositiontaking_1 smallmoney,
	@auto_v11spositiontaking_20 smallmoney,
	--v201
	@auto_v201spositiontaking_3 smallmoney,

	@auto_v99spositiontaking_1 smallmoney,
	@auto_v99spositiontaking_2 smallmoney,
	@auto_v99spositiontaking_3 smallmoney,
	@auto_v99spositiontaking_20 smallmoney,
	
	@max_spositiontaking_1 smallmoney,
	@max_spositiontaking_2 smallmoney,
	@max_spositiontaking_3 smallmoney,
	@max_spositiontaking_4 smallmoney,
	@max_spositiontaking_5 smallmoney,
	@max_spositiontaking_6 smallmoney,
	@max_spositiontaking_7 smallmoney,
	@max_spositiontaking_8 smallmoney,
	@max_spositiontaking_9 smallmoney,
	@max_spositiontaking_10 smallmoney,
	
	@max_slivepositiontaking_1 smallmoney,
	@max_slivepositiontaking_3 smallmoney,
	@max_slivepositiontaking_7 smallmoney,
	@max_slivepositiontaking_8 smallmoney,
	
	@max_v2spositiontaking_1 smallmoney,
	@max_v2spositiontaking_2 smallmoney,
	@max_v2spositiontaking_3 smallmoney,
	@max_v2spositiontaking_7 smallmoney,
	@max_v2spositiontaking_8 smallmoney,
	@max_v2spositiontaking_9 smallmoney,
	@max_v2spositiontaking_20 smallmoney,

	@max_v3spositiontaking_1 smallmoney,
	@max_v3spositiontaking_2 smallmoney,
	@max_v3spositiontaking_3 smallmoney,
	@max_v3spositiontaking_20 smallmoney,

	@max_v5spositiontaking_1 smallmoney,
	@max_v5spositiontaking_2 smallmoney,
	@max_v5spositiontaking_3 smallmoney,
	@max_v5spositiontaking_20 smallmoney,

	@max_v8spositiontaking_1 smallmoney,
	@max_v8spositiontaking_3 smallmoney,
	@max_v8spositiontaking_20 smallmoney,

	@max_v10spositiontaking_1 smallmoney,
	@max_v10spositiontaking_2 smallmoney,
	@max_v10spositiontaking_3 smallmoney,
	@max_v10spositiontaking_20 smallmoney,

	@max_v11spositiontaking_1 smallmoney,
	@max_v11spositiontaking_20 smallmoney,

	--v201
	@max_v201spositiontaking_3 smallmoney,

	@max_v99spositiontaking_1 smallmoney,
	@max_v99spositiontaking_2 smallmoney,
	@max_v99spositiontaking_3 smallmoney,
	@max_v99spositiontaking_20 smallmoney,
	
	@spositiontaking_1 smallmoney,
	@spositiontaking_2 smallmoney,
	@spositiontaking_3 smallmoney,
	@spositiontaking_4 smallmoney,
	@spositiontaking_5 smallmoney,
	@spositiontaking_6 smallmoney,
	@spositiontaking_7 smallmoney,
	@spositiontaking_8 smallmoney,
	@spositiontaking_9 smallmoney,
	@spositiontaking_10 smallmoney,
	
	@slivepositiontaking_1 smallmoney,
	@slivepositiontaking_3 smallmoney,
	@slivepositiontaking_7 smallmoney,
	@slivepositiontaking_8 smallmoney,
	
	@v2spositiontaking_1 smallmoney,
	@v2spositiontaking_2 smallmoney,
	@v2spositiontaking_3 smallmoney,
	@v2spositiontaking_7 smallmoney,
	@v2spositiontaking_8 smallmoney,
	@v2spositiontaking_9 smallmoney,
	@v2spositiontaking_20 smallmoney,

	@v3spositiontaking_1 smallmoney,
	@v3spositiontaking_2 smallmoney,
	@v3spositiontaking_3 smallmoney,
	@v3spositiontaking_20 smallmoney,

	@v5spositiontaking_1 smallmoney,
	@v5spositiontaking_2 smallmoney,
	@v5spositiontaking_3 smallmoney,
	@v5spositiontaking_20 smallmoney,

	@v8spositiontaking_1 smallmoney,
	@v8spositiontaking_3 smallmoney,
	@v8spositiontaking_20 smallmoney,

	@v10spositiontaking_1 smallmoney,
	@v10spositiontaking_2 smallmoney,
	@v10spositiontaking_3 smallmoney,
	@v10spositiontaking_20 smallmoney,

	@v11spositiontaking_1 smallmoney,
	@v11spositiontaking_20 smallmoney,
	--V201
	@v201spositiontaking_3 smallmoney,

	@v99spositiontaking_1 smallmoney,
	@v99spositiontaking_2 smallmoney,
	@v99spositiontaking_3 smallmoney,
	@v99spositiontaking_20 smallmoney,
	
	@recommend int,
	@mrecommend int,
	@srecommend int,
	
	@member_auto_spositiontaking_1 smallmoney,
	@member_auto_spositiontaking_2 smallmoney,
	@member_auto_spositiontaking_3 smallmoney,
	@member_auto_spositiontaking_4 smallmoney,
	@member_auto_spositiontaking_5 smallmoney,
	@member_auto_spositiontaking_6 smallmoney,
	@member_auto_spositiontaking_7 smallmoney,
	@member_auto_spositiontaking_8 smallmoney,
	@member_auto_spositiontaking_9 smallmoney,
	@member_auto_spositiontaking_10 smallmoney,
	
	@member_auto_slivepositiontaking_1 smallmoney,
	@member_auto_slivepositiontaking_3 smallmoney,
	@member_auto_slivepositiontaking_7 smallmoney,
	@member_auto_slivepositiontaking_8 smallmoney,
	
	@member_auto_v2spositiontaking_1 smallmoney,
	@member_auto_v2spositiontaking_2 smallmoney,
	@member_auto_v2spositiontaking_3 smallmoney,
	@member_auto_v2spositiontaking_7 smallmoney,
	@member_auto_v2spositiontaking_8 smallmoney,
	@member_auto_v2spositiontaking_9 smallmoney,
	@member_auto_v2spositiontaking_20 smallmoney,

	@member_auto_v3spositiontaking_1 smallmoney,
	@member_auto_v3spositiontaking_2 smallmoney,
	@member_auto_v3spositiontaking_3 smallmoney,
	@member_auto_v3spositiontaking_20 smallmoney,

	@member_auto_v5spositiontaking_1 smallmoney,
	@member_auto_v5spositiontaking_2 smallmoney,
	@member_auto_v5spositiontaking_3 smallmoney,
	@member_auto_v5spositiontaking_20 smallmoney,

	@member_auto_v8spositiontaking_1 smallmoney,
	@member_auto_v8spositiontaking_3 smallmoney,
	@member_auto_v8spositiontaking_20 smallmoney,

	@member_auto_v10spositiontaking_1 smallmoney,
	@member_auto_v10spositiontaking_2 smallmoney,
	@member_auto_v10spositiontaking_3 smallmoney,
	@member_auto_v10spositiontaking_20 smallmoney,

	@member_auto_v11spositiontaking_1 smallmoney,
	@member_auto_v11spositiontaking_20 smallmoney,
	--v201
	@member_auto_v201spositiontaking_3 smallmoney,

	@member_auto_v99spositiontaking_1 smallmoney,
	@member_auto_v99spositiontaking_2 smallmoney,
	@member_auto_v99spositiontaking_3 smallmoney,
	@member_auto_v99spositiontaking_20 smallmoney,

	@member_isauto_spositiontaking_1 bit,
	@member_isauto_spositiontaking_2 bit,
	@member_isauto_spositiontaking_3 bit,
	@member_isauto_spositiontaking_4 bit,
	@member_isauto_spositiontaking_5 bit,
	@member_isauto_spositiontaking_6 bit,
	@member_isauto_spositiontaking_7 bit,
	@member_isauto_spositiontaking_8 bit,
	@member_isauto_spositiontaking_9 bit,
	@member_isauto_spositiontaking_10 bit,
	
	@member_isauto_slivepositiontaking_1 bit,
	@member_isauto_slivepositiontaking_3 bit,
	@member_isauto_slivepositiontaking_7 bit,
	@member_isauto_slivepositiontaking_8 bit,
	
	@member_isauto_v2spositiontaking_1 bit,
	@member_isauto_v2spositiontaking_2 bit,
	@member_isauto_v2spositiontaking_3 bit,
	@member_isauto_v2spositiontaking_7 bit,
	@member_isauto_v2spositiontaking_8 bit,
	@member_isauto_v2spositiontaking_9 bit,
	@member_isauto_v2spositiontaking_20 bit,

	@member_isauto_v3spositiontaking_1 bit,
	@member_isauto_v3spositiontaking_2 bit,
	@member_isauto_v3spositiontaking_3 bit,
	@member_isauto_v3spositiontaking_20 bit,

	@member_isauto_v5spositiontaking_1 bit,
	@member_isauto_v5spositiontaking_2 bit,
	@member_isauto_v5spositiontaking_3 bit,
	@member_isauto_v5spositiontaking_20 bit,

	@member_isauto_v8spositiontaking_1 bit,
	@member_isauto_v8spositiontaking_3 bit,
	@member_isauto_v8spositiontaking_20 bit,

	@member_isauto_v10spositiontaking_1 bit,
	@member_isauto_v10spositiontaking_2 bit,
	@member_isauto_v10spositiontaking_3 bit,
	@member_isauto_v10spositiontaking_20 bit,

	@member_isauto_v11spositiontaking_1 bit,
	@member_isauto_v11spositiontaking_20 bit,
	--v201
	@member_isauto_v201spositiontaking_3 bit,

	@member_isauto_v99spositiontaking_1 bit,
	@member_isauto_v99spositiontaking_2 bit,
	@member_isauto_v99spositiontaking_3 bit,
	@member_isauto_v99spositiontaking_20 bit,

	@isauto_spositiontaking_1 bit,
	@isauto_spositiontaking_2 bit,
	@isauto_spositiontaking_3 bit,
	@isauto_spositiontaking_4 bit,
	@isauto_spositiontaking_5 bit,
	@isauto_spositiontaking_6 bit,
	@isauto_spositiontaking_7 bit,
	@isauto_spositiontaking_8 bit,
	@isauto_spositiontaking_9 bit,
	@isauto_spositiontaking_10 bit,
	@isauto_slivepositiontaking_1 bit,
	@isauto_slivepositiontaking_3 bit,
	@isauto_slivepositiontaking_7 bit,
	@isauto_slivepositiontaking_8 bit,
	
	@isauto_v2spositiontaking_1 bit,
	@isauto_v2spositiontaking_2 bit,
	@isauto_v2spositiontaking_3 bit,
	@isauto_v2spositiontaking_7 bit,
	@isauto_v2spositiontaking_8 bit,
	@isauto_v2spositiontaking_9 bit,
	@isauto_v2spositiontaking_20 bit,

	@isauto_v3spositiontaking_1 bit,
	@isauto_v3spositiontaking_2 bit,
	@isauto_v3spositiontaking_3 bit,
	@isauto_v3spositiontaking_20 bit,

	@isauto_v5spositiontaking_1 bit,
	@isauto_v5spositiontaking_2 bit,
	@isauto_v5spositiontaking_3 bit,
	@isauto_v5spositiontaking_20 bit,

	@isauto_v8spositiontaking_1 bit,
	@isauto_v8spositiontaking_3 bit,
	@isauto_v8spositiontaking_20 bit,

	@isauto_v10spositiontaking_1 bit,
	@isauto_v10spositiontaking_2 bit,
	@isauto_v10spositiontaking_3 bit,
	@isauto_v10spositiontaking_20 bit,

	@isauto_v11spositiontaking_1 bit,
	@isauto_v11spositiontaking_20 bit,
	--v201
	@isauto_v201spositiontaking_3 bit,

	@isauto_v99spositiontaking_1 bit,
	@isauto_v99spositiontaking_2 bit,
	@isauto_v99spositiontaking_3 bit,
	@isauto_v99spositiontaking_20 bit

declare
	@max_mapositiontaking_1 smallmoney,
	@max_mapositiontaking_2 smallmoney,
	@max_mapositiontaking_3 smallmoney,
	@max_mapositiontaking_4 smallmoney,
	@max_mapositiontaking_5 smallmoney,
	@max_mapositiontaking_6 smallmoney,
	@max_mapositiontaking_7 smallmoney,
	@max_mapositiontaking_8 smallmoney,
	@max_mapositiontaking_9 smallmoney,
	@max_mapositiontaking_10 smallmoney,
	
	@max_malivepositiontaking_1 smallmoney,
	@max_malivepositiontaking_3 smallmoney,
	@max_malivepositiontaking_7 smallmoney,
	@max_malivepositiontaking_8 smallmoney,
	
	@max_v2mapositiontaking_1 smallmoney,
	@max_v2mapositiontaking_2 smallmoney,
	@max_v2mapositiontaking_3 smallmoney,
	@max_v2mapositiontaking_7 smallmoney,
	@max_v2mapositiontaking_8 smallmoney,
	@max_v2mapositiontaking_9 smallmoney,
	@max_v2mapositiontaking_20 smallmoney,

	@max_v3mapositiontaking_1 smallmoney,
	@max_v3mapositiontaking_2 smallmoney,
	@max_v3mapositiontaking_3 smallmoney,
	@max_v3mapositiontaking_20 smallmoney,

	@max_v5mapositiontaking_1 smallmoney,
	@max_v5mapositiontaking_2 smallmoney,
	@max_v5mapositiontaking_3 smallmoney,
	@max_v5mapositiontaking_20 smallmoney,

	@max_v8mapositiontaking_1 smallmoney,
	@max_v8mapositiontaking_3 smallmoney,
	@max_v8mapositiontaking_20 smallmoney,

	@max_v10mapositiontaking_1 smallmoney,
	@max_v10mapositiontaking_2 smallmoney,
	@max_v10mapositiontaking_3 smallmoney,
	@max_v10mapositiontaking_20 smallmoney,

	@max_v11mapositiontaking_1 smallmoney,
	@max_v11mapositiontaking_20 smallmoney,
	--v201
	@max_v201mapositiontaking_3 smallmoney,

	@max_v99mapositiontaking_1 smallmoney,
	@max_v99mapositiontaking_2 smallmoney,
	@max_v99mapositiontaking_3 smallmoney,
	@max_v99mapositiontaking_20 smallmoney
	
declare
	@min_mapositiontaking_1 smallmoney,
	@min_mapositiontaking_2 smallmoney,
	@min_mapositiontaking_3 smallmoney,
	@min_mapositiontaking_4 smallmoney,
	@min_mapositiontaking_5 smallmoney,
	@min_mapositiontaking_6 smallmoney,
	@min_mapositiontaking_7 smallmoney,
	@min_mapositiontaking_8 smallmoney,
	@min_mapositiontaking_9 smallmoney,
	@min_mapositiontaking_10 smallmoney,
	@min_malivepositiontaking_1 smallmoney,
	@min_malivepositiontaking_3 smallmoney,
	@min_malivepositiontaking_7 smallmoney,
	@min_malivepositiontaking_8 smallmoney,
	
	@min_v2mapositiontaking_1 smallmoney,
	@min_v2mapositiontaking_2 smallmoney,
	@min_v2mapositiontaking_3 smallmoney,
	@min_v2mapositiontaking_7 smallmoney,
	@min_v2mapositiontaking_8 smallmoney,
	@min_v2mapositiontaking_9 smallmoney,
	@min_v2mapositiontaking_20 smallmoney,

	@min_v3mapositiontaking_1 smallmoney,
	@min_v3mapositiontaking_2 smallmoney,
	@min_v3mapositiontaking_3 smallmoney,
	@min_v3mapositiontaking_20 smallmoney,

	@min_v5mapositiontaking_1 smallmoney,
	@min_v5mapositiontaking_2 smallmoney,
	@min_v5mapositiontaking_3 smallmoney,
	@min_v5mapositiontaking_20 smallmoney,

	@min_v8mapositiontaking_1 smallmoney,
	@min_v8mapositiontaking_3 smallmoney,
	@min_v8mapositiontaking_20 smallmoney,

	@min_v10mapositiontaking_1 smallmoney,
	@min_v10mapositiontaking_2 smallmoney,
	@min_v10mapositiontaking_3 smallmoney,
	@min_v10mapositiontaking_20 smallmoney,

	@min_v11mapositiontaking_1 smallmoney,
	@min_v11mapositiontaking_20 smallmoney,
	--v201
	@min_v201mapositiontaking_3 smallmoney,

	@min_v99mapositiontaking_1 smallmoney,
	@min_v99mapositiontaking_2 smallmoney,
	@min_v99mapositiontaking_3 smallmoney,
	@min_v99mapositiontaking_20 smallmoney

select @old_closed = closed, @old_suspended= reject ,@recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend, @username = username
from custinfo with (NOLOCK) where custid = @custid
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select @allowupdatepositiontaking = dbo.IsAllowChangePositiontaking(@mrecommend, getdate())

--Update Customer Info First.

UPDATE custinfo with (ROWLOCK, UPDLOCK) SET 
	closed=@closed ,
	reject = case when @suspended is null or @UpdateMultiple = 1 then reject else @suspended end 
WHERE custid=@CustID


--Log customer info
Declare @LogSPData varchar(5000)

Select @LogSPData = 'custid='+ coalesce(cast(@CustID as varchar(50)),space(1)) + ',
Closed='+ coalesce(cast(@Closed as varchar(50)),space(1)) + ',
suspended='+ coalesce(cast(@suspended as varchar(50)),space(1)) + ',
UserID='+ coalesce(cast(@UserID as varchar(50)),space(1)) + ',
allowUpdpt='+ coalesce(cast(@allowupdatepositiontaking as varchar(50)),space(1)) + ',
Language='+ coalesce(cast(@Language as varchar(2)),space(1))+',
SubAccID='+ coalesce(cast(@SubAccID as varchar(50)),space(1)) + ',
IP='+ coalesce(cast(@IP as varchar(15)),space(1))+',
ErrCode='+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + ',
ErrMsg='+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+'
'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
	@UserID = @UserID,
	@CustID = @CustID,
	@SpName = 'Acc_CustomerUpdMember_Master_xtest',
	@Doing = @LogSPData


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
if @srecommend>100 and @custid<>79711
BEGIN
	declare @ErrMsg varchar(200)
	Select @ErrMsg = 'Sorry, please try again later.'
	RaisError (@ErrMsg, 16, 1)
	return
END
*/
--s1,a1,old_m1,u1,i1
select @spositiontaking_1 = spositiontaking, @slivepositiontaking_1 = slivepositiontaking, @apositiontaking_1 = apositiontaking, @alivepositiontaking_1 = alivepositiontaking, @member_auto_spositiontaking_1 = autopositiontaking, @member_auto_slivepositiontaking_1 = autolivepositiontaking, @member_isauto_spositiontaking_1 = isautopositiontaking, @member_isauto_slivepositiontaking_1 = isautolivepositiontaking, @old_mpositiontaking_1 = mpositiontaking, @old_mlivepositiontaking_1 = mlivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=1
select @spositiontaking_3 = spositiontaking, @slivepositiontaking_3 = slivepositiontaking, @apositiontaking_3 = apositiontaking, @alivepositiontaking_3 = alivepositiontaking, @member_auto_spositiontaking_3 = autopositiontaking, @member_auto_slivepositiontaking_3 = autolivepositiontaking, @member_isauto_spositiontaking_3 = isautopositiontaking, @member_isauto_slivepositiontaking_3 = isautolivepositiontaking, @old_mpositiontaking_3 = mpositiontaking, @old_mlivepositiontaking_3 = mlivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=1
select @spositiontaking_7 = spositiontaking, @slivepositiontaking_7 = slivepositiontaking, @apositiontaking_7 = apositiontaking, @alivepositiontaking_7 = alivepositiontaking, @member_auto_spositiontaking_7 = autopositiontaking, @member_auto_slivepositiontaking_7 = autolivepositiontaking, @member_isauto_spositiontaking_7 = isautopositiontaking, @member_isauto_slivepositiontaking_7 = isautolivepositiontaking, @old_mpositiontaking_7 = mpositiontaking, @old_mlivepositiontaking_7 = mlivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=1
select @spositiontaking_8 = spositiontaking, @slivepositiontaking_8 = slivepositiontaking, @apositiontaking_8 = apositiontaking, @alivepositiontaking_8 = alivepositiontaking, @member_auto_spositiontaking_8 = autopositiontaking, @member_auto_slivepositiontaking_8 = autolivepositiontaking, @member_isauto_spositiontaking_8 = isautopositiontaking, @member_isauto_slivepositiontaking_8 = isautolivepositiontaking, @old_mpositiontaking_8 = mpositiontaking, @old_mlivepositiontaking_8 = mlivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=1

select @spositiontaking_2 = spositiontaking, @apositiontaking_2 = apositiontaking, @old_mpositiontaking_2 = mpositiontaking, @member_auto_spositiontaking_2 = autopositiontaking, @member_isauto_spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=1
select @spositiontaking_4 = spositiontaking, @apositiontaking_4 = apositiontaking, @old_mpositiontaking_4 = mpositiontaking, @member_auto_spositiontaking_4 = autopositiontaking, @member_isauto_spositiontaking_4 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=4 and sporttype=1
select @spositiontaking_5 = spositiontaking, @apositiontaking_5 = apositiontaking, @old_mpositiontaking_5 = mpositiontaking, @member_auto_spositiontaking_5 = autopositiontaking, @member_isauto_spositiontaking_5 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=5 and sporttype=1
select @spositiontaking_6 = spositiontaking, @apositiontaking_6 = apositiontaking, @old_mpositiontaking_6 = mpositiontaking, @member_auto_spositiontaking_6 = autopositiontaking, @member_isauto_spositiontaking_6 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=6 and sporttype=1
select @spositiontaking_9 = spositiontaking, @apositiontaking_9 = apositiontaking, @old_mpositiontaking_9 = mpositiontaking, @member_auto_spositiontaking_9 = autopositiontaking, @member_isauto_spositiontaking_9 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=1
select @spositiontaking_10 = spositiontaking, @apositiontaking_10 = apositiontaking, @old_mpositiontaking_10 = mpositiontaking, @member_auto_spositiontaking_10 = autopositiontaking, @member_isauto_spositiontaking_10 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=10 and sporttype=1

select @v2spositiontaking_1 = spositiontaking, @v2apositiontaking_1 = apositiontaking, @member_auto_v2spositiontaking_1 = autopositiontaking, @member_isauto_v2spositiontaking_1 = isautopositiontaking, @old_v2mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=2
select @v2spositiontaking_2 = spositiontaking, @v2apositiontaking_2 = apositiontaking, @member_auto_v2spositiontaking_2 = autopositiontaking, @member_isauto_v2spositiontaking_2 = isautopositiontaking, @old_v2mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=2
select @v2spositiontaking_3 = spositiontaking, @v2apositiontaking_3 = apositiontaking, @member_auto_v2spositiontaking_3 = autopositiontaking, @member_isauto_v2spositiontaking_3 = isautopositiontaking, @old_v2mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=2
select @v2spositiontaking_7 = spositiontaking, @v2apositiontaking_7 = apositiontaking, @member_auto_v2spositiontaking_7 = autopositiontaking, @member_isauto_v2spositiontaking_7 = isautopositiontaking, @old_v2mpositiontaking_7 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=2
select @v2spositiontaking_8 = spositiontaking, @v2apositiontaking_8 = apositiontaking, @member_auto_v2spositiontaking_8 = autopositiontaking, @member_isauto_v2spositiontaking_8 = isautopositiontaking, @old_v2mpositiontaking_8 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=2
select @v2spositiontaking_9 = spositiontaking, @v2apositiontaking_9 = apositiontaking, @member_auto_v2spositiontaking_9 = autopositiontaking, @member_isauto_v2spositiontaking_9 = isautopositiontaking, @old_v2mpositiontaking_9 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=2
select @v2spositiontaking_20 = spositiontaking, @v2apositiontaking_20 = apositiontaking, @member_auto_v2spositiontaking_20 = autopositiontaking, @member_isauto_v2spositiontaking_20 = isautopositiontaking, @old_v2mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=2

select @v3spositiontaking_1 = spositiontaking, @v3apositiontaking_1 = apositiontaking, @member_auto_v3spositiontaking_1 = autopositiontaking, @member_isauto_v3spositiontaking_1 = isautopositiontaking, @old_v3mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=3
select @v3spositiontaking_2 = spositiontaking, @v3apositiontaking_2 = apositiontaking, @member_auto_v3spositiontaking_2 = autopositiontaking, @member_isauto_v3spositiontaking_2 = isautopositiontaking, @old_v3mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=3
select @v3spositiontaking_3 = spositiontaking, @v3apositiontaking_3 = apositiontaking, @member_auto_v3spositiontaking_3 = autopositiontaking, @member_isauto_v3spositiontaking_3 = isautopositiontaking, @old_v3mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=3
select @v3spositiontaking_20 = spositiontaking, @v3apositiontaking_20 = apositiontaking, @member_auto_v3spositiontaking_20 = autopositiontaking, @member_isauto_v3spositiontaking_20 = isautopositiontaking, @old_v3mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=3

select @v5spositiontaking_1 = spositiontaking, @v5apositiontaking_1 = apositiontaking, @member_auto_v5spositiontaking_1 = autopositiontaking, @member_isauto_v5spositiontaking_1 = isautopositiontaking, @old_v5mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=5
select @v5spositiontaking_2 = spositiontaking, @v5apositiontaking_2 = apositiontaking, @member_auto_v5spositiontaking_2 = autopositiontaking, @member_isauto_v5spositiontaking_2 = isautopositiontaking, @old_v5mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=5
select @v5spositiontaking_3 = spositiontaking, @v5apositiontaking_3 = apositiontaking, @member_auto_v5spositiontaking_3 = autopositiontaking, @member_isauto_v5spositiontaking_3 = isautopositiontaking, @old_v5mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=5
select @v5spositiontaking_20 = spositiontaking, @v5apositiontaking_20 = apositiontaking, @member_auto_v5spositiontaking_20 = autopositiontaking, @member_isauto_v5spositiontaking_20 = isautopositiontaking, @old_v5mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=5

select @v8spositiontaking_1 = spositiontaking, @v8apositiontaking_1 = apositiontaking, @member_auto_v8spositiontaking_1 = autopositiontaking, @member_isauto_v8spositiontaking_1 = isautopositiontaking, @old_v8mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=8
select @v8spositiontaking_3 = spositiontaking, @v8apositiontaking_3 = apositiontaking, @member_auto_v8spositiontaking_3 = autopositiontaking, @member_isauto_v8spositiontaking_3 = isautopositiontaking, @old_v8mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=8
select @v8spositiontaking_20 = spositiontaking, @v8apositiontaking_20 = apositiontaking, @member_auto_v8spositiontaking_20 = autopositiontaking, @member_isauto_v8spositiontaking_20 = isautopositiontaking, @old_v8mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=8

select @v10spositiontaking_1 = spositiontaking, @v10apositiontaking_1 = apositiontaking, @member_auto_v10spositiontaking_1 = autopositiontaking, @member_isauto_v10spositiontaking_1 = isautopositiontaking, @old_v10mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=10
select @v10spositiontaking_2 = spositiontaking, @v10apositiontaking_2 = apositiontaking, @member_auto_v10spositiontaking_2 = autopositiontaking, @member_isauto_v10spositiontaking_2 = isautopositiontaking, @old_v10mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=10
select @v10spositiontaking_3 = spositiontaking, @v10apositiontaking_3 = apositiontaking, @member_auto_v10spositiontaking_3 = autopositiontaking, @member_isauto_v10spositiontaking_3 = isautopositiontaking, @old_v10mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=10
select @v10spositiontaking_20 = spositiontaking, @v10apositiontaking_20 = apositiontaking, @member_auto_v10spositiontaking_20 = autopositiontaking, @member_isauto_v10spositiontaking_20 = isautopositiontaking, @old_v10mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=10

select @v11spositiontaking_1 = spositiontaking, @v11apositiontaking_1 = apositiontaking, @member_auto_v11spositiontaking_1 = autopositiontaking, @member_isauto_v11spositiontaking_1 = isautopositiontaking, @old_v11mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=11
select @v11spositiontaking_20 = spositiontaking, @v11apositiontaking_20 = apositiontaking, @member_auto_v11spositiontaking_20 = autopositiontaking, @member_isauto_v11spositiontaking_20 = isautopositiontaking, @old_v11mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=11
--v201
select @v201spositiontaking_3 = spositiontaking, @v201apositiontaking_3 = apositiontaking, @member_auto_v201spositiontaking_3 = autopositiontaking, @member_isauto_v201spositiontaking_3 = isautopositiontaking, @old_v201mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=201

select @v99spositiontaking_1 = spositiontaking, @v99apositiontaking_1 = apositiontaking, @member_auto_v99spositiontaking_1 = autopositiontaking, @member_isauto_v99spositiontaking_1 = isautopositiontaking, @old_v99mpositiontaking_1 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=99
select @v99spositiontaking_2 = spositiontaking, @v99apositiontaking_2 = apositiontaking, @member_auto_v99spositiontaking_2 = autopositiontaking, @member_isauto_v99spositiontaking_2 = isautopositiontaking, @old_v99mpositiontaking_2 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=99
select @v99spositiontaking_3 = spositiontaking, @v99apositiontaking_3 = apositiontaking, @member_auto_v99spositiontaking_3 = autopositiontaking, @member_isauto_v99spositiontaking_3 = isautopositiontaking, @old_v99mpositiontaking_3 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=99
select @v99spositiontaking_20 = spositiontaking, @v99apositiontaking_20 = apositiontaking, @member_auto_v99spositiontaking_20 = autopositiontaking, @member_isauto_v99spositiontaking_20 = isautopositiontaking, @old_v99mpositiontaking_20 = mpositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=99

--Check if old_PT = new_PT return
IF @mpositiontaking_1 = @old_mpositiontaking_1 AND
	@mpositiontaking_2 = @old_mpositiontaking_2 AND
	@mpositiontaking_3 = @old_mpositiontaking_3 AND
	@mpositiontaking_4 = @old_mpositiontaking_4 AND
	@mpositiontaking_5 = @old_mpositiontaking_5 AND
	@mpositiontaking_6 = @old_mpositiontaking_6 AND
	@mpositiontaking_7 = @old_mpositiontaking_7 AND
	@mpositiontaking_8 = @old_mpositiontaking_8 AND
	@mpositiontaking_9 = @old_mpositiontaking_9 AND
	@mpositiontaking_10 = @old_mpositiontaking_10 AND
	@mlivepositiontaking_1 = @old_mlivepositiontaking_1 AND
	@mlivepositiontaking_3 = @old_mlivepositiontaking_3 AND
	@mlivepositiontaking_7 = @old_mlivepositiontaking_7 AND
	@mlivepositiontaking_8 = @old_mlivepositiontaking_8 AND

	@v2mpositiontaking_1 = @old_v2mpositiontaking_1 AND
	@v2mpositiontaking_2 = @old_v2mpositiontaking_2 AND
	@v2mpositiontaking_3 = @old_v2mpositiontaking_3 AND
	@v2mpositiontaking_7 = @old_v2mpositiontaking_7 AND
	@v2mpositiontaking_8 = @old_v2mpositiontaking_8 AND
	@v2mpositiontaking_9 = @old_v2mpositiontaking_9 AND
	@v2mpositiontaking_20 = @old_v2mpositiontaking_20 AND

	@v3mpositiontaking_1 = @old_v3mpositiontaking_1 AND
	@v3mpositiontaking_2 = @old_v3mpositiontaking_2 AND
	@v3mpositiontaking_3 = @old_v3mpositiontaking_3 AND
	@v3mpositiontaking_20 = @old_v3mpositiontaking_20 AND

	@v5mpositiontaking_1 = @old_v5mpositiontaking_1 AND
	@v5mpositiontaking_2 = @old_v5mpositiontaking_2 AND
	@v5mpositiontaking_3 = @old_v5mpositiontaking_3 AND
	@v5mpositiontaking_20 = @old_v5mpositiontaking_20 AND

	@v8mpositiontaking_1 = @old_v8mpositiontaking_1 AND
	@v8mpositiontaking_3 = @old_v8mpositiontaking_3 AND
	@v8mpositiontaking_20 = @old_v8mpositiontaking_20 AND

	@v10mpositiontaking_1 = @old_v10mpositiontaking_1 AND
	@v10mpositiontaking_2 = @old_v10mpositiontaking_2 AND
	@v10mpositiontaking_3 = @old_v10mpositiontaking_3 AND
	@v10mpositiontaking_20 = @old_v10mpositiontaking_20 AND

	@v11mpositiontaking_1 = @old_v11mpositiontaking_1 AND
	@v11mpositiontaking_20 = @old_v11mpositiontaking_20 AND
	@v201mpositiontaking_3 = @old_v201mpositiontaking_3 AND

	@v99mpositiontaking_1 = @old_v99mpositiontaking_1 AND
	@v99mpositiontaking_2 = @old_v99mpositiontaking_2 AND
	@v99mpositiontaking_3 = @old_v99mpositiontaking_3 AND
	@v99mpositiontaking_20 = @old_v99mpositiontaking_20 
BEGIN
	return 
END

--m3,u3,i3
select @max_mapositiontaking_1 =mpositiontaking, @max_malivepositiontaking_1 =mlivepositiontaking, @auto_spositiontaking_1 = autopositiontaking, @auto_slivepositiontaking_1 = autolivepositiontaking, @isauto_spositiontaking_1 = isautopositiontaking, @isauto_slivepositiontaking_1 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=1
select @max_mapositiontaking_3 =mpositiontaking, @max_malivepositiontaking_3 =mlivepositiontaking, @auto_spositiontaking_3 = autopositiontaking, @auto_slivepositiontaking_3 = autolivepositiontaking, @isauto_spositiontaking_3 = isautopositiontaking, @isauto_slivepositiontaking_3 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=1
select @max_mapositiontaking_7 =mpositiontaking, @max_malivepositiontaking_7 =mlivepositiontaking, @auto_spositiontaking_7 = autopositiontaking, @auto_slivepositiontaking_7 = autolivepositiontaking, @isauto_spositiontaking_7 = isautopositiontaking, @isauto_slivepositiontaking_7 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=1
select @max_mapositiontaking_8 =mpositiontaking, @max_malivepositiontaking_8 =mlivepositiontaking, @auto_spositiontaking_8 = autopositiontaking, @auto_slivepositiontaking_8 = autolivepositiontaking, @isauto_spositiontaking_8 = isautopositiontaking, @isauto_slivepositiontaking_8 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=1
select @max_mapositiontaking_2 =mpositiontaking, @auto_spositiontaking_2 = autopositiontaking, @isauto_spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=1
select @max_mapositiontaking_4 =mpositiontaking, @auto_spositiontaking_4 = autopositiontaking, @isauto_spositiontaking_4 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=4 and sporttype=1
select @max_mapositiontaking_5 =mpositiontaking, @auto_spositiontaking_5 = autopositiontaking, @isauto_spositiontaking_5 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=5 and sporttype=1
select @max_mapositiontaking_6 =mpositiontaking, @auto_spositiontaking_6 = autopositiontaking, @isauto_spositiontaking_6 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=6 and sporttype=1
select @max_mapositiontaking_9 =mpositiontaking, @auto_spositiontaking_9 = autopositiontaking, @isauto_spositiontaking_9 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=1
select @max_mapositiontaking_10 =mpositiontaking, @auto_spositiontaking_10 = autopositiontaking, @isauto_spositiontaking_10 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=10 and sporttype=1

select @max_v2mapositiontaking_1 =mpositiontaking, @auto_v2spositiontaking_1 = autopositiontaking, @isauto_v2spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=2
select @max_v2mapositiontaking_2 =mpositiontaking, @auto_v2spositiontaking_2 = autopositiontaking, @isauto_v2spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=2
select @max_v2mapositiontaking_3 =mpositiontaking, @auto_v2spositiontaking_3 = autopositiontaking, @isauto_v2spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=2
select @max_v2mapositiontaking_7 =mpositiontaking, @auto_v2spositiontaking_7 = autopositiontaking, @isauto_v2spositiontaking_7 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=2
select @max_v2mapositiontaking_8 =mpositiontaking, @auto_v2spositiontaking_8 = autopositiontaking, @isauto_v2spositiontaking_8 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=2
select @max_v2mapositiontaking_9 =mpositiontaking, @auto_v2spositiontaking_9 = autopositiontaking, @isauto_v2spositiontaking_9 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=2
select @max_v2mapositiontaking_20 =mpositiontaking, @auto_v2spositiontaking_20 = autopositiontaking, @isauto_v2spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=2

select @max_v3mapositiontaking_1 =mpositiontaking, @auto_v3spositiontaking_1 = autopositiontaking, @isauto_v3spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=3
select @max_v3mapositiontaking_2 =mpositiontaking, @auto_v3spositiontaking_2 = autopositiontaking, @isauto_v3spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=3
select @max_v3mapositiontaking_3 =mpositiontaking, @auto_v3spositiontaking_3 = autopositiontaking, @isauto_v3spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=3
select @max_v3mapositiontaking_20 =mpositiontaking, @auto_v3spositiontaking_20 = autopositiontaking, @isauto_v3spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=3

select @max_v5mapositiontaking_1 =mpositiontaking, @auto_v5spositiontaking_1 = autopositiontaking, @isauto_v5spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=5
select @max_v5mapositiontaking_2 =mpositiontaking, @auto_v5spositiontaking_2 = autopositiontaking, @isauto_v5spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=5
select @max_v5mapositiontaking_3 =mpositiontaking, @auto_v5spositiontaking_3 = autopositiontaking, @isauto_v5spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=5
select @max_v5mapositiontaking_20 =mpositiontaking, @auto_v5spositiontaking_20 = autopositiontaking, @isauto_v5spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=5

select @max_v8mapositiontaking_1 =mpositiontaking, @auto_v8spositiontaking_1 = autopositiontaking, @isauto_v8spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=8
select @max_v8mapositiontaking_3 =mpositiontaking, @auto_v8spositiontaking_3 = autopositiontaking, @isauto_v8spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=8
select @max_v8mapositiontaking_20 =mpositiontaking, @auto_v8spositiontaking_20 = autopositiontaking, @isauto_v8spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=8

select @max_v10mapositiontaking_1 =mpositiontaking, @auto_v10spositiontaking_1 = autopositiontaking, @isauto_v10spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=10
select @max_v10mapositiontaking_2 =mpositiontaking, @auto_v10spositiontaking_2 = autopositiontaking, @isauto_v10spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=10
select @max_v10mapositiontaking_3 =mpositiontaking, @auto_v10spositiontaking_3 = autopositiontaking, @isauto_v10spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=10
select @max_v10mapositiontaking_20 =mpositiontaking, @auto_v10spositiontaking_20 = autopositiontaking, @isauto_v10spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=10

select @max_v11mapositiontaking_1 =mpositiontaking, @auto_v11spositiontaking_1 = autopositiontaking, @isauto_v11spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=11
select @max_v11mapositiontaking_20 =mpositiontaking, @auto_v11spositiontaking_20 = autopositiontaking, @isauto_v11spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=11
--v201
select @max_v201mapositiontaking_3 =mpositiontaking, @auto_v201spositiontaking_3 = autopositiontaking, @isauto_v201spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=201

select @max_v99mapositiontaking_1 =mpositiontaking, @auto_v99spositiontaking_1 = autopositiontaking, @isauto_v99spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=99
select @max_v99mapositiontaking_2 =mpositiontaking, @auto_v99spositiontaking_2 = autopositiontaking, @isauto_v99spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=99
select @max_v99mapositiontaking_3 =mpositiontaking, @auto_v99spositiontaking_3 = autopositiontaking, @isauto_v99spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=99
select @max_v99mapositiontaking_20 =mpositiontaking, @auto_v99spositiontaking_20 = autopositiontaking, @isauto_v99spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=99

--m1>m3?m3:m1
select 
	@mpositiontaking_1 = case when @mpositiontaking_1>@max_mapositiontaking_1 then @max_mapositiontaking_1 else @mpositiontaking_1 end,
	@mpositiontaking_2 = case when @mpositiontaking_2>@max_mapositiontaking_2 then @max_mapositiontaking_2 else @mpositiontaking_2 end,
	@mpositiontaking_3 = case when @mpositiontaking_3>@max_mapositiontaking_3 then @max_mapositiontaking_3 else @mpositiontaking_3 end,
	@mpositiontaking_4 = case when @mpositiontaking_4>@max_mapositiontaking_4 then @max_mapositiontaking_4 else @mpositiontaking_4 end,
	@mpositiontaking_5 = case when @mpositiontaking_5>@max_mapositiontaking_5 then @max_mapositiontaking_5 else @mpositiontaking_5 end,
	@mpositiontaking_6 = case when @mpositiontaking_6>@max_mapositiontaking_6 then @max_mapositiontaking_6 else @mpositiontaking_6 end,
	@mpositiontaking_7 = case when @mpositiontaking_7>@max_mapositiontaking_7 then @max_mapositiontaking_7 else @mpositiontaking_7 end,
	@mpositiontaking_8 = case when @mpositiontaking_8>@max_mapositiontaking_8 then @max_mapositiontaking_8 else @mpositiontaking_8 end,
	@mpositiontaking_9 = case when @mpositiontaking_9>@max_mapositiontaking_9 then @max_mapositiontaking_9 else @mpositiontaking_9 end,
	@mpositiontaking_10 = case when @mpositiontaking_10>@max_mapositiontaking_10 then @max_mapositiontaking_10 else @mpositiontaking_10 end,

	@mlivepositiontaking_1 = case when @mlivepositiontaking_1>@max_malivepositiontaking_1 then @max_malivepositiontaking_1 else @mlivepositiontaking_1 end,
	@mlivepositiontaking_3 = case when @mlivepositiontaking_3>@max_malivepositiontaking_3 then @max_malivepositiontaking_3 else @mlivepositiontaking_3 end,
	@mlivepositiontaking_7 = case when @mlivepositiontaking_7>@max_malivepositiontaking_7 then @max_malivepositiontaking_7 else @mlivepositiontaking_7 end,
	@mlivepositiontaking_8 = case when @mlivepositiontaking_8>@max_malivepositiontaking_8 then @max_malivepositiontaking_8 else @mlivepositiontaking_8 end,

	@v2mpositiontaking_1 = case when @v2mpositiontaking_1>@max_v2mapositiontaking_1 then @max_v2mapositiontaking_1 else @v2mpositiontaking_1 end,
	@v2mpositiontaking_2 = case when @v2mpositiontaking_2>@max_v2mapositiontaking_2 then @max_v2mapositiontaking_2 else @v2mpositiontaking_2 end,
	@v2mpositiontaking_3 = case when @v2mpositiontaking_3>@max_v2mapositiontaking_3 then @max_v2mapositiontaking_3 else @v2mpositiontaking_3 end,
	@v2mpositiontaking_7 = case when @v2mpositiontaking_7>@max_v2mapositiontaking_7 then @max_v2mapositiontaking_7 else @v2mpositiontaking_7 end,
	@v2mpositiontaking_8 = case when @v2mpositiontaking_8>@max_v2mapositiontaking_8 then @max_v2mapositiontaking_8 else @v2mpositiontaking_8 end,
	@v2mpositiontaking_9 = case when @v2mpositiontaking_9>@max_v2mapositiontaking_9 then @max_v2mapositiontaking_9 else @v2mpositiontaking_9 end,
	@v2mpositiontaking_20 = case when @v2mpositiontaking_20>@max_v2mapositiontaking_20 then @max_v2mapositiontaking_20 else @v2mpositiontaking_20 end,

	@v3mpositiontaking_1 = case when @v3mpositiontaking_1>@max_v3mapositiontaking_1 then @max_v3mapositiontaking_1 else @v3mpositiontaking_1 end,
	@v3mpositiontaking_2 = case when @v3mpositiontaking_2>@max_v3mapositiontaking_2 then @max_v3mapositiontaking_2 else @v3mpositiontaking_2 end,
	@v3mpositiontaking_3 = case when @v3mpositiontaking_3>@max_v3mapositiontaking_3 then @max_v3mapositiontaking_3 else @v3mpositiontaking_3 end,
	@v3mpositiontaking_20 = case when @v3mpositiontaking_20>@max_v3mapositiontaking_20 then @max_v3mapositiontaking_20 else @v3mpositiontaking_20 end,

	@v5mpositiontaking_1 = case when @v5mpositiontaking_1>@max_v5mapositiontaking_1 then @max_v5mapositiontaking_1 else @v5mpositiontaking_1 end,
	@v5mpositiontaking_2 = case when @v5mpositiontaking_2>@max_v5mapositiontaking_2 then @max_v5mapositiontaking_2 else @v5mpositiontaking_2 end,
	@v5mpositiontaking_3 = case when @v5mpositiontaking_3>@max_v5mapositiontaking_3 then @max_v5mapositiontaking_3 else @v5mpositiontaking_3 end,
	@v5mpositiontaking_20 = case when @v5mpositiontaking_20>@max_v5mapositiontaking_20 then @max_v5mapositiontaking_20 else @v5mpositiontaking_20 end,

	@v8mpositiontaking_1 = case when @v8mpositiontaking_1>@max_v8mapositiontaking_1 then @max_v8mapositiontaking_1 else @v8mpositiontaking_1 end,
	@v8mpositiontaking_3 = case when @v8mpositiontaking_3>@max_v8mapositiontaking_3 then @max_v8mapositiontaking_3 else @v8mpositiontaking_3 end,
	@v8mpositiontaking_20 = case when @v8mpositiontaking_20>@max_v8mapositiontaking_20 then @max_v8mapositiontaking_20 else @v8mpositiontaking_20 end,

	@v10mpositiontaking_1 = case when @v10mpositiontaking_1>@max_v10mapositiontaking_1 then @max_v10mapositiontaking_1 else @v10mpositiontaking_1 end,
	@v10mpositiontaking_2 = case when @v10mpositiontaking_2>@max_v10mapositiontaking_2 then @max_v10mapositiontaking_2 else @v10mpositiontaking_2 end,
	@v10mpositiontaking_3 = case when @v10mpositiontaking_3>@max_v10mapositiontaking_3 then @max_v10mapositiontaking_3 else @v10mpositiontaking_3 end,
	@v10mpositiontaking_20 = case when @v10mpositiontaking_20>@max_v10mapositiontaking_20 then @max_v10mapositiontaking_20 else @v10mpositiontaking_20 end,

	@v11mpositiontaking_1 = case when @v11mpositiontaking_1>@max_v11mapositiontaking_1 then @max_v11mapositiontaking_1 else @v11mpositiontaking_1 end,
	@v11mpositiontaking_20 = case when @v11mpositiontaking_20>@max_v11mapositiontaking_20 then @max_v11mapositiontaking_20 else @v11mpositiontaking_20 end,
	--v201
	@v201mpositiontaking_3 = case when @v201mpositiontaking_3>@max_v201mapositiontaking_3 then @max_v201mapositiontaking_3 else @v201mpositiontaking_3 end,

	@v99mpositiontaking_1 = case when @v99mpositiontaking_1>@max_v99mapositiontaking_1 then @max_v99mapositiontaking_1 else @v99mpositiontaking_1 end,
	@v99mpositiontaking_2 = case when @v99mpositiontaking_2>@max_v99mapositiontaking_2 then @max_v99mapositiontaking_2 else @v99mpositiontaking_2 end,
	@v99mpositiontaking_3 = case when @v99mpositiontaking_3>@max_v99mapositiontaking_3 then @max_v99mapositiontaking_3 else @v99mpositiontaking_3 end,
	@v99mpositiontaking_20 = case when @v99mpositiontaking_20>@max_v99mapositiontaking_20 then @max_v99mapositiontaking_20 else @v99mpositiontaking_20 end
/*
--m1=m1+a1>m3?m3-a1:m1
select 
	@mpositiontaking_1 = case when @mpositiontaking_1+@apositiontaking_1>@max_mapositiontaking_1 then @max_mapositiontaking_1-@apositiontaking_1 else @mpositiontaking_1 end,
	@mpositiontaking_2 = case when @mpositiontaking_2+@apositiontaking_2>@max_mapositiontaking_2 then @max_mapositiontaking_2-@apositiontaking_2 else @mpositiontaking_2 end,
	@mpositiontaking_3 = case when @mpositiontaking_3+@apositiontaking_3>@max_mapositiontaking_3 then @max_mapositiontaking_3-@apositiontaking_3 else @mpositiontaking_3 end,
	@mpositiontaking_4 = case when @mpositiontaking_4+@apositiontaking_4>@max_mapositiontaking_4 then @max_mapositiontaking_4-@apositiontaking_4 else @mpositiontaking_4 end,
	@mpositiontaking_5 = case when @mpositiontaking_5+@apositiontaking_5>@max_mapositiontaking_5 then @max_mapositiontaking_5-@apositiontaking_5 else @mpositiontaking_5 end,
	@mpositiontaking_6 = case when @mpositiontaking_6+@apositiontaking_6>@max_mapositiontaking_6 then @max_mapositiontaking_6-@apositiontaking_6 else @mpositiontaking_6 end,
	@mpositiontaking_7 = case when @mpositiontaking_7+@apositiontaking_7>@max_mapositiontaking_7 then @max_mapositiontaking_7-@apositiontaking_7 else @mpositiontaking_7 end,
	@mpositiontaking_8 = case when @mpositiontaking_8+@apositiontaking_8>@max_mapositiontaking_8 then @max_mapositiontaking_8-@apositiontaking_8 else @mpositiontaking_8 end,
	@mpositiontaking_9 = case when @mpositiontaking_9+@apositiontaking_9>@max_mapositiontaking_9 then @max_mapositiontaking_9-@apositiontaking_9 else @mpositiontaking_9 end,
	@mpositiontaking_10 = case when @mpositiontaking_10+@apositiontaking_10>@max_mapositiontaking_10 then @max_mapositiontaking_10-@apositiontaking_10 else @mpositiontaking_10 end,

	@mlivepositiontaking_1 = case when @mlivepositiontaking_1+@alivepositiontaking_1>@max_malivepositiontaking_1 then @max_malivepositiontaking_1-@alivepositiontaking_1 else @mlivepositiontaking_1 end,
	@mlivepositiontaking_3 = case when @mlivepositiontaking_3+@alivepositiontaking_3>@max_malivepositiontaking_3 then @max_malivepositiontaking_3-@alivepositiontaking_3 else @mlivepositiontaking_3 end,
	@mlivepositiontaking_7 = case when @mlivepositiontaking_7+@alivepositiontaking_7>@max_malivepositiontaking_7 then @max_malivepositiontaking_7-@alivepositiontaking_7 else @mlivepositiontaking_7 end,
	@mlivepositiontaking_8 = case when @mlivepositiontaking_8+@alivepositiontaking_8>@max_malivepositiontaking_8 then @max_malivepositiontaking_8-@alivepositiontaking_8 else @mlivepositiontaking_8 end,

	@v2mpositiontaking_1 = case when @v2apositiontaking_1+@v2mpositiontaking_1>@max_v2mapositiontaking_1 then @max_v2mapositiontaking_1-@v2apositiontaking_1 else @v2mpositiontaking_1 end,
	@v2mpositiontaking_2 = case when @v2apositiontaking_2+@v2mpositiontaking_2>@max_v2mapositiontaking_2 then @max_v2mapositiontaking_2-@v2apositiontaking_2 else @v2mpositiontaking_2 end,
	@v2mpositiontaking_3 = case when @v2apositiontaking_3+@v2mpositiontaking_3>@max_v2mapositiontaking_3 then @max_v2mapositiontaking_3-@v2apositiontaking_3 else @v2mpositiontaking_3 end,
	@v2mpositiontaking_7 = case when @v2apositiontaking_7+@v2mpositiontaking_7>@max_v2mapositiontaking_7 then @max_v2mapositiontaking_7-@v2apositiontaking_7 else @v2mpositiontaking_7 end,
	@v2mpositiontaking_8 = case when @v2apositiontaking_8+@v2mpositiontaking_8>@max_v2mapositiontaking_8 then @max_v2mapositiontaking_8-@v2apositiontaking_8 else @v2mpositiontaking_8 end,
	@v2mpositiontaking_9 = case when @v2apositiontaking_9+@v2mpositiontaking_9>@max_v2mapositiontaking_9 then @max_v2mapositiontaking_9-@v2apositiontaking_9 else @v2mpositiontaking_9 end,
	@v2mpositiontaking_20 = case when @v2apositiontaking_20+@v2mpositiontaking_20>@max_v2mapositiontaking_20 then @max_v2mapositiontaking_20-@v2apositiontaking_20 else @v2mpositiontaking_20 end,

	@v3mpositiontaking_1 = case when @v3apositiontaking_1+@v3mpositiontaking_1>@max_v3mapositiontaking_1 then @max_v3mapositiontaking_1-@v3apositiontaking_1 else @v3mpositiontaking_1 end,
	@v3mpositiontaking_2 = case when @v3apositiontaking_2+@v3mpositiontaking_2>@max_v3mapositiontaking_2 then @max_v3mapositiontaking_2-@v3apositiontaking_2 else @v3mpositiontaking_2 end,
	@v3mpositiontaking_3 = case when @v3apositiontaking_3+@v3mpositiontaking_3>@max_v3mapositiontaking_3 then @max_v3mapositiontaking_3-@v3apositiontaking_3 else @v3mpositiontaking_3 end,
	@v3mpositiontaking_20 = case when @v3apositiontaking_20+@v3mpositiontaking_20>@max_v3mapositiontaking_20 then @max_v3mapositiontaking_20-@v3apositiontaking_20 else @v3mpositiontaking_20 end,

	@v5mpositiontaking_1 = case when @v5apositiontaking_1+@v5mpositiontaking_1>@max_v5mapositiontaking_1 then @max_v5mapositiontaking_1-@v5apositiontaking_1 else @v5mpositiontaking_1 end,
	@v5mpositiontaking_2 = case when @v5apositiontaking_2+@v5mpositiontaking_2>@max_v5mapositiontaking_2 then @max_v5mapositiontaking_2-@v5apositiontaking_2 else @v5mpositiontaking_2 end,
	@v5mpositiontaking_3 = case when @v5apositiontaking_3+@v5mpositiontaking_3>@max_v5mapositiontaking_3 then @max_v5mapositiontaking_3-@v5apositiontaking_3 else @v5mpositiontaking_3 end,
	@v5mpositiontaking_20 = case when @v5apositiontaking_20+@v5mpositiontaking_20>@max_v5mapositiontaking_20 then @max_v5mapositiontaking_20-@v5apositiontaking_20 else @v5mpositiontaking_20 end,

	@v8mpositiontaking_1 = case when @v8apositiontaking_1+@v8mpositiontaking_1>@max_v8mapositiontaking_1 then @max_v8mapositiontaking_1-@v8apositiontaking_1 else @v8mpositiontaking_1 end,
	@v8mpositiontaking_3 = case when @v8apositiontaking_3+@v8mpositiontaking_3>@max_v8mapositiontaking_3 then @max_v8mapositiontaking_3-@v8apositiontaking_3 else @v8mpositiontaking_3 end,
	@v8mpositiontaking_20 = case when @v8apositiontaking_20+@v8mpositiontaking_20>@max_v8mapositiontaking_20 then @max_v8mapositiontaking_20-@v8apositiontaking_20 else @v8mpositiontaking_20 end,

	@v10mpositiontaking_1 = case when @v10apositiontaking_1+@v10mpositiontaking_1>@max_v10mapositiontaking_1 then @max_v10mapositiontaking_1-@v10apositiontaking_1 else @v10mpositiontaking_1 end,
	@v10mpositiontaking_2 = case when @v10apositiontaking_2+@v10mpositiontaking_2>@max_v10mapositiontaking_2 then @max_v10mapositiontaking_2-@v10apositiontaking_2 else @v10mpositiontaking_2 end,
	@v10mpositiontaking_3 = case when @v10apositiontaking_3+@v10mpositiontaking_3>@max_v10mapositiontaking_3 then @max_v10mapositiontaking_3-@v10apositiontaking_3 else @v10mpositiontaking_3 end,
	@v10mpositiontaking_20 = case when @v10apositiontaking_20+@v10mpositiontaking_20>@max_v10mapositiontaking_20 then @max_v10mapositiontaking_20-@v10apositiontaking_20 else @v10mpositiontaking_20 end,

	@v11mpositiontaking_1 = case when @v11apositiontaking_1+@v11mpositiontaking_1>@max_v11mapositiontaking_1 then @max_v11mapositiontaking_1-@v11apositiontaking_1 else @v11mpositiontaking_1 end,
	@v11mpositiontaking_20 = case when @v11apositiontaking_20+@v11mpositiontaking_20>@max_v11mapositiontaking_20 then @max_v11mapositiontaking_20-@v11apositiontaking_20 else @v11mpositiontaking_20 end,
	--v201
	@v201mpositiontaking_3 = case when @v201apositiontaking_3+@v201mpositiontaking_3>@max_v201mapositiontaking_3 then @max_v201mapositiontaking_3-@v201apositiontaking_3 else @v201mpositiontaking_3 end,

	@v99mpositiontaking_1 = case when @v99apositiontaking_1+@v99mpositiontaking_1>@max_v99mapositiontaking_1 then @max_v99mapositiontaking_1-@v99apositiontaking_1 else @v99mpositiontaking_1 end,
	@v99mpositiontaking_2 = case when @v99apositiontaking_2+@v99mpositiontaking_2>@max_v99mapositiontaking_2 then @max_v99mapositiontaking_2-@v99apositiontaking_2 else @v99mpositiontaking_2 end,
	@v99mpositiontaking_3 = case when @v99apositiontaking_3+@v99mpositiontaking_3>@max_v99mapositiontaking_3 then @max_v99mapositiontaking_3-@v99apositiontaking_3 else @v99mpositiontaking_3 end,
	@v99mpositiontaking_20 = case when @v99apositiontaking_20+@v99mpositiontaking_20>@max_v99mapositiontaking_20 then @max_v99mapositiontaking_20-@v99apositiontaking_20 else @v99mpositiontaking_20 end
*/
--Check m1+a1<=m3
declare @ErrType varchar(4000)
Select @ErrType = ' '
Select @ErrType = @ErrType + sportname + '-' + typenamee + '-Max: '+cast(b.maxmapositiontaking - b.apositiontaking as varchar(10)) 
	+ case when b.sporttype = 1 and b.bettype in (1,3,7,8) then ' -Max Live: '+cast(b.maxlivemapositiontaking - b.alivepositiontaking as varchar(10)) else '' end + '<br>'
from(	
				  select	1	as	bettype	,	1	as	sporttype	,	@apositiontaking_1	as	apositiontaking	,	@mpositiontaking_1	as	mpositiontaking	,	@max_mapositiontaking_1	as	maxmapositiontaking	,	@alivepositiontaking_1	as	alivepositiontaking	,	@mlivepositiontaking_1	as	mlivepositiontaking	,	@max_malivepositiontaking_1	as	maxlivemapositiontaking
		union all select	2	as	bettype	,	1	as	sporttype	,	@apositiontaking_2	as	apositiontaking	,	@mpositiontaking_2	as	mpositiontaking	,	@max_mapositiontaking_2	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	3	as	bettype	,	1	as	sporttype	,	@apositiontaking_3	as	apositiontaking	,	@mpositiontaking_3	as	mpositiontaking	,	@max_mapositiontaking_3	as	maxmapositiontaking	,	@alivepositiontaking_3	as	alivepositiontaking	,	@mlivepositiontaking_3	as	mlivepositiontaking	,	@max_malivepositiontaking_3	as	maxlivemapositiontaking
		union all select	4	as	bettype	,	1	as	sporttype	,	@apositiontaking_4	as	apositiontaking	,	@mpositiontaking_4	as	mpositiontaking	,	@max_mapositiontaking_4	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	5	as	bettype	,	1	as	sporttype	,	@apositiontaking_5	as	apositiontaking	,	@mpositiontaking_5	as	mpositiontaking	,	@max_mapositiontaking_5	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	6	as	bettype	,	1	as	sporttype	,	@apositiontaking_6	as	apositiontaking	,	@mpositiontaking_6	as	mpositiontaking	,	@max_mapositiontaking_6	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	7	as	bettype	,	1	as	sporttype	,	@apositiontaking_7	as	apositiontaking	,	@mpositiontaking_7	as	mpositiontaking	,	@max_mapositiontaking_7	as	maxmapositiontaking	,	@alivepositiontaking_7	as	alivepositiontaking	,	@mlivepositiontaking_7	as	mlivepositiontaking	,	@max_malivepositiontaking_7	as	maxlivemapositiontaking
		union all select	8	as	bettype	,	1	as	sporttype	,	@apositiontaking_8	as	apositiontaking	,	@mpositiontaking_8	as	mpositiontaking	,	@max_mapositiontaking_8	as	maxmapositiontaking	,	@alivepositiontaking_8	as	alivepositiontaking	,	@mlivepositiontaking_8	as	mlivepositiontaking	,	@max_malivepositiontaking_8	as	maxlivemapositiontaking
		union all select	9	as	bettype	,	1	as	sporttype	,	@apositiontaking_9	as	apositiontaking	,	@mpositiontaking_9	as	mpositiontaking	,	@max_mapositiontaking_9	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	10	as	bettype	,	1	as	sporttype	,	@apositiontaking_10	as	apositiontaking	,	@mpositiontaking_10	as	mpositiontaking	,	@max_mapositiontaking_10	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	1	as	bettype	,	2	as	sporttype	,	@v2apositiontaking_1	as	apositiontaking	,	@v2mpositiontaking_1	as	mpositiontaking	,	@max_v2mapositiontaking_1	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	2	as	bettype	,	2	as	sporttype	,	@v2apositiontaking_2	as	apositiontaking	,	@v2mpositiontaking_2	as	mpositiontaking	,	@max_v2mapositiontaking_2	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	3	as	bettype	,	2	as	sporttype	,	@v2apositiontaking_3	as	apositiontaking	,	@v2mpositiontaking_3	as	mpositiontaking	,	@max_v2mapositiontaking_3	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	7	as	bettype	,	2	as	sporttype	,	@v2apositiontaking_7	as	apositiontaking	,	@v2mpositiontaking_7	as	mpositiontaking	,	@max_v2mapositiontaking_7	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	8	as	bettype	,	2	as	sporttype	,	@v2apositiontaking_8	as	apositiontaking	,	@v2mpositiontaking_8	as	mpositiontaking	,	@max_v2mapositiontaking_8	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	9	as	bettype	,	2	as	sporttype	,	@v2apositiontaking_9	as	apositiontaking	,	@v2mpositiontaking_9	as	mpositiontaking	,	@max_v2mapositiontaking_9	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	20	as	bettype	,	2	as	sporttype	,	@v2apositiontaking_20	as	apositiontaking	,	@v2mpositiontaking_20	as	mpositiontaking	,	@max_v2mapositiontaking_20	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	1	as	bettype	,	3	as	sporttype	,	@v3apositiontaking_1	as	apositiontaking	,	@v3mpositiontaking_1	as	mpositiontaking	,	@max_v3mapositiontaking_1	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	2	as	bettype	,	3	as	sporttype	,	@v3apositiontaking_2	as	apositiontaking	,	@v3mpositiontaking_2	as	mpositiontaking	,	@max_v3mapositiontaking_2	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	3	as	bettype	,	3	as	sporttype	,	@v3apositiontaking_3	as	apositiontaking	,	@v3mpositiontaking_3	as	mpositiontaking	,	@max_v3mapositiontaking_3	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	20	as	bettype	,	3	as	sporttype	,	@v3apositiontaking_20	as	apositiontaking	,	@v3mpositiontaking_20	as	mpositiontaking	,	@max_v3mapositiontaking_20	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	1	as	bettype	,	5	as	sporttype	,	@v5apositiontaking_1	as	apositiontaking	,	@v5mpositiontaking_1	as	mpositiontaking	,	@max_v5mapositiontaking_1	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	2	as	bettype	,	5	as	sporttype	,	@v5apositiontaking_2	as	apositiontaking	,	@v5mpositiontaking_2	as	mpositiontaking	,	@max_v5mapositiontaking_2	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	3	as	bettype	,	5	as	sporttype	,	@v5apositiontaking_3	as	apositiontaking	,	@v5mpositiontaking_3	as	mpositiontaking	,	@max_v5mapositiontaking_3	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	20	as	bettype	,	5	as	sporttype	,	@v5apositiontaking_20	as	apositiontaking	,	@v5mpositiontaking_20	as	mpositiontaking	,	@max_v5mapositiontaking_20	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	1	as	bettype	,	8	as	sporttype	,	@v8apositiontaking_1	as	apositiontaking	,	@v8mpositiontaking_1	as	mpositiontaking	,	@max_v8mapositiontaking_1	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	3	as	bettype	,	8	as	sporttype	,	@v8apositiontaking_3	as	apositiontaking	,	@v8mpositiontaking_3	as	mpositiontaking	,	@max_v8mapositiontaking_3	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	20	as	bettype	,	8	as	sporttype	,	@v8apositiontaking_20	as	apositiontaking	,	@v8mpositiontaking_20	as	mpositiontaking	,	@max_v8mapositiontaking_20	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	1	as	bettype	,	10	as	sporttype	,	@v10apositiontaking_1	as	apositiontaking	,	@v10mpositiontaking_1	as	mpositiontaking	,	@max_v10mapositiontaking_1	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	2	as	bettype	,	10	as	sporttype	,	@v10apositiontaking_2	as	apositiontaking	,	@v10mpositiontaking_2	as	mpositiontaking	,	@max_v10mapositiontaking_2	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	3	as	bettype	,	10	as	sporttype	,	@v10apositiontaking_3	as	apositiontaking	,	@v10mpositiontaking_3	as	mpositiontaking	,	@max_v10mapositiontaking_3	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	20	as	bettype	,	10	as	sporttype	,	@v10apositiontaking_20	as	apositiontaking	,	@v10mpositiontaking_20	as	mpositiontaking	,	@max_v10mapositiontaking_20	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	1	as	bettype	,	11	as	sporttype	,	@v11apositiontaking_1	as	apositiontaking	,	@v11mpositiontaking_1	as	mpositiontaking	,	@max_v11mapositiontaking_1	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	20	as	bettype	,	11	as	sporttype	,	@v11apositiontaking_20	as	apositiontaking	,	@v11mpositiontaking_20	as	mpositiontaking	,	@max_v11mapositiontaking_20	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	3	as	bettype	,	201	as	sporttype	,	@v201apositiontaking_3	as	apositiontaking	,	@v201mpositiontaking_3	as	mpositiontaking	,	@max_v201mapositiontaking_3	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
																																	
		union all select	1	as	bettype	,	99	as	sporttype	,	@v99apositiontaking_1	as	apositiontaking	,	@v99mpositiontaking_1	as	mpositiontaking	,	@max_v99mapositiontaking_1	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	2	as	bettype	,	99	as	sporttype	,	@v99apositiontaking_2	as	apositiontaking	,	@v99mpositiontaking_2	as	mpositiontaking	,	@max_v99mapositiontaking_2	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	3	as	bettype	,	99	as	sporttype	,	@v99apositiontaking_3	as	apositiontaking	,	@v99mpositiontaking_3	as	mpositiontaking	,	@max_v99mapositiontaking_3	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
		union all select	20	as	bettype	,	99	as	sporttype	,	@v99apositiontaking_20	as	apositiontaking	,	@v99mpositiontaking_20	as	mpositiontaking	,	@max_v99mapositiontaking_20	as	maxmapositiontaking	,	0	as	alivepositiontaking	,	0	as	mlivepositiontaking	,	0	as	maxlivemapositiontaking
	)b inner join sports (nolock) on b.sporttype = sports.sporttype
		inner join bettype (nolock) on b.bettype = bettype.typeid
where b.apositiontaking + b.mpositiontaking > b.maxmapositiontaking
	or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking + b.mlivepositiontaking > b.maxlivemapositiontaking)
order by b.sporttype,b.bettype
IF @ErrType <> ''
Begin
	Select @ErrMsg = 	case @Language 
					when 'E' then 'Wrong position taking. User:' + @username + '<br>' + @ErrType
					when 'CS' then N'占成数不正确. User:' + @username + '<br>' + @ErrType
					when 'CT' then N'佔成數不正確. User:' + @username + '<br>' + @ErrType
					when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง. User:' + @username + '<br>' + @ErrType
					when 'J' then N'Wrong position taking. User:' + @username + '<br>' + @ErrType
					else N'Wrong position taking. User:' + @username + '<br>' + @ErrType
			end, @ErrCode = 102
	return 
End
	 	
--n3
select @min_mapositiontaking_1 = minpositiontaking, @min_malivepositiontaking_1 = minlivepositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=1
select @min_mapositiontaking_3 = minpositiontaking, @min_malivepositiontaking_3 = minlivepositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=1
select @min_mapositiontaking_7 = minpositiontaking, @min_malivepositiontaking_7 = minlivepositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=1
select @min_mapositiontaking_8 = minpositiontaking, @min_malivepositiontaking_8 = minlivepositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=1
select @min_mapositiontaking_2 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=1
select @min_mapositiontaking_4 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=4 and sporttype=1
select @min_mapositiontaking_5 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=5 and sporttype=1
select @min_mapositiontaking_6 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=6 and sporttype=1
select @min_mapositiontaking_9 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=1
select @min_mapositiontaking_10 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=10 and sporttype=1

select @min_v2mapositiontaking_1 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=2
select @min_v2mapositiontaking_2 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=2 
select @min_v2mapositiontaking_3 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=2
select @min_v2mapositiontaking_7 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=2
select @min_v2mapositiontaking_8 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=2
select @min_v2mapositiontaking_9 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=2
select @min_v2mapositiontaking_20 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=2

select @min_v3mapositiontaking_1 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=3
select @min_v3mapositiontaking_2 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=3 
select @min_v3mapositiontaking_3 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=3
select @min_v3mapositiontaking_20 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=3

select @min_v5mapositiontaking_1 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=5
select @min_v5mapositiontaking_2 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=5 
select @min_v5mapositiontaking_3 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=5
select @min_v5mapositiontaking_20 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=5

select @min_v8mapositiontaking_1 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=8
select @min_v8mapositiontaking_3 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=8
select @min_v8mapositiontaking_20 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=8

select @min_v10mapositiontaking_1 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=10
select @min_v10mapositiontaking_2 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=10 
select @min_v10mapositiontaking_3 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=10
select @min_v10mapositiontaking_20 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=10

select @min_v11mapositiontaking_1 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=11
select @min_v11mapositiontaking_20 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=11
--v201
select @min_v201mapositiontaking_3 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=201

select @min_v99mapositiontaking_1 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=99
select @min_v99mapositiontaking_2 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=99 
select @min_v99mapositiontaking_3 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=99
select @min_v99mapositiontaking_20 = minpositiontaking from custoverride with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=99
--m1=m1+a1<n3?n3-a1:m1
select 
	@mpositiontaking_1 = case when @mpositiontaking_1+@apositiontaking_1<@min_mapositiontaking_1 then @min_mapositiontaking_1-@apositiontaking_1 else @mpositiontaking_1 end,
	@mpositiontaking_2 = case when @mpositiontaking_2+@apositiontaking_2<@min_mapositiontaking_2 then @min_mapositiontaking_2-@apositiontaking_2 else @mpositiontaking_2 end,
	@mpositiontaking_3 = case when @mpositiontaking_3+@apositiontaking_3<@min_mapositiontaking_3 then @min_mapositiontaking_3-@apositiontaking_3 else @mpositiontaking_3 end,
	@mpositiontaking_4 = case when @mpositiontaking_4+@apositiontaking_4<@min_mapositiontaking_4 then @min_mapositiontaking_4-@apositiontaking_4 else @mpositiontaking_4 end,
	@mpositiontaking_5 = case when @mpositiontaking_5+@apositiontaking_5<@min_mapositiontaking_5 then @min_mapositiontaking_5-@apositiontaking_5 else @mpositiontaking_5 end,
	@mpositiontaking_6 = case when @mpositiontaking_6+@apositiontaking_6<@min_mapositiontaking_6 then @min_mapositiontaking_6-@apositiontaking_6 else @mpositiontaking_6 end,
	@mpositiontaking_7 = case when @mpositiontaking_7+@apositiontaking_7<@min_mapositiontaking_7 then @min_mapositiontaking_7-@apositiontaking_7 else @mpositiontaking_7 end,
	@mpositiontaking_8 = case when @mpositiontaking_8+@apositiontaking_8<@min_mapositiontaking_8 then @min_mapositiontaking_8-@apositiontaking_8 else @mpositiontaking_8 end,
	@mpositiontaking_9 = case when @mpositiontaking_9+@apositiontaking_9<@min_mapositiontaking_9 then @min_mapositiontaking_9-@apositiontaking_9 else @mpositiontaking_9 end,
	@mpositiontaking_10 = case when @mpositiontaking_10+@apositiontaking_10<@min_mapositiontaking_10 then @min_mapositiontaking_10-@apositiontaking_10 else @mpositiontaking_10 end,

	@mlivepositiontaking_1 = case when @mlivepositiontaking_1+@alivepositiontaking_1<@min_malivepositiontaking_1 then @min_malivepositiontaking_1-@alivepositiontaking_1 else @mlivepositiontaking_1 end,
	@mlivepositiontaking_3 = case when @mlivepositiontaking_3+@alivepositiontaking_3<@min_malivepositiontaking_3 then @min_malivepositiontaking_3-@alivepositiontaking_3 else @mlivepositiontaking_3 end,
	@mlivepositiontaking_7 = case when @mlivepositiontaking_7+@alivepositiontaking_7<@min_malivepositiontaking_7 then @min_malivepositiontaking_7-@alivepositiontaking_7 else @mlivepositiontaking_7 end,
	@mlivepositiontaking_8 = case when @mlivepositiontaking_8+@alivepositiontaking_8<@min_malivepositiontaking_8 then @min_malivepositiontaking_8-@alivepositiontaking_8 else @mlivepositiontaking_8 end,

	@v2mpositiontaking_1 = case when @v2apositiontaking_1+@v2mpositiontaking_1<@min_v2mapositiontaking_1 then @min_v2mapositiontaking_1-@v2apositiontaking_1 else @v2mpositiontaking_1 end,
	@v2mpositiontaking_2 = case when @v2apositiontaking_2+@v2mpositiontaking_2<@min_v2mapositiontaking_2 then @min_v2mapositiontaking_2-@v2apositiontaking_2 else @v2mpositiontaking_2 end,
	@v2mpositiontaking_3 = case when @v2apositiontaking_3+@v2mpositiontaking_3<@min_v2mapositiontaking_3 then @min_v2mapositiontaking_3-@v2apositiontaking_3 else @v2mpositiontaking_3 end,
	@v2mpositiontaking_7 = case when @v2apositiontaking_7+@v2mpositiontaking_7<@min_v2mapositiontaking_7 then @min_v2mapositiontaking_7-@v2apositiontaking_7 else @v2mpositiontaking_7 end,
	@v2mpositiontaking_8 = case when @v2apositiontaking_8+@v2mpositiontaking_8<@min_v2mapositiontaking_8 then @min_v2mapositiontaking_8-@v2apositiontaking_8 else @v2mpositiontaking_8 end,
	@v2mpositiontaking_9 = case when @v2apositiontaking_9+@v2mpositiontaking_9<@min_v2mapositiontaking_9 then @min_v2mapositiontaking_9-@v2apositiontaking_9 else @v2mpositiontaking_9 end,
	@v2mpositiontaking_20 = case when @v2apositiontaking_20+@v2mpositiontaking_20<@min_v2mapositiontaking_20 then @min_v2mapositiontaking_20-@v2apositiontaking_20 else @v2mpositiontaking_20 end,

	@v3mpositiontaking_1 = case when @v3apositiontaking_1+@v3mpositiontaking_1<@min_v3mapositiontaking_1 then @min_v3mapositiontaking_1-@v3apositiontaking_1 else @v3mpositiontaking_1 end,
	@v3mpositiontaking_2 = case when @v3apositiontaking_2+@v3mpositiontaking_2<@min_v3mapositiontaking_2 then @min_v3mapositiontaking_2-@v3apositiontaking_2 else @v3mpositiontaking_2 end,
	@v3mpositiontaking_3 = case when @v3apositiontaking_3+@v3mpositiontaking_3<@min_v3mapositiontaking_3 then @min_v3mapositiontaking_3-@v3apositiontaking_3 else @v3mpositiontaking_3 end,
	@v3mpositiontaking_20 = case when @v3apositiontaking_20+@v3mpositiontaking_20<@min_v3mapositiontaking_20 then @min_v3mapositiontaking_20-@v3apositiontaking_20 else @v3mpositiontaking_20 end,

	@v5mpositiontaking_1 = case when @v5apositiontaking_1+@v5mpositiontaking_1<@min_v5mapositiontaking_1 then @min_v5mapositiontaking_1-@v5apositiontaking_1 else @v5mpositiontaking_1 end,
	@v5mpositiontaking_2 = case when @v5apositiontaking_2+@v5mpositiontaking_2<@min_v5mapositiontaking_2 then @min_v5mapositiontaking_2-@v5apositiontaking_2 else @v5mpositiontaking_2 end,
	@v5mpositiontaking_3 = case when @v5apositiontaking_3+@v5mpositiontaking_3<@min_v5mapositiontaking_3 then @min_v5mapositiontaking_3-@v5apositiontaking_3 else @v5mpositiontaking_3 end,
	@v5mpositiontaking_20 = case when @v5apositiontaking_20+@v5mpositiontaking_20<@min_v5mapositiontaking_20 then @min_v5mapositiontaking_20-@v5apositiontaking_20 else @v5mpositiontaking_20 end,

	@v8mpositiontaking_1 = case when @v8apositiontaking_1+@v8mpositiontaking_1<@min_v8mapositiontaking_1 then @min_v8mapositiontaking_1-@v8apositiontaking_1 else @v8mpositiontaking_1 end,
	@v8mpositiontaking_3 = case when @v8apositiontaking_3+@v8mpositiontaking_3<@min_v8mapositiontaking_3 then @min_v8mapositiontaking_3-@v8apositiontaking_3 else @v8mpositiontaking_3 end,
	@v8mpositiontaking_20 = case when @v8apositiontaking_20+@v8mpositiontaking_20<@min_v8mapositiontaking_20 then @min_v8mapositiontaking_20-@v8apositiontaking_20 else @v8mpositiontaking_20 end,

	@v10mpositiontaking_1 = case when @v10apositiontaking_1+@v10mpositiontaking_1<@min_v10mapositiontaking_1 then @min_v10mapositiontaking_1-@v10apositiontaking_1 else @v10mpositiontaking_1 end,
	@v10mpositiontaking_2 = case when @v10apositiontaking_2+@v10mpositiontaking_2<@min_v10mapositiontaking_2 then @min_v10mapositiontaking_2-@v10apositiontaking_2 else @v10mpositiontaking_2 end,
	@v10mpositiontaking_3 = case when @v10apositiontaking_3+@v10mpositiontaking_3<@min_v10mapositiontaking_3 then @min_v10mapositiontaking_3-@v10apositiontaking_3 else @v10mpositiontaking_3 end,
	@v10mpositiontaking_20 = case when @v10apositiontaking_20+@v10mpositiontaking_20<@min_v10mapositiontaking_20 then @min_v10mapositiontaking_20-@v10apositiontaking_20 else @v10mpositiontaking_20 end,

	@v11mpositiontaking_1 = case when @v11apositiontaking_1+@v11mpositiontaking_1<@min_v11mapositiontaking_1 then @min_v11mapositiontaking_1-@v11apositiontaking_1 else @v11mpositiontaking_1 end,
	@v11mpositiontaking_20 = case when @v11apositiontaking_20+@v11mpositiontaking_20<@min_v11mapositiontaking_20 then @min_v11mapositiontaking_20-@v11apositiontaking_20 else @v11mpositiontaking_20 end,
	--v201
	@v201mpositiontaking_3 = case when @v201apositiontaking_3+@v201mpositiontaking_3<@min_v201mapositiontaking_3 then @min_v201mapositiontaking_3-@v201apositiontaking_3 else @v201mpositiontaking_3 end,

	@v99mpositiontaking_1 = case when @v99apositiontaking_1+@v99mpositiontaking_1<@min_v99mapositiontaking_1 then @min_v99mapositiontaking_1-@v99apositiontaking_1 else @v99mpositiontaking_1 end,
	@v99mpositiontaking_2 = case when @v99apositiontaking_2+@v99mpositiontaking_2<@min_v99mapositiontaking_2 then @min_v99mapositiontaking_2-@v99apositiontaking_2 else @v99mpositiontaking_2 end,
	@v99mpositiontaking_3 = case when @v99apositiontaking_3+@v99mpositiontaking_3<@min_v99mapositiontaking_3 then @min_v99mapositiontaking_3-@v99apositiontaking_3 else @v99mpositiontaking_3 end,
	@v99mpositiontaking_20 = case when @v99apositiontaking_20+@v99mpositiontaking_20<@min_v99mapositiontaking_20 then @min_v99mapositiontaking_20-@v99apositiontaking_20 else @v99mpositiontaking_20 end

select 
	@mpositiontaking_1 = case when @mpositiontaking_1<0 then 0 else @mpositiontaking_1 end,
	@mpositiontaking_2 = case when @mpositiontaking_2<0 then 0 else @mpositiontaking_2 end,
	@mpositiontaking_3 = case when @mpositiontaking_3<0 then 0 else @mpositiontaking_3 end,
	@mpositiontaking_4 = case when @mpositiontaking_4<0 then 0 else @mpositiontaking_4 end,
	@mpositiontaking_5 = case when @mpositiontaking_5<0 then 0 else @mpositiontaking_5 end,
	@mpositiontaking_6 = case when @mpositiontaking_6<0 then 0 else @mpositiontaking_6 end,
	@mpositiontaking_7 = case when @mpositiontaking_7<0 then 0 else @mpositiontaking_7 end,
	@mpositiontaking_8 = case when @mpositiontaking_8<0 then 0 else @mpositiontaking_8 end,
	@mpositiontaking_9 = case when @mpositiontaking_9<0 then 0 else @mpositiontaking_9 end,
	@mpositiontaking_10 = case when @mpositiontaking_10<0 then 0 else @mpositiontaking_10 end,

	@mlivepositiontaking_1 = case when @mlivepositiontaking_1<0 then 0 else @mlivepositiontaking_1 end,
	@mlivepositiontaking_3 = case when @mlivepositiontaking_3<0 then 0 else @mlivepositiontaking_3 end,
	@mlivepositiontaking_7 = case when @mlivepositiontaking_7<0 then 0 else @mlivepositiontaking_7 end,
	@mlivepositiontaking_8 = case when @mlivepositiontaking_8<0 then 0 else @mlivepositiontaking_8 end,

	@v2mpositiontaking_1 = case when @v2mpositiontaking_1<0 then 0 else @v2mpositiontaking_1 end,
	@v2mpositiontaking_2 = case when @v2mpositiontaking_2<0 then 0 else @v2mpositiontaking_2 end,
	@v2mpositiontaking_3 = case when @v2mpositiontaking_3<0 then 0 else @v2mpositiontaking_3 end,
	@v2mpositiontaking_7 = case when @v2mpositiontaking_7<0 then 0 else @v2mpositiontaking_7 end,
	@v2mpositiontaking_8 = case when @v2mpositiontaking_8<0 then 0 else @v2mpositiontaking_8 end,
	@v2mpositiontaking_9 = case when @v2mpositiontaking_9<0 then 0 else @v2mpositiontaking_9 end,
	@v2mpositiontaking_20 = case when @v2mpositiontaking_20<0 then 0 else @v2mpositiontaking_20 end,

	@v3mpositiontaking_1 = case when @v3mpositiontaking_1<0 then 0 else @v3mpositiontaking_1 end,
	@v3mpositiontaking_2 = case when @v3mpositiontaking_2<0 then 0 else @v3mpositiontaking_2 end,
	@v3mpositiontaking_3 = case when @v3mpositiontaking_3<0 then 0 else @v3mpositiontaking_3 end,
	@v3mpositiontaking_20 = case when @v3mpositiontaking_20<0 then 0 else @v3mpositiontaking_20 end,

	@v5mpositiontaking_1 = case when @v5mpositiontaking_1<0 then 0 else @v5mpositiontaking_1 end,
	@v5mpositiontaking_2 = case when @v5mpositiontaking_2<0 then 0 else @v5mpositiontaking_2 end,
	@v5mpositiontaking_3 = case when @v5mpositiontaking_3<0 then 0 else @v5mpositiontaking_3 end,
	@v5mpositiontaking_20 = case when @v5mpositiontaking_20<0 then 0 else @v5mpositiontaking_20 end,

	@v8mpositiontaking_1 = case when @v8mpositiontaking_1<0 then 0 else @v8mpositiontaking_1 end,
	@v8mpositiontaking_3 = case when @v8mpositiontaking_3<0 then 0 else @v8mpositiontaking_3 end,
	@v8mpositiontaking_20 = case when @v8mpositiontaking_20<0 then 0 else @v8mpositiontaking_20 end,

	@v10mpositiontaking_1 = case when @v10mpositiontaking_1<0 then 0 else @v10mpositiontaking_1 end,
	@v10mpositiontaking_2 = case when @v10mpositiontaking_2<0 then 0 else @v10mpositiontaking_2 end,
	@v10mpositiontaking_3 = case when @v10mpositiontaking_3<0 then 0 else @v10mpositiontaking_3 end,
	@v10mpositiontaking_20 = case when @v10mpositiontaking_20<0 then 0 else @v10mpositiontaking_20 end,

	@v11mpositiontaking_1 = case when @v11mpositiontaking_1<0 then 0 else @v11mpositiontaking_1 end,
	@v11mpositiontaking_20 = case when @v11mpositiontaking_20<0 then 0 else @v11mpositiontaking_20 end,
	--v201
	@v201mpositiontaking_3 = case when @v201mpositiontaking_3<0 then 0 else @v201mpositiontaking_3 end,

	@v99mpositiontaking_1 = case when @v99mpositiontaking_1<0 then 0 else @v99mpositiontaking_1 end,
	@v99mpositiontaking_2 = case when @v99mpositiontaking_2<0 then 0 else @v99mpositiontaking_2 end,
	@v99mpositiontaking_3 = case when @v99mpositiontaking_3<0 then 0 else @v99mpositiontaking_3 end,
	@v99mpositiontaking_20 = case when @v99mpositiontaking_20<0 then 0 else @v99mpositiontaking_20 end
--s4
select @max_spositiontaking_1 = spositiontaking, @max_slivepositiontaking_1 = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=1
select @max_spositiontaking_3 = spositiontaking, @max_slivepositiontaking_3 = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=1
select @max_spositiontaking_7 = spositiontaking, @max_slivepositiontaking_7 = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=7 and sporttype=1
select @max_spositiontaking_8 = spositiontaking, @max_slivepositiontaking_8 = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=8 and sporttype=1
select @max_spositiontaking_2 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=1
select @max_spositiontaking_4 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=4 and sporttype=1
select @max_spositiontaking_5 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=5 and sporttype=1
select @max_spositiontaking_6 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=6 and sporttype=1
select @max_spositiontaking_9 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=9 and sporttype=1
select @max_spositiontaking_10 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=10 and sporttype=1

select @max_v2spositiontaking_1 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=2
select @max_v2spositiontaking_2 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=2
select @max_v2spositiontaking_3 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=2
select @max_v2spositiontaking_7 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=7 and sporttype=2
select @max_v2spositiontaking_8 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=8 and sporttype=2
select @max_v2spositiontaking_9 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=9 and sporttype=2
select @max_v2spositiontaking_20 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=2

select @max_v3spositiontaking_1 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=3
select @max_v3spositiontaking_2 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=3
select @max_v3spositiontaking_3 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=3
select @max_v3spositiontaking_20 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=3

select @max_v5spositiontaking_1 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=5
select @max_v5spositiontaking_2 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=5
select @max_v5spositiontaking_3 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=5
select @max_v5spositiontaking_20 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=5

select @max_v8spositiontaking_1 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=8
select @max_v8spositiontaking_3 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=8
select @max_v8spositiontaking_20 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=8

select @max_v10spositiontaking_1 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=10
select @max_v10spositiontaking_2 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=10
select @max_v10spositiontaking_3 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=10
select @max_v10spositiontaking_20 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=10

select @max_v11spositiontaking_1 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=11
select @max_v11spositiontaking_20 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=11
--v201
select @max_v201spositiontaking_3 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=201

select @max_v99spositiontaking_1 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=99
select @max_v99spositiontaking_2 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=99
select @max_v99spositiontaking_3 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=99
select @max_v99spositiontaking_20 = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=99

---------------------------------------------------------------------------------------------------------------------------------------------
--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in master account)
select 
	@auto_spositiontaking_1 = case when @member_isauto_spositiontaking_1>0 then @member_auto_spositiontaking_1 else @auto_spositiontaking_1 end,
	@auto_spositiontaking_2 = case when @member_isauto_spositiontaking_2>0 then @member_auto_spositiontaking_2 else @auto_spositiontaking_2 end,
	@auto_spositiontaking_3 = case when @member_isauto_spositiontaking_3>0 then @member_auto_spositiontaking_3 else @auto_spositiontaking_3 end,
	@auto_spositiontaking_4 = case when @member_isauto_spositiontaking_4>0 then @member_auto_spositiontaking_4 else @auto_spositiontaking_4 end,
	@auto_spositiontaking_5 = case when @member_isauto_spositiontaking_5>0 then @member_auto_spositiontaking_5 else @auto_spositiontaking_5 end,
	@auto_spositiontaking_6 = case when @member_isauto_spositiontaking_6>0 then @member_auto_spositiontaking_6 else @auto_spositiontaking_6 end,
	@auto_spositiontaking_7 = case when @member_isauto_spositiontaking_7>0 then @member_auto_spositiontaking_7 else @auto_spositiontaking_7 end,
	@auto_spositiontaking_8 = case when @member_isauto_spositiontaking_8>0 then @member_auto_spositiontaking_8 else @auto_spositiontaking_8 end,
	@auto_spositiontaking_9 = case when @member_isauto_spositiontaking_9>0 then @member_auto_spositiontaking_9 else @auto_spositiontaking_9 end,
	@auto_spositiontaking_10 = case when @member_isauto_spositiontaking_10>0 then @member_auto_spositiontaking_10 else @auto_spositiontaking_10 end,

	@auto_slivepositiontaking_1 = case when @member_isauto_slivepositiontaking_1>0 then @member_auto_slivepositiontaking_1 else @auto_slivepositiontaking_1 end,
	@auto_slivepositiontaking_3 = case when @member_isauto_slivepositiontaking_3>0 then @member_auto_slivepositiontaking_3 else @auto_slivepositiontaking_3 end,
	@auto_slivepositiontaking_7 = case when @member_isauto_slivepositiontaking_7>0 then @member_auto_slivepositiontaking_7 else @auto_slivepositiontaking_7 end,
	@auto_slivepositiontaking_8 = case when @member_isauto_slivepositiontaking_8>0 then @member_auto_slivepositiontaking_8 else @auto_slivepositiontaking_8 end,

	@auto_v2spositiontaking_1 = case when @member_isauto_v2spositiontaking_1>0 then @member_auto_v2spositiontaking_1 else @auto_v2spositiontaking_1 end,
	@auto_v2spositiontaking_2 = case when @member_isauto_v2spositiontaking_2>0 then @member_auto_v2spositiontaking_2 else @auto_v2spositiontaking_2 end,
	@auto_v2spositiontaking_3 = case when @member_isauto_v2spositiontaking_3>0 then @member_auto_v2spositiontaking_3 else @auto_v2spositiontaking_3 end,
	@auto_v2spositiontaking_7 = case when @member_isauto_v2spositiontaking_7>0 then @member_auto_v2spositiontaking_7 else @auto_v2spositiontaking_7 end,
	@auto_v2spositiontaking_8 = case when @member_isauto_v2spositiontaking_8>0 then @member_auto_v2spositiontaking_8 else @auto_v2spositiontaking_8 end,
	@auto_v2spositiontaking_9 = case when @member_isauto_v2spositiontaking_9>0 then @member_auto_v2spositiontaking_9 else @auto_v2spositiontaking_9 end,
	@auto_v2spositiontaking_20 = case when @member_isauto_v2spositiontaking_20>0 then @member_auto_v2spositiontaking_20 else @auto_v2spositiontaking_20 end,

	@auto_v3spositiontaking_1 = case when @member_isauto_v3spositiontaking_1>0 then @member_auto_v3spositiontaking_1 else @auto_v3spositiontaking_1 end,
	@auto_v3spositiontaking_2 = case when @member_isauto_v3spositiontaking_2>0 then @member_auto_v3spositiontaking_2 else @auto_v3spositiontaking_2 end,
	@auto_v3spositiontaking_3 = case when @member_isauto_v3spositiontaking_3>0 then @member_auto_v3spositiontaking_3 else @auto_v3spositiontaking_3 end,
	@auto_v3spositiontaking_20 = case when @member_isauto_v3spositiontaking_20>0 then @member_auto_v3spositiontaking_20 else @auto_v3spositiontaking_20 end,

	@auto_v5spositiontaking_1 = case when @member_isauto_v5spositiontaking_1>0 then @member_auto_v5spositiontaking_1 else @auto_v5spositiontaking_1 end,
	@auto_v5spositiontaking_2 = case when @member_isauto_v5spositiontaking_2>0 then @member_auto_v5spositiontaking_2 else @auto_v5spositiontaking_2 end,
	@auto_v5spositiontaking_3 = case when @member_isauto_v5spositiontaking_3>0 then @member_auto_v5spositiontaking_3 else @auto_v5spositiontaking_3 end,
	@auto_v5spositiontaking_20 = case when @member_isauto_v5spositiontaking_20>0 then @member_auto_v5spositiontaking_20 else @auto_v5spositiontaking_20 end,

	@auto_v8spositiontaking_1 = case when @member_isauto_v8spositiontaking_1>0 then @member_auto_v8spositiontaking_1 else @auto_v8spositiontaking_1 end,
	@auto_v8spositiontaking_3 = case when @member_isauto_v8spositiontaking_3>0 then @member_auto_v8spositiontaking_3 else @auto_v8spositiontaking_3 end,
	@auto_v8spositiontaking_20 = case when @member_isauto_v8spositiontaking_20>0 then @member_auto_v8spositiontaking_20 else @auto_v8spositiontaking_20 end,

	@auto_v10spositiontaking_1 = case when @member_isauto_v10spositiontaking_1>0 then @member_auto_v10spositiontaking_1 else @auto_v10spositiontaking_1 end,
	@auto_v10spositiontaking_2 = case when @member_isauto_v10spositiontaking_2>0 then @member_auto_v10spositiontaking_2 else @auto_v10spositiontaking_2 end,
	@auto_v10spositiontaking_3 = case when @member_isauto_v10spositiontaking_3>0 then @member_auto_v10spositiontaking_3 else @auto_v10spositiontaking_3 end,
	@auto_v10spositiontaking_20 = case when @member_isauto_v10spositiontaking_20>0 then @member_auto_v10spositiontaking_20 else @auto_v10spositiontaking_20 end,

	@auto_v11spositiontaking_1 = case when @member_isauto_v11spositiontaking_1>0 then @member_auto_v11spositiontaking_1 else @auto_v11spositiontaking_1 end,
	@auto_v11spositiontaking_20 = case when @member_isauto_v11spositiontaking_20>0 then @member_auto_v11spositiontaking_20 else @auto_v11spositiontaking_20 end,
	--v201
	@auto_v201spositiontaking_3 = case when @member_isauto_v201spositiontaking_3>0 then @member_auto_v201spositiontaking_3 else @auto_v201spositiontaking_3 end,

	@auto_v99spositiontaking_1 = case when @member_isauto_v99spositiontaking_1>0 then @member_auto_v99spositiontaking_1 else @auto_v99spositiontaking_1 end,
	@auto_v99spositiontaking_2 = case when @member_isauto_v99spositiontaking_2>0 then @member_auto_v99spositiontaking_2 else @auto_v99spositiontaking_2 end,
	@auto_v99spositiontaking_3 = case when @member_isauto_v99spositiontaking_3>0 then @member_auto_v99spositiontaking_3 else @auto_v99spositiontaking_3 end,
	@auto_v99spositiontaking_20 = case when @member_isauto_v99spositiontaking_20>0 then @member_auto_v99spositiontaking_20 else @auto_v99spositiontaking_20 end,

	@isauto_spositiontaking_1 = case when @member_isauto_spositiontaking_1>0 then @member_isauto_spositiontaking_1 else @isauto_spositiontaking_1 end,
	@isauto_spositiontaking_2 = case when @member_isauto_spositiontaking_2>0 then @member_isauto_spositiontaking_2 else @isauto_spositiontaking_2 end,
	@isauto_spositiontaking_3 = case when @member_isauto_spositiontaking_3>0 then @member_isauto_spositiontaking_3 else @isauto_spositiontaking_3 end,
	@isauto_spositiontaking_4 = case when @member_isauto_spositiontaking_4>0 then @member_isauto_spositiontaking_4 else @isauto_spositiontaking_4 end,
	@isauto_spositiontaking_5 = case when @member_isauto_spositiontaking_5>0 then @member_isauto_spositiontaking_5 else @isauto_spositiontaking_5 end,
	@isauto_spositiontaking_6 = case when @member_isauto_spositiontaking_6>0 then @member_isauto_spositiontaking_6 else @isauto_spositiontaking_6 end,
	@isauto_spositiontaking_7 = case when @member_isauto_spositiontaking_7>0 then @member_isauto_spositiontaking_7 else @isauto_spositiontaking_7 end,
	@isauto_spositiontaking_8 = case when @member_isauto_spositiontaking_8>0 then @member_isauto_spositiontaking_8 else @isauto_spositiontaking_8 end,
	@isauto_spositiontaking_9 = case when @member_isauto_spositiontaking_9>0 then @member_isauto_spositiontaking_9 else @isauto_spositiontaking_9 end,
	@isauto_spositiontaking_10 = case when @member_isauto_spositiontaking_10>0 then @member_isauto_spositiontaking_10 else @isauto_spositiontaking_10 end,

	@isauto_slivepositiontaking_1 = case when @member_isauto_slivepositiontaking_1>0 then @member_isauto_slivepositiontaking_1 else @isauto_slivepositiontaking_1 end,
	@isauto_slivepositiontaking_3 = case when @member_isauto_slivepositiontaking_3>0 then @member_isauto_slivepositiontaking_3 else @isauto_slivepositiontaking_3 end,
	@isauto_slivepositiontaking_7 = case when @member_isauto_slivepositiontaking_7>0 then @member_isauto_slivepositiontaking_7 else @isauto_slivepositiontaking_7 end,
	@isauto_slivepositiontaking_8 = case when @member_isauto_slivepositiontaking_8>0 then @member_isauto_slivepositiontaking_8 else @isauto_slivepositiontaking_8 end,

	@isauto_v2spositiontaking_1 = case when @member_isauto_v2spositiontaking_1>0 then @member_isauto_v2spositiontaking_1 else @isauto_v2spositiontaking_1 end,
	@isauto_v2spositiontaking_2 = case when @member_isauto_v2spositiontaking_2>0 then @member_isauto_v2spositiontaking_2 else @isauto_v2spositiontaking_2 end,
	@isauto_v2spositiontaking_3 = case when @member_isauto_v2spositiontaking_3>0 then @member_isauto_v2spositiontaking_3 else @isauto_v2spositiontaking_3 end,
	@isauto_v2spositiontaking_7 = case when @member_isauto_v2spositiontaking_7>0 then @member_isauto_v2spositiontaking_7 else @isauto_v2spositiontaking_7 end,
	@isauto_v2spositiontaking_8 = case when @member_isauto_v2spositiontaking_8>0 then @member_isauto_v2spositiontaking_8 else @isauto_v2spositiontaking_8 end,
	@isauto_v2spositiontaking_9 = case when @member_isauto_v2spositiontaking_9>0 then @member_isauto_v2spositiontaking_9 else @isauto_v2spositiontaking_9 end,
	@isauto_v2spositiontaking_20 = case when @member_isauto_v2spositiontaking_20>0 then @member_isauto_v2spositiontaking_20 else @isauto_v2spositiontaking_20 end,

	@isauto_v3spositiontaking_1 = case when @member_isauto_v3spositiontaking_1>0 then @member_isauto_v3spositiontaking_1 else @isauto_v3spositiontaking_1 end,
	@isauto_v3spositiontaking_2 = case when @member_isauto_v3spositiontaking_2>0 then @member_isauto_v3spositiontaking_2 else @isauto_v3spositiontaking_2 end,
	@isauto_v3spositiontaking_3 = case when @member_isauto_v3spositiontaking_3>0 then @member_isauto_v3spositiontaking_3 else @isauto_v3spositiontaking_3 end,
	@isauto_v3spositiontaking_20 = case when @member_isauto_v3spositiontaking_20>0 then @member_isauto_v3spositiontaking_20 else @isauto_v3spositiontaking_20 end,

	@isauto_v5spositiontaking_1 = case when @member_isauto_v5spositiontaking_1>0 then @member_isauto_v5spositiontaking_1 else @isauto_v5spositiontaking_1 end,
	@isauto_v5spositiontaking_2 = case when @member_isauto_v5spositiontaking_2>0 then @member_isauto_v5spositiontaking_2 else @isauto_v5spositiontaking_2 end,
	@isauto_v5spositiontaking_3 = case when @member_isauto_v5spositiontaking_3>0 then @member_isauto_v5spositiontaking_3 else @isauto_v5spositiontaking_3 end,
	@isauto_v5spositiontaking_20 = case when @member_isauto_v5spositiontaking_20>0 then @member_isauto_v5spositiontaking_20 else @isauto_v5spositiontaking_20 end,

	@isauto_v8spositiontaking_1 = case when @member_isauto_v8spositiontaking_1>0 then @member_isauto_v8spositiontaking_1 else @isauto_v8spositiontaking_1 end,
	@isauto_v8spositiontaking_3 = case when @member_isauto_v8spositiontaking_3>0 then @member_isauto_v8spositiontaking_3 else @isauto_v8spositiontaking_3 end,
	@isauto_v8spositiontaking_20 = case when @member_isauto_v8spositiontaking_20>0 then @member_isauto_v8spositiontaking_20 else @isauto_v8spositiontaking_20 end,

	@isauto_v10spositiontaking_1 = case when @member_isauto_v10spositiontaking_1>0 then @member_isauto_v10spositiontaking_1 else @isauto_v10spositiontaking_1 end,
	@isauto_v10spositiontaking_2 = case when @member_isauto_v10spositiontaking_2>0 then @member_isauto_v10spositiontaking_2 else @isauto_v10spositiontaking_2 end,
	@isauto_v10spositiontaking_3 = case when @member_isauto_v10spositiontaking_3>0 then @member_isauto_v10spositiontaking_3 else @isauto_v10spositiontaking_3 end,
	@isauto_v10spositiontaking_20 = case when @member_isauto_v10spositiontaking_20>0 then @member_isauto_v10spositiontaking_20 else @isauto_v10spositiontaking_20 end,

	@isauto_v11spositiontaking_1 = case when @member_isauto_v11spositiontaking_1>0 then @member_isauto_v11spositiontaking_1 else @isauto_v11spositiontaking_1 end,
	@isauto_v11spositiontaking_20 = case when @member_isauto_v11spositiontaking_20>0 then @member_isauto_v11spositiontaking_20 else @isauto_v11spositiontaking_20 end,
	--v201
	@isauto_v201spositiontaking_3 = case when @member_isauto_v201spositiontaking_3>0 then @member_isauto_v201spositiontaking_3 else @isauto_v201spositiontaking_3 end,

	@isauto_v99spositiontaking_1 = case when @member_isauto_v99spositiontaking_1>0 then @member_isauto_v99spositiontaking_1 else @isauto_v99spositiontaking_1 end,
	@isauto_v99spositiontaking_2 = case when @member_isauto_v99spositiontaking_2>0 then @member_isauto_v99spositiontaking_2 else @isauto_v99spositiontaking_2 end,
	@isauto_v99spositiontaking_3 = case when @member_isauto_v99spositiontaking_3>0 then @member_isauto_v99spositiontaking_3 else @isauto_v99spositiontaking_3 end,
	@isauto_v99spositiontaking_20 = case when @member_isauto_v99spositiontaking_20>0 then @member_isauto_v99spositiontaking_20 else @isauto_v99spositiontaking_20 end
---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
select @spositiontaking_1 = case when isnull(@isauto_spositiontaking_1, 0)<=0 then @spositiontaking_1 else case when @auto_spositiontaking_1 < @max_spositiontaking_1 - @mpositiontaking_1 - @apositiontaking_1 then @auto_spositiontaking_1 else @max_spositiontaking_1 - @mpositiontaking_1 - @apositiontaking_1 end end
select @spositiontaking_3 = case when isnull(@isauto_spositiontaking_3, 0)<=0 then @spositiontaking_3 else case when @auto_spositiontaking_3 < @max_spositiontaking_3 - @mpositiontaking_3 - @apositiontaking_3 then @auto_spositiontaking_3 else @max_spositiontaking_3 - @mpositiontaking_3 - @apositiontaking_3 end end
select @spositiontaking_7 = case when isnull(@isauto_spositiontaking_7, 0)<=0 then @spositiontaking_7 else case when @auto_spositiontaking_7 < @max_spositiontaking_7 - @mpositiontaking_7 - @apositiontaking_7 then @auto_spositiontaking_7 else @max_spositiontaking_7 - @mpositiontaking_7 - @apositiontaking_7 end end
select @spositiontaking_8 = case when isnull(@isauto_spositiontaking_8, 0)<=0 then @spositiontaking_8 else case when @auto_spositiontaking_8 < @max_spositiontaking_8 - @mpositiontaking_8 - @apositiontaking_8 then @auto_spositiontaking_8 else @max_spositiontaking_8 - @mpositiontaking_8 - @apositiontaking_8 end end

select @slivepositiontaking_1 = case when isnull(@isauto_slivepositiontaking_1, 0)<=0 then @slivepositiontaking_1 else case when @auto_slivepositiontaking_1 < @max_slivepositiontaking_1 - @mlivepositiontaking_1 - @alivepositiontaking_1 then @auto_slivepositiontaking_1 else @max_slivepositiontaking_1 - @mlivepositiontaking_1 - @alivepositiontaking_1 end end
select @slivepositiontaking_3 = case when isnull(@isauto_slivepositiontaking_3, 0)<=0 then @slivepositiontaking_3 else case when @auto_slivepositiontaking_3 < @max_slivepositiontaking_3 - @mlivepositiontaking_3 - @alivepositiontaking_3 then @auto_slivepositiontaking_3 else @max_slivepositiontaking_3 - @mlivepositiontaking_3 - @alivepositiontaking_3 end end
select @slivepositiontaking_7 = case when isnull(@isauto_slivepositiontaking_7, 0)<=0 then @slivepositiontaking_7 else case when @auto_slivepositiontaking_7 < @max_slivepositiontaking_7 - @mlivepositiontaking_7 - @alivepositiontaking_7 then @auto_slivepositiontaking_7 else @max_slivepositiontaking_7 - @mlivepositiontaking_7 - @alivepositiontaking_7 end end
select @slivepositiontaking_8 = case when isnull(@isauto_slivepositiontaking_8, 0)<=0 then @slivepositiontaking_8 else case when @auto_slivepositiontaking_8 < @max_slivepositiontaking_8 - @mlivepositiontaking_8 - @alivepositiontaking_8 then @auto_slivepositiontaking_8 else @max_slivepositiontaking_8 - @mlivepositiontaking_8 - @alivepositiontaking_8 end end

select @spositiontaking_2 = case when isnull(@isauto_spositiontaking_2, 0)<=0 then @spositiontaking_2 else case when @auto_spositiontaking_2 < @max_spositiontaking_2 - @mpositiontaking_2 - @apositiontaking_2 then @auto_spositiontaking_2 else @max_spositiontaking_2 - @mpositiontaking_2 - @apositiontaking_2 end end
select @spositiontaking_4 = case when isnull(@isauto_spositiontaking_4, 0)<=0 then @spositiontaking_4 else case when @auto_spositiontaking_4 < @max_spositiontaking_4 - @mpositiontaking_4 - @apositiontaking_4 then @auto_spositiontaking_4 else @max_spositiontaking_4 - @mpositiontaking_4 - @apositiontaking_4 end end
select @spositiontaking_5 = case when isnull(@isauto_spositiontaking_5, 0)<=0 then @spositiontaking_5 else case when @auto_spositiontaking_5 < @max_spositiontaking_5 - @mpositiontaking_5 - @apositiontaking_5 then @auto_spositiontaking_5 else @max_spositiontaking_5 - @mpositiontaking_5 - @apositiontaking_5 end end
select @spositiontaking_6 = case when isnull(@isauto_spositiontaking_6, 0)<=0 then @spositiontaking_6 else case when @auto_spositiontaking_6 < @max_spositiontaking_6 - @mpositiontaking_6 - @apositiontaking_6 then @auto_spositiontaking_6 else @max_spositiontaking_6 - @mpositiontaking_6 - @apositiontaking_6 end end
select @spositiontaking_9 = case when isnull(@isauto_spositiontaking_9, 0)<=0 then @spositiontaking_9 else case when @auto_spositiontaking_9 < @max_spositiontaking_9 - @mpositiontaking_9 - @apositiontaking_9 then @auto_spositiontaking_9 else @max_spositiontaking_9 - @mpositiontaking_9 - @apositiontaking_9 end end
select @spositiontaking_10 = case when isnull(@isauto_spositiontaking_10, 0)<=0 then @spositiontaking_10 else case when @auto_spositiontaking_10 < @max_spositiontaking_10 - @mpositiontaking_10 - @apositiontaking_10 then @auto_spositiontaking_10 else @max_spositiontaking_10 - @mpositiontaking_10 - @apositiontaking_10 end end

select @v2spositiontaking_1 = case when isnull(@isauto_v2spositiontaking_1, 0)<=0 then @v2spositiontaking_1 else case when @auto_v2spositiontaking_1 < @max_v2spositiontaking_1 - @v2mpositiontaking_1 - @v2apositiontaking_1 then @auto_v2spositiontaking_1 else @max_v2spositiontaking_1 - @v2mpositiontaking_1 - @v2apositiontaking_1 end end
select @v2spositiontaking_2 = case when isnull(@isauto_v2spositiontaking_2, 0)<=0 then @v2spositiontaking_2 else case when @auto_v2spositiontaking_2 < @max_v2spositiontaking_2 - @v2mpositiontaking_2 - @v2apositiontaking_2 then @auto_v2spositiontaking_2 else @max_v2spositiontaking_2 - @v2mpositiontaking_2 - @v2apositiontaking_2 end end
select @v2spositiontaking_3 = case when isnull(@isauto_v2spositiontaking_3, 0)<=0 then @v2spositiontaking_3 else case when @auto_v2spositiontaking_3 < @max_v2spositiontaking_3 - @v2mpositiontaking_3 - @v2apositiontaking_3 then @auto_v2spositiontaking_3 else @max_v2spositiontaking_3 - @v2mpositiontaking_3 - @v2apositiontaking_3 end end
select @v2spositiontaking_7 = case when isnull(@isauto_v2spositiontaking_7, 0)<=0 then @v2spositiontaking_7 else case when @auto_v2spositiontaking_7 < @max_v2spositiontaking_7 - @v2mpositiontaking_7 - @v2apositiontaking_7 then @auto_v2spositiontaking_7 else @max_v2spositiontaking_7 - @v2mpositiontaking_7 - @v2apositiontaking_7 end end
select @v2spositiontaking_8 = case when isnull(@isauto_v2spositiontaking_8, 0)<=0 then @v2spositiontaking_8 else case when @auto_v2spositiontaking_8 < @max_v2spositiontaking_8 - @v2mpositiontaking_8 - @v2apositiontaking_8 then @auto_v2spositiontaking_8 else @max_v2spositiontaking_8 - @v2mpositiontaking_8 - @v2apositiontaking_8 end end
select @v2spositiontaking_9 = case when isnull(@isauto_v2spositiontaking_9, 0)<=0 then @v2spositiontaking_9 else case when @auto_v2spositiontaking_9 < @max_v2spositiontaking_9 - @v2mpositiontaking_9 - @v2apositiontaking_9 then @auto_v2spositiontaking_9 else @max_v2spositiontaking_9 - @v2mpositiontaking_9 - @v2apositiontaking_9 end end
select @v2spositiontaking_20 = case when isnull(@isauto_v2spositiontaking_20, 0)<=0 then @v2spositiontaking_20 else case when @auto_v2spositiontaking_20 < @max_v2spositiontaking_20 - @v2mpositiontaking_20 - @v2apositiontaking_20 then @auto_v2spositiontaking_20 else @max_v2spositiontaking_20 - @v2mpositiontaking_20 - @v2apositiontaking_20 end end

select @v3spositiontaking_1 = case when isnull(@isauto_v3spositiontaking_1, 0)<=0 then @v3spositiontaking_1 else case when @auto_v3spositiontaking_1 < @max_v3spositiontaking_1 - @v3mpositiontaking_1 - @v3apositiontaking_1 then @auto_v3spositiontaking_1 else @max_v3spositiontaking_1 - @v3mpositiontaking_1 - @v3apositiontaking_1 end end
select @v3spositiontaking_2 = case when isnull(@isauto_v3spositiontaking_2, 0)<=0 then @v3spositiontaking_2 else case when @auto_v3spositiontaking_2 < @max_v3spositiontaking_2 - @v3mpositiontaking_2 - @v3apositiontaking_2 then @auto_v3spositiontaking_2 else @max_v3spositiontaking_2 - @v3mpositiontaking_2 - @v3apositiontaking_2 end end
select @v3spositiontaking_3 = case when isnull(@isauto_v3spositiontaking_3, 0)<=0 then @v3spositiontaking_3 else case when @auto_v3spositiontaking_3 < @max_v3spositiontaking_3 - @v3mpositiontaking_3 - @v3apositiontaking_3 then @auto_v3spositiontaking_3 else @max_v3spositiontaking_3 - @v3mpositiontaking_3 - @v3apositiontaking_3 end end
select @v3spositiontaking_20 = case when isnull(@isauto_v3spositiontaking_20, 0)<=0 then @v3spositiontaking_20 else case when @auto_v3spositiontaking_20 < @max_v3spositiontaking_20 - @v3mpositiontaking_20 - @v3apositiontaking_20 then @auto_v3spositiontaking_20 else @max_v3spositiontaking_20 - @v3mpositiontaking_20 - @v3apositiontaking_20 end end

select @v5spositiontaking_1 = case when isnull(@isauto_v5spositiontaking_1, 0)<=0 then @v5spositiontaking_1 else case when @auto_v5spositiontaking_1 < @max_v5spositiontaking_1 - @v5mpositiontaking_1 - @v5apositiontaking_1 then @auto_v5spositiontaking_1 else @max_v5spositiontaking_1 - @v5mpositiontaking_1 - @v5apositiontaking_1 end end
select @v5spositiontaking_2 = case when isnull(@isauto_v5spositiontaking_2, 0)<=0 then @v5spositiontaking_2 else case when @auto_v5spositiontaking_2 < @max_v5spositiontaking_2 - @v5mpositiontaking_2 - @v5apositiontaking_2 then @auto_v5spositiontaking_2 else @max_v5spositiontaking_2 - @v5mpositiontaking_2 - @v5apositiontaking_2 end end
select @v5spositiontaking_3 = case when isnull(@isauto_v5spositiontaking_3, 0)<=0 then @v5spositiontaking_3 else case when @auto_v5spositiontaking_3 < @max_v5spositiontaking_3 - @v5mpositiontaking_3 - @v5apositiontaking_3 then @auto_v5spositiontaking_3 else @max_v5spositiontaking_3 - @v5mpositiontaking_3 - @v5apositiontaking_3 end end
select @v5spositiontaking_20 = case when isnull(@isauto_v5spositiontaking_20, 0)<=0 then @v5spositiontaking_20 else case when @auto_v5spositiontaking_20 < @max_v5spositiontaking_20 - @v5mpositiontaking_20 - @v5apositiontaking_20 then @auto_v5spositiontaking_20 else @max_v5spositiontaking_20 - @v5mpositiontaking_20 - @v5apositiontaking_20 end end

select @v8spositiontaking_1 = case when isnull(@isauto_v8spositiontaking_1, 0)<=0 then @v8spositiontaking_1 else case when @auto_v8spositiontaking_1 < @max_v8spositiontaking_1 - @v8mpositiontaking_1 - @v8apositiontaking_1 then @auto_v8spositiontaking_1 else @max_v8spositiontaking_1 - @v8mpositiontaking_1 - @v8apositiontaking_1 end end
select @v8spositiontaking_3 = case when isnull(@isauto_v8spositiontaking_3, 0)<=0 then @v8spositiontaking_3 else case when @auto_v8spositiontaking_3 < @max_v8spositiontaking_3 - @v8mpositiontaking_3 - @v8apositiontaking_3 then @auto_v8spositiontaking_3 else @max_v8spositiontaking_3 - @v8mpositiontaking_3 - @v8apositiontaking_3 end end
select @v8spositiontaking_20 = case when isnull(@isauto_v8spositiontaking_20, 0)<=0 then @v8spositiontaking_20 else case when @auto_v8spositiontaking_20 < @max_v8spositiontaking_20 - @v8mpositiontaking_20 - @v8apositiontaking_20 then @auto_v8spositiontaking_20 else @max_v8spositiontaking_20 - @v8mpositiontaking_20 - @v8apositiontaking_20 end end

select @v10spositiontaking_1 = case when isnull(@isauto_v10spositiontaking_1, 0)<=0 then @v10spositiontaking_1 else case when @auto_v10spositiontaking_1 < @max_v10spositiontaking_1 - @v10mpositiontaking_1 - @v10apositiontaking_1 then @auto_v10spositiontaking_1 else @max_v10spositiontaking_1 - @v10mpositiontaking_1 - @v10apositiontaking_1 end end
select @v10spositiontaking_2 = case when isnull(@isauto_v10spositiontaking_2, 0)<=0 then @v10spositiontaking_2 else case when @auto_v10spositiontaking_2 < @max_v10spositiontaking_2 - @v10mpositiontaking_2 - @v10apositiontaking_2 then @auto_v10spositiontaking_2 else @max_v10spositiontaking_2 - @v10mpositiontaking_2 - @v10apositiontaking_2 end end
select @v10spositiontaking_3 = case when isnull(@isauto_v10spositiontaking_3, 0)<=0 then @v10spositiontaking_3 else case when @auto_v10spositiontaking_3 < @max_v10spositiontaking_3 - @v10mpositiontaking_3 - @v10apositiontaking_3 then @auto_v10spositiontaking_3 else @max_v10spositiontaking_3 - @v10mpositiontaking_3 - @v10apositiontaking_3 end end
select @v10spositiontaking_20 = case when isnull(@isauto_v10spositiontaking_20, 0)<=0 then @v10spositiontaking_20 else case when @auto_v10spositiontaking_20 < @max_v10spositiontaking_20 - @v10mpositiontaking_20 - @v10apositiontaking_20 then @auto_v10spositiontaking_20 else @max_v10spositiontaking_20 - @v10mpositiontaking_20 - @v10apositiontaking_20 end end

select @v11spositiontaking_1 = case when isnull(@isauto_v11spositiontaking_1, 0)<=0 then @v11spositiontaking_1 else case when @auto_v11spositiontaking_1 < @max_v11spositiontaking_1 - @v11mpositiontaking_1 - @v11apositiontaking_1 then @auto_v11spositiontaking_1 else @max_v11spositiontaking_1 - @v11mpositiontaking_1 - @v11apositiontaking_1 end end
select @v11spositiontaking_20 = case when isnull(@isauto_v11spositiontaking_20, 0)<=0 then @v11spositiontaking_20 else case when @auto_v11spositiontaking_20 < @max_v11spositiontaking_20 - @v11mpositiontaking_20 - @v11apositiontaking_20 then @auto_v11spositiontaking_20 else @max_v11spositiontaking_20 - @v11mpositiontaking_20 - @v11apositiontaking_20 end end
--v021
select @v201spositiontaking_3 = case when isnull(@isauto_v201spositiontaking_3, 0)<=0 then @v201spositiontaking_3 else case when @auto_v201spositiontaking_3 < @max_v201spositiontaking_3 - @v201mpositiontaking_3 - @v201apositiontaking_3 then @auto_v201spositiontaking_3 else @max_v201spositiontaking_3 - @v201mpositiontaking_3 - @v201apositiontaking_3 end end

select @v99spositiontaking_1 = case when isnull(@isauto_v99spositiontaking_1, 0)<=0 then @v99spositiontaking_1 else case when @auto_v99spositiontaking_1 < @max_v99spositiontaking_1 - @v99mpositiontaking_1 - @v99apositiontaking_1 then @auto_v99spositiontaking_1 else @max_v99spositiontaking_1 - @v99mpositiontaking_1 - @v99apositiontaking_1 end end
select @v99spositiontaking_2 = case when isnull(@isauto_v99spositiontaking_2, 0)<=0 then @v99spositiontaking_2 else case when @auto_v99spositiontaking_2 < @max_v99spositiontaking_2 - @v99mpositiontaking_2 - @v99apositiontaking_2 then @auto_v99spositiontaking_2 else @max_v99spositiontaking_2 - @v99mpositiontaking_2 - @v99apositiontaking_2 end end
select @v99spositiontaking_3 = case when isnull(@isauto_v99spositiontaking_3, 0)<=0 then @v99spositiontaking_3 else case when @auto_v99spositiontaking_3 < @max_v99spositiontaking_3 - @v99mpositiontaking_3 - @v99apositiontaking_3 then @auto_v99spositiontaking_3 else @max_v99spositiontaking_3 - @v99mpositiontaking_3 - @v99apositiontaking_3 end end
select @v99spositiontaking_20 = case when isnull(@isauto_v99spositiontaking_20, 0)<=0 then @v99spositiontaking_20 else case when @auto_v99spositiontaking_20 < @max_v99spositiontaking_20 - @v99mpositiontaking_20 - @v99apositiontaking_20 then @auto_v99spositiontaking_20 else @max_v99spositiontaking_20 - @v99mpositiontaking_20 - @v99apositiontaking_20 end end

-------------------------------------------------------------------------------
--maxs1=isauto?s4:s4-m3
select @max_spositiontaking_1 = case when isnull(@isauto_spositiontaking_1, 0)>0 then @max_spositiontaking_1 else @max_spositiontaking_1-@max_mapositiontaking_1 end
select @max_spositiontaking_3 = case when isnull(@isauto_spositiontaking_3, 0)>0 then @max_spositiontaking_3 else @max_spositiontaking_3-@max_mapositiontaking_3 end
select @max_spositiontaking_7 = case when isnull(@isauto_spositiontaking_7, 0)>0 then @max_spositiontaking_7 else @max_spositiontaking_7-@max_mapositiontaking_7 end
select @max_spositiontaking_8 = case when isnull(@isauto_spositiontaking_8, 0)>0 then @max_spositiontaking_8 else @max_spositiontaking_8-@max_mapositiontaking_8 end

select @max_slivepositiontaking_1 = case when isnull(@isauto_slivepositiontaking_1, 0)>0 then @max_slivepositiontaking_1 else @max_slivepositiontaking_1-@max_malivepositiontaking_1 end
select @max_slivepositiontaking_3 = case when isnull(@isauto_slivepositiontaking_3, 0)>0 then @max_slivepositiontaking_3 else @max_slivepositiontaking_3-@max_malivepositiontaking_3 end
select @max_slivepositiontaking_7 = case when isnull(@isauto_slivepositiontaking_7, 0)>0 then @max_slivepositiontaking_7 else @max_slivepositiontaking_7-@max_malivepositiontaking_7 end
select @max_slivepositiontaking_8 = case when isnull(@isauto_slivepositiontaking_8, 0)>0 then @max_slivepositiontaking_8 else @max_slivepositiontaking_8-@max_malivepositiontaking_8 end

select @max_spositiontaking_2 = case when isnull(@isauto_spositiontaking_2, 0)>0 then @max_spositiontaking_2 else @max_spositiontaking_2-@max_mapositiontaking_2 end
select @max_spositiontaking_4 = case when isnull(@isauto_spositiontaking_4, 0)>0 then @max_spositiontaking_4 else @max_spositiontaking_4-@max_mapositiontaking_4 end
select @max_spositiontaking_5 = case when isnull(@isauto_spositiontaking_5, 0)>0 then @max_spositiontaking_5 else @max_spositiontaking_5-@max_mapositiontaking_5 end
select @max_spositiontaking_6 = case when isnull(@isauto_spositiontaking_6, 0)>0 then @max_spositiontaking_6 else @max_spositiontaking_6-@max_mapositiontaking_6 end
select @max_spositiontaking_9 = case when isnull(@isauto_spositiontaking_9, 0)>0 then @max_spositiontaking_9 else @max_spositiontaking_9-@max_mapositiontaking_9 end
select @max_spositiontaking_10 = case when isnull(@isauto_spositiontaking_10, 0)>0 then @max_spositiontaking_10 else @max_spositiontaking_10-@max_mapositiontaking_10 end

select @max_v2spositiontaking_1 = case when isnull(@isauto_v2spositiontaking_1, 0)>0 then @max_v2spositiontaking_1 else @max_v2spositiontaking_1-@max_v2mapositiontaking_1 end
select @max_v2spositiontaking_2 = case when isnull(@isauto_v2spositiontaking_2, 0)>0 then @max_v2spositiontaking_2 else @max_v2spositiontaking_2-@max_v2mapositiontaking_2 end
select @max_v2spositiontaking_3 = case when isnull(@isauto_v2spositiontaking_3, 0)>0 then @max_v2spositiontaking_3 else @max_v2spositiontaking_3-@max_v2mapositiontaking_3 end
select @max_v2spositiontaking_7 = case when isnull(@isauto_v2spositiontaking_7, 0)>0 then @max_v2spositiontaking_7 else @max_v2spositiontaking_7-@max_v2mapositiontaking_7 end
select @max_v2spositiontaking_8 = case when isnull(@isauto_v2spositiontaking_8, 0)>0 then @max_v2spositiontaking_8 else @max_v2spositiontaking_8-@max_v2mapositiontaking_8 end
select @max_v2spositiontaking_9 = case when isnull(@isauto_v2spositiontaking_9, 0)>0 then @max_v2spositiontaking_9 else @max_v2spositiontaking_9-@max_v2mapositiontaking_9 end
select @max_v2spositiontaking_20 = case when isnull(@isauto_v2spositiontaking_20, 0)>0 then @max_v2spositiontaking_20 else @max_v2spositiontaking_20-@max_v2mapositiontaking_20 end

select @max_v3spositiontaking_1 = case when isnull(@isauto_v3spositiontaking_1, 0)>0 then @max_v3spositiontaking_1 else @max_v3spositiontaking_1-@max_v3mapositiontaking_1 end
select @max_v3spositiontaking_2 = case when isnull(@isauto_v3spositiontaking_2, 0)>0 then @max_v3spositiontaking_2 else @max_v3spositiontaking_2-@max_v3mapositiontaking_2 end
select @max_v3spositiontaking_3 = case when isnull(@isauto_v3spositiontaking_3, 0)>0 then @max_v3spositiontaking_3 else @max_v3spositiontaking_3-@max_v3mapositiontaking_3 end
select @max_v3spositiontaking_20 = case when isnull(@isauto_v3spositiontaking_20, 0)>0 then @max_v3spositiontaking_20 else @max_v3spositiontaking_20-@max_v3mapositiontaking_20 end

select @max_v5spositiontaking_1 = case when isnull(@isauto_v5spositiontaking_1, 0)>0 then @max_v5spositiontaking_1 else @max_v5spositiontaking_1-@max_v5mapositiontaking_1 end
select @max_v5spositiontaking_2 = case when isnull(@isauto_v5spositiontaking_2, 0)>0 then @max_v5spositiontaking_2 else @max_v5spositiontaking_2-@max_v5mapositiontaking_2 end
select @max_v5spositiontaking_3 = case when isnull(@isauto_v5spositiontaking_3, 0)>0 then @max_v5spositiontaking_3 else @max_v5spositiontaking_3-@max_v5mapositiontaking_3 end
select @max_v5spositiontaking_20 = case when isnull(@isauto_v5spositiontaking_20, 0)>0 then @max_v5spositiontaking_20 else @max_v5spositiontaking_20-@max_v5mapositiontaking_20 end

select @max_v8spositiontaking_1 = case when isnull(@isauto_v8spositiontaking_1, 0)>0 then @max_v8spositiontaking_1 else @max_v8spositiontaking_1-@max_v8mapositiontaking_1 end
select @max_v8spositiontaking_3 = case when isnull(@isauto_v8spositiontaking_3, 0)>0 then @max_v8spositiontaking_3 else @max_v8spositiontaking_3-@max_v8mapositiontaking_3 end
select @max_v8spositiontaking_20 = case when isnull(@isauto_v8spositiontaking_20, 0)>0 then @max_v8spositiontaking_20 else @max_v8spositiontaking_20-@max_v8mapositiontaking_20 end

select @max_v10spositiontaking_1 = case when isnull(@isauto_v10spositiontaking_1, 0)>0 then @max_v10spositiontaking_1 else @max_v10spositiontaking_1-@max_v10mapositiontaking_1 end
select @max_v10spositiontaking_2 = case when isnull(@isauto_v10spositiontaking_2, 0)>0 then @max_v10spositiontaking_2 else @max_v10spositiontaking_2-@max_v10mapositiontaking_2 end
select @max_v10spositiontaking_3 = case when isnull(@isauto_v10spositiontaking_3, 0)>0 then @max_v10spositiontaking_3 else @max_v10spositiontaking_3-@max_v10mapositiontaking_3 end
select @max_v10spositiontaking_20 = case when isnull(@isauto_v10spositiontaking_20, 0)>0 then @max_v10spositiontaking_20 else @max_v10spositiontaking_20-@max_v10mapositiontaking_20 end

select @max_v11spositiontaking_1 = case when isnull(@isauto_v11spositiontaking_1, 0)>0 then @max_v11spositiontaking_1 else @max_v11spositiontaking_1-@max_v11mapositiontaking_1 end
select @max_v11spositiontaking_20 = case when isnull(@isauto_v11spositiontaking_20, 0)>0 then @max_v11spositiontaking_20 else @max_v11spositiontaking_20-@max_v11mapositiontaking_20 end
--v201
select @max_v201spositiontaking_3 = case when isnull(@isauto_v201spositiontaking_3, 0)>0 then @max_v201spositiontaking_3 else @max_v201spositiontaking_3-@max_v201mapositiontaking_3 end

select @max_v99spositiontaking_1 = case when isnull(@isauto_v99spositiontaking_1, 0)>0 then @max_v99spositiontaking_1 else @max_v99spositiontaking_1-@max_v99mapositiontaking_1 end
select @max_v99spositiontaking_2 = case when isnull(@isauto_v99spositiontaking_2, 0)>0 then @max_v99spositiontaking_2 else @max_v99spositiontaking_2-@max_v99mapositiontaking_2 end
select @max_v99spositiontaking_3 = case when isnull(@isauto_v99spositiontaking_3, 0)>0 then @max_v99spositiontaking_3 else @max_v99spositiontaking_3-@max_v99mapositiontaking_3 end
select @max_v99spositiontaking_20 = case when isnull(@isauto_v99spositiontaking_20, 0)>0 then @max_v99spositiontaking_20 else @max_v99spositiontaking_20-@max_v99mapositiontaking_20 end
--s1=s1>maxs1?maxs1:s1
select @spositiontaking_1 = case when @spositiontaking_1 > @max_spositiontaking_1 then @max_spositiontaking_1 else @spositiontaking_1 end
select @spositiontaking_3 = case when @spositiontaking_3 > @max_spositiontaking_3 then @max_spositiontaking_3 else @spositiontaking_3 end
select @spositiontaking_7 = case when @spositiontaking_7 > @max_spositiontaking_7 then @max_spositiontaking_7 else @spositiontaking_7 end
select @spositiontaking_8 = case when @spositiontaking_8 > @max_spositiontaking_8 then @max_spositiontaking_8 else @spositiontaking_8 end

select @slivepositiontaking_1 = case when @slivepositiontaking_1 > @max_slivepositiontaking_1 then @max_slivepositiontaking_1 else @slivepositiontaking_1 end
select @slivepositiontaking_3 = case when @slivepositiontaking_3 > @max_slivepositiontaking_3 then @max_slivepositiontaking_3 else @slivepositiontaking_3 end
select @slivepositiontaking_7 = case when @slivepositiontaking_7 > @max_slivepositiontaking_7 then @max_slivepositiontaking_7 else @slivepositiontaking_7 end
select @slivepositiontaking_8 = case when @slivepositiontaking_8 > @max_slivepositiontaking_8 then @max_slivepositiontaking_8 else @slivepositiontaking_8 end

select @spositiontaking_2 = case when @spositiontaking_2 > @max_spositiontaking_2 then @max_spositiontaking_2 else @spositiontaking_2 end
select @spositiontaking_4 = case when @spositiontaking_4 > @max_spositiontaking_4 then @max_spositiontaking_4 else @spositiontaking_4 end
select @spositiontaking_5 = case when @spositiontaking_5 > @max_spositiontaking_5 then @max_spositiontaking_5 else @spositiontaking_5 end
select @spositiontaking_6 = case when @spositiontaking_6 > @max_spositiontaking_6 then @max_spositiontaking_6 else @spositiontaking_6 end
select @spositiontaking_9 = case when @spositiontaking_9 > @max_spositiontaking_9 then @max_spositiontaking_9 else @spositiontaking_9 end
select @spositiontaking_10 = case when @spositiontaking_10 > @max_spositiontaking_10 then @max_spositiontaking_10 else @spositiontaking_10 end

select @v2spositiontaking_1 = case when @v2spositiontaking_1 > @max_v2spositiontaking_1 then @max_v2spositiontaking_1 else @v2spositiontaking_1 end
select @v2spositiontaking_2 = case when @v2spositiontaking_2 > @max_v2spositiontaking_2 then @max_v2spositiontaking_2 else @v2spositiontaking_2 end
select @v2spositiontaking_3 = case when @v2spositiontaking_3 > @max_v2spositiontaking_3 then @max_v2spositiontaking_3 else @v2spositiontaking_3 end
select @v2spositiontaking_7 = case when @v2spositiontaking_7 > @max_v2spositiontaking_7 then @max_v2spositiontaking_7 else @v2spositiontaking_7 end
select @v2spositiontaking_8 = case when @v2spositiontaking_8 > @max_v2spositiontaking_8 then @max_v2spositiontaking_8 else @v2spositiontaking_8 end
select @v2spositiontaking_9 = case when @v2spositiontaking_9 > @max_v2spositiontaking_9 then @max_v2spositiontaking_9 else @v2spositiontaking_9 end
select @v2spositiontaking_20 = case when @v2spositiontaking_20 > @max_v2spositiontaking_20 then @max_v2spositiontaking_20 else @v2spositiontaking_20 end

select @v3spositiontaking_1 = case when @v3spositiontaking_1 > @max_v3spositiontaking_1 then @max_v3spositiontaking_1 else @v3spositiontaking_1 end
select @v3spositiontaking_2 = case when @v3spositiontaking_2 > @max_v3spositiontaking_2 then @max_v3spositiontaking_2 else @v3spositiontaking_2 end
select @v3spositiontaking_3 = case when @v3spositiontaking_3 > @max_v3spositiontaking_3 then @max_v3spositiontaking_3 else @v3spositiontaking_3 end
select @v3spositiontaking_20 = case when @v3spositiontaking_20 > @max_v3spositiontaking_20 then @max_v3spositiontaking_20 else @v3spositiontaking_20 end

select @v5spositiontaking_1 = case when @v5spositiontaking_1 > @max_v5spositiontaking_1 then @max_v5spositiontaking_1 else @v5spositiontaking_1 end
select @v5spositiontaking_2 = case when @v5spositiontaking_2 > @max_v5spositiontaking_2 then @max_v5spositiontaking_2 else @v5spositiontaking_2 end
select @v5spositiontaking_3 = case when @v5spositiontaking_3 > @max_v5spositiontaking_3 then @max_v5spositiontaking_3 else @v5spositiontaking_3 end
select @v5spositiontaking_20 = case when @v5spositiontaking_20 > @max_v5spositiontaking_20 then @max_v5spositiontaking_20 else @v5spositiontaking_20 end

select @v8spositiontaking_1 = case when @v8spositiontaking_1 > @max_v8spositiontaking_1 then @max_v8spositiontaking_1 else @v8spositiontaking_1 end
select @v8spositiontaking_3 = case when @v8spositiontaking_3 > @max_v8spositiontaking_3 then @max_v8spositiontaking_3 else @v8spositiontaking_3 end
select @v8spositiontaking_20 = case when @v8spositiontaking_20 > @max_v8spositiontaking_20 then @max_v8spositiontaking_20 else @v8spositiontaking_20 end

select @v10spositiontaking_1 = case when @v10spositiontaking_1 > @max_v10spositiontaking_1 then @max_v10spositiontaking_1 else @v10spositiontaking_1 end
select @v10spositiontaking_2 = case when @v10spositiontaking_2 > @max_v10spositiontaking_2 then @max_v10spositiontaking_2 else @v10spositiontaking_2 end
select @v10spositiontaking_3 = case when @v10spositiontaking_3 > @max_v10spositiontaking_3 then @max_v10spositiontaking_3 else @v10spositiontaking_3 end
select @v10spositiontaking_20 = case when @v10spositiontaking_20 > @max_v10spositiontaking_20 then @max_v10spositiontaking_20 else @v10spositiontaking_20 end

select @v11spositiontaking_1 = case when @v11spositiontaking_1 > @max_v11spositiontaking_1 then @max_v11spositiontaking_1 else @v11spositiontaking_1 end
select @v11spositiontaking_20 = case when @v11spositiontaking_20 > @max_v11spositiontaking_20 then @max_v11spositiontaking_20 else @v11spositiontaking_20 end
--v201
select @v201spositiontaking_3 = case when @v201spositiontaking_3 > @max_v201spositiontaking_3 then @max_v201spositiontaking_3 else @v201spositiontaking_3 end

select @v99spositiontaking_1 = case when @v99spositiontaking_1 > @max_v99spositiontaking_1 then @max_v99spositiontaking_1 else @v99spositiontaking_1 end
select @v99spositiontaking_2 = case when @v99spositiontaking_2 > @max_v99spositiontaking_2 then @max_v99spositiontaking_2 else @v99spositiontaking_2 end
select @v99spositiontaking_3 = case when @v99spositiontaking_3 > @max_v99spositiontaking_3 then @max_v99spositiontaking_3 else @v99spositiontaking_3 end
select @v99spositiontaking_20 = case when @v99spositiontaking_20 > @max_v99spositiontaking_20 then @max_v99spositiontaking_20 else @v99spositiontaking_20 end

/*
print 'spos: ' + convert(varchar(20), @spositiontaking_1)
print 'spos: ' + convert(varchar(20), @spositiontaking_1)
print 'is auto spos: ' + convert(varchar(20), @isauto_spositiontaking_1)
print 'autospos: ' + convert(varchar(20), @auto_spositiontaking_1)
*/
if @allowupdatepositiontaking = 1
BEGIN
	--don't update m1,s1 for member under agent was set i2=1(normal)
	update cs with (ROWLOCK, UPDLOCK)
	set
		mpositiontaking = case cs.sporttype 	when 1 then case cs.bettype when 1 then @mpositiontaking_1 when 2 then @mpositiontaking_2 when 3 then @mpositiontaking_3 when 4 then @mpositiontaking_4 when 5 then @mpositiontaking_5 when 6 then @mpositiontaking_6 when 7 then @mpositiontaking_7 when 8 then @mpositiontaking_8 when 9 then @mpositiontaking_9 when 10 then @mpositiontaking_10 else 0 end
						when 2 then case cs.bettype when 1 then @v2mpositiontaking_1 when 2 then @v2mpositiontaking_2 when 3 then @v2mpositiontaking_3 when 7 then @v2mpositiontaking_7 when 8 then @v2mpositiontaking_8 when 9 then @v2mpositiontaking_9 when 20 then @v2mpositiontaking_20 else 0 end
						when 3 then case cs.bettype when 1 then @v3mpositiontaking_1 when 2 then @v3mpositiontaking_2 when 3 then @v3mpositiontaking_3 when 20 then @v3mpositiontaking_20 else 0 end
						when 5 then case cs.bettype when 1 then @v5mpositiontaking_1 when 2 then @v5mpositiontaking_2 when 3 then @v5mpositiontaking_3 when 20 then @v5mpositiontaking_20 else 0 end
						when 8 then case cs.bettype when 1 then @v8mpositiontaking_1 when 3 then @v8mpositiontaking_3 when 20 then @v8mpositiontaking_20 else 0 end
						when 10 then case cs.bettype when 1 then @v10mpositiontaking_1 when 2 then @v10mpositiontaking_2 when 3 then @v10mpositiontaking_3 when 20 then @v10mpositiontaking_20 else 0 end
						when 11 then case cs.bettype when 1 then @v11mpositiontaking_1 when 20 then @v11mpositiontaking_20 else 0 end
						--v201
						when 201 then case cs.bettype when 3 then @v201mpositiontaking_3 else 0 end

						when 99 then case cs.bettype when 1 then @v99mpositiontaking_1 when 2 then @v99mpositiontaking_2 when 3 then @v99mpositiontaking_3 when 20 then @v99mpositiontaking_20 else 0 end
						else cs.mpositiontaking end,
		spositiontaking =  case cs.sporttype when 1 then case cs.bettype when 1 then @spositiontaking_1 when 2 then @spositiontaking_2 when 3 then @spositiontaking_3 when 4 then @spositiontaking_4 when 5 then @spositiontaking_5 when 6 then @spositiontaking_6 when 7 then @spositiontaking_7 when 8 then @spositiontaking_8 when 9 then @spositiontaking_9 when 10 then @spositiontaking_10 else 0 end
						when 2 then case cs.bettype when 1 then @v2spositiontaking_1 when 2 then @v2spositiontaking_2 when 3 then @v2spositiontaking_3 when 7 then @v2spositiontaking_7 when 8 then @v2spositiontaking_8 when 9 then @v2spositiontaking_9 when 20 then @v2spositiontaking_20 else 0 end
						when 3 then case cs.bettype when 1 then @v3spositiontaking_1 when 2 then @v3spositiontaking_2 when 3 then @v3spositiontaking_3 when 20 then @v3spositiontaking_20 else 0 end
						when 5 then case cs.bettype when 1 then @v5spositiontaking_1 when 2 then @v5spositiontaking_2 when 3 then @v5spositiontaking_3 when 20 then @v5spositiontaking_20 else 0 end
						when 8 then case cs.bettype when 1 then @v8spositiontaking_1 when 3 then @v8spositiontaking_3 when 20 then @v8spositiontaking_20 else 0 end
						when 10 then case cs.bettype when 1 then @v10spositiontaking_1 when 2 then @v10spositiontaking_2 when 3 then @v10spositiontaking_3 when 20 then @v10spositiontaking_20 else 0 end
						when 11 then case cs.bettype when 1 then @v11spositiontaking_1 when 20 then @v11spositiontaking_20 else 0 end
						--v201
						when 201 then case cs.bettype when 3 then @v201spositiontaking_3 else 0 end
						when 99 then case cs.bettype when 1 then @v99spositiontaking_1 when 2 then @v99spositiontaking_2 when 3 then @v99spositiontaking_3 when 20 then @v99spositiontaking_20 else 0 end
						else cs.spositiontaking end
	from Custsetting cs inner join customer c with(nolock) on cs.custid = c.custid
		inner join Custsetting acs with(nolock) on acs.custid = c.recommend and cs.sporttype = acs.sporttype and cs.bettype = acs.bettype 
	where c.custid=@custid and c.roleid = 1 and acs.isautopositiontaking = 0 

	--don't update m1,s1 for member under agent was set i2=1(live)
	update cs with (ROWLOCK, UPDLOCK)
	set
		mlivepositiontaking = case cs.sporttype 	when 1 then case cs.bettype when 1 then @mlivepositiontaking_1 when 3 then @mlivepositiontaking_3 when 7 then @mlivepositiontaking_7 when 8 then @mlivepositiontaking_8 else cs.mlivepositiontaking end else cs.mlivepositiontaking end,
		slivepositiontaking = case cs.sporttype 	when 1 then case cs.bettype when 1 then @slivepositiontaking_1 when 3 then @slivepositiontaking_3 when 7 then @slivepositiontaking_7 when 8 then @slivepositiontaking_8 else cs.slivepositiontaking end else cs.slivepositiontaking end
	from Custsetting cs inner join customer c with(nolock) on cs.custid = c.custid
		inner join Custsetting acs with(nolock) on acs.custid = c.recommend and cs.sporttype = acs.sporttype and cs.bettype = acs.bettype 
	where c.custid=@custid and c.roleid = 1 and acs.isautolivepositiontaking = 0 
END
EXEC dbo.Acc_CustomerUpdMember_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend


--Log for PT
	
Select @LogSPData = '<m>mpt_1='+ coalesce(cast(@mpositiontaking_1 as varchar(50)),space(1)) + ',
mpt_2='+ coalesce(cast(@mpositiontaking_2 as varchar(50)),space(1)) + ',
mpt_3='+ coalesce(cast(@mpositiontaking_3 as varchar(50)),space(1)) + ',
mpt_4='+ coalesce(cast(@mpositiontaking_4 as varchar(50)),space(1)) + ',
mpt_5='+ coalesce(cast(@mpositiontaking_5 as varchar(50)),space(1)) + ',
mpt_6='+ coalesce(cast(@mpositiontaking_6 as varchar(50)),space(1)) + ',
mpt_7='+ coalesce(cast(@mpositiontaking_7 as varchar(50)),space(1)) + ',
mpt_8='+ coalesce(cast(@mpositiontaking_8 as varchar(50)),space(1)) + ',
mpt_9='+ coalesce(cast(@mpositiontaking_9 as varchar(50)),space(1)) + ',
mpt_10='+ coalesce(cast(@mpositiontaking_10 as varchar(50)),space(1)) + ',
mlivept_1='+ coalesce(cast(@mlivepositiontaking_1 as varchar(50)),space(1)) + ',
mlivept_3='+ coalesce(cast(@mlivepositiontaking_3 as varchar(50)),space(1)) + ',
mlivept_7='+ coalesce(cast(@mlivepositiontaking_7 as varchar(50)),space(1)) + ',
mlivept_8='+ coalesce(cast(@mlivepositiontaking_8 as varchar(50)),space(1)) + ' '+char(7)+ 

'v2mpt_1='+ coalesce(cast(@v2mpositiontaking_1 as varchar(50)),space(1)) + ',
v2mpt_2='+ coalesce(cast(@v2mpositiontaking_2 as varchar(50)),space(1)) + ',
v2mpt_3='+ coalesce(cast(@v2mpositiontaking_3 as varchar(50)),space(1)) + ',
v2mpt_7='+ coalesce(cast(@v2mpositiontaking_7 as varchar(50)),space(1)) + ',
v2mpt_8='+ coalesce(cast(@v2mpositiontaking_8 as varchar(50)),space(1)) + ',
v2mpt_9='+ coalesce(cast(@v2mpositiontaking_9 as varchar(50)),space(1)) + ',
v2mpt_20='+ coalesce(cast(@v2mpositiontaking_20 as varchar(50)),space(1)) + ' ' +char(7)+ 

'v3mpt_1='+ coalesce(cast(@v3mpositiontaking_1 as varchar(50)),space(1)) + ',
v3mpt_2='+ coalesce(cast(@v3mpositiontaking_2 as varchar(50)),space(1)) + ',
v3mpt_3='+ coalesce(cast(@v3mpositiontaking_3 as varchar(50)),space(1)) + ',
v3mpt_20='+ coalesce(cast(@v3mpositiontaking_20 as varchar(50)),space(1)) + ' '+char(7)+ 

'v5mpt_1='+ coalesce(cast(@v5mpositiontaking_1 as varchar(50)),space(1)) + ',
v5mpt_2='+ coalesce(cast(@v5mpositiontaking_2 as varchar(50)),space(1)) + ',
v5mpt_3='+ coalesce(cast(@v5mpositiontaking_3 as varchar(50)),space(1)) + ',
v5mpt_20='+ coalesce(cast(@v5mpositiontaking_20 as varchar(50)),space(1)) + ' '+char(7)+ 

'v8mpt_1='+ coalesce(cast(@v8mpositiontaking_1 as varchar(50)),space(1)) + ',
v8mpt_3='+ coalesce(cast(@v8mpositiontaking_3 as varchar(50)),space(1)) + ',
v8mpt_20='+ coalesce(cast(@v8mpositiontaking_20 as varchar(50)),space(1)) + ' '+char(7)+ 

'v10mpt_1='+ coalesce(cast(@v10mpositiontaking_1 as varchar(50)),space(1)) + ',
v10mpt_2='+ coalesce(cast(@v10mpositiontaking_2 as varchar(50)),space(1)) + ',
v10mpt_3='+ coalesce(cast(@v10mpositiontaking_3 as varchar(50)),space(1)) + ',
v10mpt_20='+ coalesce(cast(@v10mpositiontaking_20 as varchar(50)),space(1)) + ' '+char(7)+ 

'v11mpt_1='+ coalesce(cast(@v11mpositiontaking_1 as varchar(50)),space(1)) + ',
v11mpt_20='+ coalesce(cast(@v11mpositiontaking_20 as varchar(50)),space(1)) + ' '+char(7)+ 

'v201mpt_3='+ coalesce(cast(@v201mpositiontaking_3 as varchar(50)),space(1)) + ' '+char(7)+ 

'v99mpt_1='+ coalesce(cast(@v99mpositiontaking_1 as varchar(50)),space(1)) + ',
v99mpt_2='+ coalesce(cast(@v99mpositiontaking_2 as varchar(50)),space(1)) + ',
v99mpt_3='+ coalesce(cast(@v99mpositiontaking_3 as varchar(50)),space(1)) + ',
v99mpt_20='+ coalesce(cast(@v99mpositiontaking_20 as varchar(50)),space(1)) + ' '+char(7)+ '</m>'+

--isauto 
'<iam>isa_mpt_1='+ coalesce(cast(@isauto_mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_mpt_2='+ coalesce(cast(@isauto_mpositiontaking_2 as varchar(50)),space(1)) + ',
isa_mpt_3='+ coalesce(cast(@isauto_mpositiontaking_3 as varchar(50)),space(1)) + ',
isa_mpt_4='+ coalesce(cast(@isauto_mpositiontaking_4 as varchar(50)),space(1)) + ',
isa_mpt_5='+ coalesce(cast(@isauto_mpositiontaking_5 as varchar(50)),space(1)) + ',
isa_mpt_6='+ coalesce(cast(@isauto_mpositiontaking_6 as varchar(50)),space(1)) + ',
isa_mpt_7='+ coalesce(cast(@isauto_mpositiontaking_7 as varchar(50)),space(1)) + ',
isa_mpt_8='+ coalesce(cast(@isauto_mpositiontaking_8 as varchar(50)),space(1)) + ',
isa_mpt_9='+ coalesce(cast(@isauto_mpositiontaking_9 as varchar(50)),space(1)) + ',
isa_mpt_10='+ coalesce(cast(@isauto_mpositiontaking_10 as varchar(50)),space(1)) + ',
isa_mlivept_1='+ coalesce(cast(@isauto_mlivepositiontaking_1 as varchar(50)),space(1)) + ',
isa_mlivept_3='+ coalesce(cast(@isauto_mlivepositiontaking_3 as varchar(50)),space(1)) + ',
isa_mlivept_7='+ coalesce(cast(@isauto_mlivepositiontaking_7 as varchar(50)),space(1)) + ',
isa_mlivept_8='+ coalesce(cast(@isauto_mlivepositiontaking_8 as varchar(50)),space(1)) + ',

isa_v2mpt_1='+ coalesce(cast(@isauto_v2mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_v2mpt_2='+ coalesce(cast(@isauto_v2mpositiontaking_2 as varchar(50)),space(1)) + ',
isa_v2mpt_3='+ coalesce(cast(@isauto_v2mpositiontaking_3 as varchar(50)),space(1)) + ',
isa_v2mpt_7='+ coalesce(cast(@isauto_v2mpositiontaking_7 as varchar(50)),space(1)) + ',
isa_v2mpt_8='+ coalesce(cast(@isauto_v2mpositiontaking_8 as varchar(50)),space(1)) + ',
isa_v2mpt_9='+ coalesce(cast(@isauto_v2mpositiontaking_9 as varchar(50)),space(1)) + ',
isa_v2mpt_20='+ coalesce(cast(@isauto_v2mpositiontaking_20 as varchar(50)),space(1)) + ',

isa_v3mpt_1='+ coalesce(cast(@isauto_v3mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_v3mpt_2='+ coalesce(cast(@isauto_v3mpositiontaking_2 as varchar(50)),space(1)) + ',
isa_v3mpt_3='+ coalesce(cast(@isauto_v3mpositiontaking_3 as varchar(50)),space(1)) + ',
isa_v3mpt_20='+ coalesce(cast(@isauto_v3mpositiontaking_20 as varchar(50)),space(1)) + ',

isa_v5mpt_1='+ coalesce(cast(@isauto_v5mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_v5mpt_2='+ coalesce(cast(@isauto_v5mpositiontaking_2 as varchar(50)),space(1)) + ',
isa_v5mpt_3='+ coalesce(cast(@isauto_v5mpositiontaking_3 as varchar(50)),space(1)) + ',
isa_v5mpt_20='+ coalesce(cast(@isauto_v5mpositiontaking_20 as varchar(50)),space(1)) + ',

isa_v8mpt_1='+ coalesce(cast(@isauto_v8mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_v8mpt_3='+ coalesce(cast(@isauto_v8mpositiontaking_3 as varchar(50)),space(1)) + ',
isa_v8mpt_20='+ coalesce(cast(@isauto_v8mpositiontaking_20 as varchar(50)),space(1)) + ',

isa_v10mpt_1='+ coalesce(cast(@isauto_v10mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_v10mpt_2='+ coalesce(cast(@isauto_v10mpositiontaking_2 as varchar(50)),space(1)) + ',
isa_v10mpt_3='+ coalesce(cast(@isauto_v10mpositiontaking_3 as varchar(50)),space(1)) + ',
isa_v10mpt_20='+ coalesce(cast(@isauto_v10mpositiontaking_20 as varchar(50)),space(1)) + ',

isa_v11mpt_1='+ coalesce(cast(@isauto_v11mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_v11mpt_20='+ coalesce(cast(@isauto_v11mpositiontaking_20 as varchar(50)),space(1)) + ',

isa_v201mpt_3='+ coalesce(cast(@isauto_v201mpositiontaking_3 as varchar(50)),space(1)) + ',

isa_v99mpt_1='+ coalesce(cast(@isauto_v99mpositiontaking_1 as varchar(50)),space(1)) + ',
isa_v99mpt_2='+ coalesce(cast(@isauto_v99mpositiontaking_2 as varchar(50)),space(1)) + ',
isa_v99mpt_3='+ coalesce(cast(@isauto_v99mpositiontaking_3 as varchar(50)),space(1)) + ',
isa_v99mpt_20='+ coalesce(cast(@isauto_v99mpositiontaking_20 as varchar(50)),space(1)) + char(7)+'</iam>'


--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
	@UserID = @UserID,
	@CustID = @CustID,
	@SpName = 'Acc_CustomerUpdMember_Master_xtest',
	@Doing = @LogSPData


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Master_xtest] TO [bodbadminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Master_xtest] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMember_Master_xtest] TO [vnteam]