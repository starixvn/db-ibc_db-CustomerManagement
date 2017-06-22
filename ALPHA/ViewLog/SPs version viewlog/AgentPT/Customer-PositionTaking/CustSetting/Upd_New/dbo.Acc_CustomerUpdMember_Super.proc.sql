ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_Super] 
	@CustID int,--memberid
	@Closed bit,
	@disCasino bit = 0,
	@UpdateClosed bit = 0,
	@Suspended bit = null,
	@updatesuspended bit = 0,
	@DisabledFI bit = 0,
	@spositiontaking_1 smallmoney OUTPUT,
	@spositiontaking_2 smallmoney OUTPUT,
	@spositiontaking_3 smallmoney OUTPUT,
	@spositiontaking_4 smallmoney OUTPUT,
	@spositiontaking_5 smallmoney OUTPUT,
	@spositiontaking_6 smallmoney OUTPUT,
	@spositiontaking_7 smallmoney OUTPUT,
	@spositiontaking_8 smallmoney OUTPUT,
	@spositiontaking_9 smallmoney OUTPUT,
	@spositiontaking_10 smallmoney OUTPUT,
	
	@slivepositiontaking_1 smallmoney OUTPUT,
	@slivepositiontaking_3 smallmoney OUTPUT,
	@slivepositiontaking_7 smallmoney OUTPUT,
	@slivepositiontaking_8 smallmoney OUTPUT,
	
	@v2spositiontaking_1 smallmoney OUTPUT,
	@v2spositiontaking_2 smallmoney OUTPUT,
	@v2spositiontaking_3 smallmoney OUTPUT,
	@v2spositiontaking_7 smallmoney OUTPUT,
	@v2spositiontaking_8 smallmoney OUTPUT,
	@v2spositiontaking_9 smallmoney OUTPUT,
	@v2spositiontaking_20 smallmoney OUTPUT,

	@v3spositiontaking_1 smallmoney OUTPUT,
	@v3spositiontaking_2 smallmoney OUTPUT,
	@v3spositiontaking_3 smallmoney OUTPUT,
	@v3spositiontaking_20 smallmoney OUTPUT,

	@v5spositiontaking_1 smallmoney OUTPUT,
	@v5spositiontaking_2 smallmoney OUTPUT,
	@v5spositiontaking_3 smallmoney OUTPUT,
	@v5spositiontaking_20 smallmoney OUTPUT,

	@v8spositiontaking_1 smallmoney OUTPUT,
	@v8spositiontaking_3 smallmoney OUTPUT,
	@v8spositiontaking_20 smallmoney OUTPUT,

	@v10spositiontaking_1 smallmoney OUTPUT,
	@v10spositiontaking_2 smallmoney OUTPUT,
	@v10spositiontaking_3 smallmoney OUTPUT,
	@v10spositiontaking_20 smallmoney OUTPUT,

	@v11spositiontaking_1 smallmoney OUTPUT,
	@v11spositiontaking_20 smallmoney OUTPUT,

	--v151
	--@v151spositiontaking_31 smallmoney OUTPUT,
	--@v151spositiontaking_32 smallmoney OUTPUT,

	@v99spositiontaking_1 smallmoney OUTPUT,
	@v99spositiontaking_2 smallmoney OUTPUT,
	@v99spositiontaking_3 smallmoney OUTPUT,
	@v99spositiontaking_20 smallmoney OUTPUT,
	
	@UserID int,
	
	@auto_spositiontaking_1 smallmoney = 0,
	@auto_spositiontaking_2 smallmoney = 0,
	@auto_spositiontaking_3 smallmoney = 0,
	@auto_spositiontaking_4 smallmoney = 0,
	@auto_spositiontaking_5 smallmoney= 0,
	@auto_spositiontaking_6 smallmoney = 0,
	@auto_spositiontaking_7 smallmoney = 0,
	@auto_spositiontaking_8 smallmoney = 0,
	@auto_spositiontaking_9 smallmoney = 0,
	@auto_spositiontaking_10 smallmoney = 0,
	
	@auto_slivepositiontaking_1 smallmoney = 0,
	@auto_slivepositiontaking_3 smallmoney = 0,
	@auto_slivepositiontaking_7 smallmoney = 0,
	@auto_slivepositiontaking_8 smallmoney = 0,
	
	@auto_v2spositiontaking_1 smallmoney = 0,
	@auto_v2spositiontaking_2 smallmoney = 0,
	@auto_v2spositiontaking_3 smallmoney = 0,
	@auto_v2spositiontaking_7 smallmoney = 0,
	@auto_v2spositiontaking_8 smallmoney = 0,
	@auto_v2spositiontaking_9 smallmoney = 0,
	@auto_v2spositiontaking_20 smallmoney = 0,

	@auto_v3spositiontaking_1 smallmoney = 0,
	@auto_v3spositiontaking_2 smallmoney = 0,
	@auto_v3spositiontaking_3 smallmoney = 0,
	@auto_v3spositiontaking_20 smallmoney = 0,

	@auto_v5spositiontaking_1 smallmoney = 0,
	@auto_v5spositiontaking_2 smallmoney = 0,
	@auto_v5spositiontaking_3 smallmoney = 0,
	@auto_v5spositiontaking_20 smallmoney = 0,

	@auto_v8spositiontaking_1 smallmoney = 0,
	@auto_v8spositiontaking_3 smallmoney = 0,
	@auto_v8spositiontaking_20 smallmoney = 0,

	@auto_v10spositiontaking_1 smallmoney = 0,
	@auto_v10spositiontaking_2 smallmoney = 0,
	@auto_v10spositiontaking_3 smallmoney = 0,
	@auto_v10spositiontaking_20 smallmoney = 0,

	@auto_v11spositiontaking_1 smallmoney = 0,
	@auto_v11spositiontaking_20 smallmoney = 0,

	@auto_v99spositiontaking_1 smallmoney = 0,
	@auto_v99spositiontaking_2 smallmoney = 0,
	@auto_v99spositiontaking_3 smallmoney = 0,
	@auto_v99spositiontaking_20 smallmoney = 0,
	--i1
	@isauto_spositiontaking_1 bit = 0,
	@isauto_spositiontaking_2 bit = 0,
	@isauto_spositiontaking_3 bit = 0,
	@isauto_spositiontaking_4 bit = 0,
	@isauto_spositiontaking_5 bit= 0,
	@isauto_spositiontaking_6 bit = 0,
	@isauto_spositiontaking_7 bit = 0,
	@isauto_spositiontaking_8 bit = 0,
	@isauto_spositiontaking_9 bit = 0,
	@isauto_spositiontaking_10 bit = 0,
	
	@isauto_slivepositiontaking_1 bit = 0,
	@isauto_slivepositiontaking_3 bit = 0,
	@isauto_slivepositiontaking_7 bit = 0,
	@isauto_slivepositiontaking_8 bit = 0,
	
	@isauto_v2spositiontaking_1 bit = 0,
	@isauto_v2spositiontaking_2 bit = 0,
	@isauto_v2spositiontaking_3 bit = 0,
	@isauto_v2spositiontaking_7 bit = 0,
	@isauto_v2spositiontaking_8 bit = 0,
	@isauto_v2spositiontaking_9 bit = 0,
	@isauto_v2spositiontaking_20 bit = 0,

	@isauto_v3spositiontaking_1 bit = 0,
	@isauto_v3spositiontaking_2 bit = 0,
	@isauto_v3spositiontaking_3 bit = 0,
	@isauto_v3spositiontaking_20 bit = 0,

	@isauto_v5spositiontaking_1 bit = 0,
	@isauto_v5spositiontaking_2 bit = 0,
	@isauto_v5spositiontaking_3 bit = 0,
	@isauto_v5spositiontaking_20 bit = 0,

	@isauto_v8spositiontaking_1 bit = 0,
	@isauto_v8spositiontaking_3 bit = 0,
	@isauto_v8spositiontaking_20 bit = 0,

	@isauto_v10spositiontaking_1 bit = 0,
	@isauto_v10spositiontaking_2 bit = 0,
	@isauto_v10spositiontaking_3 bit = 0,
	@isauto_v10spositiontaking_20 bit = 0,

	@isauto_v11spositiontaking_1 bit = 0,
	@isauto_v11spositiontaking_20 bit = 0,

	@isauto_v99spositiontaking_1 bit = 0,
	@isauto_v99spositiontaking_2 bit = 0,
	@isauto_v99spositiontaking_3 bit = 0,
	@isauto_v99spositiontaking_20 bit = 0,
	
	--i3
	@isauto_smpositiontaking_1 bit = 0,
	@isauto_smpositiontaking_2 bit = 0,
	@isauto_smpositiontaking_3 bit = 0,
	@isauto_smpositiontaking_4 bit = 0,
	@isauto_smpositiontaking_5 bit= 0,
	@isauto_smpositiontaking_6 bit = 0,
	@isauto_smpositiontaking_7 bit = 0,
	@isauto_smpositiontaking_8 bit = 0,
	@isauto_smpositiontaking_9 bit = 0,
	@isauto_smpositiontaking_10 bit = 0,
	
	@isauto_smlivepositiontaking_1 bit = 0,
	@isauto_smlivepositiontaking_3 bit = 0,
	@isauto_smlivepositiontaking_7 bit = 0,
	@isauto_smlivepositiontaking_8 bit = 0,
	
	@isauto_v2smpositiontaking_1 bit = 0,
	@isauto_v2smpositiontaking_2 bit = 0,
	@isauto_v2smpositiontaking_3 bit = 0,
	@isauto_v2smpositiontaking_7 bit = 0,
	@isauto_v2smpositiontaking_8 bit = 0,
	@isauto_v2smpositiontaking_9 bit = 0,
	@isauto_v2smpositiontaking_20 bit = 0,

	@isauto_v3smpositiontaking_1 bit = 0,
	@isauto_v3smpositiontaking_2 bit = 0,
	@isauto_v3smpositiontaking_3 bit = 0,
	@isauto_v3smpositiontaking_20 bit = 0,

	@isauto_v5smpositiontaking_1 bit = 0,
	@isauto_v5smpositiontaking_2 bit = 0,
	@isauto_v5smpositiontaking_3 bit = 0,
	@isauto_v5smpositiontaking_20 bit = 0,

	@isauto_v8smpositiontaking_1 bit = 0,
	@isauto_v8smpositiontaking_3 bit = 0,
	@isauto_v8smpositiontaking_20 bit = 0,

	@isauto_v10smpositiontaking_1 bit = 0,
	@isauto_v10smpositiontaking_2 bit = 0,
	@isauto_v10smpositiontaking_3 bit = 0,
	@isauto_v10smpositiontaking_20 bit = 0,

	@isauto_v11smpositiontaking_1 bit = 0,
	@isauto_v11smpositiontaking_20 bit = 0,

	@isauto_v99smpositiontaking_1 bit = 0,
	@isauto_v99smpositiontaking_2 bit = 0,
	@isauto_v99smpositiontaking_3 bit = 0,
	@isauto_v99smpositiontaking_20 bit = 0,
		
	@language varchar(2) = 'E',
	@SubAccID int = 0, --Sub-AccountID
	@IP varchar(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080515@Thien
Task : Super edits Member
DB: DB02.bodb02
Original: Acc_CustomerUpdSuper_Member

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3, hard code copy min/max/maxperbet/PT for 201 from 2 sporttype 
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090314@HanhVu: add Korean language
	- 20090403@Phuc: Add new tag on write log session <isau> for i3
					 Check to update old value (disable FI cases) for update multiple member.
    - 20090424@Phuc:Separate finance sporttype(201).
					Write log subaccname instead of subaccid.		
    - 20090717@Phuc: Enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	- 20090801@Shifu: check disabled user
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091127@Jamie: Remove input @UpdateMultiple and write log @updatesuspended
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON
/*
if not exists (select 1 from custinfo with (nolock) where custid = @custid and srecommend in (181940,197461))
BEGIN
	declare @ErrMsg varchar(200)
	Select @ErrMsg = 'Sorry, please try again later.'
	RaisError (@ErrMsg, 16, 1)
	return
END
*/
Declare @ErrCode_cur int, @ErrMsg_cur nvarchar(4000), @mrecommend int, @recommend int,	@srecommend int

select @DisabledFI = isnull(@DisabledFI,0), @ErrCode_cur = 0, @ErrMsg_cur = '', @ErrCode = '', @ErrMsg = ''

select @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @username = username from custinfo with (NOLOCK) where custid = @custid

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode_Cur output,@ErrMsg=@ErrMsg_Cur output
IF @ErrCode_Cur > 0
BEGIN
	select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
--end
 
declare 
	@mpositiontaking_1 smallmoney,
	@mpositiontaking_2 smallmoney,
	@mpositiontaking_3 smallmoney,
	@mpositiontaking_4 smallmoney,
	@mpositiontaking_5 smallmoney,
	@mpositiontaking_6 smallmoney,
	@mpositiontaking_7 smallmoney,
	@mpositiontaking_8 smallmoney,
	@mpositiontaking_9 smallmoney,
	@mpositiontaking_10 smallmoney,
	@mlivepositiontaking_1 smallmoney,
	@mlivepositiontaking_3 smallmoney,
	@mlivepositiontaking_7 smallmoney,
	@mlivepositiontaking_8 smallmoney,
	
	@v2mpositiontaking_1 smallmoney,
	@v2mpositiontaking_2 smallmoney,
	@v2mpositiontaking_3 smallmoney,
	@v2mpositiontaking_7 smallmoney,
	@v2mpositiontaking_8 smallmoney,
	@v2mpositiontaking_9 smallmoney,
	@v2mpositiontaking_20 smallmoney,
	
	@v3mpositiontaking_1 smallmoney,
	@v3mpositiontaking_2 smallmoney,
	@v3mpositiontaking_3 smallmoney,
	@v3mpositiontaking_20 smallmoney,

	@v5mpositiontaking_1 smallmoney,
	@v5mpositiontaking_2 smallmoney,
	@v5mpositiontaking_3 smallmoney,
	@v5mpositiontaking_20 smallmoney,

	@v8mpositiontaking_1 smallmoney,
	@v8mpositiontaking_3 smallmoney,
	@v8mpositiontaking_20 smallmoney,

	@v10mpositiontaking_1 smallmoney,
	@v10mpositiontaking_2 smallmoney,
	@v10mpositiontaking_3 smallmoney,
	@v10mpositiontaking_20 smallmoney,

	@v11mpositiontaking_1 smallmoney,
	@v11mpositiontaking_20 smallmoney,

	@v99mpositiontaking_1 smallmoney,
	@v99mpositiontaking_2 smallmoney,
	@v99mpositiontaking_3 smallmoney,
	@v99mpositiontaking_20 smallmoney,
	
	@old_spositiontaking_1 smallmoney,
	@old_spositiontaking_2 smallmoney,
	@old_spositiontaking_3 smallmoney,
	@old_spositiontaking_4 smallmoney,
	@old_spositiontaking_5 smallmoney,
	@old_spositiontaking_6 smallmoney,
	@old_spositiontaking_7 smallmoney,
	@old_spositiontaking_8 smallmoney,
	@old_spositiontaking_9 smallmoney,
	@old_spositiontaking_10 smallmoney,
	
	@old_slivepositiontaking_1 smallmoney,
	@old_slivepositiontaking_3 smallmoney,
	@old_slivepositiontaking_7 smallmoney,
	@old_slivepositiontaking_8 smallmoney,
	
	@old_v2spositiontaking_1 smallmoney,
	@old_v2spositiontaking_2 smallmoney,
	@old_v2spositiontaking_3 smallmoney,
	@old_v2spositiontaking_7 smallmoney,
	@old_v2spositiontaking_8 smallmoney,
	@old_v2spositiontaking_9 smallmoney,
	@old_v2spositiontaking_20 smallmoney,
	
	@old_v3spositiontaking_1 smallmoney,
	@old_v3spositiontaking_2 smallmoney,
	@old_v3spositiontaking_3 smallmoney,
	@old_v3spositiontaking_20 smallmoney,

	@old_v5spositiontaking_1 smallmoney,
	@old_v5spositiontaking_2 smallmoney,
	@old_v5spositiontaking_3 smallmoney,
	@old_v5spositiontaking_20 smallmoney,

	@old_v8spositiontaking_1 smallmoney,
	@old_v8spositiontaking_3 smallmoney,
	@old_v8spositiontaking_20 smallmoney,

	@old_v10spositiontaking_1 smallmoney,
	@old_v10spositiontaking_2 smallmoney,
	@old_v10spositiontaking_3 smallmoney,
	@old_v10spositiontaking_20 smallmoney,

	@old_v11spositiontaking_1 smallmoney,
	@old_v11spositiontaking_20 smallmoney,

	@old_v99spositiontaking_1 smallmoney,
	@old_v99spositiontaking_2 smallmoney,
	@old_v99spositiontaking_3 smallmoney,
	@old_v99spositiontaking_20 smallmoney,

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

	@v99apositiontaking_1 smallmoney,
	@v99apositiontaking_2 smallmoney,
	@v99apositiontaking_3 smallmoney,
	@v99apositiontaking_20 smallmoney,
	
	@spositiontaking_1_max smallmoney,
	@spositiontaking_2_max smallmoney,
	@spositiontaking_3_max smallmoney,
	@spositiontaking_4_max smallmoney,
	@spositiontaking_5_max smallmoney,
	@spositiontaking_6_max smallmoney,
	@spositiontaking_7_max smallmoney,
	@spositiontaking_8_max smallmoney,
	@spositiontaking_9_max smallmoney,
	@spositiontaking_10_max smallmoney,
	
	@slivepositiontaking_1_max smallmoney,
	@slivepositiontaking_3_max smallmoney,
	@slivepositiontaking_7_max smallmoney,
	@slivepositiontaking_8_max smallmoney,
	
	@v2spositiontaking_1_max smallmoney,
	@v2spositiontaking_2_max smallmoney,
	@v2spositiontaking_3_max smallmoney,
	@v2spositiontaking_7_max smallmoney,
	@v2spositiontaking_8_max smallmoney,
	@v2spositiontaking_9_max smallmoney,
	@v2spositiontaking_20_max smallmoney,
	
	@v3spositiontaking_1_max smallmoney,
	@v3spositiontaking_2_max smallmoney,
	@v3spositiontaking_3_max smallmoney,
	@v3spositiontaking_20_max smallmoney,

	@v5spositiontaking_1_max smallmoney,
	@v5spositiontaking_2_max smallmoney,
	@v5spositiontaking_3_max smallmoney,
	@v5spositiontaking_20_max smallmoney,

	@v8spositiontaking_1_max smallmoney,
	@v8spositiontaking_3_max smallmoney,
	@v8spositiontaking_20_max smallmoney,

	@v10spositiontaking_1_max smallmoney,
	@v10spositiontaking_2_max smallmoney,
	@v10spositiontaking_3_max smallmoney,
	@v10spositiontaking_20_max smallmoney,

	@v11spositiontaking_1_max smallmoney,
	@v11spositiontaking_20_max smallmoney,

	@v99spositiontaking_1_max smallmoney,
	@v99spositiontaking_2_max smallmoney,
	@v99spositiontaking_3_max smallmoney,
	@v99spositiontaking_20_max smallmoney,
	
	--Old u1,i1
	@old_auto_spositiontaking_1 smallmoney ,
	@old_auto_spositiontaking_2 smallmoney ,
	@old_auto_spositiontaking_3 smallmoney ,
	@old_auto_spositiontaking_4 smallmoney ,
	@old_auto_spositiontaking_5 smallmoney,
	@old_auto_spositiontaking_6 smallmoney ,
	@old_auto_spositiontaking_7 smallmoney ,
	@old_auto_spositiontaking_8 smallmoney ,
	@old_auto_spositiontaking_9 smallmoney ,
	@old_auto_spositiontaking_10 smallmoney ,
	
	@old_auto_slivepositiontaking_1 smallmoney ,
	@old_auto_slivepositiontaking_3 smallmoney ,
	@old_auto_slivepositiontaking_7 smallmoney ,
	@old_auto_slivepositiontaking_8 smallmoney ,
	
	@old_auto_v2spositiontaking_1 smallmoney ,
	@old_auto_v2spositiontaking_2 smallmoney ,
	@old_auto_v2spositiontaking_3 smallmoney ,
	@old_auto_v2spositiontaking_7 smallmoney ,
	@old_auto_v2spositiontaking_8 smallmoney ,
	@old_auto_v2spositiontaking_9 smallmoney ,
	@old_auto_v2spositiontaking_20 smallmoney ,

	@old_auto_v3spositiontaking_1 smallmoney ,
	@old_auto_v3spositiontaking_2 smallmoney ,
	@old_auto_v3spositiontaking_3 smallmoney ,
	@old_auto_v3spositiontaking_20 smallmoney ,

	@old_auto_v5spositiontaking_1 smallmoney ,
	@old_auto_v5spositiontaking_2 smallmoney ,
	@old_auto_v5spositiontaking_3 smallmoney ,
	@old_auto_v5spositiontaking_20 smallmoney ,

	@old_auto_v8spositiontaking_1 smallmoney ,
	@old_auto_v8spositiontaking_3 smallmoney ,
	@old_auto_v8spositiontaking_20 smallmoney ,

	@old_auto_v10spositiontaking_1 smallmoney ,
	@old_auto_v10spositiontaking_2 smallmoney ,
	@old_auto_v10spositiontaking_3 smallmoney ,
	@old_auto_v10spositiontaking_20 smallmoney ,

	@old_auto_v11spositiontaking_1 smallmoney ,
	@old_auto_v11spositiontaking_20 smallmoney ,

	@old_auto_v99spositiontaking_1 smallmoney ,
	@old_auto_v99spositiontaking_2 smallmoney ,
	@old_auto_v99spositiontaking_3 smallmoney ,
	@old_auto_v99spositiontaking_20 smallmoney ,
	
	@old_isauto_spositiontaking_1 bit ,
	@old_isauto_spositiontaking_2 bit ,
	@old_isauto_spositiontaking_3 bit ,
	@old_isauto_spositiontaking_4 bit ,
	@old_isauto_spositiontaking_5 bit,
	@old_isauto_spositiontaking_6 bit ,
	@old_isauto_spositiontaking_7 bit ,
	@old_isauto_spositiontaking_8 bit ,
	@old_isauto_spositiontaking_9 bit ,
	@old_isauto_spositiontaking_10 bit ,
	
	@old_isauto_slivepositiontaking_1 bit ,
	@old_isauto_slivepositiontaking_3 bit ,
	@old_isauto_slivepositiontaking_7 bit ,
	@old_isauto_slivepositiontaking_8 bit ,
	
	@old_isauto_v2spositiontaking_1 bit ,
	@old_isauto_v2spositiontaking_2 bit ,
	@old_isauto_v2spositiontaking_3 bit ,
	@old_isauto_v2spositiontaking_7 bit ,
	@old_isauto_v2spositiontaking_8 bit ,
	@old_isauto_v2spositiontaking_9 bit ,
	@old_isauto_v2spositiontaking_20 bit ,

	@old_isauto_v3spositiontaking_1 bit ,
	@old_isauto_v3spositiontaking_2 bit ,
	@old_isauto_v3spositiontaking_3 bit ,
	@old_isauto_v3spositiontaking_20 bit ,

	@old_isauto_v5spositiontaking_1 bit ,
	@old_isauto_v5spositiontaking_2 bit ,
	@old_isauto_v5spositiontaking_3 bit ,
	@old_isauto_v5spositiontaking_20 bit ,

	@old_isauto_v8spositiontaking_1 bit ,
	@old_isauto_v8spositiontaking_3 bit ,
	@old_isauto_v8spositiontaking_20 bit ,

	@old_isauto_v10spositiontaking_1 bit ,
	@old_isauto_v10spositiontaking_2 bit ,
	@old_isauto_v10spositiontaking_3 bit ,
	@old_isauto_v10spositiontaking_20 bit ,

	@old_isauto_v11spositiontaking_1 bit ,
	@old_isauto_v11spositiontaking_20 bit ,

	@old_isauto_v99spositiontaking_1 bit ,
	@old_isauto_v99spositiontaking_2 bit ,
	@old_isauto_v99spositiontaking_3 bit ,
	@old_isauto_v99spositiontaking_20 bit
	
	
declare @ErrType varchar(1000) 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check param
declare @IsValid bit
Select @isvalid = 1
if 
	@spositiontaking_1  <0
	or @spositiontaking_2  <0
	or @spositiontaking_3  <0
	or @spositiontaking_4  <0
	or @spositiontaking_5  <0
	or @spositiontaking_6  <0
	or @spositiontaking_7  <0
	or @spositiontaking_8  <0
	or @spositiontaking_9  <0
	or @spositiontaking_10 <0
	or @slivepositiontaking_1  <0
	or @slivepositiontaking_3  <0
	or @slivepositiontaking_7  <0
	or @slivepositiontaking_8  <0
	or @spositiontaking_1  >0.9
	or @spositiontaking_2  >0.9
	or @spositiontaking_3  >0.9
	or @spositiontaking_4  >0.9
	or @spositiontaking_5  >0.9
	or @spositiontaking_6  >0.9
	or @spositiontaking_7  >0.9
	or @spositiontaking_8  >0.9
	or @spositiontaking_9  >0.9
	or @spositiontaking_10 >0.9
	or @slivepositiontaking_1  >0.9
	or @slivepositiontaking_3  >0.9
	or @slivepositiontaking_7  >0.9
	or @slivepositiontaking_8  >0.9
	
	or @v2spositiontaking_1 <0
	or @v2spositiontaking_2 <0
	or @v2spositiontaking_3 <0
	or @v2spositiontaking_7 <0
	or @v2spositiontaking_8 <0
	or @v2spositiontaking_9 <0
	or @v2spositiontaking_20 <0

	or @v3spositiontaking_1 <0
	or @v3spositiontaking_2 <0
	or @v3spositiontaking_3 <0
	or @v3spositiontaking_20 <0

	or @v5spositiontaking_1 <0
	or @v5spositiontaking_2 <0
	or @v5spositiontaking_3 <0
	or @v5spositiontaking_20 <0

	or @v8spositiontaking_1 <0
	or @v8spositiontaking_3 <0
	or @v8spositiontaking_20 <0

	or @v10spositiontaking_1 <0
	or @v10spositiontaking_2 <0
	or @v10spositiontaking_3 <0
	or @v10spositiontaking_20 <0

	or @v11spositiontaking_1 <0
	or @v11spositiontaking_20 <0

	or @v99spositiontaking_1 <0
	or @v99spositiontaking_2 <0
	or @v99spositiontaking_3 <0
	or @v99spositiontaking_20 <0
	
	or @v2spositiontaking_1 >0.9
	or @v2spositiontaking_2 >0.9
	or @v2spositiontaking_3 >0.9
	or @v2spositiontaking_7 >0.9
	or @v2spositiontaking_8 >0.9
	or @v2spositiontaking_9 >0.9
	or @v2spositiontaking_20 >0.9

	or @v3spositiontaking_1 >0.9
	or @v3spositiontaking_2 >0.9
	or @v3spositiontaking_3 >0.9
	or @v3spositiontaking_20 >0.9

	or @v5spositiontaking_1 >0.9
	or @v5spositiontaking_2 >0.9
	or @v5spositiontaking_3 >0.9
	or @v5spositiontaking_20 >0.9

	or @v8spositiontaking_1 >0.9
	or @v8spositiontaking_3 >0.9
	or @v8spositiontaking_20 >0.9

	or @v10spositiontaking_1 >0.9
	or @v10spositiontaking_2 >0.9
	or @v10spositiontaking_3 >0.9
	or @v10spositiontaking_20 >0.9

	or @v11spositiontaking_1 >0.9
	or @v11spositiontaking_20 >0.9

	or @v99spositiontaking_1 >0.9
	or @v99spositiontaking_2 >0.9
	or @v99spositiontaking_3 >0.9
	or @v99spositiontaking_20 >0.9
BEGIN
	select @isvalid = 0, @ErrCode_cur = 1
	Select @ErrMsg_cur = case @Language 
							when 'E' then 'Wrong position taking.'
							when 'CS' then N'占成数不正确.'
							when 'CT' then N'佔成數不正確.'
							when 'TH' then N'การกำหนดไม่ถูกต้อง.'
							when 'J' then N'Wrong position taking.'
							when 'KO' then N'거래 조건이 잘못 되었습니다.'
							else N'Wrong position taking.'
						 end
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)			
	return
END

-- Update customer info first

	SELECT @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	IF @disCasino = 1 AND EXISTS(SELECT 1 FROM Custinfo WITH (NOLOCK) WHERE syncCasino = 1 AND custID = @CustID)
	BEGIN
		IF @UpdateClosed = 1
		BEGIN
			Select @ErrMsg_Cur = case @Language 
								when 'E' then 'This CLOSED function is temporarily unavailable, please update later.'
								when 'CS' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'CT' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'TH' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'J' then N'This CLOSED function is temporarily unavailable, please update later.'
								when 'KO' then N'This CLOSED function is temporarily unavailable, please update later.'
								else N'This CLOSED function is temporarily unavailable, please update later.'
							end	,
				@ErrCode_Cur = 902
				SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		END
		SELECT @ErrCode_Cur = 0, @ErrMsg_Cur = ''
		IF @updatesuspended = 1
		BEGIN
			Select @ErrMsg_Cur = case @Language 
								when 'E' then 'This SUSPENDED function is temporarily unavailable, please update later.'
								when 'CS' then N'This SUSPENDED function is temporarily unavailable, please update later.'
								when 'CT' then N'This SUSPENDED function is temporarily unavailable, please update later.'
								when 'TH' then N'This SUSPENDED function is temporarily unavailable, please update later.'
								when 'J' then N'This SUSPENDED function is temporarily unavailable, please update later.'
								when 'KO' then N'This SUSPENDED function is temporarily unavailable, please update later.'
								else N'This SUSPENDED function is temporarily unavailable, please update later.'
							end	,
				@ErrCode_Cur = 903
				SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		END
		SELECT @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	END
	ELSE
		BEGIN
			UPDATE custinfo with (ROWLOCK, UPDLOCK) SET 
				closed= case when @closed is null or @UpdateClosed = 0 then closed else @closed end,
				reject = case  when @suspended is null or @updatesuspended = 0 then reject else @suspended end
			WHERE custid=@CustID
			
			Select @ErrCode = @ErrCode + '-102'+char(7), @ErrMsg = @ErrMsg + char(7)
		END

--Log customer info
Declare @LogSPData varchar(4000)

Select @LogSPData = '<Acc_CustomerUpdMember_Super custid="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" ' +
'Closed="'+ coalesce(cast(@Closed as varchar(50)),space(1)) + '" ' +
'ClosedMultiple="'+ coalesce(cast(@UpdateClosed as varchar(2)),space(1)) + '" ' +
'Suspended="'+ coalesce(cast(@Suspended as varchar(2)),space(1)) + '" ' +
'SuspendedMultiple="'+ coalesce(cast(@updatesuspended as varchar(2)),space(1)) + '" ' +
'DisabledFI="'+ coalesce(cast(@DisabledFI as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'language="'+ coalesce(cast(@language as varchar(2)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1116,
	@TrackingValue = @LogSPData

--Check Old_PT <> New_PT
select @apositiontaking_1 = apositiontaking, @alivepositiontaking_1 = alivepositiontaking, @mpositiontaking_1 = mpositiontaking, @mlivepositiontaking_1 = mlivepositiontaking, @old_spositiontaking_1 = spositiontaking, @old_slivepositiontaking_1 = slivepositiontaking, @old_auto_spositiontaking_1 = autopositiontaking, @old_auto_slivepositiontaking_1 = autolivepositiontaking, @old_isauto_spositiontaking_1 = isautopositiontaking, @old_isauto_slivepositiontaking_1 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=1
select @apositiontaking_3 = apositiontaking, @alivepositiontaking_3 = alivepositiontaking,@mpositiontaking_3 = mpositiontaking, @mlivepositiontaking_3 = mlivepositiontaking, @old_spositiontaking_3 = spositiontaking, @old_slivepositiontaking_3 = slivepositiontaking, @old_auto_spositiontaking_3 = autopositiontaking, @old_auto_slivepositiontaking_3 = autolivepositiontaking, @old_isauto_spositiontaking_3 = isautopositiontaking, @old_isauto_slivepositiontaking_3 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=1
select @apositiontaking_7 = apositiontaking, @alivepositiontaking_7 = alivepositiontaking,@mpositiontaking_7 = mpositiontaking, @mlivepositiontaking_7 = mlivepositiontaking, @old_spositiontaking_7 = spositiontaking, @old_slivepositiontaking_7 = slivepositiontaking, @old_auto_spositiontaking_7 = autopositiontaking, @old_auto_slivepositiontaking_7 = autolivepositiontaking, @old_isauto_spositiontaking_7 = isautopositiontaking, @old_isauto_slivepositiontaking_7 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=1
select @apositiontaking_8 = apositiontaking, @alivepositiontaking_8 = alivepositiontaking,@mpositiontaking_8 = mpositiontaking, @mlivepositiontaking_8 = mlivepositiontaking, @old_spositiontaking_8 = spositiontaking, @old_slivepositiontaking_8 = slivepositiontaking, @old_auto_spositiontaking_8 = autopositiontaking, @old_auto_slivepositiontaking_8 = autolivepositiontaking, @old_isauto_spositiontaking_8 = isautopositiontaking, @old_isauto_slivepositiontaking_8 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=1

select @apositiontaking_2 = apositiontaking, @mpositiontaking_2 = mpositiontaking, @old_spositiontaking_2 = spositiontaking, @old_auto_spositiontaking_2 = autopositiontaking, @old_isauto_spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=1
select @apositiontaking_4 = apositiontaking, @mpositiontaking_4 = mpositiontaking, @old_spositiontaking_4 = spositiontaking, @old_auto_spositiontaking_4 = autopositiontaking, @old_isauto_spositiontaking_4 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=4 and sporttype=1
select @apositiontaking_5 = apositiontaking, @mpositiontaking_5 = mpositiontaking, @old_spositiontaking_5 = spositiontaking, @old_auto_spositiontaking_5 = autopositiontaking, @old_isauto_spositiontaking_5 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=5 and sporttype=1
select @apositiontaking_6 = apositiontaking, @mpositiontaking_6 = mpositiontaking, @old_spositiontaking_6 = spositiontaking, @old_auto_spositiontaking_6 = autopositiontaking, @old_isauto_spositiontaking_6 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=6 and sporttype=1
select @apositiontaking_9 = apositiontaking, @mpositiontaking_9 = mpositiontaking, @old_spositiontaking_9 = spositiontaking, @old_auto_spositiontaking_9 = autopositiontaking, @old_isauto_spositiontaking_9 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=1
select @apositiontaking_10 = apositiontaking, @mpositiontaking_10 = mpositiontaking, @old_spositiontaking_10 = spositiontaking, @old_auto_spositiontaking_10 = autopositiontaking, @old_isauto_spositiontaking_10 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=10 and sporttype=1

select @v2apositiontaking_1 = apositiontaking, @v2mpositiontaking_1 = mpositiontaking, @old_v2spositiontaking_1 = spositiontaking, @old_auto_v2spositiontaking_1 = autopositiontaking, @old_isauto_v2spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=2
select @v2apositiontaking_2 = apositiontaking, @v2mpositiontaking_2 = mpositiontaking, @old_v2spositiontaking_2 = spositiontaking, @old_auto_v2spositiontaking_2 = autopositiontaking, @old_isauto_v2spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=2
select @v2apositiontaking_3 = apositiontaking, @v2mpositiontaking_3 = mpositiontaking, @old_v2spositiontaking_3 = spositiontaking, @old_auto_v2spositiontaking_3 = autopositiontaking, @old_isauto_v2spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=2
select @v2apositiontaking_7 = apositiontaking, @v2mpositiontaking_7 = mpositiontaking, @old_v2spositiontaking_7 = spositiontaking, @old_auto_v2spositiontaking_7 = autopositiontaking, @old_isauto_v2spositiontaking_7 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=2
select @v2apositiontaking_8 = apositiontaking, @v2mpositiontaking_8 = mpositiontaking, @old_v2spositiontaking_8 = spositiontaking, @old_auto_v2spositiontaking_8 = autopositiontaking, @old_isauto_v2spositiontaking_8 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=2
select @v2apositiontaking_9 = apositiontaking, @v2mpositiontaking_9 = mpositiontaking, @old_v2spositiontaking_9 = spositiontaking, @old_auto_v2spositiontaking_9 = autopositiontaking, @old_isauto_v2spositiontaking_9 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=2
select @v2apositiontaking_20 = apositiontaking, @v2mpositiontaking_20 = mpositiontaking, @old_v2spositiontaking_20 = spositiontaking, @old_auto_v2spositiontaking_20 = autopositiontaking, @old_isauto_v2spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=2

select @v3apositiontaking_1 = apositiontaking, @v3mpositiontaking_1 = mpositiontaking, @old_v3spositiontaking_1 = spositiontaking, @old_auto_v3spositiontaking_1 = autopositiontaking, @old_isauto_v3spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=3
select @v3apositiontaking_2 = apositiontaking, @v3mpositiontaking_2 = mpositiontaking, @old_v3spositiontaking_2 = spositiontaking, @old_auto_v3spositiontaking_2 = autopositiontaking, @old_isauto_v3spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=3
select @v3apositiontaking_3 = apositiontaking, @v3mpositiontaking_3 = mpositiontaking, @old_v3spositiontaking_3 = spositiontaking, @old_auto_v3spositiontaking_3 = autopositiontaking, @old_isauto_v3spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=3
select @v3apositiontaking_20 = apositiontaking, @v3mpositiontaking_20 = mpositiontaking, @old_v3spositiontaking_20 = spositiontaking, @old_auto_v3spositiontaking_20 = autopositiontaking, @old_isauto_v3spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=3

select @v5apositiontaking_1 = apositiontaking, @v5mpositiontaking_1 = mpositiontaking, @old_v5spositiontaking_1 = spositiontaking, @old_auto_v5spositiontaking_1 = autopositiontaking, @old_isauto_v5spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=5
select @v5apositiontaking_2 = apositiontaking, @v5mpositiontaking_2 = mpositiontaking, @old_v5spositiontaking_2 = spositiontaking, @old_auto_v5spositiontaking_2 = autopositiontaking, @old_isauto_v5spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=5
select @v5apositiontaking_3 = apositiontaking, @v5mpositiontaking_3 = mpositiontaking, @old_v5spositiontaking_3 = spositiontaking, @old_auto_v5spositiontaking_3 = autopositiontaking, @old_isauto_v5spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=5
select @v5apositiontaking_20 = apositiontaking, @v5mpositiontaking_20 = mpositiontaking, @old_v5spositiontaking_20 = spositiontaking, @old_auto_v5spositiontaking_20 = autopositiontaking, @old_isauto_v5spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=5

select @v8apositiontaking_1 = apositiontaking, @v8mpositiontaking_1 = mpositiontaking, @old_v8spositiontaking_1 = spositiontaking, @old_auto_v8spositiontaking_1 = autopositiontaking, @old_isauto_v8spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=8
select @v8apositiontaking_3 = apositiontaking, @v8mpositiontaking_3 = mpositiontaking, @old_v8spositiontaking_3 = spositiontaking, @old_auto_v8spositiontaking_3 = autopositiontaking, @old_isauto_v8spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=8
select @v8apositiontaking_20 = apositiontaking, @v8mpositiontaking_20 = mpositiontaking, @old_v8spositiontaking_20 = spositiontaking, @old_auto_v8spositiontaking_20 = autopositiontaking, @old_isauto_v8spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=8

select @v10apositiontaking_1 = apositiontaking, @v10mpositiontaking_1 = mpositiontaking, @old_v10spositiontaking_1 = spositiontaking, @old_auto_v10spositiontaking_1 = autopositiontaking, @old_isauto_v10spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=10
select @v10apositiontaking_2 = apositiontaking, @v10mpositiontaking_2 = mpositiontaking, @old_v10spositiontaking_2 = spositiontaking, @old_auto_v10spositiontaking_2 = autopositiontaking, @old_isauto_v10spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=10
select @v10apositiontaking_3 = apositiontaking, @v10mpositiontaking_3 = mpositiontaking, @old_v10spositiontaking_3 = spositiontaking, @old_auto_v10spositiontaking_3 = autopositiontaking, @old_isauto_v10spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=10
select @v10apositiontaking_20 = apositiontaking, @v10mpositiontaking_20 = mpositiontaking, @old_v10spositiontaking_20 = spositiontaking, @old_auto_v10spositiontaking_20 = autopositiontaking, @old_isauto_v10spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=10

select @v11apositiontaking_1 = apositiontaking, @v11mpositiontaking_1 = mpositiontaking, @old_v11spositiontaking_1 = spositiontaking, @old_auto_v11spositiontaking_1 = autopositiontaking, @old_isauto_v11spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=11
select @v11apositiontaking_20 = apositiontaking, @v11mpositiontaking_20 = mpositiontaking, @old_v11spositiontaking_20 = spositiontaking, @old_auto_v11spositiontaking_20 = autopositiontaking, @old_isauto_v11spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=11

select @v99apositiontaking_1 = apositiontaking, @v99mpositiontaking_1 = mpositiontaking, @old_v99spositiontaking_1 = spositiontaking, @old_auto_v99spositiontaking_1 = autopositiontaking, @old_isauto_v99spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=99
select @v99apositiontaking_2 = apositiontaking, @v99mpositiontaking_2 = mpositiontaking, @old_v99spositiontaking_2 = spositiontaking, @old_auto_v99spositiontaking_2 = autopositiontaking, @old_isauto_v99spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=99
select @v99apositiontaking_3 = apositiontaking, @v99mpositiontaking_3 = mpositiontaking, @old_v99spositiontaking_3 = spositiontaking, @old_auto_v99spositiontaking_3 = autopositiontaking, @old_isauto_v99spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=99
select @v99apositiontaking_20 = apositiontaking, @v99mpositiontaking_20 = mpositiontaking, @old_v99spositiontaking_20 = spositiontaking, @old_auto_v99spositiontaking_20 = autopositiontaking, @old_isauto_v99spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=99


IF @spositiontaking_1 = @old_spositiontaking_1 AND
	@spositiontaking_2 = @old_spositiontaking_2 AND
	@spositiontaking_3 = @old_spositiontaking_3 AND
	@spositiontaking_4 = @old_spositiontaking_4 AND
	@spositiontaking_5 = @old_spositiontaking_5 AND
	@spositiontaking_6 = @old_spositiontaking_6 AND
	@spositiontaking_7 = @old_spositiontaking_7 AND
	@spositiontaking_8 = @old_spositiontaking_8 AND
	@spositiontaking_9 = @old_spositiontaking_9 AND
	@spositiontaking_10 = @old_spositiontaking_10 AND
	@slivepositiontaking_1 = @old_slivepositiontaking_1 AND
	@slivepositiontaking_3 = @old_slivepositiontaking_3 AND
	@slivepositiontaking_7 = @old_slivepositiontaking_7 AND
	@slivepositiontaking_8 = @old_slivepositiontaking_8 AND

	@v2spositiontaking_1 = @old_v2spositiontaking_1 AND
	@v2spositiontaking_2 = @old_v2spositiontaking_2 AND
	@v2spositiontaking_3 = @old_v2spositiontaking_3 AND
	@v2spositiontaking_7 = @old_v2spositiontaking_7 AND
	@v2spositiontaking_8 = @old_v2spositiontaking_8 AND
	@v2spositiontaking_9 = @old_v2spositiontaking_9 AND
	@v2spositiontaking_20 = @old_v2spositiontaking_20 AND
	
	@v3spositiontaking_1 = @old_v3spositiontaking_1 AND
	@v3spositiontaking_2 = @old_v3spositiontaking_2 AND
	@v3spositiontaking_3 = @old_v3spositiontaking_3 AND
	@v3spositiontaking_20 = @old_v3spositiontaking_20 AND
	
	@v5spositiontaking_1 = @old_v5spositiontaking_1 AND
	@v5spositiontaking_2 = @old_v5spositiontaking_2 AND
	@v5spositiontaking_3 = @old_v5spositiontaking_3 AND
	@v5spositiontaking_20 = @old_v5spositiontaking_20 AND
	
	@v8spositiontaking_1 = @old_v8spositiontaking_1 AND
	@v8spositiontaking_3 = @old_v8spositiontaking_3 AND
	@v8spositiontaking_20 = @old_v8spositiontaking_20 AND
	
	@v10spositiontaking_1 = @old_v10spositiontaking_1 AND
	@v10spositiontaking_2 = @old_v10spositiontaking_2 AND
	@v10spositiontaking_3 = @old_v10spositiontaking_3 AND
	@v10spositiontaking_20 = @old_v10spositiontaking_20 AND
	
	@v11spositiontaking_1 = @old_v11spositiontaking_1 AND
	@v11spositiontaking_20 = @old_v11spositiontaking_20 AND
	
	@v99spositiontaking_1 = @old_v99spositiontaking_1 AND
	@v99spositiontaking_2 = @old_v99spositiontaking_2 AND
	@v99spositiontaking_3 = @old_v99spositiontaking_3 AND
	@v99spositiontaking_20 = @old_v99spositiontaking_20 AND
	
	@auto_spositiontaking_1 = @old_auto_spositiontaking_1 AND
	@auto_spositiontaking_2 = @old_auto_spositiontaking_2 AND
	@auto_spositiontaking_3 = @old_auto_spositiontaking_3 AND
	@auto_spositiontaking_4 = @old_auto_spositiontaking_4 AND
	@auto_spositiontaking_5 = @old_auto_spositiontaking_5 AND
	@auto_spositiontaking_6 = @old_auto_spositiontaking_6 AND
	@auto_spositiontaking_7 = @old_auto_spositiontaking_7 AND
	@auto_spositiontaking_8 = @old_auto_spositiontaking_8 AND
	@auto_spositiontaking_9 = @old_auto_spositiontaking_9 AND
	@auto_spositiontaking_10 = @old_auto_spositiontaking_10 AND
	@auto_slivepositiontaking_1 = @old_auto_slivepositiontaking_1 AND
	@auto_slivepositiontaking_3 = @old_auto_slivepositiontaking_3 AND
	@auto_slivepositiontaking_7 = @old_auto_slivepositiontaking_7 AND
	@auto_slivepositiontaking_8 = @old_auto_slivepositiontaking_8 AND
	
	@auto_v2spositiontaking_1 = @old_auto_v2spositiontaking_1 AND
	@auto_v2spositiontaking_2 = @old_auto_v2spositiontaking_2 AND
	@auto_v2spositiontaking_3 = @old_auto_v2spositiontaking_3 AND
	@auto_v2spositiontaking_7 = @old_auto_v2spositiontaking_7 AND
	@auto_v2spositiontaking_8 = @old_auto_v2spositiontaking_8 AND
	@auto_v2spositiontaking_9 = @old_auto_v2spositiontaking_9 AND
	@auto_v2spositiontaking_20 = @old_auto_v2spositiontaking_20 AND
	
	@auto_v3spositiontaking_1 = @old_auto_v3spositiontaking_1 AND
	@auto_v3spositiontaking_2 = @old_auto_v3spositiontaking_2 AND
	@auto_v3spositiontaking_3 = @old_auto_v3spositiontaking_3 AND
	@auto_v3spositiontaking_20 = @old_auto_v3spositiontaking_20 AND
	
	@auto_v5spositiontaking_1 = @old_auto_v5spositiontaking_1 AND
	@auto_v5spositiontaking_2 = @old_auto_v5spositiontaking_2 AND
	@auto_v5spositiontaking_3 = @old_auto_v5spositiontaking_3 AND
	@auto_v5spositiontaking_20 = @old_auto_v5spositiontaking_20 AND
	
	@auto_v8spositiontaking_1 = @old_auto_v8spositiontaking_1 AND
	@auto_v8spositiontaking_3 = @old_auto_v8spositiontaking_3 AND
	@auto_v8spositiontaking_20 = @old_auto_v8spositiontaking_20 AND
	
	@auto_v10spositiontaking_1 = @old_auto_v10spositiontaking_1 AND
	@auto_v10spositiontaking_2 = @old_auto_v10spositiontaking_2 AND
	@auto_v10spositiontaking_3 = @old_auto_v10spositiontaking_3 AND
	@auto_v10spositiontaking_20 = @old_auto_v10spositiontaking_20 AND
	
	@auto_v11spositiontaking_1 = @old_auto_v11spositiontaking_1 AND
	@auto_v11spositiontaking_20 = @old_auto_v11spositiontaking_20 AND

	@auto_v99spositiontaking_1 = @old_auto_v99spositiontaking_1 AND
	@auto_v99spositiontaking_2 = @old_auto_v99spositiontaking_2 AND
	@auto_v99spositiontaking_3 = @old_auto_v99spositiontaking_3 AND
	@auto_v99spositiontaking_20 = @old_auto_v99spositiontaking_20 AND
	
	@isauto_spositiontaking_1 = @old_isauto_spositiontaking_1 AND
	@isauto_spositiontaking_2 = @old_isauto_spositiontaking_2 AND
	@isauto_spositiontaking_3 = @old_isauto_spositiontaking_3 AND
	@isauto_spositiontaking_4 = @old_isauto_spositiontaking_4 AND
	@isauto_spositiontaking_5 = @old_isauto_spositiontaking_5 AND
	@isauto_spositiontaking_6 = @old_isauto_spositiontaking_6 AND
	@isauto_spositiontaking_7 = @old_isauto_spositiontaking_7 AND
	@isauto_spositiontaking_8 = @old_isauto_spositiontaking_8 AND
	@isauto_spositiontaking_9 = @old_isauto_spositiontaking_9 AND
	@isauto_spositiontaking_10 = @old_isauto_spositiontaking_10 AND
	@isauto_slivepositiontaking_1 = @old_isauto_slivepositiontaking_1 AND
	@isauto_slivepositiontaking_3 = @old_isauto_slivepositiontaking_3 AND
	@isauto_slivepositiontaking_7 = @old_isauto_slivepositiontaking_7 AND
	@isauto_slivepositiontaking_8 = @old_isauto_slivepositiontaking_8 AND
	
	@isauto_v2spositiontaking_1 = @old_isauto_v2spositiontaking_1 AND
	@isauto_v2spositiontaking_2 = @old_isauto_v2spositiontaking_2 AND
	@isauto_v2spositiontaking_3 = @old_isauto_v2spositiontaking_3 AND
	@isauto_v2spositiontaking_7 = @old_isauto_v2spositiontaking_7 AND
	@isauto_v2spositiontaking_8 = @old_isauto_v2spositiontaking_8 AND
	@isauto_v2spositiontaking_9 = @old_isauto_v2spositiontaking_9 AND
	@isauto_v2spositiontaking_20 = @old_isauto_v2spositiontaking_20 AND
	
	@isauto_v3spositiontaking_1 = @old_isauto_v3spositiontaking_1 AND
	@isauto_v3spositiontaking_2 = @old_isauto_v3spositiontaking_2 AND
	@isauto_v3spositiontaking_3 = @old_isauto_v3spositiontaking_3 AND
	@isauto_v3spositiontaking_20 = @old_isauto_v3spositiontaking_20 AND
	
	@isauto_v5spositiontaking_1 = @old_isauto_v5spositiontaking_1 AND
	@isauto_v5spositiontaking_2 = @old_isauto_v5spositiontaking_2 AND
	@isauto_v5spositiontaking_3 = @old_isauto_v5spositiontaking_3 AND
	@isauto_v5spositiontaking_20 = @old_isauto_v5spositiontaking_20 AND
	
	@isauto_v8spositiontaking_1 = @old_isauto_v8spositiontaking_1 AND
	@isauto_v8spositiontaking_3 = @old_isauto_v8spositiontaking_3 AND
	@isauto_v8spositiontaking_20 = @old_isauto_v8spositiontaking_20 AND
	
	@isauto_v10spositiontaking_1 = @old_isauto_v10spositiontaking_1 AND
	@isauto_v10spositiontaking_2 = @old_isauto_v10spositiontaking_2 AND
	@isauto_v10spositiontaking_3 = @old_isauto_v10spositiontaking_3 AND
	@isauto_v10spositiontaking_20 = @old_isauto_v10spositiontaking_20 AND
	
	@isauto_v11spositiontaking_1 = @old_isauto_v11spositiontaking_1 AND
	@isauto_v11spositiontaking_20 = @old_isauto_v11spositiontaking_20 AND
	
	@isauto_v99spositiontaking_1 = @old_isauto_v99spositiontaking_1 AND
	@isauto_v99spositiontaking_2 = @old_isauto_v99spositiontaking_2 AND
	@isauto_v99spositiontaking_3 = @old_isauto_v99spositiontaking_3 AND
	@isauto_v99spositiontaking_20 = @old_isauto_v99spositiontaking_20 
BEGIN
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	return
END 

--Check u1<=l4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + ', '
	from custoverride as co with (NOLOCK) inner join
(
			select 1 as sporttype, 1 as bettype, @auto_spositiontaking_1 as autopositiontaking, @isauto_spositiontaking_1 as isautopositiontaking, @auto_slivepositiontaking_1 as autolivepositiontaking, @isauto_slivepositiontaking_1 as isautolivepositiontaking
	union all		select 1 as sporttype, 3 as bettype, @auto_spositiontaking_3 as autopositiontaking, @isauto_spositiontaking_3 as isautopositiontaking, @auto_slivepositiontaking_3 as autolivepositiontaking, @isauto_slivepositiontaking_3 as isautolivepositiontaking
	union all		select 1 as sporttype, 7 as bettype, @auto_spositiontaking_7 as autopositiontaking, @isauto_spositiontaking_7 as isautopositiontaking, @auto_slivepositiontaking_7 as autolivepositiontaking, @isauto_slivepositiontaking_7 as isautolivepositiontaking
	union all		select 1 as sporttype, 8 as bettype, @auto_spositiontaking_8 as autopositiontaking, @isauto_spositiontaking_8 as isautopositiontaking, @auto_slivepositiontaking_8 as autolivepositiontaking, @isauto_slivepositiontaking_8 as isautolivepositiontaking

	union all		select 1 as sporttype, 2 as bettype, @auto_spositiontaking_2 as autopositiontaking, @isauto_spositiontaking_2 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 1 as sporttype, 4 as bettype, @auto_spositiontaking_4 as autopositiontaking, @isauto_spositiontaking_4 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 1 as sporttype, 5 as bettype, @auto_spositiontaking_5 as autopositiontaking, @isauto_spositiontaking_5 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 1 as sporttype, 6 as bettype, @auto_spositiontaking_6 as autopositiontaking, @isauto_spositiontaking_6 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 1 as sporttype, 9 as bettype, @auto_spositiontaking_9 as autopositiontaking, @isauto_spositiontaking_9 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 1 as sporttype, 10 as bettype, @auto_spositiontaking_10 as autopositiontaking, @isauto_spositiontaking_10 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking

	union all		select 2 as sporttype, 1 as bettype, @auto_v2spositiontaking_1 as autopositiontaking, @isauto_v2spositiontaking_1 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 2 as sporttype, 2 as bettype, @auto_v2spositiontaking_2 as autopositiontaking, @isauto_v2spositiontaking_2 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 2 as sporttype, 3 as bettype, @auto_v2spositiontaking_3 as autopositiontaking, @isauto_v2spositiontaking_3 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 2 as sporttype, 7 as bettype, @auto_v2spositiontaking_7 as autopositiontaking, @isauto_v2spositiontaking_7 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 2 as sporttype, 8 as bettype, @auto_v2spositiontaking_8 as autopositiontaking, @isauto_v2spositiontaking_8 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 2 as sporttype, 9 as bettype, @auto_v2spositiontaking_9 as autopositiontaking, @isauto_v2spositiontaking_9 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 2 as sporttype, 20 as bettype, @auto_v2spositiontaking_20 as autopositiontaking, @isauto_v2spositiontaking_20 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking

	union all		select 3 as sporttype, 1 as bettype, @auto_v3spositiontaking_1 as autopositiontaking, @isauto_v3spositiontaking_1 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 3 as sporttype, 2 as bettype, @auto_v3spositiontaking_2 as autopositiontaking, @isauto_v3spositiontaking_2 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 3 as sporttype, 3 as bettype, @auto_v3spositiontaking_3 as autopositiontaking, @isauto_v3spositiontaking_3 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 3 as sporttype, 20 as bettype, @auto_v3spositiontaking_20 as autopositiontaking, @isauto_v3spositiontaking_20 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking

	union all		select 5 as sporttype, 1 as bettype, @auto_v5spositiontaking_1 as autopositiontaking, @isauto_v5spositiontaking_1 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 5 as sporttype, 2 as bettype, @auto_v5spositiontaking_2 as autopositiontaking, @isauto_v5spositiontaking_2 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 5 as sporttype, 3 as bettype, @auto_v5spositiontaking_3 as autopositiontaking, @isauto_v5spositiontaking_3 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 5 as sporttype, 20 as bettype, @auto_v5spositiontaking_20 as autopositiontaking, @isauto_v5spositiontaking_20 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking

	union all		select 8 as sporttype, 1 as bettype, @auto_v8spositiontaking_1 as autopositiontaking, @isauto_v8spositiontaking_1 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 8 as sporttype, 3 as bettype, @auto_v8spositiontaking_3 as autopositiontaking, @isauto_v8spositiontaking_3 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 8 as sporttype, 20 as bettype, @auto_v8spositiontaking_20 as autopositiontaking, @isauto_v8spositiontaking_20 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking

	union all		select 10 as sporttype, 1 as bettype, @auto_v10spositiontaking_1 as autopositiontaking, @isauto_v10spositiontaking_1 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 10 as sporttype, 2 as bettype, @auto_v10spositiontaking_2 as autopositiontaking, @isauto_v10spositiontaking_2 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 10 as sporttype, 3 as bettype, @auto_v10spositiontaking_3 as autopositiontaking, @isauto_v10spositiontaking_3 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 10 as sporttype, 20 as bettype, @auto_v10spositiontaking_20 as autopositiontaking, @isauto_v10spositiontaking_20 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking

	union all		select 11 as sporttype, 1 as bettype, @auto_v11spositiontaking_1 as autopositiontaking, @isauto_v11spositiontaking_1 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 11 as sporttype, 20 as bettype, @auto_v11spositiontaking_20 as autopositiontaking, @isauto_v11spositiontaking_20 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking

	union all		select 99 as sporttype, 1 as bettype, @auto_v99spositiontaking_1 as autopositiontaking, @isauto_v99spositiontaking_1 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 99 as sporttype, 2 as bettype, @auto_v99spositiontaking_2 as autopositiontaking, @isauto_v99spositiontaking_2 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 99 as sporttype, 3 as bettype, @auto_v99spositiontaking_3 as autopositiontaking, @isauto_v99spositiontaking_3 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	union all		select 99 as sporttype, 20 as bettype, @auto_v99spositiontaking_20 as autopositiontaking, @isauto_v99spositiontaking_20 as isautopositiontaking, 0 as autolivepositiontaking, 0 as isautolivepositiontaking
	
) as b on co.sporttype=b.sporttype and co.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid

where co.custid = @srecommend and ((b.isautopositiontaking>0 and b.autopositiontaking>co.maxpositiontaking) or (b.isautolivepositiontaking>0 and b.sporttype=1 and b.bettype in (1,3,7,8) and b.autolivepositiontaking>co.maxlivepositiontaking))


if @ErrType <>''
BEGIN
	select @isvalid = 0, @ErrCode_cur = 2
	Select @ErrMsg_cur = 	case @Language 
									when 'E' then 'Wrong position taking (min/max set by company) ('+@ErrType+').'
									when 'CS' then N'占成数不正确(公司设给最低/高占成) ('+@ErrType+').'
									when 'CT' then N'佔成數不正確(公司設給最低/高佔成) ('+@ErrType+').'
									when 'TH' then N'การกำหนดไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท) ('+@ErrType+').'
									when 'J' then N'Wrong position taking (min/max set by company) ('+@ErrType+').'
									when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값) ('+@ErrType+').'
									else N'Wrong position taking (min/max set by company) ('+@ErrType+').'
							end
	select	@ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END

-- End check parameter
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




	--Check u1<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 1 as sporttype, @auto_spositiontaking_1 as autopositiontaking, @auto_slivepositiontaking_1 as autolivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @auto_spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @auto_spositiontaking_3 as autopositiontaking, @auto_slivepositiontaking_3 as autolivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @auto_spositiontaking_4 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @auto_spositiontaking_5 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @auto_spositiontaking_6 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @auto_spositiontaking_7 as autopositiontaking, @auto_slivepositiontaking_7 as autolivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @auto_spositiontaking_8 as autopositiontaking, @auto_slivepositiontaking_8 as autolivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @auto_spositiontaking_9 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @auto_spositiontaking_10 as autopositiontaking, 0 as autolivepositiontaking
			
			union all 	select 1 as bettype, 2 as sporttype, @auto_v2spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @auto_v2spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @auto_v2spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @auto_v2spositiontaking_7 as autopositiontaking, 0 as autolivepositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @auto_v2spositiontaking_8 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @auto_v2spositiontaking_9 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @auto_v2spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking

			union all 	select 1 as bettype, 3 as sporttype, @auto_v3spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @auto_v3spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @auto_v3spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @auto_v3spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking

			union all 	select 1 as bettype, 5 as sporttype, @auto_v5spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @auto_v5spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @auto_v5spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @auto_v5spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking

			union all 	select 1 as bettype, 8 as sporttype, @auto_v8spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @auto_v8spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @auto_v8spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking

			union all 	select 1 as bettype, 10 as sporttype, @auto_v10spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @auto_v10spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @auto_v10spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @auto_v10spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking

			union all 	select 1 as bettype, 11 as sporttype, @auto_v11spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @auto_v11spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking

			union all 	select 1 as bettype, 99 as sporttype, @auto_v99spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @auto_v99spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @auto_v99spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @auto_v99spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and 
		((cs.spositiontaking<b.autopositiontaking) or (b.bettype in (1,3,7,8) and b.sporttype=1 and cs.slivepositiontaking<b.autolivepositiontaking))
		
	if @ErrType <>''
	BEGIN
		Select @ErrMsg_cur =	@UserName + ': '+
							case @Language 
								when 'E' then 'Wrong auto position taking.<br>'+@ErrType
								when 'CS' then N'自动占成数不正确.<br>'+@ErrType
								when 'CT' then N'自動佔成數不正確.<br>'+@ErrType
								when 'TH' then N'การปรับยอดเงินที่ผิดพลาดอันเนื่องมาจากระบบ.<br>'+@ErrType
								when 'J' then N'Wrong auto position taking.<br>'+@ErrType
								when 'KO' then N'자동 거래조건이 잘못 되었습니다.<br>'+@ErrType
								else N'Wrong auto position taking.<br>'+@ErrType
							end, @ErrCode_cur = 7							
		select  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
	--Check s1<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 1 as sporttype, @spositiontaking_1 as positiontaking, @slivepositiontaking_1 as livepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @spositiontaking_2 as positiontaking, 0 as livepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @spositiontaking_3 as positiontaking, @slivepositiontaking_3 as livepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @spositiontaking_4 as positiontaking, 0 as livepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @spositiontaking_5 as positiontaking, 0 as livepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @spositiontaking_6 as positiontaking, 0 as livepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @spositiontaking_7 as positiontaking, @slivepositiontaking_7 as livepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @spositiontaking_8 as positiontaking, @slivepositiontaking_8 as livepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @spositiontaking_9 as positiontaking, 0 as livepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @spositiontaking_10 as positiontaking, 0 as livepositiontaking
			
			union all	select 1 as bettype, 2 as sporttype, @v2spositiontaking_1 as positiontaking, 0 as livepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2spositiontaking_2 as positiontaking, 0 as livepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2spositiontaking_3 as positiontaking, 0 as livepositiontaking
			union all 	select 7 as bettype, 2 as sporttype, @v2spositiontaking_7 as positiontaking, 0 as livepositiontaking
			union all 	select 8 as bettype, 2 as sporttype, @v2spositiontaking_8 as positiontaking, 0 as livepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2spositiontaking_9 as positiontaking, 0 as livepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2spositiontaking_20 as positiontaking, 0 as livepositiontaking

			union all	select 1 as bettype, 3 as sporttype, @v3spositiontaking_1 as positiontaking, 0 as livepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3spositiontaking_2 as positiontaking, 0 as livepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3spositiontaking_3 as positiontaking, 0 as livepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3spositiontaking_20 as positiontaking, 0 as livepositiontaking

			union all	select 1 as bettype, 5 as sporttype, @v5spositiontaking_1 as positiontaking, 0 as livepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5spositiontaking_2 as positiontaking, 0 as livepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5spositiontaking_3 as positiontaking, 0 as livepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5spositiontaking_20 as positiontaking, 0 as livepositiontaking

			union all	select 1 as bettype, 8 as sporttype, @v8spositiontaking_1 as positiontaking, 0 as livepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8spositiontaking_3 as positiontaking, 0 as livepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8spositiontaking_20 as positiontaking, 0 as livepositiontaking

			union all	select 1 as bettype, 10 as sporttype, @v10spositiontaking_1 as positiontaking, 0 as livepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10spositiontaking_2 as positiontaking, 0 as livepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10spositiontaking_3 as positiontaking, 0 as livepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10spositiontaking_20 as positiontaking, 0 as livepositiontaking

			union all	select 1 as bettype, 11 as sporttype, @v11spositiontaking_1 as positiontaking, 0 as livepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11spositiontaking_20 as positiontaking, 0 as livepositiontaking

			union all	select 1 as bettype, 99 as sporttype, @v99spositiontaking_1 as positiontaking, 0 as livepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99spositiontaking_2 as positiontaking, 0 as livepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99spositiontaking_3 as positiontaking, 0 as livepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99spositiontaking_20 as positiontaking, 0 as livepositiontaking
			
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and 
		((cs.spositiontaking<b.positiontaking) or (b.bettype in (1,3,7,8) and b.sporttype=1 and cs.slivepositiontaking<b.livepositiontaking))
		
	if @ErrType <>''
	BEGIN
		Select @ErrMsg_cur =	@UserName + ': '+
							case @Language 
								when 'E' then 'Wrong  position taking.<br>'+@ErrType
								when 'CS' then N'占成数不正确.<br>'+@ErrType
								when 'CT' then N'佔成數不正確.<br>'+@ErrType
								when 'TH' then N'การกำหนดไม่ถูกต้อง.<br>'+@ErrType
								when 'J' then N'Wrong  position taking.<br>'+@ErrType
								when 'KO' then N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
								else N'Wrong  position taking.<br>'+@ErrType
							end, @ErrCode_cur = 8							
		select	@ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END


select @spositiontaking_1_max = spositiontaking, @slivepositiontaking_1_max = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=1
select @spositiontaking_3_max = spositiontaking, @slivepositiontaking_3_max = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=1
select @spositiontaking_7_max = spositiontaking, @slivepositiontaking_7_max = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=7 and sporttype=1
select @spositiontaking_8_max = spositiontaking, @slivepositiontaking_8_max = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=8 and sporttype=1

select @spositiontaking_2_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=1
select @spositiontaking_4_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=4 and sporttype=1
select @spositiontaking_5_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=5 and sporttype=1
select @spositiontaking_6_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=6 and sporttype=1
select @spositiontaking_9_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=9 and sporttype=1
select @spositiontaking_10_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=10 and sporttype=1

select @v2spositiontaking_1_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=2
select @v2spositiontaking_2_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=2
select @v2spositiontaking_3_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=2
select @v2spositiontaking_7_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=7 and sporttype=2
select @v2spositiontaking_8_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=8 and sporttype=2
select @v2spositiontaking_9_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=9 and sporttype=2
select @v2spositiontaking_20_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=2

select @v3spositiontaking_1_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=3
select @v3spositiontaking_2_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=3
select @v3spositiontaking_3_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=3
select @v3spositiontaking_20_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=3

select @v5spositiontaking_1_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=5
select @v5spositiontaking_2_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=5
select @v5spositiontaking_3_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=5
select @v5spositiontaking_20_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=5

select @v8spositiontaking_1_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=8
select @v8spositiontaking_3_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=8
select @v8spositiontaking_20_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=8

select @v10spositiontaking_1_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=10
select @v10spositiontaking_2_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=10
select @v10spositiontaking_3_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=10
select @v10spositiontaking_20_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=10

select @v11spositiontaking_1_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=11
select @v11spositiontaking_20_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=11

select @v99spositiontaking_1_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=1 and sporttype=99
select @v99spositiontaking_2_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=99
select @v99spositiontaking_3_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=99
select @v99spositiontaking_20_max = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and bettype=20 and sporttype=99

select 
	@spositiontaking_1 = case when @spositiontaking_1+@mpositiontaking_1+@apositiontaking_1>@spositiontaking_1_max then @spositiontaking_1_max-@mpositiontaking_1-@apositiontaking_1 else @spositiontaking_1 end,
	@spositiontaking_2 = case when @spositiontaking_2+@mpositiontaking_2+@apositiontaking_2>@spositiontaking_2_max then @spositiontaking_2_max-@mpositiontaking_2-@apositiontaking_2 else @spositiontaking_2 end,
	@spositiontaking_3 = case when @spositiontaking_3+@mpositiontaking_3+@apositiontaking_3>@spositiontaking_3_max then @spositiontaking_3_max-@mpositiontaking_3-@apositiontaking_3 else @spositiontaking_3 end,
	@spositiontaking_4 = case when @spositiontaking_4+@mpositiontaking_4+@apositiontaking_4>@spositiontaking_4_max then @spositiontaking_4_max-@mpositiontaking_4-@apositiontaking_4 else @spositiontaking_4 end,
	@spositiontaking_5 = case when @spositiontaking_5+@mpositiontaking_5+@apositiontaking_5>@spositiontaking_5_max then @spositiontaking_5_max-@mpositiontaking_5-@apositiontaking_5 else @spositiontaking_5 end,
	@spositiontaking_6 = case when @spositiontaking_6+@mpositiontaking_6+@apositiontaking_6>@spositiontaking_6_max then @spositiontaking_6_max-@mpositiontaking_6-@apositiontaking_6 else @spositiontaking_6 end,
	@spositiontaking_7 = case when @spositiontaking_7+@mpositiontaking_7+@apositiontaking_7>@spositiontaking_7_max then @spositiontaking_7_max-@mpositiontaking_7-@apositiontaking_7 else @spositiontaking_7 end,
	@spositiontaking_8 = case when @spositiontaking_8+@mpositiontaking_8+@apositiontaking_8>@spositiontaking_8_max then @spositiontaking_8_max-@mpositiontaking_8-@apositiontaking_8 else @spositiontaking_8 end,
	@spositiontaking_9 = case when @spositiontaking_9+@mpositiontaking_9+@apositiontaking_9>@spositiontaking_9_max then @spositiontaking_9_max-@mpositiontaking_9-@apositiontaking_9 else @spositiontaking_9 end,
	@spositiontaking_10 = case when @spositiontaking_10+@mpositiontaking_10+@apositiontaking_10>@spositiontaking_10_max then @spositiontaking_10_max-@mpositiontaking_10-@apositiontaking_10 else @spositiontaking_10 end,

	@slivepositiontaking_1 = case when @slivepositiontaking_1+@mlivepositiontaking_1+@alivepositiontaking_1>@slivepositiontaking_1_max then @slivepositiontaking_1_max-@mlivepositiontaking_1-@alivepositiontaking_1 else @slivepositiontaking_1 end,
	@slivepositiontaking_3 = case when @slivepositiontaking_3+@mlivepositiontaking_3+@alivepositiontaking_3>@slivepositiontaking_3_max then @slivepositiontaking_3_max-@mlivepositiontaking_3-@alivepositiontaking_3 else @slivepositiontaking_3 end,
	@slivepositiontaking_7 = case when @slivepositiontaking_7+@mlivepositiontaking_7+@alivepositiontaking_7>@slivepositiontaking_7_max then @slivepositiontaking_7_max-@mlivepositiontaking_7-@alivepositiontaking_7 else @slivepositiontaking_7 end,
	@slivepositiontaking_8 = case when @slivepositiontaking_8+@mlivepositiontaking_8+@alivepositiontaking_8>@slivepositiontaking_8_max then @slivepositiontaking_8_max-@mlivepositiontaking_8-@alivepositiontaking_8 else @slivepositiontaking_8 end,

	@v2spositiontaking_1 = case when @v2mpositiontaking_1+@v2spositiontaking_1+@v2apositiontaking_1>@v2spositiontaking_1_max then @v2spositiontaking_1_max-@v2mpositiontaking_1-@v2apositiontaking_1 else @v2spositiontaking_1 end,
	@v2spositiontaking_2 = case when @v2mpositiontaking_2+@v2spositiontaking_2+@v2apositiontaking_2>@v2spositiontaking_2_max then @v2spositiontaking_2_max-@v2mpositiontaking_2-@v2apositiontaking_2 else @v2spositiontaking_2 end,
	@v2spositiontaking_3 = case when @v2mpositiontaking_3+@v2spositiontaking_3+@v2apositiontaking_3>@v2spositiontaking_3_max then @v2spositiontaking_3_max-@v2mpositiontaking_3-@v2apositiontaking_3 else @v2spositiontaking_3 end,
	@v2spositiontaking_7 = case when @v2mpositiontaking_7+@v2spositiontaking_7+@v2apositiontaking_7>@v2spositiontaking_7_max then @v2spositiontaking_7_max-@v2mpositiontaking_7-@v2apositiontaking_7 else @v2spositiontaking_7 end,
	@v2spositiontaking_8 = case when @v2mpositiontaking_8+@v2spositiontaking_8+@v2apositiontaking_8>@v2spositiontaking_8_max then @v2spositiontaking_8_max-@v2mpositiontaking_8-@v2apositiontaking_8 else @v2spositiontaking_8 end,
	@v2spositiontaking_9 = case when @v2mpositiontaking_9+@v2spositiontaking_9+@v2apositiontaking_9>@v2spositiontaking_9_max then @v2spositiontaking_9_max-@v2mpositiontaking_9-@v2apositiontaking_9 else @v2spositiontaking_9 end,
	@v2spositiontaking_20 = case when @v2mpositiontaking_20+@v2spositiontaking_20+@v2apositiontaking_20>@v2spositiontaking_20_max then @v2spositiontaking_20_max-@v2mpositiontaking_20-@v2apositiontaking_20 else @v2spositiontaking_20 end,

	@v3spositiontaking_1 = case when @v3mpositiontaking_1+@v3spositiontaking_1+@v3apositiontaking_1>@v3spositiontaking_1_max then @v3spositiontaking_1_max-@v3mpositiontaking_1-@v3apositiontaking_1 else @v3spositiontaking_1 end,
	@v3spositiontaking_2 = case when @v3mpositiontaking_2+@v3spositiontaking_2+@v3apositiontaking_2>@v3spositiontaking_2_max then @v3spositiontaking_2_max-@v3mpositiontaking_2-@v3apositiontaking_2 else @v3spositiontaking_2 end,
	@v3spositiontaking_3 = case when @v3mpositiontaking_3+@v3spositiontaking_3+@v3apositiontaking_3>@v3spositiontaking_3_max then @v3spositiontaking_3_max-@v3mpositiontaking_3-@v3apositiontaking_3 else @v3spositiontaking_3 end,
	@v3spositiontaking_20 = case when @v3mpositiontaking_20+@v3spositiontaking_20+@v3apositiontaking_20>@v3spositiontaking_20_max then @v3spositiontaking_20_max-@v3mpositiontaking_20-@v3apositiontaking_20 else @v3spositiontaking_20 end,

	@v5spositiontaking_1 = case when @v5mpositiontaking_1+@v5spositiontaking_1+@v5apositiontaking_1>@v5spositiontaking_1_max then @v5spositiontaking_1_max-@v5mpositiontaking_1-@v5apositiontaking_1 else @v5spositiontaking_1 end,
	@v5spositiontaking_2 = case when @v5mpositiontaking_2+@v5spositiontaking_2+@v5apositiontaking_2>@v5spositiontaking_2_max then @v5spositiontaking_2_max-@v5mpositiontaking_2-@v5apositiontaking_2 else @v5spositiontaking_2 end,
	@v5spositiontaking_3 = case when @v5mpositiontaking_3+@v5spositiontaking_3+@v5apositiontaking_3>@v5spositiontaking_3_max then @v5spositiontaking_3_max-@v5mpositiontaking_3-@v5apositiontaking_3 else @v5spositiontaking_3 end,
	@v5spositiontaking_20 = case when @v5mpositiontaking_20+@v5spositiontaking_20+@v5apositiontaking_20>@v5spositiontaking_20_max then @v5spositiontaking_20_max-@v5mpositiontaking_20-@v5apositiontaking_20 else @v5spositiontaking_20 end,

	@v8spositiontaking_1 = case when @v8mpositiontaking_1+@v8spositiontaking_1+@v8apositiontaking_1>@v8spositiontaking_1_max then @v8spositiontaking_1_max-@v8mpositiontaking_1-@v8apositiontaking_1 else @v8spositiontaking_1 end,
	@v8spositiontaking_3 = case when @v8mpositiontaking_3+@v8spositiontaking_3+@v8apositiontaking_3>@v8spositiontaking_3_max then @v8spositiontaking_3_max-@v8mpositiontaking_3-@v8apositiontaking_3 else @v8spositiontaking_3 end,
	@v8spositiontaking_20 = case when @v8mpositiontaking_20+@v8spositiontaking_20+@v8apositiontaking_20>@v8spositiontaking_20_max then @v8spositiontaking_20_max-@v8mpositiontaking_20-@v8apositiontaking_20 else @v8spositiontaking_20 end,

	@v10spositiontaking_1 = case when @v10mpositiontaking_1+@v10spositiontaking_1+@v10apositiontaking_1>@v10spositiontaking_1_max then @v10spositiontaking_1_max-@v10mpositiontaking_1-@v10apositiontaking_1 else @v10spositiontaking_1 end,
	@v10spositiontaking_2 = case when @v10mpositiontaking_2+@v10spositiontaking_2+@v10apositiontaking_2>@v10spositiontaking_2_max then @v10spositiontaking_2_max-@v10mpositiontaking_2-@v10apositiontaking_2 else @v10spositiontaking_2 end,
	@v10spositiontaking_3 = case when @v10mpositiontaking_3+@v10spositiontaking_3+@v10apositiontaking_3>@v10spositiontaking_3_max then @v10spositiontaking_3_max-@v10mpositiontaking_3-@v10apositiontaking_3 else @v10spositiontaking_3 end,
	@v10spositiontaking_20 = case when @v10mpositiontaking_20+@v10spositiontaking_20+@v10apositiontaking_20>@v10spositiontaking_20_max then @v10spositiontaking_20_max-@v10mpositiontaking_20-@v10apositiontaking_20 else @v10spositiontaking_20 end,

	@v11spositiontaking_1 = case when @v11mpositiontaking_1+@v11spositiontaking_1+@v11apositiontaking_1>@v11spositiontaking_1_max then @v11spositiontaking_1_max-@v11mpositiontaking_1-@v11apositiontaking_1 else @v11spositiontaking_1 end,
	@v11spositiontaking_20 = case when @v11mpositiontaking_20+@v11spositiontaking_20+@v11apositiontaking_20>@v11spositiontaking_20_max then @v11spositiontaking_20_max-@v11mpositiontaking_20-@v11apositiontaking_20 else @v11spositiontaking_20 end,

	@v99spositiontaking_1 = case when @v99mpositiontaking_1+@v99spositiontaking_1+@v99apositiontaking_1>@v99spositiontaking_1_max then @v99spositiontaking_1_max-@v99mpositiontaking_1-@v99apositiontaking_1 else @v99spositiontaking_1 end,
	@v99spositiontaking_2 = case when @v99mpositiontaking_2+@v99spositiontaking_2+@v99apositiontaking_2>@v99spositiontaking_2_max then @v99spositiontaking_2_max-@v99mpositiontaking_2-@v99apositiontaking_2 else @v99spositiontaking_2 end,
	@v99spositiontaking_3 = case when @v99mpositiontaking_3+@v99spositiontaking_3+@v99apositiontaking_3>@v99spositiontaking_3_max then @v99spositiontaking_3_max-@v99mpositiontaking_3-@v99apositiontaking_3 else @v99spositiontaking_3 end,
	@v99spositiontaking_20 = case when @v99mpositiontaking_20+@v99spositiontaking_20+@v99apositiontaking_20>@v99spositiontaking_20_max then @v99spositiontaking_20_max-@v99mpositiontaking_20-@v99apositiontaking_20 else @v99spositiontaking_20 end

select 
	@spositiontaking_1 = case when @spositiontaking_1<0 then 0 else @spositiontaking_1 end,
	@spositiontaking_2 = case when @spositiontaking_2<0 then 0 else @spositiontaking_2 end,
	@spositiontaking_3 = case when @spositiontaking_3<0 then 0 else @spositiontaking_3 end,
	@spositiontaking_4 = case when @spositiontaking_4<0 then 0 else @spositiontaking_4 end,
	@spositiontaking_5 = case when @spositiontaking_5<0 then 0 else @spositiontaking_5 end,
	@spositiontaking_6 = case when @spositiontaking_6<0 then 0 else @spositiontaking_6 end,
	@spositiontaking_7 = case when @spositiontaking_7<0 then 0 else @spositiontaking_7 end,
	@spositiontaking_8 = case when @spositiontaking_8<0 then 0 else @spositiontaking_8 end,
	@spositiontaking_9 = case when @spositiontaking_9<0 then 0 else @spositiontaking_9 end,
	@spositiontaking_10 = case when @spositiontaking_10<0 then 0 else @spositiontaking_10 end,

	@slivepositiontaking_1 = case when @slivepositiontaking_1<0 then 0 else @slivepositiontaking_1 end,
	@slivepositiontaking_3 = case when @slivepositiontaking_3<0 then 0 else @slivepositiontaking_3 end,
	@slivepositiontaking_7 = case when @slivepositiontaking_7<0 then 0 else @slivepositiontaking_7 end,
	@slivepositiontaking_8 = case when @slivepositiontaking_8<0 then 0 else @slivepositiontaking_8 end,

	@v2spositiontaking_1 = case when @v2spositiontaking_1<0 then 0 else @v2spositiontaking_1 end,
	@v2spositiontaking_2 = case when @v2spositiontaking_2<0 then 0 else @v2spositiontaking_2 end,
	@v2spositiontaking_3 = case when @v2spositiontaking_3<0 then 0 else @v2spositiontaking_3 end,
	@v2spositiontaking_7 = case when @v2spositiontaking_7<0 then 0 else @v2spositiontaking_7 end,
	@v2spositiontaking_8 = case when @v2spositiontaking_8<0 then 0 else @v2spositiontaking_8 end,
	@v2spositiontaking_9 = case when @v2spositiontaking_9<0 then 0 else @v2spositiontaking_9 end,
	@v2spositiontaking_20 = case when @v2spositiontaking_20<0 then 0 else @v2spositiontaking_20 end,

	@v3spositiontaking_1 = case when @v3spositiontaking_1<0 then 0 else @v3spositiontaking_1 end,
	@v3spositiontaking_2 = case when @v3spositiontaking_2<0 then 0 else @v3spositiontaking_2 end,
	@v3spositiontaking_3 = case when @v3spositiontaking_3<0 then 0 else @v3spositiontaking_3 end,
	@v3spositiontaking_20 = case when @v3spositiontaking_20<0 then 0 else @v3spositiontaking_20 end,

	@v5spositiontaking_1 = case when @v5spositiontaking_1<0 then 0 else @v5spositiontaking_1 end,
	@v5spositiontaking_2 = case when @v5spositiontaking_2<0 then 0 else @v5spositiontaking_2 end,
	@v5spositiontaking_3 = case when @v5spositiontaking_3<0 then 0 else @v5spositiontaking_3 end,
	@v5spositiontaking_20 = case when @v5spositiontaking_20<0 then 0 else @v5spositiontaking_20 end,

	@v8spositiontaking_1 = case when @v8spositiontaking_1<0 then 0 else @v8spositiontaking_1 end,
	@v8spositiontaking_3 = case when @v8spositiontaking_3<0 then 0 else @v8spositiontaking_3 end,
	@v8spositiontaking_20 = case when @v8spositiontaking_20<0 then 0 else @v8spositiontaking_20 end,

	@v10spositiontaking_1 = case when @v10spositiontaking_1<0 then 0 else @v10spositiontaking_1 end,
	@v10spositiontaking_2 = case when @v10spositiontaking_2<0 then 0 else @v10spositiontaking_2 end,
	@v10spositiontaking_3 = case when @v10spositiontaking_3<0 then 0 else @v10spositiontaking_3 end,
	@v10spositiontaking_20 = case when @v10spositiontaking_20<0 then 0 else @v10spositiontaking_20 end,

	@v11spositiontaking_1 = case when @v11spositiontaking_1<0 then 0 else @v11spositiontaking_1 end,
	@v11spositiontaking_20 = case when @v11spositiontaking_20<0 then 0 else @v11spositiontaking_20 end,

	@v99spositiontaking_1 = case when @v99spositiontaking_1<0 then 0 else @v99spositiontaking_1 end,
	@v99spositiontaking_2 = case when @v99spositiontaking_2<0 then 0 else @v99spositiontaking_2 end,
	@v99spositiontaking_3 = case when @v99spositiontaking_3<0 then 0 else @v99spositiontaking_3 end,
	@v99spositiontaking_20 = case when @v99spositiontaking_20<0 then 0 else @v99spositiontaking_20 end

--don't update s1 for member under master was set i3=1(normal)
update cs with (ROWLOCK, UPDLOCK)
set
	cs.spositiontaking = case cs.sporttype 	when 1 then case cs.bettype when 1 then @spositiontaking_1 when 2 then @spositiontaking_2 when 3 then @spositiontaking_3 when 4 then @spositiontaking_4 when 5 then @spositiontaking_5 when 6 then @spositiontaking_6 when 7 then @spositiontaking_7 when 8 then @spositiontaking_8 when 9 then @spositiontaking_9 when 10 then @spositiontaking_10 else 0 end
					when 2 then case cs.bettype when 1 then @v2spositiontaking_1 when 2 then @v2spositiontaking_2 when 3 then @v2spositiontaking_3 when 7 then @v2spositiontaking_7 when 8 then @v2spositiontaking_8 when 9 then @v2spositiontaking_9 when 20 then @v2spositiontaking_20  else 0 end
					when 3 then case cs.bettype when 1 then @v3spositiontaking_1 when 2 then @v3spositiontaking_2 when 3 then @v3spositiontaking_3 when 20 then @v3spositiontaking_20 else 0 end
					when 5 then case cs.bettype when 1 then @v5spositiontaking_1 when 2 then @v5spositiontaking_2 when 3 then @v5spositiontaking_3 when 20 then @v5spositiontaking_20 else 0 end
					when 8 then case cs.bettype when 1 then @v8spositiontaking_1 when 3 then @v8spositiontaking_3 when 20 then @v8spositiontaking_20 else 0 end
					when 10 then case cs.bettype when 1 then @v10spositiontaking_1 when 2 then @v10spositiontaking_2 when 3 then @v10spositiontaking_3 when 20 then @v10spositiontaking_20 else 0 end
					when 11 then case cs.bettype when 1 then @v11spositiontaking_1 when 20 then @v11spositiontaking_20 else 0 end
					when 99 then case cs.bettype when 1 then @v99spositiontaking_1 when 2 then @v99spositiontaking_2 when 3 then @v99spositiontaking_3 when 20 then @v99spositiontaking_20 else 0 end
					else cs.spositiontaking end
from Custsetting cs inner join custinfo c (nolock) on cs.custid = c.custid
	inner join custsetting scs (nolock) on scs.custid = c.mrecommend and cs.sporttype = scs.sporttype and cs.bettype = scs.bettype
where cs.custid=@custid and c.roleid = 1 and scs.isautopositiontaking = 0
--don't update s1 for member under master was set i3=1(live)
update cs with (ROWLOCK, UPDLOCK)
set
	cs.slivepositiontaking = case cs.sporttype 	when 1 then case cs.bettype when 1 then @slivepositiontaking_1 when 3 then @slivepositiontaking_3 when 7 then @slivepositiontaking_7 when 8 then @slivepositiontaking_8 else cs.slivepositiontaking end else cs.slivepositiontaking end
from Custsetting cs inner join custinfo c (nolock) on cs.custid = c.custid
	inner join custsetting scs (nolock) on scs.custid = c.mrecommend and cs.sporttype = scs.sporttype and cs.bettype = scs.bettype
where cs.custid=@custid and c.roleid = 1 and scs.isautolivepositiontaking = 0

EXEC dbo.Acc_CustomerUpdMember_AutoPositiontaking 
			@custid = @custid,
			@auto_spositiontaking_1 = @auto_spositiontaking_1,
			@auto_spositiontaking_2 = @auto_spositiontaking_2,
			@auto_spositiontaking_3 = @auto_spositiontaking_3,
			@auto_spositiontaking_4 = @auto_spositiontaking_4,
			@auto_spositiontaking_5 = @auto_spositiontaking_5,
			@auto_spositiontaking_6 = @auto_spositiontaking_6,
			@auto_spositiontaking_7 = @auto_spositiontaking_7,
			@auto_spositiontaking_8 = @auto_spositiontaking_8,
			@auto_spositiontaking_9 = @auto_spositiontaking_9,
			@auto_spositiontaking_10 = @auto_spositiontaking_10,
			@auto_slivepositiontaking_1 = @auto_slivepositiontaking_1,
			@auto_slivepositiontaking_3 = @auto_slivepositiontaking_3,
			@auto_slivepositiontaking_7 = @auto_slivepositiontaking_7,
			@auto_slivepositiontaking_8 = @auto_slivepositiontaking_8,
			@auto_v2spositiontaking_1 = @auto_v2spositiontaking_1,
			@auto_v2spositiontaking_2 = @auto_v2spositiontaking_2,
			@auto_v2spositiontaking_3 = @auto_v2spositiontaking_3,
			@auto_v2spositiontaking_7 = @auto_v2spositiontaking_7,
			@auto_v2spositiontaking_8 = @auto_v2spositiontaking_8,
			@auto_v2spositiontaking_9 = @auto_v2spositiontaking_9,
			@auto_v2spositiontaking_20 = @auto_v2spositiontaking_20,
			@auto_v3spositiontaking_1 = @auto_v3spositiontaking_1,
			@auto_v3spositiontaking_2 = @auto_v3spositiontaking_2,
			@auto_v3spositiontaking_3 = @auto_v3spositiontaking_3,
			@auto_v3spositiontaking_20 = @auto_v3spositiontaking_20,
			@auto_v5spositiontaking_1 = @auto_v5spositiontaking_1,
			@auto_v5spositiontaking_2 = @auto_v5spositiontaking_2,
			@auto_v5spositiontaking_3 = @auto_v5spositiontaking_3,
			@auto_v5spositiontaking_20 = @auto_v5spositiontaking_20,
			@auto_v8spositiontaking_1 = @auto_v8spositiontaking_1,
			@auto_v8spositiontaking_3 = @auto_v8spositiontaking_3,
			@auto_v8spositiontaking_20 = @auto_v8spositiontaking_20,
			@auto_v10spositiontaking_1 = @auto_v10spositiontaking_1,
			@auto_v10spositiontaking_2 = @auto_v10spositiontaking_2,
			@auto_v10spositiontaking_3 = @auto_v10spositiontaking_3,
			@auto_v10spositiontaking_20 = @auto_v10spositiontaking_20,
			@auto_v11spositiontaking_1 = @auto_v11spositiontaking_1,
			@auto_v11spositiontaking_20 = @auto_v11spositiontaking_20,
			
			@auto_v99spositiontaking_1 = @auto_v99spositiontaking_1,
			@auto_v99spositiontaking_2 = @auto_v99spositiontaking_2,
			@auto_v99spositiontaking_3 = @auto_v99spositiontaking_3,
			@auto_v99spositiontaking_20 = @auto_v99spositiontaking_20,
			@isauto_spositiontaking_1 = @isauto_spositiontaking_1,
			@isauto_spositiontaking_2 = @isauto_spositiontaking_2,
			@isauto_spositiontaking_3 = @isauto_spositiontaking_3,
			@isauto_spositiontaking_4 = @isauto_spositiontaking_4,
			@isauto_spositiontaking_5 = @isauto_spositiontaking_5,
			@isauto_spositiontaking_6 = @isauto_spositiontaking_6,
			@isauto_spositiontaking_7 = @isauto_spositiontaking_7,
			@isauto_spositiontaking_8 = @isauto_spositiontaking_8,
			@isauto_spositiontaking_9 = @isauto_spositiontaking_9,
			@isauto_spositiontaking_10 = @isauto_spositiontaking_10,
			@isauto_slivepositiontaking_1 = @isauto_slivepositiontaking_1,
			@isauto_slivepositiontaking_3 = @isauto_slivepositiontaking_3,
			@isauto_slivepositiontaking_7 = @isauto_slivepositiontaking_7,
			@isauto_slivepositiontaking_8 = @isauto_slivepositiontaking_8,
			@isauto_v2spositiontaking_1 = @isauto_v2spositiontaking_1,
			@isauto_v2spositiontaking_2 = @isauto_v2spositiontaking_2,
			@isauto_v2spositiontaking_3 = @isauto_v2spositiontaking_3,
			@isauto_v2spositiontaking_7 = @isauto_v2spositiontaking_7,
			@isauto_v2spositiontaking_8 = @isauto_v2spositiontaking_8,
			@isauto_v2spositiontaking_9 = @isauto_v2spositiontaking_9,
			@isauto_v2spositiontaking_20 = @isauto_v2spositiontaking_20,
			@isauto_v3spositiontaking_1 = @isauto_v3spositiontaking_1,
			@isauto_v3spositiontaking_2 = @isauto_v3spositiontaking_2,
			@isauto_v3spositiontaking_3 = @isauto_v3spositiontaking_3,
			@isauto_v3spositiontaking_20 = @isauto_v3spositiontaking_20,
			@isauto_v5spositiontaking_1 = @isauto_v5spositiontaking_1,
			@isauto_v5spositiontaking_2 = @isauto_v5spositiontaking_2,
			@isauto_v5spositiontaking_3 = @isauto_v5spositiontaking_3,
			@isauto_v5spositiontaking_20 = @isauto_v5spositiontaking_20,
			@isauto_v8spositiontaking_1 = @isauto_v8spositiontaking_1,
			@isauto_v8spositiontaking_3 = @isauto_v8spositiontaking_3,
			@isauto_v8spositiontaking_20 = @isauto_v8spositiontaking_20,
			@isauto_v10spositiontaking_1 = @isauto_v10spositiontaking_1,
			@isauto_v10spositiontaking_2 = @isauto_v10spositiontaking_2,
			@isauto_v10spositiontaking_3 = @isauto_v10spositiontaking_3,
			@isauto_v10spositiontaking_20 = @isauto_v10spositiontaking_20,
			@isauto_v11spositiontaking_1 = @isauto_v11spositiontaking_1,
			@isauto_v11spositiontaking_20 = @isauto_v11spositiontaking_20,
			
			@isauto_v99spositiontaking_1 = @isauto_v99spositiontaking_1,
			@isauto_v99spositiontaking_2 = @isauto_v99spositiontaking_2,
			@isauto_v99spositiontaking_3 = @isauto_v99spositiontaking_3,
			@isauto_v99spositiontaking_20 = @isauto_v99spositiontaking_20,
			@language = @language,
			@userid = @userid

EXEC dbo.Acc_CustomerUpdMember_MinMaxPositiontaking 
	@custid = @custid, 
	@recommend = @recommend, 
	@mrecommend = @mrecommend, 
	@srecommend = @srecommend,
	@updautosuper = 0
	
Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)

Select @LogSPData = '<Acc_CustomerUpdMember_Super><s spt_1="'+ coalesce(cast(@spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'spt_2="'+ coalesce(cast(@spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'spt_3="'+ coalesce(cast(@spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'spt_4="'+ coalesce(cast(@spositiontaking_4 as varchar(50)),space(1)) + '" ' +
'spt_5="'+ coalesce(cast(@spositiontaking_5 as varchar(50)),space(1))  + '" ' +
'spt_6="'+ coalesce(cast(@spositiontaking_6 as varchar(50)),space(1)) + '" ' +
'spt_7="'+ coalesce(cast(@spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'spt_8="'+ coalesce(cast(@spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'spt_9="'+ coalesce(cast(@spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'spt_10="'+ coalesce(cast(@spositiontaking_10 as varchar(50)),space(1)) + '" ' +
'slivept_1="'+ coalesce(cast(@slivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'slivept_3="'+ coalesce(cast(@slivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'slivept_7="'+ coalesce(cast(@slivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'slivept_8="'+ coalesce(cast(@slivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'v2spt_1="'+ coalesce(cast(@v2spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v2spt_2="'+ coalesce(cast(@v2spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v2spt_3="'+ coalesce(cast(@v2spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v2spt_7="'+ coalesce(cast(@v2spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'v2spt_8="'+ coalesce(cast(@v2spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'v2spt_9="'+ coalesce(cast(@v2spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'v2spt_20="'+ coalesce(cast(@v2spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v3spt_1="'+ coalesce(cast(@v3spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v3spt_2="'+ coalesce(cast(@v3spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v3spt_3="'+ coalesce(cast(@v3spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v3spt_20="'+ coalesce(cast(@v3spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v5spt_1="'+ coalesce(cast(@v5spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v5spt_2="'+ coalesce(cast(@v5spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v5spt_3="'+ coalesce(cast(@v5spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v5spt_20="'+ coalesce(cast(@v5spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v8spt_1="'+ coalesce(cast(@v8spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v8spt_3="'+ coalesce(cast(@v8spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v8spt_20="'+ coalesce(cast(@v8spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v10spt_1="'+ coalesce(cast(@v10spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v10spt_2="'+ coalesce(cast(@v10spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v10spt_3="'+ coalesce(cast(@v10spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v10spt_20="'+ coalesce(cast(@v10spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v11spt_1="'+ coalesce(cast(@v11spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v11spt_20="'+ coalesce(cast(@v11spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v99spt_1="'+ coalesce(cast(@v99spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v99spt_2="'+ coalesce(cast(@v99spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v99spt_3="'+ coalesce(cast(@v99spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v99spt_20="'+ coalesce(cast(@v99spositiontaking_20 as varchar(50)),space(1)) + '" />' +

'<au a_spt_1="'+ coalesce(cast(@auto_spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_spt_2="'+ coalesce(cast(@auto_spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_spt_3="'+ coalesce(cast(@auto_spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_spt_4="'+ coalesce(cast(@auto_spositiontaking_4 as varchar(50)),space(1)) + '" ' +
'a_spt_5="'+ coalesce(cast(@auto_spositiontaking_5 as varchar(50)),space(1)) + '" ' +
'a_spt_6="'+ coalesce(cast(@auto_spositiontaking_6 as varchar(50)),space(1)) + '" ' +
'a_spt_7="'+ coalesce(cast(@auto_spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_spt_8="'+ coalesce(cast(@auto_spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'a_spt_9="'+ coalesce(cast(@auto_spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'a_spt_10="'+ coalesce(cast(@auto_spositiontaking_10 as varchar(50)),space(1)) + '" ' +
'a_slivept_1="'+ coalesce(cast(@auto_slivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_slivept_3="'+ coalesce(cast(@auto_slivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_slivept_7="'+ coalesce(cast(@auto_slivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_slivept_8="'+ coalesce(cast(@auto_slivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'a_v2spt_1="'+ coalesce(cast(@auto_v2spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v2spt_2="'+ coalesce(cast(@auto_v2spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v2spt_3="'+ coalesce(cast(@auto_v2spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v2spt_7="'+ coalesce(cast(@auto_v2spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_v2spt_8="'+ coalesce(cast(@auto_v2spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'a_v2spt_9="'+ coalesce(cast(@auto_v2spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'a_v2spt_20="'+ coalesce(cast(@auto_v2spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v3spt_1="'+ coalesce(cast(@auto_v3spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v3spt_2="'+ coalesce(cast(@auto_v3spositiontaking_2 as varchar(50)),space(1))  + '" ' +
'a_v3spt_3="'+ coalesce(cast(@auto_v3spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v3spt_20="'+ coalesce(cast(@auto_v3spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v5spt_1="'+ coalesce(cast(@auto_v5spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v5spt_2="'+ coalesce(cast(@auto_v5spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v5spt_3="'+ coalesce(cast(@auto_v5spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v5spt_20="'+ coalesce(cast(@auto_v5spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v8spt_1="'+ coalesce(cast(@auto_v8spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v8spt_3="'+ coalesce(cast(@auto_v8spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v8spt_20="'+ coalesce(cast(@auto_v8spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v10spt_1="'+ coalesce(cast(@auto_v10spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v10spt_2="'+ coalesce(cast(@auto_v10spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v10spt_3="'+ coalesce(cast(@auto_v10spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v10spt_20="'+ coalesce(cast(@auto_v10spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v11spt_1="'+ coalesce(cast(@auto_v11spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v11spt_20="'+ coalesce(cast(@auto_v11spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v99spt_1="'+ coalesce(cast(@auto_v99spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v99spt_2="'+ coalesce(cast(@auto_v99spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v99spt_3="'+ coalesce(cast(@auto_v99spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v99spt_20="'+ coalesce(cast(@auto_v99spositiontaking_20 as varchar(50)),space(1)) + '" />' +

--i1
'<ia isa_spt_1="'+ coalesce(cast(@isauto_spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_spt_2="'+ coalesce(cast(@isauto_spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_spt_3="'+ coalesce(cast(@isauto_spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_spt_4="'+ coalesce(cast(@isauto_spositiontaking_4 as varchar(50)),space(1)) + '" ' +
'isa_spt_5="'+ coalesce(cast(@isauto_spositiontaking_5 as varchar(50)),space(1)) + '" ' +
'isa_spt_6="'+ coalesce(cast(@isauto_spositiontaking_6 as varchar(50)),space(1)) + '" ' +
'isa_spt_7="'+ coalesce(cast(@isauto_spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_spt_8="'+ coalesce(cast(@isauto_spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_spt_9="'+ coalesce(cast(@isauto_spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_spt_10="'+ coalesce(cast(@isauto_spositiontaking_10 as varchar(50)),space(1)) + '" ' +
'isa_slivept_1="'+ coalesce(cast(@isauto_slivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_slivept_3="'+ coalesce(cast(@isauto_slivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_slivept_7="'+ coalesce(cast(@isauto_slivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_slivept_8="'+ coalesce(cast(@isauto_slivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'isa_v2spt_1="'+ coalesce(cast(@isauto_v2spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_2="'+ coalesce(cast(@isauto_v2spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_3="'+ coalesce(cast(@isauto_v2spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_7="'+ coalesce(cast(@isauto_v2spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_8="'+ coalesce(cast(@isauto_v2spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_9="'+ coalesce(cast(@isauto_v2spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_20="'+ coalesce(cast(@isauto_v2spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v3spt_1="'+ coalesce(cast(@isauto_v3spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v3spt_2="'+ coalesce(cast(@isauto_v3spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v3spt_3="'+ coalesce(cast(@isauto_v3spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v3spt_20="'+ coalesce(cast(@isauto_v3spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v5spt_1="'+ coalesce(cast(@isauto_v5spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v5spt_2="'+ coalesce(cast(@isauto_v5spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v5spt_3="'+ coalesce(cast(@isauto_v5spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v5spt_20="'+ coalesce(cast(@isauto_v5spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v8spt_1="'+ coalesce(cast(@isauto_v8spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v8spt_3="'+ coalesce(cast(@isauto_v8spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v8spt_20="'+ coalesce(cast(@isauto_v8spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v10spt_1="'+ coalesce(cast(@isauto_v10spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v10spt_2="'+ coalesce(cast(@isauto_v10spositiontaking_2 as varchar(50)),space(1))  + '" ' +
'isa_v10spt_3="'+ coalesce(cast(@isauto_v10spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v10spt_20="'+ coalesce(cast(@isauto_v10spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v11spt_1="'+ coalesce(cast(@isauto_v11spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v11spt_20="'+ coalesce(cast(@isauto_v11spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v99spt_1="'+ coalesce(cast(@isauto_v99spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v99spt_2="'+ coalesce(cast(@isauto_v99spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v99spt_3="'+ coalesce(cast(@isauto_v99spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v99spt_20="'+ coalesce(cast(@isauto_v99spositiontaking_20 as varchar(50)),space(1)) + '" />' +

--i3
'<isau isa_smpt_1="'+ coalesce(cast(@isauto_smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_smpt_2="'+ coalesce(cast(@isauto_smpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_smpt_3="'+ coalesce(cast(@isauto_smpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_smpt_4="'+ coalesce(cast(@isauto_smpositiontaking_4 as varchar(50)),space(1)) + '" ' +
'isa_smpt_5="'+ coalesce(cast(@isauto_smpositiontaking_5 as varchar(50)),space(1)) + '" ' +
'isa_smpt_6="'+ coalesce(cast(@isauto_smpositiontaking_6 as varchar(50)),space(1)) + '" ' +
'isa_smpt_7="'+ coalesce(cast(@isauto_smpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_smpt_8="'+ coalesce(cast(@isauto_smpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_smpt_9="'+ coalesce(cast(@isauto_smpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_smpt_10="'+ coalesce(cast(@isauto_smpositiontaking_10 as varchar(50)),space(1)) + '" ' +
'isa_smlivept_1="'+ coalesce(cast(@isauto_smlivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_smlivept_3="'+ coalesce(cast(@isauto_smlivepositiontaking_3 as varchar(50)),space(1))  + '" ' +
'isa_smlivept_7="'+ coalesce(cast(@isauto_smlivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_smlivept_8="'+ coalesce(cast(@isauto_smlivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'isa_v2smpt_1="'+ coalesce(cast(@isauto_v2smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v2smpt_2="'+ coalesce(cast(@isauto_v2smpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v2smpt_3="'+ coalesce(cast(@isauto_v2smpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v2smpt_7="'+ coalesce(cast(@isauto_v2smpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_v2smpt_8="'+ coalesce(cast(@isauto_v2smpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_v2smpt_9="'+ coalesce(cast(@isauto_v2smpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_v2smpt_20="'+ coalesce(cast(@isauto_v2smpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v3smpt_1="'+ coalesce(cast(@isauto_v3smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v3smpt_2="'+ coalesce(cast(@isauto_v3smpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v3smpt_3="'+ coalesce(cast(@isauto_v3smpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v3smpt_20="'+ coalesce(cast(@isauto_v3smpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v5smpt_1="'+ coalesce(cast(@isauto_v5smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v5smpt_2="'+ coalesce(cast(@isauto_v5smpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v5smpt_3="'+ coalesce(cast(@isauto_v5smpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v5smpt_20="'+ coalesce(cast(@isauto_v5smpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v8smpt_1="'+ coalesce(cast(@isauto_v8smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v8smpt_3="'+ coalesce(cast(@isauto_v8smpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v8smpt_20="'+ coalesce(cast(@isauto_v8smpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v10smpt_1="'+ coalesce(cast(@isauto_v10smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v10smpt_2="'+ coalesce(cast(@isauto_v10smpositiontaking_2 as varchar(50)),space(1))  + '" ' +
'isa_v10smpt_3="'+ coalesce(cast(@isauto_v10smpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v10smpt_20="'+ coalesce(cast(@isauto_v10smpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v11smpt_1="'+ coalesce(cast(@isauto_v11smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v11smpt_20="'+ coalesce(cast(@isauto_v11smpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v99smpt_1="'+ coalesce(cast(@isauto_v99smpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v99smpt_2="'+ coalesce(cast(@isauto_v99smpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v99smpt_3="'+ coalesce(cast(@isauto_v99smpositiontaking_3 as varchar(50)),space(1))  + '" ' +
'isa_v99smpt_20="'+ coalesce(cast(@isauto_v99smpositiontaking_20 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMember_Super>'

	
--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 404,
	@TrackingValue = @LogSPData
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Super] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Super] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMember_Super] TO [vnteam]