ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_PositionTaking]
	@custid INT,--memberid		
		
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
	
	@UpdateMultiple BIT = 0,
	@UpdatePositiontaking BIT = 1,	
	@UpdatePositiontakingv2 BIT = 1,
	@UpdatePositiontakingv3 BIT = 1,
	@UpdatePositiontakingv5 BIT = 1,
	@UpdatePositiontakingv8 BIT = 1,
	@UpdatePositiontakingv10 BIT = 1,
	@UpdatePositiontakingv11 BIT = 1,

	@UpdatePositiontakingv99 BIT = 1,
	
	@UserID INT,	
	
	@IP varchar(15)='',	
	@Language VARCHAR(2)= 'E',	
	@SubAccID INT = 0, --Sub-AccountID	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080516@Thien
Task : Update Member's Position Taking
DB: DB02.bodb02
Original:

Revisions:
   	- 20080810@Thien: This SP is used by Acc_CustomerUpdMoveMember also
    - 20081023@Phuc: Add new sporttype 201, bettype 3, hard code copy min/max/maxperbet/PT for 201 from 2 sporttype 
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090630@Phuc: auto master PT on member level.
					Write log subaccname instead of subaccid.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON


DECLARE 	
	@Recommend INT,	
	@MRecommend INT,
	@SRecommend INT,
	@UserName varchar(40),
	@ErrAcc varchar(4000), @ErrType varchar(4000),
	--m1
	@mpositiontaking_1 SMALLMONEY,
	@mpositiontaking_2 SMALLMONEY,
	@mpositiontaking_3 SMALLMONEY,
	@mpositiontaking_4 SMALLMONEY,
	@mpositiontaking_5 SMALLMONEY,
	@mpositiontaking_6 SMALLMONEY,
	@mpositiontaking_7 SMALLMONEY,
	@mpositiontaking_8 SMALLMONEY,
	@mpositiontaking_9 SMALLMONEY,
	@mpositiontaking_10 SMALLMONEY,
	
	@mlivepositiontaking_1 SMALLMONEY,
	@mlivepositiontaking_3 SMALLMONEY,
	@mlivepositiontaking_7 SMALLMONEY,
	@mlivepositiontaking_8 SMALLMONEY,
	
	@v2mpositiontaking_1 SMALLMONEY,
	@v2mpositiontaking_2 SMALLMONEY,
	@v2mpositiontaking_3 SMALLMONEY,
	@v2mpositiontaking_7 SMALLMONEY,
	@v2mpositiontaking_8 SMALLMONEY,
	@v2mpositiontaking_9 SMALLMONEY,
	@v2mpositiontaking_20 SMALLMONEY,

	@v3mpositiontaking_1 SMALLMONEY,
	@v3mpositiontaking_2 SMALLMONEY,
	@v3mpositiontaking_3 SMALLMONEY,
	@v3mpositiontaking_20 SMALLMONEY,

	@v5mpositiontaking_1 SMALLMONEY,
	@v5mpositiontaking_2 SMALLMONEY,
	@v5mpositiontaking_3 SMALLMONEY,
	@v5mpositiontaking_20 SMALLMONEY,

	@v8mpositiontaking_1 SMALLMONEY,
	@v8mpositiontaking_3 SMALLMONEY,
	@v8mpositiontaking_20 SMALLMONEY,

	@v10mpositiontaking_1 SMALLMONEY,
	@v10mpositiontaking_2 SMALLMONEY,
	@v10mpositiontaking_3 SMALLMONEY,
	@v10mpositiontaking_20 SMALLMONEY,

	@v11mpositiontaking_1 SMALLMONEY,
	@v11mpositiontaking_20 SMALLMONEY,

	@v99mpositiontaking_1 SMALLMONEY,
	@v99mpositiontaking_2 SMALLMONEY,
	@v99mpositiontaking_3 SMALLMONEY,
	@v99mpositiontaking_20 SMALLMONEY,
	--m3
	@mapositiontaking_1_max SMALLMONEY,
	@mapositiontaking_2_max SMALLMONEY,
	@mapositiontaking_3_max SMALLMONEY,
	@mapositiontaking_4_max SMALLMONEY,
	@mapositiontaking_5_max SMALLMONEY,
	@mapositiontaking_6_max SMALLMONEY,
	@mapositiontaking_7_max SMALLMONEY,
	@mapositiontaking_8_max SMALLMONEY,
	@mapositiontaking_9_max SMALLMONEY,
	@mapositiontaking_10_max SMALLMONEY,
	
	@malivepositiontaking_1_max SMALLMONEY,
	@malivepositiontaking_3_max SMALLMONEY,
	@malivepositiontaking_7_max SMALLMONEY,
	@malivepositiontaking_8_max SMALLMONEY,
	
	@v2mapositiontaking_1_max SMALLMONEY,
	@v2mapositiontaking_2_max SMALLMONEY,
	@v2mapositiontaking_3_max SMALLMONEY,
	@v2mapositiontaking_7_max SMALLMONEY,
	@v2mapositiontaking_8_max SMALLMONEY,
	@v2mapositiontaking_9_max SMALLMONEY,
	@v2mapositiontaking_20_max SMALLMONEY,
	
	@v3mapositiontaking_1_max SMALLMONEY,
	@v3mapositiontaking_2_max SMALLMONEY,
	@v3mapositiontaking_3_max SMALLMONEY,
	@v3mapositiontaking_20_max SMALLMONEY,

	@v5mapositiontaking_1_max SMALLMONEY,
	@v5mapositiontaking_2_max SMALLMONEY,
	@v5mapositiontaking_3_max SMALLMONEY,
	@v5mapositiontaking_20_max SMALLMONEY,

	@v8mapositiontaking_1_max SMALLMONEY,
	@v8mapositiontaking_3_max SMALLMONEY,
	@v8mapositiontaking_20_max SMALLMONEY,

	@v10mapositiontaking_1_max SMALLMONEY,
	@v10mapositiontaking_2_max SMALLMONEY,
	@v10mapositiontaking_3_max SMALLMONEY,
	@v10mapositiontaking_20_max SMALLMONEY,

	@v11mapositiontaking_1_max SMALLMONEY,
	@v11mapositiontaking_20_max SMALLMONEY,

	@v99mapositiontaking_1_max SMALLMONEY,
	@v99mapositiontaking_2_max SMALLMONEY,
	@v99mapositiontaking_3_max SMALLMONEY,
	@v99mapositiontaking_20_max SMALLMONEY,	
	--old_a1
	@old_apositiontaking_1 SMALLMONEY,
	@old_apositiontaking_2 SMALLMONEY,
	@old_apositiontaking_3 SMALLMONEY,
	@old_apositiontaking_4 SMALLMONEY,
	@old_apositiontaking_5 SMALLMONEY,
	@old_apositiontaking_6 SMALLMONEY,
	@old_apositiontaking_7 SMALLMONEY,
	@old_apositiontaking_8 SMALLMONEY,
	@old_apositiontaking_9 SMALLMONEY,
	@old_apositiontaking_10 SMALLMONEY,
	
	@old_alivepositiontaking_1 SMALLMONEY,
	@old_alivepositiontaking_3 SMALLMONEY,
	@old_alivepositiontaking_7 SMALLMONEY,
	@old_alivepositiontaking_8 SMALLMONEY,
	
	@old_v2apositiontaking_1 SMALLMONEY,
	@old_v2apositiontaking_2 SMALLMONEY,
	@old_v2apositiontaking_3 SMALLMONEY,
	@old_v2apositiontaking_7 SMALLMONEY,
	@old_v2apositiontaking_8 SMALLMONEY,
	@old_v2apositiontaking_9 SMALLMONEY,
	@old_v2apositiontaking_20 SMALLMONEY,

	@old_v3apositiontaking_1 SMALLMONEY,
	@old_v3apositiontaking_2 SMALLMONEY,
	@old_v3apositiontaking_3 SMALLMONEY,
	@old_v3apositiontaking_20 SMALLMONEY,

	@old_v5apositiontaking_1 SMALLMONEY,
	@old_v5apositiontaking_2 SMALLMONEY,
	@old_v5apositiontaking_3 SMALLMONEY,
	@old_v5apositiontaking_20 SMALLMONEY,

	@old_v8apositiontaking_1 SMALLMONEY,
	@old_v8apositiontaking_3 SMALLMONEY,
	@old_v8apositiontaking_20 SMALLMONEY,

	@old_v10apositiontaking_1 SMALLMONEY,
	@old_v10apositiontaking_2 SMALLMONEY,
	@old_v10apositiontaking_3 SMALLMONEY,
	@old_v10apositiontaking_20 SMALLMONEY,

	@old_v11apositiontaking_1 SMALLMONEY,
	@old_v11apositiontaking_20 SMALLMONEY,

	@old_v99apositiontaking_1 SMALLMONEY,
	@old_v99apositiontaking_2 SMALLMONEY,
	@old_v99apositiontaking_3 SMALLMONEY,
	@old_v99apositiontaking_20 SMALLMONEY,	
	--s1
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

	--um2
	@auto_mpositiontaking_1 SMALLMONEY,
	@auto_mpositiontaking_2 SMALLMONEY,
	@auto_mpositiontaking_3 SMALLMONEY,
	@auto_mpositiontaking_4 SMALLMONEY,
	@auto_mpositiontaking_5 SMALLMONEY,
	@auto_mpositiontaking_6 SMALLMONEY,
	@auto_mpositiontaking_7 SMALLMONEY,
	@auto_mpositiontaking_8 SMALLMONEY,
	@auto_mpositiontaking_9 SMALLMONEY,
	@auto_mpositiontaking_10 SMALLMONEY,
	@auto_mlivepositiontaking_1 SMALLMONEY,
	@auto_mlivepositiontaking_3 SMALLMONEY,
	@auto_mlivepositiontaking_7 SMALLMONEY,
	@auto_mlivepositiontaking_8 SMALLMONEY,
	
	@auto_v2mpositiontaking_1 SMALLMONEY,
	@auto_v2mpositiontaking_2 SMALLMONEY,
	@auto_v2mpositiontaking_3 SMALLMONEY,
	@auto_v2mpositiontaking_7 SMALLMONEY,
	@auto_v2mpositiontaking_8 SMALLMONEY,
	@auto_v2mpositiontaking_9 SMALLMONEY,
	@auto_v2mpositiontaking_20 SMALLMONEY,
	
	@auto_v3mpositiontaking_1 SMALLMONEY,
	@auto_v3mpositiontaking_2 SMALLMONEY,
	@auto_v3mpositiontaking_3 SMALLMONEY,
	@auto_v3mpositiontaking_20 SMALLMONEY,

	@auto_v5mpositiontaking_1 SMALLMONEY,
	@auto_v5mpositiontaking_2 SMALLMONEY,
	@auto_v5mpositiontaking_3 SMALLMONEY,
	@auto_v5mpositiontaking_20 SMALLMONEY,

	@auto_v8mpositiontaking_1 SMALLMONEY,
	@auto_v8mpositiontaking_3 SMALLMONEY,
	@auto_v8mpositiontaking_20 SMALLMONEY,

	@auto_v10mpositiontaking_1 SMALLMONEY,
	@auto_v10mpositiontaking_2 SMALLMONEY,
	@auto_v10mpositiontaking_3 SMALLMONEY,
	@auto_v10mpositiontaking_20 SMALLMONEY,

	@auto_v11mpositiontaking_1 SMALLMONEY,
	@auto_v11mpositiontaking_20 SMALLMONEY,

	@auto_v99mpositiontaking_1 SMALLMONEY,
	@auto_v99mpositiontaking_2 SMALLMONEY,
	@auto_v99mpositiontaking_3 SMALLMONEY,
	@auto_v99mpositiontaking_20 SMALLMONEY,
	--im2
	@isauto_mpositiontaking_1 BIT,
	@isauto_mpositiontaking_2 BIT,
	@isauto_mpositiontaking_3 BIT,
	@isauto_mpositiontaking_4 BIT,
	@isauto_mpositiontaking_5 BIT,
	@isauto_mpositiontaking_6 BIT,
	@isauto_mpositiontaking_7 BIT,
	@isauto_mpositiontaking_8 BIT,
	@isauto_mpositiontaking_9 BIT,
	@isauto_mpositiontaking_10 BIT,
	
	@isauto_mlivepositiontaking_1 BIT,
	@isauto_mlivepositiontaking_3 BIT,
	@isauto_mlivepositiontaking_7 BIT,
	@isauto_mlivepositiontaking_8 BIT,
	
	@isauto_v2mpositiontaking_1 BIT,
	@isauto_v2mpositiontaking_2 BIT,
	@isauto_v2mpositiontaking_3 BIT,
	@isauto_v2mpositiontaking_7 BIT,
	@isauto_v2mpositiontaking_8 BIT,
	@isauto_v2mpositiontaking_9 BIT,
	@isauto_v2mpositiontaking_20 BIT,
	
	@isauto_v3mpositiontaking_1 BIT,
	@isauto_v3mpositiontaking_2 BIT,
	@isauto_v3mpositiontaking_3 BIT,
	@isauto_v3mpositiontaking_20 BIT,

	@isauto_v5mpositiontaking_1 BIT,
	@isauto_v5mpositiontaking_2 BIT,
	@isauto_v5mpositiontaking_3 BIT,
	@isauto_v5mpositiontaking_20 BIT,

	@isauto_v8mpositiontaking_1 BIT,
	@isauto_v8mpositiontaking_3 BIT,
	@isauto_v8mpositiontaking_20 BIT,

	@isauto_v10mpositiontaking_1 BIT,
	@isauto_v10mpositiontaking_2 BIT,
	@isauto_v10mpositiontaking_3 BIT,
	@isauto_v10mpositiontaking_20 BIT,

	@isauto_v11mpositiontaking_1 BIT,
	@isauto_v11mpositiontaking_20 BIT,

	@isauto_v99mpositiontaking_1 BIT,
	@isauto_v99mpositiontaking_2 BIT,
	@isauto_v99mpositiontaking_3 BIT,
	@isauto_v99mpositiontaking_20 BIT,
	
	--im1
	@isauto_mpositiontaking_mem_1 BIT,
	@isauto_mpositiontaking_mem_2 BIT,
	@isauto_mpositiontaking_mem_3 BIT,
	@isauto_mpositiontaking_mem_4 BIT,
	@isauto_mpositiontaking_mem_5 BIT,
	@isauto_mpositiontaking_mem_6 BIT,
	@isauto_mpositiontaking_mem_7 BIT,
	@isauto_mpositiontaking_mem_8 BIT,
	@isauto_mpositiontaking_mem_9 BIT,
	@isauto_mpositiontaking_mem_10 BIT,
	@isauto_mlivepositiontaking_mem_1 BIT,
	@isauto_mlivepositiontaking_mem_3 BIT,
	@isauto_mlivepositiontaking_mem_7 BIT,
	@isauto_mlivepositiontaking_mem_8 BIT,
	
	@isauto_v2mpositiontaking_mem_1 BIT,
	@isauto_v2mpositiontaking_mem_2 BIT,
	@isauto_v2mpositiontaking_mem_3 BIT,
	@isauto_v2mpositiontaking_mem_7 BIT,
	@isauto_v2mpositiontaking_mem_8 BIT,
	@isauto_v2mpositiontaking_mem_9 BIT,
	@isauto_v2mpositiontaking_mem_20 BIT,
	
	@isauto_v3mpositiontaking_mem_1 BIT,
	@isauto_v3mpositiontaking_mem_2 BIT,
	@isauto_v3mpositiontaking_mem_3 BIT,
	@isauto_v3mpositiontaking_mem_20 BIT,
	
	@isauto_v5mpositiontaking_mem_1 BIT,
	@isauto_v5mpositiontaking_mem_2 BIT,
	@isauto_v5mpositiontaking_mem_3 BIT,
	@isauto_v5mpositiontaking_mem_20 BIT,
	
	@isauto_v8mpositiontaking_mem_1 BIT,
	@isauto_v8mpositiontaking_mem_3 BIT,
	@isauto_v8mpositiontaking_mem_20 BIT,
	
	@isauto_v10mpositiontaking_mem_1 BIT,
	@isauto_v10mpositiontaking_mem_2 BIT,
	@isauto_v10mpositiontaking_mem_3 BIT,
	@isauto_v10mpositiontaking_mem_20 BIT,
	
	@isauto_v11mpositiontaking_mem_1 BIT,
	@isauto_v11mpositiontaking_mem_20 BIT,

	@isauto_v99mpositiontaking_mem_1 BIT,
	@isauto_v99mpositiontaking_mem_2 BIT,
	@isauto_v99mpositiontaking_mem_3 BIT,
	@isauto_v99mpositiontaking_mem_20 BIT,	

	--um1
	@auto_mpositiontaking_mem_1 SMALLMONEY,
	@auto_mpositiontaking_mem_2 SMALLMONEY,
	@auto_mpositiontaking_mem_3 SMALLMONEY,
	@auto_mpositiontaking_mem_4 SMALLMONEY,
	@auto_mpositiontaking_mem_5 SMALLMONEY,
	@auto_mpositiontaking_mem_6 SMALLMONEY,
	@auto_mpositiontaking_mem_7 SMALLMONEY,
	@auto_mpositiontaking_mem_8 SMALLMONEY,
	@auto_mpositiontaking_mem_9 SMALLMONEY,
	@auto_mpositiontaking_mem_10 SMALLMONEY,
	@auto_mlivepositiontaking_mem_1 SMALLMONEY,
	@auto_mlivepositiontaking_mem_3 SMALLMONEY,
	@auto_mlivepositiontaking_mem_7 SMALLMONEY,
	@auto_mlivepositiontaking_mem_8 SMALLMONEY,
	
	@auto_v2mpositiontaking_mem_1 SMALLMONEY,
	@auto_v2mpositiontaking_mem_2 SMALLMONEY,
	@auto_v2mpositiontaking_mem_3 SMALLMONEY,
	@auto_v2mpositiontaking_mem_7 SMALLMONEY,
	@auto_v2mpositiontaking_mem_8 SMALLMONEY,
	@auto_v2mpositiontaking_mem_9 SMALLMONEY,
	@auto_v2mpositiontaking_mem_20 SMALLMONEY,
	
	@auto_v3mpositiontaking_mem_1 SMALLMONEY,
	@auto_v3mpositiontaking_mem_2 SMALLMONEY,
	@auto_v3mpositiontaking_mem_3 SMALLMONEY,
	@auto_v3mpositiontaking_mem_20 SMALLMONEY,
	
	@auto_v5mpositiontaking_mem_1 SMALLMONEY,
	@auto_v5mpositiontaking_mem_2 SMALLMONEY,
	@auto_v5mpositiontaking_mem_3 SMALLMONEY,
	@auto_v5mpositiontaking_mem_20 SMALLMONEY,
	
	@auto_v8mpositiontaking_mem_1 SMALLMONEY,
	@auto_v8mpositiontaking_mem_3 SMALLMONEY,
	@auto_v8mpositiontaking_mem_20 SMALLMONEY,
	
	@auto_v10mpositiontaking_mem_1 SMALLMONEY,
	@auto_v10mpositiontaking_mem_2 SMALLMONEY,
	@auto_v10mpositiontaking_mem_3 SMALLMONEY,
	@auto_v10mpositiontaking_mem_20 SMALLMONEY,
	
	@auto_v11mpositiontaking_mem_1 SMALLMONEY,
	@auto_v11mpositiontaking_mem_20 SMALLMONEY,

	@auto_v99mpositiontaking_mem_1 SMALLMONEY,
	@auto_v99mpositiontaking_mem_2 SMALLMONEY,
	@auto_v99mpositiontaking_mem_3 SMALLMONEY,
	@auto_v99mpositiontaking_mem_20 SMALLMONEY
	

SELECT 	
	@Recommend = recommend,
	@MRecommend = mrecommend,
	@SRecommend = srecommend,	
	@UserName = username
FROM custinfo WITH (NOLOCK)
WHERE CustID = @CustID

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if @UpdateMultiple = 0 or @UpdatePositiontaking = 1
BEGIN
	if 
		@apositiontaking_1  <0
		or @apositiontaking_2  <0
		or @apositiontaking_3  <0
		or @apositiontaking_4  <0
		or @apositiontaking_5  <0
		or @apositiontaking_6  <0
		or @apositiontaking_7  <0
		or @apositiontaking_8  <0
		or @apositiontaking_9  <0
		or @alivepositiontaking_1  <0
		or @alivepositiontaking_3  <0
		or @alivepositiontaking_7  <0
		or @alivepositiontaking_8  <0		
		or @apositiontaking_10 <0
		or @apositiontaking_1  >0.9
		or @apositiontaking_2  >0.9
		or @apositiontaking_3  >0.9
		or @apositiontaking_4  >0.9
		or @apositiontaking_5  >0.9
		or @apositiontaking_6  >0.9
		or @apositiontaking_7  >0.9
		or @apositiontaking_8  >0.9
		or @apositiontaking_9  >0.9
		or @apositiontaking_10 >0.9
		or @alivepositiontaking_1  >0.9
		or @alivepositiontaking_3  >0.9
		or @alivepositiontaking_7  >0.9
		or @alivepositiontaking_8  >0.9		
		
	BEGIN
		select @ErrCode = 5
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Soccer).'
							when 'CS' then N'占成数不正确(于足球).'
							when 'CT' then N'佔成數不正確(於足球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาฟุตบอล).'
							when 'J' then N'Wrong position taking (for Soccer).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (축구).'
							else N'Wrong position taking (for Soccer).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 1 as sporttype, @apositiontaking_1 as apositiontaking, @alivepositiontaking_1 as alivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @apositiontaking_3 as apositiontaking, @alivepositiontaking_3 as alivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @apositiontaking_4 as apositiontaking, 0 as alivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @apositiontaking_5 as apositiontaking, 0 as alivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @apositiontaking_6 as apositiontaking, 0 as alivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @apositiontaking_7 as apositiontaking, @alivepositiontaking_7 as alivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @apositiontaking_8 as apositiontaking, @alivepositiontaking_8 as alivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @apositiontaking_9 as apositiontaking, 0 as alivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @apositiontaking_10 as apositiontaking, 0 as alivepositiontaking			
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)) or 
						((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking)))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 6
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
					select 1 as bettype, 1 as sporttype, @apositiontaking_1 as apositiontaking, @alivepositiontaking_1 as alivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @apositiontaking_3 as apositiontaking, @alivepositiontaking_3 as alivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @apositiontaking_7 as apositiontaking, @alivepositiontaking_7 as alivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @apositiontaking_8 as apositiontaking, @alivepositiontaking_8 as alivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @apositiontaking_4 as apositiontaking, 0 as alivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @apositiontaking_5 as apositiontaking, 0 as alivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @apositiontaking_6 as apositiontaking, 0 as alivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @apositiontaking_9 as apositiontaking, 0 as alivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @apositiontaking_10 as apositiontaking, 0 as alivepositiontaking
			) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 7
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
						select 1 as bettype, 1 as sporttype, @apositiontaking_1 as apositiontaking, @alivepositiontaking_1 as alivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @apositiontaking_3 as apositiontaking, @alivepositiontaking_3 as alivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @apositiontaking_7 as apositiontaking, @alivepositiontaking_7 as alivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @apositiontaking_8 as apositiontaking, @alivepositiontaking_8 as alivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @apositiontaking_4 as apositiontaking, 0 as alivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @apositiontaking_5 as apositiontaking, 0 as alivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @apositiontaking_6 as apositiontaking, 0 as alivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @apositiontaking_9 as apositiontaking, 0 as alivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @apositiontaking_10 as apositiontaking, 0 as alivepositiontaking
			) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END

--Basketball
if @UpdateMultiple = 0 or @UpdatePositiontakingv2 = 1
BEGIN
	if 
		@v2apositiontaking_1  <0
		or @v2apositiontaking_2  <0
		or @v2apositiontaking_3  <0
		or @v2apositiontaking_7  <0
		or @v2apositiontaking_8  <0
		or @v2apositiontaking_9  <0
		or @v2apositiontaking_20  <0		
	
		or @v2apositiontaking_1  >0.9
		or @v2apositiontaking_2  >0.9
		or @v2apositiontaking_3  >0.9
		or @v2apositiontaking_7  >0.9
		or @v2apositiontaking_8  >0.9
		or @v2apositiontaking_9  >0.9
		or @v2apositiontaking_20  >0.9
	
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Basketball).'
							when 'CS' then N'占成数不正确(于篮球).'
							when 'CT' then N'佔成數不正確(於籃球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Wrong position taking (for Basketball).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (농구).'
							else N'Wrong position taking (for Basketball).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 2 as sporttype, @v2apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @v2apositiontaking_7 as apositiontaking, 0 as alivepositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @v2apositiontaking_8 as apositiontaking, 0 as alivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2apositiontaking_9 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2apositiontaking_20 as apositiontaking, 0 as alivepositiontaking

		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
	--or ((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
	)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 2 as sporttype, @v2apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @v2apositiontaking_7 as apositiontaking, 0 as alivepositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @v2apositiontaking_8 as apositiontaking, 0 as alivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2apositiontaking_9 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
				 		select 1 as bettype, 2 as sporttype, @v2apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @v2apositiontaking_7 as apositiontaking, 0 as alivepositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @v2apositiontaking_8 as apositiontaking, 0 as alivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2apositiontaking_9 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END

--Football
if @UpdateMultiple = 0 or @UpdatePositiontakingv3 = 1
BEGIN
	if 
		@v3apositiontaking_1  <0
		or @v3apositiontaking_2  <0
		or @v3apositiontaking_3  <0
		or @v3apositiontaking_20  <0		
		or @v3apositiontaking_1  >0.9
		or @v3apositiontaking_2  >0.9
		or @v3apositiontaking_3  >0.9
		or @v3apositiontaking_20  >0.9
		
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Football).'
							when 'CS' then N'占成数不正确(于美式足球).'
							when 'CT' then N'佔成數不正確(於美式足球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Wrong position taking (for Football).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (풋볼).'
							else N'Wrong position taking (for Football).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 3 as sporttype, @v3apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
	--or ((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
	)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 3 as sporttype, @v3apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
				 		select 1 as bettype, 3 as sporttype, @v3apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END

--Tennis
if @UpdateMultiple = 0 or @UpdatePositiontakingv5 = 1
BEGIN
	if 
		@v5apositiontaking_1  <0
		or @v5apositiontaking_2  <0
		or @v5apositiontaking_3  <0
		or @v5apositiontaking_20  <0		
		or @v5apositiontaking_1  >0.9
		or @v5apositiontaking_2  >0.9
		or @v5apositiontaking_3  >0.9
		or @v5apositiontaking_20  >0.9
		
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Tennis).'
							when 'CS' then N'占成数不正确(于网球).'
							when 'CT' then N'佔成數不正確(於網球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Wrong position taking (for Tennis).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (테니스).'
							else N'Wrong position taking (for Tennis).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 5 as sporttype, @v5apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
	--or ((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
	)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 5 as sporttype, @v5apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
				 		select 1 as bettype, 5 as sporttype, @v5apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END

--Baseball
if @UpdateMultiple = 0 or @UpdatePositiontakingv8 = 1
BEGIN
	if 
		@v8apositiontaking_1  <0
		or @v8apositiontaking_3  <0
		or @v8apositiontaking_20  <0		
		or @v8apositiontaking_1  >0.9
		or @v8apositiontaking_3  >0.9
		or @v8apositiontaking_20  >0.9
		
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Baseball).'
							when 'CS' then N'占成数不正确(于棒球).'
							when 'CT' then N'佔成數不正確(於棒球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาเบสบอล).'
							when 'J' then N'Wrong position taking (for Baseball).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (야구).'
							else N'Wrong position taking (for Baseball).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 8 as sporttype, @v8apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
	--or ((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
	)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 8 as sporttype, @v8apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
				 	select 1 as bettype, 8 as sporttype, @v8apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END

--Golf
if @UpdateMultiple = 0 or @UpdatePositiontakingv10 = 1
BEGIN
	if 
		@v10apositiontaking_1  <0
		or @v10apositiontaking_2  <0
		or @v10apositiontaking_3  <0
		or @v10apositiontaking_20  <0		
		or @v10apositiontaking_1  >0.9
		or @v10apositiontaking_2  >0.9
		or @v10apositiontaking_3  >0.9
		or @v10apositiontaking_20  >0.9
		
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Golf).'
							when 'CS' then N'占成数不正确(于高尔夫球).'
							when 'CT' then N'佔成數不正確(於高爾夫球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬากอฟล์).'
							when 'J' then N'Wrong position taking (for Golf).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (골프).'
							else N'Wrong position taking (for Golf).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 10 as sporttype, @v10apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
	--or ((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
	)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 10 as sporttype, @v10apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
				 		select 1 as bettype, 10 as sporttype, @v10apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END

--Motorsports
if @UpdateMultiple = 0 or @UpdatePositiontakingv11 = 1
BEGIN
	if 
		@v11apositiontaking_1  <0
		or @v11apositiontaking_20  <0		
		or @v11apositiontaking_1  >0.9
		or @v11apositiontaking_20  >0.9
		
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Motorsports).'
							when 'CS' then N'占成数不正确(于赛车).'
							when 'CT' then N'佔成數不正確(於賽車).'
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สำหรับกีฬารถแข่ง).'
							when 'J' then N'Wrong position taking (for Motorsports).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (모토스포츠).'
							else N'Wrong position taking (for Motorsports).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 11 as sporttype, @v11apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
	--or ((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
	)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 11 as sporttype, @v11apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
				 		select 1 as bettype, 11 as sporttype, @v11apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END

--Other sports
if @UpdateMultiple = 0 or @UpdatePositiontakingv99 = 1
BEGIN
	if 
		@v99apositiontaking_1  <0
		or @v99apositiontaking_2  <0
		or @v99apositiontaking_3  <0
		or @v99apositiontaking_20  <0		
		or @v99apositiontaking_1  >0.9
		or @v99apositiontaking_2  >0.9
		or @v99apositiontaking_3  >0.9
		or @v99apositiontaking_20  >0.9
		
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Other sports).'
							when 'CS' then N'占成数不正确(于其他).'
							when 'CT' then N'佔成數不正確(於其他).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Wrong position taking (for Other sports).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (기타 스포츠).'
							else N'Wrong position taking (for Other sports).'
					end
		return
	END

	--check n2<=a1<=l2 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
					select 1 as bettype, 99 as sporttype, @v99apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @recommend and (( (b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking))
	--or ((b.sporttype = 1 and b.bettype in (1,3,7,8)) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
	)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a1<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 99 as sporttype, @v99apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @recommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
							else N'Wrong position taking (max set by company).<br>'+@ErrType
					end
		return
	END
	/*
	--check a1<=a2 - Phuc
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((acs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((acs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as acs with (NOLOCK) inner join 
		(
				 		select 1 as bettype, 99 as sporttype, @v99apositiontaking_1 as apositiontaking, 0 as alivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99apositiontaking_2 as apositiontaking, 0 as alivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99apositiontaking_3 as apositiontaking, 0 as alivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99apositiontaking_20 as apositiontaking, 0 as alivepositiontaking
		) as b on acs.sporttype=b.sporttype and acs.bettype = b.bettype and acs.custid = @recommend  
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking>acs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>acs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 203
		Select @ErrMsg = 	case @Language 
									when 'E' then 'Wrong agent positiontaking. <br>'+@ErrType
									when 'CS' then N'代理占成数不正确. <br>'+@ErrType
									when 'CT' then N'代理佔成數不正確. <br>'+@ErrType
									when 'TH' then N'การกำหนดตัวแทนไม่ถูกต้อง. <br>'+@ErrType
									when 'J' then N'ポジション設定が無効です。. <br>'+@ErrType
									when 'ES' then N'Posición de agente incorrecta . <br>'+@ErrType
									else N'Wrong agent positiontaking. <br>'+@ErrType
							end
		return
	END
	*/
END


--------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--m1,s1,u1,i1,um1,im1
SELECT @spositiontaking_1 = spositiontaking, @slivepositiontaking_1 = slivepositiontaking, @mpositiontaking_1 = mpositiontaking, @mlivepositiontaking_1 = mlivepositiontaking, @auto_spositiontaking_mem_1 = autopositiontaking, @auto_slivepositiontaking_mem_1 = autolivepositiontaking, @isauto_spositiontaking_mem_1 = isautopositiontaking, @isauto_slivepositiontaking_mem_1 = isautolivepositiontaking, @old_apositiontaking_1 = apositiontaking, @old_alivepositiontaking_1 = alivepositiontaking, @auto_mpositiontaking_mem_1 = autompositiontaking, @isauto_mpositiontaking_mem_1 = isautompositiontaking, @auto_mlivepositiontaking_mem_1 = autolivempositiontaking, @isauto_mlivepositiontaking_mem_1 = isautolivempositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=1
SELECT @spositiontaking_3 = spositiontaking, @slivepositiontaking_3 = slivepositiontaking, @mpositiontaking_3 = mpositiontaking, @mlivepositiontaking_3 = mlivepositiontaking, @auto_spositiontaking_mem_3 = autopositiontaking, @auto_slivepositiontaking_mem_3 = autolivepositiontaking, @isauto_spositiontaking_mem_3 = isautopositiontaking, @isauto_slivepositiontaking_mem_3 = isautolivepositiontaking, @old_apositiontaking_3 = apositiontaking, @old_alivepositiontaking_3 = alivepositiontaking, @auto_mpositiontaking_mem_3 = autompositiontaking, @isauto_mpositiontaking_mem_3 = isautompositiontaking, @auto_mlivepositiontaking_mem_3 = autolivempositiontaking, @isauto_mlivepositiontaking_mem_3 = isautolivempositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=1
SELECT @spositiontaking_7 = spositiontaking, @slivepositiontaking_7 = slivepositiontaking, @mpositiontaking_7 = mpositiontaking, @mlivepositiontaking_7 = mlivepositiontaking, @auto_spositiontaking_mem_7 = autopositiontaking, @auto_slivepositiontaking_mem_7 = autolivepositiontaking, @isauto_spositiontaking_mem_7 = isautopositiontaking, @isauto_slivepositiontaking_mem_7 = isautolivepositiontaking, @old_apositiontaking_7 = apositiontaking, @old_alivepositiontaking_7 = alivepositiontaking, @auto_mpositiontaking_mem_7 = autompositiontaking, @isauto_mpositiontaking_mem_7 = isautompositiontaking, @auto_mlivepositiontaking_mem_7 = autolivempositiontaking, @isauto_mlivepositiontaking_mem_7 = isautolivempositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=1
SELECT @spositiontaking_8 = spositiontaking, @slivepositiontaking_8 = slivepositiontaking, @mpositiontaking_8 = mpositiontaking, @mlivepositiontaking_8 = mlivepositiontaking, @auto_spositiontaking_mem_8 = autopositiontaking, @auto_slivepositiontaking_mem_8 = autolivepositiontaking, @isauto_spositiontaking_mem_8 = isautopositiontaking, @isauto_slivepositiontaking_mem_8 = isautolivepositiontaking, @old_apositiontaking_8 = apositiontaking, @old_alivepositiontaking_8 = alivepositiontaking, @auto_mpositiontaking_mem_8 = autompositiontaking, @isauto_mpositiontaking_mem_8 = isautompositiontaking, @auto_mlivepositiontaking_mem_8 = autolivempositiontaking, @isauto_mlivepositiontaking_mem_8 = isautolivempositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=1

SELECT @spositiontaking_2 = spositiontaking, @mpositiontaking_2 = mpositiontaking, @old_apositiontaking_2 = apositiontaking, @auto_spositiontaking_mem_2 = autopositiontaking, @isauto_spositiontaking_mem_2 = isautopositiontaking, @auto_mpositiontaking_mem_2 = autompositiontaking, @isauto_mpositiontaking_mem_2 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=1
SELECT @spositiontaking_4 = spositiontaking, @mpositiontaking_4 = mpositiontaking, @old_apositiontaking_4 = apositiontaking, @auto_spositiontaking_mem_4 = autopositiontaking, @isauto_spositiontaking_mem_4 = isautopositiontaking, @auto_mpositiontaking_mem_4 = autompositiontaking, @isauto_mpositiontaking_mem_4 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=4 AND sporttype=1
SELECT @spositiontaking_5 = spositiontaking, @mpositiontaking_5 = mpositiontaking, @old_apositiontaking_5 = apositiontaking, @auto_spositiontaking_mem_5 = autopositiontaking, @isauto_spositiontaking_mem_5 = isautopositiontaking, @auto_mpositiontaking_mem_5 = autompositiontaking, @isauto_mpositiontaking_mem_5 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=5 AND sporttype=1
SELECT @spositiontaking_6 = spositiontaking, @mpositiontaking_6 = mpositiontaking, @old_apositiontaking_6 = apositiontaking, @auto_spositiontaking_mem_6 = autopositiontaking, @isauto_spositiontaking_mem_6 = isautopositiontaking, @auto_mpositiontaking_mem_6 = autompositiontaking, @isauto_mpositiontaking_mem_6 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=6 AND sporttype=1
SELECT @spositiontaking_9 = spositiontaking, @mpositiontaking_9 = mpositiontaking, @old_apositiontaking_9 = apositiontaking, @auto_spositiontaking_mem_9 = autopositiontaking, @isauto_spositiontaking_mem_9 = isautopositiontaking, @auto_mpositiontaking_mem_9 = autompositiontaking, @isauto_mpositiontaking_mem_9 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=1
SELECT @spositiontaking_10 = spositiontaking, @mpositiontaking_10 = mpositiontaking, @old_apositiontaking_10 = apositiontaking, @auto_spositiontaking_mem_10 = autopositiontaking, @isauto_spositiontaking_mem_10 = isautopositiontaking, @auto_mpositiontaking_mem_10 = autompositiontaking, @isauto_mpositiontaking_mem_10 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=10 AND sporttype=1

SELECT @v2spositiontaking_1 = spositiontaking, @v2mpositiontaking_1 = mpositiontaking, @auto_v2spositiontaking_mem_1 = autopositiontaking, @isauto_v2spositiontaking_mem_1 = isautopositiontaking, @old_v2apositiontaking_1 = apositiontaking, @auto_v2mpositiontaking_mem_1 = autompositiontaking, @isauto_v2mpositiontaking_mem_1 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=2
SELECT @v2spositiontaking_2 = spositiontaking, @v2mpositiontaking_2 = mpositiontaking, @auto_v2spositiontaking_mem_2 = autopositiontaking, @isauto_v2spositiontaking_mem_2 = isautopositiontaking, @old_v2apositiontaking_2 = apositiontaking, @auto_v2mpositiontaking_mem_2 = autompositiontaking, @isauto_v2mpositiontaking_mem_2 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=2
SELECT @v2spositiontaking_3 = spositiontaking, @v2mpositiontaking_3 = mpositiontaking, @auto_v2spositiontaking_mem_3 = autopositiontaking, @isauto_v2spositiontaking_mem_3 = isautopositiontaking, @old_v2apositiontaking_3 = apositiontaking, @auto_v2mpositiontaking_mem_3 = autompositiontaking, @isauto_v2mpositiontaking_mem_3 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=2
SELECT @v2spositiontaking_7 = spositiontaking, @v2mpositiontaking_7 = mpositiontaking, @auto_v2spositiontaking_mem_7 = autopositiontaking, @isauto_v2spositiontaking_mem_7 = isautopositiontaking, @old_v2apositiontaking_7 = apositiontaking, @auto_v2mpositiontaking_mem_7 = autompositiontaking, @isauto_v2mpositiontaking_mem_7 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=2
SELECT @v2spositiontaking_8 = spositiontaking, @v2mpositiontaking_8 = mpositiontaking, @auto_v2spositiontaking_mem_8 = autopositiontaking, @isauto_v2spositiontaking_mem_8 = isautopositiontaking, @old_v2apositiontaking_8 = apositiontaking, @auto_v2mpositiontaking_mem_8 = autompositiontaking, @isauto_v2mpositiontaking_mem_8 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=2
SELECT @v2spositiontaking_9 = spositiontaking, @v2mpositiontaking_9 = mpositiontaking, @auto_v2spositiontaking_mem_9 = autopositiontaking, @isauto_v2spositiontaking_mem_9 = isautopositiontaking, @old_v2apositiontaking_9 = apositiontaking, @auto_v2mpositiontaking_mem_9 = autompositiontaking, @isauto_v2mpositiontaking_mem_9 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=2
SELECT @v2spositiontaking_20 = spositiontaking, @v2mpositiontaking_20 = mpositiontaking, @auto_v2spositiontaking_mem_20 = autopositiontaking, @isauto_v2spositiontaking_mem_20 = isautopositiontaking, @old_v2apositiontaking_20 = apositiontaking, @auto_v2mpositiontaking_mem_20 = autompositiontaking, @isauto_v2mpositiontaking_mem_20 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=2

SELECT @v3spositiontaking_1 = spositiontaking, @v3mpositiontaking_1 = mpositiontaking, @auto_v3spositiontaking_mem_1 = autopositiontaking, @isauto_v3spositiontaking_mem_1 = isautopositiontaking, @old_v3apositiontaking_1 = apositiontaking, @auto_v3mpositiontaking_mem_1 = autompositiontaking, @isauto_v3mpositiontaking_mem_1 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=3
SELECT @v3spositiontaking_2 = spositiontaking, @v3mpositiontaking_2 = mpositiontaking, @auto_v3spositiontaking_mem_2 = autopositiontaking, @isauto_v3spositiontaking_mem_2 = isautopositiontaking, @old_v3apositiontaking_2 = apositiontaking, @auto_v3mpositiontaking_mem_2 = autompositiontaking, @isauto_v3mpositiontaking_mem_2 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=3
SELECT @v3spositiontaking_3 = spositiontaking, @v3mpositiontaking_3 = mpositiontaking, @auto_v3spositiontaking_mem_3 = autopositiontaking, @isauto_v3spositiontaking_mem_3 = isautopositiontaking, @old_v3apositiontaking_3 = apositiontaking, @auto_v3mpositiontaking_mem_3 = autompositiontaking, @isauto_v3mpositiontaking_mem_3 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=3
SELECT @v3spositiontaking_20 = spositiontaking, @v3mpositiontaking_20 = mpositiontaking, @auto_v3spositiontaking_mem_20 = autopositiontaking, @isauto_v3spositiontaking_mem_20 = isautopositiontaking, @old_v3apositiontaking_20 = apositiontaking, @auto_v3mpositiontaking_mem_20 = autompositiontaking, @isauto_v3mpositiontaking_mem_20 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=3

SELECT @v5spositiontaking_1 = spositiontaking, @v5mpositiontaking_1 = mpositiontaking, @auto_v5spositiontaking_mem_1 = autopositiontaking, @isauto_v5spositiontaking_mem_1 = isautopositiontaking, @old_v5apositiontaking_1 = apositiontaking, @auto_v5mpositiontaking_mem_1 = autompositiontaking, @isauto_v5mpositiontaking_mem_1 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=5
SELECT @v5spositiontaking_2 = spositiontaking, @v5mpositiontaking_2 = mpositiontaking, @auto_v5spositiontaking_mem_2 = autopositiontaking, @isauto_v5spositiontaking_mem_2 = isautopositiontaking, @old_v5apositiontaking_2 = apositiontaking, @auto_v5mpositiontaking_mem_2 = autompositiontaking, @isauto_v5mpositiontaking_mem_2 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=5
SELECT @v5spositiontaking_3 = spositiontaking, @v5mpositiontaking_3 = mpositiontaking, @auto_v5spositiontaking_mem_3 = autopositiontaking, @isauto_v5spositiontaking_mem_3 = isautopositiontaking, @old_v5apositiontaking_3 = apositiontaking, @auto_v5mpositiontaking_mem_3 = autompositiontaking, @isauto_v5mpositiontaking_mem_3 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=5
SELECT @v5spositiontaking_20 = spositiontaking, @v5mpositiontaking_20 = mpositiontaking, @auto_v5spositiontaking_mem_20 = autopositiontaking, @isauto_v5spositiontaking_mem_20 = isautopositiontaking, @old_v5apositiontaking_20 = apositiontaking, @auto_v5mpositiontaking_mem_20 = autompositiontaking, @isauto_v5mpositiontaking_mem_20 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=5

SELECT @v8spositiontaking_1 = spositiontaking, @v8mpositiontaking_1 = mpositiontaking, @auto_v8spositiontaking_mem_1 = autopositiontaking, @isauto_v8spositiontaking_mem_1 = isautopositiontaking, @old_v8apositiontaking_1 = apositiontaking, @auto_v8mpositiontaking_mem_1 = autompositiontaking, @isauto_v8mpositiontaking_mem_1 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=8
SELECT @v8spositiontaking_3 = spositiontaking, @v8mpositiontaking_3 = mpositiontaking, @auto_v8spositiontaking_mem_3 = autopositiontaking, @isauto_v8spositiontaking_mem_3 = isautopositiontaking, @old_v8apositiontaking_3 = apositiontaking, @auto_v8mpositiontaking_mem_3 = autompositiontaking, @isauto_v8mpositiontaking_mem_3 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=8
SELECT @v8spositiontaking_20 = spositiontaking, @v8mpositiontaking_20 = mpositiontaking, @auto_v8spositiontaking_mem_20 = autopositiontaking, @isauto_v8spositiontaking_mem_20 = isautopositiontaking, @old_v8apositiontaking_20 = apositiontaking, @auto_v8mpositiontaking_mem_20 = autompositiontaking, @isauto_v8mpositiontaking_mem_20 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=8

SELECT @v10spositiontaking_1 = spositiontaking, @v10mpositiontaking_1 = mpositiontaking, @auto_v10spositiontaking_mem_1 = autopositiontaking, @isauto_v10spositiontaking_mem_1 = isautopositiontaking, @old_v10apositiontaking_1 = apositiontaking, @auto_v10mpositiontaking_mem_1 = autompositiontaking, @isauto_v10mpositiontaking_mem_1 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=10
SELECT @v10spositiontaking_2 = spositiontaking, @v10mpositiontaking_2 = mpositiontaking, @auto_v10spositiontaking_mem_2 = autopositiontaking, @isauto_v10spositiontaking_mem_2 = isautopositiontaking, @old_v10apositiontaking_2 = apositiontaking, @auto_v10mpositiontaking_mem_2 = autompositiontaking, @isauto_v10mpositiontaking_mem_2 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=10
SELECT @v10spositiontaking_3 = spositiontaking, @v10mpositiontaking_3 = mpositiontaking, @auto_v10spositiontaking_mem_3 = autopositiontaking, @isauto_v10spositiontaking_mem_3 = isautopositiontaking, @old_v10apositiontaking_3 = apositiontaking, @auto_v10mpositiontaking_mem_3 = autompositiontaking, @isauto_v10mpositiontaking_mem_3 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=10
SELECT @v10spositiontaking_20 = spositiontaking, @v10mpositiontaking_20 = mpositiontaking, @auto_v10spositiontaking_mem_20 = autopositiontaking, @isauto_v10spositiontaking_mem_20 = isautopositiontaking, @old_v10apositiontaking_20 = apositiontaking, @auto_v10mpositiontaking_mem_20 = autompositiontaking, @isauto_v10mpositiontaking_mem_20 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=10

SELECT @v11spositiontaking_1 = spositiontaking, @v11mpositiontaking_1 = mpositiontaking, @auto_v11spositiontaking_mem_1 = autopositiontaking, @isauto_v11spositiontaking_mem_1 = isautopositiontaking, @old_v11apositiontaking_1 = apositiontaking, @auto_v11mpositiontaking_mem_1 = autompositiontaking, @isauto_v11mpositiontaking_mem_1 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=11
SELECT @v11spositiontaking_20 = spositiontaking, @v11mpositiontaking_20 = mpositiontaking, @auto_v11spositiontaking_mem_20 = autopositiontaking, @isauto_v11spositiontaking_mem_20 = isautopositiontaking, @old_v11apositiontaking_20 = apositiontaking, @auto_v11mpositiontaking_mem_20 = autompositiontaking, @isauto_v11mpositiontaking_mem_20 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=11

SELECT @v99spositiontaking_1 = spositiontaking, @v99mpositiontaking_1 = mpositiontaking, @auto_v99spositiontaking_mem_1 = autopositiontaking, @isauto_v99spositiontaking_mem_1 = isautopositiontaking, @old_v99apositiontaking_1 = apositiontaking, @auto_v99mpositiontaking_mem_1 = autompositiontaking, @isauto_v99mpositiontaking_mem_1 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=99
SELECT @v99spositiontaking_2 = spositiontaking, @v99mpositiontaking_2 = mpositiontaking, @auto_v99spositiontaking_mem_2 = autopositiontaking, @isauto_v99spositiontaking_mem_2 = isautopositiontaking, @old_v99apositiontaking_2 = apositiontaking, @auto_v99mpositiontaking_mem_2 = autompositiontaking, @isauto_v99mpositiontaking_mem_2 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=99
SELECT @v99spositiontaking_3 = spositiontaking, @v99mpositiontaking_3 = mpositiontaking, @auto_v99spositiontaking_mem_3 = autopositiontaking, @isauto_v99spositiontaking_mem_3 = isautopositiontaking, @old_v99apositiontaking_3 = apositiontaking, @auto_v99mpositiontaking_mem_3 = autompositiontaking, @isauto_v99mpositiontaking_mem_3 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=99
SELECT @v99spositiontaking_20 = spositiontaking, @v99mpositiontaking_20 = mpositiontaking, @auto_v99spositiontaking_mem_20 = autopositiontaking, @isauto_v99spositiontaking_mem_20 = isautopositiontaking, @old_v99apositiontaking_20 = apositiontaking, @auto_v99mpositiontaking_mem_20 = autompositiontaking, @isauto_v99mpositiontaking_mem_20 = isautompositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=99


------------------------------------------------------------------------------------------------------------------------------
--Auto Master PT
------------------------------------------------------------------------------------------------------------------------------
--um2,im2
select @auto_mpositiontaking_1 = autompositiontaking, @auto_mlivepositiontaking_1 = autolivempositiontaking, @isauto_mpositiontaking_1 = isautompositiontaking, @isauto_mlivepositiontaking_1 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=1
--select @mpositiontaking_1 = mpositiontaking, @mlivepositiontaking_1 = mlivepositiontaking, @minMinBet = MinBet, @maxMaxBet = MaxBet, @maxdiscount = case when @ugroup in ('a','hka') then groupa when @ugroup in ('b','hkb') then groupb when @ugroup in ('c','hkc') then groupc else groupd end from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=1
select @auto_mpositiontaking_3 = autompositiontaking, @auto_mlivepositiontaking_3 = autolivempositiontaking, @isauto_mpositiontaking_3 = isautompositiontaking, @isauto_mlivepositiontaking_3 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=1
select @auto_mpositiontaking_7 = autompositiontaking, @auto_mlivepositiontaking_7 = autolivempositiontaking, @isauto_mpositiontaking_7 = isautompositiontaking, @isauto_mlivepositiontaking_7 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=7 and sporttype=1
select @auto_mpositiontaking_8 = autompositiontaking, @auto_mlivepositiontaking_8 = autolivempositiontaking, @isauto_mpositiontaking_8 = isautompositiontaking, @isauto_mlivepositiontaking_8 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=8 and sporttype=1
select @auto_mpositiontaking_2 = autompositiontaking, @isauto_mpositiontaking_2 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=1
select @auto_mpositiontaking_4 = autompositiontaking, @isauto_mpositiontaking_4 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=4 and sporttype=1
--select @mpositiontaking_4 = mpositiontaking, @maxdiscountcs = discount from custsetting with (NOLOCK) where custid = @recommend and bettype=4 and sporttype=1
select @auto_mpositiontaking_5 = autompositiontaking, @isauto_mpositiontaking_5 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=5 and sporttype=1
select @auto_mpositiontaking_6 = autompositiontaking, @isauto_mpositiontaking_6 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=6 and sporttype=1
select @auto_mpositiontaking_9 = autompositiontaking, @isauto_mpositiontaking_9 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=9 and sporttype=1
select @auto_mpositiontaking_10 = autompositiontaking, @isauto_mpositiontaking_10 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=10 and sporttype=1

select @auto_v2mpositiontaking_1 = autompositiontaking, @isauto_v2mpositiontaking_1 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=2
select @auto_v2mpositiontaking_2 = autompositiontaking, @isauto_v2mpositiontaking_2 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=2
select @auto_v2mpositiontaking_3 = autompositiontaking, @isauto_v2mpositiontaking_3 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=2
select @auto_v2mpositiontaking_7 = autompositiontaking, @isauto_v2mpositiontaking_7 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=7 and sporttype=2
select @auto_v2mpositiontaking_8 = autompositiontaking, @isauto_v2mpositiontaking_8 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=8 and sporttype=2
select @auto_v2mpositiontaking_9 = autompositiontaking, @isauto_v2mpositiontaking_9 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=9 and sporttype=2
select @auto_v2mpositiontaking_20 = autompositiontaking, @isauto_v2mpositiontaking_20 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=20 and sporttype=2

select @auto_v3mpositiontaking_1 = autompositiontaking, @isauto_v3mpositiontaking_1 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=3
select @auto_v3mpositiontaking_2 = autompositiontaking, @isauto_v3mpositiontaking_2 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=3
select @auto_v3mpositiontaking_3 = autompositiontaking, @isauto_v3mpositiontaking_3 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=3
select @auto_v3mpositiontaking_20 = autompositiontaking, @isauto_v3mpositiontaking_20 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=20 and sporttype=3

select @auto_v5mpositiontaking_1 = autompositiontaking, @isauto_v5mpositiontaking_1 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=5
select @auto_v5mpositiontaking_2 = autompositiontaking, @isauto_v5mpositiontaking_2 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=5
select @auto_v5mpositiontaking_3 = autompositiontaking, @isauto_v5mpositiontaking_3 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=5
select @auto_v5mpositiontaking_20 = autompositiontaking, @isauto_v5mpositiontaking_20 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=20 and sporttype=5

select @auto_v8mpositiontaking_1 = autompositiontaking, @isauto_v8mpositiontaking_1 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=8
select @auto_v8mpositiontaking_3 = autompositiontaking, @isauto_v8mpositiontaking_3 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=8
select @auto_v8mpositiontaking_20 = autompositiontaking, @isauto_v8mpositiontaking_20 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=20 and sporttype=8

select @auto_v10mpositiontaking_1 = autompositiontaking, @isauto_v10mpositiontaking_1 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=10
select @auto_v10mpositiontaking_2 = autompositiontaking, @isauto_v10mpositiontaking_2 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=10
select @auto_v10mpositiontaking_3 = autompositiontaking, @isauto_v10mpositiontaking_3 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=10
select @auto_v10mpositiontaking_20 = autompositiontaking, @isauto_v10mpositiontaking_20 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=20 and sporttype=10

select @auto_v11mpositiontaking_1 = autompositiontaking, @isauto_v11mpositiontaking_1 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=11
select @auto_v11mpositiontaking_20 = autompositiontaking, @isauto_v11mpositiontaking_20 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=20 and sporttype=11

select @auto_v99mpositiontaking_1 = autompositiontaking, @isauto_v99mpositiontaking_1 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=99
select @auto_v99mpositiontaking_2 = autompositiontaking, @isauto_v99mpositiontaking_2 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=99
select @auto_v99mpositiontaking_3 = autompositiontaking, @isauto_v99mpositiontaking_3 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=99
select @auto_v99mpositiontaking_20 = autompositiontaking, @isauto_v99mpositiontaking_20 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=20 and sporttype=99
------------------------------------------------------------------------------------------------------------------------------



--s3,m3,u3,i3
SELECT @mapositiontaking_1_max = mpositiontaking, @malivepositiontaking_1_max = mlivepositiontaking, @auto_spositiontaking_1 = autopositiontaking, @auto_slivepositiontaking_1 = autolivepositiontaking, @isauto_spositiontaking_1 = isautopositiontaking, @isauto_slivepositiontaking_1 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=1
SELECT @mapositiontaking_3_max = mpositiontaking, @malivepositiontaking_3_max = mlivepositiontaking, @auto_spositiontaking_3 = autopositiontaking, @auto_slivepositiontaking_3 = autolivepositiontaking, @isauto_spositiontaking_3 = isautopositiontaking, @isauto_slivepositiontaking_3 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=1
SELECT @mapositiontaking_7_max = mpositiontaking, @malivepositiontaking_7_max = mlivepositiontaking, @auto_spositiontaking_7 = autopositiontaking, @auto_slivepositiontaking_7 = autolivepositiontaking, @isauto_spositiontaking_7 = isautopositiontaking, @isauto_slivepositiontaking_7 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=7 AND sporttype=1
SELECT @mapositiontaking_8_max = mpositiontaking, @malivepositiontaking_8_max = mlivepositiontaking, @auto_spositiontaking_8 = autopositiontaking, @auto_slivepositiontaking_8 = autolivepositiontaking, @isauto_spositiontaking_8 = isautopositiontaking, @isauto_slivepositiontaking_8 = isautolivepositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=8 AND sporttype=1
SELECT @mapositiontaking_2_max = mpositiontaking, @auto_spositiontaking_2 = autopositiontaking, @isauto_spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=1
SELECT @mapositiontaking_4_max = mpositiontaking, @auto_spositiontaking_4 = autopositiontaking, @isauto_spositiontaking_4 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=4 AND sporttype=1
SELECT @mapositiontaking_5_max = mpositiontaking, @auto_spositiontaking_5 = autopositiontaking, @isauto_spositiontaking_5 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=5 AND sporttype=1
SELECT @mapositiontaking_6_max = mpositiontaking, @auto_spositiontaking_6 = autopositiontaking, @isauto_spositiontaking_6 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=6 AND sporttype=1
SELECT @mapositiontaking_9_max = mpositiontaking, @auto_spositiontaking_9 = autopositiontaking, @isauto_spositiontaking_9 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=9 AND sporttype=1
SELECT @mapositiontaking_10_max = mpositiontaking, @auto_spositiontaking_10 = autopositiontaking, @isauto_spositiontaking_10 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=10 AND sporttype=1

SELECT @v2mapositiontaking_1_max = mpositiontaking, @auto_v2spositiontaking_1 = autopositiontaking, @isauto_v2spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=2
SELECT @v2mapositiontaking_2_max = mpositiontaking, @auto_v2spositiontaking_2 = autopositiontaking, @isauto_v2spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=2
SELECT @v2mapositiontaking_3_max = mpositiontaking, @auto_v2spositiontaking_3 = autopositiontaking, @isauto_v2spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=2
SELECT @v2mapositiontaking_7_max = mpositiontaking, @auto_v2spositiontaking_7 = autopositiontaking, @isauto_v2spositiontaking_7 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=7 AND sporttype=2
SELECT @v2mapositiontaking_8_max = mpositiontaking, @auto_v2spositiontaking_8 = autopositiontaking, @isauto_v2spositiontaking_8 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=8 AND sporttype=2
SELECT @v2mapositiontaking_9_max = mpositiontaking, @auto_v2spositiontaking_9 = autopositiontaking, @isauto_v2spositiontaking_9 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=9 AND sporttype=2
SELECT @v2mapositiontaking_20_max = mpositiontaking, @auto_v2spositiontaking_20 = autopositiontaking, @isauto_v2spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=2

SELECT @v3mapositiontaking_1_max = mpositiontaking, @auto_v3spositiontaking_1 = autopositiontaking, @isauto_v3spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=3
SELECT @v3mapositiontaking_2_max = mpositiontaking, @auto_v3spositiontaking_2 = autopositiontaking, @isauto_v3spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=3
SELECT @v3mapositiontaking_3_max = mpositiontaking, @auto_v3spositiontaking_3 = autopositiontaking, @isauto_v3spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=3
SELECT @v3mapositiontaking_20_max = mpositiontaking, @auto_v3spositiontaking_20 = autopositiontaking, @isauto_v3spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=3

SELECT @v5mapositiontaking_1_max = mpositiontaking, @auto_v5spositiontaking_1 = autopositiontaking, @isauto_v5spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=5
SELECT @v5mapositiontaking_2_max = mpositiontaking, @auto_v5spositiontaking_2 = autopositiontaking, @isauto_v5spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=5
SELECT @v5mapositiontaking_3_max = mpositiontaking, @auto_v5spositiontaking_3 = autopositiontaking, @isauto_v5spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=5
SELECT @v5mapositiontaking_20_max = mpositiontaking, @auto_v5spositiontaking_20 = autopositiontaking, @isauto_v5spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=5

SELECT @v8mapositiontaking_1_max = mpositiontaking, @auto_v8spositiontaking_1 = autopositiontaking, @isauto_v8spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=8
SELECT @v8mapositiontaking_3_max = mpositiontaking, @auto_v8spositiontaking_3 = autopositiontaking, @isauto_v8spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=8
SELECT @v8mapositiontaking_20_max = mpositiontaking, @auto_v8spositiontaking_20 = autopositiontaking, @isauto_v8spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=8

SELECT @v10mapositiontaking_1_max = mpositiontaking, @auto_v10spositiontaking_1 = autopositiontaking, @isauto_v10spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=10
SELECT @v10mapositiontaking_2_max = mpositiontaking, @auto_v10spositiontaking_2 = autopositiontaking, @isauto_v10spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=10
SELECT @v10mapositiontaking_3_max = mpositiontaking, @auto_v10spositiontaking_3 = autopositiontaking, @isauto_v10spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=10
SELECT @v10mapositiontaking_20_max = mpositiontaking, @auto_v10spositiontaking_20 = autopositiontaking, @isauto_v10spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=10

SELECT @v11mapositiontaking_1_max = mpositiontaking, @auto_v11spositiontaking_1 = autopositiontaking, @isauto_v11spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=11
SELECT @v11mapositiontaking_20_max = mpositiontaking, @auto_v11spositiontaking_20 = autopositiontaking, @isauto_v11spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=11

SELECT @v99mapositiontaking_1_max = mpositiontaking, @auto_v99spositiontaking_1 = autopositiontaking, @isauto_v99spositiontaking_1 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=1 AND sporttype=99
SELECT @v99mapositiontaking_2_max = mpositiontaking, @auto_v99spositiontaking_2 = autopositiontaking, @isauto_v99spositiontaking_2 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=2 AND sporttype=99
SELECT @v99mapositiontaking_3_max = mpositiontaking, @auto_v99spositiontaking_3 = autopositiontaking, @isauto_v99spositiontaking_3 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=3 AND sporttype=99
SELECT @v99mapositiontaking_20_max = mpositiontaking, @auto_v99spositiontaking_20 = autopositiontaking, @isauto_v99spositiontaking_20 = isautopositiontaking FROM custsetting WITH (NOLOCK) WHERE custid = @mrecommend AND bettype=20 AND sporttype=99

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
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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


--a1=min(a1,m3)
SELECT 
	@apositiontaking_1 = CASE WHEN @apositiontaking_1>@mapositiontaking_1_max THEN @mapositiontaking_1_max ELSE @apositiontaking_1 END,
	@apositiontaking_2 = CASE WHEN @apositiontaking_2>@mapositiontaking_2_max THEN @mapositiontaking_2_max ELSE @apositiontaking_2 END,
	@apositiontaking_3 = CASE WHEN @apositiontaking_3>@mapositiontaking_3_max THEN @mapositiontaking_3_max ELSE @apositiontaking_3 END,
	@apositiontaking_4 = CASE WHEN @apositiontaking_4>@mapositiontaking_4_max THEN @mapositiontaking_4_max ELSE @apositiontaking_4 END,
	@apositiontaking_5 = CASE WHEN @apositiontaking_5>@mapositiontaking_5_max THEN @mapositiontaking_5_max ELSE @apositiontaking_5 END,
	@apositiontaking_6 = CASE WHEN @apositiontaking_6>@mapositiontaking_6_max THEN @mapositiontaking_6_max ELSE @apositiontaking_6 END,
	@apositiontaking_7 = CASE WHEN @apositiontaking_7>@mapositiontaking_7_max THEN @mapositiontaking_7_max ELSE @apositiontaking_7 END,
	@apositiontaking_8 = CASE WHEN @apositiontaking_8>@mapositiontaking_8_max THEN @mapositiontaking_8_max ELSE @apositiontaking_8 END,
	@apositiontaking_9 = CASE WHEN @apositiontaking_9>@mapositiontaking_9_max THEN @mapositiontaking_9_max ELSE @apositiontaking_9 END,
	@apositiontaking_10 = CASE WHEN @apositiontaking_10>@mapositiontaking_10_max THEN @mapositiontaking_10_max ELSE @apositiontaking_10 END,

	@alivepositiontaking_1 = CASE WHEN @alivepositiontaking_1>@malivepositiontaking_1_max THEN @malivepositiontaking_1_max ELSE @alivepositiontaking_1 END,
	@alivepositiontaking_3 = CASE WHEN @alivepositiontaking_3>@malivepositiontaking_3_max THEN @malivepositiontaking_3_max ELSE @alivepositiontaking_3 END,
	@alivepositiontaking_7 = CASE WHEN @alivepositiontaking_7>@malivepositiontaking_7_max THEN @malivepositiontaking_7_max ELSE @alivepositiontaking_7 END,
	@alivepositiontaking_8 = CASE WHEN @alivepositiontaking_8>@malivepositiontaking_8_max THEN @malivepositiontaking_8_max ELSE @alivepositiontaking_8 END,

	@v2apositiontaking_1 = CASE WHEN @v2apositiontaking_1>@v2mapositiontaking_1_max THEN @v2mapositiontaking_1_max ELSE @v2apositiontaking_1 END,
	@v2apositiontaking_2 = CASE WHEN @v2apositiontaking_2>@v2mapositiontaking_2_max THEN @v2mapositiontaking_2_max ELSE @v2apositiontaking_2 END,
	@v2apositiontaking_3 = CASE WHEN @v2apositiontaking_3>@v2mapositiontaking_3_max THEN @v2mapositiontaking_3_max ELSE @v2apositiontaking_3 END,
	@v2apositiontaking_7 = CASE WHEN @v2apositiontaking_7>@v2mapositiontaking_7_max THEN @v2mapositiontaking_7_max ELSE @v2apositiontaking_7 END,
	@v2apositiontaking_8 = CASE WHEN @v2apositiontaking_8>@v2mapositiontaking_8_max THEN @v2mapositiontaking_8_max ELSE @v2apositiontaking_8 END,
	@v2apositiontaking_9 = CASE WHEN @v2apositiontaking_9>@v2mapositiontaking_9_max THEN @v2mapositiontaking_9_max ELSE @v2apositiontaking_9 END,
	@v2apositiontaking_20 = CASE WHEN @v2apositiontaking_20>@v2mapositiontaking_20_max THEN @v2mapositiontaking_20_max ELSE @v2apositiontaking_20 END,
	
	@v3apositiontaking_1 = CASE WHEN @v3apositiontaking_1>@v3mapositiontaking_1_max THEN @v3mapositiontaking_1_max ELSE @v3apositiontaking_1 END,
	@v3apositiontaking_2 = CASE WHEN @v3apositiontaking_2>@v3mapositiontaking_2_max THEN @v3mapositiontaking_2_max ELSE @v3apositiontaking_2 END,
	@v3apositiontaking_3 = CASE WHEN @v3apositiontaking_3>@v3mapositiontaking_3_max THEN @v3mapositiontaking_3_max ELSE @v3apositiontaking_3 END,
	@v3apositiontaking_20 = CASE WHEN @v3apositiontaking_20>@v3mapositiontaking_20_max THEN @v3mapositiontaking_20_max ELSE @v3apositiontaking_20 END,

	@v5apositiontaking_1 = CASE WHEN @v5apositiontaking_1>@v5mapositiontaking_1_max THEN @v5mapositiontaking_1_max ELSE @v5apositiontaking_1 END,
	@v5apositiontaking_2 = CASE WHEN @v5apositiontaking_2>@v5mapositiontaking_2_max THEN @v5mapositiontaking_2_max ELSE @v5apositiontaking_2 END,
	@v5apositiontaking_3 = CASE WHEN @v5apositiontaking_3>@v5mapositiontaking_3_max THEN @v5mapositiontaking_3_max ELSE @v5apositiontaking_3 END,
	@v5apositiontaking_20 = CASE WHEN @v5apositiontaking_20>@v5mapositiontaking_20_max THEN @v5mapositiontaking_20_max ELSE @v5apositiontaking_20 END,

	@v8apositiontaking_1 = CASE WHEN @v8apositiontaking_1>@v8mapositiontaking_1_max THEN @v8mapositiontaking_1_max ELSE @v8apositiontaking_1 END,
	@v8apositiontaking_3 = CASE WHEN @v8apositiontaking_3>@v8mapositiontaking_3_max THEN @v8mapositiontaking_3_max ELSE @v8apositiontaking_3 END,
	@v8apositiontaking_20 = CASE WHEN @v8apositiontaking_20>@v8mapositiontaking_20_max THEN @v8mapositiontaking_20_max ELSE @v8apositiontaking_20 END,

	@v10apositiontaking_1 = CASE WHEN @v10apositiontaking_1>@v10mapositiontaking_1_max THEN @v10mapositiontaking_1_max ELSE @v10apositiontaking_1 END,
	@v10apositiontaking_2 = CASE WHEN @v10apositiontaking_2>@v10mapositiontaking_2_max THEN @v10mapositiontaking_2_max ELSE @v10apositiontaking_2 END,
	@v10apositiontaking_3 = CASE WHEN @v10apositiontaking_3>@v10mapositiontaking_3_max THEN @v10mapositiontaking_3_max ELSE @v10apositiontaking_3 END,
	@v10apositiontaking_20 = CASE WHEN @v10apositiontaking_20>@v10mapositiontaking_20_max THEN @v10mapositiontaking_20_max ELSE @v10apositiontaking_20 END,

	@v11apositiontaking_1 = CASE WHEN @v11apositiontaking_1>@v11mapositiontaking_1_max THEN @v11mapositiontaking_1_max ELSE @v11apositiontaking_1 END,
	@v11apositiontaking_20 = CASE WHEN @v11apositiontaking_20>@v11mapositiontaking_20_max THEN @v11mapositiontaking_20_max ELSE @v11apositiontaking_20 END,

	@v99apositiontaking_1 = CASE WHEN @v99apositiontaking_1>@v99mapositiontaking_1_max THEN @v99mapositiontaking_1_max ELSE @v99apositiontaking_1 END,
	@v99apositiontaking_2 = CASE WHEN @v99apositiontaking_2>@v99mapositiontaking_2_max THEN @v99mapositiontaking_2_max ELSE @v99apositiontaking_2 END,
	@v99apositiontaking_3 = CASE WHEN @v99apositiontaking_3>@v99mapositiontaking_3_max THEN @v99mapositiontaking_3_max ELSE @v99apositiontaking_3 END,
	@v99apositiontaking_20 = CASE WHEN @v99apositiontaking_20>@v99mapositiontaking_20_max THEN @v99mapositiontaking_20_max ELSE @v99apositiontaking_20 END

--a1=if(!im)if(m1+a1>m3,m3-m1)
SELECT 
	@apositiontaking_1 = CASE WHEN @isauto_mpositiontaking_1 > 0 THEN @apositiontaking_1 ELSE CASE WHEN @apositiontaking_1+@mpositiontaking_1>@mapositiontaking_1_max THEN @mapositiontaking_1_max-@mpositiontaking_1 ELSE @apositiontaking_1 END END,
	@apositiontaking_2 = CASE WHEN @isauto_mpositiontaking_2 > 0 THEN @apositiontaking_2 ELSE CASE WHEN @apositiontaking_2+@mpositiontaking_2>@mapositiontaking_2_max THEN @mapositiontaking_2_max-@mpositiontaking_2 ELSE @apositiontaking_2 END END,
	@apositiontaking_3 = CASE WHEN @isauto_mpositiontaking_3 > 0 THEN @apositiontaking_3 ELSE CASE WHEN @apositiontaking_3+@mpositiontaking_3>@mapositiontaking_3_max THEN @mapositiontaking_3_max-@mpositiontaking_3 ELSE @apositiontaking_3 END END,
	@apositiontaking_4 = CASE WHEN @isauto_mpositiontaking_4 > 0 THEN @apositiontaking_4 ELSE CASE WHEN @apositiontaking_4+@mpositiontaking_4>@mapositiontaking_4_max THEN @mapositiontaking_4_max-@mpositiontaking_4 ELSE @apositiontaking_4 END END,
	@apositiontaking_5 = CASE WHEN @isauto_mpositiontaking_5 > 0 THEN @apositiontaking_5 ELSE CASE WHEN @apositiontaking_5+@mpositiontaking_5>@mapositiontaking_5_max THEN @mapositiontaking_5_max-@mpositiontaking_5 ELSE @apositiontaking_5 END END,
	@apositiontaking_6 = CASE WHEN @isauto_mpositiontaking_6 > 0 THEN @apositiontaking_6 ELSE CASE WHEN @apositiontaking_6+@mpositiontaking_6>@mapositiontaking_6_max THEN @mapositiontaking_6_max-@mpositiontaking_6 ELSE @apositiontaking_6 END END,
	@apositiontaking_7 = CASE WHEN @isauto_mpositiontaking_7 > 0 THEN @apositiontaking_7 ELSE CASE WHEN @apositiontaking_7+@mpositiontaking_7>@mapositiontaking_7_max THEN @mapositiontaking_7_max-@mpositiontaking_7 ELSE @apositiontaking_7 END END,
	@apositiontaking_8 = CASE WHEN @isauto_mpositiontaking_8 > 0 THEN @apositiontaking_8 ELSE CASE WHEN @apositiontaking_8+@mpositiontaking_8>@mapositiontaking_8_max THEN @mapositiontaking_8_max-@mpositiontaking_8 ELSE @apositiontaking_8 END END,
	@apositiontaking_9 = CASE WHEN @isauto_mpositiontaking_9 > 0 THEN @apositiontaking_9 ELSE CASE WHEN @apositiontaking_9+@mpositiontaking_9>@mapositiontaking_9_max THEN @mapositiontaking_9_max-@mpositiontaking_9 ELSE @apositiontaking_9 END END,
	@apositiontaking_10 = CASE WHEN @isauto_mpositiontaking_10 > 0 THEN @apositiontaking_10 ELSE CASE WHEN @apositiontaking_10+@mpositiontaking_10>@mapositiontaking_10_max THEN @mapositiontaking_10_max-@mpositiontaking_10 ELSE @apositiontaking_10 END END,

	@alivepositiontaking_1 = CASE WHEN @isauto_mlivepositiontaking_1 > 0 THEN @alivepositiontaking_1 ELSE CASE WHEN @alivepositiontaking_1+@mlivepositiontaking_1>@malivepositiontaking_1_max THEN @malivepositiontaking_1_max-@mlivepositiontaking_1 ELSE @alivepositiontaking_1 END END,
	@alivepositiontaking_3 = CASE WHEN @isauto_mlivepositiontaking_3 > 0 THEN @alivepositiontaking_3 ELSE CASE WHEN @alivepositiontaking_3+@mlivepositiontaking_3>@malivepositiontaking_3_max THEN @malivepositiontaking_3_max-@mlivepositiontaking_3 ELSE @alivepositiontaking_3 END END,
	@alivepositiontaking_7 = CASE WHEN @isauto_mlivepositiontaking_7 > 0 THEN @alivepositiontaking_7 ELSE CASE WHEN @alivepositiontaking_7+@mlivepositiontaking_7>@malivepositiontaking_7_max THEN @malivepositiontaking_7_max-@mlivepositiontaking_7 ELSE @alivepositiontaking_7 END END,
	@alivepositiontaking_8 = CASE WHEN @isauto_mlivepositiontaking_8 > 0 THEN @alivepositiontaking_8 ELSE CASE WHEN @alivepositiontaking_8+@mlivepositiontaking_8>@malivepositiontaking_8_max THEN @malivepositiontaking_8_max-@mlivepositiontaking_8 ELSE @alivepositiontaking_8 END END,

	@v2apositiontaking_1 = CASE WHEN @isauto_v2mpositiontaking_1 > 0 THEN @v2apositiontaking_1 ELSE CASE WHEN @v2apositiontaking_1+@v2mpositiontaking_1>@v2mapositiontaking_1_max THEN @v2mapositiontaking_1_max-@v2mpositiontaking_1 ELSE @v2apositiontaking_1 END END,
	@v2apositiontaking_2 = CASE WHEN @isauto_v2mpositiontaking_2 > 0 THEN @v2apositiontaking_2 ELSE CASE WHEN @v2apositiontaking_2+@v2mpositiontaking_2>@v2mapositiontaking_2_max THEN @v2mapositiontaking_2_max-@v2mpositiontaking_2 ELSE @v2apositiontaking_2 END END,
	@v2apositiontaking_3 = CASE WHEN @isauto_v2mpositiontaking_3 > 0 THEN @v2apositiontaking_3 ELSE CASE WHEN @v2apositiontaking_3+@v2mpositiontaking_3>@v2mapositiontaking_3_max THEN @v2mapositiontaking_3_max-@v2mpositiontaking_3 ELSE @v2apositiontaking_3 END END,
	@v2apositiontaking_7 = CASE WHEN @isauto_v2mpositiontaking_7 > 0 THEN @v2apositiontaking_7 ELSE CASE WHEN @v2apositiontaking_7+@v2mpositiontaking_7>@v2mapositiontaking_7_max THEN @v2mapositiontaking_7_max-@v2mpositiontaking_7 ELSE @v2apositiontaking_7 END END,
	@v2apositiontaking_8 = CASE WHEN @isauto_v2mpositiontaking_8 > 0 THEN @v2apositiontaking_8 ELSE CASE WHEN @v2apositiontaking_8+@v2mpositiontaking_8>@v2mapositiontaking_8_max THEN @v2mapositiontaking_8_max-@v2mpositiontaking_8 ELSE @v2apositiontaking_8 END END,
	@v2apositiontaking_9 = CASE WHEN @isauto_v2mpositiontaking_9 > 0 THEN @v2apositiontaking_9 ELSE CASE WHEN @v2apositiontaking_9+@v2mpositiontaking_9>@v2mapositiontaking_9_max THEN @v2mapositiontaking_9_max-@v2mpositiontaking_9 ELSE @v2apositiontaking_9 END END,
	@v2apositiontaking_20 = CASE WHEN @isauto_v2mpositiontaking_20 > 0 THEN @v2apositiontaking_20 ELSE CASE WHEN @v2apositiontaking_20+@v2mpositiontaking_20>@v2mapositiontaking_20_max THEN @v2mapositiontaking_20_max-@v2mpositiontaking_20 ELSE @v2apositiontaking_20 END END,

	@v3apositiontaking_1 = CASE WHEN @isauto_v3mpositiontaking_1 > 0 THEN @v3apositiontaking_1 ELSE CASE WHEN @v3apositiontaking_1+@v3mpositiontaking_1>@v3mapositiontaking_1_max THEN @v3mapositiontaking_1_max-@v3mpositiontaking_1 ELSE @v3apositiontaking_1 END END,
	@v3apositiontaking_2 = CASE WHEN @isauto_v3mpositiontaking_2 > 0 THEN @v3apositiontaking_2 ELSE CASE WHEN @v3apositiontaking_2+@v3mpositiontaking_2>@v3mapositiontaking_2_max THEN @v3mapositiontaking_2_max-@v3mpositiontaking_2 ELSE @v3apositiontaking_2 END END,
	@v3apositiontaking_3 = CASE WHEN @isauto_v3mpositiontaking_3 > 0 THEN @v3apositiontaking_3 ELSE CASE WHEN @v3apositiontaking_3+@v3mpositiontaking_3>@v3mapositiontaking_3_max THEN @v3mapositiontaking_3_max-@v3mpositiontaking_3 ELSE @v3apositiontaking_3 END END,
	@v3apositiontaking_20 = CASE WHEN @isauto_v3mpositiontaking_20 > 0 THEN @v3apositiontaking_20 ELSE CASE WHEN @v3apositiontaking_20+@v3mpositiontaking_20>@v3mapositiontaking_20_max THEN @v3mapositiontaking_20_max-@v3mpositiontaking_20 ELSE @v3apositiontaking_20 END END,

	@v5apositiontaking_1 = CASE WHEN @isauto_v5mpositiontaking_1 > 0 THEN @v5apositiontaking_1 ELSE CASE WHEN @v5apositiontaking_1+@v5mpositiontaking_1>@v5mapositiontaking_1_max THEN @v5mapositiontaking_1_max-@v5mpositiontaking_1 ELSE @v5apositiontaking_1 END END,
	@v5apositiontaking_2 = CASE WHEN @isauto_v5mpositiontaking_2 > 0 THEN @v5apositiontaking_2 ELSE CASE WHEN @v5apositiontaking_2+@v5mpositiontaking_2>@v5mapositiontaking_2_max THEN @v5mapositiontaking_2_max-@v5mpositiontaking_2 ELSE @v5apositiontaking_2 END END,
	@v5apositiontaking_3 = CASE WHEN @isauto_v5mpositiontaking_3 > 0 THEN @v5apositiontaking_3 ELSE CASE WHEN @v5apositiontaking_3+@v5mpositiontaking_3>@v5mapositiontaking_3_max THEN @v5mapositiontaking_3_max-@v5mpositiontaking_3 ELSE @v5apositiontaking_3 END END,
	@v5apositiontaking_20 = CASE WHEN @isauto_v5mpositiontaking_20 > 0 THEN @v5apositiontaking_20 ELSE CASE WHEN @v5apositiontaking_20+@v5mpositiontaking_20>@v5mapositiontaking_20_max THEN @v5mapositiontaking_20_max-@v5mpositiontaking_20 ELSE @v5apositiontaking_20 END END,

	@v8apositiontaking_1 = CASE WHEN @isauto_v8mpositiontaking_1 > 0 THEN @v8apositiontaking_1 ELSE CASE WHEN @v8apositiontaking_1+@v8mpositiontaking_1>@v8mapositiontaking_1_max THEN @v8mapositiontaking_1_max-@v8mpositiontaking_1 ELSE @v8apositiontaking_1 END END,
	@v8apositiontaking_3 = CASE WHEN @isauto_v8mpositiontaking_3 > 0 THEN @v8apositiontaking_3 ELSE CASE WHEN @v8apositiontaking_3+@v8mpositiontaking_3>@v8mapositiontaking_3_max THEN @v8mapositiontaking_3_max-@v8mpositiontaking_3 ELSE @v8apositiontaking_3 END END,
	@v8apositiontaking_20 = CASE WHEN @isauto_v8mpositiontaking_20 > 0 THEN @v8apositiontaking_20 ELSE CASE WHEN @v8apositiontaking_20+@v8mpositiontaking_20>@v8mapositiontaking_20_max THEN @v8mapositiontaking_20_max-@v8mpositiontaking_20 ELSE @v8apositiontaking_20 END END,

	@v10apositiontaking_1 = CASE WHEN @isauto_v10mpositiontaking_1 > 0 THEN @v10apositiontaking_1 ELSE CASE WHEN @v10apositiontaking_1+@v10mpositiontaking_1>@v10mapositiontaking_1_max THEN @v10mapositiontaking_1_max-@v10mpositiontaking_1 ELSE @v10apositiontaking_1 END END,
	@v10apositiontaking_2 = CASE WHEN @isauto_v10mpositiontaking_2 > 0 THEN @v10apositiontaking_2 ELSE CASE WHEN @v10apositiontaking_2+@v10mpositiontaking_2>@v10mapositiontaking_2_max THEN @v10mapositiontaking_2_max-@v10mpositiontaking_2 ELSE @v10apositiontaking_2 END END,
	@v10apositiontaking_3 = CASE WHEN @isauto_v10mpositiontaking_3 > 0 THEN @v10apositiontaking_3 ELSE CASE WHEN @v10apositiontaking_3+@v10mpositiontaking_3>@v10mapositiontaking_3_max THEN @v10mapositiontaking_3_max-@v10mpositiontaking_3 ELSE @v10apositiontaking_3 END END,
	@v10apositiontaking_20 = CASE WHEN @isauto_v10mpositiontaking_20 > 0 THEN @v10apositiontaking_20 ELSE CASE WHEN @v10apositiontaking_20+@v10mpositiontaking_20>@v10mapositiontaking_20_max THEN @v10mapositiontaking_20_max-@v10mpositiontaking_20 ELSE @v10apositiontaking_20 END END,

	@v11apositiontaking_1 = CASE WHEN @isauto_v11mpositiontaking_1 > 0 THEN @v11apositiontaking_1 ELSE CASE WHEN @v11apositiontaking_1+@v11mpositiontaking_1>@v11mapositiontaking_1_max THEN @v11mapositiontaking_1_max-@v11mpositiontaking_1 ELSE @v11apositiontaking_1 END END,
	@v11apositiontaking_20 = CASE WHEN @isauto_v11mpositiontaking_20 > 0 THEN @v11apositiontaking_20 ELSE CASE WHEN @v11apositiontaking_20+@v11mpositiontaking_20>@v11mapositiontaking_20_max THEN @v11mapositiontaking_20_max-@v11mpositiontaking_20 ELSE @v11apositiontaking_20 END END,

	@v99apositiontaking_1 = CASE WHEN @isauto_v99mpositiontaking_1 > 0 THEN @v99apositiontaking_1 ELSE CASE WHEN @v99apositiontaking_1+@v99mpositiontaking_1>@v99mapositiontaking_1_max THEN @v99mapositiontaking_1_max-@v99mpositiontaking_1 ELSE @v99apositiontaking_1 END END,
	@v99apositiontaking_2 = CASE WHEN @isauto_v99mpositiontaking_2 > 0 THEN @v99apositiontaking_2 ELSE CASE WHEN @v99apositiontaking_2+@v99mpositiontaking_2>@v99mapositiontaking_2_max THEN @v99mapositiontaking_2_max-@v99mpositiontaking_2 ELSE @v99apositiontaking_2 END END,
	@v99apositiontaking_3 = CASE WHEN @isauto_v99mpositiontaking_3 > 0 THEN @v99apositiontaking_3 ELSE CASE WHEN @v99apositiontaking_3+@v99mpositiontaking_3>@v99mapositiontaking_3_max THEN @v99mapositiontaking_3_max-@v99mpositiontaking_3 ELSE @v99apositiontaking_3 END END,
	@v99apositiontaking_20 = CASE WHEN @isauto_v99mpositiontaking_20 > 0 THEN @v99apositiontaking_20 ELSE CASE WHEN @v99apositiontaking_20+@v99mpositiontaking_20>@v99mapositiontaking_20_max THEN @v99mapositiontaking_20_max-@v99mpositiontaking_20 ELSE @v99apositiontaking_20 END END

SELECT 
	@apositiontaking_1 = CASE WHEN @apositiontaking_1<0 THEN 0 ELSE @apositiontaking_1 END,
	@apositiontaking_2 = CASE WHEN @apositiontaking_2<0 THEN 0 ELSE @apositiontaking_2 END,
	@apositiontaking_3 = CASE WHEN @apositiontaking_3<0 THEN 0 ELSE @apositiontaking_3 END,
	@apositiontaking_4 = CASE WHEN @apositiontaking_4<0 THEN 0 ELSE @apositiontaking_4 END,
	@apositiontaking_5 = CASE WHEN @apositiontaking_5<0 THEN 0 ELSE @apositiontaking_5 END,
	@apositiontaking_6 = CASE WHEN @apositiontaking_6<0 THEN 0 ELSE @apositiontaking_6 END,
	@apositiontaking_7 = CASE WHEN @apositiontaking_7<0 THEN 0 ELSE @apositiontaking_7 END,
	@apositiontaking_8 = CASE WHEN @apositiontaking_8<0 THEN 0 ELSE @apositiontaking_8 END,
	@apositiontaking_9 = CASE WHEN @apositiontaking_9<0 THEN 0 ELSE @apositiontaking_9 END,
	@apositiontaking_10 = CASE WHEN @apositiontaking_10<0 THEN 0 ELSE @apositiontaking_10 END,

	@alivepositiontaking_1 = CASE WHEN @alivepositiontaking_1<0 THEN 0 ELSE @alivepositiontaking_1 END,
	@alivepositiontaking_3 = CASE WHEN @alivepositiontaking_3<0 THEN 0 ELSE @alivepositiontaking_3 END,
	@alivepositiontaking_7 = CASE WHEN @alivepositiontaking_7<0 THEN 0 ELSE @alivepositiontaking_7 END,
	@alivepositiontaking_8 = CASE WHEN @alivepositiontaking_8<0 THEN 0 ELSE @alivepositiontaking_8 END,

	@v2apositiontaking_1 = CASE WHEN @v2apositiontaking_1<0 THEN 0 ELSE @v2apositiontaking_1 END,
	@v2apositiontaking_2 = CASE WHEN @v2apositiontaking_2<0 THEN 0 ELSE @v2apositiontaking_2 END,
	@v2apositiontaking_3 = CASE WHEN @v2apositiontaking_3<0 THEN 0 ELSE @v2apositiontaking_3 END,
	@v2apositiontaking_7 = CASE WHEN @v2apositiontaking_7<0 THEN 0 ELSE @v2apositiontaking_7 END,
	@v2apositiontaking_8 = CASE WHEN @v2apositiontaking_8<0 THEN 0 ELSE @v2apositiontaking_8 END,
	@v2apositiontaking_9 = CASE WHEN @v2apositiontaking_9<0 THEN 0 ELSE @v2apositiontaking_9 END,
	@v2apositiontaking_20 = CASE WHEN @v2apositiontaking_20<0 THEN 0 ELSE @v2apositiontaking_20 END,

	@v3apositiontaking_1 = CASE WHEN @v3apositiontaking_1<0 THEN 0 ELSE @v3apositiontaking_1 END,
	@v3apositiontaking_2 = CASE WHEN @v3apositiontaking_2<0 THEN 0 ELSE @v3apositiontaking_2 END,
	@v3apositiontaking_3 = CASE WHEN @v3apositiontaking_3<0 THEN 0 ELSE @v3apositiontaking_3 END,
	@v3apositiontaking_20 = CASE WHEN @v3apositiontaking_20<0 THEN 0 ELSE @v3apositiontaking_20 END,

	@v5apositiontaking_1 = CASE WHEN @v5apositiontaking_1<0 THEN 0 ELSE @v5apositiontaking_1 END,
	@v5apositiontaking_2 = CASE WHEN @v5apositiontaking_2<0 THEN 0 ELSE @v5apositiontaking_2 END,
	@v5apositiontaking_3 = CASE WHEN @v5apositiontaking_3<0 THEN 0 ELSE @v5apositiontaking_3 END,
	@v5apositiontaking_20 = CASE WHEN @v5apositiontaking_20<0 THEN 0 ELSE @v5apositiontaking_20 END,

	@v8apositiontaking_1 = CASE WHEN @v8apositiontaking_1<0 THEN 0 ELSE @v8apositiontaking_1 END,
	@v8apositiontaking_3 = CASE WHEN @v8apositiontaking_3<0 THEN 0 ELSE @v8apositiontaking_3 END,
	@v8apositiontaking_20 = CASE WHEN @v8apositiontaking_20<0 THEN 0 ELSE @v8apositiontaking_20 END,

	@v10apositiontaking_1 = CASE WHEN @v10apositiontaking_1<0 THEN 0 ELSE @v10apositiontaking_1 END,
	@v10apositiontaking_2 = CASE WHEN @v10apositiontaking_2<0 THEN 0 ELSE @v10apositiontaking_2 END,
	@v10apositiontaking_3 = CASE WHEN @v10apositiontaking_3<0 THEN 0 ELSE @v10apositiontaking_3 END,
	@v10apositiontaking_20 = CASE WHEN @v10apositiontaking_20<0 THEN 0 ELSE @v10apositiontaking_20 END,

	@v11apositiontaking_1 = CASE WHEN @v11apositiontaking_1<0 THEN 0 ELSE @v11apositiontaking_1 END,
	@v11apositiontaking_20 = CASE WHEN @v11apositiontaking_20<0 THEN 0 ELSE @v11apositiontaking_20 END,

	@v99apositiontaking_1 = CASE WHEN @v99apositiontaking_1<0 THEN 0 ELSE @v99apositiontaking_1 END,
	@v99apositiontaking_2 = CASE WHEN @v99apositiontaking_2<0 THEN 0 ELSE @v99apositiontaking_2 END,
	@v99apositiontaking_3 = CASE WHEN @v99apositiontaking_3<0 THEN 0 ELSE @v99apositiontaking_3 END,
	@v99apositiontaking_20 = CASE WHEN @v99apositiontaking_20<0 THEN 0 ELSE @v99apositiontaking_20 END


---------------------------------------------------------------------------------------------------------------------------------------------
----------------***Use Master Auto Position Taking***----------------------------------
--use @auto_mpt at agent
--@max_mpt = @maxdownlinepos + mpt ; pt: positiontaking
--if u2 = 0 then m1 = m2
--else	if u2 < m3 - a1 then m1 = u2
--		else m1 = m3 - a1

select @mpositiontaking_1 = case when isnull(@isauto_mpositiontaking_1, 0)=0 then @mpositiontaking_1 else case when @auto_mpositiontaking_1 < @mapositiontaking_1_max - @apositiontaking_1 then @auto_mpositiontaking_1 else @mapositiontaking_1_max - @apositiontaking_1 end end
select @mpositiontaking_3 = case when isnull(@isauto_mpositiontaking_3, 0)=0 then @mpositiontaking_3 else case when @auto_mpositiontaking_3 < @mapositiontaking_3_max - @apositiontaking_3 then @auto_mpositiontaking_3 else @mapositiontaking_3_max - @apositiontaking_3 end end
select @mpositiontaking_7 = case when isnull(@isauto_mpositiontaking_7, 0)=0 then @mpositiontaking_7 else case when @auto_mpositiontaking_7 < @mapositiontaking_7_max - @apositiontaking_7 then @auto_mpositiontaking_7 else @mapositiontaking_7_max - @apositiontaking_7 end end
select @mpositiontaking_8 = case when isnull(@isauto_mpositiontaking_8, 0)=0 then @mpositiontaking_8 else case when @auto_mpositiontaking_8 < @mapositiontaking_8_max - @apositiontaking_8 then @auto_mpositiontaking_8 else @mapositiontaking_8_max - @apositiontaking_8 end end

select @mlivepositiontaking_1 = case when isnull(@isauto_mlivepositiontaking_1, 0)=0 then @mlivepositiontaking_1 else case when @auto_mlivepositiontaking_1 < @malivepositiontaking_1_max - @alivepositiontaking_1 then @auto_mlivepositiontaking_1 else @malivepositiontaking_1_max - @alivepositiontaking_1 end end
select @mlivepositiontaking_3 = case when isnull(@isauto_mlivepositiontaking_3, 0)=0 then @mlivepositiontaking_3 else case when @auto_mlivepositiontaking_3 < @malivepositiontaking_3_max - @alivepositiontaking_3 then @auto_mlivepositiontaking_3 else @malivepositiontaking_3_max - @alivepositiontaking_3 end end
select @mlivepositiontaking_7 = case when isnull(@isauto_mlivepositiontaking_7, 0)=0 then @mlivepositiontaking_7 else case when @auto_mlivepositiontaking_7 < @malivepositiontaking_7_max - @alivepositiontaking_7 then @auto_mlivepositiontaking_7 else @malivepositiontaking_7_max - @alivepositiontaking_7 end end
select @mlivepositiontaking_8 = case when isnull(@isauto_mlivepositiontaking_8, 0)=0 then @mlivepositiontaking_8 else case when @auto_mlivepositiontaking_8 < @malivepositiontaking_8_max - @alivepositiontaking_8 then @auto_mlivepositiontaking_8 else @malivepositiontaking_8_max - @alivepositiontaking_8 end end

select @mpositiontaking_2 = case when isnull(@isauto_mpositiontaking_2, 0)=0 then @mpositiontaking_2 else case when @auto_mpositiontaking_2 < @mapositiontaking_2_max - @apositiontaking_2 then @auto_mpositiontaking_2 else @mapositiontaking_2_max - @apositiontaking_2 end end
select @mpositiontaking_4 = case when isnull(@isauto_mpositiontaking_4, 0)=0 then @mpositiontaking_4 else case when @auto_mpositiontaking_4 < @mapositiontaking_4_max - @apositiontaking_4 then @auto_mpositiontaking_4 else @mapositiontaking_4_max - @apositiontaking_4 end end
select @mpositiontaking_5 = case when isnull(@isauto_mpositiontaking_5, 0)=0 then @mpositiontaking_5 else case when @auto_mpositiontaking_5 < @mapositiontaking_5_max - @apositiontaking_5 then @auto_mpositiontaking_5 else @mapositiontaking_5_max - @apositiontaking_5 end end
select @mpositiontaking_6 = case when isnull(@isauto_mpositiontaking_6, 0)=0 then @mpositiontaking_6 else case when @auto_mpositiontaking_6 < @mapositiontaking_6_max - @apositiontaking_6 then @auto_mpositiontaking_6 else @mapositiontaking_6_max - @apositiontaking_6 end end
select @mpositiontaking_9 = case when isnull(@isauto_mpositiontaking_9, 0)=0 then @mpositiontaking_9 else case when @auto_mpositiontaking_9 < @mapositiontaking_9_max - @apositiontaking_9 then @auto_mpositiontaking_9 else @mapositiontaking_9_max - @apositiontaking_9 end end
select @mpositiontaking_10 = case when isnull(@isauto_mpositiontaking_10, 0)=0 then @mpositiontaking_10 else case when @auto_mpositiontaking_10 < @mapositiontaking_10_max - @apositiontaking_10 then @auto_mpositiontaking_10 else @mapositiontaking_10_max - @apositiontaking_10 end end

select @v2mpositiontaking_1 = case when isnull(@isauto_v2mpositiontaking_1, 0)=0 then @v2mpositiontaking_1 else case when @auto_v2mpositiontaking_1 < @v2mapositiontaking_1_max - @v2apositiontaking_1 then @auto_v2mpositiontaking_1 else @v2mapositiontaking_1_max - @v2apositiontaking_1 end end
select @v2mpositiontaking_2 = case when isnull(@isauto_v2mpositiontaking_2, 0)=0 then @v2mpositiontaking_2 else case when @auto_v2mpositiontaking_2 < @v2mapositiontaking_2_max - @v2apositiontaking_2 then @auto_v2mpositiontaking_2 else @v2mapositiontaking_2_max - @v2apositiontaking_2 end end
select @v2mpositiontaking_3 = case when isnull(@isauto_v2mpositiontaking_3, 0)=0 then @v2mpositiontaking_3 else case when @auto_v2mpositiontaking_3 < @v2mapositiontaking_3_max - @v2apositiontaking_3 then @auto_v2mpositiontaking_3 else @v2mapositiontaking_3_max - @v2apositiontaking_3 end end
select @v2mpositiontaking_7 = case when isnull(@isauto_v2mpositiontaking_7, 0)=0 then @v2mpositiontaking_7 else case when @auto_v2mpositiontaking_7 < @v2mapositiontaking_7_max - @v2apositiontaking_7 then @auto_v2mpositiontaking_7 else @v2mapositiontaking_7_max - @v2apositiontaking_7 end end
select @v2mpositiontaking_8 = case when isnull(@isauto_v2mpositiontaking_8, 0)=0 then @v2mpositiontaking_8 else case when @auto_v2mpositiontaking_8 < @v2mapositiontaking_8_max - @v2apositiontaking_8 then @auto_v2mpositiontaking_8 else @v2mapositiontaking_8_max - @v2apositiontaking_8 end end
select @v2mpositiontaking_9 = case when isnull(@isauto_v2mpositiontaking_9, 0)=0 then @v2mpositiontaking_9 else case when @auto_v2mpositiontaking_9 < @v2mapositiontaking_9_max - @v2apositiontaking_9 then @auto_v2mpositiontaking_9 else @v2mapositiontaking_9_max - @v2apositiontaking_9 end end
select @v2mpositiontaking_20 = case when isnull(@isauto_v2mpositiontaking_20, 0)=0 then @v2mpositiontaking_20 else case when @auto_v2mpositiontaking_20 < @v2mapositiontaking_20_max - @v2apositiontaking_20 then @auto_v2mpositiontaking_20 else @v2mapositiontaking_20_max - @v2apositiontaking_20 end end

select @v3mpositiontaking_1 = case when isnull(@isauto_v3mpositiontaking_1, 0)=0 then @v3mpositiontaking_1 else case when @auto_v3mpositiontaking_1 < @v3mapositiontaking_1_max - @v3apositiontaking_1 then @auto_v3mpositiontaking_1 else @v3mapositiontaking_1_max - @v3apositiontaking_1 end end
select @v3mpositiontaking_2 = case when isnull(@isauto_v3mpositiontaking_2, 0)=0 then @v3mpositiontaking_2 else case when @auto_v3mpositiontaking_2 < @v3mapositiontaking_2_max - @v3apositiontaking_2 then @auto_v3mpositiontaking_2 else @v3mapositiontaking_2_max - @v3apositiontaking_2 end end
select @v3mpositiontaking_3 = case when isnull(@isauto_v3mpositiontaking_3, 0)=0 then @v3mpositiontaking_3 else case when @auto_v3mpositiontaking_3 < @v3mapositiontaking_3_max - @v3apositiontaking_3 then @auto_v3mpositiontaking_3 else @v3mapositiontaking_3_max - @v3apositiontaking_3 end end
select @v3mpositiontaking_20 = case when isnull(@isauto_v3mpositiontaking_20, 0)=0 then @v3mpositiontaking_20 else case when @auto_v3mpositiontaking_20 < @v3mapositiontaking_20_max - @v3apositiontaking_20 then @auto_v3mpositiontaking_20 else @v3mapositiontaking_20_max - @v3apositiontaking_20 end end

select @v5mpositiontaking_1 = case when isnull(@isauto_v5mpositiontaking_1, 0)=0 then @v5mpositiontaking_1 else case when @auto_v5mpositiontaking_1 < @v5mapositiontaking_1_max - @v5apositiontaking_1 then @auto_v5mpositiontaking_1 else @v5mapositiontaking_1_max - @v5apositiontaking_1 end end
select @v5mpositiontaking_2 = case when isnull(@isauto_v5mpositiontaking_2, 0)=0 then @v5mpositiontaking_2 else case when @auto_v5mpositiontaking_2 < @v5mapositiontaking_2_max - @v5apositiontaking_2 then @auto_v5mpositiontaking_2 else @v5mapositiontaking_2_max - @v5apositiontaking_2 end end
select @v5mpositiontaking_3 = case when isnull(@isauto_v5mpositiontaking_3, 0)=0 then @v5mpositiontaking_3 else case when @auto_v5mpositiontaking_3 < @v5mapositiontaking_3_max - @v5apositiontaking_3 then @auto_v5mpositiontaking_3 else @v5mapositiontaking_3_max - @v5apositiontaking_3 end end
select @v5mpositiontaking_20 = case when isnull(@isauto_v5mpositiontaking_20, 0)=0 then @v5mpositiontaking_20 else case when @auto_v5mpositiontaking_20 < @v5mapositiontaking_20_max - @v5apositiontaking_20 then @auto_v5mpositiontaking_20 else @v5mapositiontaking_20_max - @v5apositiontaking_20 end end

select @v8mpositiontaking_1 = case when isnull(@isauto_v8mpositiontaking_1, 0)=0 then @v8mpositiontaking_1 else case when @auto_v8mpositiontaking_1 < @v8mapositiontaking_1_max - @v8apositiontaking_1 then @auto_v8mpositiontaking_1 else @v8mapositiontaking_1_max - @v8apositiontaking_1 end end
select @v8mpositiontaking_3 = case when isnull(@isauto_v8mpositiontaking_3, 0)=0 then @v8mpositiontaking_3 else case when @auto_v8mpositiontaking_3 < @v8mapositiontaking_3_max - @v8apositiontaking_3 then @auto_v8mpositiontaking_3 else @v8mapositiontaking_3_max - @v8apositiontaking_3 end end
select @v8mpositiontaking_20 = case when isnull(@isauto_v8mpositiontaking_20, 0)=0 then @v8mpositiontaking_20 else case when @auto_v8mpositiontaking_20 < @v8mapositiontaking_20_max - @v8apositiontaking_20 then @auto_v8mpositiontaking_20 else @v8mapositiontaking_20_max - @v8apositiontaking_20 end end

select @v10mpositiontaking_1 = case when isnull(@isauto_v10mpositiontaking_1, 0)=0 then @v10mpositiontaking_1 else case when @auto_v10mpositiontaking_1 < @v10mapositiontaking_1_max - @v10apositiontaking_1 then @auto_v10mpositiontaking_1 else @v10mapositiontaking_1_max - @v10apositiontaking_1 end end
select @v10mpositiontaking_2 = case when isnull(@isauto_v10mpositiontaking_2, 0)=0 then @v10mpositiontaking_2 else case when @auto_v10mpositiontaking_2 < @v10mapositiontaking_2_max - @v10apositiontaking_2 then @auto_v10mpositiontaking_2 else @v10mapositiontaking_2_max - @v10apositiontaking_2 end end
select @v10mpositiontaking_3 = case when isnull(@isauto_v10mpositiontaking_3, 0)=0 then @v10mpositiontaking_3 else case when @auto_v10mpositiontaking_3 < @v10mapositiontaking_3_max - @v10apositiontaking_3 then @auto_v10mpositiontaking_3 else @v10mapositiontaking_3_max - @v10apositiontaking_3 end end
select @v10mpositiontaking_20 = case when isnull(@isauto_v10mpositiontaking_20, 0)=0 then @v10mpositiontaking_20 else case when @auto_v10mpositiontaking_20 < @v10mapositiontaking_20_max - @v10apositiontaking_20 then @auto_v10mpositiontaking_20 else @v10mapositiontaking_20_max - @v10apositiontaking_20 end end

select @v11mpositiontaking_1 = case when isnull(@isauto_v11mpositiontaking_1, 0)=0 then @v11mpositiontaking_1 else case when @auto_v11mpositiontaking_1 < @v11mapositiontaking_1_max - @v11apositiontaking_1 then @auto_v11mpositiontaking_1 else @v11mapositiontaking_1_max - @v11apositiontaking_1 end end
select @v11mpositiontaking_20 = case when isnull(@isauto_v11mpositiontaking_20, 0)=0 then @v11mpositiontaking_20 else case when @auto_v11mpositiontaking_20 < @v11mapositiontaking_20_max - @v11apositiontaking_20 then @auto_v11mpositiontaking_20 else @v11mapositiontaking_20_max - @v11apositiontaking_20 end end

select @v99mpositiontaking_1 = case when isnull(@isauto_v99mpositiontaking_1, 0)=0 then @v99mpositiontaking_1 else case when @auto_v99mpositiontaking_1 < @v99mapositiontaking_1_max - @v99apositiontaking_1 then @auto_v99mpositiontaking_1 else @v99mapositiontaking_1_max - @v99apositiontaking_1 end end
select @v99mpositiontaking_2 = case when isnull(@isauto_v99mpositiontaking_2, 0)=0 then @v99mpositiontaking_2 else case when @auto_v99mpositiontaking_2 < @v99mapositiontaking_2_max - @v99apositiontaking_2 then @auto_v99mpositiontaking_2 else @v99mapositiontaking_2_max - @v99apositiontaking_2 end end
select @v99mpositiontaking_3 = case when isnull(@isauto_v99mpositiontaking_3, 0)=0 then @v99mpositiontaking_3 else case when @auto_v99mpositiontaking_3 < @v99mapositiontaking_3_max - @v99apositiontaking_3 then @auto_v99mpositiontaking_3 else @v99mapositiontaking_3_max - @v99apositiontaking_3 end end
select @v99mpositiontaking_20 = case when isnull(@isauto_v99mpositiontaking_20, 0)=0 then @v99mpositiontaking_20 else case when @auto_v99mpositiontaking_20 < @v99mapositiontaking_20_max - @v99apositiontaking_20 then @auto_v99mpositiontaking_20 else @v99mapositiontaking_20_max - @v99apositiontaking_20 end end
--------------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------

----------------***Use Auto Position Taking***----------------------------------
--@max_spt = @maxdownlinepos + spt ; pt: positiontaking
--if @auto_spt = 0 then @spt = @spt  -- Auto pt is not used
--else	if @auto_spt < @max_spt - @mpt - @apt then @spt = @auto_spt
--		else @spt = @max_spt - @mpt - @apt
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
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--REPLACING CHECK MAX SUPER PT ON MEMBER
/*
SELECT @max_spositiontaking_1 = CASE WHEN ISNULL(@isauto_spositiontaking_1, 0)>0 THEN @max_spositiontaking_1 ELSE @max_spositiontaking_1 - @mapositiontaking_1_max END
SELECT @max_spositiontaking_3 = CASE WHEN ISNULL(@isauto_spositiontaking_3, 0)>0 THEN @max_spositiontaking_3 ELSE @max_spositiontaking_3 - @mapositiontaking_3_max END
SELECT @max_spositiontaking_7 = CASE WHEN ISNULL(@isauto_spositiontaking_7, 0)>0 THEN @max_spositiontaking_7 ELSE @max_spositiontaking_7 - @mapositiontaking_7_max END
SELECT @max_spositiontaking_8 = CASE WHEN ISNULL(@isauto_spositiontaking_8, 0)>0 THEN @max_spositiontaking_8 ELSE @max_spositiontaking_8 - @mapositiontaking_8_max END

SELECT @max_slivepositiontaking_1 = CASE WHEN ISNULL(@isauto_slivepositiontaking_1, 0)>0 THEN @max_slivepositiontaking_1 ELSE @max_slivepositiontaking_1 - @malivepositiontaking_1_max END
SELECT @max_slivepositiontaking_3 = CASE WHEN ISNULL(@isauto_slivepositiontaking_3, 0)>0 THEN @max_slivepositiontaking_3 ELSE @max_slivepositiontaking_3 - @malivepositiontaking_3_max END
SELECT @max_slivepositiontaking_7 = CASE WHEN ISNULL(@isauto_slivepositiontaking_7, 0)>0 THEN @max_slivepositiontaking_7 ELSE @max_slivepositiontaking_7 - @malivepositiontaking_7_max END
SELECT @max_slivepositiontaking_8 = CASE WHEN ISNULL(@isauto_slivepositiontaking_8, 0)>0 THEN @max_slivepositiontaking_8 ELSE @max_slivepositiontaking_8 - @malivepositiontaking_8_max END

SELECT @max_spositiontaking_2 = CASE WHEN ISNULL(@isauto_spositiontaking_2, 0)>0 THEN @max_spositiontaking_2 ELSE @max_spositiontaking_2 - @mapositiontaking_2_max END
SELECT @max_spositiontaking_4 = CASE WHEN ISNULL(@isauto_spositiontaking_4, 0)>0 THEN @max_spositiontaking_4 ELSE @max_spositiontaking_4 - @mapositiontaking_4_max END
SELECT @max_spositiontaking_5 = CASE WHEN ISNULL(@isauto_spositiontaking_5, 0)>0 THEN @max_spositiontaking_5 ELSE @max_spositiontaking_5 - @mapositiontaking_5_max END
SELECT @max_spositiontaking_6 = CASE WHEN ISNULL(@isauto_spositiontaking_6, 0)>0 THEN @max_spositiontaking_6 ELSE @max_spositiontaking_6 - @mapositiontaking_6_max END
SELECT @max_spositiontaking_9 = CASE WHEN ISNULL(@isauto_spositiontaking_9, 0)>0 THEN @max_spositiontaking_9 ELSE @max_spositiontaking_9 - @mapositiontaking_9_max END
SELECT @max_spositiontaking_10 = CASE WHEN ISNULL(@isauto_spositiontaking_10, 0)>0 THEN @max_spositiontaking_10 ELSE @max_spositiontaking_10 - @mapositiontaking_10_max END

SELECT @max_v2spositiontaking_1 = CASE WHEN ISNULL(@isauto_v2spositiontaking_1, 0)>0 THEN @max_v2spositiontaking_1 ELSE @max_v2spositiontaking_1 - @v2mapositiontaking_1_max END
SELECT @max_v2spositiontaking_2 = CASE WHEN ISNULL(@isauto_v2spositiontaking_2, 0)>0 THEN @max_v2spositiontaking_2 ELSE @max_v2spositiontaking_2 - @v2mapositiontaking_2_max END
SELECT @max_v2spositiontaking_3 = CASE WHEN ISNULL(@isauto_v2spositiontaking_3, 0)>0 THEN @max_v2spositiontaking_3 ELSE @max_v2spositiontaking_3 - @v2mapositiontaking_3_max END
SELECT @max_v2spositiontaking_7 = CASE WHEN ISNULL(@isauto_v2spositiontaking_7, 0)>0 THEN @max_v2spositiontaking_7 ELSE @max_v2spositiontaking_7 - @v2mapositiontaking_7_max END
SELECT @max_v2spositiontaking_8 = CASE WHEN ISNULL(@isauto_v2spositiontaking_8, 0)>0 THEN @max_v2spositiontaking_8 ELSE @max_v2spositiontaking_8 - @v2mapositiontaking_8_max END
SELECT @max_v2spositiontaking_9 = CASE WHEN ISNULL(@isauto_v2spositiontaking_9, 0)>0 THEN @max_v2spositiontaking_9 ELSE @max_v2spositiontaking_9 - @v2mapositiontaking_9_max END
SELECT @max_v2spositiontaking_20 = CASE WHEN ISNULL(@isauto_v2spositiontaking_20, 0)>0 THEN @max_v2spositiontaking_20 ELSE @max_v2spositiontaking_20 - @v2mapositiontaking_20_max END

SELECT @max_v3spositiontaking_1 = CASE WHEN ISNULL(@isauto_v3spositiontaking_1, 0)>0 THEN @max_v3spositiontaking_1 ELSE @max_v3spositiontaking_1 - @v3mapositiontaking_1_max END
SELECT @max_v3spositiontaking_2 = CASE WHEN ISNULL(@isauto_v3spositiontaking_2, 0)>0 THEN @max_v3spositiontaking_2 ELSE @max_v3spositiontaking_2 - @v3mapositiontaking_2_max END
SELECT @max_v3spositiontaking_3 = CASE WHEN ISNULL(@isauto_v3spositiontaking_3, 0)>0 THEN @max_v3spositiontaking_3 ELSE @max_v3spositiontaking_3 - @v3mapositiontaking_3_max END
SELECT @max_v3spositiontaking_20 = CASE WHEN ISNULL(@isauto_v3spositiontaking_20, 0)>0 THEN @max_v3spositiontaking_20 ELSE @max_v3spositiontaking_20 - @v3mapositiontaking_20_max END

SELECT @max_v5spositiontaking_1 = CASE WHEN ISNULL(@isauto_v5spositiontaking_1, 0)>0 THEN @max_v5spositiontaking_1 ELSE @max_v5spositiontaking_1 - @v5mapositiontaking_1_max END
SELECT @max_v5spositiontaking_2 = CASE WHEN ISNULL(@isauto_v5spositiontaking_2, 0)>0 THEN @max_v5spositiontaking_2 ELSE @max_v5spositiontaking_2 - @v5mapositiontaking_2_max END
SELECT @max_v5spositiontaking_3 = CASE WHEN ISNULL(@isauto_v5spositiontaking_3, 0)>0 THEN @max_v5spositiontaking_3 ELSE @max_v5spositiontaking_3 - @v5mapositiontaking_3_max END
SELECT @max_v5spositiontaking_20 = CASE WHEN ISNULL(@isauto_v5spositiontaking_20, 0)>0 THEN @max_v5spositiontaking_20 ELSE @max_v5spositiontaking_20 - @v5mapositiontaking_20_max END

SELECT @max_v8spositiontaking_1 = CASE WHEN ISNULL(@isauto_v8spositiontaking_1, 0)>0 THEN @max_v8spositiontaking_1 ELSE @max_v8spositiontaking_1 - @v8mapositiontaking_1_max END
SELECT @max_v8spositiontaking_3 = CASE WHEN ISNULL(@isauto_v8spositiontaking_3, 0)>0 THEN @max_v8spositiontaking_3 ELSE @max_v8spositiontaking_3 - @v8mapositiontaking_3_max END
SELECT @max_v8spositiontaking_20 = CASE WHEN ISNULL(@isauto_v8spositiontaking_20, 0)>0 THEN @max_v8spositiontaking_20 ELSE @max_v8spositiontaking_20 - @v8mapositiontaking_20_max END

SELECT @max_v10spositiontaking_1 = CASE WHEN ISNULL(@isauto_v10spositiontaking_1, 0)>0 THEN @max_v10spositiontaking_1 ELSE @max_v10spositiontaking_1 - @v10mapositiontaking_1_max END
SELECT @max_v10spositiontaking_2 = CASE WHEN ISNULL(@isauto_v10spositiontaking_2, 0)>0 THEN @max_v10spositiontaking_2 ELSE @max_v10spositiontaking_2 - @v10mapositiontaking_2_max END
SELECT @max_v10spositiontaking_3 = CASE WHEN ISNULL(@isauto_v10spositiontaking_3, 0)>0 THEN @max_v10spositiontaking_3 ELSE @max_v10spositiontaking_3 - @v10mapositiontaking_3_max END
SELECT @max_v10spositiontaking_20 = CASE WHEN ISNULL(@isauto_v10spositiontaking_20, 0)>0 THEN @max_v10spositiontaking_20 ELSE @max_v10spositiontaking_20 - @v10mapositiontaking_20_max END

SELECT @max_v11spositiontaking_1 = CASE WHEN ISNULL(@isauto_v11spositiontaking_1, 0)>0 THEN @max_v11spositiontaking_1 ELSE @max_v11spositiontaking_1 - @v11mapositiontaking_1_max END
SELECT @max_v11spositiontaking_20 = CASE WHEN ISNULL(@isauto_v11spositiontaking_20, 0)>0 THEN @max_v11spositiontaking_20 ELSE @max_v11spositiontaking_20 - @v11mapositiontaking_20_max END

SELECT @max_v12spositiontaking_2 = CASE WHEN ISNULL(@isauto_v12spositiontaking_2, 0)>0 THEN @max_v12spositiontaking_2 ELSE @max_v12spositiontaking_2 - @v12mapositiontaking_2_max END
SELECT @max_v12spositiontaking_21 = CASE WHEN ISNULL(@isauto_v12spositiontaking_21, 0)>0 THEN @max_v12spositiontaking_21 ELSE @max_v12spositiontaking_21 - @v12mapositiontaking_21_max END
SELECT @max_v12spositiontaking_22 = CASE WHEN ISNULL(@isauto_v12spositiontaking_22, 0)>0 THEN @max_v12spositiontaking_22 ELSE @max_v12spositiontaking_22 - @v12mapositiontaking_22_max END

SELECT @max_v99spositiontaking_1 = CASE WHEN ISNULL(@isauto_v99spositiontaking_1, 0)>0 THEN @max_v99spositiontaking_1 ELSE @max_v99spositiontaking_1 - @v99mapositiontaking_1_max END
SELECT @max_v99spositiontaking_2 = CASE WHEN ISNULL(@isauto_v99spositiontaking_2, 0)>0 THEN @max_v99spositiontaking_2 ELSE @max_v99spositiontaking_2 - @v99mapositiontaking_2_max END
SELECT @max_v99spositiontaking_3 = CASE WHEN ISNULL(@isauto_v99spositiontaking_3, 0)>0 THEN @max_v99spositiontaking_3 ELSE @max_v99spositiontaking_3 - @v99mapositiontaking_3_max END
SELECT @max_v99spositiontaking_20 = CASE WHEN ISNULL(@isauto_v99spositiontaking_20, 0)>0 THEN @max_v99spositiontaking_20 ELSE @max_v99spositiontaking_20 - @v99mapositiontaking_20_max END
*/


--max_spositiontaking = if(i1||i3)s4:s4-m1-a1
SELECT @max_spositiontaking_1 = CASE WHEN ISNULL(@isauto_spositiontaking_1, 0)>0 THEN @max_spositiontaking_1 ELSE @max_spositiontaking_1 - @mpositiontaking_1 - @apositiontaking_1 END
SELECT @max_spositiontaking_3 = CASE WHEN ISNULL(@isauto_spositiontaking_3, 0)>0 THEN @max_spositiontaking_3 ELSE @max_spositiontaking_3 - @mpositiontaking_3 - @apositiontaking_3 END
SELECT @max_spositiontaking_7 = CASE WHEN ISNULL(@isauto_spositiontaking_7, 0)>0 THEN @max_spositiontaking_7 ELSE @max_spositiontaking_7 - @mpositiontaking_7 - @apositiontaking_7 END
SELECT @max_spositiontaking_8 = CASE WHEN ISNULL(@isauto_spositiontaking_8, 0)>0 THEN @max_spositiontaking_8 ELSE @max_spositiontaking_8 - @mpositiontaking_8 - @apositiontaking_8 END

SELECT @max_slivepositiontaking_1 = CASE WHEN ISNULL(@isauto_slivepositiontaking_1, 0)>0 THEN @max_slivepositiontaking_1 ELSE @max_slivepositiontaking_1 - @mlivepositiontaking_1 - @alivepositiontaking_1 END
SELECT @max_slivepositiontaking_3 = CASE WHEN ISNULL(@isauto_slivepositiontaking_3, 0)>0 THEN @max_slivepositiontaking_3 ELSE @max_slivepositiontaking_3 - @mlivepositiontaking_3 - @alivepositiontaking_3 END
SELECT @max_slivepositiontaking_7 = CASE WHEN ISNULL(@isauto_slivepositiontaking_7, 0)>0 THEN @max_slivepositiontaking_7 ELSE @max_slivepositiontaking_7 - @mlivepositiontaking_7 - @alivepositiontaking_7 END
SELECT @max_slivepositiontaking_8 = CASE WHEN ISNULL(@isauto_slivepositiontaking_8, 0)>0 THEN @max_slivepositiontaking_8 ELSE @max_slivepositiontaking_8 - @mlivepositiontaking_8 - @alivepositiontaking_8 END

SELECT @max_spositiontaking_2 = CASE WHEN ISNULL(@isauto_spositiontaking_2, 0)>0 THEN @max_spositiontaking_2 ELSE @max_spositiontaking_2 - @mpositiontaking_2 - @apositiontaking_2 END
SELECT @max_spositiontaking_4 = CASE WHEN ISNULL(@isauto_spositiontaking_4, 0)>0 THEN @max_spositiontaking_4 ELSE @max_spositiontaking_4 - @mpositiontaking_4 - @apositiontaking_4 END
SELECT @max_spositiontaking_5 = CASE WHEN ISNULL(@isauto_spositiontaking_5, 0)>0 THEN @max_spositiontaking_5 ELSE @max_spositiontaking_5 - @mpositiontaking_5 - @apositiontaking_5 END
SELECT @max_spositiontaking_6 = CASE WHEN ISNULL(@isauto_spositiontaking_6, 0)>0 THEN @max_spositiontaking_6 ELSE @max_spositiontaking_6 - @mpositiontaking_6 - @apositiontaking_6 END
SELECT @max_spositiontaking_9 = CASE WHEN ISNULL(@isauto_spositiontaking_9, 0)>0 THEN @max_spositiontaking_9 ELSE @max_spositiontaking_9 - @mpositiontaking_9 - @apositiontaking_9 END
SELECT @max_spositiontaking_10 = CASE WHEN ISNULL(@isauto_spositiontaking_10, 0)>0 THEN @max_spositiontaking_10 ELSE @max_spositiontaking_10 - @mpositiontaking_10 - @apositiontaking_10 END

SELECT @max_v2spositiontaking_1 = CASE WHEN ISNULL(@isauto_v2spositiontaking_1, 0)>0 THEN @max_v2spositiontaking_1 ELSE @max_v2spositiontaking_1 - @v2mpositiontaking_1 - @v2apositiontaking_1 END
SELECT @max_v2spositiontaking_2 = CASE WHEN ISNULL(@isauto_v2spositiontaking_2, 0)>0 THEN @max_v2spositiontaking_2 ELSE @max_v2spositiontaking_2 - @v2mpositiontaking_2 - @v2apositiontaking_2 END
SELECT @max_v2spositiontaking_3 = CASE WHEN ISNULL(@isauto_v2spositiontaking_3, 0)>0 THEN @max_v2spositiontaking_3 ELSE @max_v2spositiontaking_3 - @v2mpositiontaking_3 - @v2apositiontaking_3 END
SELECT @max_v2spositiontaking_7 = CASE WHEN ISNULL(@isauto_v2spositiontaking_7, 0)>0 THEN @max_v2spositiontaking_7 ELSE @max_v2spositiontaking_7 - @v2mpositiontaking_7 - @v2apositiontaking_7 END
SELECT @max_v2spositiontaking_8 = CASE WHEN ISNULL(@isauto_v2spositiontaking_8, 0)>0 THEN @max_v2spositiontaking_8 ELSE @max_v2spositiontaking_8 - @v2mpositiontaking_8 - @v2apositiontaking_8 END
SELECT @max_v2spositiontaking_9 = CASE WHEN ISNULL(@isauto_v2spositiontaking_9, 0)>0 THEN @max_v2spositiontaking_9 ELSE @max_v2spositiontaking_9 - @v2mpositiontaking_9 - @v2apositiontaking_9 END
SELECT @max_v2spositiontaking_20 = CASE WHEN ISNULL(@isauto_v2spositiontaking_20, 0)>0 THEN @max_v2spositiontaking_20 ELSE @max_v2spositiontaking_20 - @v2mpositiontaking_20 - @v2apositiontaking_20 END

SELECT @max_v3spositiontaking_1 = CASE WHEN ISNULL(@isauto_v3spositiontaking_1, 0)>0 THEN @max_v3spositiontaking_1 ELSE @max_v3spositiontaking_1 - @v3mpositiontaking_1 - @v3apositiontaking_1 END
SELECT @max_v3spositiontaking_2 = CASE WHEN ISNULL(@isauto_v3spositiontaking_2, 0)>0 THEN @max_v3spositiontaking_2 ELSE @max_v3spositiontaking_2 - @v3mpositiontaking_2 - @v3apositiontaking_2 END
SELECT @max_v3spositiontaking_3 = CASE WHEN ISNULL(@isauto_v3spositiontaking_3, 0)>0 THEN @max_v3spositiontaking_3 ELSE @max_v3spositiontaking_3 - @v3mpositiontaking_3 - @v3apositiontaking_3 END
SELECT @max_v3spositiontaking_20 = CASE WHEN ISNULL(@isauto_v3spositiontaking_20, 0)>0 THEN @max_v3spositiontaking_20 ELSE @max_v3spositiontaking_20 - @v3mpositiontaking_20 - @v3apositiontaking_20 END

SELECT @max_v5spositiontaking_1 = CASE WHEN ISNULL(@isauto_v5spositiontaking_1, 0)>0 THEN @max_v5spositiontaking_1 ELSE @max_v5spositiontaking_1 - @v5mpositiontaking_1 - @v5apositiontaking_1 END
SELECT @max_v5spositiontaking_2 = CASE WHEN ISNULL(@isauto_v5spositiontaking_2, 0)>0 THEN @max_v5spositiontaking_2 ELSE @max_v5spositiontaking_2 - @v5mpositiontaking_2 - @v5apositiontaking_2 END
SELECT @max_v5spositiontaking_3 = CASE WHEN ISNULL(@isauto_v5spositiontaking_3, 0)>0 THEN @max_v5spositiontaking_3 ELSE @max_v5spositiontaking_3 - @v5mpositiontaking_3 - @v5apositiontaking_3 END
SELECT @max_v5spositiontaking_20 = CASE WHEN ISNULL(@isauto_v5spositiontaking_20, 0)>0 THEN @max_v5spositiontaking_20 ELSE @max_v5spositiontaking_20 - @v5mpositiontaking_20 - @v5apositiontaking_20 END

SELECT @max_v8spositiontaking_1 = CASE WHEN ISNULL(@isauto_v8spositiontaking_1, 0)>0 THEN @max_v8spositiontaking_1 ELSE @max_v8spositiontaking_1 - @v8mpositiontaking_1 - @v8apositiontaking_1 END
SELECT @max_v8spositiontaking_3 = CASE WHEN ISNULL(@isauto_v8spositiontaking_3, 0)>0 THEN @max_v8spositiontaking_3 ELSE @max_v8spositiontaking_3 - @v8mpositiontaking_3 - @v8apositiontaking_3 END
SELECT @max_v8spositiontaking_20 = CASE WHEN ISNULL(@isauto_v8spositiontaking_20, 0)>0 THEN @max_v8spositiontaking_20 ELSE @max_v8spositiontaking_20 - @v8mpositiontaking_20 - @v8apositiontaking_20 END

SELECT @max_v10spositiontaking_1 = CASE WHEN ISNULL(@isauto_v10spositiontaking_1, 0)>0 THEN @max_v10spositiontaking_1 ELSE @max_v10spositiontaking_1 - @v10mpositiontaking_1 - @v10apositiontaking_1 END
SELECT @max_v10spositiontaking_2 = CASE WHEN ISNULL(@isauto_v10spositiontaking_2, 0)>0 THEN @max_v10spositiontaking_2 ELSE @max_v10spositiontaking_2 - @v10mpositiontaking_2 - @v10apositiontaking_2 END
SELECT @max_v10spositiontaking_3 = CASE WHEN ISNULL(@isauto_v10spositiontaking_3, 0)>0 THEN @max_v10spositiontaking_3 ELSE @max_v10spositiontaking_3 - @v10mpositiontaking_3 - @v10apositiontaking_3 END
SELECT @max_v10spositiontaking_20 = CASE WHEN ISNULL(@isauto_v10spositiontaking_20, 0)>0 THEN @max_v10spositiontaking_20 ELSE @max_v10spositiontaking_20 - @v10mpositiontaking_20 - @v10apositiontaking_20 END

SELECT @max_v11spositiontaking_1 = CASE WHEN ISNULL(@isauto_v11spositiontaking_1, 0)>0 THEN @max_v11spositiontaking_1 ELSE @max_v11spositiontaking_1 - @v11mpositiontaking_1 - @v11apositiontaking_1 END
SELECT @max_v11spositiontaking_20 = CASE WHEN ISNULL(@isauto_v11spositiontaking_20, 0)>0 THEN @max_v11spositiontaking_20 ELSE @max_v11spositiontaking_20 - @v11mpositiontaking_20 - @v11apositiontaking_20 END

SELECT @max_v99spositiontaking_1 = CASE WHEN ISNULL(@isauto_v99spositiontaking_1, 0)>0 THEN @max_v99spositiontaking_1 ELSE @max_v99spositiontaking_1 - @v99mpositiontaking_1 - @v99apositiontaking_1 END
SELECT @max_v99spositiontaking_2 = CASE WHEN ISNULL(@isauto_v99spositiontaking_2, 0)>0 THEN @max_v99spositiontaking_2 ELSE @max_v99spositiontaking_2 - @v99mpositiontaking_2 - @v99apositiontaking_2 END
SELECT @max_v99spositiontaking_3 = CASE WHEN ISNULL(@isauto_v99spositiontaking_3, 0)>0 THEN @max_v99spositiontaking_3 ELSE @max_v99spositiontaking_3 - @v99mpositiontaking_3 - @v99apositiontaking_3 END
SELECT @max_v99spositiontaking_20 = CASE WHEN ISNULL(@isauto_v99spositiontaking_20, 0)>0 THEN @max_v99spositiontaking_20 ELSE @max_v99spositiontaking_20 - @v99mpositiontaking_20 - @v99apositiontaking_20 END
--//REPLACING CHECK MAX SUPER PT ON MEMBER

--s1=min(s1,max_spositiontaking)
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



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------
BEGIN TRANSACTION
---------------------------------------

UPDATE custsetting WITH (ROWLOCK, UPDLOCK)
SET
	apositiontaking = CASE WHEN (@UpdateMultiple = 1 AND ((sporttype=1 AND @UpdatePositiontaking = 0) OR (sporttype=2 AND @UpdatePositiontakingv2 = 0)  OR (sporttype=3 AND @UpdatePositiontakingv3 = 0) OR (sporttype=5 AND @UpdatePositiontakingv5 = 0) OR (sporttype=8 AND @UpdatePositiontakingv8 = 0) OR (sporttype=10 AND @UpdatePositiontakingv10 = 0) OR (sporttype=11 AND @UpdatePositiontakingv11 = 0) OR (sporttype=99 AND @UpdatePositiontakingv99 = 0))) THEN apositiontaking ELSE CASE sporttype WHEN 1 THEN CASE bettype WHEN 1 THEN @apositiontaking_1 WHEN 2 THEN @apositiontaking_2 WHEN 3 THEN @apositiontaking_3 WHEN 4 THEN @apositiontaking_4 WHEN 5 THEN @apositiontaking_5 WHEN 6 THEN @apositiontaking_6 WHEN 7 THEN @apositiontaking_7 WHEN 8 THEN @apositiontaking_8 WHEN 9 THEN @apositiontaking_9 WHEN 10 THEN @apositiontaking_10 ELSE 0 END
					WHEN 2 THEN CASE bettype WHEN 1 THEN @v2apositiontaking_1 WHEN 2 THEN @v2apositiontaking_2 WHEN 3 THEN @v2apositiontaking_3 WHEN 7 THEN @v2apositiontaking_7 WHEN 8 THEN @v2apositiontaking_8 WHEN 9 THEN @v2apositiontaking_9 WHEN 20 THEN @v2apositiontaking_20 ELSE 0 END
					WHEN 3 THEN CASE bettype WHEN 1 THEN @v3apositiontaking_1 WHEN 2 THEN @v3apositiontaking_2 WHEN 3 THEN @v3apositiontaking_3 WHEN 20 THEN @v3apositiontaking_20 ELSE 0 END
					WHEN 5 THEN CASE bettype WHEN 1 THEN @v5apositiontaking_1 WHEN 2 THEN @v5apositiontaking_2 WHEN 3 THEN @v5apositiontaking_3 WHEN 20 THEN @v5apositiontaking_20 ELSE 0 END
					WHEN 8 THEN CASE bettype WHEN 1 THEN @v8apositiontaking_1 WHEN 3 THEN @v8apositiontaking_3 WHEN 20 THEN @v8apositiontaking_20 ELSE 0 END
					WHEN 10 THEN CASE bettype WHEN 1 THEN @v10apositiontaking_1 WHEN 2 THEN @v10apositiontaking_2 WHEN 3 THEN @v10apositiontaking_3 WHEN 20 THEN @v10apositiontaking_20 ELSE 0 END
					WHEN 11 THEN CASE bettype WHEN 1 THEN @v11apositiontaking_1 WHEN 20 THEN @v11apositiontaking_20 ELSE 0 END
					WHEN 99 THEN CASE bettype WHEN 1 THEN @v99apositiontaking_1 WHEN 2 THEN @v99apositiontaking_2 WHEN 3 THEN @v99apositiontaking_3 WHEN 20 THEN @v99apositiontaking_20 ELSE 0 END
					ELSE apositiontaking END END,
	alivepositiontaking = CASE WHEN (@UpdateMultiple = 1 AND ((sporttype=1 AND @UpdatePositiontaking = 0) OR (sporttype=2 AND @UpdatePositiontakingv2 = 0)  OR (sporttype=3 AND @UpdatePositiontakingv3 = 0) OR (sporttype=5 AND @UpdatePositiontakingv5 = 0) OR (sporttype=8 AND @UpdatePositiontakingv8 = 0) OR (sporttype=10 AND @UpdatePositiontakingv10 = 0) OR (sporttype=11 AND @UpdatePositiontakingv11 = 0) OR (sporttype=99 AND @UpdatePositiontakingv99 = 0))) THEN alivepositiontaking ELSE CASE sporttype 	WHEN 1 THEN CASE bettype WHEN 1 THEN @alivepositiontaking_1 WHEN 3 THEN @alivepositiontaking_3 WHEN 7 THEN @alivepositiontaking_7 WHEN 8 THEN @alivepositiontaking_8 ELSE alivepositiontaking END ELSE alivepositiontaking END END,
	
	--Auto Master PT
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	mpositiontaking = CASE WHEN (@UpdateMultiple = 1 AND ((sporttype=1 AND @UpdatePositiontaking = 0) OR (sporttype=2 AND @UpdatePositiontakingv2 = 0)  OR (sporttype=3 AND @UpdatePositiontakingv3 = 0) OR (sporttype=5 AND @UpdatePositiontakingv5 = 0) OR (sporttype=8 AND @UpdatePositiontakingv8 = 0) OR (sporttype=10 AND @UpdatePositiontakingv10 = 0) OR (sporttype=11 AND @UpdatePositiontakingv11 = 0) OR (sporttype=99 AND @UpdatePositiontakingv99 = 0))) THEN mpositiontaking ELSE CASE sporttype WHEN 1 THEN CASE bettype WHEN 1 THEN @mpositiontaking_1 WHEN 2 THEN @mpositiontaking_2 WHEN 3 THEN @mpositiontaking_3 WHEN 4 THEN @mpositiontaking_4 WHEN 5 THEN @mpositiontaking_5 WHEN 6 THEN @mpositiontaking_6 WHEN 7 THEN @mpositiontaking_7 WHEN 8 THEN @mpositiontaking_8 WHEN 9 THEN @mpositiontaking_9 WHEN 10 THEN @mpositiontaking_10 ELSE 0 END
					WHEN 2 THEN CASE bettype WHEN 1 THEN @v2mpositiontaking_1 WHEN 2 THEN @v2mpositiontaking_2 WHEN 3 THEN @v2mpositiontaking_3 WHEN 7 THEN @v2mpositiontaking_7 WHEN 8 THEN @v2mpositiontaking_8 WHEN 9 THEN @v2mpositiontaking_9 WHEN 20 THEN @v2mpositiontaking_20 ELSE 0 END
					WHEN 3 THEN CASE bettype WHEN 1 THEN @v3mpositiontaking_1 WHEN 2 THEN @v3mpositiontaking_2 WHEN 3 THEN @v3mpositiontaking_3 WHEN 20 THEN @v3mpositiontaking_20 ELSE 0 END
					WHEN 5 THEN CASE bettype WHEN 1 THEN @v5mpositiontaking_1 WHEN 2 THEN @v5mpositiontaking_2 WHEN 3 THEN @v5mpositiontaking_3 WHEN 20 THEN @v5mpositiontaking_20 ELSE 0 END
					WHEN 8 THEN CASE bettype WHEN 1 THEN @v8mpositiontaking_1 WHEN 3 THEN @v8mpositiontaking_3 WHEN 20 THEN @v8mpositiontaking_20 ELSE 0 END
					WHEN 10 THEN CASE bettype WHEN 1 THEN @v10mpositiontaking_1 WHEN 2 THEN @v10mpositiontaking_2 WHEN 3 THEN @v10mpositiontaking_3 WHEN 20 THEN @v10mpositiontaking_20 ELSE 0 END
					WHEN 11 THEN CASE bettype WHEN 1 THEN @v11mpositiontaking_1 WHEN 20 THEN @v11mpositiontaking_20 ELSE 0 END
					WHEN 99 THEN CASE bettype WHEN 1 THEN @v99mpositiontaking_1 WHEN 2 THEN @v99mpositiontaking_2 WHEN 3 THEN @v99mpositiontaking_3 WHEN 20 THEN @v99mpositiontaking_20 ELSE 0 END
					ELSE mpositiontaking END END,
	mlivepositiontaking = CASE WHEN ( @UpdateMultiple = 1 AND ((sporttype=1 AND @UpdatePositiontaking = 0) OR (sporttype=2 AND @UpdatePositiontakingv2 = 0) OR (sporttype=3 AND @UpdatePositiontakingv3 = 0) OR (sporttype=5 AND @UpdatePositiontakingv5 = 0) OR (sporttype=8 AND @UpdatePositiontakingv8 = 0) OR (sporttype=10 AND @UpdatePositiontakingv10 = 0) OR (sporttype=11 AND @UpdatePositiontakingv11 = 0) OR (sporttype=99 AND @UpdatePositiontakingv99 = 0))) THEN mlivepositiontaking ELSE CASE sporttype 	WHEN 1 THEN CASE bettype WHEN 1 THEN @mlivepositiontaking_1 WHEN 3 THEN @mlivepositiontaking_3 WHEN 7 THEN @mlivepositiontaking_7 WHEN 8 THEN @mlivepositiontaking_8 ELSE mlivepositiontaking END ELSE mlivepositiontaking END END,
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	spositiontaking = CASE WHEN (@UpdateMultiple = 1 AND ((sporttype=1 AND @UpdatePositiontaking = 0) OR (sporttype=2 AND @UpdatePositiontakingv2 = 0)  OR (sporttype=3 AND @UpdatePositiontakingv3 = 0) OR (sporttype=5 AND @UpdatePositiontakingv5 = 0) OR (sporttype=8 AND @UpdatePositiontakingv8 = 0) OR (sporttype=10 AND @UpdatePositiontakingv10 = 0) OR (sporttype=11 AND @UpdatePositiontakingv11 = 0) OR (sporttype=99 AND @UpdatePositiontakingv99 = 0))) THEN spositiontaking ELSE CASE sporttype WHEN 1 THEN CASE bettype WHEN 1 THEN @spositiontaking_1 WHEN 2 THEN @spositiontaking_2 WHEN 3 THEN @spositiontaking_3 WHEN 4 THEN @spositiontaking_4 WHEN 5 THEN @spositiontaking_5 WHEN 6 THEN @spositiontaking_6 WHEN 7 THEN @spositiontaking_7 WHEN 8 THEN @spositiontaking_8 WHEN 9 THEN @spositiontaking_9 WHEN 10 THEN @spositiontaking_10 ELSE 0 END
					WHEN 2 THEN CASE bettype WHEN 1 THEN @v2spositiontaking_1 WHEN 2 THEN @v2spositiontaking_2 WHEN 3 THEN @v2spositiontaking_3 WHEN 7 THEN @v2spositiontaking_7 WHEN 8 THEN @v2spositiontaking_8 WHEN 9 THEN @v2spositiontaking_9 WHEN 20 THEN @v2spositiontaking_20 ELSE 0 END
					WHEN 3 THEN CASE bettype WHEN 1 THEN @v3spositiontaking_1 WHEN 2 THEN @v3spositiontaking_2 WHEN 3 THEN @v3spositiontaking_3 WHEN 20 THEN @v3spositiontaking_20 ELSE 0 END
					WHEN 5 THEN CASE bettype WHEN 1 THEN @v5spositiontaking_1 WHEN 2 THEN @v5spositiontaking_2 WHEN 3 THEN @v5spositiontaking_3 WHEN 20 THEN @v5spositiontaking_20 ELSE 0 END
					WHEN 8 THEN CASE bettype WHEN 1 THEN @v8spositiontaking_1 WHEN 3 THEN @v8spositiontaking_3 WHEN 20 THEN @v8spositiontaking_20 ELSE 0 END
					WHEN 10 THEN CASE bettype WHEN 1 THEN @v10spositiontaking_1 WHEN 2 THEN @v10spositiontaking_2 WHEN 3 THEN @v10spositiontaking_3 WHEN 20 THEN @v10spositiontaking_20 ELSE 0 END
					WHEN 11 THEN CASE bettype WHEN 1 THEN @v11spositiontaking_1 WHEN 20 THEN @v11spositiontaking_20 ELSE 0 END
					WHEN 99 THEN CASE bettype WHEN 1 THEN @v99spositiontaking_1 WHEN 2 THEN @v99spositiontaking_2 WHEN 3 THEN @v99spositiontaking_3 WHEN 20 THEN @v99spositiontaking_20 ELSE 0 END
					ELSE spositiontaking END END,
	slivepositiontaking = CASE WHEN ( @UpdateMultiple = 1 AND ((sporttype=1 AND @UpdatePositiontaking = 0) OR (sporttype=2 AND @UpdatePositiontakingv2 = 0) OR (sporttype=3 AND @UpdatePositiontakingv3 = 0) OR (sporttype=5 AND @UpdatePositiontakingv5 = 0) OR (sporttype=8 AND @UpdatePositiontakingv8 = 0) OR (sporttype=10 AND @UpdatePositiontakingv10 = 0) OR (sporttype=11 AND @UpdatePositiontakingv11 = 0) OR (sporttype=99 AND @UpdatePositiontakingv99 = 0))) THEN slivepositiontaking ELSE CASE sporttype 	WHEN 1 THEN CASE bettype WHEN 1 THEN @slivepositiontaking_1 WHEN 3 THEN @slivepositiontaking_3 WHEN 7 THEN @slivepositiontaking_7 WHEN 8 THEN @slivepositiontaking_8 ELSE slivepositiontaking END ELSE slivepositiontaking END END
WHERE custid=@custid

EXEC dbo.Acc_CustomerUpdMember_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend

COMMIT TRANSACTION

Declare @LogSPData varchar(5000)
	
Select @LogSPData = '<Acc_CustomerUpdMember_PositionTaking><info UpdMultiple="'+ coalesce(cast(@UpdateMultiple as varchar(50)),space(1)) + '" ' +
'Updpt="'+ coalesce(cast(@UpdatePositiontaking as varchar(50)),space(1)) + '" ' +
'Updptv2="'+ coalesce(cast(@UpdatePositiontakingv2 as varchar(50)),space(1)) + '" ' +
'Updptv3="'+ coalesce(cast(@UpdatePositiontakingv3 as varchar(50)),space(1)) + '" ' +
'Updptv5="'+ coalesce(cast(@UpdatePositiontakingv5 as varchar(50)),space(1)) + '" ' +
'Updptv8="'+ coalesce(cast(@UpdatePositiontakingv8 as varchar(50)),space(1)) + '" ' +
'Updptv10="'+ coalesce(cast(@UpdatePositiontakingv10 as varchar(50)),space(1)) + '" ' +
'Updptv11="'+ coalesce(cast(@UpdatePositiontakingv11 as varchar(50)),space(1)) + '" ' +
'Updptv99="'+ coalesce(cast(@UpdatePositiontakingv99 as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />' +

'<ag apt_1="'+ coalesce(cast(@apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'apt_2="'+ coalesce(cast(@apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'apt_3="'+ coalesce(cast(@apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'apt_4="'+ coalesce(cast(@apositiontaking_4 as varchar(50)),space(1)) + '" ' +
'apt_5="'+ coalesce(cast(@apositiontaking_5 as varchar(50)),space(1)) + '" ' +
'apt_6="'+ coalesce(cast(@apositiontaking_6 as varchar(50)),space(1)) + '" ' +
'apt_7="'+ coalesce(cast(@apositiontaking_7 as varchar(50)),space(1)) + '" ' +
'apt_8="'+ coalesce(cast(@apositiontaking_8 as varchar(50)),space(1)) + '" ' +
'apt_9="'+ coalesce(cast(@apositiontaking_9 as varchar(50)),space(1)) + '" ' +
'apt_10="'+ coalesce(cast(@apositiontaking_10 as varchar(50)),space(1)) + '" ' +
'alivept_1="'+ coalesce(cast(@alivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'alivept_3="'+ coalesce(cast(@alivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'alivept_7="'+ coalesce(cast(@alivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'alivept_8="'+ coalesce(cast(@alivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'v2apt_1="'+ coalesce(cast(@v2apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v2apt_2="'+ coalesce(cast(@v2apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v2apt_3="'+ coalesce(cast(@v2apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v2apt_7="'+ coalesce(cast(@v2apositiontaking_7 as varchar(50)),space(1)) + '" ' +
'v2apt_8="'+ coalesce(cast(@v2apositiontaking_8 as varchar(50)),space(1)) + '" ' +
'v2apt_9="'+ coalesce(cast(@v2apositiontaking_9 as varchar(50)),space(1)) + '" ' +
'v2apt_20="'+ coalesce(cast(@v2apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v3apt_1="'+ coalesce(cast(@v3apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v3apt_2="'+ coalesce(cast(@v3apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v3apt_3="'+ coalesce(cast(@v3apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v3apt_20="'+ coalesce(cast(@v3apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v5apt_1="'+ coalesce(cast(@v5apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v5apt_2="'+ coalesce(cast(@v5apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v5apt_3="'+ coalesce(cast(@v5apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v5apt_20="'+ coalesce(cast(@v5apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v8apt_1="'+ coalesce(cast(@v8apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v8apt_3="'+ coalesce(cast(@v8apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v8apt_20="'+ coalesce(cast(@v8apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v10apt_1="'+ coalesce(cast(@v10apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v10apt_2="'+ coalesce(cast(@v10apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v10apt_3="'+ coalesce(cast(@v10apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v10apt_20="'+ coalesce(cast(@v10apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v11apt_1="'+ coalesce(cast(@v11apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v11apt_20="'+ coalesce(cast(@v11apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v99apt_1="'+ coalesce(cast(@v99apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v99apt_2="'+ coalesce(cast(@v99apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v99apt_3="'+ coalesce(cast(@v99apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v99apt_20="'+ coalesce(cast(@v99apositiontaking_20 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMember_PositionTaking>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 413,
	@TrackingValue = @LogSPData


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_PositionTaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMember_PositionTaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMember_PositionTaking] TO [vnteam]