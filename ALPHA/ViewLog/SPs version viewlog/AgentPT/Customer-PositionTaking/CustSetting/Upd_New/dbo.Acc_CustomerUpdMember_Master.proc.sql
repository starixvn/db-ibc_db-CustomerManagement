ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_Master] 
	@CustID INT,--memberid
	@Closed BIT = null,
	@UpdateClosed bit = 0,
	@suspended BIT =NULL,
	@UpdateSuspended BIT =0, 	
	@disCasino bit = 0,
	
	--m1
	@mpositiontaking_1 SMALLMONEY OUTPUT,
	@mpositiontaking_2 SMALLMONEY OUTPUT,
	@mpositiontaking_3 SMALLMONEY OUTPUT,
	@mpositiontaking_4 SMALLMONEY OUTPUT,
	@mpositiontaking_5 SMALLMONEY OUTPUT,
	@mpositiontaking_6 SMALLMONEY OUTPUT,
	@mpositiontaking_7 SMALLMONEY OUTPUT,
	@mpositiontaking_8 SMALLMONEY OUTPUT,
	@mpositiontaking_9 SMALLMONEY OUTPUT,
	@mpositiontaking_10 SMALLMONEY OUTPUT,
	@mlivepositiontaking_1 SMALLMONEY OUTPUT,
	@mlivepositiontaking_3 SMALLMONEY OUTPUT,
	@mlivepositiontaking_7 SMALLMONEY OUTPUT,
	@mlivepositiontaking_8 SMALLMONEY OUTPUT,
	
	@v2mpositiontaking_1 SMALLMONEY OUTPUT,
	@v2mpositiontaking_2 SMALLMONEY OUTPUT,
	@v2mpositiontaking_3 SMALLMONEY OUTPUT,
	@v2mpositiontaking_7 SMALLMONEY OUTPUT,
	@v2mpositiontaking_8 SMALLMONEY OUTPUT,
	@v2mpositiontaking_9 SMALLMONEY OUTPUT,
	@v2mpositiontaking_20 SMALLMONEY OUTPUT,

	@v3mpositiontaking_1 SMALLMONEY OUTPUT,
	@v3mpositiontaking_2 SMALLMONEY OUTPUT,
	@v3mpositiontaking_3 SMALLMONEY OUTPUT,
	@v3mpositiontaking_20 SMALLMONEY OUTPUT,

	@v5mpositiontaking_1 SMALLMONEY OUTPUT,
	@v5mpositiontaking_2 SMALLMONEY OUTPUT,
	@v5mpositiontaking_3 SMALLMONEY OUTPUT,
	@v5mpositiontaking_20 SMALLMONEY OUTPUT,

	@v8mpositiontaking_1 SMALLMONEY OUTPUT,
	@v8mpositiontaking_3 SMALLMONEY OUTPUT,
	@v8mpositiontaking_20 SMALLMONEY OUTPUT,

	@v10mpositiontaking_1 SMALLMONEY OUTPUT,
	@v10mpositiontaking_2 SMALLMONEY OUTPUT,
	@v10mpositiontaking_3 SMALLMONEY OUTPUT,
	@v10mpositiontaking_20 SMALLMONEY OUTPUT,

	@v11mpositiontaking_1 SMALLMONEY OUTPUT,
	@v11mpositiontaking_20 SMALLMONEY OUTPUT,

	@v99mpositiontaking_1 SMALLMONEY OUTPUT,
	@v99mpositiontaking_2 SMALLMONEY OUTPUT,
	@v99mpositiontaking_3 SMALLMONEY OUTPUT,
	@v99mpositiontaking_20 SMALLMONEY OUTPUT,
	--im2
	@isauto_mpositiontaking_1 BIT = 0,
	@isauto_mpositiontaking_2 BIT = 0,
	@isauto_mpositiontaking_3 BIT = 0,
	@isauto_mpositiontaking_4 BIT = 0,
	@isauto_mpositiontaking_5 BIT= 0,
	@isauto_mpositiontaking_6 BIT = 0,
	@isauto_mpositiontaking_7 BIT = 0,
	@isauto_mpositiontaking_8 BIT = 0,
	@isauto_mpositiontaking_9 BIT = 0,
	@isauto_mpositiontaking_10 BIT = 0,
	@isauto_mlivepositiontaking_1 BIT = 0,
	@isauto_mlivepositiontaking_3 BIT = 0,
	@isauto_mlivepositiontaking_7 BIT = 0,
	@isauto_mlivepositiontaking_8 BIT = 0,
	
	@isauto_v2mpositiontaking_1 BIT = 0,
	@isauto_v2mpositiontaking_2 BIT = 0,
	@isauto_v2mpositiontaking_3 BIT = 0,
	@isauto_v2mpositiontaking_7 BIT = 0,
	@isauto_v2mpositiontaking_8 BIT = 0,
	@isauto_v2mpositiontaking_9 BIT = 0,
	@isauto_v2mpositiontaking_20 BIT = 0,
	
	@isauto_v3mpositiontaking_1 BIT = 0,
	@isauto_v3mpositiontaking_2 BIT = 0,
	@isauto_v3mpositiontaking_3 BIT = 0,
	@isauto_v3mpositiontaking_20 BIT = 0,
	
	@isauto_v5mpositiontaking_1 BIT = 0,
	@isauto_v5mpositiontaking_2 BIT = 0,
	@isauto_v5mpositiontaking_3 BIT = 0,
	@isauto_v5mpositiontaking_20 BIT = 0,
	
	@isauto_v8mpositiontaking_1 BIT = 0,
	@isauto_v8mpositiontaking_3 BIT = 0,
	@isauto_v8mpositiontaking_20 BIT = 0,
	
	@isauto_v10mpositiontaking_1 BIT = 0,
	@isauto_v10mpositiontaking_2 BIT = 0,
	@isauto_v10mpositiontaking_3 BIT = 0,
	@isauto_v10mpositiontaking_20 BIT = 0,
	
	@isauto_v11mpositiontaking_1 BIT = 0,
	@isauto_v11mpositiontaking_20 BIT = 0,

	@isauto_v99mpositiontaking_1 BIT = 0,
	@isauto_v99mpositiontaking_2 BIT = 0,
	@isauto_v99mpositiontaking_3 BIT = 0,
	@isauto_v99mpositiontaking_20 BIT = 0,	
	
	--im1
	@isauto_mpositiontaking_mem_1 BIT = 0,
	@isauto_mpositiontaking_mem_2 BIT = 0,
	@isauto_mpositiontaking_mem_3 BIT = 0,
	@isauto_mpositiontaking_mem_4 BIT = 0,
	@isauto_mpositiontaking_mem_5 BIT= 0,
	@isauto_mpositiontaking_mem_6 BIT = 0,
	@isauto_mpositiontaking_mem_7 BIT = 0,
	@isauto_mpositiontaking_mem_8 BIT = 0,
	@isauto_mpositiontaking_mem_9 BIT = 0,
	@isauto_mpositiontaking_mem_10 BIT = 0,
	@isauto_mlivepositiontaking_mem_1 BIT = 0,
	@isauto_mlivepositiontaking_mem_3 BIT = 0,
	@isauto_mlivepositiontaking_mem_7 BIT = 0,
	@isauto_mlivepositiontaking_mem_8 BIT = 0,
	
	@isauto_v2mpositiontaking_mem_1 BIT = 0,
	@isauto_v2mpositiontaking_mem_2 BIT = 0,
	@isauto_v2mpositiontaking_mem_3 BIT = 0,
	@isauto_v2mpositiontaking_mem_7 BIT = 0,
	@isauto_v2mpositiontaking_mem_8 BIT = 0,
	@isauto_v2mpositiontaking_mem_9 BIT = 0,
	@isauto_v2mpositiontaking_mem_20 BIT = 0,
	
	@isauto_v3mpositiontaking_mem_1 BIT = 0,
	@isauto_v3mpositiontaking_mem_2 BIT = 0,
	@isauto_v3mpositiontaking_mem_3 BIT = 0,
	@isauto_v3mpositiontaking_mem_20 BIT = 0,
	
	@isauto_v5mpositiontaking_mem_1 BIT = 0,
	@isauto_v5mpositiontaking_mem_2 BIT = 0,
	@isauto_v5mpositiontaking_mem_3 BIT = 0,
	@isauto_v5mpositiontaking_mem_20 BIT = 0,
	
	@isauto_v8mpositiontaking_mem_1 BIT = 0,
	@isauto_v8mpositiontaking_mem_3 BIT = 0,
	@isauto_v8mpositiontaking_mem_20 BIT = 0,
	
	@isauto_v10mpositiontaking_mem_1 BIT = 0,
	@isauto_v10mpositiontaking_mem_2 BIT = 0,
	@isauto_v10mpositiontaking_mem_3 BIT = 0,
	@isauto_v10mpositiontaking_mem_20 BIT = 0,
	
	@isauto_v11mpositiontaking_mem_1 BIT = 0,
	@isauto_v11mpositiontaking_mem_20 BIT = 0,

	@isauto_v99mpositiontaking_mem_1 BIT = 0,
	@isauto_v99mpositiontaking_mem_2 BIT = 0,
	@isauto_v99mpositiontaking_mem_3 BIT = 0,
	@isauto_v99mpositiontaking_mem_20 BIT = 0,	

	--um1
	@auto_mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_2 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_3 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_4 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_5 SMALLMONEY= 0,
	@auto_mpositiontaking_mem_6 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_7 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_8 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_9 SMALLMONEY = 0,
	@auto_mpositiontaking_mem_10 SMALLMONEY = 0,
	@auto_mlivepositiontaking_mem_1 SMALLMONEY = 0,
	@auto_mlivepositiontaking_mem_3 SMALLMONEY = 0,
	@auto_mlivepositiontaking_mem_7 SMALLMONEY = 0,
	@auto_mlivepositiontaking_mem_8 SMALLMONEY = 0,
	
	@auto_v2mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_v2mpositiontaking_mem_2 SMALLMONEY = 0,
	@auto_v2mpositiontaking_mem_3 SMALLMONEY = 0,
	@auto_v2mpositiontaking_mem_7 SMALLMONEY = 0,
	@auto_v2mpositiontaking_mem_8 SMALLMONEY = 0,
	@auto_v2mpositiontaking_mem_9 SMALLMONEY = 0,
	@auto_v2mpositiontaking_mem_20 SMALLMONEY = 0,
	
	@auto_v3mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_v3mpositiontaking_mem_2 SMALLMONEY = 0,
	@auto_v3mpositiontaking_mem_3 SMALLMONEY = 0,
	@auto_v3mpositiontaking_mem_20 SMALLMONEY = 0,
	
	@auto_v5mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_v5mpositiontaking_mem_2 SMALLMONEY = 0,
	@auto_v5mpositiontaking_mem_3 SMALLMONEY = 0,
	@auto_v5mpositiontaking_mem_20 SMALLMONEY = 0,
	
	@auto_v8mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_v8mpositiontaking_mem_3 SMALLMONEY = 0,
	@auto_v8mpositiontaking_mem_20 SMALLMONEY = 0,
	
	@auto_v10mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_v10mpositiontaking_mem_2 SMALLMONEY = 0,
	@auto_v10mpositiontaking_mem_3 SMALLMONEY = 0,
	@auto_v10mpositiontaking_mem_20 SMALLMONEY = 0,
	
	@auto_v11mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_v11mpositiontaking_mem_20 SMALLMONEY = 0,

	@auto_v99mpositiontaking_mem_1 SMALLMONEY = 0,
	@auto_v99mpositiontaking_mem_2 SMALLMONEY = 0,
	@auto_v99mpositiontaking_mem_3 SMALLMONEY = 0,
	@auto_v99mpositiontaking_mem_20 SMALLMONEY = 0,	

	@UserID INT,--masterid	
	
	@Language VARCHAR(2) = 'E',
	@SubAccID INT = 0, --Sub-AccountID
	@IP VARCHAR(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090122@[creator]
Task : Master edit member
DB: DB02.bodb02
Original: [Acc_CustomerUpdMaster_Member]

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3, hard code copy min/max/maxperbet/PT for 201 from 2 sporttype 
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
				Write log subaccname instead of subaccid.
    - 20090616@Phuc: Auto master PT on member level.
					 Enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	- 20090801@Shifu: check disabled user
	- 20090806@Phuc: remove check m1=min(m3-a2,m1)
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091125@Terry: check disabled casino
	- 20100112@Kiwi: Amend to write log in xml format.
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
DECLARE @ErrType varchar(1000), @ErrCode_cur int, @ErrMsg_cur NVARCHAR(4000)
SELECT @ErrCode_cur = 0, @ErrMsg_cur = '', @ErrCode = '', @ErrMsg = ''

DECLARE @old_closed BIT,
	@old_suspended BIT,	
	@recommend INT,
	@mrecommend INT,
	@srecommend INT
	
SELECT @old_closed = closed, @old_suspended= reject ,@recommend = recommend, @mrecommend = mrecommend, @srecommend = srecommend, @UserName = username
FROM custinfo WITH (NOLOCK) WHERE custid = @custid

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode_Cur output,@ErrMsg=@ErrMsg_Cur output
IF @ErrCode_Cur > 0
BEGIN
	select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
--end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check parameter

DECLARE @IsValid BIT

SELECT @isvalid = 1
IF 
	@mpositiontaking_1  <0
	OR @mpositiontaking_2  <0
	OR @mpositiontaking_3  <0
	OR @mpositiontaking_4  <0
	OR @mpositiontaking_5  <0
	OR @mpositiontaking_6  <0
	OR @mpositiontaking_7  <0
	OR @mpositiontaking_8  <0
	OR @mpositiontaking_9  <0
	OR @mpositiontaking_10 <0
	OR @mlivepositiontaking_1  <0
	OR @mlivepositiontaking_3  <0
	OR @mlivepositiontaking_7  <0
	OR @mlivepositiontaking_8  <0
	OR @mpositiontaking_1  >0.9
	OR @mpositiontaking_2  >0.9
	OR @mpositiontaking_3  >0.9
	OR @mpositiontaking_4  >0.9
	OR @mpositiontaking_5  >0.9
	OR @mpositiontaking_6  >0.9
	OR @mpositiontaking_7  >0.9
	OR @mpositiontaking_8  >0.9
	OR @mpositiontaking_9  >0.9
	OR @mpositiontaking_10 >0.9
	OR @mlivepositiontaking_1  >0.9
	OR @mlivepositiontaking_3  >0.9
	OR @mlivepositiontaking_7  >0.9
	OR @mlivepositiontaking_8  >0.9
	
	
	OR @v2mpositiontaking_1 <0
	OR @v2mpositiontaking_2 <0
	OR @v2mpositiontaking_3 <0
	OR @v2mpositiontaking_7 <0
	OR @v2mpositiontaking_8 <0
	OR @v2mpositiontaking_9 <0
	OR @v2mpositiontaking_20 <0

	OR @v3mpositiontaking_1 <0
	OR @v3mpositiontaking_2 <0
	OR @v3mpositiontaking_3 <0
	OR @v3mpositiontaking_20 <0

	OR @v5mpositiontaking_1 <0
	OR @v5mpositiontaking_2 <0
	OR @v5mpositiontaking_3 <0
	OR @v5mpositiontaking_20 <0

	OR @v8mpositiontaking_1 <0
	OR @v8mpositiontaking_3 <0
	OR @v8mpositiontaking_20 <0

	OR @v10mpositiontaking_1 <0
	OR @v10mpositiontaking_2 <0
	OR @v10mpositiontaking_3 <0
	OR @v10mpositiontaking_20 <0

	OR @v11mpositiontaking_1 <0
	OR @v11mpositiontaking_20 <0

	OR @v99mpositiontaking_1 <0
	OR @v99mpositiontaking_2 <0
	OR @v99mpositiontaking_3 <0
	OR @v99mpositiontaking_20 <0
	
	OR @v2mpositiontaking_1 >0.9
	OR @v2mpositiontaking_2 >0.9
	OR @v2mpositiontaking_3 >0.9
	OR @v2mpositiontaking_7 >0.9
	OR @v2mpositiontaking_8 >0.9
	OR @v2mpositiontaking_9 >0.9
	OR @v2mpositiontaking_20 >0.9

	OR @v3mpositiontaking_1 >0.9
	OR @v3mpositiontaking_2 >0.9
	OR @v3mpositiontaking_3 >0.9
	OR @v3mpositiontaking_20 >0.9

	OR @v5mpositiontaking_1 >0.9
	OR @v5mpositiontaking_2 >0.9
	OR @v5mpositiontaking_3 >0.9
	OR @v5mpositiontaking_20 >0.9

	OR @v8mpositiontaking_1 >0.9
	OR @v8mpositiontaking_3 >0.9
	OR @v8mpositiontaking_20 >0.9

	OR @v10mpositiontaking_1 >0.9
	OR @v10mpositiontaking_2 >0.9
	OR @v10mpositiontaking_3 >0.9
	OR @v10mpositiontaking_20 >0.9

	OR @v11mpositiontaking_1 >0.9
	OR @v11mpositiontaking_20 >0.9

	OR @v99mpositiontaking_1 >0.9
	OR @v99mpositiontaking_2 >0.9
	OR @v99mpositiontaking_3 >0.9
	OR @v99mpositiontaking_20 >0.9
BEGIN
	SELECT @isvalid = 0, @ErrCode_cur = 5
	SELECT @ErrMsg_cur = 	CASE @Language 
						WHEN 'E' THEN 'Wrong position taking.'
						WHEN 'CS' THEN N'占成数不正确.'
						WHEN 'CT' THEN N'佔成數不正確.'
						WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง.'
						WHEN 'J' THEN N'Wrong position taking.'
						WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다.'
						ELSE N'Wrong position taking.'
				END
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
			
	RETURN
END

IF @IsValid = 0
BEGIN
	RAISERROR (@ErrMsg, 16, 1)
	RETURN
END

DECLARE 
	--a1
	@apositiontaking_1 SMALLMONEY,
	@apositiontaking_2 SMALLMONEY,
	@apositiontaking_3 SMALLMONEY,
	@apositiontaking_4 SMALLMONEY,
	@apositiontaking_5 SMALLMONEY,
	@apositiontaking_6 SMALLMONEY,
	@apositiontaking_7 SMALLMONEY,
	@apositiontaking_8 SMALLMONEY,
	@apositiontaking_9 SMALLMONEY,
	@apositiontaking_10 SMALLMONEY,
	@alivepositiontaking_1 SMALLMONEY,
	@alivepositiontaking_3 SMALLMONEY,
	@alivepositiontaking_7 SMALLMONEY,
	@alivepositiontaking_8 SMALLMONEY,
	
	@v2apositiontaking_1 SMALLMONEY,
	@v2apositiontaking_2 SMALLMONEY,
	@v2apositiontaking_3 SMALLMONEY,
	@v2apositiontaking_7 SMALLMONEY,
	@v2apositiontaking_8 SMALLMONEY,
	@v2apositiontaking_9 SMALLMONEY,
	@v2apositiontaking_20 SMALLMONEY,

	@v3apositiontaking_1 SMALLMONEY,
	@v3apositiontaking_2 SMALLMONEY,
	@v3apositiontaking_3 SMALLMONEY,
	@v3apositiontaking_20 SMALLMONEY,

	@v5apositiontaking_1 SMALLMONEY,
	@v5apositiontaking_2 SMALLMONEY,
	@v5apositiontaking_3 SMALLMONEY,
	@v5apositiontaking_20 SMALLMONEY,

	@v8apositiontaking_1 SMALLMONEY,
	@v8apositiontaking_3 SMALLMONEY,
	@v8apositiontaking_20 SMALLMONEY,

	@v10apositiontaking_1 SMALLMONEY,
	@v10apositiontaking_2 SMALLMONEY,
	@v10apositiontaking_3 SMALLMONEY,
	@v10apositiontaking_20 SMALLMONEY,

	@v11apositiontaking_1 SMALLMONEY,
	@v11apositiontaking_20 SMALLMONEY,
	
	@v99apositiontaking_1 SMALLMONEY,
	@v99apositiontaking_2 SMALLMONEY,
	@v99apositiontaking_3 SMALLMONEY,
	@v99apositiontaking_20 SMALLMONEY,
	
	--a2
	@max_apositiontaking_1 SMALLMONEY,
	@max_apositiontaking_2 SMALLMONEY,
	@max_apositiontaking_3 SMALLMONEY,
	@max_apositiontaking_4 SMALLMONEY,
	@max_apositiontaking_5 SMALLMONEY,
	@max_apositiontaking_6 SMALLMONEY,
	@max_apositiontaking_7 SMALLMONEY,
	@max_apositiontaking_8 SMALLMONEY,
	@max_apositiontaking_9 SMALLMONEY,
	@max_apositiontaking_10 SMALLMONEY,
	@max_alivepositiontaking_1 SMALLMONEY,
	@max_alivepositiontaking_3 SMALLMONEY,
	@max_alivepositiontaking_7 SMALLMONEY,
	@max_alivepositiontaking_8 SMALLMONEY,
	
	@max_v2apositiontaking_1 SMALLMONEY,
	@max_v2apositiontaking_2 SMALLMONEY,
	@max_v2apositiontaking_3 SMALLMONEY,
	@max_v2apositiontaking_7 SMALLMONEY,
	@max_v2apositiontaking_8 SMALLMONEY,
	@max_v2apositiontaking_9 SMALLMONEY,
	@max_v2apositiontaking_20 SMALLMONEY,

	@max_v3apositiontaking_1 SMALLMONEY,
	@max_v3apositiontaking_2 SMALLMONEY,
	@max_v3apositiontaking_3 SMALLMONEY,
	@max_v3apositiontaking_20 SMALLMONEY,

	@max_v5apositiontaking_1 SMALLMONEY,
	@max_v5apositiontaking_2 SMALLMONEY,
	@max_v5apositiontaking_3 SMALLMONEY,
	@max_v5apositiontaking_20 SMALLMONEY,

	@max_v8apositiontaking_1 SMALLMONEY,
	@max_v8apositiontaking_3 SMALLMONEY,
	@max_v8apositiontaking_20 SMALLMONEY,

	@max_v10apositiontaking_1 SMALLMONEY,
	@max_v10apositiontaking_2 SMALLMONEY,
	@max_v10apositiontaking_3 SMALLMONEY,
	@max_v10apositiontaking_20 SMALLMONEY,

	@max_v11apositiontaking_1 SMALLMONEY,
	@max_v11apositiontaking_20 SMALLMONEY,
	
	@max_v99apositiontaking_1 SMALLMONEY,
	@max_v99apositiontaking_2 SMALLMONEY,
	@max_v99apositiontaking_3 SMALLMONEY,
	@max_v99apositiontaking_20 SMALLMONEY,
	
	--old_m1	
	@old_mpositiontaking_1 SMALLMONEY,
	@old_mpositiontaking_2 SMALLMONEY,
	@old_mpositiontaking_3 SMALLMONEY,
	@old_mpositiontaking_4 SMALLMONEY,
	@old_mpositiontaking_5 SMALLMONEY,
	@old_mpositiontaking_6 SMALLMONEY,
	@old_mpositiontaking_7 SMALLMONEY,
	@old_mpositiontaking_8 SMALLMONEY,
	@old_mpositiontaking_9 SMALLMONEY,
	@old_mpositiontaking_10 SMALLMONEY,
	
	@old_mlivepositiontaking_1 SMALLMONEY,
	@old_mlivepositiontaking_3 SMALLMONEY,
	@old_mlivepositiontaking_7 SMALLMONEY,
	@old_mlivepositiontaking_8 SMALLMONEY,
	
	@old_v2mpositiontaking_1 SMALLMONEY,
	@old_v2mpositiontaking_2 SMALLMONEY,
	@old_v2mpositiontaking_3 SMALLMONEY,
	@old_v2mpositiontaking_7 SMALLMONEY,
	@old_v2mpositiontaking_8 SMALLMONEY,
	@old_v2mpositiontaking_9 SMALLMONEY,
	@old_v2mpositiontaking_20 SMALLMONEY,

	@old_v3mpositiontaking_1 SMALLMONEY,
	@old_v3mpositiontaking_2 SMALLMONEY,
	@old_v3mpositiontaking_3 SMALLMONEY,
	@old_v3mpositiontaking_20 SMALLMONEY,

	@old_v5mpositiontaking_1 SMALLMONEY,
	@old_v5mpositiontaking_2 SMALLMONEY,
	@old_v5mpositiontaking_3 SMALLMONEY,
	@old_v5mpositiontaking_20 SMALLMONEY,

	@old_v8mpositiontaking_1 SMALLMONEY,
	@old_v8mpositiontaking_3 SMALLMONEY,
	@old_v8mpositiontaking_20 SMALLMONEY,

	@old_v10mpositiontaking_1 SMALLMONEY,
	@old_v10mpositiontaking_2 SMALLMONEY,
	@old_v10mpositiontaking_3 SMALLMONEY,
	@old_v10mpositiontaking_20 SMALLMONEY,

	@old_v11mpositiontaking_1 SMALLMONEY,
	@old_v11mpositiontaking_20 SMALLMONEY,

	@old_v99mpositiontaking_1 SMALLMONEY,
	@old_v99mpositiontaking_2 SMALLMONEY,
	@old_v99mpositiontaking_3 SMALLMONEY,
	@old_v99mpositiontaking_20 SMALLMONEY,
	
	--old_um1
	@old_auto_mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_mpositiontaking_mem_2 SMALLMONEY,
	@old_auto_mpositiontaking_mem_3 SMALLMONEY,
	@old_auto_mpositiontaking_mem_4 SMALLMONEY,
	@old_auto_mpositiontaking_mem_5 SMALLMONEY,
	@old_auto_mpositiontaking_mem_6 SMALLMONEY,
	@old_auto_mpositiontaking_mem_7 SMALLMONEY,
	@old_auto_mpositiontaking_mem_8 SMALLMONEY,
	@old_auto_mpositiontaking_mem_9 SMALLMONEY,
	@old_auto_mpositiontaking_mem_10 SMALLMONEY,
	
	@old_auto_mlivepositiontaking_mem_1 SMALLMONEY,
	@old_auto_mlivepositiontaking_mem_3 SMALLMONEY,
	@old_auto_mlivepositiontaking_mem_7 SMALLMONEY,
	@old_auto_mlivepositiontaking_mem_8 SMALLMONEY,
	
	@old_auto_v2mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_v2mpositiontaking_mem_2 SMALLMONEY,
	@old_auto_v2mpositiontaking_mem_3 SMALLMONEY,
	@old_auto_v2mpositiontaking_mem_7 SMALLMONEY,
	@old_auto_v2mpositiontaking_mem_8 SMALLMONEY,
	@old_auto_v2mpositiontaking_mem_9 SMALLMONEY,
	@old_auto_v2mpositiontaking_mem_20 SMALLMONEY,

	@old_auto_v3mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_v3mpositiontaking_mem_2 SMALLMONEY,
	@old_auto_v3mpositiontaking_mem_3 SMALLMONEY,
	@old_auto_v3mpositiontaking_mem_20 SMALLMONEY,

	@old_auto_v5mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_v5mpositiontaking_mem_2 SMALLMONEY,
	@old_auto_v5mpositiontaking_mem_3 SMALLMONEY,
	@old_auto_v5mpositiontaking_mem_20 SMALLMONEY,

	@old_auto_v8mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_v8mpositiontaking_mem_3 SMALLMONEY,
	@old_auto_v8mpositiontaking_mem_20 SMALLMONEY,

	@old_auto_v10mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_v10mpositiontaking_mem_2 SMALLMONEY,
	@old_auto_v10mpositiontaking_mem_3 SMALLMONEY,
	@old_auto_v10mpositiontaking_mem_20 SMALLMONEY,

	@old_auto_v11mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_v11mpositiontaking_mem_20 SMALLMONEY,

	@old_auto_v99mpositiontaking_mem_1 SMALLMONEY,
	@old_auto_v99mpositiontaking_mem_2 SMALLMONEY,
	@old_auto_v99mpositiontaking_mem_3 SMALLMONEY,
	@old_auto_v99mpositiontaking_mem_20 SMALLMONEY,
	
	--old_im1
	@old_isauto_mpositiontaking_mem_1 BIT,
	@old_isauto_mpositiontaking_mem_2 BIT,
	@old_isauto_mpositiontaking_mem_3 BIT,
	@old_isauto_mpositiontaking_mem_4 BIT,
	@old_isauto_mpositiontaking_mem_5 BIT,
	@old_isauto_mpositiontaking_mem_6 BIT,
	@old_isauto_mpositiontaking_mem_7 BIT,
	@old_isauto_mpositiontaking_mem_8 BIT,
	@old_isauto_mpositiontaking_mem_9 BIT,
	@old_isauto_mpositiontaking_mem_10 BIT,
	
	@old_isauto_mlivepositiontaking_mem_1 BIT,
	@old_isauto_mlivepositiontaking_mem_3 BIT,
	@old_isauto_mlivepositiontaking_mem_7 BIT,
	@old_isauto_mlivepositiontaking_mem_8 BIT,
	
	@old_isauto_v2mpositiontaking_mem_1 BIT,
	@old_isauto_v2mpositiontaking_mem_2 BIT,
	@old_isauto_v2mpositiontaking_mem_3 BIT,
	@old_isauto_v2mpositiontaking_mem_7 BIT,
	@old_isauto_v2mpositiontaking_mem_8 BIT,
	@old_isauto_v2mpositiontaking_mem_9 BIT,
	@old_isauto_v2mpositiontaking_mem_20 BIT,

	@old_isauto_v3mpositiontaking_mem_1 BIT,
	@old_isauto_v3mpositiontaking_mem_2 BIT,
	@old_isauto_v3mpositiontaking_mem_3 BIT,
	@old_isauto_v3mpositiontaking_mem_20 BIT,

	@old_isauto_v5mpositiontaking_mem_1 BIT,
	@old_isauto_v5mpositiontaking_mem_2 BIT,
	@old_isauto_v5mpositiontaking_mem_3 BIT,
	@old_isauto_v5mpositiontaking_mem_20 BIT,

	@old_isauto_v8mpositiontaking_mem_1 BIT,
	@old_isauto_v8mpositiontaking_mem_3 BIT,
	@old_isauto_v8mpositiontaking_mem_20 BIT,

	@old_isauto_v10mpositiontaking_mem_1 BIT,
	@old_isauto_v10mpositiontaking_mem_2 BIT,
	@old_isauto_v10mpositiontaking_mem_3 BIT,
	@old_isauto_v10mpositiontaking_mem_20 BIT,

	@old_isauto_v11mpositiontaking_mem_1 BIT,
	@old_isauto_v11mpositiontaking_mem_20 BIT,

	@old_isauto_v99mpositiontaking_mem_1 BIT,
	@old_isauto_v99mpositiontaking_mem_2 BIT,
	@old_isauto_v99mpositiontaking_mem_3 BIT,
	@old_isauto_v99mpositiontaking_mem_20 BIT,


	--@maxpos smallmoney,
	--s4
	@max_spositiontaking_1 SMALLMONEY,
	@max_spositiontaking_2 SMALLMONEY,
	@max_spositiontaking_3 SMALLMONEY,
	@max_spositiontaking_4 SMALLMONEY,
	@max_spositiontaking_5 SMALLMONEY,
	@max_spositiontaking_6 SMALLMONEY,
	@max_spositiontaking_7 SMALLMONEY,
	@max_spositiontaking_8 SMALLMONEY,
	@max_spositiontaking_9 SMALLMONEY,
	@max_spositiontaking_10 SMALLMONEY,
	
	@max_slivepositiontaking_1 SMALLMONEY,
	@max_slivepositiontaking_3 SMALLMONEY,
	@max_slivepositiontaking_7 SMALLMONEY,
	@max_slivepositiontaking_8 SMALLMONEY,
	
	@max_v2spositiontaking_1 SMALLMONEY,
	@max_v2spositiontaking_2 SMALLMONEY,
	@max_v2spositiontaking_3 SMALLMONEY,
	@max_v2spositiontaking_7 SMALLMONEY,
	@max_v2spositiontaking_8 SMALLMONEY,
	@max_v2spositiontaking_9 SMALLMONEY,
	@max_v2spositiontaking_20 SMALLMONEY,

	@max_v3spositiontaking_1 SMALLMONEY,
	@max_v3spositiontaking_2 SMALLMONEY,
	@max_v3spositiontaking_3 SMALLMONEY,
	@max_v3spositiontaking_20 SMALLMONEY,

	@max_v5spositiontaking_1 SMALLMONEY,
	@max_v5spositiontaking_2 SMALLMONEY,
	@max_v5spositiontaking_3 SMALLMONEY,
	@max_v5spositiontaking_20 SMALLMONEY,

	@max_v8spositiontaking_1 SMALLMONEY,
	@max_v8spositiontaking_3 SMALLMONEY,
	@max_v8spositiontaking_20 SMALLMONEY,

	@max_v10spositiontaking_1 SMALLMONEY,
	@max_v10spositiontaking_2 SMALLMONEY,
	@max_v10spositiontaking_3 SMALLMONEY,
	@max_v10spositiontaking_20 SMALLMONEY,

	@max_v11spositiontaking_1 SMALLMONEY,
	@max_v11spositiontaking_20 SMALLMONEY,

	@max_v99spositiontaking_1 SMALLMONEY,
	@max_v99spositiontaking_2 SMALLMONEY,
	@max_v99spositiontaking_3 SMALLMONEY,
	@max_v99spositiontaking_20 SMALLMONEY,
	
	@spositiontaking_1 SMALLMONEY,
	@spositiontaking_2 SMALLMONEY,
	@spositiontaking_3 SMALLMONEY,
	@spositiontaking_4 SMALLMONEY,
	@spositiontaking_5 SMALLMONEY,
	@spositiontaking_6 SMALLMONEY,
	@spositiontaking_7 SMALLMONEY,
	@spositiontaking_8 SMALLMONEY,
	@spositiontaking_9 SMALLMONEY,
	@spositiontaking_10 SMALLMONEY,
	
	@slivepositiontaking_1 SMALLMONEY,
	@slivepositiontaking_3 SMALLMONEY,
	@slivepositiontaking_7 SMALLMONEY,
	@slivepositiontaking_8 SMALLMONEY,
	
	@v2spositiontaking_1 SMALLMONEY,
	@v2spositiontaking_2 SMALLMONEY,
	@v2spositiontaking_3 SMALLMONEY,
	@v2spositiontaking_7 SMALLMONEY,
	@v2spositiontaking_8 SMALLMONEY,
	@v2spositiontaking_9 SMALLMONEY,
	@v2spositiontaking_20 SMALLMONEY,

	@v3spositiontaking_1 SMALLMONEY,
	@v3spositiontaking_2 SMALLMONEY,
	@v3spositiontaking_3 SMALLMONEY,
	@v3spositiontaking_20 SMALLMONEY,

	@v5spositiontaking_1 SMALLMONEY,
	@v5spositiontaking_2 SMALLMONEY,
	@v5spositiontaking_3 SMALLMONEY,
	@v5spositiontaking_20 SMALLMONEY,

	@v8spositiontaking_1 SMALLMONEY,
	@v8spositiontaking_3 SMALLMONEY,
	@v8spositiontaking_20 SMALLMONEY,

	@v10spositiontaking_1 SMALLMONEY,
	@v10spositiontaking_2 SMALLMONEY,
	@v10spositiontaking_3 SMALLMONEY,
	@v10spositiontaking_20 SMALLMONEY,

	@v11spositiontaking_1 SMALLMONEY,
	@v11spositiontaking_20 SMALLMONEY,

	@v99spositiontaking_1 SMALLMONEY,
	@v99spositiontaking_2 SMALLMONEY,
	@v99spositiontaking_3 SMALLMONEY,
	@v99spositiontaking_20 SMALLMONEY,	
	--u1
	@auto_spositiontaking_mem_1 SMALLMONEY,
	@auto_spositiontaking_mem_2 SMALLMONEY,
	@auto_spositiontaking_mem_3 SMALLMONEY,
	@auto_spositiontaking_mem_4 SMALLMONEY,
	@auto_spositiontaking_mem_5 SMALLMONEY,
	@auto_spositiontaking_mem_6 SMALLMONEY,
	@auto_spositiontaking_mem_7 SMALLMONEY,
	@auto_spositiontaking_mem_8 SMALLMONEY,
	@auto_spositiontaking_mem_9 SMALLMONEY,
	@auto_spositiontaking_mem_10 SMALLMONEY,
	
	@auto_slivepositiontaking_mem_1 SMALLMONEY,
	@auto_slivepositiontaking_mem_3 SMALLMONEY,
	@auto_slivepositiontaking_mem_7 SMALLMONEY,
	@auto_slivepositiontaking_mem_8 SMALLMONEY,
	
	@auto_v2spositiontaking_mem_1 SMALLMONEY,
	@auto_v2spositiontaking_mem_2 SMALLMONEY,
	@auto_v2spositiontaking_mem_3 SMALLMONEY,
	@auto_v2spositiontaking_mem_7 SMALLMONEY,
	@auto_v2spositiontaking_mem_8 SMALLMONEY,
	@auto_v2spositiontaking_mem_9 SMALLMONEY,
	@auto_v2spositiontaking_mem_20 SMALLMONEY,

	@auto_v3spositiontaking_mem_1 SMALLMONEY,
	@auto_v3spositiontaking_mem_2 SMALLMONEY,
	@auto_v3spositiontaking_mem_3 SMALLMONEY,
	@auto_v3spositiontaking_mem_20 SMALLMONEY,

	@auto_v5spositiontaking_mem_1 SMALLMONEY,
	@auto_v5spositiontaking_mem_2 SMALLMONEY,
	@auto_v5spositiontaking_mem_3 SMALLMONEY,
	@auto_v5spositiontaking_mem_20 SMALLMONEY,

	@auto_v8spositiontaking_mem_1 SMALLMONEY,
	@auto_v8spositiontaking_mem_3 SMALLMONEY,
	@auto_v8spositiontaking_mem_20 SMALLMONEY,

	@auto_v10spositiontaking_mem_1 SMALLMONEY,
	@auto_v10spositiontaking_mem_2 SMALLMONEY,
	@auto_v10spositiontaking_mem_3 SMALLMONEY,
	@auto_v10spositiontaking_mem_20 SMALLMONEY,

	@auto_v11spositiontaking_mem_1 SMALLMONEY,
	@auto_v11spositiontaking_mem_20 SMALLMONEY,

	@auto_v99spositiontaking_mem_1 SMALLMONEY,
	@auto_v99spositiontaking_mem_2 SMALLMONEY,
	@auto_v99spositiontaking_mem_3 SMALLMONEY,
	@auto_v99spositiontaking_mem_20 SMALLMONEY,
	--i1
	@isauto_spositiontaking_mem_1 BIT,
	@isauto_spositiontaking_mem_2 BIT,
	@isauto_spositiontaking_mem_3 BIT,
	@isauto_spositiontaking_mem_4 BIT,
	@isauto_spositiontaking_mem_5 BIT,
	@isauto_spositiontaking_mem_6 BIT,
	@isauto_spositiontaking_mem_7 BIT,
	@isauto_spositiontaking_mem_8 BIT,
	@isauto_spositiontaking_mem_9 BIT,
	@isauto_spositiontaking_mem_10 BIT,
	
	@isauto_slivepositiontaking_mem_1 BIT,
	@isauto_slivepositiontaking_mem_3 BIT,
	@isauto_slivepositiontaking_mem_7 BIT,
	@isauto_slivepositiontaking_mem_8 BIT,
	
	@isauto_v2spositiontaking_mem_1 BIT,
	@isauto_v2spositiontaking_mem_2 BIT,
	@isauto_v2spositiontaking_mem_3 BIT,
	@isauto_v2spositiontaking_mem_7 BIT,
	@isauto_v2spositiontaking_mem_8 BIT,
	@isauto_v2spositiontaking_mem_9 BIT,
	@isauto_v2spositiontaking_mem_20 BIT,

	@isauto_v3spositiontaking_mem_1 BIT,
	@isauto_v3spositiontaking_mem_2 BIT,
	@isauto_v3spositiontaking_mem_3 BIT,
	@isauto_v3spositiontaking_mem_20 BIT,

	@isauto_v5spositiontaking_mem_1 BIT,
	@isauto_v5spositiontaking_mem_2 BIT,
	@isauto_v5spositiontaking_mem_3 BIT,
	@isauto_v5spositiontaking_mem_20 BIT,

	@isauto_v8spositiontaking_mem_1 BIT,
	@isauto_v8spositiontaking_mem_3 BIT,
	@isauto_v8spositiontaking_mem_20 BIT,

	@isauto_v10spositiontaking_mem_1 BIT,
	@isauto_v10spositiontaking_mem_2 BIT,
	@isauto_v10spositiontaking_mem_3 BIT,
	@isauto_v10spositiontaking_mem_20 BIT,

	@isauto_v11spositiontaking_mem_1 BIT,
	@isauto_v11spositiontaking_mem_20 BIT,

	@isauto_v99spositiontaking_mem_1 BIT,
	@isauto_v99spositiontaking_mem_2 BIT,
	@isauto_v99spositiontaking_mem_3 BIT,
	@isauto_v99spositiontaking_mem_20 BIT,
	--u3
	@auto_spositiontaking_1 SMALLMONEY,
	@auto_spositiontaking_2 SMALLMONEY,
	@auto_spositiontaking_3 SMALLMONEY,
	@auto_spositiontaking_4 SMALLMONEY,
	@auto_spositiontaking_5 SMALLMONEY,
	@auto_spositiontaking_6 SMALLMONEY,
	@auto_spositiontaking_7 SMALLMONEY,
	@auto_spositiontaking_8 SMALLMONEY,
	@auto_spositiontaking_9 SMALLMONEY,
	@auto_spositiontaking_10 SMALLMONEY,
	
	@auto_slivepositiontaking_1 SMALLMONEY,
	@auto_slivepositiontaking_3 SMALLMONEY,
	@auto_slivepositiontaking_7 SMALLMONEY,
	@auto_slivepositiontaking_8 SMALLMONEY,
	
	@auto_v2spositiontaking_1 SMALLMONEY,
	@auto_v2spositiontaking_2 SMALLMONEY,
	@auto_v2spositiontaking_3 SMALLMONEY,
	@auto_v2spositiontaking_7 SMALLMONEY,
	@auto_v2spositiontaking_8 SMALLMONEY,
	@auto_v2spositiontaking_9 SMALLMONEY,
	@auto_v2spositiontaking_20 SMALLMONEY,

	@auto_v3spositiontaking_1 SMALLMONEY,
	@auto_v3spositiontaking_2 SMALLMONEY,
	@auto_v3spositiontaking_3 SMALLMONEY,
	@auto_v3spositiontaking_20 SMALLMONEY,

	@auto_v5spositiontaking_1 SMALLMONEY,
	@auto_v5spositiontaking_2 SMALLMONEY,
	@auto_v5spositiontaking_3 SMALLMONEY,
	@auto_v5spositiontaking_20 SMALLMONEY,

	@auto_v8spositiontaking_1 SMALLMONEY,
	@auto_v8spositiontaking_3 SMALLMONEY,
	@auto_v8spositiontaking_20 SMALLMONEY,

	@auto_v10spositiontaking_1 SMALLMONEY,
	@auto_v10spositiontaking_2 SMALLMONEY,
	@auto_v10spositiontaking_3 SMALLMONEY,
	@auto_v10spositiontaking_20 SMALLMONEY,

	@auto_v11spositiontaking_1 SMALLMONEY,
	@auto_v11spositiontaking_20 SMALLMONEY,

	@auto_v99spositiontaking_1 SMALLMONEY,
	@auto_v99spositiontaking_2 SMALLMONEY,
	@auto_v99spositiontaking_3 SMALLMONEY,
	@auto_v99spositiontaking_20 SMALLMONEY,
	
	--i3
	@isauto_spositiontaking_1 BIT,
	@isauto_spositiontaking_2 BIT,
	@isauto_spositiontaking_3 BIT,
	@isauto_spositiontaking_4 BIT,
	@isauto_spositiontaking_5 BIT,
	@isauto_spositiontaking_6 BIT,
	@isauto_spositiontaking_7 BIT,
	@isauto_spositiontaking_8 BIT,
	@isauto_spositiontaking_9 BIT,
	@isauto_spositiontaking_10 BIT,
	@isauto_slivepositiontaking_1 BIT,
	@isauto_slivepositiontaking_3 BIT,
	@isauto_slivepositiontaking_7 BIT,
	@isauto_slivepositiontaking_8 BIT,
	
	@isauto_v2spositiontaking_1 BIT,
	@isauto_v2spositiontaking_2 BIT,
	@isauto_v2spositiontaking_3 BIT,
	@isauto_v2spositiontaking_7 BIT,
	@isauto_v2spositiontaking_8 BIT,
	@isauto_v2spositiontaking_9 BIT,
	@isauto_v2spositiontaking_20 BIT,

	@isauto_v3spositiontaking_1 BIT,
	@isauto_v3spositiontaking_2 BIT,
	@isauto_v3spositiontaking_3 BIT,
	@isauto_v3spositiontaking_20 BIT,

	@isauto_v5spositiontaking_1 BIT,
	@isauto_v5spositiontaking_2 BIT,
	@isauto_v5spositiontaking_3 BIT,
	@isauto_v5spositiontaking_20 BIT,

	@isauto_v8spositiontaking_1 BIT,
	@isauto_v8spositiontaking_3 BIT,
	@isauto_v8spositiontaking_20 BIT,

	@isauto_v10spositiontaking_1 BIT,
	@isauto_v10spositiontaking_2 BIT,
	@isauto_v10spositiontaking_3 BIT,
	@isauto_v10spositiontaking_20 BIT,

	@isauto_v11spositiontaking_1 BIT,
	@isauto_v11spositiontaking_20 BIT,

	@isauto_v99spositiontaking_1 BIT,
	@isauto_v99spositiontaking_2 BIT,
	@isauto_v99spositiontaking_3 BIT,
	@isauto_v99spositiontaking_20 BIT,
	
	--um2
	@auto_mpositiontaking_1 SMALLMONEY ,
	@auto_mpositiontaking_2 SMALLMONEY ,
	@auto_mpositiontaking_3 SMALLMONEY ,
	@auto_mpositiontaking_4 SMALLMONEY ,
	@auto_mpositiontaking_5 SMALLMONEY,
	@auto_mpositiontaking_6 SMALLMONEY ,
	@auto_mpositiontaking_7 SMALLMONEY ,
	@auto_mpositiontaking_8 SMALLMONEY ,
	@auto_mpositiontaking_9 SMALLMONEY ,
	@auto_mpositiontaking_10 SMALLMONEY ,
	@auto_mlivepositiontaking_1 SMALLMONEY ,
	@auto_mlivepositiontaking_3 SMALLMONEY ,
	@auto_mlivepositiontaking_7 SMALLMONEY ,
	@auto_mlivepositiontaking_8 SMALLMONEY ,
	
	@auto_v2mpositiontaking_1 SMALLMONEY ,
	@auto_v2mpositiontaking_2 SMALLMONEY ,
	@auto_v2mpositiontaking_3 SMALLMONEY ,
	@auto_v2mpositiontaking_7 SMALLMONEY ,
	@auto_v2mpositiontaking_8 SMALLMONEY ,
	@auto_v2mpositiontaking_9 SMALLMONEY ,
	@auto_v2mpositiontaking_20 SMALLMONEY ,
	
	@auto_v3mpositiontaking_1 SMALLMONEY ,
	@auto_v3mpositiontaking_2 SMALLMONEY ,
	@auto_v3mpositiontaking_3 SMALLMONEY ,
	@auto_v3mpositiontaking_20 SMALLMONEY ,
	
	@auto_v5mpositiontaking_1 SMALLMONEY ,
	@auto_v5mpositiontaking_2 SMALLMONEY ,
	@auto_v5mpositiontaking_3 SMALLMONEY ,
	@auto_v5mpositiontaking_20 SMALLMONEY ,
	
	@auto_v8mpositiontaking_1 SMALLMONEY ,
	@auto_v8mpositiontaking_3 SMALLMONEY ,
	@auto_v8mpositiontaking_20 SMALLMONEY ,
	
	@auto_v10mpositiontaking_1 SMALLMONEY ,
	@auto_v10mpositiontaking_2 SMALLMONEY ,
	@auto_v10mpositiontaking_3 SMALLMONEY ,
	@auto_v10mpositiontaking_20 SMALLMONEY ,
	
	@auto_v11mpositiontaking_1 SMALLMONEY ,
	@auto_v11mpositiontaking_20 SMALLMONEY ,

	@auto_v99mpositiontaking_1 SMALLMONEY ,
	@auto_v99mpositiontaking_2 SMALLMONEY ,
	@auto_v99mpositiontaking_3 SMALLMONEY ,
	@auto_v99mpositiontaking_20 SMALLMONEY

DECLARE
	@max_mapositiontaking_1 SMALLMONEY,
	@max_mapositiontaking_2 SMALLMONEY,
	@max_mapositiontaking_3 SMALLMONEY,
	@max_mapositiontaking_4 SMALLMONEY,
	@max_mapositiontaking_5 SMALLMONEY,
	@max_mapositiontaking_6 SMALLMONEY,
	@max_mapositiontaking_7 SMALLMONEY,
	@max_mapositiontaking_8 SMALLMONEY,
	@max_mapositiontaking_9 SMALLMONEY,
	@max_mapositiontaking_10 SMALLMONEY,
	
	@max_malivepositiontaking_1 SMALLMONEY,
	@max_malivepositiontaking_3 SMALLMONEY,
	@max_malivepositiontaking_7 SMALLMONEY,
	@max_malivepositiontaking_8 SMALLMONEY,
	
	@max_v2mapositiontaking_1 SMALLMONEY,
	@max_v2mapositiontaking_2 SMALLMONEY,
	@max_v2mapositiontaking_3 SMALLMONEY,
	@max_v2mapositiontaking_7 SMALLMONEY,
	@max_v2mapositiontaking_8 SMALLMONEY,
	@max_v2mapositiontaking_9 SMALLMONEY,
	@max_v2mapositiontaking_20 SMALLMONEY,

	@max_v3mapositiontaking_1 SMALLMONEY,
	@max_v3mapositiontaking_2 SMALLMONEY,
	@max_v3mapositiontaking_3 SMALLMONEY,
	@max_v3mapositiontaking_20 SMALLMONEY,

	@max_v5mapositiontaking_1 SMALLMONEY,
	@max_v5mapositiontaking_2 SMALLMONEY,
	@max_v5mapositiontaking_3 SMALLMONEY,
	@max_v5mapositiontaking_20 SMALLMONEY,

	@max_v8mapositiontaking_1 SMALLMONEY,
	@max_v8mapositiontaking_3 SMALLMONEY,
	@max_v8mapositiontaking_20 SMALLMONEY,

	@max_v10mapositiontaking_1 SMALLMONEY,
	@max_v10mapositiontaking_2 SMALLMONEY,
	@max_v10mapositiontaking_3 SMALLMONEY,
	@max_v10mapositiontaking_20 SMALLMONEY,

	@max_v11mapositiontaking_1 SMALLMONEY,
	@max_v11mapositiontaking_20 SMALLMONEY,

	@max_v99mapositiontaking_1 SMALLMONEY,
	@max_v99mapositiontaking_2 SMALLMONEY,
	@max_v99mapositiontaking_3 SMALLMONEY,
	@max_v99mapositiontaking_20 SMALLMONEY
	
DECLARE
	@min_mapositiontaking_1 SMALLMONEY,
	@min_mapositiontaking_2 SMALLMONEY,
	@min_mapositiontaking_3 SMALLMONEY,
	@min_mapositiontaking_4 SMALLMONEY,
	@min_mapositiontaking_5 SMALLMONEY,
	@min_mapositiontaking_6 SMALLMONEY,
	@min_mapositiontaking_7 SMALLMONEY,
	@min_mapositiontaking_8 SMALLMONEY,
	@min_mapositiontaking_9 SMALLMONEY,
	@min_mapositiontaking_10 SMALLMONEY,
	@min_malivepositiontaking_1 SMALLMONEY,
	@min_malivepositiontaking_3 SMALLMONEY,
	@min_malivepositiontaking_7 SMALLMONEY,
	@min_malivepositiontaking_8 SMALLMONEY,
	
	@min_v2mapositiontaking_1 SMALLMONEY,
	@min_v2mapositiontaking_2 SMALLMONEY,
	@min_v2mapositiontaking_3 SMALLMONEY,
	@min_v2mapositiontaking_7 SMALLMONEY,
	@min_v2mapositiontaking_8 SMALLMONEY,
	@min_v2mapositiontaking_9 SMALLMONEY,
	@min_v2mapositiontaking_20 SMALLMONEY,

	@min_v3mapositiontaking_1 SMALLMONEY,
	@min_v3mapositiontaking_2 SMALLMONEY,
	@min_v3mapositiontaking_3 SMALLMONEY,
	@min_v3mapositiontaking_20 SMALLMONEY,

	@min_v5mapositiontaking_1 SMALLMONEY,
	@min_v5mapositiontaking_2 SMALLMONEY,
	@min_v5mapositiontaking_3 SMALLMONEY,
	@min_v5mapositiontaking_20 SMALLMONEY,

	@min_v8mapositiontaking_1 SMALLMONEY,
	@min_v8mapositiontaking_3 SMALLMONEY,
	@min_v8mapositiontaking_20 SMALLMONEY,

	@min_v10mapositiontaking_1 SMALLMONEY,
	@min_v10mapositiontaking_2 SMALLMONEY,
	@min_v10mapositiontaking_3 SMALLMONEY,
	@min_v10mapositiontaking_20 SMALLMONEY,

	@min_v11mapositiontaking_1 SMALLMONEY,
	@min_v11mapositiontaking_20 SMALLMONEY,

	@min_v99mapositiontaking_1 SMALLMONEY,
	@min_v99mapositiontaking_2 SMALLMONEY,
	@min_v99mapositiontaking_3 SMALLMONEY,
	@min_v99mapositiontaking_20 SMALLMONEY

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Update Customer Info First.
	
	SELECT @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	IF @disCasino = 1 AND EXISTS (SELECT 1 FROM Custinfo WITH (NOLOCK) WHERE syncCasino = 1 AND custID = @CustID)
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
		SELECT @ErrCode_Cur = 0, @ErrMsg_Cur=''

		IF @UpdateSuspended = 1
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
		SELECT @ErrCode_Cur = 0, @ErrMsg_Cur=''		
	END
	ELSE
		BEGIN
			UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET 
				closed= case when @closed is null or @UpdateClosed = 0 then closed else @closed end,
				reject = CASE WHEN @suspended IS NULL OR @UpdateSuspended = 0 THEN reject ELSE @suspended END 
			WHERE custid=@CustID

			Select @ErrCode = @ErrCode + '-102'+char(7), @ErrMsg = @ErrMsg + char(7)
		END
		




--Log customer info
DECLARE @LogSPData VARCHAR(4000)

SELECT @LogSPData = '<Acc_CustomerUpdMember_Master custid="'+ COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' +
'Closed="'+ COALESCE(CAST(@Closed AS VARCHAR(2)),SPACE(1)) + '" ' +
'ClosedMultiple="'+ COALESCE(CAST(@UpdateClosed AS VARCHAR(2)),SPACE(1)) + '" ' +
'suspended="'+ COALESCE(CAST(@suspended AS VARCHAR(2)),SPACE(1)) + '" ' +
'suspendedMultiple="'+ COALESCE(CAST(@UpdateSuspended AS VARCHAR(2)),SPACE(1)) + '" ' +
'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),SPACE(1)) + '" ' +
'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1117,
	@TrackingValue = @LogSPData

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
SELECT	@spositiontaking_1	=	spositiontaking,	@slivepositiontaking_1	=	slivepositiontaking,	@apositiontaking_1	=	apositiontaking,	@alivepositiontaking_1	=	alivepositiontaking,	@auto_spositiontaking_mem_1	=	autopositiontaking,	@auto_slivepositiontaking_mem_1	=	autolivepositiontaking,	@isauto_spositiontaking_mem_1	=	isautopositiontaking,	@isauto_slivepositiontaking_mem_1	=	isautolivepositiontaking,	@old_mpositiontaking_1	=	mpositiontaking,	@old_auto_mpositiontaking_mem_1	=	autompositiontaking,	@old_isauto_mpositiontaking_mem_1	=	isautompositiontaking,	@old_mlivepositiontaking_1	=	mlivepositiontaking	,@old_auto_mlivepositiontaking_mem_1	=	autolivempositiontaking,	@old_isauto_mlivepositiontaking_mem_1	=	isautolivempositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																									
SELECT	@spositiontaking_3	=	spositiontaking,	@slivepositiontaking_3	=	slivepositiontaking,	@apositiontaking_3	=	apositiontaking,	@alivepositiontaking_3	=	alivepositiontaking,	@auto_spositiontaking_mem_3	=	autopositiontaking,	@auto_slivepositiontaking_mem_3	=	autolivepositiontaking,	@isauto_spositiontaking_mem_3	=	isautopositiontaking,	@isauto_slivepositiontaking_mem_3	=	isautolivepositiontaking,	@old_mpositiontaking_3	=	mpositiontaking,	@old_auto_mpositiontaking_mem_3	=	autompositiontaking,	@old_isauto_mpositiontaking_mem_3	=	isautompositiontaking,	@old_mlivepositiontaking_3	=	mlivepositiontaking	,@old_auto_mlivepositiontaking_mem_3	=	autolivempositiontaking,	@old_isauto_mlivepositiontaking_mem_3	=	isautolivempositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																									
SELECT	@spositiontaking_7	=	spositiontaking,	@slivepositiontaking_7	=	slivepositiontaking,	@apositiontaking_7	=	apositiontaking,	@alivepositiontaking_7	=	alivepositiontaking,	@auto_spositiontaking_mem_7	=	autopositiontaking,	@auto_slivepositiontaking_mem_7	=	autolivepositiontaking,	@isauto_spositiontaking_mem_7	=	isautopositiontaking,	@isauto_slivepositiontaking_mem_7	=	isautolivepositiontaking,	@old_mpositiontaking_7	=	mpositiontaking,	@old_auto_mpositiontaking_mem_7	=	autompositiontaking,	@old_isauto_mpositiontaking_mem_7	=	isautompositiontaking,	@old_mlivepositiontaking_7	=	mlivepositiontaking	,@old_auto_mlivepositiontaking_mem_7	=	autolivempositiontaking,	@old_isauto_mlivepositiontaking_mem_7	=	isautolivempositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=7	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																									
SELECT	@spositiontaking_8	=	spositiontaking,	@slivepositiontaking_8	=	slivepositiontaking,	@apositiontaking_8	=	apositiontaking,	@alivepositiontaking_8	=	alivepositiontaking,	@auto_spositiontaking_mem_8	=	autopositiontaking,	@auto_slivepositiontaking_mem_8	=	autolivepositiontaking,	@isauto_spositiontaking_mem_8	=	isautopositiontaking,	@isauto_slivepositiontaking_mem_8	=	isautolivepositiontaking,	@old_mpositiontaking_8	=	mpositiontaking,	@old_auto_mpositiontaking_mem_8	=	autompositiontaking,	@old_isauto_mpositiontaking_mem_8	=	isautompositiontaking,	@old_mlivepositiontaking_8	=	mlivepositiontaking	,@old_auto_mlivepositiontaking_mem_8	=	autolivempositiontaking,	@old_isauto_mlivepositiontaking_mem_8	=	isautolivempositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=8	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																									

SELECT	@spositiontaking_2	=	spositiontaking,	@apositiontaking_2	=	apositiontaking,	@old_mpositiontaking_2	=	mpositiontaking,	@auto_spositiontaking_mem_2	=	autopositiontaking,	@isauto_spositiontaking_mem_2	=	isautopositiontaking	,	@old_auto_mpositiontaking_mem_2	=	autompositiontaking	,	@old_isauto_mpositiontaking_mem_2	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=2	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@spositiontaking_4	=	spositiontaking,	@apositiontaking_4	=	apositiontaking,	@old_mpositiontaking_4	=	mpositiontaking,	@auto_spositiontaking_mem_4	=	autopositiontaking,	@isauto_spositiontaking_mem_4	=	isautopositiontaking	,	@old_auto_mpositiontaking_mem_4	=	autompositiontaking	,	@old_isauto_mpositiontaking_mem_4	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=4	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@spositiontaking_5	=	spositiontaking,	@apositiontaking_5	=	apositiontaking,	@old_mpositiontaking_5	=	mpositiontaking,	@auto_spositiontaking_mem_5	=	autopositiontaking,	@isauto_spositiontaking_mem_5	=	isautopositiontaking	,	@old_auto_mpositiontaking_mem_5	=	autompositiontaking	,	@old_isauto_mpositiontaking_mem_5	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=5	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@spositiontaking_6	=	spositiontaking,	@apositiontaking_6	=	apositiontaking,	@old_mpositiontaking_6	=	mpositiontaking,	@auto_spositiontaking_mem_6	=	autopositiontaking,	@isauto_spositiontaking_mem_6	=	isautopositiontaking	,	@old_auto_mpositiontaking_mem_6	=	autompositiontaking	,	@old_isauto_mpositiontaking_mem_6	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=6	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@spositiontaking_9	=	spositiontaking,	@apositiontaking_9	=	apositiontaking,	@old_mpositiontaking_9	=	mpositiontaking,	@auto_spositiontaking_mem_9	=	autopositiontaking,	@isauto_spositiontaking_mem_9	=	isautopositiontaking	,	@old_auto_mpositiontaking_mem_9	=	autompositiontaking	,	@old_isauto_mpositiontaking_mem_9	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=9	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@spositiontaking_10	=	spositiontaking,	@apositiontaking_10	=	apositiontaking,	@old_mpositiontaking_10	=	mpositiontaking,	@auto_spositiontaking_mem_10	=	autopositiontaking,	@isauto_spositiontaking_mem_10	=	isautopositiontaking	,	@old_auto_mpositiontaking_mem_10	=	autompositiontaking	,	@old_isauto_mpositiontaking_mem_10	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=10	AND	sporttype=1																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
SELECT	@v2spositiontaking_1	=	spositiontaking,	@v2apositiontaking_1	=	apositiontaking,	@auto_v2spositiontaking_mem_1	=	autopositiontaking,	@isauto_v2spositiontaking_mem_1	=	isautopositiontaking,	@old_v2mpositiontaking_1	=	mpositiontaking	,	@old_auto_v2mpositiontaking_mem_1	=	autompositiontaking	,	@old_isauto_v2mpositiontaking_mem_1	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=2																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v2spositiontaking_2	=	spositiontaking,	@v2apositiontaking_2	=	apositiontaking,	@auto_v2spositiontaking_mem_2	=	autopositiontaking,	@isauto_v2spositiontaking_mem_2	=	isautopositiontaking,	@old_v2mpositiontaking_2	=	mpositiontaking	,	@old_auto_v2mpositiontaking_mem_2	=	autompositiontaking	,	@old_isauto_v2mpositiontaking_mem_2	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=2	AND	sporttype=2																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v2spositiontaking_3	=	spositiontaking,	@v2apositiontaking_3	=	apositiontaking,	@auto_v2spositiontaking_mem_3	=	autopositiontaking,	@isauto_v2spositiontaking_mem_3	=	isautopositiontaking,	@old_v2mpositiontaking_3	=	mpositiontaking	,	@old_auto_v2mpositiontaking_mem_3	=	autompositiontaking	,	@old_isauto_v2mpositiontaking_mem_3	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=2																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v2spositiontaking_7	=	spositiontaking,	@v2apositiontaking_7	=	apositiontaking,	@auto_v2spositiontaking_mem_7	=	autopositiontaking,	@isauto_v2spositiontaking_mem_7	=	isautopositiontaking,	@old_v2mpositiontaking_7	=	mpositiontaking	,	@old_auto_v2mpositiontaking_mem_7	=	autompositiontaking	,	@old_isauto_v2mpositiontaking_mem_7	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=7	AND	sporttype=2																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v2spositiontaking_8	=	spositiontaking,	@v2apositiontaking_8	=	apositiontaking,	@auto_v2spositiontaking_mem_8	=	autopositiontaking,	@isauto_v2spositiontaking_mem_8	=	isautopositiontaking,	@old_v2mpositiontaking_8	=	mpositiontaking	,	@old_auto_v2mpositiontaking_mem_8	=	autompositiontaking	,	@old_isauto_v2mpositiontaking_mem_8	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=8	AND	sporttype=2																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v2spositiontaking_9	=	spositiontaking,	@v2apositiontaking_9	=	apositiontaking,	@auto_v2spositiontaking_mem_9	=	autopositiontaking,	@isauto_v2spositiontaking_mem_9	=	isautopositiontaking,	@old_v2mpositiontaking_9	=	mpositiontaking	,	@old_auto_v2mpositiontaking_mem_9	=	autompositiontaking	,	@old_isauto_v2mpositiontaking_mem_9	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=9	AND	sporttype=2																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v2spositiontaking_20	=	spositiontaking,	@v2apositiontaking_20	=	apositiontaking,	@auto_v2spositiontaking_mem_20	=	autopositiontaking,	@isauto_v2spositiontaking_mem_20	=	isautopositiontaking,	@old_v2mpositiontaking_20	=	mpositiontaking	,	@old_auto_v2mpositiontaking_mem_20	=	autompositiontaking	,	@old_isauto_v2mpositiontaking_mem_20	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=20	AND	sporttype=2																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
SELECT	@v3spositiontaking_1	=	spositiontaking,	@v3apositiontaking_1	=	apositiontaking,	@auto_v3spositiontaking_mem_1	=	autopositiontaking,	@isauto_v3spositiontaking_mem_1	=	isautopositiontaking,	@old_v3mpositiontaking_1	=	mpositiontaking	,	@old_auto_v3mpositiontaking_mem_1	=	autompositiontaking	,	@old_isauto_v3mpositiontaking_mem_1	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=3																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v3spositiontaking_2	=	spositiontaking,	@v3apositiontaking_2	=	apositiontaking,	@auto_v3spositiontaking_mem_2	=	autopositiontaking,	@isauto_v3spositiontaking_mem_2	=	isautopositiontaking,	@old_v3mpositiontaking_2	=	mpositiontaking	,	@old_auto_v3mpositiontaking_mem_2	=	autompositiontaking	,	@old_isauto_v3mpositiontaking_mem_2	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=2	AND	sporttype=3																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v3spositiontaking_3	=	spositiontaking,	@v3apositiontaking_3	=	apositiontaking,	@auto_v3spositiontaking_mem_3	=	autopositiontaking,	@isauto_v3spositiontaking_mem_3	=	isautopositiontaking,	@old_v3mpositiontaking_3	=	mpositiontaking	,	@old_auto_v3mpositiontaking_mem_3	=	autompositiontaking	,	@old_isauto_v3mpositiontaking_mem_3	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=3																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v3spositiontaking_20	=	spositiontaking,	@v3apositiontaking_20	=	apositiontaking,	@auto_v3spositiontaking_mem_20	=	autopositiontaking,	@isauto_v3spositiontaking_mem_20	=	isautopositiontaking,	@old_v3mpositiontaking_20	=	mpositiontaking	,	@old_auto_v3mpositiontaking_mem_20	=	autompositiontaking	,	@old_isauto_v3mpositiontaking_mem_20	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=20	AND	sporttype=3																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
SELECT	@v5spositiontaking_1	=	spositiontaking,	@v5apositiontaking_1	=	apositiontaking,	@auto_v5spositiontaking_mem_1	=	autopositiontaking,	@isauto_v5spositiontaking_mem_1	=	isautopositiontaking,	@old_v5mpositiontaking_1	=	mpositiontaking	,	@old_auto_v5mpositiontaking_mem_1	=	autompositiontaking	,	@old_isauto_v5mpositiontaking_mem_1	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=5																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v5spositiontaking_2	=	spositiontaking,	@v5apositiontaking_2	=	apositiontaking,	@auto_v5spositiontaking_mem_2	=	autopositiontaking,	@isauto_v5spositiontaking_mem_2	=	isautopositiontaking,	@old_v5mpositiontaking_2	=	mpositiontaking	,	@old_auto_v5mpositiontaking_mem_2	=	autompositiontaking	,	@old_isauto_v5mpositiontaking_mem_2	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=2	AND	sporttype=5																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v5spositiontaking_3	=	spositiontaking,	@v5apositiontaking_3	=	apositiontaking,	@auto_v5spositiontaking_mem_3	=	autopositiontaking,	@isauto_v5spositiontaking_mem_3	=	isautopositiontaking,	@old_v5mpositiontaking_3	=	mpositiontaking	,	@old_auto_v5mpositiontaking_mem_3	=	autompositiontaking	,	@old_isauto_v5mpositiontaking_mem_3	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=5																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v5spositiontaking_20	=	spositiontaking,	@v5apositiontaking_20	=	apositiontaking,	@auto_v5spositiontaking_mem_20	=	autopositiontaking,	@isauto_v5spositiontaking_mem_20	=	isautopositiontaking,	@old_v5mpositiontaking_20	=	mpositiontaking	,	@old_auto_v5mpositiontaking_mem_20	=	autompositiontaking	,	@old_isauto_v5mpositiontaking_mem_20	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=20	AND	sporttype=5																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
SELECT	@v8spositiontaking_1	=	spositiontaking,	@v8apositiontaking_1	=	apositiontaking,	@auto_v8spositiontaking_mem_1	=	autopositiontaking,	@isauto_v8spositiontaking_mem_1	=	isautopositiontaking,	@old_v8mpositiontaking_1	=	mpositiontaking	,	@old_auto_v8mpositiontaking_mem_1	=	autompositiontaking	,	@old_isauto_v8mpositiontaking_mem_1	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=8																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v8spositiontaking_3	=	spositiontaking,	@v8apositiontaking_3	=	apositiontaking,	@auto_v8spositiontaking_mem_3	=	autopositiontaking,	@isauto_v8spositiontaking_mem_3	=	isautopositiontaking,	@old_v8mpositiontaking_3	=	mpositiontaking	,	@old_auto_v8mpositiontaking_mem_3	=	autompositiontaking	,	@old_isauto_v8mpositiontaking_mem_3	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=8																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v8spositiontaking_20	=	spositiontaking,	@v8apositiontaking_20	=	apositiontaking,	@auto_v8spositiontaking_mem_20	=	autopositiontaking,	@isauto_v8spositiontaking_mem_20	=	isautopositiontaking,	@old_v8mpositiontaking_20	=	mpositiontaking	,	@old_auto_v8mpositiontaking_mem_20	=	autompositiontaking	,	@old_isauto_v8mpositiontaking_mem_20	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=20	AND	sporttype=8																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
SELECT	@v10spositiontaking_1	=	spositiontaking,	@v10apositiontaking_1	=	apositiontaking,	@auto_v10spositiontaking_mem_1	=	autopositiontaking,	@isauto_v10spositiontaking_mem_1	=	isautopositiontaking,	@old_v10mpositiontaking_1	=	mpositiontaking	,	@old_auto_v10mpositiontaking_mem_1	=	autompositiontaking	,	@old_isauto_v10mpositiontaking_mem_1	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=10																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v10spositiontaking_2	=	spositiontaking,	@v10apositiontaking_2	=	apositiontaking,	@auto_v10spositiontaking_mem_2	=	autopositiontaking,	@isauto_v10spositiontaking_mem_2	=	isautopositiontaking,	@old_v10mpositiontaking_2	=	mpositiontaking	,	@old_auto_v10mpositiontaking_mem_2	=	autompositiontaking	,	@old_isauto_v10mpositiontaking_mem_2	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=2	AND	sporttype=10																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v10spositiontaking_3	=	spositiontaking,	@v10apositiontaking_3	=	apositiontaking,	@auto_v10spositiontaking_mem_3	=	autopositiontaking,	@isauto_v10spositiontaking_mem_3	=	isautopositiontaking,	@old_v10mpositiontaking_3	=	mpositiontaking	,	@old_auto_v10mpositiontaking_mem_3	=	autompositiontaking	,	@old_isauto_v10mpositiontaking_mem_3	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=10																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v10spositiontaking_20	=	spositiontaking,	@v10apositiontaking_20	=	apositiontaking,	@auto_v10spositiontaking_mem_20	=	autopositiontaking,	@isauto_v10spositiontaking_mem_20	=	isautopositiontaking,	@old_v10mpositiontaking_20	=	mpositiontaking	,	@old_auto_v10mpositiontaking_mem_20	=	autompositiontaking	,	@old_isauto_v10mpositiontaking_mem_20	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=20	AND	sporttype=10																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
SELECT	@v11spositiontaking_1	=	spositiontaking,	@v11apositiontaking_1	=	apositiontaking,	@auto_v11spositiontaking_mem_1	=	autopositiontaking,	@isauto_v11spositiontaking_mem_1	=	isautopositiontaking,	@old_v11mpositiontaking_1	=	mpositiontaking	,	@old_auto_v11mpositiontaking_mem_1	=	autompositiontaking	,	@old_isauto_v11mpositiontaking_mem_1	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=11																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v11spositiontaking_20	=	spositiontaking,	@v11apositiontaking_20	=	apositiontaking,	@auto_v11spositiontaking_mem_20	=	autopositiontaking,	@isauto_v11spositiontaking_mem_20	=	isautopositiontaking,	@old_v11mpositiontaking_20	=	mpositiontaking	,	@old_auto_v11mpositiontaking_mem_20	=	autompositiontaking	,	@old_isauto_v11mpositiontaking_mem_20	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=20	AND	sporttype=11																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																															
SELECT	@v99spositiontaking_1	=	spositiontaking,	@v99apositiontaking_1	=	apositiontaking,	@auto_v99spositiontaking_mem_1	=	autopositiontaking,	@isauto_v99spositiontaking_mem_1	=	isautopositiontaking,	@old_v99mpositiontaking_1	=	mpositiontaking	,	@old_auto_v99mpositiontaking_mem_1	=	autompositiontaking	,	@old_isauto_v99mpositiontaking_mem_1	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=1	AND	sporttype=99																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v99spositiontaking_2	=	spositiontaking,	@v99apositiontaking_2	=	apositiontaking,	@auto_v99spositiontaking_mem_2	=	autopositiontaking,	@isauto_v99spositiontaking_mem_2	=	isautopositiontaking,	@old_v99mpositiontaking_2	=	mpositiontaking	,	@old_auto_v99mpositiontaking_mem_2	=	autompositiontaking	,	@old_isauto_v99mpositiontaking_mem_2	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=2	AND	sporttype=99																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v99spositiontaking_3	=	spositiontaking,	@v99apositiontaking_3	=	apositiontaking,	@auto_v99spositiontaking_mem_3	=	autopositiontaking,	@isauto_v99spositiontaking_mem_3	=	isautopositiontaking,	@old_v99mpositiontaking_3	=	mpositiontaking	,	@old_auto_v99mpositiontaking_mem_3	=	autompositiontaking	,	@old_isauto_v99mpositiontaking_mem_3	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=3	AND	sporttype=99																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												
SELECT	@v99spositiontaking_20	=	spositiontaking,	@v99apositiontaking_20	=	apositiontaking,	@auto_v99spositiontaking_mem_20	=	autopositiontaking,	@isauto_v99spositiontaking_mem_20	=	isautopositiontaking,	@old_v99mpositiontaking_20	=	mpositiontaking	,	@old_auto_v99mpositiontaking_mem_20	=	autompositiontaking	,	@old_isauto_v99mpositiontaking_mem_20	=	isautompositiontaking	FROM	custsetting	WITH	(NOLOCK)	WHERE	custid	=	@custid	AND	bettype=20	AND	sporttype=99																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																																												

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

	@v99mpositiontaking_1 = @old_v99mpositiontaking_1 AND
	@v99mpositiontaking_2 = @old_v99mpositiontaking_2 AND
	@v99mpositiontaking_3 = @old_v99mpositiontaking_3 AND
	@v99mpositiontaking_20 = @old_v99mpositiontaking_20 AND
	--um1
	@auto_mpositiontaking_mem_1 = @old_auto_mpositiontaking_mem_1 AND
	@auto_mpositiontaking_mem_2 = @old_auto_mpositiontaking_mem_2 AND
	@auto_mpositiontaking_mem_3 = @old_auto_mpositiontaking_mem_3 AND
	@auto_mpositiontaking_mem_4 = @old_auto_mpositiontaking_mem_4 AND
	@auto_mpositiontaking_mem_5 = @old_auto_mpositiontaking_mem_5 AND
	@auto_mpositiontaking_mem_6 = @old_auto_mpositiontaking_mem_6 AND
	@auto_mpositiontaking_mem_7 = @old_auto_mpositiontaking_mem_7 AND
	@auto_mpositiontaking_mem_8 = @old_auto_mpositiontaking_mem_8 AND
	@auto_mpositiontaking_mem_9 = @old_auto_mpositiontaking_mem_9 AND
	@auto_mpositiontaking_mem_10 = @old_auto_mpositiontaking_mem_10 AND
	@auto_mlivepositiontaking_mem_1 = @old_auto_mlivepositiontaking_mem_1 AND
	@auto_mlivepositiontaking_mem_3 = @old_auto_mlivepositiontaking_mem_3 AND
	@auto_mlivepositiontaking_mem_7 = @old_auto_mlivepositiontaking_mem_7 AND
	@auto_mlivepositiontaking_mem_8 = @old_auto_mlivepositiontaking_mem_8 AND
	
	@auto_v2mpositiontaking_mem_1 = @old_auto_v2mpositiontaking_mem_1 AND
	@auto_v2mpositiontaking_mem_2 = @old_auto_v2mpositiontaking_mem_2 AND
	@auto_v2mpositiontaking_mem_3 = @old_auto_v2mpositiontaking_mem_3 AND
	@auto_v2mpositiontaking_mem_7 = @old_auto_v2mpositiontaking_mem_7 AND
	@auto_v2mpositiontaking_mem_8 = @old_auto_v2mpositiontaking_mem_8 AND
	@auto_v2mpositiontaking_mem_9 = @old_auto_v2mpositiontaking_mem_9 AND
	@auto_v2mpositiontaking_mem_20 = @old_auto_v2mpositiontaking_mem_20 AND

	@auto_v3mpositiontaking_mem_1 = @old_auto_v3mpositiontaking_mem_1 AND
	@auto_v3mpositiontaking_mem_2 = @old_auto_v3mpositiontaking_mem_2 AND
	@auto_v3mpositiontaking_mem_3 = @old_auto_v3mpositiontaking_mem_3 AND
	@auto_v3mpositiontaking_mem_20 = @old_auto_v3mpositiontaking_mem_20 AND

	@auto_v5mpositiontaking_mem_1 = @old_auto_v5mpositiontaking_mem_1 AND
	@auto_v5mpositiontaking_mem_2 = @old_auto_v5mpositiontaking_mem_2 AND
	@auto_v5mpositiontaking_mem_3 = @old_auto_v5mpositiontaking_mem_3 AND
	@auto_v5mpositiontaking_mem_20 = @old_auto_v5mpositiontaking_mem_20 AND

	@auto_v8mpositiontaking_mem_1 = @old_auto_v8mpositiontaking_mem_1 AND
	@auto_v8mpositiontaking_mem_3 = @old_auto_v8mpositiontaking_mem_3 AND
	@auto_v8mpositiontaking_mem_20 = @old_auto_v8mpositiontaking_mem_20 AND

	@auto_v10mpositiontaking_mem_1 = @old_auto_v10mpositiontaking_mem_1 AND
	@auto_v10mpositiontaking_mem_2 = @old_auto_v10mpositiontaking_mem_2 AND
	@auto_v10mpositiontaking_mem_3 = @old_auto_v10mpositiontaking_mem_3 AND
	@auto_v10mpositiontaking_mem_20 = @old_auto_v10mpositiontaking_mem_20 AND

	@auto_v11mpositiontaking_mem_1 = @old_auto_v11mpositiontaking_mem_1 AND
	@auto_v11mpositiontaking_mem_20 = @old_auto_v11mpositiontaking_mem_20 AND

	@auto_v99mpositiontaking_mem_1 = @old_auto_v99mpositiontaking_mem_1 AND
	@auto_v99mpositiontaking_mem_2 = @old_auto_v99mpositiontaking_mem_2 AND
	@auto_v99mpositiontaking_mem_3 = @old_auto_v99mpositiontaking_mem_3 AND
	@auto_v99mpositiontaking_mem_20 = @old_auto_v99mpositiontaking_mem_20 AND
	--im1
	@isauto_mpositiontaking_mem_1 = @old_isauto_mpositiontaking_mem_1 AND
	@isauto_mpositiontaking_mem_2 = @old_isauto_mpositiontaking_mem_2 AND
	@isauto_mpositiontaking_mem_3 = @old_isauto_mpositiontaking_mem_3 AND
	@isauto_mpositiontaking_mem_4 = @old_isauto_mpositiontaking_mem_4 AND
	@isauto_mpositiontaking_mem_5 = @old_isauto_mpositiontaking_mem_5 AND
	@isauto_mpositiontaking_mem_6 = @old_isauto_mpositiontaking_mem_6 AND
	@isauto_mpositiontaking_mem_7 = @old_isauto_mpositiontaking_mem_7 AND
	@isauto_mpositiontaking_mem_8 = @old_isauto_mpositiontaking_mem_8 AND
	@isauto_mpositiontaking_mem_9 = @old_isauto_mpositiontaking_mem_9 AND
	@isauto_mpositiontaking_mem_10 = @old_isauto_mpositiontaking_mem_10 AND
	@isauto_mlivepositiontaking_mem_1 = @old_isauto_mlivepositiontaking_mem_1 AND
	@isauto_mlivepositiontaking_mem_3 = @old_isauto_mlivepositiontaking_mem_3 AND
	@isauto_mlivepositiontaking_mem_7 = @old_isauto_mlivepositiontaking_mem_7 AND
	@isauto_mlivepositiontaking_mem_8 = @old_isauto_mlivepositiontaking_mem_8 AND

	@isauto_v2mpositiontaking_mem_1 = @old_isauto_v2mpositiontaking_mem_1 AND
	@isauto_v2mpositiontaking_mem_2 = @old_isauto_v2mpositiontaking_mem_2 AND
	@isauto_v2mpositiontaking_mem_3 = @old_isauto_v2mpositiontaking_mem_3 AND
	@isauto_v2mpositiontaking_mem_7 = @old_isauto_v2mpositiontaking_mem_7 AND
	@isauto_v2mpositiontaking_mem_8 = @old_isauto_v2mpositiontaking_mem_8 AND
	@isauto_v2mpositiontaking_mem_9 = @old_isauto_v2mpositiontaking_mem_9 AND
	@isauto_v2mpositiontaking_mem_20 = @old_isauto_v2mpositiontaking_mem_20 AND

	@isauto_v3mpositiontaking_mem_1 = @old_isauto_v3mpositiontaking_mem_1 AND
	@isauto_v3mpositiontaking_mem_2 = @old_isauto_v3mpositiontaking_mem_2 AND
	@isauto_v3mpositiontaking_mem_3 = @old_isauto_v3mpositiontaking_mem_3 AND
	@isauto_v3mpositiontaking_mem_20 = @old_isauto_v3mpositiontaking_mem_20 AND

	@isauto_v5mpositiontaking_mem_1 = @old_isauto_v5mpositiontaking_mem_1 AND
	@isauto_v5mpositiontaking_mem_2 = @old_isauto_v5mpositiontaking_mem_2 AND
	@isauto_v5mpositiontaking_mem_3 = @old_isauto_v5mpositiontaking_mem_3 AND
	@isauto_v5mpositiontaking_mem_20 = @old_isauto_v5mpositiontaking_mem_20 AND

	@isauto_v8mpositiontaking_mem_1 = @old_isauto_v8mpositiontaking_mem_1 AND
	@isauto_v8mpositiontaking_mem_3 = @old_isauto_v8mpositiontaking_mem_3 AND
	@isauto_v8mpositiontaking_mem_20 = @old_isauto_v8mpositiontaking_mem_20 AND

	@isauto_v10mpositiontaking_mem_1 = @old_isauto_v10mpositiontaking_mem_1 AND
	@isauto_v10mpositiontaking_mem_2 = @old_isauto_v10mpositiontaking_mem_2 AND
	@isauto_v10mpositiontaking_mem_3 = @old_isauto_v10mpositiontaking_mem_3 AND
	@isauto_v10mpositiontaking_mem_20 = @old_isauto_v10mpositiontaking_mem_20 AND

	@isauto_v11mpositiontaking_mem_1 = @old_isauto_v11mpositiontaking_mem_1 AND
	@isauto_v11mpositiontaking_mem_20 = @old_isauto_v11mpositiontaking_mem_20 AND

	@isauto_v99mpositiontaking_mem_1 = @old_isauto_v99mpositiontaking_mem_1 AND
	@isauto_v99mpositiontaking_mem_2 = @old_isauto_v99mpositiontaking_mem_2 AND
	@isauto_v99mpositiontaking_mem_3 = @old_isauto_v99mpositiontaking_mem_3 AND
	@isauto_v99mpositiontaking_mem_20 = @old_isauto_v99mpositiontaking_mem_20 
BEGIN
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	RETURN 
END

--Check um1<=l3
	SELECT @ErrType = ''
	SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((co.maxpositiontaking) AS VARCHAR(10))
	+ CASE WHEN b.sporttype=1 AND b.bettype IN (1,3,7,8) THEN '-MaxLive: '+ CAST((co.maxlivepositiontaking) AS VARCHAR(10)) ELSE '' END + '<br>'
	FROM custoverride AS co WITH (NOLOCK) INNER JOIN
		(
					SELECT 1 AS sporttype, 1 AS bettype, @auto_mpositiontaking_mem_1 AS autopositiontaking, @isauto_mpositiontaking_mem_1 AS isautopositiontaking, @auto_mlivepositiontaking_mem_1 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_1 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 3 AS bettype, @auto_mpositiontaking_mem_3 AS autopositiontaking, @isauto_mpositiontaking_mem_3 AS isautopositiontaking, @auto_mlivepositiontaking_mem_3 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_3 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 7 AS bettype, @auto_mpositiontaking_mem_7 AS autopositiontaking, @isauto_mpositiontaking_mem_7 AS isautopositiontaking, @auto_mlivepositiontaking_mem_7 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_7 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 8 AS bettype, @auto_mpositiontaking_mem_8 AS autopositiontaking, @isauto_mpositiontaking_mem_8 AS isautopositiontaking, @auto_mlivepositiontaking_mem_8 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_8 AS isautolivepositiontaking

			UNION ALL		SELECT 1 AS sporttype, 2 AS bettype, @auto_mpositiontaking_mem_2 AS autopositiontaking, @isauto_mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 4 AS bettype, @auto_mpositiontaking_mem_4 AS autopositiontaking, @isauto_mpositiontaking_mem_4 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 5 AS bettype, @auto_mpositiontaking_mem_5 AS autopositiontaking, @isauto_mpositiontaking_mem_5 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 6 AS bettype, @auto_mpositiontaking_mem_6 AS autopositiontaking, @isauto_mpositiontaking_mem_6 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 9 AS bettype, @auto_mpositiontaking_mem_9 AS autopositiontaking, @isauto_mpositiontaking_mem_9 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 10 AS bettype, @auto_mpositiontaking_mem_10 AS autopositiontaking, @isauto_mpositiontaking_mem_10 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 2 AS sporttype, 1 AS bettype, @auto_v2mpositiontaking_mem_1 AS autopositiontaking, @isauto_v2mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 2 AS bettype, @auto_v2mpositiontaking_mem_2 AS autopositiontaking, @isauto_v2mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 3 AS bettype, @auto_v2mpositiontaking_mem_3 AS autopositiontaking, @isauto_v2mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 7 AS bettype, @auto_v2mpositiontaking_mem_7 AS autopositiontaking, @isauto_v2mpositiontaking_mem_7 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 8 AS bettype, @auto_v2mpositiontaking_mem_8 AS autopositiontaking, @isauto_v2mpositiontaking_mem_8 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 9 AS bettype, @auto_v2mpositiontaking_mem_9 AS autopositiontaking, @isauto_v2mpositiontaking_mem_9 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 20 AS bettype, @auto_v2mpositiontaking_mem_20 AS autopositiontaking, @isauto_v2mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 3 AS sporttype, 1 AS bettype, @auto_v3mpositiontaking_mem_1 AS autopositiontaking, @isauto_v3mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 3 AS sporttype, 2 AS bettype, @auto_v3mpositiontaking_mem_2 AS autopositiontaking, @isauto_v3mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 3 AS sporttype, 3 AS bettype, @auto_v3mpositiontaking_mem_3 AS autopositiontaking, @isauto_v3mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 3 AS sporttype, 20 AS bettype, @auto_v3mpositiontaking_mem_20 AS autopositiontaking, @isauto_v3mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 5 AS sporttype, 1 AS bettype, @auto_v5mpositiontaking_mem_1 AS autopositiontaking, @isauto_v5mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 5 AS sporttype, 2 AS bettype, @auto_v5mpositiontaking_mem_2 AS autopositiontaking, @isauto_v5mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 5 AS sporttype, 3 AS bettype, @auto_v5mpositiontaking_mem_3 AS autopositiontaking, @isauto_v5mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 5 AS sporttype, 20 AS bettype, @auto_v5mpositiontaking_mem_20 AS autopositiontaking, @isauto_v5mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 8 AS sporttype, 1 AS bettype, @auto_v8mpositiontaking_mem_1 AS autopositiontaking, @isauto_v8mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 8 AS sporttype, 3 AS bettype, @auto_v8mpositiontaking_mem_3 AS autopositiontaking, @isauto_v8mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 8 AS sporttype, 20 AS bettype, @auto_v8mpositiontaking_mem_20 AS autopositiontaking, @isauto_v8mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 10 AS sporttype, 1 AS bettype, @auto_v10mpositiontaking_mem_1 AS autopositiontaking, @isauto_v10mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 10 AS sporttype, 2 AS bettype, @auto_v10mpositiontaking_mem_2 AS autopositiontaking, @isauto_v10mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 10 AS sporttype, 3 AS bettype, @auto_v10mpositiontaking_mem_3 AS autopositiontaking, @isauto_v10mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 10 AS sporttype, 20 AS bettype, @auto_v10mpositiontaking_mem_20 AS autopositiontaking, @isauto_v10mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 11 AS sporttype, 1 AS bettype, @auto_v11mpositiontaking_mem_1 AS autopositiontaking, @isauto_v11mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 11 AS sporttype, 20 AS bettype, @auto_v11mpositiontaking_mem_20 AS autopositiontaking, @isauto_v11mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 99 AS sporttype, 1 AS bettype, @auto_v99mpositiontaking_mem_1 AS autopositiontaking, @isauto_v99mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 99 AS sporttype, 2 AS bettype, @auto_v99mpositiontaking_mem_2 AS autopositiontaking, @isauto_v99mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 99 AS sporttype, 3 AS bettype, @auto_v99mpositiontaking_mem_3 AS autopositiontaking, @isauto_v99mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 99 AS sporttype, 20 AS bettype, @auto_v99mpositiontaking_mem_20 AS autopositiontaking, @isauto_v99mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			
		) AS b ON co.sporttype=b.sporttype AND co.bettype=b.bettype
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid

WHERE co.custid = @mrecommend AND ((b.isautopositiontaking>0 AND b.autopositiontaking>co.maxpositiontaking) OR (b.isautolivepositiontaking>0 AND b.sporttype=1 AND b.bettype IN (1,3,7,8) AND b.autolivepositiontaking>co.maxlivepositiontaking))

IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 6,
		   @ErrMsg_cur = CASE @Language 
						WHEN 'E' THEN 'Wrong position taking (min/max set by company) ('+@ErrType+').'
						WHEN 'CS' THEN N'占成数不正确(公司设给最低/高占成) ('+@ErrType+').'
						WHEN 'CT' THEN N'佔成數不正確(公司設給最低/高佔成) ('+@ErrType+').'
						WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท) ('+@ErrType+').'
						WHEN 'J' THEN N'Wrong position taking (min/max set by company) ('+@ErrType+').'
						WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값) ('+@ErrType+').'
						ELSE N'Wrong position taking (min/max set by company) ('+@ErrType+').'
				END
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)

	RETURN
END

--Check um1<=m3
	SELECT @ErrType = ''
	SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((mcs.mpositiontaking) AS VARCHAR(10))
	+ CASE WHEN b.sporttype=1 AND b.bettype IN (1,3,7,8) THEN '-MaxLive: '+ CAST((mcs.mlivepositiontaking) AS VARCHAR(10)) ELSE '' END + '<br>'
	FROM custsetting AS mcs WITH (NOLOCK) INNER JOIN
		(
					SELECT 1 AS sporttype, 1 AS bettype, @auto_mpositiontaking_mem_1 AS autopositiontaking, @isauto_mpositiontaking_mem_1 AS isautopositiontaking, @auto_mlivepositiontaking_mem_1 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_1 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 3 AS bettype, @auto_mpositiontaking_mem_3 AS autopositiontaking, @isauto_mpositiontaking_mem_3 AS isautopositiontaking, @auto_mlivepositiontaking_mem_3 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_3 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 7 AS bettype, @auto_mpositiontaking_mem_7 AS autopositiontaking, @isauto_mpositiontaking_mem_7 AS isautopositiontaking, @auto_mlivepositiontaking_mem_7 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_7 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 8 AS bettype, @auto_mpositiontaking_mem_8 AS autopositiontaking, @isauto_mpositiontaking_mem_8 AS isautopositiontaking, @auto_mlivepositiontaking_mem_8 AS autolivepositiontaking, @isauto_mlivepositiontaking_mem_8 AS isautolivepositiontaking

			UNION ALL		SELECT 1 AS sporttype, 2 AS bettype, @auto_mpositiontaking_mem_2 AS autopositiontaking, @isauto_mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 4 AS bettype, @auto_mpositiontaking_mem_4 AS autopositiontaking, @isauto_mpositiontaking_mem_4 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 5 AS bettype, @auto_mpositiontaking_mem_5 AS autopositiontaking, @isauto_mpositiontaking_mem_5 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 6 AS bettype, @auto_mpositiontaking_mem_6 AS autopositiontaking, @isauto_mpositiontaking_mem_6 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 9 AS bettype, @auto_mpositiontaking_mem_9 AS autopositiontaking, @isauto_mpositiontaking_mem_9 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 1 AS sporttype, 10 AS bettype, @auto_mpositiontaking_mem_10 AS autopositiontaking, @isauto_mpositiontaking_mem_10 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 2 AS sporttype, 1 AS bettype, @auto_v2mpositiontaking_mem_1 AS autopositiontaking, @isauto_v2mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 2 AS bettype, @auto_v2mpositiontaking_mem_2 AS autopositiontaking, @isauto_v2mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 3 AS bettype, @auto_v2mpositiontaking_mem_3 AS autopositiontaking, @isauto_v2mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 7 AS bettype, @auto_v2mpositiontaking_mem_7 AS autopositiontaking, @isauto_v2mpositiontaking_mem_7 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 8 AS bettype, @auto_v2mpositiontaking_mem_8 AS autopositiontaking, @isauto_v2mpositiontaking_mem_8 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 9 AS bettype, @auto_v2mpositiontaking_mem_9 AS autopositiontaking, @isauto_v2mpositiontaking_mem_9 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 2 AS sporttype, 20 AS bettype, @auto_v2mpositiontaking_mem_20 AS autopositiontaking, @isauto_v2mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 3 AS sporttype, 1 AS bettype, @auto_v3mpositiontaking_mem_1 AS autopositiontaking, @isauto_v3mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 3 AS sporttype, 2 AS bettype, @auto_v3mpositiontaking_mem_2 AS autopositiontaking, @isauto_v3mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 3 AS sporttype, 3 AS bettype, @auto_v3mpositiontaking_mem_3 AS autopositiontaking, @isauto_v3mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 3 AS sporttype, 20 AS bettype, @auto_v3mpositiontaking_mem_20 AS autopositiontaking, @isauto_v3mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 5 AS sporttype, 1 AS bettype, @auto_v5mpositiontaking_mem_1 AS autopositiontaking, @isauto_v5mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 5 AS sporttype, 2 AS bettype, @auto_v5mpositiontaking_mem_2 AS autopositiontaking, @isauto_v5mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 5 AS sporttype, 3 AS bettype, @auto_v5mpositiontaking_mem_3 AS autopositiontaking, @isauto_v5mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 5 AS sporttype, 20 AS bettype, @auto_v5mpositiontaking_mem_20 AS autopositiontaking, @isauto_v5mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 8 AS sporttype, 1 AS bettype, @auto_v8mpositiontaking_mem_1 AS autopositiontaking, @isauto_v8mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 8 AS sporttype, 3 AS bettype, @auto_v8mpositiontaking_mem_3 AS autopositiontaking, @isauto_v8mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 8 AS sporttype, 20 AS bettype, @auto_v8mpositiontaking_mem_20 AS autopositiontaking, @isauto_v8mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 10 AS sporttype, 1 AS bettype, @auto_v10mpositiontaking_mem_1 AS autopositiontaking, @isauto_v10mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 10 AS sporttype, 2 AS bettype, @auto_v10mpositiontaking_mem_2 AS autopositiontaking, @isauto_v10mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 10 AS sporttype, 3 AS bettype, @auto_v10mpositiontaking_mem_3 AS autopositiontaking, @isauto_v10mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 10 AS sporttype, 20 AS bettype, @auto_v10mpositiontaking_mem_20 AS autopositiontaking, @isauto_v10mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 11 AS sporttype, 1 AS bettype, @auto_v11mpositiontaking_mem_1 AS autopositiontaking, @isauto_v11mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 11 AS sporttype, 20 AS bettype, @auto_v11mpositiontaking_mem_20 AS autopositiontaking, @isauto_v11mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking

			UNION ALL		SELECT 99 AS sporttype, 1 AS bettype, @auto_v99mpositiontaking_mem_1 AS autopositiontaking, @isauto_v99mpositiontaking_mem_1 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 99 AS sporttype, 2 AS bettype, @auto_v99mpositiontaking_mem_2 AS autopositiontaking, @isauto_v99mpositiontaking_mem_2 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 99 AS sporttype, 3 AS bettype, @auto_v99mpositiontaking_mem_3 AS autopositiontaking, @isauto_v99mpositiontaking_mem_3 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			UNION ALL		SELECT 99 AS sporttype, 20 AS bettype, @auto_v99mpositiontaking_mem_20 AS autopositiontaking, @isauto_v99mpositiontaking_mem_20 AS isautopositiontaking, 0 AS autolivepositiontaking, 0 AS isautolivepositiontaking
			
		) AS b ON mcs.sporttype=b.sporttype AND mcs.bettype=b.bettype
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid
WHERE mcs.custid = @mrecommend AND ((b.isautopositiontaking>0 AND b.autopositiontaking>mcs.mpositiontaking) OR (b.isautolivepositiontaking>0 AND b.sporttype=1 AND b.bettype IN (1,3,7,8) AND b.autolivepositiontaking>mcs.mlivepositiontaking))

IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 7,
		   @ErrMsg_cur = @UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Wrong auto position taking.<br>'+@ErrType
							WHEN 'CS' THEN N'自动占成数不正确.<br>'+@ErrType
							WHEN 'CT' THEN N'自動佔成數不正確.<br>'+@ErrType
							WHEN 'TH' THEN N'การปรับยอดเงินที่ผิดพลาดอันเนื่องมาจากระบบ.<br>'+@ErrType
							WHEN 'J' THEN N'Wrong auto position taking.<br>'+@ErrType
							WHEN 'KO' THEN N'자동 거래조건이 잘못 되었습니다.<br>'+@ErrType
							ELSE N'Wrong auto position taking.<br>'+@ErrType
						END		
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		   @ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
								
	RETURN
END

--m3,u3,i3
SELECT @max_mapositiontaking_1 =mpositiontaking, @max_malivepositiontaking_1 =mlivepositiontaking, @auto_spositiontaking_1 = autopositiontaking, @auto_slivepositiontaking_1 = autolivepositiontaking, @isauto_spositiontaking_1 = isautopositiontaking, @isauto_slivepositiontaking_1 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=1
SELECT @max_mapositiontaking_3 =mpositiontaking, @max_malivepositiontaking_3 =mlivepositiontaking, @auto_spositiontaking_3 = autopositiontaking, @auto_slivepositiontaking_3 = autolivepositiontaking, @isauto_spositiontaking_3 = isautopositiontaking, @isauto_slivepositiontaking_3 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=1
SELECT @max_mapositiontaking_7 =mpositiontaking, @max_malivepositiontaking_7 =mlivepositiontaking, @auto_spositiontaking_7 = autopositiontaking, @auto_slivepositiontaking_7 = autolivepositiontaking, @isauto_spositiontaking_7 = isautopositiontaking, @isauto_slivepositiontaking_7 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=7 AND sporttype=1
SELECT @max_mapositiontaking_8 =mpositiontaking, @max_malivepositiontaking_8 =mlivepositiontaking, @auto_spositiontaking_8 = autopositiontaking, @auto_slivepositiontaking_8 = autolivepositiontaking, @isauto_spositiontaking_8 = isautopositiontaking, @isauto_slivepositiontaking_8 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=8 AND sporttype=1
SELECT @max_mapositiontaking_2 =mpositiontaking, @auto_spositiontaking_2 = autopositiontaking, @isauto_spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=1
SELECT @max_mapositiontaking_4 =mpositiontaking, @auto_spositiontaking_4 = autopositiontaking, @isauto_spositiontaking_4 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=4 AND sporttype=1
SELECT @max_mapositiontaking_5 =mpositiontaking, @auto_spositiontaking_5 = autopositiontaking, @isauto_spositiontaking_5 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=5 AND sporttype=1
SELECT @max_mapositiontaking_6 =mpositiontaking, @auto_spositiontaking_6 = autopositiontaking, @isauto_spositiontaking_6 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=6 AND sporttype=1
SELECT @max_mapositiontaking_9 =mpositiontaking, @auto_spositiontaking_9 = autopositiontaking, @isauto_spositiontaking_9 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=9 AND sporttype=1
SELECT @max_mapositiontaking_10 =mpositiontaking, @auto_spositiontaking_10 = autopositiontaking, @isauto_spositiontaking_10 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=10 AND sporttype=1

SELECT @max_v2mapositiontaking_1 =mpositiontaking, @auto_v2spositiontaking_1 = autopositiontaking, @isauto_v2spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=2
SELECT @max_v2mapositiontaking_2 =mpositiontaking, @auto_v2spositiontaking_2 = autopositiontaking, @isauto_v2spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=2
SELECT @max_v2mapositiontaking_3 =mpositiontaking, @auto_v2spositiontaking_3 = autopositiontaking, @isauto_v2spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=2
SELECT @max_v2mapositiontaking_7 =mpositiontaking, @auto_v2spositiontaking_7 = autopositiontaking, @isauto_v2spositiontaking_7 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=7 AND sporttype=2
SELECT @max_v2mapositiontaking_8 =mpositiontaking, @auto_v2spositiontaking_8 = autopositiontaking, @isauto_v2spositiontaking_8 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=8 AND sporttype=2
SELECT @max_v2mapositiontaking_9 =mpositiontaking, @auto_v2spositiontaking_9 = autopositiontaking, @isauto_v2spositiontaking_9 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=9 AND sporttype=2
SELECT @max_v2mapositiontaking_20 =mpositiontaking, @auto_v2spositiontaking_20 = autopositiontaking, @isauto_v2spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=2

SELECT @max_v3mapositiontaking_1 =mpositiontaking, @auto_v3spositiontaking_1 = autopositiontaking, @isauto_v3spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=3
SELECT @max_v3mapositiontaking_2 =mpositiontaking, @auto_v3spositiontaking_2 = autopositiontaking, @isauto_v3spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=3
SELECT @max_v3mapositiontaking_3 =mpositiontaking, @auto_v3spositiontaking_3 = autopositiontaking, @isauto_v3spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=3
SELECT @max_v3mapositiontaking_20 =mpositiontaking, @auto_v3spositiontaking_20 = autopositiontaking, @isauto_v3spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=3

SELECT @max_v5mapositiontaking_1 =mpositiontaking, @auto_v5spositiontaking_1 = autopositiontaking, @isauto_v5spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=5
SELECT @max_v5mapositiontaking_2 =mpositiontaking, @auto_v5spositiontaking_2 = autopositiontaking, @isauto_v5spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=5
SELECT @max_v5mapositiontaking_3 =mpositiontaking, @auto_v5spositiontaking_3 = autopositiontaking, @isauto_v5spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=5
SELECT @max_v5mapositiontaking_20 =mpositiontaking, @auto_v5spositiontaking_20 = autopositiontaking, @isauto_v5spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=5

SELECT @max_v8mapositiontaking_1 =mpositiontaking, @auto_v8spositiontaking_1 = autopositiontaking, @isauto_v8spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=8
SELECT @max_v8mapositiontaking_3 =mpositiontaking, @auto_v8spositiontaking_3 = autopositiontaking, @isauto_v8spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=8
SELECT @max_v8mapositiontaking_20 =mpositiontaking, @auto_v8spositiontaking_20 = autopositiontaking, @isauto_v8spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=8

SELECT @max_v10mapositiontaking_1 =mpositiontaking, @auto_v10spositiontaking_1 = autopositiontaking, @isauto_v10spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=10
SELECT @max_v10mapositiontaking_2 =mpositiontaking, @auto_v10spositiontaking_2 = autopositiontaking, @isauto_v10spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=10
SELECT @max_v10mapositiontaking_3 =mpositiontaking, @auto_v10spositiontaking_3 = autopositiontaking, @isauto_v10spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=10
SELECT @max_v10mapositiontaking_20 =mpositiontaking, @auto_v10spositiontaking_20 = autopositiontaking, @isauto_v10spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=10

SELECT @max_v11mapositiontaking_1 =mpositiontaking, @auto_v11spositiontaking_1 = autopositiontaking, @isauto_v11spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=11
SELECT @max_v11mapositiontaking_20 =mpositiontaking, @auto_v11spositiontaking_20 = autopositiontaking, @isauto_v11spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=11

SELECT @max_v99mapositiontaking_1 =mpositiontaking, @auto_v99spositiontaking_1 = autopositiontaking, @isauto_v99spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=99
SELECT @max_v99mapositiontaking_2 =mpositiontaking, @auto_v99spositiontaking_2 = autopositiontaking, @isauto_v99spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=99
SELECT @max_v99mapositiontaking_3 =mpositiontaking, @auto_v99spositiontaking_3 = autopositiontaking, @isauto_v99spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=99
SELECT @max_v99mapositiontaking_20 =mpositiontaking, @auto_v99spositiontaking_20 = autopositiontaking, @isauto_v99spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=99
--n3
SELECT @min_mapositiontaking_1 = minpositiontaking, @min_malivepositiontaking_1 = minlivepositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=1
SELECT @min_mapositiontaking_3 = minpositiontaking, @min_malivepositiontaking_3 = minlivepositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=1
SELECT @min_mapositiontaking_7 = minpositiontaking, @min_malivepositiontaking_7 = minlivepositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=7 AND sporttype=1
SELECT @min_mapositiontaking_8 = minpositiontaking, @min_malivepositiontaking_8 = minlivepositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=8 AND sporttype=1
SELECT @min_mapositiontaking_2 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=1
SELECT @min_mapositiontaking_4 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=4 AND sporttype=1
SELECT @min_mapositiontaking_5 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=5 AND sporttype=1
SELECT @min_mapositiontaking_6 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=6 AND sporttype=1
SELECT @min_mapositiontaking_9 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=9 AND sporttype=1
SELECT @min_mapositiontaking_10 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=10 AND sporttype=1

SELECT @min_v2mapositiontaking_1 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=2
SELECT @min_v2mapositiontaking_2 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=2 
SELECT @min_v2mapositiontaking_3 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=2
SELECT @min_v2mapositiontaking_7 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=7 AND sporttype=2
SELECT @min_v2mapositiontaking_8 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=8 AND sporttype=2
SELECT @min_v2mapositiontaking_9 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=9 AND sporttype=2
SELECT @min_v2mapositiontaking_20 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=2

SELECT @min_v3mapositiontaking_1 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=3
SELECT @min_v3mapositiontaking_2 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=3 
SELECT @min_v3mapositiontaking_3 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=3
SELECT @min_v3mapositiontaking_20 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=3

SELECT @min_v5mapositiontaking_1 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=5
SELECT @min_v5mapositiontaking_2 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=5 
SELECT @min_v5mapositiontaking_3 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=5
SELECT @min_v5mapositiontaking_20 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=5

SELECT @min_v8mapositiontaking_1 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=8
SELECT @min_v8mapositiontaking_3 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=8
SELECT @min_v8mapositiontaking_20 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=8

SELECT @min_v10mapositiontaking_1 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=10
SELECT @min_v10mapositiontaking_2 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=10 
SELECT @min_v10mapositiontaking_3 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=10
SELECT @min_v10mapositiontaking_20 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=10

SELECT @min_v11mapositiontaking_1 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=11
SELECT @min_v11mapositiontaking_20 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=11

SELECT @min_v99mapositiontaking_1 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=99
SELECT @min_v99mapositiontaking_2 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=99 
SELECT @min_v99mapositiontaking_3 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=99
SELECT @min_v99mapositiontaking_20 = minpositiontaking FROM custoverride WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=99

--s4
SELECT @max_spositiontaking_1 = spositiontaking, @max_slivepositiontaking_1 = slivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=1
SELECT @max_spositiontaking_3 = spositiontaking, @max_slivepositiontaking_3 = slivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=1
SELECT @max_spositiontaking_7 = spositiontaking, @max_slivepositiontaking_7 = slivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=7 AND sporttype=1
SELECT @max_spositiontaking_8 = spositiontaking, @max_slivepositiontaking_8 = slivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=8 AND sporttype=1
SELECT @max_spositiontaking_2 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=1
SELECT @max_spositiontaking_4 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=4 AND sporttype=1
SELECT @max_spositiontaking_5 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=5 AND sporttype=1
SELECT @max_spositiontaking_6 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=6 AND sporttype=1
SELECT @max_spositiontaking_9 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=9 AND sporttype=1
SELECT @max_spositiontaking_10 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=10 AND sporttype=1

SELECT @max_v2spositiontaking_1 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=2
SELECT @max_v2spositiontaking_2 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=2
SELECT @max_v2spositiontaking_3 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=2
SELECT @max_v2spositiontaking_7 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=7 AND sporttype=2
SELECT @max_v2spositiontaking_8 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=8 AND sporttype=2
SELECT @max_v2spositiontaking_9 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=9 AND sporttype=2
SELECT @max_v2spositiontaking_20 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=20 AND sporttype=2

SELECT @max_v3spositiontaking_1 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=3
SELECT @max_v3spositiontaking_2 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=3
SELECT @max_v3spositiontaking_3 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=3
SELECT @max_v3spositiontaking_20 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=20 AND sporttype=3

SELECT @max_v5spositiontaking_1 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=5
SELECT @max_v5spositiontaking_2 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=5
SELECT @max_v5spositiontaking_3 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=5
SELECT @max_v5spositiontaking_20 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=20 AND sporttype=5

SELECT @max_v8spositiontaking_1 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=8
SELECT @max_v8spositiontaking_3 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=8
SELECT @max_v8spositiontaking_20 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=20 AND sporttype=8

SELECT @max_v10spositiontaking_1 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=10
SELECT @max_v10spositiontaking_2 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=10
SELECT @max_v10spositiontaking_3 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=10
SELECT @max_v10spositiontaking_20 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=20 AND sporttype=10

SELECT @max_v11spositiontaking_1 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=11
SELECT @max_v11spositiontaking_20 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=20 AND sporttype=11

SELECT @max_v99spositiontaking_1 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=1 AND sporttype=99
SELECT @max_v99spositiontaking_2 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=2 AND sporttype=99
SELECT @max_v99spositiontaking_3 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=3 AND sporttype=99
SELECT @max_v99spositiontaking_20 = spositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @srecommend AND bettype=20 AND sporttype=99

--um2
SELECT 
	@auto_mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_4 = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_5 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_6 = MAX(CASE WHEN acs.bettype = 6 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_7 = MAX(CASE WHEN acs.bettype = 7 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_8 = MAX(CASE WHEN acs.bettype = 8 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_9 = MAX(CASE WHEN acs.bettype = 9 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	@auto_mpositiontaking_10 = MAX(CASE WHEN acs.bettype = 10 AND acs.sporttype=1 THEN acs.autompositiontaking ELSE 0 END),
	
	@auto_mlivepositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.autolivempositiontaking ELSE 0 END),
	@auto_mlivepositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=1 THEN acs.autolivempositiontaking ELSE 0 END),
	@auto_mlivepositiontaking_7 = MAX(CASE WHEN acs.bettype = 7 AND acs.sporttype=1 THEN acs.autolivempositiontaking ELSE 0 END),
	@auto_mlivepositiontaking_8 = MAX(CASE WHEN acs.bettype = 8 AND acs.sporttype=1 THEN acs.autolivempositiontaking ELSE 0 END),

	@auto_v2mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=2 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v2mpositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=2 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v2mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=2 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v2mpositiontaking_7 = MAX(CASE WHEN acs.bettype = 7 AND acs.sporttype=2 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v2mpositiontaking_8 = MAX(CASE WHEN acs.bettype = 8 AND acs.sporttype=2 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v2mpositiontaking_9 = MAX(CASE WHEN acs.bettype = 9 AND acs.sporttype=2 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v2mpositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=2 THEN acs.autompositiontaking ELSE 0 END),

	@auto_v3mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=3 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v3mpositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=3 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v3mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=3 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v3mpositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=3 THEN acs.autompositiontaking ELSE 0 END),

	@auto_v5mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=5 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v5mpositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=5 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v5mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=5 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v5mpositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=5 THEN acs.autompositiontaking ELSE 0 END),

	@auto_v8mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=8 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v8mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=8 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v8mpositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=8 THEN acs.autompositiontaking ELSE 0 END),

	@auto_v10mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=10 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v10mpositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=10 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v10mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=10 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v10mpositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=10 THEN acs.autompositiontaking ELSE 0 END),

	@auto_v11mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=11 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v11mpositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=11 THEN acs.autompositiontaking ELSE 0 END),

	@auto_v99mpositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=99 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v99mpositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=99 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v99mpositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=99 THEN acs.autompositiontaking ELSE 0 END),
	@auto_v99mpositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=99 THEN acs.autompositiontaking ELSE 0 END),
	
	--a2	
	@max_apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_4 = MAX(CASE WHEN acs.bettype = 4 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_5 = MAX(CASE WHEN acs.bettype = 5 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_6 = MAX(CASE WHEN acs.bettype = 6 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_7 = MAX(CASE WHEN acs.bettype = 7 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_8 = MAX(CASE WHEN acs.bettype = 8 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_9 = MAX(CASE WHEN acs.bettype = 9 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	@max_apositiontaking_10 = MAX(CASE WHEN acs.bettype = 10 AND acs.sporttype=1 THEN acs.apositiontaking ELSE 0 END),
	
	@max_alivepositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=1 THEN acs.alivepositiontaking ELSE 0 END),
	@max_alivepositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=1 THEN acs.alivepositiontaking ELSE 0 END),
	@max_alivepositiontaking_7 = MAX(CASE WHEN acs.bettype = 7 AND acs.sporttype=1 THEN acs.alivepositiontaking ELSE 0 END),
	@max_alivepositiontaking_8 = MAX(CASE WHEN acs.bettype = 8 AND acs.sporttype=1 THEN acs.alivepositiontaking ELSE 0 END),

	@max_v2apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=2 THEN acs.apositiontaking ELSE 0 END),
	@max_v2apositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=2 THEN acs.apositiontaking ELSE 0 END),
	@max_v2apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=2 THEN acs.apositiontaking ELSE 0 END),
	@max_v2apositiontaking_7 = MAX(CASE WHEN acs.bettype = 7 AND acs.sporttype=2 THEN acs.apositiontaking ELSE 0 END),
	@max_v2apositiontaking_8 = MAX(CASE WHEN acs.bettype = 8 AND acs.sporttype=2 THEN acs.apositiontaking ELSE 0 END),
	@max_v2apositiontaking_9 = MAX(CASE WHEN acs.bettype = 9 AND acs.sporttype=2 THEN acs.apositiontaking ELSE 0 END),
	@max_v2apositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=2 THEN acs.apositiontaking ELSE 0 END),

	@max_v3apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=3 THEN acs.apositiontaking ELSE 0 END),
	@max_v3apositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=3 THEN acs.apositiontaking ELSE 0 END),
	@max_v3apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=3 THEN acs.apositiontaking ELSE 0 END),
	@max_v3apositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=3 THEN acs.apositiontaking ELSE 0 END),

	@max_v5apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=5 THEN acs.apositiontaking ELSE 0 END),
	@max_v5apositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=5 THEN acs.apositiontaking ELSE 0 END),
	@max_v5apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=5 THEN acs.apositiontaking ELSE 0 END),
	@max_v5apositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=5 THEN acs.apositiontaking ELSE 0 END),

	@max_v8apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=8 THEN acs.apositiontaking ELSE 0 END),
	@max_v8apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=8 THEN acs.apositiontaking ELSE 0 END),
	@max_v8apositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=8 THEN acs.apositiontaking ELSE 0 END),

	@max_v10apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=10 THEN acs.apositiontaking ELSE 0 END),
	@max_v10apositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=10 THEN acs.apositiontaking ELSE 0 END),
	@max_v10apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=10 THEN acs.apositiontaking ELSE 0 END),
	@max_v10apositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=10 THEN acs.apositiontaking ELSE 0 END),

	@max_v11apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=11 THEN acs.apositiontaking ELSE 0 END),
	@max_v11apositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=11 THEN acs.apositiontaking ELSE 0 END),

	@max_v99apositiontaking_1 = MAX(CASE WHEN acs.bettype = 1 AND acs.sporttype=99 THEN acs.apositiontaking ELSE 0 END),
	@max_v99apositiontaking_2 = MAX(CASE WHEN acs.bettype = 2 AND acs.sporttype=99 THEN acs.apositiontaking ELSE 0 END),
	@max_v99apositiontaking_3 = MAX(CASE WHEN acs.bettype = 3 AND acs.sporttype=99 THEN acs.apositiontaking ELSE 0 END),
	@max_v99apositiontaking_20 = MAX(CASE WHEN acs.bettype = 20 AND acs.sporttype=99 THEN acs.apositiontaking ELSE 0 END)
FROM custsetting acs WITH(NOLOCK)
WHERE acs.custid = @recommend


--Check m1<=m3
SELECT @ErrType = ''
SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((b.maxmpositiontaking) AS VARCHAR(10))
+ CASE WHEN b.sporttype=1 AND b.bettype IN (1,3,7,8) THEN '-MaxLive: '+ CAST((b.maxmlivepositiontaking) AS VARCHAR(10)) ELSE '' END + '<br>'
FROM (
						SELECT 1 AS sporttype	,	 1 AS bettype	,	 @mpositiontaking_1 AS mpositiontaking	,	 @max_mapositiontaking_1 AS maxmpositiontaking	,	 @mlivepositiontaking_1 AS mlivepositiontaking	,	 @max_malivepositiontaking_1 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 3 AS bettype	,	 @mpositiontaking_3 AS mpositiontaking	,	 @max_mapositiontaking_3 AS maxmpositiontaking	,	 @mlivepositiontaking_3 AS mlivepositiontaking	,	 @max_malivepositiontaking_3 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 7 AS bettype	,	 @mpositiontaking_7 AS mpositiontaking	,	 @max_mapositiontaking_7 AS maxmpositiontaking	,	 @mlivepositiontaking_7 AS mlivepositiontaking	,	 @max_malivepositiontaking_7 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 8 AS bettype	,	 @mpositiontaking_8 AS mpositiontaking	,	 @max_mapositiontaking_8 AS maxmpositiontaking	,	 @mlivepositiontaking_8 AS mlivepositiontaking	,	 @max_malivepositiontaking_8 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 1 AS sporttype	,	 2 AS bettype	,	 @mpositiontaking_2 AS mpositiontaking	,	 @max_mapositiontaking_2 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 4 AS bettype	,	 @mpositiontaking_4 AS mpositiontaking	,	 @max_mapositiontaking_4 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 5 AS bettype	,	 @mpositiontaking_5 AS mpositiontaking	,	 @max_mapositiontaking_5 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 6 AS bettype	,	 @mpositiontaking_6 AS mpositiontaking	,	 @max_mapositiontaking_6 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 9 AS bettype	,	 @mpositiontaking_9 AS mpositiontaking	,	 @max_mapositiontaking_9 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 1 AS sporttype	,	 10 AS bettype	,	 @mpositiontaking_10 AS mpositiontaking	,	 @max_mapositiontaking_10 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 2 AS sporttype	,	 1 AS bettype	,	 @v2mpositiontaking_1 AS mpositiontaking	,	 @max_v2mapositiontaking_1 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 2 AS sporttype	,	 2 AS bettype	,	 @v2mpositiontaking_2 AS mpositiontaking	,	 @max_v2mapositiontaking_2 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 2 AS sporttype	,	 3 AS bettype	,	 @v2mpositiontaking_3 AS mpositiontaking	,	 @max_v2mapositiontaking_3 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 2 AS sporttype	,	 7 AS bettype	,	 @v2mpositiontaking_7 AS mpositiontaking	,	 @max_v2mapositiontaking_7 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 2 AS sporttype	,	 8 AS bettype	,	 @v2mpositiontaking_8 AS mpositiontaking	,	 @max_v2mapositiontaking_8 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 2 AS sporttype	,	 9 AS bettype	,	 @v2mpositiontaking_9 AS mpositiontaking	,	 @max_v2mapositiontaking_9 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 2 AS sporttype	,	 20 AS bettype	,	 @v2mpositiontaking_20 AS mpositiontaking	,	 @max_v2mapositiontaking_20 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 3 AS sporttype	,	 1 AS bettype	,	 @v3mpositiontaking_1 AS mpositiontaking	,	 @max_v3mapositiontaking_1 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 3 AS sporttype	,	 2 AS bettype	,	 @v3mpositiontaking_2 AS mpositiontaking	,	 @max_v3mapositiontaking_2 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 3 AS sporttype	,	 3 AS bettype	,	 @v3mpositiontaking_3 AS mpositiontaking	,	 @max_v3mapositiontaking_3 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 3 AS sporttype	,	 20 AS bettype	,	 @v3mpositiontaking_20 AS mpositiontaking	,	 @max_v3mapositiontaking_20 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 5 AS sporttype	,	 1 AS bettype	,	 @v5mpositiontaking_1 AS mpositiontaking	,	 @max_v5mapositiontaking_1 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 5 AS sporttype	,	 2 AS bettype	,	 @v5mpositiontaking_2 AS mpositiontaking	,	 @max_v5mapositiontaking_2 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 5 AS sporttype	,	 3 AS bettype	,	 @v5mpositiontaking_3 AS mpositiontaking	,	 @max_v5mapositiontaking_3 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 5 AS sporttype	,	 20 AS bettype	,	 @v5mpositiontaking_20 AS mpositiontaking	,	 @max_v5mapositiontaking_20 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 8 AS sporttype	,	 1 AS bettype	,	 @v8mpositiontaking_1 AS mpositiontaking	,	 @max_v8mapositiontaking_1 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 8 AS sporttype	,	 3 AS bettype	,	 @v8mpositiontaking_3 AS mpositiontaking	,	 @max_v8mapositiontaking_3 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 8 AS sporttype	,	 20 AS bettype	,	 @v8mpositiontaking_20 AS mpositiontaking	,	 @max_v8mapositiontaking_20 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 10 AS sporttype	,	 1 AS bettype	,	 @v10mpositiontaking_1 AS mpositiontaking	,	 @max_v10mapositiontaking_1 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 10 AS sporttype	,	 2 AS bettype	,	 @v10mpositiontaking_2 AS mpositiontaking	,	 @max_v10mapositiontaking_2 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 10 AS sporttype	,	 3 AS bettype	,	 @v10mpositiontaking_3 AS mpositiontaking	,	 @max_v10mapositiontaking_3 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 10 AS sporttype	,	 20 AS bettype	,	 @v10mpositiontaking_20 AS mpositiontaking	,	 @max_v10mapositiontaking_20 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 11 AS sporttype	,	 1 AS bettype	,	 @v11mpositiontaking_1 AS mpositiontaking	,	 @max_v11mapositiontaking_1 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 11 AS sporttype	,	 20 AS bettype	,	 @v11mpositiontaking_20 AS mpositiontaking	,	 @max_v11mapositiontaking_20 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
														
		UNION ALL		SELECT 99 AS sporttype	,	 1 AS bettype	,	 @v99mpositiontaking_1 AS mpositiontaking	,	 @max_v99mapositiontaking_1 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 99 AS sporttype	,	 2 AS bettype	,	 @v99mpositiontaking_2 AS mpositiontaking	,	 @max_v99mapositiontaking_2 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 99 AS sporttype	,	 3 AS bettype	,	 @v99mpositiontaking_3 AS mpositiontaking	,	 @max_v99mapositiontaking_3 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
		UNION ALL		SELECT 99 AS sporttype	,	 20 AS bettype	,	 @v99mpositiontaking_20 AS mpositiontaking	,	 @max_v99mapositiontaking_20 AS maxmpositiontaking	,	 0 AS mlivepositiontaking	,	 0 AS maxmlivepositiontaking
)b 	
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid
WHERE (b.mpositiontaking>b.maxmpositiontaking) 
	OR (b.sporttype=1 AND b.bettype IN (1,3,7,8) AND b.mlivepositiontaking>b.maxmlivepositiontaking)

IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 8,
			@ErrMsg_cur = @UserName + ': '+
						CASE @Language 
							WHEN 'E' THEN 'Wrong  position taking.<br>'+@ErrType
							WHEN 'CS' THEN N'占成数不正确.<br>'+@ErrType
							WHEN 'CT' THEN N'佔成數不正確.<br>'+@ErrType
							WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง.<br>'+@ErrType
							WHEN 'J' THEN N'Wrong  position taking.<br>'+@ErrType
							WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
							ELSE N'Wrong  position taking.<br>'+@ErrType
						END							
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		
	RETURN
END
--Check m1<=l3
SELECT @ErrType = ''
SELECT @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ CAST((co.maxpositiontaking) AS VARCHAR(10))
+ CASE WHEN b.sporttype=1 AND b.bettype IN (1,3,7,8) THEN '-MaxLive: '+ CAST((co.maxlivepositiontaking) AS VARCHAR(10)) ELSE '' END + '<br>'
	FROM custoverride AS co WITH (NOLOCK) INNER JOIN
		(
							SELECT 1 AS sporttype	,	 1 AS bettype	,	 @mpositiontaking_1 AS mpositiontaking	,	 @mlivepositiontaking_1 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 3 AS bettype	,	 @mpositiontaking_3 AS mpositiontaking	,	 @mlivepositiontaking_3 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 7 AS bettype	,	 @mpositiontaking_7 AS mpositiontaking	,	 @mlivepositiontaking_7 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 8 AS bettype	,	 @mpositiontaking_8 AS mpositiontaking	,	 @mlivepositiontaking_8 AS mlivepositiontaking
											
			UNION ALL		SELECT 1 AS sporttype	,	 2 AS bettype	,	 @mpositiontaking_2 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 4 AS bettype	,	 @mpositiontaking_4 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 5 AS bettype	,	 @mpositiontaking_5 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 6 AS bettype	,	 @mpositiontaking_6 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 9 AS bettype	,	 @mpositiontaking_9 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 1 AS sporttype	,	 10 AS bettype	,	 @mpositiontaking_10 AS mpositiontaking	,	 0 AS mlivepositiontaking
											
			UNION ALL		SELECT 2 AS sporttype	,	 1 AS bettype	,	 @v2mpositiontaking_1 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 2 AS sporttype	,	 2 AS bettype	,	 @v2mpositiontaking_2 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 2 AS sporttype	,	 3 AS bettype	,	 @v2mpositiontaking_3 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 2 AS sporttype	,	 7 AS bettype	,	 @v2mpositiontaking_7 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 2 AS sporttype	,	 8 AS bettype	,	 @v2mpositiontaking_8 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 2 AS sporttype	,	 9 AS bettype	,	 @v2mpositiontaking_9 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 2 AS sporttype	,	 20 AS bettype	,	 @v2mpositiontaking_20 AS mpositiontaking	,	 0 AS mlivepositiontaking
											
			UNION ALL		SELECT 3 AS sporttype	,	 1 AS bettype	,	 @v3mpositiontaking_1 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 3 AS sporttype	,	 2 AS bettype	,	 @v3mpositiontaking_2 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 3 AS sporttype	,	 3 AS bettype	,	 @v3mpositiontaking_3 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 3 AS sporttype	,	 20 AS bettype	,	 @v3mpositiontaking_20 AS mpositiontaking	,	 0 AS mlivepositiontaking
											
			UNION ALL		SELECT 5 AS sporttype	,	 1 AS bettype	,	 @v5mpositiontaking_1 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 5 AS sporttype	,	 2 AS bettype	,	 @v5mpositiontaking_2 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 5 AS sporttype	,	 3 AS bettype	,	 @v5mpositiontaking_3 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 5 AS sporttype	,	 20 AS bettype	,	 @v5mpositiontaking_20 AS mpositiontaking	,	 0 AS mlivepositiontaking
											
			UNION ALL		SELECT 8 AS sporttype	,	 1 AS bettype	,	 @v8mpositiontaking_1 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 8 AS sporttype	,	 3 AS bettype	,	 @v8mpositiontaking_3 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 8 AS sporttype	,	 20 AS bettype	,	 @v8mpositiontaking_20 AS mpositiontaking	,	 0 AS mlivepositiontaking
											
			UNION ALL		SELECT 10 AS sporttype	,	 1 AS bettype	,	 @v10mpositiontaking_1 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 10 AS sporttype	,	 2 AS bettype	,	 @v10mpositiontaking_2 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 10 AS sporttype	,	 3 AS bettype	,	 @v10mpositiontaking_3 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 10 AS sporttype	,	 20 AS bettype	,	 @v10mpositiontaking_20 AS mpositiontaking	,	 0 AS mlivepositiontaking
											
			UNION ALL		SELECT 11 AS sporttype	,	 1 AS bettype	,	 @v11mpositiontaking_1 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 11 AS sporttype	,	 20 AS bettype	,	 @v11mpositiontaking_20 AS mpositiontaking	,	 0 AS mlivepositiontaking
											
			UNION ALL		SELECT 99 AS sporttype	,	 1 AS bettype	,	 @v99mpositiontaking_1 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 99 AS sporttype	,	 2 AS bettype	,	 @v99mpositiontaking_2 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 99 AS sporttype	,	 3 AS bettype	,	 @v99mpositiontaking_3 AS mpositiontaking	,	 0 AS mlivepositiontaking
			UNION ALL		SELECT 99 AS sporttype	,	 20 AS bettype	,	 @v99mpositiontaking_20 AS mpositiontaking	,	 0 AS mlivepositiontaking
		) AS b ON co.sporttype=b.sporttype AND co.bettype=b.bettype
	INNER JOIN sports WITH (NOLOCK) ON b.sporttype = sports.sporttype
	INNER JOIN bettype WITH (NOLOCK) ON b.bettype = bettype.typeid
WHERE co.custid = @mrecommend AND ((b.mpositiontaking>co.maxpositiontaking) OR (b.sporttype=1 AND b.bettype IN (1,3,7,8) AND b.mlivepositiontaking>co.maxlivepositiontaking))
IF @ErrType <>''
BEGIN
	SELECT @ErrCode_cur = 9,
  			@ErrMsg_cur = @UserName + ': '+
				 CASE @Language 
						WHEN 'E' THEN 'Wrong position taking (min/max set by company) ('+@ErrType+').'
						WHEN 'CS' THEN N'占成数不正确(公司设给最低/高占成) ('+@ErrType+').'
						WHEN 'CT' THEN N'佔成數不正確(公司設給最低/高佔成) ('+@ErrType+').'
						WHEN 'TH' THEN N'การกำหนดไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท) ('+@ErrType+').'
						WHEN 'J' THEN N'Wrong position taking (min/max set by company) ('+@ErrType+').'
						WHEN 'KO' THEN N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값) ('+@ErrType+').'
						ELSE N'Wrong position taking (min/max set by company) ('+@ErrType+').'
				END
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
		   @ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	RETURN
END

--m1=m1+a1>m3?m3-a1:m1
SELECT 
	@mpositiontaking_1 = CASE WHEN @mpositiontaking_1+@apositiontaking_1>@max_mapositiontaking_1 THEN @max_mapositiontaking_1-@apositiontaking_1 ELSE @mpositiontaking_1 END,
	@mpositiontaking_2 = CASE WHEN @mpositiontaking_2+@apositiontaking_2>@max_mapositiontaking_2 THEN @max_mapositiontaking_2-@apositiontaking_2 ELSE @mpositiontaking_2 END,
	@mpositiontaking_3 = CASE WHEN @mpositiontaking_3+@apositiontaking_3>@max_mapositiontaking_3 THEN @max_mapositiontaking_3-@apositiontaking_3 ELSE @mpositiontaking_3 END,
	@mpositiontaking_4 = CASE WHEN @mpositiontaking_4+@apositiontaking_4>@max_mapositiontaking_4 THEN @max_mapositiontaking_4-@apositiontaking_4 ELSE @mpositiontaking_4 END,
	@mpositiontaking_5 = CASE WHEN @mpositiontaking_5+@apositiontaking_5>@max_mapositiontaking_5 THEN @max_mapositiontaking_5-@apositiontaking_5 ELSE @mpositiontaking_5 END,
	@mpositiontaking_6 = CASE WHEN @mpositiontaking_6+@apositiontaking_6>@max_mapositiontaking_6 THEN @max_mapositiontaking_6-@apositiontaking_6 ELSE @mpositiontaking_6 END,
	@mpositiontaking_7 = CASE WHEN @mpositiontaking_7+@apositiontaking_7>@max_mapositiontaking_7 THEN @max_mapositiontaking_7-@apositiontaking_7 ELSE @mpositiontaking_7 END,
	@mpositiontaking_8 = CASE WHEN @mpositiontaking_8+@apositiontaking_8>@max_mapositiontaking_8 THEN @max_mapositiontaking_8-@apositiontaking_8 ELSE @mpositiontaking_8 END,
	@mpositiontaking_9 = CASE WHEN @mpositiontaking_9+@apositiontaking_9>@max_mapositiontaking_9 THEN @max_mapositiontaking_9-@apositiontaking_9 ELSE @mpositiontaking_9 END,
	@mpositiontaking_10 = CASE WHEN @mpositiontaking_10+@apositiontaking_10>@max_mapositiontaking_10 THEN @max_mapositiontaking_10-@apositiontaking_10 ELSE @mpositiontaking_10 END,

	@mlivepositiontaking_1 = CASE WHEN @mlivepositiontaking_1+@alivepositiontaking_1>@max_malivepositiontaking_1 THEN @max_malivepositiontaking_1-@alivepositiontaking_1 ELSE @mlivepositiontaking_1 END,
	@mlivepositiontaking_3 = CASE WHEN @mlivepositiontaking_3+@alivepositiontaking_3>@max_malivepositiontaking_3 THEN @max_malivepositiontaking_3-@alivepositiontaking_3 ELSE @mlivepositiontaking_3 END,
	@mlivepositiontaking_7 = CASE WHEN @mlivepositiontaking_7+@alivepositiontaking_7>@max_malivepositiontaking_7 THEN @max_malivepositiontaking_7-@alivepositiontaking_7 ELSE @mlivepositiontaking_7 END,
	@mlivepositiontaking_8 = CASE WHEN @mlivepositiontaking_8+@alivepositiontaking_8>@max_malivepositiontaking_8 THEN @max_malivepositiontaking_8-@alivepositiontaking_8 ELSE @mlivepositiontaking_8 END,

	@v2mpositiontaking_1 = CASE WHEN @v2apositiontaking_1+@v2mpositiontaking_1>@max_v2mapositiontaking_1 THEN @max_v2mapositiontaking_1-@v2apositiontaking_1 ELSE @v2mpositiontaking_1 END,
	@v2mpositiontaking_2 = CASE WHEN @v2apositiontaking_2+@v2mpositiontaking_2>@max_v2mapositiontaking_2 THEN @max_v2mapositiontaking_2-@v2apositiontaking_2 ELSE @v2mpositiontaking_2 END,
	@v2mpositiontaking_3 = CASE WHEN @v2apositiontaking_3+@v2mpositiontaking_3>@max_v2mapositiontaking_3 THEN @max_v2mapositiontaking_3-@v2apositiontaking_3 ELSE @v2mpositiontaking_3 END,
	@v2mpositiontaking_7 = CASE WHEN @v2apositiontaking_7+@v2mpositiontaking_7>@max_v2mapositiontaking_7 THEN @max_v2mapositiontaking_7-@v2apositiontaking_7 ELSE @v2mpositiontaking_7 END,
	@v2mpositiontaking_8 = CASE WHEN @v2apositiontaking_8+@v2mpositiontaking_8>@max_v2mapositiontaking_8 THEN @max_v2mapositiontaking_8-@v2apositiontaking_8 ELSE @v2mpositiontaking_8 END,
	@v2mpositiontaking_9 = CASE WHEN @v2apositiontaking_9+@v2mpositiontaking_9>@max_v2mapositiontaking_9 THEN @max_v2mapositiontaking_9-@v2apositiontaking_9 ELSE @v2mpositiontaking_9 END,
	@v2mpositiontaking_20 = CASE WHEN @v2apositiontaking_20+@v2mpositiontaking_20>@max_v2mapositiontaking_20 THEN @max_v2mapositiontaking_20-@v2apositiontaking_20 ELSE @v2mpositiontaking_20 END,

	@v3mpositiontaking_1 = CASE WHEN @v3apositiontaking_1+@v3mpositiontaking_1>@max_v3mapositiontaking_1 THEN @max_v3mapositiontaking_1-@v3apositiontaking_1 ELSE @v3mpositiontaking_1 END,
	@v3mpositiontaking_2 = CASE WHEN @v3apositiontaking_2+@v3mpositiontaking_2>@max_v3mapositiontaking_2 THEN @max_v3mapositiontaking_2-@v3apositiontaking_2 ELSE @v3mpositiontaking_2 END,
	@v3mpositiontaking_3 = CASE WHEN @v3apositiontaking_3+@v3mpositiontaking_3>@max_v3mapositiontaking_3 THEN @max_v3mapositiontaking_3-@v3apositiontaking_3 ELSE @v3mpositiontaking_3 END,
	@v3mpositiontaking_20 = CASE WHEN @v3apositiontaking_20+@v3mpositiontaking_20>@max_v3mapositiontaking_20 THEN @max_v3mapositiontaking_20-@v3apositiontaking_20 ELSE @v3mpositiontaking_20 END,

	@v5mpositiontaking_1 = CASE WHEN @v5apositiontaking_1+@v5mpositiontaking_1>@max_v5mapositiontaking_1 THEN @max_v5mapositiontaking_1-@v5apositiontaking_1 ELSE @v5mpositiontaking_1 END,
	@v5mpositiontaking_2 = CASE WHEN @v5apositiontaking_2+@v5mpositiontaking_2>@max_v5mapositiontaking_2 THEN @max_v5mapositiontaking_2-@v5apositiontaking_2 ELSE @v5mpositiontaking_2 END,
	@v5mpositiontaking_3 = CASE WHEN @v5apositiontaking_3+@v5mpositiontaking_3>@max_v5mapositiontaking_3 THEN @max_v5mapositiontaking_3-@v5apositiontaking_3 ELSE @v5mpositiontaking_3 END,
	@v5mpositiontaking_20 = CASE WHEN @v5apositiontaking_20+@v5mpositiontaking_20>@max_v5mapositiontaking_20 THEN @max_v5mapositiontaking_20-@v5apositiontaking_20 ELSE @v5mpositiontaking_20 END,

	@v8mpositiontaking_1 = CASE WHEN @v8apositiontaking_1+@v8mpositiontaking_1>@max_v8mapositiontaking_1 THEN @max_v8mapositiontaking_1-@v8apositiontaking_1 ELSE @v8mpositiontaking_1 END,
	@v8mpositiontaking_3 = CASE WHEN @v8apositiontaking_3+@v8mpositiontaking_3>@max_v8mapositiontaking_3 THEN @max_v8mapositiontaking_3-@v8apositiontaking_3 ELSE @v8mpositiontaking_3 END,
	@v8mpositiontaking_20 = CASE WHEN @v8apositiontaking_20+@v8mpositiontaking_20>@max_v8mapositiontaking_20 THEN @max_v8mapositiontaking_20-@v8apositiontaking_20 ELSE @v8mpositiontaking_20 END,

	@v10mpositiontaking_1 = CASE WHEN @v10apositiontaking_1+@v10mpositiontaking_1>@max_v10mapositiontaking_1 THEN @max_v10mapositiontaking_1-@v10apositiontaking_1 ELSE @v10mpositiontaking_1 END,
	@v10mpositiontaking_2 = CASE WHEN @v10apositiontaking_2+@v10mpositiontaking_2>@max_v10mapositiontaking_2 THEN @max_v10mapositiontaking_2-@v10apositiontaking_2 ELSE @v10mpositiontaking_2 END,
	@v10mpositiontaking_3 = CASE WHEN @v10apositiontaking_3+@v10mpositiontaking_3>@max_v10mapositiontaking_3 THEN @max_v10mapositiontaking_3-@v10apositiontaking_3 ELSE @v10mpositiontaking_3 END,
	@v10mpositiontaking_20 = CASE WHEN @v10apositiontaking_20+@v10mpositiontaking_20>@max_v10mapositiontaking_20 THEN @max_v10mapositiontaking_20-@v10apositiontaking_20 ELSE @v10mpositiontaking_20 END,

	@v11mpositiontaking_1 = CASE WHEN @v11apositiontaking_1+@v11mpositiontaking_1>@max_v11mapositiontaking_1 THEN @max_v11mapositiontaking_1-@v11apositiontaking_1 ELSE @v11mpositiontaking_1 END,
	@v11mpositiontaking_20 = CASE WHEN @v11apositiontaking_20+@v11mpositiontaking_20>@max_v11mapositiontaking_20 THEN @max_v11mapositiontaking_20-@v11apositiontaking_20 ELSE @v11mpositiontaking_20 END,

	@v99mpositiontaking_1 = CASE WHEN @v99apositiontaking_1+@v99mpositiontaking_1>@max_v99mapositiontaking_1 THEN @max_v99mapositiontaking_1-@v99apositiontaking_1 ELSE @v99mpositiontaking_1 END,
	@v99mpositiontaking_2 = CASE WHEN @v99apositiontaking_2+@v99mpositiontaking_2>@max_v99mapositiontaking_2 THEN @max_v99mapositiontaking_2-@v99apositiontaking_2 ELSE @v99mpositiontaking_2 END,
	@v99mpositiontaking_3 = CASE WHEN @v99apositiontaking_3+@v99mpositiontaking_3>@max_v99mapositiontaking_3 THEN @max_v99mapositiontaking_3-@v99apositiontaking_3 ELSE @v99mpositiontaking_3 END,
	@v99mpositiontaking_20 = CASE WHEN @v99apositiontaking_20+@v99mpositiontaking_20>@max_v99mapositiontaking_20 THEN @max_v99mapositiontaking_20-@v99apositiontaking_20 ELSE @v99mpositiontaking_20 END

--m1=m1+a1<n3?n3-a1:m1
SELECT 
	@mpositiontaking_1 = CASE WHEN @mpositiontaking_1+@apositiontaking_1<@min_mapositiontaking_1 THEN @min_mapositiontaking_1-@apositiontaking_1 ELSE @mpositiontaking_1 END,
	@mpositiontaking_2 = CASE WHEN @mpositiontaking_2+@apositiontaking_2<@min_mapositiontaking_2 THEN @min_mapositiontaking_2-@apositiontaking_2 ELSE @mpositiontaking_2 END,
	@mpositiontaking_3 = CASE WHEN @mpositiontaking_3+@apositiontaking_3<@min_mapositiontaking_3 THEN @min_mapositiontaking_3-@apositiontaking_3 ELSE @mpositiontaking_3 END,
	@mpositiontaking_4 = CASE WHEN @mpositiontaking_4+@apositiontaking_4<@min_mapositiontaking_4 THEN @min_mapositiontaking_4-@apositiontaking_4 ELSE @mpositiontaking_4 END,
	@mpositiontaking_5 = CASE WHEN @mpositiontaking_5+@apositiontaking_5<@min_mapositiontaking_5 THEN @min_mapositiontaking_5-@apositiontaking_5 ELSE @mpositiontaking_5 END,
	@mpositiontaking_6 = CASE WHEN @mpositiontaking_6+@apositiontaking_6<@min_mapositiontaking_6 THEN @min_mapositiontaking_6-@apositiontaking_6 ELSE @mpositiontaking_6 END,
	@mpositiontaking_7 = CASE WHEN @mpositiontaking_7+@apositiontaking_7<@min_mapositiontaking_7 THEN @min_mapositiontaking_7-@apositiontaking_7 ELSE @mpositiontaking_7 END,
	@mpositiontaking_8 = CASE WHEN @mpositiontaking_8+@apositiontaking_8<@min_mapositiontaking_8 THEN @min_mapositiontaking_8-@apositiontaking_8 ELSE @mpositiontaking_8 END,
	@mpositiontaking_9 = CASE WHEN @mpositiontaking_9+@apositiontaking_9<@min_mapositiontaking_9 THEN @min_mapositiontaking_9-@apositiontaking_9 ELSE @mpositiontaking_9 END,
	@mpositiontaking_10 = CASE WHEN @mpositiontaking_10+@apositiontaking_10<@min_mapositiontaking_10 THEN @min_mapositiontaking_10-@apositiontaking_10 ELSE @mpositiontaking_10 END,

	@mlivepositiontaking_1 = CASE WHEN @mlivepositiontaking_1+@alivepositiontaking_1<@min_malivepositiontaking_1 THEN @min_malivepositiontaking_1-@alivepositiontaking_1 ELSE @mlivepositiontaking_1 END,
	@mlivepositiontaking_3 = CASE WHEN @mlivepositiontaking_3+@alivepositiontaking_3<@min_malivepositiontaking_3 THEN @min_malivepositiontaking_3-@alivepositiontaking_3 ELSE @mlivepositiontaking_3 END,
	@mlivepositiontaking_7 = CASE WHEN @mlivepositiontaking_7+@alivepositiontaking_7<@min_malivepositiontaking_7 THEN @min_malivepositiontaking_7-@alivepositiontaking_7 ELSE @mlivepositiontaking_7 END,
	@mlivepositiontaking_8 = CASE WHEN @mlivepositiontaking_8+@alivepositiontaking_8<@min_malivepositiontaking_8 THEN @min_malivepositiontaking_8-@alivepositiontaking_8 ELSE @mlivepositiontaking_8 END,

	@v2mpositiontaking_1 = CASE WHEN @v2apositiontaking_1+@v2mpositiontaking_1<@min_v2mapositiontaking_1 THEN @min_v2mapositiontaking_1-@v2apositiontaking_1 ELSE @v2mpositiontaking_1 END,
	@v2mpositiontaking_2 = CASE WHEN @v2apositiontaking_2+@v2mpositiontaking_2<@min_v2mapositiontaking_2 THEN @min_v2mapositiontaking_2-@v2apositiontaking_2 ELSE @v2mpositiontaking_2 END,
	@v2mpositiontaking_3 = CASE WHEN @v2apositiontaking_3+@v2mpositiontaking_3<@min_v2mapositiontaking_3 THEN @min_v2mapositiontaking_3-@v2apositiontaking_3 ELSE @v2mpositiontaking_3 END,
	@v2mpositiontaking_7 = CASE WHEN @v2apositiontaking_7+@v2mpositiontaking_7<@min_v2mapositiontaking_7 THEN @min_v2mapositiontaking_7-@v2apositiontaking_7 ELSE @v2mpositiontaking_7 END,
	@v2mpositiontaking_8 = CASE WHEN @v2apositiontaking_8+@v2mpositiontaking_8<@min_v2mapositiontaking_8 THEN @min_v2mapositiontaking_8-@v2apositiontaking_8 ELSE @v2mpositiontaking_8 END,
	@v2mpositiontaking_9 = CASE WHEN @v2apositiontaking_9+@v2mpositiontaking_9<@min_v2mapositiontaking_9 THEN @min_v2mapositiontaking_9-@v2apositiontaking_9 ELSE @v2mpositiontaking_9 END,
	@v2mpositiontaking_20 = CASE WHEN @v2apositiontaking_20+@v2mpositiontaking_20<@min_v2mapositiontaking_20 THEN @min_v2mapositiontaking_20-@v2apositiontaking_20 ELSE @v2mpositiontaking_20 END,

	@v3mpositiontaking_1 = CASE WHEN @v3apositiontaking_1+@v3mpositiontaking_1<@min_v3mapositiontaking_1 THEN @min_v3mapositiontaking_1-@v3apositiontaking_1 ELSE @v3mpositiontaking_1 END,
	@v3mpositiontaking_2 = CASE WHEN @v3apositiontaking_2+@v3mpositiontaking_2<@min_v3mapositiontaking_2 THEN @min_v3mapositiontaking_2-@v3apositiontaking_2 ELSE @v3mpositiontaking_2 END,
	@v3mpositiontaking_3 = CASE WHEN @v3apositiontaking_3+@v3mpositiontaking_3<@min_v3mapositiontaking_3 THEN @min_v3mapositiontaking_3-@v3apositiontaking_3 ELSE @v3mpositiontaking_3 END,
	@v3mpositiontaking_20 = CASE WHEN @v3apositiontaking_20+@v3mpositiontaking_20<@min_v3mapositiontaking_20 THEN @min_v3mapositiontaking_20-@v3apositiontaking_20 ELSE @v3mpositiontaking_20 END,

	@v5mpositiontaking_1 = CASE WHEN @v5apositiontaking_1+@v5mpositiontaking_1<@min_v5mapositiontaking_1 THEN @min_v5mapositiontaking_1-@v5apositiontaking_1 ELSE @v5mpositiontaking_1 END,
	@v5mpositiontaking_2 = CASE WHEN @v5apositiontaking_2+@v5mpositiontaking_2<@min_v5mapositiontaking_2 THEN @min_v5mapositiontaking_2-@v5apositiontaking_2 ELSE @v5mpositiontaking_2 END,
	@v5mpositiontaking_3 = CASE WHEN @v5apositiontaking_3+@v5mpositiontaking_3<@min_v5mapositiontaking_3 THEN @min_v5mapositiontaking_3-@v5apositiontaking_3 ELSE @v5mpositiontaking_3 END,
	@v5mpositiontaking_20 = CASE WHEN @v5apositiontaking_20+@v5mpositiontaking_20<@min_v5mapositiontaking_20 THEN @min_v5mapositiontaking_20-@v5apositiontaking_20 ELSE @v5mpositiontaking_20 END,

	@v8mpositiontaking_1 = CASE WHEN @v8apositiontaking_1+@v8mpositiontaking_1<@min_v8mapositiontaking_1 THEN @min_v8mapositiontaking_1-@v8apositiontaking_1 ELSE @v8mpositiontaking_1 END,
	@v8mpositiontaking_3 = CASE WHEN @v8apositiontaking_3+@v8mpositiontaking_3<@min_v8mapositiontaking_3 THEN @min_v8mapositiontaking_3-@v8apositiontaking_3 ELSE @v8mpositiontaking_3 END,
	@v8mpositiontaking_20 = CASE WHEN @v8apositiontaking_20+@v8mpositiontaking_20<@min_v8mapositiontaking_20 THEN @min_v8mapositiontaking_20-@v8apositiontaking_20 ELSE @v8mpositiontaking_20 END,

	@v10mpositiontaking_1 = CASE WHEN @v10apositiontaking_1+@v10mpositiontaking_1<@min_v10mapositiontaking_1 THEN @min_v10mapositiontaking_1-@v10apositiontaking_1 ELSE @v10mpositiontaking_1 END,
	@v10mpositiontaking_2 = CASE WHEN @v10apositiontaking_2+@v10mpositiontaking_2<@min_v10mapositiontaking_2 THEN @min_v10mapositiontaking_2-@v10apositiontaking_2 ELSE @v10mpositiontaking_2 END,
	@v10mpositiontaking_3 = CASE WHEN @v10apositiontaking_3+@v10mpositiontaking_3<@min_v10mapositiontaking_3 THEN @min_v10mapositiontaking_3-@v10apositiontaking_3 ELSE @v10mpositiontaking_3 END,
	@v10mpositiontaking_20 = CASE WHEN @v10apositiontaking_20+@v10mpositiontaking_20<@min_v10mapositiontaking_20 THEN @min_v10mapositiontaking_20-@v10apositiontaking_20 ELSE @v10mpositiontaking_20 END,

	@v11mpositiontaking_1 = CASE WHEN @v11apositiontaking_1+@v11mpositiontaking_1<@min_v11mapositiontaking_1 THEN @min_v11mapositiontaking_1-@v11apositiontaking_1 ELSE @v11mpositiontaking_1 END,
	@v11mpositiontaking_20 = CASE WHEN @v11apositiontaking_20+@v11mpositiontaking_20<@min_v11mapositiontaking_20 THEN @min_v11mapositiontaking_20-@v11apositiontaking_20 ELSE @v11mpositiontaking_20 END,

	@v99mpositiontaking_1 = CASE WHEN @v99apositiontaking_1+@v99mpositiontaking_1<@min_v99mapositiontaking_1 THEN @min_v99mapositiontaking_1-@v99apositiontaking_1 ELSE @v99mpositiontaking_1 END,
	@v99mpositiontaking_2 = CASE WHEN @v99apositiontaking_2+@v99mpositiontaking_2<@min_v99mapositiontaking_2 THEN @min_v99mapositiontaking_2-@v99apositiontaking_2 ELSE @v99mpositiontaking_2 END,
	@v99mpositiontaking_3 = CASE WHEN @v99apositiontaking_3+@v99mpositiontaking_3<@min_v99mapositiontaking_3 THEN @min_v99mapositiontaking_3-@v99apositiontaking_3 ELSE @v99mpositiontaking_3 END,
	@v99mpositiontaking_20 = CASE WHEN @v99apositiontaking_20+@v99mpositiontaking_20<@min_v99mapositiontaking_20 THEN @min_v99mapositiontaking_20-@v99apositiontaking_20 ELSE @v99mpositiontaking_20 END

SELECT 
	@mpositiontaking_1 = CASE WHEN @mpositiontaking_1<0 THEN 0 ELSE @mpositiontaking_1 END,
	@mpositiontaking_2 = CASE WHEN @mpositiontaking_2<0 THEN 0 ELSE @mpositiontaking_2 END,
	@mpositiontaking_3 = CASE WHEN @mpositiontaking_3<0 THEN 0 ELSE @mpositiontaking_3 END,
	@mpositiontaking_4 = CASE WHEN @mpositiontaking_4<0 THEN 0 ELSE @mpositiontaking_4 END,
	@mpositiontaking_5 = CASE WHEN @mpositiontaking_5<0 THEN 0 ELSE @mpositiontaking_5 END,
	@mpositiontaking_6 = CASE WHEN @mpositiontaking_6<0 THEN 0 ELSE @mpositiontaking_6 END,
	@mpositiontaking_7 = CASE WHEN @mpositiontaking_7<0 THEN 0 ELSE @mpositiontaking_7 END,
	@mpositiontaking_8 = CASE WHEN @mpositiontaking_8<0 THEN 0 ELSE @mpositiontaking_8 END,
	@mpositiontaking_9 = CASE WHEN @mpositiontaking_9<0 THEN 0 ELSE @mpositiontaking_9 END,
	@mpositiontaking_10 = CASE WHEN @mpositiontaking_10<0 THEN 0 ELSE @mpositiontaking_10 END,

	@mlivepositiontaking_1 = CASE WHEN @mlivepositiontaking_1<0 THEN 0 ELSE @mlivepositiontaking_1 END,
	@mlivepositiontaking_3 = CASE WHEN @mlivepositiontaking_3<0 THEN 0 ELSE @mlivepositiontaking_3 END,
	@mlivepositiontaking_7 = CASE WHEN @mlivepositiontaking_7<0 THEN 0 ELSE @mlivepositiontaking_7 END,
	@mlivepositiontaking_8 = CASE WHEN @mlivepositiontaking_8<0 THEN 0 ELSE @mlivepositiontaking_8 END,

	@v2mpositiontaking_1 = CASE WHEN @v2mpositiontaking_1<0 THEN 0 ELSE @v2mpositiontaking_1 END,
	@v2mpositiontaking_2 = CASE WHEN @v2mpositiontaking_2<0 THEN 0 ELSE @v2mpositiontaking_2 END,
	@v2mpositiontaking_3 = CASE WHEN @v2mpositiontaking_3<0 THEN 0 ELSE @v2mpositiontaking_3 END,
	@v2mpositiontaking_7 = CASE WHEN @v2mpositiontaking_7<0 THEN 0 ELSE @v2mpositiontaking_7 END,
	@v2mpositiontaking_8 = CASE WHEN @v2mpositiontaking_8<0 THEN 0 ELSE @v2mpositiontaking_8 END,
	@v2mpositiontaking_9 = CASE WHEN @v2mpositiontaking_9<0 THEN 0 ELSE @v2mpositiontaking_9 END,
	@v2mpositiontaking_20 = CASE WHEN @v2mpositiontaking_20<0 THEN 0 ELSE @v2mpositiontaking_20 END,

	@v3mpositiontaking_1 = CASE WHEN @v3mpositiontaking_1<0 THEN 0 ELSE @v3mpositiontaking_1 END,
	@v3mpositiontaking_2 = CASE WHEN @v3mpositiontaking_2<0 THEN 0 ELSE @v3mpositiontaking_2 END,
	@v3mpositiontaking_3 = CASE WHEN @v3mpositiontaking_3<0 THEN 0 ELSE @v3mpositiontaking_3 END,
	@v3mpositiontaking_20 = CASE WHEN @v3mpositiontaking_20<0 THEN 0 ELSE @v3mpositiontaking_20 END,

	@v5mpositiontaking_1 = CASE WHEN @v5mpositiontaking_1<0 THEN 0 ELSE @v5mpositiontaking_1 END,
	@v5mpositiontaking_2 = CASE WHEN @v5mpositiontaking_2<0 THEN 0 ELSE @v5mpositiontaking_2 END,
	@v5mpositiontaking_3 = CASE WHEN @v5mpositiontaking_3<0 THEN 0 ELSE @v5mpositiontaking_3 END,
	@v5mpositiontaking_20 = CASE WHEN @v5mpositiontaking_20<0 THEN 0 ELSE @v5mpositiontaking_20 END,

	@v8mpositiontaking_1 = CASE WHEN @v8mpositiontaking_1<0 THEN 0 ELSE @v8mpositiontaking_1 END,
	@v8mpositiontaking_3 = CASE WHEN @v8mpositiontaking_3<0 THEN 0 ELSE @v8mpositiontaking_3 END,
	@v8mpositiontaking_20 = CASE WHEN @v8mpositiontaking_20<0 THEN 0 ELSE @v8mpositiontaking_20 END,

	@v10mpositiontaking_1 = CASE WHEN @v10mpositiontaking_1<0 THEN 0 ELSE @v10mpositiontaking_1 END,
	@v10mpositiontaking_2 = CASE WHEN @v10mpositiontaking_2<0 THEN 0 ELSE @v10mpositiontaking_2 END,
	@v10mpositiontaking_3 = CASE WHEN @v10mpositiontaking_3<0 THEN 0 ELSE @v10mpositiontaking_3 END,
	@v10mpositiontaking_20 = CASE WHEN @v10mpositiontaking_20<0 THEN 0 ELSE @v10mpositiontaking_20 END,

	@v11mpositiontaking_1 = CASE WHEN @v11mpositiontaking_1<0 THEN 0 ELSE @v11mpositiontaking_1 END,
	@v11mpositiontaking_20 = CASE WHEN @v11mpositiontaking_20<0 THEN 0 ELSE @v11mpositiontaking_20 END,

	@v99mpositiontaking_1 = CASE WHEN @v99mpositiontaking_1<0 THEN 0 ELSE @v99mpositiontaking_1 END,
	@v99mpositiontaking_2 = CASE WHEN @v99mpositiontaking_2<0 THEN 0 ELSE @v99mpositiontaking_2 END,
	@v99mpositiontaking_3 = CASE WHEN @v99mpositiontaking_3<0 THEN 0 ELSE @v99mpositiontaking_3 END,
	@v99mpositiontaking_20 = CASE WHEN @v99mpositiontaking_20<0 THEN 0 ELSE @v99mpositiontaking_20 END


--Must include code for auto master
--um=im1>0?um1:um2
--im=im1>0?im1:im2
--m1=im>0?min(um,m3-a1):m1
----------------------------------------------------------------------------------------------------------------------------
--auto master

--um=im1>0?um1:um2
SELECT 
	@auto_mpositiontaking_1 = CASE WHEN @isauto_mpositiontaking_mem_1>0 THEN @auto_mpositiontaking_mem_1 ELSE @auto_mpositiontaking_1 END,
	@auto_mpositiontaking_2 = CASE WHEN @isauto_mpositiontaking_mem_2>0 THEN @auto_mpositiontaking_mem_2 ELSE @auto_mpositiontaking_2 END,
	@auto_mpositiontaking_3 = CASE WHEN @isauto_mpositiontaking_mem_3>0 THEN @auto_mpositiontaking_mem_3 ELSE @auto_mpositiontaking_3 END,
	@auto_mpositiontaking_4 = CASE WHEN @isauto_mpositiontaking_mem_4>0 THEN @auto_mpositiontaking_mem_4 ELSE @auto_mpositiontaking_4 END,
	@auto_mpositiontaking_5 = CASE WHEN @isauto_mpositiontaking_mem_5>0 THEN @auto_mpositiontaking_mem_5 ELSE @auto_mpositiontaking_5 END,
	@auto_mpositiontaking_6 = CASE WHEN @isauto_mpositiontaking_mem_6>0 THEN @auto_mpositiontaking_mem_6 ELSE @auto_mpositiontaking_6 END,
	@auto_mpositiontaking_7 = CASE WHEN @isauto_mpositiontaking_mem_7>0 THEN @auto_mpositiontaking_mem_7 ELSE @auto_mpositiontaking_7 END,
	@auto_mpositiontaking_8 = CASE WHEN @isauto_mpositiontaking_mem_8>0 THEN @auto_mpositiontaking_mem_8 ELSE @auto_mpositiontaking_8 END,
	@auto_mpositiontaking_9 = CASE WHEN @isauto_mpositiontaking_mem_9>0 THEN @auto_mpositiontaking_mem_9 ELSE @auto_mpositiontaking_9 END,
	@auto_mpositiontaking_10 = CASE WHEN @isauto_mpositiontaking_mem_10>0 THEN @auto_mpositiontaking_mem_10 ELSE @auto_mpositiontaking_10 END,

	@auto_mlivepositiontaking_1 = CASE WHEN @isauto_mlivepositiontaking_mem_1>0 THEN @auto_mlivepositiontaking_mem_1 ELSE @auto_mlivepositiontaking_1 END,
	@auto_mlivepositiontaking_3 = CASE WHEN @isauto_mlivepositiontaking_mem_3>0 THEN @auto_mlivepositiontaking_mem_3 ELSE @auto_mlivepositiontaking_3 END,
	@auto_mlivepositiontaking_7 = CASE WHEN @isauto_mlivepositiontaking_mem_7>0 THEN @auto_mlivepositiontaking_mem_7 ELSE @auto_mlivepositiontaking_7 END,
	@auto_mlivepositiontaking_8 = CASE WHEN @isauto_mlivepositiontaking_mem_8>0 THEN @auto_mlivepositiontaking_mem_8 ELSE @auto_mlivepositiontaking_8 END,

	@auto_v2mpositiontaking_1 = CASE WHEN @isauto_v2mpositiontaking_mem_1>0 THEN @auto_v2mpositiontaking_mem_1 ELSE @auto_v2mpositiontaking_1 END,
	@auto_v2mpositiontaking_2 = CASE WHEN @isauto_v2mpositiontaking_mem_2>0 THEN @auto_v2mpositiontaking_mem_2 ELSE @auto_v2mpositiontaking_2 END,
	@auto_v2mpositiontaking_3 = CASE WHEN @isauto_v2mpositiontaking_mem_3>0 THEN @auto_v2mpositiontaking_mem_3 ELSE @auto_v2mpositiontaking_3 END,
	@auto_v2mpositiontaking_7 = CASE WHEN @isauto_v2mpositiontaking_mem_7>0 THEN @auto_v2mpositiontaking_mem_7 ELSE @auto_v2mpositiontaking_7 END,
	@auto_v2mpositiontaking_8 = CASE WHEN @isauto_v2mpositiontaking_mem_8>0 THEN @auto_v2mpositiontaking_mem_8 ELSE @auto_v2mpositiontaking_8 END,
	@auto_v2mpositiontaking_9 = CASE WHEN @isauto_v2mpositiontaking_mem_9>0 THEN @auto_v2mpositiontaking_mem_9 ELSE @auto_v2mpositiontaking_9 END,
	@auto_v2mpositiontaking_20 = CASE WHEN @isauto_v2mpositiontaking_mem_20>0 THEN @auto_v2mpositiontaking_mem_20 ELSE @auto_v2mpositiontaking_20 END,

	@auto_v3mpositiontaking_1 = CASE WHEN @isauto_v3mpositiontaking_mem_1>0 THEN @auto_v3mpositiontaking_mem_1 ELSE @auto_v3mpositiontaking_1 END,
	@auto_v3mpositiontaking_2 = CASE WHEN @isauto_v3mpositiontaking_mem_2>0 THEN @auto_v3mpositiontaking_mem_2 ELSE @auto_v3mpositiontaking_2 END,
	@auto_v3mpositiontaking_3 = CASE WHEN @isauto_v3mpositiontaking_mem_3>0 THEN @auto_v3mpositiontaking_mem_3 ELSE @auto_v3mpositiontaking_3 END,
	@auto_v3mpositiontaking_20 = CASE WHEN @isauto_v3mpositiontaking_mem_20>0 THEN @auto_v3mpositiontaking_mem_20 ELSE @auto_v3mpositiontaking_20 END,

	@auto_v5mpositiontaking_1 = CASE WHEN @isauto_v5mpositiontaking_mem_1>0 THEN @auto_v5mpositiontaking_mem_1 ELSE @auto_v5mpositiontaking_1 END,
	@auto_v5mpositiontaking_2 = CASE WHEN @isauto_v5mpositiontaking_mem_2>0 THEN @auto_v5mpositiontaking_mem_2 ELSE @auto_v5mpositiontaking_2 END,
	@auto_v5mpositiontaking_3 = CASE WHEN @isauto_v5mpositiontaking_mem_3>0 THEN @auto_v5mpositiontaking_mem_3 ELSE @auto_v5mpositiontaking_3 END,
	@auto_v5mpositiontaking_20 = CASE WHEN @isauto_v5mpositiontaking_mem_20>0 THEN @auto_v5mpositiontaking_mem_20 ELSE @auto_v5mpositiontaking_20 END,

	@auto_v8mpositiontaking_1 = CASE WHEN @isauto_v8mpositiontaking_mem_1>0 THEN @auto_v8mpositiontaking_mem_1 ELSE @auto_v8mpositiontaking_1 END,
	@auto_v8mpositiontaking_3 = CASE WHEN @isauto_v8mpositiontaking_mem_3>0 THEN @auto_v8mpositiontaking_mem_3 ELSE @auto_v8mpositiontaking_3 END,
	@auto_v8mpositiontaking_20 = CASE WHEN @isauto_v8mpositiontaking_mem_20>0 THEN @auto_v8mpositiontaking_mem_20 ELSE @auto_v8mpositiontaking_20 END,

	@auto_v10mpositiontaking_1 = CASE WHEN @isauto_v10mpositiontaking_mem_1>0 THEN @auto_v10mpositiontaking_mem_1 ELSE @auto_v10mpositiontaking_1 END,
	@auto_v10mpositiontaking_2 = CASE WHEN @isauto_v10mpositiontaking_mem_2>0 THEN @auto_v10mpositiontaking_mem_2 ELSE @auto_v10mpositiontaking_2 END,
	@auto_v10mpositiontaking_3 = CASE WHEN @isauto_v10mpositiontaking_mem_3>0 THEN @auto_v10mpositiontaking_mem_3 ELSE @auto_v10mpositiontaking_3 END,
	@auto_v10mpositiontaking_20 = CASE WHEN @isauto_v10mpositiontaking_mem_20>0 THEN @auto_v10mpositiontaking_mem_20 ELSE @auto_v10mpositiontaking_20 END,

	@auto_v11mpositiontaking_1 = CASE WHEN @isauto_v11mpositiontaking_mem_1>0 THEN @auto_v11mpositiontaking_mem_1 ELSE @auto_v11mpositiontaking_1 END,
	@auto_v11mpositiontaking_20 = CASE WHEN @isauto_v11mpositiontaking_mem_20>0 THEN @auto_v11mpositiontaking_mem_20 ELSE @auto_v11mpositiontaking_20 END,

	@auto_v99mpositiontaking_1 = CASE WHEN @isauto_v99mpositiontaking_mem_1>0 THEN @auto_v99mpositiontaking_mem_1 ELSE @auto_v99mpositiontaking_1 END,
	@auto_v99mpositiontaking_2 = CASE WHEN @isauto_v99mpositiontaking_mem_2>0 THEN @auto_v99mpositiontaking_mem_2 ELSE @auto_v99mpositiontaking_2 END,
	@auto_v99mpositiontaking_3 = CASE WHEN @isauto_v99mpositiontaking_mem_3>0 THEN @auto_v99mpositiontaking_mem_3 ELSE @auto_v99mpositiontaking_3 END,
	@auto_v99mpositiontaking_20 = CASE WHEN @isauto_v99mpositiontaking_mem_20>0 THEN @auto_v99mpositiontaking_mem_20 ELSE @auto_v99mpositiontaking_20 END,
	--im=im1>0?im1:im2
	@isauto_mpositiontaking_1 = CASE WHEN @isauto_mpositiontaking_mem_1>0 THEN @isauto_mpositiontaking_mem_1 ELSE @isauto_mpositiontaking_1 END,
	@isauto_mpositiontaking_2 = CASE WHEN @isauto_mpositiontaking_mem_2>0 THEN @isauto_mpositiontaking_mem_2 ELSE @isauto_mpositiontaking_2 END,
	@isauto_mpositiontaking_3 = CASE WHEN @isauto_mpositiontaking_mem_3>0 THEN @isauto_mpositiontaking_mem_3 ELSE @isauto_mpositiontaking_3 END,
	@isauto_mpositiontaking_4 = CASE WHEN @isauto_mpositiontaking_mem_4>0 THEN @isauto_mpositiontaking_mem_4 ELSE @isauto_mpositiontaking_4 END,
	@isauto_mpositiontaking_5 = CASE WHEN @isauto_mpositiontaking_mem_5>0 THEN @isauto_mpositiontaking_mem_5 ELSE @isauto_mpositiontaking_5 END,
	@isauto_mpositiontaking_6 = CASE WHEN @isauto_mpositiontaking_mem_6>0 THEN @isauto_mpositiontaking_mem_6 ELSE @isauto_mpositiontaking_6 END,
	@isauto_mpositiontaking_7 = CASE WHEN @isauto_mpositiontaking_mem_7>0 THEN @isauto_mpositiontaking_mem_7 ELSE @isauto_mpositiontaking_7 END,
	@isauto_mpositiontaking_8 = CASE WHEN @isauto_mpositiontaking_mem_8>0 THEN @isauto_mpositiontaking_mem_8 ELSE @isauto_mpositiontaking_8 END,
	@isauto_mpositiontaking_9 = CASE WHEN @isauto_mpositiontaking_mem_9>0 THEN @isauto_mpositiontaking_mem_9 ELSE @isauto_mpositiontaking_9 END,
	@isauto_mpositiontaking_10 = CASE WHEN @isauto_mpositiontaking_mem_10>0 THEN @isauto_mpositiontaking_mem_10 ELSE @isauto_mpositiontaking_10 END,

	@isauto_mlivepositiontaking_1 = CASE WHEN @isauto_mlivepositiontaking_mem_1>0 THEN @isauto_mlivepositiontaking_mem_1 ELSE @isauto_mlivepositiontaking_1 END,
	@isauto_mlivepositiontaking_3 = CASE WHEN @isauto_mlivepositiontaking_mem_3>0 THEN @isauto_mlivepositiontaking_mem_3 ELSE @isauto_mlivepositiontaking_3 END,
	@isauto_mlivepositiontaking_7 = CASE WHEN @isauto_mlivepositiontaking_mem_7>0 THEN @isauto_mlivepositiontaking_mem_7 ELSE @isauto_mlivepositiontaking_7 END,
	@isauto_mlivepositiontaking_8 = CASE WHEN @isauto_mlivepositiontaking_mem_8>0 THEN @isauto_mlivepositiontaking_mem_8 ELSE @isauto_mlivepositiontaking_8 END,

	@isauto_v2mpositiontaking_1 = CASE WHEN @isauto_v2mpositiontaking_mem_1>0 THEN @isauto_v2mpositiontaking_mem_1 ELSE @isauto_v2mpositiontaking_1 END,
	@isauto_v2mpositiontaking_2 = CASE WHEN @isauto_v2mpositiontaking_mem_2>0 THEN @isauto_v2mpositiontaking_mem_2 ELSE @isauto_v2mpositiontaking_2 END,
	@isauto_v2mpositiontaking_3 = CASE WHEN @isauto_v2mpositiontaking_mem_3>0 THEN @isauto_v2mpositiontaking_mem_3 ELSE @isauto_v2mpositiontaking_3 END,
	@isauto_v2mpositiontaking_7 = CASE WHEN @isauto_v2mpositiontaking_mem_7>0 THEN @isauto_v2mpositiontaking_mem_7 ELSE @isauto_v2mpositiontaking_7 END,
	@isauto_v2mpositiontaking_8 = CASE WHEN @isauto_v2mpositiontaking_mem_8>0 THEN @isauto_v2mpositiontaking_mem_8 ELSE @isauto_v2mpositiontaking_8 END,
	@isauto_v2mpositiontaking_9 = CASE WHEN @isauto_v2mpositiontaking_mem_9>0 THEN @isauto_v2mpositiontaking_mem_9 ELSE @isauto_v2mpositiontaking_9 END,
	@isauto_v2mpositiontaking_20 = CASE WHEN @isauto_v2mpositiontaking_mem_20>0 THEN @isauto_v2mpositiontaking_mem_20 ELSE @isauto_v2mpositiontaking_20 END,

	@isauto_v3mpositiontaking_1 = CASE WHEN @isauto_v3mpositiontaking_mem_1>0 THEN @isauto_v3mpositiontaking_mem_1 ELSE @isauto_v3mpositiontaking_1 END,
	@isauto_v3mpositiontaking_2 = CASE WHEN @isauto_v3mpositiontaking_mem_2>0 THEN @isauto_v3mpositiontaking_mem_2 ELSE @isauto_v3mpositiontaking_2 END,
	@isauto_v3mpositiontaking_3 = CASE WHEN @isauto_v3mpositiontaking_mem_3>0 THEN @isauto_v3mpositiontaking_mem_3 ELSE @isauto_v3mpositiontaking_3 END,
	@isauto_v3mpositiontaking_20 = CASE WHEN @isauto_v3mpositiontaking_mem_20>0 THEN @isauto_v3mpositiontaking_mem_20 ELSE @isauto_v3mpositiontaking_20 END,

	@isauto_v5mpositiontaking_1 = CASE WHEN @isauto_v5mpositiontaking_mem_1>0 THEN @isauto_v5mpositiontaking_mem_1 ELSE @isauto_v5mpositiontaking_1 END,
	@isauto_v5mpositiontaking_2 = CASE WHEN @isauto_v5mpositiontaking_mem_2>0 THEN @isauto_v5mpositiontaking_mem_2 ELSE @isauto_v5mpositiontaking_2 END,
	@isauto_v5mpositiontaking_3 = CASE WHEN @isauto_v5mpositiontaking_mem_3>0 THEN @isauto_v5mpositiontaking_mem_3 ELSE @isauto_v5mpositiontaking_3 END,
	@isauto_v5mpositiontaking_20 = CASE WHEN @isauto_v5mpositiontaking_mem_20>0 THEN @isauto_v5mpositiontaking_mem_20 ELSE @isauto_v5mpositiontaking_20 END,

	@isauto_v8mpositiontaking_1 = CASE WHEN @isauto_v8mpositiontaking_mem_1>0 THEN @isauto_v8mpositiontaking_mem_1 ELSE @isauto_v8mpositiontaking_1 END,
	@isauto_v8mpositiontaking_3 = CASE WHEN @isauto_v8mpositiontaking_mem_3>0 THEN @isauto_v8mpositiontaking_mem_3 ELSE @isauto_v8mpositiontaking_3 END,
	@isauto_v8mpositiontaking_20 = CASE WHEN @isauto_v8mpositiontaking_mem_20>0 THEN @isauto_v8mpositiontaking_mem_20 ELSE @isauto_v8mpositiontaking_20 END,

	@isauto_v10mpositiontaking_1 = CASE WHEN @isauto_v10mpositiontaking_mem_1>0 THEN @isauto_v10mpositiontaking_mem_1 ELSE @isauto_v10mpositiontaking_1 END,
	@isauto_v10mpositiontaking_2 = CASE WHEN @isauto_v10mpositiontaking_mem_2>0 THEN @isauto_v10mpositiontaking_mem_2 ELSE @isauto_v10mpositiontaking_2 END,
	@isauto_v10mpositiontaking_3 = CASE WHEN @isauto_v10mpositiontaking_mem_3>0 THEN @isauto_v10mpositiontaking_mem_3 ELSE @isauto_v10mpositiontaking_3 END,
	@isauto_v10mpositiontaking_20 = CASE WHEN @isauto_v10mpositiontaking_mem_20>0 THEN @isauto_v10mpositiontaking_mem_20 ELSE @isauto_v10mpositiontaking_20 END,

	@isauto_v11mpositiontaking_1 = CASE WHEN @isauto_v11mpositiontaking_mem_1>0 THEN @isauto_v11mpositiontaking_mem_1 ELSE @isauto_v11mpositiontaking_1 END,
	@isauto_v11mpositiontaking_20 = CASE WHEN @isauto_v11mpositiontaking_mem_20>0 THEN @isauto_v11mpositiontaking_mem_20 ELSE @isauto_v11mpositiontaking_20 END,

	@isauto_v99mpositiontaking_1 = CASE WHEN @isauto_v99mpositiontaking_mem_1>0 THEN @isauto_v99mpositiontaking_mem_1 ELSE @isauto_v99mpositiontaking_1 END,
	@isauto_v99mpositiontaking_2 = CASE WHEN @isauto_v99mpositiontaking_mem_2>0 THEN @isauto_v99mpositiontaking_mem_2 ELSE @isauto_v99mpositiontaking_2 END,
	@isauto_v99mpositiontaking_3 = CASE WHEN @isauto_v99mpositiontaking_mem_3>0 THEN @isauto_v99mpositiontaking_mem_3 ELSE @isauto_v99mpositiontaking_3 END,
	@isauto_v99mpositiontaking_20 = CASE WHEN @isauto_v99mpositiontaking_mem_20>0 THEN @isauto_v99mpositiontaking_mem_20 ELSE @isauto_v99mpositiontaking_20 END
---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
--m1=im>0?min(um,m3-a1):m1
SELECT @mpositiontaking_1 = CASE WHEN ISNULL(@isauto_mpositiontaking_1, 0)<=0 THEN @mpositiontaking_1 ELSE CASE WHEN @auto_mpositiontaking_1 < @max_mapositiontaking_1 - @apositiontaking_1 THEN @auto_mpositiontaking_1 ELSE @max_mapositiontaking_1 - @apositiontaking_1 END END
SELECT @mpositiontaking_3 = CASE WHEN ISNULL(@isauto_mpositiontaking_3, 0)<=0 THEN @mpositiontaking_3 ELSE CASE WHEN @auto_mpositiontaking_3 < @max_mapositiontaking_3 - @apositiontaking_3 THEN @auto_mpositiontaking_3 ELSE @max_mapositiontaking_3 - @apositiontaking_3 END END
SELECT @mpositiontaking_7 = CASE WHEN ISNULL(@isauto_mpositiontaking_7, 0)<=0 THEN @mpositiontaking_7 ELSE CASE WHEN @auto_mpositiontaking_7 < @max_mapositiontaking_7 - @apositiontaking_7 THEN @auto_mpositiontaking_7 ELSE @max_mapositiontaking_7 - @apositiontaking_7 END END
SELECT @mpositiontaking_8 = CASE WHEN ISNULL(@isauto_mpositiontaking_8, 0)<=0 THEN @mpositiontaking_8 ELSE CASE WHEN @auto_mpositiontaking_8 < @max_mapositiontaking_8 - @apositiontaking_8 THEN @auto_mpositiontaking_8 ELSE @max_mapositiontaking_8 - @apositiontaking_8 END END

SELECT @mlivepositiontaking_1 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_1, 0)<=0 THEN @mlivepositiontaking_1 ELSE CASE WHEN @auto_mlivepositiontaking_1 < @max_malivepositiontaking_1 - @alivepositiontaking_1 THEN @auto_mlivepositiontaking_1 ELSE @max_malivepositiontaking_1 - @alivepositiontaking_1 END END
SELECT @mlivepositiontaking_3 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_3, 0)<=0 THEN @mlivepositiontaking_3 ELSE CASE WHEN @auto_mlivepositiontaking_3 < @max_malivepositiontaking_3 - @alivepositiontaking_3 THEN @auto_mlivepositiontaking_3 ELSE @max_malivepositiontaking_3 - @alivepositiontaking_3 END END
SELECT @mlivepositiontaking_7 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_7, 0)<=0 THEN @mlivepositiontaking_7 ELSE CASE WHEN @auto_mlivepositiontaking_7 < @max_malivepositiontaking_7 - @alivepositiontaking_7 THEN @auto_mlivepositiontaking_7 ELSE @max_malivepositiontaking_7 - @alivepositiontaking_7 END END
SELECT @mlivepositiontaking_8 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_8, 0)<=0 THEN @mlivepositiontaking_8 ELSE CASE WHEN @auto_mlivepositiontaking_8 < @max_malivepositiontaking_8 - @alivepositiontaking_8 THEN @auto_mlivepositiontaking_8 ELSE @max_malivepositiontaking_8 - @alivepositiontaking_8 END END

SELECT @mpositiontaking_2 = CASE WHEN ISNULL(@isauto_mpositiontaking_2, 0)<=0 THEN @mpositiontaking_2 ELSE CASE WHEN @auto_mpositiontaking_2 < @max_mapositiontaking_2 - @apositiontaking_2 THEN @auto_mpositiontaking_2 ELSE @max_mapositiontaking_2 - @apositiontaking_2 END END
SELECT @mpositiontaking_4 = CASE WHEN ISNULL(@isauto_mpositiontaking_4, 0)<=0 THEN @mpositiontaking_4 ELSE CASE WHEN @auto_mpositiontaking_4 < @max_mapositiontaking_4 - @apositiontaking_4 THEN @auto_mpositiontaking_4 ELSE @max_mapositiontaking_4 - @apositiontaking_4 END END
SELECT @mpositiontaking_5 = CASE WHEN ISNULL(@isauto_mpositiontaking_5, 0)<=0 THEN @mpositiontaking_5 ELSE CASE WHEN @auto_mpositiontaking_5 < @max_mapositiontaking_5 - @apositiontaking_5 THEN @auto_mpositiontaking_5 ELSE @max_mapositiontaking_5 - @apositiontaking_5 END END
SELECT @mpositiontaking_6 = CASE WHEN ISNULL(@isauto_mpositiontaking_6, 0)<=0 THEN @mpositiontaking_6 ELSE CASE WHEN @auto_mpositiontaking_6 < @max_mapositiontaking_6 - @apositiontaking_6 THEN @auto_mpositiontaking_6 ELSE @max_mapositiontaking_6 - @apositiontaking_6 END END
SELECT @mpositiontaking_9 = CASE WHEN ISNULL(@isauto_mpositiontaking_9, 0)<=0 THEN @mpositiontaking_9 ELSE CASE WHEN @auto_mpositiontaking_9 < @max_mapositiontaking_9 - @apositiontaking_9 THEN @auto_mpositiontaking_9 ELSE @max_mapositiontaking_9 - @apositiontaking_9 END END
SELECT @mpositiontaking_10 = CASE WHEN ISNULL(@isauto_mpositiontaking_10, 0)<=0 THEN @mpositiontaking_10 ELSE CASE WHEN @auto_mpositiontaking_10 < @max_mapositiontaking_10 - @apositiontaking_10 THEN @auto_mpositiontaking_10 ELSE @max_mapositiontaking_10 - @apositiontaking_10 END END

SELECT @v2mpositiontaking_1 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_1, 0)<=0 THEN @v2mpositiontaking_1 ELSE CASE WHEN @auto_v2mpositiontaking_1 < @max_v2mapositiontaking_1 - @v2apositiontaking_1 THEN @auto_v2mpositiontaking_1 ELSE @max_v2mapositiontaking_1 - @v2apositiontaking_1 END END
SELECT @v2mpositiontaking_2 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_2, 0)<=0 THEN @v2mpositiontaking_2 ELSE CASE WHEN @auto_v2mpositiontaking_2 < @max_v2mapositiontaking_2 - @v2apositiontaking_2 THEN @auto_v2mpositiontaking_2 ELSE @max_v2mapositiontaking_2 - @v2apositiontaking_2 END END
SELECT @v2mpositiontaking_3 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_3, 0)<=0 THEN @v2mpositiontaking_3 ELSE CASE WHEN @auto_v2mpositiontaking_3 < @max_v2mapositiontaking_3 - @v2apositiontaking_3 THEN @auto_v2mpositiontaking_3 ELSE @max_v2mapositiontaking_3 - @v2apositiontaking_3 END END
SELECT @v2mpositiontaking_7 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_7, 0)<=0 THEN @v2mpositiontaking_7 ELSE CASE WHEN @auto_v2mpositiontaking_7 < @max_v2mapositiontaking_7 - @v2apositiontaking_7 THEN @auto_v2mpositiontaking_7 ELSE @max_v2mapositiontaking_7 - @v2apositiontaking_7 END END
SELECT @v2mpositiontaking_8 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_8, 0)<=0 THEN @v2mpositiontaking_8 ELSE CASE WHEN @auto_v2mpositiontaking_8 < @max_v2mapositiontaking_8 - @v2apositiontaking_8 THEN @auto_v2mpositiontaking_8 ELSE @max_v2mapositiontaking_8 - @v2apositiontaking_8 END END
SELECT @v2mpositiontaking_9 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_9, 0)<=0 THEN @v2mpositiontaking_9 ELSE CASE WHEN @auto_v2mpositiontaking_9 < @max_v2mapositiontaking_9 - @v2apositiontaking_9 THEN @auto_v2mpositiontaking_9 ELSE @max_v2mapositiontaking_9 - @v2apositiontaking_9 END END
SELECT @v2mpositiontaking_20 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_20, 0)<=0 THEN @v2mpositiontaking_20 ELSE CASE WHEN @auto_v2mpositiontaking_20 < @max_v2mapositiontaking_20 - @v2apositiontaking_20 THEN @auto_v2mpositiontaking_20 ELSE @max_v2mapositiontaking_20 - @v2apositiontaking_20 END END

SELECT @v3mpositiontaking_1 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_1, 0)<=0 THEN @v3mpositiontaking_1 ELSE CASE WHEN @auto_v3mpositiontaking_1 < @max_v3mapositiontaking_1 - @v3apositiontaking_1 THEN @auto_v3mpositiontaking_1 ELSE @max_v3mapositiontaking_1 - @v3apositiontaking_1 END END
SELECT @v3mpositiontaking_2 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_2, 0)<=0 THEN @v3mpositiontaking_2 ELSE CASE WHEN @auto_v3mpositiontaking_2 < @max_v3mapositiontaking_2 - @v3apositiontaking_2 THEN @auto_v3mpositiontaking_2 ELSE @max_v3mapositiontaking_2 - @v3apositiontaking_2 END END
SELECT @v3mpositiontaking_3 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_3, 0)<=0 THEN @v3mpositiontaking_3 ELSE CASE WHEN @auto_v3mpositiontaking_3 < @max_v3mapositiontaking_3 - @v3apositiontaking_3 THEN @auto_v3mpositiontaking_3 ELSE @max_v3mapositiontaking_3 - @v3apositiontaking_3 END END
SELECT @v3mpositiontaking_20 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_20, 0)<=0 THEN @v3mpositiontaking_20 ELSE CASE WHEN @auto_v3mpositiontaking_20 < @max_v3mapositiontaking_20 - @v3apositiontaking_20 THEN @auto_v3mpositiontaking_20 ELSE @max_v3mapositiontaking_20 -  @v3apositiontaking_20 END END

SELECT @v5mpositiontaking_1 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_1, 0)<=0 THEN @v5mpositiontaking_1 ELSE CASE WHEN @auto_v5mpositiontaking_1 < @max_v5mapositiontaking_1 - @v5apositiontaking_1 THEN @auto_v5mpositiontaking_1 ELSE @max_v5mapositiontaking_1 - @v5apositiontaking_1 END END
SELECT @v5mpositiontaking_2 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_2, 0)<=0 THEN @v5mpositiontaking_2 ELSE CASE WHEN @auto_v5mpositiontaking_2 < @max_v5mapositiontaking_2 - @v5apositiontaking_2 THEN @auto_v5mpositiontaking_2 ELSE @max_v5mapositiontaking_2 - @v5apositiontaking_2 END END
SELECT @v5mpositiontaking_3 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_3, 0)<=0 THEN @v5mpositiontaking_3 ELSE CASE WHEN @auto_v5mpositiontaking_3 < @max_v5mapositiontaking_3 - @v5apositiontaking_3 THEN @auto_v5mpositiontaking_3 ELSE @max_v5mapositiontaking_3 - @v5apositiontaking_3 END END
SELECT @v5mpositiontaking_20 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_20, 0)<=0 THEN @v5mpositiontaking_20 ELSE CASE WHEN @auto_v5mpositiontaking_20 < @max_v5mapositiontaking_20 - @v5apositiontaking_20 THEN @auto_v5mpositiontaking_20 ELSE @max_v5mapositiontaking_20 - @v5apositiontaking_20 END END

SELECT @v8mpositiontaking_1 = CASE WHEN ISNULL(@isauto_v8mpositiontaking_1, 0)<=0 THEN @v8mpositiontaking_1 ELSE CASE WHEN @auto_v8mpositiontaking_1 < @max_v8mapositiontaking_1 - @v8apositiontaking_1 THEN @auto_v8mpositiontaking_1 ELSE @max_v8mapositiontaking_1 - @v8apositiontaking_1 END END
SELECT @v8mpositiontaking_3 = CASE WHEN ISNULL(@isauto_v8mpositiontaking_3, 0)<=0 THEN @v8mpositiontaking_3 ELSE CASE WHEN @auto_v8mpositiontaking_3 < @max_v8mapositiontaking_3 - @v8apositiontaking_3 THEN @auto_v8mpositiontaking_3 ELSE @max_v8mapositiontaking_3 - @v8apositiontaking_3 END END
SELECT @v8mpositiontaking_20 = CASE WHEN ISNULL(@isauto_v8mpositiontaking_20, 0)<=0 THEN @v8mpositiontaking_20 ELSE CASE WHEN @auto_v8mpositiontaking_20 < @max_v8mapositiontaking_20 - @v8apositiontaking_20 THEN @auto_v8mpositiontaking_20 ELSE @max_v8mapositiontaking_20 - @v8apositiontaking_20 END END

SELECT @v10mpositiontaking_1 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_1, 0)<=0 THEN @v10mpositiontaking_1 ELSE CASE WHEN @auto_v10mpositiontaking_1 < @max_v10mapositiontaking_1 - @v10apositiontaking_1 THEN @auto_v10mpositiontaking_1 ELSE @max_v10mapositiontaking_1 - @v10apositiontaking_1 END END
SELECT @v10mpositiontaking_2 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_2, 0)<=0 THEN @v10mpositiontaking_2 ELSE CASE WHEN @auto_v10mpositiontaking_2 < @max_v10mapositiontaking_2 - @v10apositiontaking_2 THEN @auto_v10mpositiontaking_2 ELSE @max_v10mapositiontaking_2 - @v10apositiontaking_2 END END
SELECT @v10mpositiontaking_3 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_3, 0)<=0 THEN @v10mpositiontaking_3 ELSE CASE WHEN @auto_v10mpositiontaking_3 < @max_v10mapositiontaking_3 - @v10apositiontaking_3 THEN @auto_v10mpositiontaking_3 ELSE @max_v10mapositiontaking_3 - @v10apositiontaking_3 END END
SELECT @v10mpositiontaking_20 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_20, 0)<=0 THEN @v10mpositiontaking_20 ELSE CASE WHEN @auto_v10mpositiontaking_20 < @max_v10mapositiontaking_20 - @v10apositiontaking_20 THEN @auto_v10mpositiontaking_20 ELSE @max_v10mapositiontaking_20 - @v10apositiontaking_20 END END

SELECT @v11mpositiontaking_1 = CASE WHEN ISNULL(@isauto_v11mpositiontaking_1, 0)<=0 THEN @v11mpositiontaking_1 ELSE CASE WHEN @auto_v11mpositiontaking_1 < @max_v11mapositiontaking_1 - @v11apositiontaking_1 THEN @auto_v11mpositiontaking_1 ELSE @max_v11mapositiontaking_1 - @v11apositiontaking_1 END END
SELECT @v11mpositiontaking_20 = CASE WHEN ISNULL(@isauto_v11mpositiontaking_20, 0)<=0 THEN @v11mpositiontaking_20 ELSE CASE WHEN @auto_v11mpositiontaking_20 < @max_v11mapositiontaking_20 - @v11apositiontaking_20 THEN @auto_v11mpositiontaking_20 ELSE @max_v11mapositiontaking_20 - @v11apositiontaking_20 END END

SELECT @v99mpositiontaking_1 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_1, 0)<=0 THEN @v99mpositiontaking_1 ELSE CASE WHEN @auto_v99mpositiontaking_1 < @max_v99mapositiontaking_1 - @v99apositiontaking_1 THEN @auto_v99mpositiontaking_1 ELSE @max_v99mapositiontaking_1 - @v99apositiontaking_1 END END
SELECT @v99mpositiontaking_2 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_2, 0)<=0 THEN @v99mpositiontaking_2 ELSE CASE WHEN @auto_v99mpositiontaking_2 < @max_v99mapositiontaking_2 - @v99apositiontaking_2 THEN @auto_v99mpositiontaking_2 ELSE @max_v99mapositiontaking_2 - @v99apositiontaking_2 END END
SELECT @v99mpositiontaking_3 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_3, 0)<=0 THEN @v99mpositiontaking_3 ELSE CASE WHEN @auto_v99mpositiontaking_3 < @max_v99mapositiontaking_3 - @v99apositiontaking_3 THEN @auto_v99mpositiontaking_3 ELSE @max_v99mapositiontaking_3 - @v99apositiontaking_3 END END
SELECT @v99mpositiontaking_20 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_20, 0)<=0 THEN @v99mpositiontaking_20 ELSE CASE WHEN @auto_v99mpositiontaking_20 < @max_v99mapositiontaking_20 - @v99apositiontaking_20 THEN @auto_v99mpositiontaking_20 ELSE @max_v99mapositiontaking_20 - @v99apositiontaking_20 END END

/* Phuc@20090806: no need cause just check m1 = min(m3-a1,m1)
-------------------------------------------------------------------------------
--maxm1=isauto?m3:m3-a2
SELECT @max_mapositiontaking_1 = CASE WHEN ISNULL(@isauto_mpositiontaking_1, 0)>0 THEN @max_mapositiontaking_1 ELSE @max_mapositiontaking_1-@max_apositiontaking_1 END
SELECT @max_mapositiontaking_3 = CASE WHEN ISNULL(@isauto_mpositiontaking_3, 0)>0 THEN @max_mapositiontaking_3 ELSE @max_mapositiontaking_3-@max_apositiontaking_3 END
SELECT @max_mapositiontaking_7 = CASE WHEN ISNULL(@isauto_mpositiontaking_7, 0)>0 THEN @max_mapositiontaking_7 ELSE @max_mapositiontaking_7-@max_apositiontaking_7 END
SELECT @max_mapositiontaking_8 = CASE WHEN ISNULL(@isauto_mpositiontaking_8, 0)>0 THEN @max_mapositiontaking_8 ELSE @max_mapositiontaking_8-@max_apositiontaking_8 END

SELECT @max_malivepositiontaking_1 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_1, 0)>0 THEN @max_malivepositiontaking_1 ELSE @max_malivepositiontaking_1-@max_alivepositiontaking_1 END
SELECT @max_malivepositiontaking_3 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_3, 0)>0 THEN @max_malivepositiontaking_3 ELSE @max_malivepositiontaking_3-@max_alivepositiontaking_3 END
SELECT @max_malivepositiontaking_7 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_7, 0)>0 THEN @max_malivepositiontaking_7 ELSE @max_malivepositiontaking_7-@max_alivepositiontaking_7 END
SELECT @max_malivepositiontaking_8 = CASE WHEN ISNULL(@isauto_mlivepositiontaking_8, 0)>0 THEN @max_malivepositiontaking_8 ELSE @max_malivepositiontaking_8-@max_alivepositiontaking_8 END

SELECT @max_mapositiontaking_2 = CASE WHEN ISNULL(@isauto_mpositiontaking_2, 0)>0 THEN @max_mapositiontaking_2 ELSE @max_mapositiontaking_2-@max_apositiontaking_2 END
SELECT @max_mapositiontaking_4 = CASE WHEN ISNULL(@isauto_mpositiontaking_4, 0)>0 THEN @max_mapositiontaking_4 ELSE @max_mapositiontaking_4-@max_apositiontaking_4 END
SELECT @max_mapositiontaking_5 = CASE WHEN ISNULL(@isauto_mpositiontaking_5, 0)>0 THEN @max_mapositiontaking_5 ELSE @max_mapositiontaking_5-@max_apositiontaking_5 END
SELECT @max_mapositiontaking_6 = CASE WHEN ISNULL(@isauto_mpositiontaking_6, 0)>0 THEN @max_mapositiontaking_6 ELSE @max_mapositiontaking_6-@max_apositiontaking_6 END
SELECT @max_mapositiontaking_9 = CASE WHEN ISNULL(@isauto_mpositiontaking_9, 0)>0 THEN @max_mapositiontaking_9 ELSE @max_mapositiontaking_9-@max_apositiontaking_9 END
SELECT @max_mapositiontaking_10 = CASE WHEN ISNULL(@isauto_mpositiontaking_10, 0)>0 THEN @max_mapositiontaking_10 ELSE @max_mapositiontaking_10-@max_apositiontaking_10 END

SELECT @max_v2mapositiontaking_1 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_1, 0)>0 THEN @max_v2mapositiontaking_1 ELSE @max_v2mapositiontaking_1-@max_v2apositiontaking_1 END
SELECT @max_v2mapositiontaking_2 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_2, 0)>0 THEN @max_v2mapositiontaking_2 ELSE @max_v2mapositiontaking_2-@max_v2apositiontaking_2 END
SELECT @max_v2mapositiontaking_3 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_3, 0)>0 THEN @max_v2mapositiontaking_3 ELSE @max_v2mapositiontaking_3-@max_v2apositiontaking_3 END
SELECT @max_v2mapositiontaking_7 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_7, 0)>0 THEN @max_v2mapositiontaking_7 ELSE @max_v2mapositiontaking_7-@max_v2apositiontaking_7 END
SELECT @max_v2mapositiontaking_8 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_8, 0)>0 THEN @max_v2mapositiontaking_8 ELSE @max_v2mapositiontaking_8-@max_v2apositiontaking_8 END
SELECT @max_v2mapositiontaking_9 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_9, 0)>0 THEN @max_v2mapositiontaking_9 ELSE @max_v2mapositiontaking_9-@max_v2apositiontaking_9 END
SELECT @max_v2mapositiontaking_20 = CASE WHEN ISNULL(@isauto_v2mpositiontaking_20, 0)>0 THEN @max_v2mapositiontaking_20 ELSE @max_v2mapositiontaking_20-@max_v2apositiontaking_20 END

SELECT @max_v3mapositiontaking_1 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_1, 0)>0 THEN @max_v3mapositiontaking_1 ELSE @max_v3mapositiontaking_1-@max_v3apositiontaking_1 END
SELECT @max_v3mapositiontaking_2 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_2, 0)>0 THEN @max_v3mapositiontaking_2 ELSE @max_v3mapositiontaking_2-@max_v3apositiontaking_2 END
SELECT @max_v3mapositiontaking_3 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_3, 0)>0 THEN @max_v3mapositiontaking_3 ELSE @max_v3mapositiontaking_3-@max_v3apositiontaking_3 END
SELECT @max_v3mapositiontaking_20 = CASE WHEN ISNULL(@isauto_v3mpositiontaking_20, 0)>0 THEN @max_v3mapositiontaking_20 ELSE @max_v3mapositiontaking_20-@max_v3apositiontaking_20 END

SELECT @max_v5mapositiontaking_1 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_1, 0)>0 THEN @max_v5mapositiontaking_1 ELSE @max_v5mapositiontaking_1-@max_v5apositiontaking_1 END
SELECT @max_v5mapositiontaking_2 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_2, 0)>0 THEN @max_v5mapositiontaking_2 ELSE @max_v5mapositiontaking_2-@max_v5apositiontaking_2 END
SELECT @max_v5mapositiontaking_3 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_3, 0)>0 THEN @max_v5mapositiontaking_3 ELSE @max_v5mapositiontaking_3-@max_v5apositiontaking_3 END
SELECT @max_v5mapositiontaking_20 = CASE WHEN ISNULL(@isauto_v5mpositiontaking_20, 0)>0 THEN @max_v5mapositiontaking_20 ELSE @max_v5mapositiontaking_20-@max_v5apositiontaking_20 END

SELECT @max_v8mapositiontaking_1 = CASE WHEN ISNULL(@isauto_v8mpositiontaking_1, 0)>0 THEN @max_v8mapositiontaking_1 ELSE @max_v8mapositiontaking_1-@max_v8apositiontaking_1 END
SELECT @max_v8mapositiontaking_3 = CASE WHEN ISNULL(@isauto_v8mpositiontaking_3, 0)>0 THEN @max_v8mapositiontaking_3 ELSE @max_v8mapositiontaking_3-@max_v8apositiontaking_3 END
SELECT @max_v8mapositiontaking_20 = CASE WHEN ISNULL(@isauto_v8mpositiontaking_20, 0)>0 THEN @max_v8mapositiontaking_20 ELSE @max_v8mapositiontaking_20-@max_v8apositiontaking_20 END

SELECT @max_v10mapositiontaking_1 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_1, 0)>0 THEN @max_v10mapositiontaking_1 ELSE @max_v10mapositiontaking_1-@max_v10apositiontaking_1 END
SELECT @max_v10mapositiontaking_2 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_2, 0)>0 THEN @max_v10mapositiontaking_2 ELSE @max_v10mapositiontaking_2-@max_v10apositiontaking_2 END
SELECT @max_v10mapositiontaking_3 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_3, 0)>0 THEN @max_v10mapositiontaking_3 ELSE @max_v10mapositiontaking_3-@max_v10apositiontaking_3 END
SELECT @max_v10mapositiontaking_20 = CASE WHEN ISNULL(@isauto_v10mpositiontaking_20, 0)>0 THEN @max_v10mapositiontaking_20 ELSE @max_v10mapositiontaking_20-@max_v10apositiontaking_20 END

SELECT @max_v11mapositiontaking_1 = CASE WHEN ISNULL(@isauto_v11mpositiontaking_1, 0)>0 THEN @max_v11mapositiontaking_1 ELSE @max_v11mapositiontaking_1-@max_v11apositiontaking_1 END
SELECT @max_v11mapositiontaking_20 = CASE WHEN ISNULL(@isauto_v11mpositiontaking_20, 0)>0 THEN @max_v11mapositiontaking_20 ELSE @max_v11mapositiontaking_20-@max_v11apositiontaking_20 END

SELECT @max_v99mapositiontaking_1 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_1, 0)>0 THEN @max_v99mapositiontaking_1 ELSE @max_v99mapositiontaking_1-@max_v99apositiontaking_1 END
SELECT @max_v99mapositiontaking_2 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_2, 0)>0 THEN @max_v99mapositiontaking_2 ELSE @max_v99mapositiontaking_2-@max_v99apositiontaking_2 END
SELECT @max_v99mapositiontaking_3 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_3, 0)>0 THEN @max_v99mapositiontaking_3 ELSE @max_v99mapositiontaking_3-@max_v99apositiontaking_3 END
SELECT @max_v99mapositiontaking_20 = CASE WHEN ISNULL(@isauto_v99mpositiontaking_20, 0)>0 THEN @max_v99mapositiontaking_20 ELSE @max_v99mapositiontaking_20-@max_v99apositiontaking_20 END
--m1=m1>maxm1?maxm1:m1
SELECT @mpositiontaking_1 = CASE WHEN @mpositiontaking_1 > @max_mapositiontaking_1 THEN @max_mapositiontaking_1 ELSE @mpositiontaking_1 END
SELECT @mpositiontaking_3 = CASE WHEN @mpositiontaking_3 > @max_mapositiontaking_3 THEN @max_mapositiontaking_3 ELSE @mpositiontaking_3 END
SELECT @mpositiontaking_7 = CASE WHEN @mpositiontaking_7 > @max_mapositiontaking_7 THEN @max_mapositiontaking_7 ELSE @mpositiontaking_7 END
SELECT @mpositiontaking_8 = CASE WHEN @mpositiontaking_8 > @max_mapositiontaking_8 THEN @max_mapositiontaking_8 ELSE @mpositiontaking_8 END

SELECT @mlivepositiontaking_1 = CASE WHEN @mlivepositiontaking_1 > @max_malivepositiontaking_1 THEN @max_malivepositiontaking_1 ELSE @mlivepositiontaking_1 END
SELECT @mlivepositiontaking_3 = CASE WHEN @mlivepositiontaking_3 > @max_malivepositiontaking_3 THEN @max_malivepositiontaking_3 ELSE @mlivepositiontaking_3 END
SELECT @mlivepositiontaking_7 = CASE WHEN @mlivepositiontaking_7 > @max_malivepositiontaking_7 THEN @max_malivepositiontaking_7 ELSE @mlivepositiontaking_7 END
SELECT @mlivepositiontaking_8 = CASE WHEN @mlivepositiontaking_8 > @max_malivepositiontaking_8 THEN @max_malivepositiontaking_8 ELSE @mlivepositiontaking_8 END

SELECT @mpositiontaking_2 = CASE WHEN @mpositiontaking_2 > @max_mapositiontaking_2 THEN @max_mapositiontaking_2 ELSE @mpositiontaking_2 END
SELECT @mpositiontaking_4 = CASE WHEN @mpositiontaking_4 > @max_mapositiontaking_4 THEN @max_mapositiontaking_4 ELSE @mpositiontaking_4 END
SELECT @mpositiontaking_5 = CASE WHEN @mpositiontaking_5 > @max_mapositiontaking_5 THEN @max_mapositiontaking_5 ELSE @mpositiontaking_5 END
SELECT @mpositiontaking_6 = CASE WHEN @mpositiontaking_6 > @max_mapositiontaking_6 THEN @max_mapositiontaking_6 ELSE @mpositiontaking_6 END
SELECT @mpositiontaking_9 = CASE WHEN @mpositiontaking_9 > @max_mapositiontaking_9 THEN @max_mapositiontaking_9 ELSE @mpositiontaking_9 END
SELECT @mpositiontaking_10 = CASE WHEN @mpositiontaking_10 > @max_mapositiontaking_10 THEN @max_mapositiontaking_10 ELSE @mpositiontaking_10 END

SELECT @v2mpositiontaking_1 = CASE WHEN @v2mpositiontaking_1 > @max_v2mapositiontaking_1 THEN @max_v2mapositiontaking_1 ELSE @v2mpositiontaking_1 END
SELECT @v2mpositiontaking_2 = CASE WHEN @v2mpositiontaking_2 > @max_v2mapositiontaking_2 THEN @max_v2mapositiontaking_2 ELSE @v2mpositiontaking_2 END
SELECT @v2mpositiontaking_3 = CASE WHEN @v2mpositiontaking_3 > @max_v2mapositiontaking_3 THEN @max_v2mapositiontaking_3 ELSE @v2mpositiontaking_3 END
SELECT @v2mpositiontaking_7 = CASE WHEN @v2mpositiontaking_7 > @max_v2mapositiontaking_7 THEN @max_v2mapositiontaking_7 ELSE @v2mpositiontaking_7 END
SELECT @v2mpositiontaking_8 = CASE WHEN @v2mpositiontaking_8 > @max_v2mapositiontaking_8 THEN @max_v2mapositiontaking_8 ELSE @v2mpositiontaking_8 END
SELECT @v2mpositiontaking_9 = CASE WHEN @v2mpositiontaking_9 > @max_v2mapositiontaking_9 THEN @max_v2mapositiontaking_9 ELSE @v2mpositiontaking_9 END
SELECT @v2mpositiontaking_20 = CASE WHEN @v2mpositiontaking_20 > @max_v2mapositiontaking_20 THEN @max_v2mapositiontaking_20 ELSE @v2mpositiontaking_20 END

SELECT @v3mpositiontaking_1 = CASE WHEN @v3mpositiontaking_1 > @max_v3mapositiontaking_1 THEN @max_v3mapositiontaking_1 ELSE @v3mpositiontaking_1 END
SELECT @v3mpositiontaking_2 = CASE WHEN @v3mpositiontaking_2 > @max_v3mapositiontaking_2 THEN @max_v3mapositiontaking_2 ELSE @v3mpositiontaking_2 END
SELECT @v3mpositiontaking_3 = CASE WHEN @v3mpositiontaking_3 > @max_v3mapositiontaking_3 THEN @max_v3mapositiontaking_3 ELSE @v3mpositiontaking_3 END
SELECT @v3mpositiontaking_20 = CASE WHEN @v3mpositiontaking_20 > @max_v3mapositiontaking_20 THEN @max_v3mapositiontaking_20 ELSE @v3mpositiontaking_20 END

SELECT @v5mpositiontaking_1 = CASE WHEN @v5mpositiontaking_1 > @max_v5mapositiontaking_1 THEN @max_v5mapositiontaking_1 ELSE @v5mpositiontaking_1 END
SELECT @v5mpositiontaking_2 = CASE WHEN @v5mpositiontaking_2 > @max_v5mapositiontaking_2 THEN @max_v5mapositiontaking_2 ELSE @v5mpositiontaking_2 END
SELECT @v5mpositiontaking_3 = CASE WHEN @v5mpositiontaking_3 > @max_v5mapositiontaking_3 THEN @max_v5mapositiontaking_3 ELSE @v5mpositiontaking_3 END
SELECT @v5mpositiontaking_20 = CASE WHEN @v5mpositiontaking_20 > @max_v5mapositiontaking_20 THEN @max_v5mapositiontaking_20 ELSE @v5mpositiontaking_20 END

SELECT @v8mpositiontaking_1 = CASE WHEN @v8mpositiontaking_1 > @max_v8mapositiontaking_1 THEN @max_v8mapositiontaking_1 ELSE @v8mpositiontaking_1 END
SELECT @v8mpositiontaking_3 = CASE WHEN @v8mpositiontaking_3 > @max_v8mapositiontaking_3 THEN @max_v8mapositiontaking_3 ELSE @v8mpositiontaking_3 END
SELECT @v8mpositiontaking_20 = CASE WHEN @v8mpositiontaking_20 > @max_v8mapositiontaking_20 THEN @max_v8mapositiontaking_20 ELSE @v8mpositiontaking_20 END

SELECT @v10mpositiontaking_1 = CASE WHEN @v10mpositiontaking_1 > @max_v10mapositiontaking_1 THEN @max_v10mapositiontaking_1 ELSE @v10mpositiontaking_1 END
SELECT @v10mpositiontaking_2 = CASE WHEN @v10mpositiontaking_2 > @max_v10mapositiontaking_2 THEN @max_v10mapositiontaking_2 ELSE @v10mpositiontaking_2 END
SELECT @v10mpositiontaking_3 = CASE WHEN @v10mpositiontaking_3 > @max_v10mapositiontaking_3 THEN @max_v10mapositiontaking_3 ELSE @v10mpositiontaking_3 END
SELECT @v10mpositiontaking_20 = CASE WHEN @v10mpositiontaking_20 > @max_v10mapositiontaking_20 THEN @max_v10mapositiontaking_20 ELSE @v10mpositiontaking_20 END

SELECT @v11mpositiontaking_1 = CASE WHEN @v11mpositiontaking_1 > @max_v11mapositiontaking_1 THEN @max_v11mapositiontaking_1 ELSE @v11mpositiontaking_1 END
SELECT @v11mpositiontaking_20 = CASE WHEN @v11mpositiontaking_20 > @max_v11mapositiontaking_20 THEN @max_v11mapositiontaking_20 ELSE @v11mpositiontaking_20 END

SELECT @v99mpositiontaking_1 = CASE WHEN @v99mpositiontaking_1 > @max_v99mapositiontaking_1 THEN @max_v99mapositiontaking_1 ELSE @v99mpositiontaking_1 END
SELECT @v99mpositiontaking_2 = CASE WHEN @v99mpositiontaking_2 > @max_v99mapositiontaking_2 THEN @max_v99mapositiontaking_2 ELSE @v99mpositiontaking_2 END
SELECT @v99mpositiontaking_3 = CASE WHEN @v99mpositiontaking_3 > @max_v99mapositiontaking_3 THEN @max_v99mapositiontaking_3 ELSE @v99mpositiontaking_3 END
SELECT @v99mpositiontaking_20 = CASE WHEN @v99mpositiontaking_20 > @max_v99mapositiontaking_20 THEN @max_v99mapositiontaking_20 ELSE @v99mpositiontaking_20 END

----------------------------------------------------------------------------------------------------------------------------
-- end auto master
*/



---------------------------------------------------------------------------------------------------------------------------------------------
--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in master account)
SELECT 
	@auto_spositiontaking_1 = CASE WHEN @isauto_spositiontaking_mem_1>0 THEN @auto_spositiontaking_mem_1 ELSE @auto_spositiontaking_1 END,
	@auto_spositiontaking_2 = CASE WHEN @isauto_spositiontaking_mem_2>0 THEN @auto_spositiontaking_mem_2 ELSE @auto_spositiontaking_2 END,
	@auto_spositiontaking_3 = CASE WHEN @isauto_spositiontaking_mem_3>0 THEN @auto_spositiontaking_mem_3 ELSE @auto_spositiontaking_3 END,
	@auto_spositiontaking_4 = CASE WHEN @isauto_spositiontaking_mem_4>0 THEN @auto_spositiontaking_mem_4 ELSE @auto_spositiontaking_4 END,
	@auto_spositiontaking_5 = CASE WHEN @isauto_spositiontaking_mem_5>0 THEN @auto_spositiontaking_mem_5 ELSE @auto_spositiontaking_5 END,
	@auto_spositiontaking_6 = CASE WHEN @isauto_spositiontaking_mem_6>0 THEN @auto_spositiontaking_mem_6 ELSE @auto_spositiontaking_6 END,
	@auto_spositiontaking_7 = CASE WHEN @isauto_spositiontaking_mem_7>0 THEN @auto_spositiontaking_mem_7 ELSE @auto_spositiontaking_7 END,
	@auto_spositiontaking_8 = CASE WHEN @isauto_spositiontaking_mem_8>0 THEN @auto_spositiontaking_mem_8 ELSE @auto_spositiontaking_8 END,
	@auto_spositiontaking_9 = CASE WHEN @isauto_spositiontaking_mem_9>0 THEN @auto_spositiontaking_mem_9 ELSE @auto_spositiontaking_9 END,
	@auto_spositiontaking_10 = CASE WHEN @isauto_spositiontaking_mem_10>0 THEN @auto_spositiontaking_mem_10 ELSE @auto_spositiontaking_10 END,

	@auto_slivepositiontaking_1 = CASE WHEN @isauto_slivepositiontaking_mem_1>0 THEN @auto_slivepositiontaking_mem_1 ELSE @auto_slivepositiontaking_1 END,
	@auto_slivepositiontaking_3 = CASE WHEN @isauto_slivepositiontaking_mem_3>0 THEN @auto_slivepositiontaking_mem_3 ELSE @auto_slivepositiontaking_3 END,
	@auto_slivepositiontaking_7 = CASE WHEN @isauto_slivepositiontaking_mem_7>0 THEN @auto_slivepositiontaking_mem_7 ELSE @auto_slivepositiontaking_7 END,
	@auto_slivepositiontaking_8 = CASE WHEN @isauto_slivepositiontaking_mem_8>0 THEN @auto_slivepositiontaking_mem_8 ELSE @auto_slivepositiontaking_8 END,

	@auto_v2spositiontaking_1 = CASE WHEN @isauto_v2spositiontaking_mem_1>0 THEN @auto_v2spositiontaking_mem_1 ELSE @auto_v2spositiontaking_1 END,
	@auto_v2spositiontaking_2 = CASE WHEN @isauto_v2spositiontaking_mem_2>0 THEN @auto_v2spositiontaking_mem_2 ELSE @auto_v2spositiontaking_2 END,
	@auto_v2spositiontaking_3 = CASE WHEN @isauto_v2spositiontaking_mem_3>0 THEN @auto_v2spositiontaking_mem_3 ELSE @auto_v2spositiontaking_3 END,
	@auto_v2spositiontaking_7 = CASE WHEN @isauto_v2spositiontaking_mem_7>0 THEN @auto_v2spositiontaking_mem_7 ELSE @auto_v2spositiontaking_7 END,
	@auto_v2spositiontaking_8 = CASE WHEN @isauto_v2spositiontaking_mem_8>0 THEN @auto_v2spositiontaking_mem_8 ELSE @auto_v2spositiontaking_8 END,
	@auto_v2spositiontaking_9 = CASE WHEN @isauto_v2spositiontaking_mem_9>0 THEN @auto_v2spositiontaking_mem_9 ELSE @auto_v2spositiontaking_9 END,
	@auto_v2spositiontaking_20 = CASE WHEN @isauto_v2spositiontaking_mem_20>0 THEN @auto_v2spositiontaking_mem_20 ELSE @auto_v2spositiontaking_20 END,

	@auto_v3spositiontaking_1 = CASE WHEN @isauto_v3spositiontaking_mem_1>0 THEN @auto_v3spositiontaking_mem_1 ELSE @auto_v3spositiontaking_1 END,
	@auto_v3spositiontaking_2 = CASE WHEN @isauto_v3spositiontaking_mem_2>0 THEN @auto_v3spositiontaking_mem_2 ELSE @auto_v3spositiontaking_2 END,
	@auto_v3spositiontaking_3 = CASE WHEN @isauto_v3spositiontaking_mem_3>0 THEN @auto_v3spositiontaking_mem_3 ELSE @auto_v3spositiontaking_3 END,
	@auto_v3spositiontaking_20 = CASE WHEN @isauto_v3spositiontaking_mem_20>0 THEN @auto_v3spositiontaking_mem_20 ELSE @auto_v3spositiontaking_20 END,

	@auto_v5spositiontaking_1 = CASE WHEN @isauto_v5spositiontaking_mem_1>0 THEN @auto_v5spositiontaking_mem_1 ELSE @auto_v5spositiontaking_1 END,
	@auto_v5spositiontaking_2 = CASE WHEN @isauto_v5spositiontaking_mem_2>0 THEN @auto_v5spositiontaking_mem_2 ELSE @auto_v5spositiontaking_2 END,
	@auto_v5spositiontaking_3 = CASE WHEN @isauto_v5spositiontaking_mem_3>0 THEN @auto_v5spositiontaking_mem_3 ELSE @auto_v5spositiontaking_3 END,
	@auto_v5spositiontaking_20 = CASE WHEN @isauto_v5spositiontaking_mem_20>0 THEN @auto_v5spositiontaking_mem_20 ELSE @auto_v5spositiontaking_20 END,

	@auto_v8spositiontaking_1 = CASE WHEN @isauto_v8spositiontaking_mem_1>0 THEN @auto_v8spositiontaking_mem_1 ELSE @auto_v8spositiontaking_1 END,
	@auto_v8spositiontaking_3 = CASE WHEN @isauto_v8spositiontaking_mem_3>0 THEN @auto_v8spositiontaking_mem_3 ELSE @auto_v8spositiontaking_3 END,
	@auto_v8spositiontaking_20 = CASE WHEN @isauto_v8spositiontaking_mem_20>0 THEN @auto_v8spositiontaking_mem_20 ELSE @auto_v8spositiontaking_20 END,

	@auto_v10spositiontaking_1 = CASE WHEN @isauto_v10spositiontaking_mem_1>0 THEN @auto_v10spositiontaking_mem_1 ELSE @auto_v10spositiontaking_1 END,
	@auto_v10spositiontaking_2 = CASE WHEN @isauto_v10spositiontaking_mem_2>0 THEN @auto_v10spositiontaking_mem_2 ELSE @auto_v10spositiontaking_2 END,
	@auto_v10spositiontaking_3 = CASE WHEN @isauto_v10spositiontaking_mem_3>0 THEN @auto_v10spositiontaking_mem_3 ELSE @auto_v10spositiontaking_3 END,
	@auto_v10spositiontaking_20 = CASE WHEN @isauto_v10spositiontaking_mem_20>0 THEN @auto_v10spositiontaking_mem_20 ELSE @auto_v10spositiontaking_20 END,

	@auto_v11spositiontaking_1 = CASE WHEN @isauto_v11spositiontaking_mem_1>0 THEN @auto_v11spositiontaking_mem_1 ELSE @auto_v11spositiontaking_1 END,
	@auto_v11spositiontaking_20 = CASE WHEN @isauto_v11spositiontaking_mem_20>0 THEN @auto_v11spositiontaking_mem_20 ELSE @auto_v11spositiontaking_20 END,

	@auto_v99spositiontaking_1 = CASE WHEN @isauto_v99spositiontaking_mem_1>0 THEN @auto_v99spositiontaking_mem_1 ELSE @auto_v99spositiontaking_1 END,
	@auto_v99spositiontaking_2 = CASE WHEN @isauto_v99spositiontaking_mem_2>0 THEN @auto_v99spositiontaking_mem_2 ELSE @auto_v99spositiontaking_2 END,
	@auto_v99spositiontaking_3 = CASE WHEN @isauto_v99spositiontaking_mem_3>0 THEN @auto_v99spositiontaking_mem_3 ELSE @auto_v99spositiontaking_3 END,
	@auto_v99spositiontaking_20 = CASE WHEN @isauto_v99spositiontaking_mem_20>0 THEN @auto_v99spositiontaking_mem_20 ELSE @auto_v99spositiontaking_20 END,

	@isauto_spositiontaking_1 = CASE WHEN @isauto_spositiontaking_mem_1>0 THEN @isauto_spositiontaking_mem_1 ELSE @isauto_spositiontaking_1 END,
	@isauto_spositiontaking_2 = CASE WHEN @isauto_spositiontaking_mem_2>0 THEN @isauto_spositiontaking_mem_2 ELSE @isauto_spositiontaking_2 END,
	@isauto_spositiontaking_3 = CASE WHEN @isauto_spositiontaking_mem_3>0 THEN @isauto_spositiontaking_mem_3 ELSE @isauto_spositiontaking_3 END,
	@isauto_spositiontaking_4 = CASE WHEN @isauto_spositiontaking_mem_4>0 THEN @isauto_spositiontaking_mem_4 ELSE @isauto_spositiontaking_4 END,
	@isauto_spositiontaking_5 = CASE WHEN @isauto_spositiontaking_mem_5>0 THEN @isauto_spositiontaking_mem_5 ELSE @isauto_spositiontaking_5 END,
	@isauto_spositiontaking_6 = CASE WHEN @isauto_spositiontaking_mem_6>0 THEN @isauto_spositiontaking_mem_6 ELSE @isauto_spositiontaking_6 END,
	@isauto_spositiontaking_7 = CASE WHEN @isauto_spositiontaking_mem_7>0 THEN @isauto_spositiontaking_mem_7 ELSE @isauto_spositiontaking_7 END,
	@isauto_spositiontaking_8 = CASE WHEN @isauto_spositiontaking_mem_8>0 THEN @isauto_spositiontaking_mem_8 ELSE @isauto_spositiontaking_8 END,
	@isauto_spositiontaking_9 = CASE WHEN @isauto_spositiontaking_mem_9>0 THEN @isauto_spositiontaking_mem_9 ELSE @isauto_spositiontaking_9 END,
	@isauto_spositiontaking_10 = CASE WHEN @isauto_spositiontaking_mem_10>0 THEN @isauto_spositiontaking_mem_10 ELSE @isauto_spositiontaking_10 END,

	@isauto_slivepositiontaking_1 = CASE WHEN @isauto_slivepositiontaking_mem_1>0 THEN @isauto_slivepositiontaking_mem_1 ELSE @isauto_slivepositiontaking_1 END,
	@isauto_slivepositiontaking_3 = CASE WHEN @isauto_slivepositiontaking_mem_3>0 THEN @isauto_slivepositiontaking_mem_3 ELSE @isauto_slivepositiontaking_3 END,
	@isauto_slivepositiontaking_7 = CASE WHEN @isauto_slivepositiontaking_mem_7>0 THEN @isauto_slivepositiontaking_mem_7 ELSE @isauto_slivepositiontaking_7 END,
	@isauto_slivepositiontaking_8 = CASE WHEN @isauto_slivepositiontaking_mem_8>0 THEN @isauto_slivepositiontaking_mem_8 ELSE @isauto_slivepositiontaking_8 END,

	@isauto_v2spositiontaking_1 = CASE WHEN @isauto_v2spositiontaking_mem_1>0 THEN @isauto_v2spositiontaking_mem_1 ELSE @isauto_v2spositiontaking_1 END,
	@isauto_v2spositiontaking_2 = CASE WHEN @isauto_v2spositiontaking_mem_2>0 THEN @isauto_v2spositiontaking_mem_2 ELSE @isauto_v2spositiontaking_2 END,
	@isauto_v2spositiontaking_3 = CASE WHEN @isauto_v2spositiontaking_mem_3>0 THEN @isauto_v2spositiontaking_mem_3 ELSE @isauto_v2spositiontaking_3 END,
	@isauto_v2spositiontaking_7 = CASE WHEN @isauto_v2spositiontaking_mem_7>0 THEN @isauto_v2spositiontaking_mem_7 ELSE @isauto_v2spositiontaking_7 END,
	@isauto_v2spositiontaking_8 = CASE WHEN @isauto_v2spositiontaking_mem_8>0 THEN @isauto_v2spositiontaking_mem_8 ELSE @isauto_v2spositiontaking_8 END,
	@isauto_v2spositiontaking_9 = CASE WHEN @isauto_v2spositiontaking_mem_9>0 THEN @isauto_v2spositiontaking_mem_9 ELSE @isauto_v2spositiontaking_9 END,
	@isauto_v2spositiontaking_20 = CASE WHEN @isauto_v2spositiontaking_mem_20>0 THEN @isauto_v2spositiontaking_mem_20 ELSE @isauto_v2spositiontaking_20 END,

	@isauto_v3spositiontaking_1 = CASE WHEN @isauto_v3spositiontaking_mem_1>0 THEN @isauto_v3spositiontaking_mem_1 ELSE @isauto_v3spositiontaking_1 END,
	@isauto_v3spositiontaking_2 = CASE WHEN @isauto_v3spositiontaking_mem_2>0 THEN @isauto_v3spositiontaking_mem_2 ELSE @isauto_v3spositiontaking_2 END,
	@isauto_v3spositiontaking_3 = CASE WHEN @isauto_v3spositiontaking_mem_3>0 THEN @isauto_v3spositiontaking_mem_3 ELSE @isauto_v3spositiontaking_3 END,
	@isauto_v3spositiontaking_20 = CASE WHEN @isauto_v3spositiontaking_mem_20>0 THEN @isauto_v3spositiontaking_mem_20 ELSE @isauto_v3spositiontaking_20 END,

	@isauto_v5spositiontaking_1 = CASE WHEN @isauto_v5spositiontaking_mem_1>0 THEN @isauto_v5spositiontaking_mem_1 ELSE @isauto_v5spositiontaking_1 END,
	@isauto_v5spositiontaking_2 = CASE WHEN @isauto_v5spositiontaking_mem_2>0 THEN @isauto_v5spositiontaking_mem_2 ELSE @isauto_v5spositiontaking_2 END,
	@isauto_v5spositiontaking_3 = CASE WHEN @isauto_v5spositiontaking_mem_3>0 THEN @isauto_v5spositiontaking_mem_3 ELSE @isauto_v5spositiontaking_3 END,
	@isauto_v5spositiontaking_20 = CASE WHEN @isauto_v5spositiontaking_mem_20>0 THEN @isauto_v5spositiontaking_mem_20 ELSE @isauto_v5spositiontaking_20 END,

	@isauto_v8spositiontaking_1 = CASE WHEN @isauto_v8spositiontaking_mem_1>0 THEN @isauto_v8spositiontaking_mem_1 ELSE @isauto_v8spositiontaking_1 END,
	@isauto_v8spositiontaking_3 = CASE WHEN @isauto_v8spositiontaking_mem_3>0 THEN @isauto_v8spositiontaking_mem_3 ELSE @isauto_v8spositiontaking_3 END,
	@isauto_v8spositiontaking_20 = CASE WHEN @isauto_v8spositiontaking_mem_20>0 THEN @isauto_v8spositiontaking_mem_20 ELSE @isauto_v8spositiontaking_20 END,

	@isauto_v10spositiontaking_1 = CASE WHEN @isauto_v10spositiontaking_mem_1>0 THEN @isauto_v10spositiontaking_mem_1 ELSE @isauto_v10spositiontaking_1 END,
	@isauto_v10spositiontaking_2 = CASE WHEN @isauto_v10spositiontaking_mem_2>0 THEN @isauto_v10spositiontaking_mem_2 ELSE @isauto_v10spositiontaking_2 END,
	@isauto_v10spositiontaking_3 = CASE WHEN @isauto_v10spositiontaking_mem_3>0 THEN @isauto_v10spositiontaking_mem_3 ELSE @isauto_v10spositiontaking_3 END,
	@isauto_v10spositiontaking_20 = CASE WHEN @isauto_v10spositiontaking_mem_20>0 THEN @isauto_v10spositiontaking_mem_20 ELSE @isauto_v10spositiontaking_20 END,

	@isauto_v11spositiontaking_1 = CASE WHEN @isauto_v11spositiontaking_mem_1>0 THEN @isauto_v11spositiontaking_mem_1 ELSE @isauto_v11spositiontaking_1 END,
	@isauto_v11spositiontaking_20 = CASE WHEN @isauto_v11spositiontaking_mem_20>0 THEN @isauto_v11spositiontaking_mem_20 ELSE @isauto_v11spositiontaking_20 END,

	@isauto_v99spositiontaking_1 = CASE WHEN @isauto_v99spositiontaking_mem_1>0 THEN @isauto_v99spositiontaking_mem_1 ELSE @isauto_v99spositiontaking_1 END,
	@isauto_v99spositiontaking_2 = CASE WHEN @isauto_v99spositiontaking_mem_2>0 THEN @isauto_v99spositiontaking_mem_2 ELSE @isauto_v99spositiontaking_2 END,
	@isauto_v99spositiontaking_3 = CASE WHEN @isauto_v99spositiontaking_mem_3>0 THEN @isauto_v99spositiontaking_mem_3 ELSE @isauto_v99spositiontaking_3 END,
	@isauto_v99spositiontaking_20 = CASE WHEN @isauto_v99spositiontaking_mem_20>0 THEN @isauto_v99spositiontaking_mem_20 ELSE @isauto_v99spositiontaking_20 END
---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
SELECT @spositiontaking_1 = CASE WHEN ISNULL(@isauto_spositiontaking_1, 0)<=0 THEN @spositiontaking_1 ELSE CASE WHEN @auto_spositiontaking_1 < @max_spositiontaking_1 - @mpositiontaking_1 - @apositiontaking_1 THEN @auto_spositiontaking_1 ELSE @max_spositiontaking_1 - @mpositiontaking_1 - @apositiontaking_1 END END
SELECT @spositiontaking_3 = CASE WHEN ISNULL(@isauto_spositiontaking_3, 0)<=0 THEN @spositiontaking_3 ELSE CASE WHEN @auto_spositiontaking_3 < @max_spositiontaking_3 - @mpositiontaking_3 - @apositiontaking_3 THEN @auto_spositiontaking_3 ELSE @max_spositiontaking_3 - @mpositiontaking_3 - @apositiontaking_3 END END
SELECT @spositiontaking_7 = CASE WHEN ISNULL(@isauto_spositiontaking_7, 0)<=0 THEN @spositiontaking_7 ELSE CASE WHEN @auto_spositiontaking_7 < @max_spositiontaking_7 - @mpositiontaking_7 - @apositiontaking_7 THEN @auto_spositiontaking_7 ELSE @max_spositiontaking_7 - @mpositiontaking_7 - @apositiontaking_7 END END
SELECT @spositiontaking_8 = CASE WHEN ISNULL(@isauto_spositiontaking_8, 0)<=0 THEN @spositiontaking_8 ELSE CASE WHEN @auto_spositiontaking_8 < @max_spositiontaking_8 - @mpositiontaking_8 - @apositiontaking_8 THEN @auto_spositiontaking_8 ELSE @max_spositiontaking_8 - @mpositiontaking_8 - @apositiontaking_8 END END

SELECT @slivepositiontaking_1 = CASE WHEN ISNULL(@isauto_slivepositiontaking_1, 0)<=0 THEN @slivepositiontaking_1 ELSE CASE WHEN @auto_slivepositiontaking_1 < @max_slivepositiontaking_1 - @mlivepositiontaking_1 - @alivepositiontaking_1 THEN @auto_slivepositiontaking_1 ELSE @max_slivepositiontaking_1 - @mlivepositiontaking_1 - @alivepositiontaking_1 END END
SELECT @slivepositiontaking_3 = CASE WHEN ISNULL(@isauto_slivepositiontaking_3, 0)<=0 THEN @slivepositiontaking_3 ELSE CASE WHEN @auto_slivepositiontaking_3 < @max_slivepositiontaking_3 - @mlivepositiontaking_3 - @alivepositiontaking_3 THEN @auto_slivepositiontaking_3 ELSE @max_slivepositiontaking_3 - @mlivepositiontaking_3 - @alivepositiontaking_3 END END
SELECT @slivepositiontaking_7 = CASE WHEN ISNULL(@isauto_slivepositiontaking_7, 0)<=0 THEN @slivepositiontaking_7 ELSE CASE WHEN @auto_slivepositiontaking_7 < @max_slivepositiontaking_7 - @mlivepositiontaking_7 - @alivepositiontaking_7 THEN @auto_slivepositiontaking_7 ELSE @max_slivepositiontaking_7 - @mlivepositiontaking_7 - @alivepositiontaking_7 END END
SELECT @slivepositiontaking_8 = CASE WHEN ISNULL(@isauto_slivepositiontaking_8, 0)<=0 THEN @slivepositiontaking_8 ELSE CASE WHEN @auto_slivepositiontaking_8 < @max_slivepositiontaking_8 - @mlivepositiontaking_8 - @alivepositiontaking_8 THEN @auto_slivepositiontaking_8 ELSE @max_slivepositiontaking_8 - @mlivepositiontaking_8 - @alivepositiontaking_8 END END

SELECT @spositiontaking_2 = CASE WHEN ISNULL(@isauto_spositiontaking_2, 0)<=0 THEN @spositiontaking_2 ELSE CASE WHEN @auto_spositiontaking_2 < @max_spositiontaking_2 - @mpositiontaking_2 - @apositiontaking_2 THEN @auto_spositiontaking_2 ELSE @max_spositiontaking_2 - @mpositiontaking_2 - @apositiontaking_2 END END
SELECT @spositiontaking_4 = CASE WHEN ISNULL(@isauto_spositiontaking_4, 0)<=0 THEN @spositiontaking_4 ELSE CASE WHEN @auto_spositiontaking_4 < @max_spositiontaking_4 - @mpositiontaking_4 - @apositiontaking_4 THEN @auto_spositiontaking_4 ELSE @max_spositiontaking_4 - @mpositiontaking_4 - @apositiontaking_4 END END
SELECT @spositiontaking_5 = CASE WHEN ISNULL(@isauto_spositiontaking_5, 0)<=0 THEN @spositiontaking_5 ELSE CASE WHEN @auto_spositiontaking_5 < @max_spositiontaking_5 - @mpositiontaking_5 - @apositiontaking_5 THEN @auto_spositiontaking_5 ELSE @max_spositiontaking_5 - @mpositiontaking_5 - @apositiontaking_5 END END
SELECT @spositiontaking_6 = CASE WHEN ISNULL(@isauto_spositiontaking_6, 0)<=0 THEN @spositiontaking_6 ELSE CASE WHEN @auto_spositiontaking_6 < @max_spositiontaking_6 - @mpositiontaking_6 - @apositiontaking_6 THEN @auto_spositiontaking_6 ELSE @max_spositiontaking_6 - @mpositiontaking_6 - @apositiontaking_6 END END
SELECT @spositiontaking_9 = CASE WHEN ISNULL(@isauto_spositiontaking_9, 0)<=0 THEN @spositiontaking_9 ELSE CASE WHEN @auto_spositiontaking_9 < @max_spositiontaking_9 - @mpositiontaking_9 - @apositiontaking_9 THEN @auto_spositiontaking_9 ELSE @max_spositiontaking_9 - @mpositiontaking_9 - @apositiontaking_9 END END
SELECT @spositiontaking_10 = CASE WHEN ISNULL(@isauto_spositiontaking_10, 0)<=0 THEN @spositiontaking_10 ELSE CASE WHEN @auto_spositiontaking_10 < @max_spositiontaking_10 - @mpositiontaking_10 - @apositiontaking_10 THEN @auto_spositiontaking_10 ELSE @max_spositiontaking_10 - @mpositiontaking_10 - @apositiontaking_10 END END

SELECT @v2spositiontaking_1 = CASE WHEN ISNULL(@isauto_v2spositiontaking_1, 0)<=0 THEN @v2spositiontaking_1 ELSE CASE WHEN @auto_v2spositiontaking_1 < @max_v2spositiontaking_1 - @v2mpositiontaking_1 - @v2apositiontaking_1 THEN @auto_v2spositiontaking_1 ELSE @max_v2spositiontaking_1 - @v2mpositiontaking_1 - @v2apositiontaking_1 END END
SELECT @v2spositiontaking_2 = CASE WHEN ISNULL(@isauto_v2spositiontaking_2, 0)<=0 THEN @v2spositiontaking_2 ELSE CASE WHEN @auto_v2spositiontaking_2 < @max_v2spositiontaking_2 - @v2mpositiontaking_2 - @v2apositiontaking_2 THEN @auto_v2spositiontaking_2 ELSE @max_v2spositiontaking_2 - @v2mpositiontaking_2 - @v2apositiontaking_2 END END
SELECT @v2spositiontaking_3 = CASE WHEN ISNULL(@isauto_v2spositiontaking_3, 0)<=0 THEN @v2spositiontaking_3 ELSE CASE WHEN @auto_v2spositiontaking_3 < @max_v2spositiontaking_3 - @v2mpositiontaking_3 - @v2apositiontaking_3 THEN @auto_v2spositiontaking_3 ELSE @max_v2spositiontaking_3 - @v2mpositiontaking_3 - @v2apositiontaking_3 END END
SELECT @v2spositiontaking_7 = CASE WHEN ISNULL(@isauto_v2spositiontaking_7, 0)<=0 THEN @v2spositiontaking_7 ELSE CASE WHEN @auto_v2spositiontaking_7 < @max_v2spositiontaking_7 - @v2mpositiontaking_7 - @v2apositiontaking_7 THEN @auto_v2spositiontaking_7 ELSE @max_v2spositiontaking_7 - @v2mpositiontaking_7 - @v2apositiontaking_7 END END
SELECT @v2spositiontaking_8 = CASE WHEN ISNULL(@isauto_v2spositiontaking_8, 0)<=0 THEN @v2spositiontaking_8 ELSE CASE WHEN @auto_v2spositiontaking_8 < @max_v2spositiontaking_8 - @v2mpositiontaking_8 - @v2apositiontaking_8 THEN @auto_v2spositiontaking_8 ELSE @max_v2spositiontaking_8 - @v2mpositiontaking_8 - @v2apositiontaking_8 END END
SELECT @v2spositiontaking_9 = CASE WHEN ISNULL(@isauto_v2spositiontaking_9, 0)<=0 THEN @v2spositiontaking_9 ELSE CASE WHEN @auto_v2spositiontaking_9 < @max_v2spositiontaking_9 - @v2mpositiontaking_9 - @v2apositiontaking_9 THEN @auto_v2spositiontaking_9 ELSE @max_v2spositiontaking_9 - @v2mpositiontaking_9 - @v2apositiontaking_9 END END
SELECT @v2spositiontaking_20 = CASE WHEN ISNULL(@isauto_v2spositiontaking_20, 0)<=0 THEN @v2spositiontaking_20 ELSE CASE WHEN @auto_v2spositiontaking_20 < @max_v2spositiontaking_20 - @v2mpositiontaking_20 - @v2apositiontaking_20 THEN @auto_v2spositiontaking_20 ELSE @max_v2spositiontaking_20 - @v2mpositiontaking_20 - @v2apositiontaking_20 END END

SELECT @v3spositiontaking_1 = CASE WHEN ISNULL(@isauto_v3spositiontaking_1, 0)<=0 THEN @v3spositiontaking_1 ELSE CASE WHEN @auto_v3spositiontaking_1 < @max_v3spositiontaking_1 - @v3mpositiontaking_1 - @v3apositiontaking_1 THEN @auto_v3spositiontaking_1 ELSE @max_v3spositiontaking_1 - @v3mpositiontaking_1 - @v3apositiontaking_1 END END
SELECT @v3spositiontaking_2 = CASE WHEN ISNULL(@isauto_v3spositiontaking_2, 0)<=0 THEN @v3spositiontaking_2 ELSE CASE WHEN @auto_v3spositiontaking_2 < @max_v3spositiontaking_2 - @v3mpositiontaking_2 - @v3apositiontaking_2 THEN @auto_v3spositiontaking_2 ELSE @max_v3spositiontaking_2 - @v3mpositiontaking_2 - @v3apositiontaking_2 END END
SELECT @v3spositiontaking_3 = CASE WHEN ISNULL(@isauto_v3spositiontaking_3, 0)<=0 THEN @v3spositiontaking_3 ELSE CASE WHEN @auto_v3spositiontaking_3 < @max_v3spositiontaking_3 - @v3mpositiontaking_3 - @v3apositiontaking_3 THEN @auto_v3spositiontaking_3 ELSE @max_v3spositiontaking_3 - @v3mpositiontaking_3 - @v3apositiontaking_3 END END
SELECT @v3spositiontaking_20 = CASE WHEN ISNULL(@isauto_v3spositiontaking_20, 0)<=0 THEN @v3spositiontaking_20 ELSE CASE WHEN @auto_v3spositiontaking_20 < @max_v3spositiontaking_20 - @v3mpositiontaking_20 - @v3apositiontaking_20 THEN @auto_v3spositiontaking_20 ELSE @max_v3spositiontaking_20 - @v3mpositiontaking_20 - @v3apositiontaking_20 END END

SELECT @v5spositiontaking_1 = CASE WHEN ISNULL(@isauto_v5spositiontaking_1, 0)<=0 THEN @v5spositiontaking_1 ELSE CASE WHEN @auto_v5spositiontaking_1 < @max_v5spositiontaking_1 - @v5mpositiontaking_1 - @v5apositiontaking_1 THEN @auto_v5spositiontaking_1 ELSE @max_v5spositiontaking_1 - @v5mpositiontaking_1 - @v5apositiontaking_1 END END
SELECT @v5spositiontaking_2 = CASE WHEN ISNULL(@isauto_v5spositiontaking_2, 0)<=0 THEN @v5spositiontaking_2 ELSE CASE WHEN @auto_v5spositiontaking_2 < @max_v5spositiontaking_2 - @v5mpositiontaking_2 - @v5apositiontaking_2 THEN @auto_v5spositiontaking_2 ELSE @max_v5spositiontaking_2 - @v5mpositiontaking_2 - @v5apositiontaking_2 END END
SELECT @v5spositiontaking_3 = CASE WHEN ISNULL(@isauto_v5spositiontaking_3, 0)<=0 THEN @v5spositiontaking_3 ELSE CASE WHEN @auto_v5spositiontaking_3 < @max_v5spositiontaking_3 - @v5mpositiontaking_3 - @v5apositiontaking_3 THEN @auto_v5spositiontaking_3 ELSE @max_v5spositiontaking_3 - @v5mpositiontaking_3 - @v5apositiontaking_3 END END
SELECT @v5spositiontaking_20 = CASE WHEN ISNULL(@isauto_v5spositiontaking_20, 0)<=0 THEN @v5spositiontaking_20 ELSE CASE WHEN @auto_v5spositiontaking_20 < @max_v5spositiontaking_20 - @v5mpositiontaking_20 - @v5apositiontaking_20 THEN @auto_v5spositiontaking_20 ELSE @max_v5spositiontaking_20 - @v5mpositiontaking_20 - @v5apositiontaking_20 END END

SELECT @v8spositiontaking_1 = CASE WHEN ISNULL(@isauto_v8spositiontaking_1, 0)<=0 THEN @v8spositiontaking_1 ELSE CASE WHEN @auto_v8spositiontaking_1 < @max_v8spositiontaking_1 - @v8mpositiontaking_1 - @v8apositiontaking_1 THEN @auto_v8spositiontaking_1 ELSE @max_v8spositiontaking_1 - @v8mpositiontaking_1 - @v8apositiontaking_1 END END
SELECT @v8spositiontaking_3 = CASE WHEN ISNULL(@isauto_v8spositiontaking_3, 0)<=0 THEN @v8spositiontaking_3 ELSE CASE WHEN @auto_v8spositiontaking_3 < @max_v8spositiontaking_3 - @v8mpositiontaking_3 - @v8apositiontaking_3 THEN @auto_v8spositiontaking_3 ELSE @max_v8spositiontaking_3 - @v8mpositiontaking_3 - @v8apositiontaking_3 END END
SELECT @v8spositiontaking_20 = CASE WHEN ISNULL(@isauto_v8spositiontaking_20, 0)<=0 THEN @v8spositiontaking_20 ELSE CASE WHEN @auto_v8spositiontaking_20 < @max_v8spositiontaking_20 - @v8mpositiontaking_20 - @v8apositiontaking_20 THEN @auto_v8spositiontaking_20 ELSE @max_v8spositiontaking_20 - @v8mpositiontaking_20 - @v8apositiontaking_20 END END

SELECT @v10spositiontaking_1 = CASE WHEN ISNULL(@isauto_v10spositiontaking_1, 0)<=0 THEN @v10spositiontaking_1 ELSE CASE WHEN @auto_v10spositiontaking_1 < @max_v10spositiontaking_1 - @v10mpositiontaking_1 - @v10apositiontaking_1 THEN @auto_v10spositiontaking_1 ELSE @max_v10spositiontaking_1 - @v10mpositiontaking_1 - @v10apositiontaking_1 END END
SELECT @v10spositiontaking_2 = CASE WHEN ISNULL(@isauto_v10spositiontaking_2, 0)<=0 THEN @v10spositiontaking_2 ELSE CASE WHEN @auto_v10spositiontaking_2 < @max_v10spositiontaking_2 - @v10mpositiontaking_2 - @v10apositiontaking_2 THEN @auto_v10spositiontaking_2 ELSE @max_v10spositiontaking_2 - @v10mpositiontaking_2 - @v10apositiontaking_2 END END
SELECT @v10spositiontaking_3 = CASE WHEN ISNULL(@isauto_v10spositiontaking_3, 0)<=0 THEN @v10spositiontaking_3 ELSE CASE WHEN @auto_v10spositiontaking_3 < @max_v10spositiontaking_3 - @v10mpositiontaking_3 - @v10apositiontaking_3 THEN @auto_v10spositiontaking_3 ELSE @max_v10spositiontaking_3 - @v10mpositiontaking_3 - @v10apositiontaking_3 END END
SELECT @v10spositiontaking_20 = CASE WHEN ISNULL(@isauto_v10spositiontaking_20, 0)<=0 THEN @v10spositiontaking_20 ELSE CASE WHEN @auto_v10spositiontaking_20 < @max_v10spositiontaking_20 - @v10mpositiontaking_20 - @v10apositiontaking_20 THEN @auto_v10spositiontaking_20 ELSE @max_v10spositiontaking_20 - @v10mpositiontaking_20 - @v10apositiontaking_20 END END

SELECT @v11spositiontaking_1 = CASE WHEN ISNULL(@isauto_v11spositiontaking_1, 0)<=0 THEN @v11spositiontaking_1 ELSE CASE WHEN @auto_v11spositiontaking_1 < @max_v11spositiontaking_1 - @v11mpositiontaking_1 - @v11apositiontaking_1 THEN @auto_v11spositiontaking_1 ELSE @max_v11spositiontaking_1 - @v11mpositiontaking_1 - @v11apositiontaking_1 END END
SELECT @v11spositiontaking_20 = CASE WHEN ISNULL(@isauto_v11spositiontaking_20, 0)<=0 THEN @v11spositiontaking_20 ELSE CASE WHEN @auto_v11spositiontaking_20 < @max_v11spositiontaking_20 - @v11mpositiontaking_20 - @v11apositiontaking_20 THEN @auto_v11spositiontaking_20 ELSE @max_v11spositiontaking_20 - @v11mpositiontaking_20 - @v11apositiontaking_20 END END

SELECT @v99spositiontaking_1 = CASE WHEN ISNULL(@isauto_v99spositiontaking_1, 0)<=0 THEN @v99spositiontaking_1 ELSE CASE WHEN @auto_v99spositiontaking_1 < @max_v99spositiontaking_1 - @v99mpositiontaking_1 - @v99apositiontaking_1 THEN @auto_v99spositiontaking_1 ELSE @max_v99spositiontaking_1 - @v99mpositiontaking_1 - @v99apositiontaking_1 END END
SELECT @v99spositiontaking_2 = CASE WHEN ISNULL(@isauto_v99spositiontaking_2, 0)<=0 THEN @v99spositiontaking_2 ELSE CASE WHEN @auto_v99spositiontaking_2 < @max_v99spositiontaking_2 - @v99mpositiontaking_2 - @v99apositiontaking_2 THEN @auto_v99spositiontaking_2 ELSE @max_v99spositiontaking_2 - @v99mpositiontaking_2 - @v99apositiontaking_2 END END
SELECT @v99spositiontaking_3 = CASE WHEN ISNULL(@isauto_v99spositiontaking_3, 0)<=0 THEN @v99spositiontaking_3 ELSE CASE WHEN @auto_v99spositiontaking_3 < @max_v99spositiontaking_3 - @v99mpositiontaking_3 - @v99apositiontaking_3 THEN @auto_v99spositiontaking_3 ELSE @max_v99spositiontaking_3 - @v99mpositiontaking_3 - @v99apositiontaking_3 END END
SELECT @v99spositiontaking_20 = CASE WHEN ISNULL(@isauto_v99spositiontaking_20, 0)<=0 THEN @v99spositiontaking_20 ELSE CASE WHEN @auto_v99spositiontaking_20 < @max_v99spositiontaking_20 - @v99mpositiontaking_20 - @v99apositiontaking_20 THEN @auto_v99spositiontaking_20 ELSE @max_v99spositiontaking_20 - @v99mpositiontaking_20 - @v99apositiontaking_20 END END

-------------------------------------------------------------------------------
--maxs1=isauto?s4:s4-m3
SELECT @max_spositiontaking_1 = CASE WHEN ISNULL(@isauto_spositiontaking_1, 0)>0 THEN @max_spositiontaking_1 ELSE @max_spositiontaking_1-@max_mapositiontaking_1 END
SELECT @max_spositiontaking_3 = CASE WHEN ISNULL(@isauto_spositiontaking_3, 0)>0 THEN @max_spositiontaking_3 ELSE @max_spositiontaking_3-@max_mapositiontaking_3 END
SELECT @max_spositiontaking_7 = CASE WHEN ISNULL(@isauto_spositiontaking_7, 0)>0 THEN @max_spositiontaking_7 ELSE @max_spositiontaking_7-@max_mapositiontaking_7 END
SELECT @max_spositiontaking_8 = CASE WHEN ISNULL(@isauto_spositiontaking_8, 0)>0 THEN @max_spositiontaking_8 ELSE @max_spositiontaking_8-@max_mapositiontaking_8 END

SELECT @max_slivepositiontaking_1 = CASE WHEN ISNULL(@isauto_slivepositiontaking_1, 0)>0 THEN @max_slivepositiontaking_1 ELSE @max_slivepositiontaking_1-@max_malivepositiontaking_1 END
SELECT @max_slivepositiontaking_3 = CASE WHEN ISNULL(@isauto_slivepositiontaking_3, 0)>0 THEN @max_slivepositiontaking_3 ELSE @max_slivepositiontaking_3-@max_malivepositiontaking_3 END
SELECT @max_slivepositiontaking_7 = CASE WHEN ISNULL(@isauto_slivepositiontaking_7, 0)>0 THEN @max_slivepositiontaking_7 ELSE @max_slivepositiontaking_7-@max_malivepositiontaking_7 END
SELECT @max_slivepositiontaking_8 = CASE WHEN ISNULL(@isauto_slivepositiontaking_8, 0)>0 THEN @max_slivepositiontaking_8 ELSE @max_slivepositiontaking_8-@max_malivepositiontaking_8 END

SELECT @max_spositiontaking_2 = CASE WHEN ISNULL(@isauto_spositiontaking_2, 0)>0 THEN @max_spositiontaking_2 ELSE @max_spositiontaking_2-@max_mapositiontaking_2 END
SELECT @max_spositiontaking_4 = CASE WHEN ISNULL(@isauto_spositiontaking_4, 0)>0 THEN @max_spositiontaking_4 ELSE @max_spositiontaking_4-@max_mapositiontaking_4 END
SELECT @max_spositiontaking_5 = CASE WHEN ISNULL(@isauto_spositiontaking_5, 0)>0 THEN @max_spositiontaking_5 ELSE @max_spositiontaking_5-@max_mapositiontaking_5 END
SELECT @max_spositiontaking_6 = CASE WHEN ISNULL(@isauto_spositiontaking_6, 0)>0 THEN @max_spositiontaking_6 ELSE @max_spositiontaking_6-@max_mapositiontaking_6 END
SELECT @max_spositiontaking_9 = CASE WHEN ISNULL(@isauto_spositiontaking_9, 0)>0 THEN @max_spositiontaking_9 ELSE @max_spositiontaking_9-@max_mapositiontaking_9 END
SELECT @max_spositiontaking_10 = CASE WHEN ISNULL(@isauto_spositiontaking_10, 0)>0 THEN @max_spositiontaking_10 ELSE @max_spositiontaking_10-@max_mapositiontaking_10 END

SELECT @max_v2spositiontaking_1 = CASE WHEN ISNULL(@isauto_v2spositiontaking_1, 0)>0 THEN @max_v2spositiontaking_1 ELSE @max_v2spositiontaking_1-@max_v2mapositiontaking_1 END
SELECT @max_v2spositiontaking_2 = CASE WHEN ISNULL(@isauto_v2spositiontaking_2, 0)>0 THEN @max_v2spositiontaking_2 ELSE @max_v2spositiontaking_2-@max_v2mapositiontaking_2 END
SELECT @max_v2spositiontaking_3 = CASE WHEN ISNULL(@isauto_v2spositiontaking_3, 0)>0 THEN @max_v2spositiontaking_3 ELSE @max_v2spositiontaking_3-@max_v2mapositiontaking_3 END
SELECT @max_v2spositiontaking_7 = CASE WHEN ISNULL(@isauto_v2spositiontaking_7, 0)>0 THEN @max_v2spositiontaking_7 ELSE @max_v2spositiontaking_7-@max_v2mapositiontaking_7 END
SELECT @max_v2spositiontaking_8 = CASE WHEN ISNULL(@isauto_v2spositiontaking_8, 0)>0 THEN @max_v2spositiontaking_8 ELSE @max_v2spositiontaking_8-@max_v2mapositiontaking_8 END
SELECT @max_v2spositiontaking_9 = CASE WHEN ISNULL(@isauto_v2spositiontaking_9, 0)>0 THEN @max_v2spositiontaking_9 ELSE @max_v2spositiontaking_9-@max_v2mapositiontaking_9 END
SELECT @max_v2spositiontaking_20 = CASE WHEN ISNULL(@isauto_v2spositiontaking_20, 0)>0 THEN @max_v2spositiontaking_20 ELSE @max_v2spositiontaking_20-@max_v2mapositiontaking_20 END

SELECT @max_v3spositiontaking_1 = CASE WHEN ISNULL(@isauto_v3spositiontaking_1, 0)>0 THEN @max_v3spositiontaking_1 ELSE @max_v3spositiontaking_1-@max_v3mapositiontaking_1 END
SELECT @max_v3spositiontaking_2 = CASE WHEN ISNULL(@isauto_v3spositiontaking_2, 0)>0 THEN @max_v3spositiontaking_2 ELSE @max_v3spositiontaking_2-@max_v3mapositiontaking_2 END
SELECT @max_v3spositiontaking_3 = CASE WHEN ISNULL(@isauto_v3spositiontaking_3, 0)>0 THEN @max_v3spositiontaking_3 ELSE @max_v3spositiontaking_3-@max_v3mapositiontaking_3 END
SELECT @max_v3spositiontaking_20 = CASE WHEN ISNULL(@isauto_v3spositiontaking_20, 0)>0 THEN @max_v3spositiontaking_20 ELSE @max_v3spositiontaking_20-@max_v3mapositiontaking_20 END

SELECT @max_v5spositiontaking_1 = CASE WHEN ISNULL(@isauto_v5spositiontaking_1, 0)>0 THEN @max_v5spositiontaking_1 ELSE @max_v5spositiontaking_1-@max_v5mapositiontaking_1 END
SELECT @max_v5spositiontaking_2 = CASE WHEN ISNULL(@isauto_v5spositiontaking_2, 0)>0 THEN @max_v5spositiontaking_2 ELSE @max_v5spositiontaking_2-@max_v5mapositiontaking_2 END
SELECT @max_v5spositiontaking_3 = CASE WHEN ISNULL(@isauto_v5spositiontaking_3, 0)>0 THEN @max_v5spositiontaking_3 ELSE @max_v5spositiontaking_3-@max_v5mapositiontaking_3 END
SELECT @max_v5spositiontaking_20 = CASE WHEN ISNULL(@isauto_v5spositiontaking_20, 0)>0 THEN @max_v5spositiontaking_20 ELSE @max_v5spositiontaking_20-@max_v5mapositiontaking_20 END

SELECT @max_v8spositiontaking_1 = CASE WHEN ISNULL(@isauto_v8spositiontaking_1, 0)>0 THEN @max_v8spositiontaking_1 ELSE @max_v8spositiontaking_1-@max_v8mapositiontaking_1 END
SELECT @max_v8spositiontaking_3 = CASE WHEN ISNULL(@isauto_v8spositiontaking_3, 0)>0 THEN @max_v8spositiontaking_3 ELSE @max_v8spositiontaking_3-@max_v8mapositiontaking_3 END
SELECT @max_v8spositiontaking_20 = CASE WHEN ISNULL(@isauto_v8spositiontaking_20, 0)>0 THEN @max_v8spositiontaking_20 ELSE @max_v8spositiontaking_20-@max_v8mapositiontaking_20 END

SELECT @max_v10spositiontaking_1 = CASE WHEN ISNULL(@isauto_v10spositiontaking_1, 0)>0 THEN @max_v10spositiontaking_1 ELSE @max_v10spositiontaking_1-@max_v10mapositiontaking_1 END
SELECT @max_v10spositiontaking_2 = CASE WHEN ISNULL(@isauto_v10spositiontaking_2, 0)>0 THEN @max_v10spositiontaking_2 ELSE @max_v10spositiontaking_2-@max_v10mapositiontaking_2 END
SELECT @max_v10spositiontaking_3 = CASE WHEN ISNULL(@isauto_v10spositiontaking_3, 0)>0 THEN @max_v10spositiontaking_3 ELSE @max_v10spositiontaking_3-@max_v10mapositiontaking_3 END
SELECT @max_v10spositiontaking_20 = CASE WHEN ISNULL(@isauto_v10spositiontaking_20, 0)>0 THEN @max_v10spositiontaking_20 ELSE @max_v10spositiontaking_20-@max_v10mapositiontaking_20 END

SELECT @max_v11spositiontaking_1 = CASE WHEN ISNULL(@isauto_v11spositiontaking_1, 0)>0 THEN @max_v11spositiontaking_1 ELSE @max_v11spositiontaking_1-@max_v11mapositiontaking_1 END
SELECT @max_v11spositiontaking_20 = CASE WHEN ISNULL(@isauto_v11spositiontaking_20, 0)>0 THEN @max_v11spositiontaking_20 ELSE @max_v11spositiontaking_20-@max_v11mapositiontaking_20 END

SELECT @max_v99spositiontaking_1 = CASE WHEN ISNULL(@isauto_v99spositiontaking_1, 0)>0 THEN @max_v99spositiontaking_1 ELSE @max_v99spositiontaking_1-@max_v99mapositiontaking_1 END
SELECT @max_v99spositiontaking_2 = CASE WHEN ISNULL(@isauto_v99spositiontaking_2, 0)>0 THEN @max_v99spositiontaking_2 ELSE @max_v99spositiontaking_2-@max_v99mapositiontaking_2 END
SELECT @max_v99spositiontaking_3 = CASE WHEN ISNULL(@isauto_v99spositiontaking_3, 0)>0 THEN @max_v99spositiontaking_3 ELSE @max_v99spositiontaking_3-@max_v99mapositiontaking_3 END
SELECT @max_v99spositiontaking_20 = CASE WHEN ISNULL(@isauto_v99spositiontaking_20, 0)>0 THEN @max_v99spositiontaking_20 ELSE @max_v99spositiontaking_20-@max_v99mapositiontaking_20 END
--s1=s1>maxs1?maxs1:s1
SELECT @spositiontaking_1 = CASE WHEN @spositiontaking_1 > @max_spositiontaking_1 THEN @max_spositiontaking_1 ELSE @spositiontaking_1 END
SELECT @spositiontaking_3 = CASE WHEN @spositiontaking_3 > @max_spositiontaking_3 THEN @max_spositiontaking_3 ELSE @spositiontaking_3 END
SELECT @spositiontaking_7 = CASE WHEN @spositiontaking_7 > @max_spositiontaking_7 THEN @max_spositiontaking_7 ELSE @spositiontaking_7 END
SELECT @spositiontaking_8 = CASE WHEN @spositiontaking_8 > @max_spositiontaking_8 THEN @max_spositiontaking_8 ELSE @spositiontaking_8 END

SELECT @slivepositiontaking_1 = CASE WHEN @slivepositiontaking_1 > @max_slivepositiontaking_1 THEN @max_slivepositiontaking_1 ELSE @slivepositiontaking_1 END
SELECT @slivepositiontaking_3 = CASE WHEN @slivepositiontaking_3 > @max_slivepositiontaking_3 THEN @max_slivepositiontaking_3 ELSE @slivepositiontaking_3 END
SELECT @slivepositiontaking_7 = CASE WHEN @slivepositiontaking_7 > @max_slivepositiontaking_7 THEN @max_slivepositiontaking_7 ELSE @slivepositiontaking_7 END
SELECT @slivepositiontaking_8 = CASE WHEN @slivepositiontaking_8 > @max_slivepositiontaking_8 THEN @max_slivepositiontaking_8 ELSE @slivepositiontaking_8 END

SELECT @spositiontaking_2 = CASE WHEN @spositiontaking_2 > @max_spositiontaking_2 THEN @max_spositiontaking_2 ELSE @spositiontaking_2 END
SELECT @spositiontaking_4 = CASE WHEN @spositiontaking_4 > @max_spositiontaking_4 THEN @max_spositiontaking_4 ELSE @spositiontaking_4 END
SELECT @spositiontaking_5 = CASE WHEN @spositiontaking_5 > @max_spositiontaking_5 THEN @max_spositiontaking_5 ELSE @spositiontaking_5 END
SELECT @spositiontaking_6 = CASE WHEN @spositiontaking_6 > @max_spositiontaking_6 THEN @max_spositiontaking_6 ELSE @spositiontaking_6 END
SELECT @spositiontaking_9 = CASE WHEN @spositiontaking_9 > @max_spositiontaking_9 THEN @max_spositiontaking_9 ELSE @spositiontaking_9 END
SELECT @spositiontaking_10 = CASE WHEN @spositiontaking_10 > @max_spositiontaking_10 THEN @max_spositiontaking_10 ELSE @spositiontaking_10 END

SELECT @v2spositiontaking_1 = CASE WHEN @v2spositiontaking_1 > @max_v2spositiontaking_1 THEN @max_v2spositiontaking_1 ELSE @v2spositiontaking_1 END
SELECT @v2spositiontaking_2 = CASE WHEN @v2spositiontaking_2 > @max_v2spositiontaking_2 THEN @max_v2spositiontaking_2 ELSE @v2spositiontaking_2 END
SELECT @v2spositiontaking_3 = CASE WHEN @v2spositiontaking_3 > @max_v2spositiontaking_3 THEN @max_v2spositiontaking_3 ELSE @v2spositiontaking_3 END
SELECT @v2spositiontaking_7 = CASE WHEN @v2spositiontaking_7 > @max_v2spositiontaking_7 THEN @max_v2spositiontaking_7 ELSE @v2spositiontaking_7 END
SELECT @v2spositiontaking_8 = CASE WHEN @v2spositiontaking_8 > @max_v2spositiontaking_8 THEN @max_v2spositiontaking_8 ELSE @v2spositiontaking_8 END
SELECT @v2spositiontaking_9 = CASE WHEN @v2spositiontaking_9 > @max_v2spositiontaking_9 THEN @max_v2spositiontaking_9 ELSE @v2spositiontaking_9 END
SELECT @v2spositiontaking_20 = CASE WHEN @v2spositiontaking_20 > @max_v2spositiontaking_20 THEN @max_v2spositiontaking_20 ELSE @v2spositiontaking_20 END

SELECT @v3spositiontaking_1 = CASE WHEN @v3spositiontaking_1 > @max_v3spositiontaking_1 THEN @max_v3spositiontaking_1 ELSE @v3spositiontaking_1 END
SELECT @v3spositiontaking_2 = CASE WHEN @v3spositiontaking_2 > @max_v3spositiontaking_2 THEN @max_v3spositiontaking_2 ELSE @v3spositiontaking_2 END
SELECT @v3spositiontaking_3 = CASE WHEN @v3spositiontaking_3 > @max_v3spositiontaking_3 THEN @max_v3spositiontaking_3 ELSE @v3spositiontaking_3 END
SELECT @v3spositiontaking_20 = CASE WHEN @v3spositiontaking_20 > @max_v3spositiontaking_20 THEN @max_v3spositiontaking_20 ELSE @v3spositiontaking_20 END

SELECT @v5spositiontaking_1 = CASE WHEN @v5spositiontaking_1 > @max_v5spositiontaking_1 THEN @max_v5spositiontaking_1 ELSE @v5spositiontaking_1 END
SELECT @v5spositiontaking_2 = CASE WHEN @v5spositiontaking_2 > @max_v5spositiontaking_2 THEN @max_v5spositiontaking_2 ELSE @v5spositiontaking_2 END
SELECT @v5spositiontaking_3 = CASE WHEN @v5spositiontaking_3 > @max_v5spositiontaking_3 THEN @max_v5spositiontaking_3 ELSE @v5spositiontaking_3 END
SELECT @v5spositiontaking_20 = CASE WHEN @v5spositiontaking_20 > @max_v5spositiontaking_20 THEN @max_v5spositiontaking_20 ELSE @v5spositiontaking_20 END

SELECT @v8spositiontaking_1 = CASE WHEN @v8spositiontaking_1 > @max_v8spositiontaking_1 THEN @max_v8spositiontaking_1 ELSE @v8spositiontaking_1 END
SELECT @v8spositiontaking_3 = CASE WHEN @v8spositiontaking_3 > @max_v8spositiontaking_3 THEN @max_v8spositiontaking_3 ELSE @v8spositiontaking_3 END
SELECT @v8spositiontaking_20 = CASE WHEN @v8spositiontaking_20 > @max_v8spositiontaking_20 THEN @max_v8spositiontaking_20 ELSE @v8spositiontaking_20 END

SELECT @v10spositiontaking_1 = CASE WHEN @v10spositiontaking_1 > @max_v10spositiontaking_1 THEN @max_v10spositiontaking_1 ELSE @v10spositiontaking_1 END
SELECT @v10spositiontaking_2 = CASE WHEN @v10spositiontaking_2 > @max_v10spositiontaking_2 THEN @max_v10spositiontaking_2 ELSE @v10spositiontaking_2 END
SELECT @v10spositiontaking_3 = CASE WHEN @v10spositiontaking_3 > @max_v10spositiontaking_3 THEN @max_v10spositiontaking_3 ELSE @v10spositiontaking_3 END
SELECT @v10spositiontaking_20 = CASE WHEN @v10spositiontaking_20 > @max_v10spositiontaking_20 THEN @max_v10spositiontaking_20 ELSE @v10spositiontaking_20 END

SELECT @v11spositiontaking_1 = CASE WHEN @v11spositiontaking_1 > @max_v11spositiontaking_1 THEN @max_v11spositiontaking_1 ELSE @v11spositiontaking_1 END
SELECT @v11spositiontaking_20 = CASE WHEN @v11spositiontaking_20 > @max_v11spositiontaking_20 THEN @max_v11spositiontaking_20 ELSE @v11spositiontaking_20 END

SELECT @v99spositiontaking_1 = CASE WHEN @v99spositiontaking_1 > @max_v99spositiontaking_1 THEN @max_v99spositiontaking_1 ELSE @v99spositiontaking_1 END
SELECT @v99spositiontaking_2 = CASE WHEN @v99spositiontaking_2 > @max_v99spositiontaking_2 THEN @max_v99spositiontaking_2 ELSE @v99spositiontaking_2 END
SELECT @v99spositiontaking_3 = CASE WHEN @v99spositiontaking_3 > @max_v99spositiontaking_3 THEN @max_v99spositiontaking_3 ELSE @v99spositiontaking_3 END
SELECT @v99spositiontaking_20 = CASE WHEN @v99spositiontaking_20 > @max_v99spositiontaking_20 THEN @max_v99spositiontaking_20 ELSE @v99spositiontaking_20 END

--don't update m1,s1 for member under agent was set im2=1
UPDATE cs WITH (ROWLOCK, UPDLOCK)
SET
	mpositiontaking = CASE cs.sporttype 	WHEN 1 THEN CASE cs.bettype WHEN 1 THEN @mpositiontaking_1 WHEN 2 THEN @mpositiontaking_2 WHEN 3 THEN @mpositiontaking_3 WHEN 4 THEN @mpositiontaking_4 WHEN 5 THEN @mpositiontaking_5 WHEN 6 THEN @mpositiontaking_6 WHEN 7 THEN @mpositiontaking_7 WHEN 8 THEN @mpositiontaking_8 WHEN 9 THEN @mpositiontaking_9 WHEN 10 THEN @mpositiontaking_10 ELSE 0 END
					WHEN 2 THEN CASE cs.bettype WHEN 1 THEN @v2mpositiontaking_1 WHEN 2 THEN @v2mpositiontaking_2 WHEN 3 THEN @v2mpositiontaking_3 WHEN 7 THEN @v2mpositiontaking_7 WHEN 8 THEN @v2mpositiontaking_8 WHEN 9 THEN @v2mpositiontaking_9 WHEN 20 THEN @v2mpositiontaking_20 ELSE 0 END
					WHEN 3 THEN CASE cs.bettype WHEN 1 THEN @v3mpositiontaking_1 WHEN 2 THEN @v3mpositiontaking_2 WHEN 3 THEN @v3mpositiontaking_3 WHEN 20 THEN @v3mpositiontaking_20 ELSE 0 END
					WHEN 5 THEN CASE cs.bettype WHEN 1 THEN @v5mpositiontaking_1 WHEN 2 THEN @v5mpositiontaking_2 WHEN 3 THEN @v5mpositiontaking_3 WHEN 20 THEN @v5mpositiontaking_20 ELSE 0 END
					WHEN 8 THEN CASE cs.bettype WHEN 1 THEN @v8mpositiontaking_1 WHEN 3 THEN @v8mpositiontaking_3 WHEN 20 THEN @v8mpositiontaking_20 ELSE 0 END
					WHEN 10 THEN CASE cs.bettype WHEN 1 THEN @v10mpositiontaking_1 WHEN 2 THEN @v10mpositiontaking_2 WHEN 3 THEN @v10mpositiontaking_3 WHEN 20 THEN @v10mpositiontaking_20 ELSE 0 END
					WHEN 11 THEN CASE cs.bettype WHEN 1 THEN @v11mpositiontaking_1 WHEN 20 THEN @v11mpositiontaking_20 ELSE 0 END
					WHEN 99 THEN CASE cs.bettype WHEN 1 THEN @v99mpositiontaking_1 WHEN 2 THEN @v99mpositiontaking_2 WHEN 3 THEN @v99mpositiontaking_3 WHEN 20 THEN @v99mpositiontaking_20 ELSE 0 END
					ELSE cs.mpositiontaking END,
	spositiontaking =  CASE cs.sporttype WHEN 1 THEN CASE cs.bettype WHEN 1 THEN @spositiontaking_1 WHEN 2 THEN @spositiontaking_2 WHEN 3 THEN @spositiontaking_3 WHEN 4 THEN @spositiontaking_4 WHEN 5 THEN @spositiontaking_5 WHEN 6 THEN @spositiontaking_6 WHEN 7 THEN @spositiontaking_7 WHEN 8 THEN @spositiontaking_8 WHEN 9 THEN @spositiontaking_9 WHEN 10 THEN @spositiontaking_10 ELSE 0 END
					WHEN 2 THEN CASE cs.bettype WHEN 1 THEN @v2spositiontaking_1 WHEN 2 THEN @v2spositiontaking_2 WHEN 3 THEN @v2spositiontaking_3 WHEN 7 THEN @v2spositiontaking_7 WHEN 8 THEN @v2spositiontaking_8 WHEN 9 THEN @v2spositiontaking_9 WHEN 20 THEN @v2spositiontaking_20 ELSE 0 END
					WHEN 3 THEN CASE cs.bettype WHEN 1 THEN @v3spositiontaking_1 WHEN 2 THEN @v3spositiontaking_2 WHEN 3 THEN @v3spositiontaking_3 WHEN 20 THEN @v3spositiontaking_20 ELSE 0 END
					WHEN 5 THEN CASE cs.bettype WHEN 1 THEN @v5spositiontaking_1 WHEN 2 THEN @v5spositiontaking_2 WHEN 3 THEN @v5spositiontaking_3 WHEN 20 THEN @v5spositiontaking_20 ELSE 0 END
					WHEN 8 THEN CASE cs.bettype WHEN 1 THEN @v8spositiontaking_1 WHEN 3 THEN @v8spositiontaking_3 WHEN 20 THEN @v8spositiontaking_20 ELSE 0 END
					WHEN 10 THEN CASE cs.bettype WHEN 1 THEN @v10spositiontaking_1 WHEN 2 THEN @v10spositiontaking_2 WHEN 3 THEN @v10spositiontaking_3 WHEN 20 THEN @v10spositiontaking_20 ELSE 0 END
					WHEN 11 THEN CASE cs.bettype WHEN 1 THEN @v11spositiontaking_1 WHEN 20 THEN @v11spositiontaking_20 ELSE 0 END
					WHEN 99 THEN CASE cs.bettype WHEN 1 THEN @v99spositiontaking_1 WHEN 2 THEN @v99spositiontaking_2 WHEN 3 THEN @v99spositiontaking_3 WHEN 20 THEN @v99spositiontaking_20 ELSE 0 END
					ELSE cs.spositiontaking END
FROM Custsetting cs INNER JOIN custinfo c WITH(NOLOCK) ON cs.custid = c.custid
	INNER JOIN Custsetting acs WITH(NOLOCK) ON acs.custid = c.recommend AND cs.sporttype = acs.sporttype AND cs.bettype = acs.bettype 
WHERE c.custid=@custid AND c.roleid = 1 AND acs.isautompositiontaking = 0 

--don't update m1,s1 for member under agent was set im2=1(live)
UPDATE cs WITH (ROWLOCK, UPDLOCK)
SET
	mlivepositiontaking = CASE cs.sporttype 	WHEN 1 THEN CASE cs.bettype WHEN 1 THEN @mlivepositiontaking_1 WHEN 3 THEN @mlivepositiontaking_3 WHEN 7 THEN @mlivepositiontaking_7 WHEN 8 THEN @mlivepositiontaking_8 ELSE cs.mlivepositiontaking END ELSE cs.mlivepositiontaking END,
	slivepositiontaking = CASE cs.sporttype 	WHEN 1 THEN CASE cs.bettype WHEN 1 THEN @slivepositiontaking_1 WHEN 3 THEN @slivepositiontaking_3 WHEN 7 THEN @slivepositiontaking_7 WHEN 8 THEN @slivepositiontaking_8 ELSE cs.slivepositiontaking END ELSE cs.slivepositiontaking END
FROM Custsetting cs INNER JOIN custinfo c WITH(NOLOCK) ON cs.custid = c.custid
	INNER JOIN Custsetting acs WITH(NOLOCK) ON acs.custid = c.recommend AND cs.sporttype = acs.sporttype AND cs.bettype = acs.bettype 
WHERE c.custid=@custid AND c.roleid = 1 AND acs.isautolivempositiontaking = 0 
print @ErrCode_Cur
--Update auto PT
SELECT @ErrCode_Cur =0 , @ErrMsg_Cur =''
EXEC dbo.Acc_CustomerUpdMember_AutoMPositiontaking 
	@custid = @custid,
	@auto_mpositiontaking_mem_1 = @auto_mpositiontaking_mem_1,
	@auto_mpositiontaking_mem_2 = @auto_mpositiontaking_mem_2,
	@auto_mpositiontaking_mem_3 = @auto_mpositiontaking_mem_3,
	@auto_mpositiontaking_mem_4 = @auto_mpositiontaking_mem_4,
	@auto_mpositiontaking_mem_5 = @auto_mpositiontaking_mem_5,
	@auto_mpositiontaking_mem_6 = @auto_mpositiontaking_mem_6,
	@auto_mpositiontaking_mem_7 = @auto_mpositiontaking_mem_7,
	@auto_mpositiontaking_mem_8 = @auto_mpositiontaking_mem_8,
	@auto_mpositiontaking_mem_9 = @auto_mpositiontaking_mem_9,
	@auto_mpositiontaking_mem_10 = @auto_mpositiontaking_mem_10,
	@auto_mlivepositiontaking_mem_1 = @auto_mlivepositiontaking_mem_1,
	@auto_mlivepositiontaking_mem_3 = @auto_mlivepositiontaking_mem_3,
	@auto_mlivepositiontaking_mem_7 = @auto_mlivepositiontaking_mem_7,
	@auto_mlivepositiontaking_mem_8 = @auto_mlivepositiontaking_mem_8,
	@auto_v2mpositiontaking_mem_1 = @auto_v2mpositiontaking_mem_1,
	@auto_v2mpositiontaking_mem_2 = @auto_v2mpositiontaking_mem_2,
	@auto_v2mpositiontaking_mem_3 = @auto_v2mpositiontaking_mem_3,
	@auto_v2mpositiontaking_mem_7 = @auto_v2mpositiontaking_mem_7,
	@auto_v2mpositiontaking_mem_8 = @auto_v2mpositiontaking_mem_8,
	@auto_v2mpositiontaking_mem_9 = @auto_v2mpositiontaking_mem_9,
	@auto_v2mpositiontaking_mem_20 = @auto_v2mpositiontaking_mem_20,
	@auto_v3mpositiontaking_mem_1 = @auto_v3mpositiontaking_mem_1,
	@auto_v3mpositiontaking_mem_2 = @auto_v3mpositiontaking_mem_2,
	@auto_v3mpositiontaking_mem_3 = @auto_v3mpositiontaking_mem_3,
	@auto_v3mpositiontaking_mem_20 = @auto_v3mpositiontaking_mem_20,
	@auto_v5mpositiontaking_mem_1 = @auto_v5mpositiontaking_mem_1,
	@auto_v5mpositiontaking_mem_2 = @auto_v5mpositiontaking_mem_2,
	@auto_v5mpositiontaking_mem_3 = @auto_v5mpositiontaking_mem_3,
	@auto_v5mpositiontaking_mem_20 = @auto_v5mpositiontaking_mem_20,
	@auto_v8mpositiontaking_mem_1 = @auto_v8mpositiontaking_mem_1,
	@auto_v8mpositiontaking_mem_3 = @auto_v8mpositiontaking_mem_3,
	@auto_v8mpositiontaking_mem_20 = @auto_v8mpositiontaking_mem_20,
	@auto_v10mpositiontaking_mem_1 = @auto_v10mpositiontaking_mem_1,
	@auto_v10mpositiontaking_mem_2 = @auto_v10mpositiontaking_mem_2,
	@auto_v10mpositiontaking_mem_3 = @auto_v10mpositiontaking_mem_3,
	@auto_v10mpositiontaking_mem_20 = @auto_v10mpositiontaking_mem_20,
	@auto_v11mpositiontaking_mem_1 = @auto_v11mpositiontaking_mem_1,
	@auto_v11mpositiontaking_mem_20 = @auto_v11mpositiontaking_mem_20,
	@auto_v99mpositiontaking_mem_1 = @auto_v99mpositiontaking_mem_1,
	@auto_v99mpositiontaking_mem_2 = @auto_v99mpositiontaking_mem_2,
	@auto_v99mpositiontaking_mem_3 = @auto_v99mpositiontaking_mem_3,
	@auto_v99mpositiontaking_mem_20 = @auto_v99mpositiontaking_mem_20,
	@isauto_mpositiontaking_mem_1 = @isauto_mpositiontaking_mem_1,
	@isauto_mpositiontaking_mem_2 = @isauto_mpositiontaking_mem_2,
	@isauto_mpositiontaking_mem_3 = @isauto_mpositiontaking_mem_3,
	@isauto_mpositiontaking_mem_4 = @isauto_mpositiontaking_mem_4,
	@isauto_mpositiontaking_mem_5 = @isauto_mpositiontaking_mem_5,
	@isauto_mpositiontaking_mem_6 = @isauto_mpositiontaking_mem_6,
	@isauto_mpositiontaking_mem_7 = @isauto_mpositiontaking_mem_7,
	@isauto_mpositiontaking_mem_8 = @isauto_mpositiontaking_mem_8,
	@isauto_mpositiontaking_mem_9 = @isauto_mpositiontaking_mem_9,
	@isauto_mpositiontaking_mem_10 = @isauto_mpositiontaking_mem_10,
	@isauto_mlivepositiontaking_mem_1 = @isauto_mlivepositiontaking_mem_1,
	@isauto_mlivepositiontaking_mem_3 = @isauto_mlivepositiontaking_mem_3,
	@isauto_mlivepositiontaking_mem_7 = @isauto_mlivepositiontaking_mem_7,
	@isauto_mlivepositiontaking_mem_8 = @isauto_mlivepositiontaking_mem_8,
	@isauto_v2mpositiontaking_mem_1 = @isauto_v2mpositiontaking_mem_1,
	@isauto_v2mpositiontaking_mem_2 = @isauto_v2mpositiontaking_mem_2,
	@isauto_v2mpositiontaking_mem_3 = @isauto_v2mpositiontaking_mem_3,
	@isauto_v2mpositiontaking_mem_7 = @isauto_v2mpositiontaking_mem_7,
	@isauto_v2mpositiontaking_mem_8 = @isauto_v2mpositiontaking_mem_8,
	@isauto_v2mpositiontaking_mem_9 = @isauto_v2mpositiontaking_mem_9,
	@isauto_v2mpositiontaking_mem_20 = @isauto_v2mpositiontaking_mem_20,
	@isauto_v3mpositiontaking_mem_1 = @isauto_v3mpositiontaking_mem_1,
	@isauto_v3mpositiontaking_mem_2 = @isauto_v3mpositiontaking_mem_2,
	@isauto_v3mpositiontaking_mem_3 = @isauto_v3mpositiontaking_mem_3,
	@isauto_v3mpositiontaking_mem_20 = @isauto_v3mpositiontaking_mem_20,
	@isauto_v5mpositiontaking_mem_1 = @isauto_v5mpositiontaking_mem_1,
	@isauto_v5mpositiontaking_mem_2 = @isauto_v5mpositiontaking_mem_2,
	@isauto_v5mpositiontaking_mem_3 = @isauto_v5mpositiontaking_mem_3,
	@isauto_v5mpositiontaking_mem_20 = @isauto_v5mpositiontaking_mem_20,
	@isauto_v8mpositiontaking_mem_1 = @isauto_v8mpositiontaking_mem_1,
	@isauto_v8mpositiontaking_mem_3 = @isauto_v8mpositiontaking_mem_3,
	@isauto_v8mpositiontaking_mem_20 = @isauto_v8mpositiontaking_mem_20,
	@isauto_v10mpositiontaking_mem_1 = @isauto_v10mpositiontaking_mem_1,
	@isauto_v10mpositiontaking_mem_2 = @isauto_v10mpositiontaking_mem_2,
	@isauto_v10mpositiontaking_mem_3 = @isauto_v10mpositiontaking_mem_3,
	@isauto_v10mpositiontaking_mem_20 = @isauto_v10mpositiontaking_mem_20,
	@isauto_v11mpositiontaking_mem_1 = @isauto_v11mpositiontaking_mem_1,
	@isauto_v11mpositiontaking_mem_20 = @isauto_v11mpositiontaking_mem_20,
	@isauto_v99mpositiontaking_mem_1 = @isauto_v99mpositiontaking_mem_1,
	@isauto_v99mpositiontaking_mem_2 = @isauto_v99mpositiontaking_mem_2,
	@isauto_v99mpositiontaking_mem_3 = @isauto_v99mpositiontaking_mem_3,
	@isauto_v99mpositiontaking_mem_20 = @isauto_v99mpositiontaking_mem_20,
	@ErrCode = @ErrCode_cur OUTPUT,
	@ErrMsg = @ErrMsg_cur OUTPUT,
	@language = @language,
	@userid = @userid

IF @ErrCode_cur <> 0
BEGIN
	SELECT @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
	 	   @ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	Return
END
ELSE
BEGIN
	
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
END
		
EXEC dbo.Acc_CustomerUpdMember_MinMaxPositiontaking 
	@custid = @custid, 
	@recommend = @recommend, 
	@mrecommend = @mrecommend, 
	@srecommend = @srecommend,
	@updautomaster = 0 -- ignore redundance update for auto master PT.

--Log for PT
	
SELECT @LogSPData = '<Acc_CustomerUpdMember_Master><m mpt_1="'+ coalesce(cast(@mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'mpt_2="'+ coalesce(cast(@mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'mpt_3="'+ coalesce(cast(@mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'mpt_4="'+ coalesce(cast(@mpositiontaking_4 as varchar(50)),space(1)) + '" ' +
'mpt_5="'+ coalesce(cast(@mpositiontaking_5 as varchar(50)),space(1)) + '" ' +
'mpt_6="'+ coalesce(cast(@mpositiontaking_6 as varchar(50)),space(1)) + '" ' +
'mpt_7="'+ coalesce(cast(@mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'mpt_8="'+ coalesce(cast(@mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'mpt_9="'+ coalesce(cast(@mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'mpt_10="'+ coalesce(cast(@mpositiontaking_10 as varchar(50)),space(1)) + '" ' +
'mlivept_1="'+ coalesce(cast(@mlivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'mlivept_3="'+ coalesce(cast(@mlivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'mlivept_7="'+ coalesce(cast(@mlivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'mlivept_8="'+ coalesce(cast(@mlivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'v2mpt_1="'+ coalesce(cast(@v2mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v2mpt_2="'+ coalesce(cast(@v2mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v2mpt_3="'+ coalesce(cast(@v2mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v2mpt_7="'+ coalesce(cast(@v2mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'v2mpt_8="'+ coalesce(cast(@v2mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'v2mpt_9="'+ coalesce(cast(@v2mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'v2mpt_20="'+ coalesce(cast(@v2mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v3mpt_1="'+ coalesce(cast(@v3mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v3mpt_2="'+ coalesce(cast(@v3mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v3mpt_3="'+ coalesce(cast(@v3mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v3mpt_20="'+ coalesce(cast(@v3mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v5mpt_1="'+ coalesce(cast(@v5mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v5mpt_2="'+ coalesce(cast(@v5mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v5mpt_3="'+ coalesce(cast(@v5mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v5mpt_20="'+ coalesce(cast(@v5mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v8mpt_1="'+ coalesce(cast(@v8mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v8mpt_3="'+ coalesce(cast(@v8mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v8mpt_20="'+ coalesce(cast(@v8mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v10mpt_1="'+ coalesce(cast(@v10mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v10mpt_2="'+ coalesce(cast(@v10mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v10mpt_3="'+ coalesce(cast(@v10mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v10mpt_20="'+ coalesce(cast(@v10mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v11mpt_1="'+ coalesce(cast(@v11mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v11mpt_20="'+ coalesce(cast(@v11mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v99mpt_1="'+ coalesce(cast(@v99mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v99mpt_2="'+ coalesce(cast(@v99mpositiontaking_2 as varchar(50)),space(1))  + '" ' +
'v99mpt_3="'+ coalesce(cast(@v99mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v99mpt_20="'+ coalesce(cast(@v99mpositiontaking_20 as varchar(50)),space(1)) + '" />' +

'<iam isa_mpt_1="'+ coalesce(cast(@isauto_mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_mpt_2="'+ coalesce(cast(@isauto_mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_mpt_3="'+ coalesce(cast(@isauto_mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_mpt_4="'+ coalesce(cast(@isauto_mpositiontaking_4 as varchar(50)),space(1)) + '" ' +
'isa_mpt_5="'+ coalesce(cast(@isauto_mpositiontaking_5 as varchar(50)),space(1)) + '" ' +
'isa_mpt_6="'+ coalesce(cast(@isauto_mpositiontaking_6 as varchar(50)),space(1)) + '" ' +
'isa_mpt_7="'+ coalesce(cast(@isauto_mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_mpt_8="'+ coalesce(cast(@isauto_mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_mpt_9="'+ coalesce(cast(@isauto_mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_mpt_10="'+ coalesce(cast(@isauto_mpositiontaking_10 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_1="'+ coalesce(cast(@isauto_mlivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_3="'+ coalesce(cast(@isauto_mlivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_7="'+ coalesce(cast(@isauto_mlivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_8="'+ coalesce(cast(@isauto_mlivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'isa_v2mpt_1="'+ coalesce(cast(@isauto_v2mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_2="'+ coalesce(cast(@isauto_v2mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_3="'+ coalesce(cast(@isauto_v2mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_7="'+ coalesce(cast(@isauto_v2mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_8="'+ coalesce(cast(@isauto_v2mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_9="'+ coalesce(cast(@isauto_v2mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_20="'+ coalesce(cast(@isauto_v2mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v3mpt_1="'+ coalesce(cast(@isauto_v3mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_2="'+ coalesce(cast(@isauto_v3mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_3="'+ coalesce(cast(@isauto_v3mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_20="'+ coalesce(cast(@isauto_v3mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v5mpt_1="'+ coalesce(cast(@isauto_v5mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_2="'+ coalesce(cast(@isauto_v5mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_3="'+ coalesce(cast(@isauto_v5mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_20="'+ coalesce(cast(@isauto_v5mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v8mpt_1="'+ coalesce(cast(@isauto_v8mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v8mpt_3="'+ coalesce(cast(@isauto_v8mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v8mpt_20="'+ coalesce(cast(@isauto_v8mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v10mpt_1="'+ coalesce(cast(@isauto_v10mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_2="'+ coalesce(cast(@isauto_v10mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_3="'+ coalesce(cast(@isauto_v10mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_20="'+ coalesce(cast(@isauto_v10mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v11mpt_1="'+ coalesce(cast(@isauto_v11mpositiontaking_1 as varchar(50)),space(1))  + '" ' +
'isa_v11mpt_20="'+ coalesce(cast(@isauto_v11mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v99mpt_1="'+ coalesce(cast(@isauto_v99mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_2="'+ coalesce(cast(@isauto_v99mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_3="'+ coalesce(cast(@isauto_v99mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_20="'+ coalesce(cast(@isauto_v99mpositiontaking_20 as varchar(50)),space(1))+ '" />' +

'<iame isa_mpt_mem_1="'+ coalesce(cast(@isauto_mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_2="'+ coalesce(cast(@isauto_mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_3="'+ coalesce(cast(@isauto_mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_4="'+ coalesce(cast(@isauto_mpositiontaking_mem_4 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_5="'+ coalesce(cast(@isauto_mpositiontaking_mem_5 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_6="'+ coalesce(cast(@isauto_mpositiontaking_mem_6 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_7="'+ coalesce(cast(@isauto_mpositiontaking_mem_7 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_8="'+ coalesce(cast(@isauto_mpositiontaking_mem_8 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_9="'+ coalesce(cast(@isauto_mpositiontaking_mem_9 as varchar(50)),space(1)) + '" ' +
'isa_mpt_mem_10="'+ coalesce(cast(@isauto_mpositiontaking_mem_10 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_mem_1="'+ coalesce(cast(@isauto_mlivepositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_mem_3="'+ coalesce(cast(@isauto_mlivepositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_mem_7="'+ coalesce(cast(@isauto_mlivepositiontaking_mem_7 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_mem_8="'+ coalesce(cast(@isauto_mlivepositiontaking_mem_8 as varchar(50)),space(1)) + '" ' +

'isa_v2mpt_mem_1="'+ coalesce(cast(@isauto_v2mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_mem_2="'+ coalesce(cast(@isauto_v2mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_mem_3="'+ coalesce(cast(@isauto_v2mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_mem_7="'+ coalesce(cast(@isauto_v2mpositiontaking_mem_7 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_mem_8="'+ coalesce(cast(@isauto_v2mpositiontaking_mem_8 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_mem_9="'+ coalesce(cast(@isauto_v2mpositiontaking_mem_9 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_mem_20="'+ coalesce(cast(@isauto_v2mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'isa_v3mpt_mem_1="'+ coalesce(cast(@isauto_v3mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_mem_2="'+ coalesce(cast(@isauto_v3mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_mem_3="'+ coalesce(cast(@isauto_v3mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_mem_20="'+ coalesce(cast(@isauto_v3mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'isa_v5mpt_mem_1="'+ coalesce(cast(@isauto_v5mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_mem_2="'+ coalesce(cast(@isauto_v5mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_mem_3="'+ coalesce(cast(@isauto_v5mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_mem_20="'+ coalesce(cast(@isauto_v5mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'isa_v8mpt_mem_1="'+ coalesce(cast(@isauto_v8mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_v8mpt_mem_3="'+ coalesce(cast(@isauto_v8mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_v8mpt_mem_20="'+ coalesce(cast(@isauto_v8mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'isa_v10mpt_mem_1="'+ coalesce(cast(@isauto_v10mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_mem_2="'+ coalesce(cast(@isauto_v10mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_mem_3="'+ coalesce(cast(@isauto_v10mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_mem_20="'+ coalesce(cast(@isauto_v10mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'isa_v11mpt_mem_1="'+ coalesce(cast(@isauto_v11mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_v11mpt_mem_20="'+ coalesce(cast(@isauto_v11mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'isa_v99mpt_mem_1="'+ coalesce(cast(@isauto_v99mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_mem_2="'+ coalesce(cast(@isauto_v99mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_mem_3="'+ coalesce(cast(@isauto_v99mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_mem_20="'+ coalesce(cast(@isauto_v99mpositiontaking_mem_20 as varchar(50)),space(1)) + '" />' +

'<aume a_mpt_mem_1="'+ coalesce(cast(@auto_mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_2="'+ coalesce(cast(@auto_mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_3="'+ coalesce(cast(@auto_mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_4="'+ coalesce(cast(@auto_mpositiontaking_mem_4 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_5="'+ coalesce(cast(@auto_mpositiontaking_mem_5 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_6="'+ coalesce(cast(@auto_mpositiontaking_mem_6 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_7="'+ coalesce(cast(@auto_mpositiontaking_mem_7 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_8="'+ coalesce(cast(@auto_mpositiontaking_mem_8 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_9="'+ coalesce(cast(@auto_mpositiontaking_mem_9 as varchar(50)),space(1)) + '" ' +
'a_mpt_mem_10="'+ coalesce(cast(@auto_mpositiontaking_mem_10 as varchar(50)),space(1)) + '" ' +
'a_mlivept_mem_1="'+ coalesce(cast(@auto_mlivepositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_mlivept_mem_3="'+ coalesce(cast(@auto_mlivepositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_mlivept_mem_7="'+ coalesce(cast(@auto_mlivepositiontaking_mem_7 as varchar(50)),space(1)) + '" ' +
'a_mlivept_mem_8="'+ coalesce(cast(@auto_mlivepositiontaking_mem_8 as varchar(50)),space(1)) + '" ' +

'a_v2mpt_mem_1="'+ coalesce(cast(@auto_v2mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_mem_2="'+ coalesce(cast(@auto_v2mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_mem_3="'+ coalesce(cast(@auto_v2mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_mem_7="'+ coalesce(cast(@auto_v2mpositiontaking_mem_7 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_mem_8="'+ coalesce(cast(@auto_v2mpositiontaking_mem_8 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_mem_9="'+ coalesce(cast(@auto_v2mpositiontaking_mem_9 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_mem_20="'+ coalesce(cast(@auto_v2mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'a_v3mpt_mem_1="'+ coalesce(cast(@auto_v3mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_v3mpt_mem_2="'+ coalesce(cast(@auto_v3mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'a_v3mpt_mem_3="'+ coalesce(cast(@auto_v3mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_v3mpt_mem_20="'+ coalesce(cast(@auto_v3mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'a_v5mpt_mem_1="'+ coalesce(cast(@auto_v5mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_v5mpt_mem_2="'+ coalesce(cast(@auto_v5mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'a_v5mpt_mem_3="'+ coalesce(cast(@auto_v5mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_v5mpt_mem_20="'+ coalesce(cast(@auto_v5mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'a_v8mpt_mem_1="'+ coalesce(cast(@auto_v8mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_v8mpt_mem_3="'+ coalesce(cast(@auto_v8mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_v8mpt_mem_20="'+ coalesce(cast(@auto_v8mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'a_v10mpt_mem_1="'+ coalesce(cast(@auto_v10mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_v10mpt_mem_2="'+ coalesce(cast(@auto_v10mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'a_v10mpt_mem_3="'+ coalesce(cast(@auto_v10mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_v10mpt_mem_20="'+ coalesce(cast(@auto_v10mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'a_v11mpt_mem_1="'+ coalesce(cast(@auto_v11mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_v11mpt_mem_20="'+ coalesce(cast(@auto_v11mpositiontaking_mem_20 as varchar(50)),space(1)) + '" ' +

'a_v99mpt_mem_1="'+ coalesce(cast(@auto_v99mpositiontaking_mem_1 as varchar(50)),space(1)) + '" ' +
'a_v99mpt_mem_2="'+ coalesce(cast(@auto_v99mpositiontaking_mem_2 as varchar(50)),space(1)) + '" ' +
'a_v99mpt_mem_3="'+ coalesce(cast(@auto_v99mpositiontaking_mem_3 as varchar(50)),space(1)) + '" ' +
'a_v99mpt_mem_20="'+ coalesce(cast(@auto_v99mpositiontaking_mem_20 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMember_Master>'


--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 407,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Master] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Master] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_Master] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMember_Master] TO [vnteam]