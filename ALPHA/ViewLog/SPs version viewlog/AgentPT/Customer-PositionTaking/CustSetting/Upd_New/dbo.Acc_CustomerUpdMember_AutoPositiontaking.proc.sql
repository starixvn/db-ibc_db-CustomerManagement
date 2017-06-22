ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_AutoPositiontaking]
	@custid int,
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
	
	@language varchar(2) = 'E',
	@userid int
AS
--@Source Control
/*
Created: 20080515@Thien
Task : Update auto PT at member level
DB: DB02.bodb02
Original:Acc_CustomerUpdAutoPositiontaking_Member

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3 
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090526@Phuc: remove write log.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/



SET NOCOUNT ON
Declare @ErrMsg nvarchar(2000)
Declare @bettype int,
	@autopositiontaking smallmoney, 	
	@isautopositiontaking bit,	
	@old_autopositiontaking smallmoney,
	@old_isautopositiontaking smallmoney,
	
	@autolivepositiontaking smallmoney,
	@isautolivepositiontaking bit,	
	@old_autolivepositiontaking smallmoney,
	@old_isautolivepositiontaking smallmoney,
	
	@maxpos smallmoney,	
	
	@autov2positiontaking smallmoney,
	@isautov2positiontaking bit, 
	@old_autov2positiontaking smallmoney,
	@old_isautov2positiontaking smallmoney,

	@autov3positiontaking smallmoney,
	@isautov3positiontaking bit, 
	@old_autov3positiontaking smallmoney,
	@old_isautov3positiontaking smallmoney,

	@autov5positiontaking smallmoney,
	@isautov5positiontaking bit, 
	@old_autov5positiontaking smallmoney,
	@old_isautov5positiontaking smallmoney,

	@autov8positiontaking smallmoney,
	@isautov8positiontaking bit, 
	@old_autov8positiontaking smallmoney,
	@old_isautov8positiontaking smallmoney,

	@autov10positiontaking smallmoney,
	@isautov10positiontaking bit, 
	@old_autov10positiontaking smallmoney,
	@old_isautov10positiontaking smallmoney,

	@autov11positiontaking smallmoney,
	@isautov11positiontaking bit, 
	@old_autov11positiontaking smallmoney,
	@old_isautov11positiontaking smallmoney,

	@autov99positiontaking smallmoney,
	@isautov99positiontaking bit, 
	@old_autov99positiontaking smallmoney,
	@old_isautov99positiontaking smallmoney,
	
	@srecommend int,
	@mrecommend int
declare 
	@old_auto_spositiontaking_1 smallmoney,
	@old_auto_spositiontaking_2 smallmoney,
	@old_auto_spositiontaking_3 smallmoney,
	@old_auto_spositiontaking_4 smallmoney,
	@old_auto_spositiontaking_5 smallmoney,
	@old_auto_spositiontaking_6 smallmoney,
	@old_auto_spositiontaking_7 smallmoney,
	@old_auto_spositiontaking_8 smallmoney,
	@old_auto_spositiontaking_9 smallmoney,
	@old_auto_spositiontaking_10 smallmoney,
	@old_auto_slivepositiontaking_1 smallmoney,
	@old_auto_slivepositiontaking_3 smallmoney,
	@old_auto_slivepositiontaking_7 smallmoney,
	@old_auto_slivepositiontaking_8 smallmoney,
	
	@old_auto_v2spositiontaking_1 smallmoney,
	@old_auto_v2spositiontaking_2 smallmoney,
	@old_auto_v2spositiontaking_3 smallmoney,
	@old_auto_v2spositiontaking_7 smallmoney,
	@old_auto_v2spositiontaking_8 smallmoney,
	@old_auto_v2spositiontaking_9 smallmoney,
	@old_auto_v2spositiontaking_20 smallmoney,

	@old_auto_v3spositiontaking_1 smallmoney,
	@old_auto_v3spositiontaking_2 smallmoney,
	@old_auto_v3spositiontaking_3 smallmoney,
	@old_auto_v3spositiontaking_20 smallmoney,

	@old_auto_v5spositiontaking_1 smallmoney,
	@old_auto_v5spositiontaking_2 smallmoney,
	@old_auto_v5spositiontaking_3 smallmoney,
	@old_auto_v5spositiontaking_20 smallmoney,

	@old_auto_v8spositiontaking_1 smallmoney,
	@old_auto_v8spositiontaking_3 smallmoney,
	@old_auto_v8spositiontaking_20 smallmoney,

	@old_auto_v10spositiontaking_1 smallmoney,
	@old_auto_v10spositiontaking_2 smallmoney,
	@old_auto_v10spositiontaking_3 smallmoney,
	@old_auto_v10spositiontaking_20 smallmoney,

	@old_auto_v11spositiontaking_1 smallmoney,
	@old_auto_v11spositiontaking_20 smallmoney,

	@old_auto_v99spositiontaking_1 smallmoney,
	@old_auto_v99spositiontaking_2 smallmoney,
	@old_auto_v99spositiontaking_3 smallmoney,
	@old_auto_v99spositiontaking_20 smallmoney,

	@old_isauto_spositiontaking_1 bit,
	@old_isauto_spositiontaking_2 bit,
	@old_isauto_spositiontaking_3 bit,
	@old_isauto_spositiontaking_4 bit,
	@old_isauto_spositiontaking_5 bit,
	@old_isauto_spositiontaking_6 bit,
	@old_isauto_spositiontaking_7 bit,
	@old_isauto_spositiontaking_8 bit,
	@old_isauto_spositiontaking_9 bit,
	@old_isauto_spositiontaking_10 bit,
	
	@old_isauto_slivepositiontaking_1 bit,
	@old_isauto_slivepositiontaking_3 bit,
	@old_isauto_slivepositiontaking_7 bit,
	@old_isauto_slivepositiontaking_8 bit,
	
	@old_isauto_v2spositiontaking_1 bit,
	@old_isauto_v2spositiontaking_2 bit,
	@old_isauto_v2spositiontaking_3 bit,
	@old_isauto_v2spositiontaking_7 bit,
	@old_isauto_v2spositiontaking_8 bit,
	@old_isauto_v2spositiontaking_9 bit,
	@old_isauto_v2spositiontaking_20 bit,

	@old_isauto_v3spositiontaking_1 bit,
	@old_isauto_v3spositiontaking_2 bit,
	@old_isauto_v3spositiontaking_3 bit,
	@old_isauto_v3spositiontaking_20 bit,

	@old_isauto_v5spositiontaking_1 bit,
	@old_isauto_v5spositiontaking_2 bit,
	@old_isauto_v5spositiontaking_3 bit,
	@old_isauto_v5spositiontaking_20 bit,

	@old_isauto_v8spositiontaking_1 bit,
	@old_isauto_v8spositiontaking_3 bit,
	@old_isauto_v8spositiontaking_20 bit,

	@old_isauto_v10spositiontaking_1 bit,
	@old_isauto_v10spositiontaking_2 bit,
	@old_isauto_v10spositiontaking_3 bit,
	@old_isauto_v10spositiontaking_20 bit,

	@old_isauto_v11spositiontaking_1 bit,
	@old_isauto_v11spositiontaking_20 bit,

	@old_isauto_v99spositiontaking_1 bit,
	@old_isauto_v99spositiontaking_2 bit,
	@old_isauto_v99spositiontaking_3 bit,
	@old_isauto_v99spositiontaking_20 bit,

	@master_auto_spositiontaking_1 smallmoney,
	@master_auto_spositiontaking_2 smallmoney,
	@master_auto_spositiontaking_3 smallmoney,
	@master_auto_spositiontaking_4 smallmoney,
	@master_auto_spositiontaking_5 smallmoney,
	@master_auto_spositiontaking_6 smallmoney,
	@master_auto_spositiontaking_7 smallmoney,
	@master_auto_spositiontaking_8 smallmoney,
	@master_auto_spositiontaking_9 smallmoney,
	@master_auto_spositiontaking_10 smallmoney,
	
	@master_auto_slivepositiontaking_1 smallmoney,
	@master_auto_slivepositiontaking_3 smallmoney,
	@master_auto_slivepositiontaking_7 smallmoney,
	@master_auto_slivepositiontaking_8 smallmoney,
	
	@master_auto_v2spositiontaking_1 smallmoney,
	@master_auto_v2spositiontaking_2 smallmoney,
	@master_auto_v2spositiontaking_3 smallmoney,
	@master_auto_v2spositiontaking_7 smallmoney,
	@master_auto_v2spositiontaking_8 smallmoney,
	@master_auto_v2spositiontaking_9 smallmoney,
	@master_auto_v2spositiontaking_20 smallmoney,
	
	@master_auto_v3spositiontaking_1 smallmoney,
	@master_auto_v3spositiontaking_2 smallmoney,
	@master_auto_v3spositiontaking_3 smallmoney,
	@master_auto_v3spositiontaking_20 smallmoney,

	@master_auto_v5spositiontaking_1 smallmoney,
	@master_auto_v5spositiontaking_2 smallmoney,
	@master_auto_v5spositiontaking_3 smallmoney,
	@master_auto_v5spositiontaking_20 smallmoney,

	@master_auto_v8spositiontaking_1 smallmoney,
	@master_auto_v8spositiontaking_3 smallmoney,
	@master_auto_v8spositiontaking_20 smallmoney,

	@master_auto_v10spositiontaking_1 smallmoney,
	@master_auto_v10spositiontaking_2 smallmoney,
	@master_auto_v10spositiontaking_3 smallmoney,
	@master_auto_v10spositiontaking_20 smallmoney,

	@master_auto_v11spositiontaking_1 smallmoney,
	@master_auto_v11spositiontaking_20 smallmoney,

	@master_auto_v99spositiontaking_1 smallmoney,
	@master_auto_v99spositiontaking_2 smallmoney,
	@master_auto_v99spositiontaking_3 smallmoney,
	@master_auto_v99spositiontaking_20 smallmoney,

	@master_isauto_spositiontaking_1 bit,
	@master_isauto_spositiontaking_2 bit,
	@master_isauto_spositiontaking_3 bit,
	@master_isauto_spositiontaking_4 bit,
	@master_isauto_spositiontaking_5 bit,
	@master_isauto_spositiontaking_6 bit,
	@master_isauto_spositiontaking_7 bit,
	@master_isauto_spositiontaking_8 bit,
	@master_isauto_spositiontaking_9 bit,
	@master_isauto_spositiontaking_10 bit,
	
	@master_isauto_slivepositiontaking_1 bit,
	@master_isauto_slivepositiontaking_3 bit,
	@master_isauto_slivepositiontaking_7 bit,
	@master_isauto_slivepositiontaking_8 bit,
	
	@master_isauto_v2spositiontaking_1 bit,
	@master_isauto_v2spositiontaking_2 bit,
	@master_isauto_v2spositiontaking_3 bit,
	@master_isauto_v2spositiontaking_7 bit,
	@master_isauto_v2spositiontaking_8 bit,
	@master_isauto_v2spositiontaking_9 bit,
	@master_isauto_v2spositiontaking_20 bit,

	@master_isauto_v3spositiontaking_1 bit,
	@master_isauto_v3spositiontaking_2 bit,
	@master_isauto_v3spositiontaking_3 bit,
	@master_isauto_v3spositiontaking_20 bit,

	@master_isauto_v5spositiontaking_1 bit,
	@master_isauto_v5spositiontaking_2 bit,
	@master_isauto_v5spositiontaking_3 bit,
	@master_isauto_v5spositiontaking_20 bit,

	@master_isauto_v8spositiontaking_1 bit,
	@master_isauto_v8spositiontaking_3 bit,
	@master_isauto_v8spositiontaking_20 bit,

	@master_isauto_v10spositiontaking_1 bit,
	@master_isauto_v10spositiontaking_2 bit,
	@master_isauto_v10spositiontaking_3 bit,
	@master_isauto_v10spositiontaking_20 bit,

	@master_isauto_v11spositiontaking_1 bit,
	@master_isauto_v11spositiontaking_20 bit,

	@master_isauto_v99spositiontaking_1 bit,
	@master_isauto_v99spositiontaking_2 bit,
	@master_isauto_v99spositiontaking_3 bit,
	@master_isauto_v99spositiontaking_20 bit

--------------------------------------------------------
--Get old Auto PT of Member
select @srecommend = srecommend, @mrecommend = mrecommend from custinfo with (NOLOCK) where custid = @custid
select 	@old_auto_spositiontaking_1	=	autopositiontaking		,	@old_isauto_spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=1
select 	@old_auto_spositiontaking_2	=	autopositiontaking		,	@old_isauto_spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=2
select 	@old_auto_spositiontaking_3	=	autopositiontaking		,	@old_isauto_spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=3
select 	@old_auto_spositiontaking_4	=	autopositiontaking		,	@old_isauto_spositiontaking_4	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=4
select 	@old_auto_spositiontaking_5	=	autopositiontaking		,	@old_isauto_spositiontaking_5	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=5
select 	@old_auto_spositiontaking_6	=	autopositiontaking		,	@old_isauto_spositiontaking_6	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=6
select 	@old_auto_spositiontaking_7	=	autopositiontaking		,	@old_isauto_spositiontaking_7	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=7
select 	@old_auto_spositiontaking_8	=	autopositiontaking		,	@old_isauto_spositiontaking_8	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=8
select 	@old_auto_spositiontaking_9	=	autopositiontaking		,	@old_isauto_spositiontaking_9	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=9
select 	@old_auto_spositiontaking_10	=	autopositiontaking		,	@old_isauto_spositiontaking_10	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=10
select 	@old_auto_slivepositiontaking_1	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_1	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=1
select 	@old_auto_slivepositiontaking_3	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_3	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=3
select 	@old_auto_slivepositiontaking_7	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_7	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=7
select 	@old_auto_slivepositiontaking_8	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_8	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=1	and bettype=8

select 	@old_auto_v2spositiontaking_1	=	autopositiontaking		,	@old_isauto_v2spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=2	and bettype=1
select 	@old_auto_v2spositiontaking_2	=	autopositiontaking		,	@old_isauto_v2spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=2	and bettype=2
select 	@old_auto_v2spositiontaking_3	=	autopositiontaking		,	@old_isauto_v2spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=2	and bettype=3
select 	@old_auto_v2spositiontaking_7	=	autopositiontaking		,	@old_isauto_v2spositiontaking_7	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=2	and bettype=7
select 	@old_auto_v2spositiontaking_8	=	autopositiontaking		,	@old_isauto_v2spositiontaking_8	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=2	and bettype=8
select 	@old_auto_v2spositiontaking_9	=	autopositiontaking		,	@old_isauto_v2spositiontaking_9	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=2	and bettype=9
select 	@old_auto_v2spositiontaking_20	=	autopositiontaking		,	@old_isauto_v2spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=2	and bettype=20

select 	@old_auto_v3spositiontaking_1	=	autopositiontaking		,	@old_isauto_v3spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=3	and bettype=1
select 	@old_auto_v3spositiontaking_2	=	autopositiontaking		,	@old_isauto_v3spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=3	and bettype=2
select 	@old_auto_v3spositiontaking_3	=	autopositiontaking		,	@old_isauto_v3spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=3	and bettype=3
select 	@old_auto_v3spositiontaking_20	=	autopositiontaking		,	@old_isauto_v3spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=3	and bettype=20

select 	@old_auto_v5spositiontaking_1	=	autopositiontaking		,	@old_isauto_v5spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=5	and bettype=1
select 	@old_auto_v5spositiontaking_2	=	autopositiontaking		,	@old_isauto_v5spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=5	and bettype=2
select 	@old_auto_v5spositiontaking_3	=	autopositiontaking		,	@old_isauto_v5spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=5	and bettype=3
select 	@old_auto_v5spositiontaking_20	=	autopositiontaking		,	@old_isauto_v5spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=5	and bettype=20

select 	@old_auto_v8spositiontaking_1	=	autopositiontaking		,	@old_isauto_v8spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=8	and bettype=1
select 	@old_auto_v8spositiontaking_3	=	autopositiontaking		,	@old_isauto_v8spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=8	and bettype=3
select 	@old_auto_v8spositiontaking_20	=	autopositiontaking		,	@old_isauto_v8spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=8	and bettype=20

select 	@old_auto_v10spositiontaking_1	=	autopositiontaking		,	@old_isauto_v10spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=10	and bettype=1
select 	@old_auto_v10spositiontaking_2	=	autopositiontaking		,	@old_isauto_v10spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=10	and bettype=2
select 	@old_auto_v10spositiontaking_3	=	autopositiontaking		,	@old_isauto_v10spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=10	and bettype=3
select 	@old_auto_v10spositiontaking_20	=	autopositiontaking		,	@old_isauto_v10spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=10	and bettype=20

select 	@old_auto_v11spositiontaking_1	=	autopositiontaking		,	@old_isauto_v11spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=11	and bettype=1
select 	@old_auto_v11spositiontaking_20	=	autopositiontaking		,	@old_isauto_v11spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=11	and bettype=20

select 	@old_auto_v99spositiontaking_1	=	autopositiontaking		,	@old_isauto_v99spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=99	and bettype=1
select 	@old_auto_v99spositiontaking_2	=	autopositiontaking		,	@old_isauto_v99spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=99	and bettype=2
select 	@old_auto_v99spositiontaking_3	=	autopositiontaking		,	@old_isauto_v99spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=99	and bettype=3
select 	@old_auto_v99spositiontaking_20	=	autopositiontaking		,	@old_isauto_v99spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @custid and sporttype=99	and bettype=20


--------------------------------------------------------

--------------------------------------------------------
--Get Auto PT of member from Master
select @master_auto_spositiontaking_1 = autopositiontaking, @master_auto_slivepositiontaking_1 = autolivepositiontaking, @master_isauto_spositiontaking_1 = isautopositiontaking, @master_isauto_slivepositiontaking_1 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=1
select @master_auto_spositiontaking_3 = autopositiontaking, @master_auto_slivepositiontaking_3 = autolivepositiontaking, @master_isauto_spositiontaking_3 = isautopositiontaking, @master_isauto_slivepositiontaking_3 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=1
select @master_auto_spositiontaking_7 = autopositiontaking, @master_auto_slivepositiontaking_7 = autolivepositiontaking, @master_isauto_spositiontaking_7 = isautopositiontaking, @master_isauto_slivepositiontaking_7 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=1
select @master_auto_spositiontaking_8 = autopositiontaking, @master_auto_slivepositiontaking_8 = autolivepositiontaking, @master_isauto_spositiontaking_8 = isautopositiontaking, @master_isauto_slivepositiontaking_8 = isautolivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=1
select @master_auto_spositiontaking_2 = autopositiontaking, @master_isauto_spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=1
select @master_auto_spositiontaking_4 = autopositiontaking, @master_isauto_spositiontaking_4 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=4 and sporttype=1
select @master_auto_spositiontaking_5 = autopositiontaking, @master_isauto_spositiontaking_5 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=5 and sporttype=1
select @master_auto_spositiontaking_6 = autopositiontaking, @master_isauto_spositiontaking_6 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=6 and sporttype=1
select @master_auto_spositiontaking_9 = autopositiontaking, @master_isauto_spositiontaking_9 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=1
select @master_auto_spositiontaking_10 = autopositiontaking, @master_isauto_spositiontaking_10 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=10 and sporttype=1

select @master_auto_v2spositiontaking_1 = autopositiontaking, @master_isauto_v2spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=2
select @master_auto_v2spositiontaking_2 = autopositiontaking, @master_isauto_v2spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=2
select @master_auto_v2spositiontaking_3 = autopositiontaking, @master_isauto_v2spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=2
select @master_auto_v2spositiontaking_7 = autopositiontaking, @master_isauto_v2spositiontaking_7 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=2
select @master_auto_v2spositiontaking_8 = autopositiontaking, @master_isauto_v2spositiontaking_8 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=2
select @master_auto_v2spositiontaking_9 = autopositiontaking, @master_isauto_v2spositiontaking_9 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=2
select @master_auto_v2spositiontaking_20 = autopositiontaking, @master_isauto_v2spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=2

select @master_auto_v3spositiontaking_1 = autopositiontaking, @master_isauto_v3spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=3
select @master_auto_v3spositiontaking_2 = autopositiontaking, @master_isauto_v3spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=3
select @master_auto_v3spositiontaking_3 = autopositiontaking, @master_isauto_v3spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=3
select @master_auto_v3spositiontaking_20 = autopositiontaking, @master_isauto_v3spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=3

select @master_auto_v5spositiontaking_1 = autopositiontaking, @master_isauto_v5spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=5
select @master_auto_v5spositiontaking_2 = autopositiontaking, @master_isauto_v5spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=5
select @master_auto_v5spositiontaking_3 = autopositiontaking, @master_isauto_v5spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=5
select @master_auto_v5spositiontaking_20 = autopositiontaking, @master_isauto_v5spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=5

select @master_auto_v8spositiontaking_1 = autopositiontaking, @master_isauto_v8spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=8
select @master_auto_v8spositiontaking_3 = autopositiontaking, @master_isauto_v8spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=8
select @master_auto_v8spositiontaking_20 = autopositiontaking, @master_isauto_v8spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=8

select @master_auto_v10spositiontaking_1 = autopositiontaking, @master_isauto_v10spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=10
select @master_auto_v10spositiontaking_2 = autopositiontaking, @master_isauto_v10spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=10
select @master_auto_v10spositiontaking_3 = autopositiontaking, @master_isauto_v10spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=10
select @master_auto_v10spositiontaking_20 = autopositiontaking, @master_isauto_v10spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=10

select @master_auto_v11spositiontaking_1 = autopositiontaking, @master_isauto_v11spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=11
select @master_auto_v11spositiontaking_20 = autopositiontaking, @master_isauto_v11spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=11

select @master_auto_v99spositiontaking_1 = autopositiontaking, @master_isauto_v99spositiontaking_1 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=99
select @master_auto_v99spositiontaking_2 = autopositiontaking, @master_isauto_v99spositiontaking_2 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=99
select @master_auto_v99spositiontaking_3 = autopositiontaking, @master_isauto_v99spositiontaking_3 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=99
select @master_auto_v99spositiontaking_20 = autopositiontaking, @master_isauto_v99spositiontaking_20 = isautopositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=99


--------------------------------------------------------

	--Update Member account (autopositiontaking field)
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, 1 as sporttype, @auto_spositiontaking_1 as autopositiontaking, @auto_slivepositiontaking_1	as autolivepositiontaking, @isauto_spositiontaking_1 as isautopositiontaking, @isauto_slivepositiontaking_1	as isautolivepositiontaking
				union all 	select 2 as bettype, 1 as sporttype, @auto_spositiontaking_2 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_2 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 3 as bettype, 1 as sporttype, @auto_spositiontaking_3 as autopositiontaking, @auto_slivepositiontaking_3 	as autolivepositiontaking, @isauto_spositiontaking_3 as isautopositiontaking, @isauto_slivepositiontaking_3	as isautolivepositiontaking
				union all 	select 4 as bettype, 1 as sporttype, @auto_spositiontaking_4 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_4 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 5 as bettype, 1 as sporttype, @auto_spositiontaking_5 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_5 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 6 as bettype, 1 as sporttype, @auto_spositiontaking_6 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_6 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 7 as bettype, 1 as sporttype, @auto_spositiontaking_7 as autopositiontaking, @auto_slivepositiontaking_7 	as autolivepositiontaking, @isauto_spositiontaking_7 as isautopositiontaking, @isauto_slivepositiontaking_7	as isautolivepositiontaking
				union all 	select 8 as bettype, 1 as sporttype, @auto_spositiontaking_8 as autopositiontaking, @auto_slivepositiontaking_8 	as autolivepositiontaking, @isauto_spositiontaking_8 as isautopositiontaking, @isauto_slivepositiontaking_8	as isautolivepositiontaking			
				union all 	select 9 as bettype, 1 as sporttype, @auto_spositiontaking_9 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_9 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 10 as bettype, 1 as sporttype, @auto_spositiontaking_10 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_10 as isautopositiontaking, 0				as isautolivepositiontaking
				
				union all 	select 1 as bettype, 2 as sporttype, @auto_v2spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, 2 as sporttype, @auto_v2spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, 2 as sporttype, @auto_v2spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 7 as bettype, 2 as sporttype, @auto_v2spositiontaking_7 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_7 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 8 as bettype, 2 as sporttype, @auto_v2spositiontaking_8 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_8 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 9 as bettype, 2 as sporttype, @auto_v2spositiontaking_9 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_9 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, 2 as sporttype, @auto_v2spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
				
				union all 	select 1 as bettype, 3 as sporttype, @auto_v3spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, 3 as sporttype, @auto_v3spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, 3 as sporttype, @auto_v3spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, 3 as sporttype, @auto_v3spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking

				union all 	select 1 as bettype, 5 as sporttype, @auto_v5spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, 5 as sporttype, @auto_v5spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, 5 as sporttype, @auto_v5spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, 5 as sporttype, @auto_v5spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking

				union all 	select 1 as bettype, 8 as sporttype, @auto_v8spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, 8 as sporttype, @auto_v8spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, 8 as sporttype, @auto_v8spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking

				union all 	select 1 as bettype, 10 as sporttype, @auto_v10spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, 10 as sporttype, @auto_v10spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, 10 as sporttype, @auto_v10spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, 10 as sporttype, @auto_v10spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking

				union all 	select 1 as bettype, 11 as sporttype, @auto_v11spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, 11 as sporttype, @auto_v11spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking

				union all 	select 1 as bettype, 99 as sporttype, @auto_v99spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, 99 as sporttype, @auto_v99spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, 99 as sporttype, @auto_v99spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, 99 as sporttype, @auto_v99spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			
			) as b on b.bettype = custsetting.bettype and b.sporttype = custsetting.sporttype
	where custsetting.custid = @custid
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
		case @Language 
			when 'E' then 'Error updating auto positiontaking'
			when 'CS' then N'更新占成数不成功'
			when 'CT' then N'更新佔成數不成功'
			when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
			when 'J' then N'Error updating auto positiontaking'
			when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
			else N'Error updating auto positiontaking'
		end	
		RaisError (@ErrMsg, 16, 1)
		return
	END
	
	---------------------------------------------------------------------------------------------------------------------------------------------
	--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in master account)
	select 
		@auto_spositiontaking_1 = case when @isauto_spositiontaking_1>0 then @auto_spositiontaking_1 else @master_auto_spositiontaking_1 end,
		@auto_spositiontaking_2 = case when @isauto_spositiontaking_2>0 then @auto_spositiontaking_2 else @master_auto_spositiontaking_2 end,
		@auto_spositiontaking_3 = case when @isauto_spositiontaking_3>0 then @auto_spositiontaking_3 else @master_auto_spositiontaking_3 end,
		@auto_spositiontaking_4 = case when @isauto_spositiontaking_4>0 then @auto_spositiontaking_4 else @master_auto_spositiontaking_4 end,
		@auto_spositiontaking_5 = case when @isauto_spositiontaking_5>0 then @auto_spositiontaking_5 else @master_auto_spositiontaking_5 end,
		@auto_spositiontaking_6 = case when @isauto_spositiontaking_6>0 then @auto_spositiontaking_6 else @master_auto_spositiontaking_6 end,
		@auto_spositiontaking_7 = case when @isauto_spositiontaking_7>0 then @auto_spositiontaking_7 else @master_auto_spositiontaking_7 end,
		@auto_spositiontaking_8 = case when @isauto_spositiontaking_8>0 then @auto_spositiontaking_8 else @master_auto_spositiontaking_8 end,
		@auto_spositiontaking_9 = case when @isauto_spositiontaking_9>0 then @auto_spositiontaking_9 else @master_auto_spositiontaking_9 end,
		@auto_spositiontaking_10 = case when @isauto_spositiontaking_10>0 then @auto_spositiontaking_10 else @master_auto_spositiontaking_10 end,
	
		@auto_slivepositiontaking_1 = case when @isauto_slivepositiontaking_1>0 then @auto_slivepositiontaking_1 else @master_auto_slivepositiontaking_1 end,
		@auto_slivepositiontaking_3 = case when @isauto_slivepositiontaking_3>0 then @auto_slivepositiontaking_3 else @master_auto_slivepositiontaking_3 end,
		@auto_slivepositiontaking_7 = case when @isauto_slivepositiontaking_7>0 then @auto_slivepositiontaking_7 else @master_auto_slivepositiontaking_7 end,
		@auto_slivepositiontaking_8 = case when @isauto_slivepositiontaking_8>0 then @auto_slivepositiontaking_8 else @master_auto_slivepositiontaking_8 end,
	
		@auto_v2spositiontaking_1 = case when @isauto_v2spositiontaking_1>0 then @auto_v2spositiontaking_1 else @master_auto_v2spositiontaking_1 end,
		@auto_v2spositiontaking_2 = case when @isauto_v2spositiontaking_2>0 then @auto_v2spositiontaking_2 else @master_auto_v2spositiontaking_2 end,
		@auto_v2spositiontaking_3 = case when @isauto_v2spositiontaking_3>0 then @auto_v2spositiontaking_3 else @master_auto_v2spositiontaking_3 end,
		@auto_v2spositiontaking_7 = case when @isauto_v2spositiontaking_7>0 then @auto_v2spositiontaking_7 else @master_auto_v2spositiontaking_7 end,
		@auto_v2spositiontaking_8 = case when @isauto_v2spositiontaking_8>0 then @auto_v2spositiontaking_8 else @master_auto_v2spositiontaking_8 end,
		@auto_v2spositiontaking_9 = case when @isauto_v2spositiontaking_9>0 then @auto_v2spositiontaking_9 else @master_auto_v2spositiontaking_9 end,
		@auto_v2spositiontaking_20 = case when @isauto_v2spositiontaking_20>0 then @auto_v2spositiontaking_20 else @master_auto_v2spositiontaking_20 end,

		@isauto_spositiontaking_1 = case when @isauto_spositiontaking_1>0 then @isauto_spositiontaking_1 else @master_isauto_spositiontaking_1 end,
		@isauto_spositiontaking_2 = case when @isauto_spositiontaking_2>0 then @isauto_spositiontaking_2 else @master_isauto_spositiontaking_2 end,
		@isauto_spositiontaking_3 = case when @isauto_spositiontaking_3>0 then @isauto_spositiontaking_3 else @master_isauto_spositiontaking_3 end,
		@isauto_spositiontaking_4 = case when @isauto_spositiontaking_4>0 then @isauto_spositiontaking_4 else @master_isauto_spositiontaking_4 end,
		@isauto_spositiontaking_5 = case when @isauto_spositiontaking_5>0 then @isauto_spositiontaking_5 else @master_isauto_spositiontaking_5 end,
		@isauto_spositiontaking_6 = case when @isauto_spositiontaking_6>0 then @isauto_spositiontaking_6 else @master_isauto_spositiontaking_6 end,
		@isauto_spositiontaking_7 = case when @isauto_spositiontaking_7>0 then @isauto_spositiontaking_7 else @master_isauto_spositiontaking_7 end,
		@isauto_spositiontaking_8 = case when @isauto_spositiontaking_8>0 then @isauto_spositiontaking_8 else @master_isauto_spositiontaking_8 end,
		@isauto_spositiontaking_9 = case when @isauto_spositiontaking_9>0 then @isauto_spositiontaking_9 else @master_isauto_spositiontaking_9 end,
		@isauto_spositiontaking_10 = case when @isauto_spositiontaking_10>0 then @isauto_spositiontaking_10 else @master_isauto_spositiontaking_10 end,
	
		@isauto_slivepositiontaking_1 = case when @isauto_slivepositiontaking_1>0 then @isauto_slivepositiontaking_1 else @master_isauto_slivepositiontaking_1 end,
		@isauto_slivepositiontaking_3 = case when @isauto_slivepositiontaking_3>0 then @isauto_slivepositiontaking_3 else @master_isauto_slivepositiontaking_3 end,
		@isauto_slivepositiontaking_7 = case when @isauto_slivepositiontaking_7>0 then @isauto_slivepositiontaking_7 else @master_isauto_slivepositiontaking_7 end,
		@isauto_slivepositiontaking_8 = case when @isauto_slivepositiontaking_8>0 then @isauto_slivepositiontaking_8 else @master_isauto_slivepositiontaking_8 end,
	
		@isauto_v2spositiontaking_1 = case when @isauto_v2spositiontaking_1>0 then @isauto_v2spositiontaking_1 else @master_isauto_v2spositiontaking_1 end,
		@isauto_v2spositiontaking_2 = case when @isauto_v2spositiontaking_2>0 then @isauto_v2spositiontaking_2 else @master_isauto_v2spositiontaking_2 end,
		@isauto_v2spositiontaking_3 = case when @isauto_v2spositiontaking_3>0 then @isauto_v2spositiontaking_3 else @master_isauto_v2spositiontaking_3 end,
		@isauto_v2spositiontaking_7 = case when @isauto_v2spositiontaking_7>0 then @isauto_v2spositiontaking_7 else @master_isauto_v2spositiontaking_7 end,
		@isauto_v2spositiontaking_8 = case when @isauto_v2spositiontaking_8>0 then @isauto_v2spositiontaking_8 else @master_isauto_v2spositiontaking_8 end,
		@isauto_v2spositiontaking_9 = case when @isauto_v2spositiontaking_9>0 then @isauto_v2spositiontaking_9 else @master_isauto_v2spositiontaking_9 end,
		@isauto_v2spositiontaking_20 = case when @isauto_v2spositiontaking_20>0 then @isauto_v2spositiontaking_20 else @master_isauto_v2spositiontaking_20 end,

		@isauto_v3spositiontaking_1 = case when @isauto_v3spositiontaking_1>0 then @isauto_v3spositiontaking_1 else @master_isauto_v3spositiontaking_1 end,
		@isauto_v3spositiontaking_2 = case when @isauto_v3spositiontaking_2>0 then @isauto_v3spositiontaking_2 else @master_isauto_v3spositiontaking_2 end,
		@isauto_v3spositiontaking_3 = case when @isauto_v3spositiontaking_3>0 then @isauto_v3spositiontaking_3 else @master_isauto_v3spositiontaking_3 end,
		@isauto_v3spositiontaking_20 = case when @isauto_v3spositiontaking_20>0 then @isauto_v3spositiontaking_20 else @master_isauto_v3spositiontaking_20 end,

		@isauto_v5spositiontaking_1 = case when @isauto_v5spositiontaking_1>0 then @isauto_v5spositiontaking_1 else @master_isauto_v5spositiontaking_1 end,
		@isauto_v5spositiontaking_2 = case when @isauto_v5spositiontaking_2>0 then @isauto_v5spositiontaking_2 else @master_isauto_v5spositiontaking_2 end,
		@isauto_v5spositiontaking_3 = case when @isauto_v5spositiontaking_3>0 then @isauto_v5spositiontaking_3 else @master_isauto_v5spositiontaking_3 end,
		@isauto_v5spositiontaking_20 = case when @isauto_v5spositiontaking_20>0 then @isauto_v5spositiontaking_20 else @master_isauto_v5spositiontaking_20 end,

		@isauto_v8spositiontaking_1 = case when @isauto_v8spositiontaking_1>0 then @isauto_v8spositiontaking_1 else @master_isauto_v8spositiontaking_1 end,
		@isauto_v8spositiontaking_3 = case when @isauto_v8spositiontaking_3>0 then @isauto_v8spositiontaking_3 else @master_isauto_v8spositiontaking_3 end,
		@isauto_v8spositiontaking_20 = case when @isauto_v8spositiontaking_20>0 then @isauto_v8spositiontaking_20 else @master_isauto_v8spositiontaking_20 end,

		@isauto_v10spositiontaking_1 = case when @isauto_v10spositiontaking_1>0 then @isauto_v10spositiontaking_1 else @master_isauto_v10spositiontaking_1 end,
		@isauto_v10spositiontaking_2 = case when @isauto_v10spositiontaking_2>0 then @isauto_v10spositiontaking_2 else @master_isauto_v10spositiontaking_2 end,
		@isauto_v10spositiontaking_3 = case when @isauto_v10spositiontaking_3>0 then @isauto_v10spositiontaking_3 else @master_isauto_v10spositiontaking_3 end,
		@isauto_v10spositiontaking_20 = case when @isauto_v10spositiontaking_20>0 then @isauto_v10spositiontaking_20 else @master_isauto_v10spositiontaking_20 end,

		@isauto_v11spositiontaking_1 = case when @isauto_v11spositiontaking_1>0 then @isauto_v11spositiontaking_1 else @master_isauto_v11spositiontaking_1 end,
		@isauto_v11spositiontaking_20 = case when @isauto_v11spositiontaking_20>0 then @isauto_v11spositiontaking_20 else @master_isauto_v11spositiontaking_20 end,

		@isauto_v99spositiontaking_1 = case when @isauto_v99spositiontaking_1>0 then @isauto_v99spositiontaking_1 else @master_isauto_v99spositiontaking_1 end,
		@isauto_v99spositiontaking_2 = case when @isauto_v99spositiontaking_2>0 then @isauto_v99spositiontaking_2 else @master_isauto_v99spositiontaking_2 end,
		@isauto_v99spositiontaking_3 = case when @isauto_v99spositiontaking_3>0 then @isauto_v99spositiontaking_3 else @master_isauto_v99spositiontaking_3 end,
		@isauto_v99spositiontaking_20 = case when @isauto_v99spositiontaking_20>0 then @isauto_v99spositiontaking_20 else @master_isauto_v99spositiontaking_20 end
	---------------------------------------------------------------------------------------------------------------------------------------------

	--Update member account
	--Using Cursor (spositiontaking field)
	DECLARE CUR CURSOR FOR 
			SELECT 1 AS bettype	,	   @isauto_spositiontaking_1 AS isautopositiontaking	,	  @isauto_slivepositiontaking_1 AS isautolivepositiontaking	,	  @auto_spositiontaking_1 AS autopositiontaking	    ,	   @auto_slivepositiontaking_1 AS autolivepositiontaking	,	  @old_auto_spositiontaking_1 AS old_autopositiontaking		,	   @old_auto_slivepositiontaking_1 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_1 AS old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_1 AS old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_1 AS isautov2positiontaking	,	   @auto_v2spositiontaking_1 AS autov2positiontaking	,		@old_auto_v2spositiontaking_1 AS old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_1 AS old_isautov2positiontaking	,	@isauto_v3spositiontaking_1 AS isautov3positiontaking	,	   @auto_v3spositiontaking_1 AS autov3positiontaking	,	   @old_auto_v3spositiontaking_1 AS old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_1 AS old_isautov3positiontaking	,	@isauto_v5spositiontaking_1 AS isautov5positiontaking	,	   @auto_v5spositiontaking_1 AS autov5positiontaking	,	   @old_auto_v5spositiontaking_1 AS old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_1 AS old_isautov5positiontaking	,	@isauto_v8spositiontaking_1 AS isautov8positiontaking	,	   @auto_v8spositiontaking_1 AS autov8positiontaking	,	   @old_auto_v8spositiontaking_1 AS old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_1 AS old_isautov8positiontaking	,	@isauto_v10spositiontaking_1 AS isautov10positiontaking	,	   @auto_v10spositiontaking_1 AS autov10positiontaking	,	   @old_auto_v10spositiontaking_1 AS old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_1 AS old_isautov10positiontaking	,	@isauto_v11spositiontaking_1 AS isautov11positiontaking	,	   @auto_v11spositiontaking_1 AS autov11positiontaking	,	   @old_auto_v11spositiontaking_1 AS old_autov11positiontaking	,	   @old_isauto_v11spositiontaking_1 AS old_isautov11positiontaking	,	@isauto_v99spositiontaking_1 AS isautov99positiontaking	,	   @auto_v99spositiontaking_1 AS autov99positiontaking	,	   @old_auto_v99spositiontaking_1 AS old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_1 AS old_isautov99positiontaking
UNION ALL  	SELECT 2 AS bettype	,	   @isauto_spositiontaking_2 AS isautopositiontaking	,								0 AS isautolivepositiontaking	,	  @auto_spositiontaking_2 AS autopositiontaking	    ,								 0 AS autolivepositiontaking	,	  @old_auto_spositiontaking_2 AS old_autopositiontaking		,										0 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_2 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_2 AS isautov2positiontaking	,	   @auto_v2spositiontaking_2 AS autov2positiontaking	,		@old_auto_v2spositiontaking_2 AS old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_2 AS old_isautov2positiontaking	,	@isauto_v3spositiontaking_2 AS isautov3positiontaking	,	   @auto_v3spositiontaking_2 AS autov3positiontaking	,	   @old_auto_v3spositiontaking_2 AS old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_2 AS old_isautov3positiontaking	,	@isauto_v5spositiontaking_2 AS isautov5positiontaking	,	   @auto_v5spositiontaking_2 AS autov5positiontaking	,	   @old_auto_v5spositiontaking_2 AS old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_2 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,	@isauto_v10spositiontaking_2 AS isautov10positiontaking	,	   @auto_v10spositiontaking_2 AS autov10positiontaking	,	   @old_auto_v10spositiontaking_2 AS old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_2 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,	@isauto_v99spositiontaking_2 AS isautov99positiontaking	,	   @auto_v99spositiontaking_2 AS autov99positiontaking	,	   @old_auto_v99spositiontaking_2 AS old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_2 AS old_isautov99positiontaking
UNION ALL 	SELECT 3 AS bettype	,	   @isauto_spositiontaking_3 AS isautopositiontaking	,	  @isauto_slivepositiontaking_3 AS isautolivepositiontaking	,	   @auto_spositiontaking_3 AS autopositiontaking	,	   @auto_slivepositiontaking_3 AS autolivepositiontaking	,	  @old_auto_spositiontaking_3 AS old_autopositiontaking		,		@old_auto_slivepositiontaking_3 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_3 AS old_isautopositiontaking	,		@old_isauto_slivepositiontaking_3 AS old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_3 AS isautov2positiontaking	,	   @auto_v2spositiontaking_3 AS autov2positiontaking	,		@old_auto_v2spositiontaking_3 AS old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_3 AS old_isautov2positiontaking	,	@isauto_v3spositiontaking_3 AS isautov3positiontaking	,	   @auto_v3spositiontaking_3 AS autov3positiontaking	,	   @old_auto_v3spositiontaking_3 AS old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_3 AS old_isautov3positiontaking	,	@isauto_v5spositiontaking_3 AS isautov5positiontaking	,	   @auto_v5spositiontaking_3 AS autov5positiontaking	,	   @old_auto_v5spositiontaking_3 AS old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_3 AS old_isautov5positiontaking	,	@isauto_v8spositiontaking_3 AS isautov8positiontaking	,	   @auto_v8spositiontaking_3 AS autov8positiontaking	,	   @old_auto_v8spositiontaking_3 AS old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_3 AS old_isautov8positiontaking	,	@isauto_v10spositiontaking_3 AS isautov10positiontaking	,	   @auto_v10spositiontaking_3 AS autov10positiontaking	,	   @old_auto_v10spositiontaking_3 AS old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_3 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,	@isauto_v99spositiontaking_3 AS isautov99positiontaking	,	   @auto_v99spositiontaking_3 AS autov99positiontaking	,	   @old_auto_v99spositiontaking_3 AS old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_3 AS old_isautov99positiontaking
UNION ALL  	SELECT 4 AS bettype	,	   @isauto_spositiontaking_4 AS isautopositiontaking	,								0 AS isautolivepositiontaking	,	   @auto_spositiontaking_4 AS autopositiontaking	,								 0 AS autolivepositiontaking	,	   @old_auto_spositiontaking_4 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_4 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,									0 AS isautov2positiontaking	,								0 AS autov2positiontaking	,									0 AS old_autov2positiontaking	,									    0 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,								    0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,									    0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking  
UNION ALL 	SELECT 5 AS bettype	,	   @isauto_spositiontaking_5 AS isautopositiontaking	,								0 AS isautolivepositiontaking	,	   @auto_spositiontaking_5 AS autopositiontaking	,								 0 AS autolivepositiontaking	,	   @old_auto_spositiontaking_5 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_5 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,									0 AS isautov2positiontaking	,								0 AS autov2positiontaking	,									0 AS old_autov2positiontaking	,										0 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking
UNION ALL  	SELECT 6 AS bettype	,	   @isauto_spositiontaking_6 AS isautopositiontaking	,								0 AS isautolivepositiontaking	,	   @auto_spositiontaking_6 AS autopositiontaking	,								 0 AS autolivepositiontaking	,	   @old_auto_spositiontaking_6 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_6 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,									0 AS isautov2positiontaking	,								0 AS autov2positiontaking	,									0 AS old_autov2positiontaking	,										0 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking
UNION ALL  	SELECT 7 AS bettype	,	   @isauto_spositiontaking_7 AS isautopositiontaking	,	  @isauto_slivepositiontaking_7 AS isautolivepositiontaking	,	  @auto_spositiontaking_7 AS autopositiontaking	    ,	   @auto_slivepositiontaking_7 AS autolivepositiontaking	,	  @old_auto_spositiontaking_7 AS old_autopositiontaking		,	   @old_auto_slivepositiontaking_7 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_7 AS old_isautopositiontaking	,		@old_isauto_slivepositiontaking_7 AS old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_7 AS isautov2positiontaking	,	   @auto_v2spositiontaking_7 AS autov2positiontaking	,		@old_auto_v2spositiontaking_7 AS old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_7 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								 0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking
UNION ALL  	SELECT 8 AS bettype	,	   @isauto_spositiontaking_8 AS isautopositiontaking	,	  @isauto_slivepositiontaking_8 AS isautolivepositiontaking	,	  @auto_spositiontaking_8 AS autopositiontaking	    ,	   @auto_slivepositiontaking_8 AS autolivepositiontaking	,	  @old_auto_spositiontaking_8 AS old_autopositiontaking		,	   @old_auto_slivepositiontaking_8 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_8 AS old_isautopositiontaking	,		@old_isauto_slivepositiontaking_8 AS old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_8 AS isautov2positiontaking	,	   @auto_v2spositiontaking_8 AS autov2positiontaking	,		@old_auto_v2spositiontaking_8 AS old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_8 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								 0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking
UNION ALL  	SELECT 9 AS bettype	,	   @isauto_spositiontaking_9 AS isautopositiontaking	,								 0 AS isautolivepositiontaking	,	   @auto_spositiontaking_9 AS autopositiontaking	,								 0 AS autolivepositiontaking	,	   @old_auto_spositiontaking_9 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_9 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_9 AS isautov2positiontaking	,	   @auto_v2spositiontaking_9 AS autov2positiontaking	,		@old_auto_v2spositiontaking_9 AS old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_9 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking  
UNION ALL  	SELECT 10 AS bettype,	   @isauto_spositiontaking_10 AS isautopositiontaking	,								  0 AS isautolivepositiontaking	,	   @auto_spositiontaking_10 AS autopositiontaking	,								 0 AS autolivepositiontaking	,	   @old_auto_spositiontaking_10 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,		@old_isauto_spositiontaking_10 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,									0 AS isautov2positiontaking	,								0 AS autov2positiontaking	,									0 AS old_autov2positiontaking	,									   0 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								 0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking
UNION ALL 	SELECT 20 AS bettype,								 0 AS isautopositiontaking	,								  0 AS isautolivepositiontaking	,								0 AS autopositiontaking	,								 0 AS autolivepositiontaking	,								  0 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,									0 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_20 AS isautov2positiontaking	,	   @auto_v2spositiontaking_20 AS autov2positiontaking	,		@old_auto_v2spositiontaking_20 AS old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_20 AS old_isautov2positiontaking	,	@isauto_v3spositiontaking_20 AS isautov3positiontaking	,	   @auto_v3spositiontaking_20 AS autov3positiontaking	,	   @old_auto_v3spositiontaking_20 AS old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_20 AS old_isautov3positiontaking	,	@isauto_v5spositiontaking_20 AS isautov5positiontaking	,	   @auto_v5spositiontaking_20 AS autov5positiontaking	,	   @old_auto_v5spositiontaking_20 AS old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_20 AS old_isautov5positiontaking	,	@isauto_v8spositiontaking_20 AS isautov8positiontaking	,	   @auto_v8spositiontaking_20 AS autov8positiontaking	,	   @old_auto_v8spositiontaking_20 AS old_autov8positiontaking	,		@old_isauto_v8spositiontaking_20 AS old_isautov8positiontaking	,	@isauto_v10spositiontaking_20 AS isautov10positiontaking,	   @auto_v10spositiontaking_20 AS autov10positiontaking	,	   @old_auto_v10spositiontaking_20 AS old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_20 AS old_isautov10positiontaking	,	@isauto_v11spositiontaking_20 AS isautov11positiontaking,	   @auto_v11spositiontaking_20 AS autov11positiontaking	,	   @old_auto_v11spositiontaking_20 AS old_autov11positiontaking	,	   @old_isauto_v11spositiontaking_20 AS old_isautov11positiontaking	,@isauto_v99spositiontaking_20 AS isautov99positiontaking	,	   @auto_v99spositiontaking_20 AS autov99positiontaking	,	   @old_auto_v99spositiontaking_20 AS old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_20 AS old_isautov99positiontaking
UNION ALL  	SELECT 21 AS bettype,								 0 AS isautopositiontaking	,								0 AS isautolivepositiontaking	,								0 AS autopositiontaking	,								 0 AS autolivepositiontaking	,								 0 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,									0 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,									0 AS isautov2positiontaking	,								0 AS autov2positiontaking	,									0 AS old_autov2positiontaking	,										0 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking
UNION ALL  	SELECT 22 AS bettype,								 0 AS isautopositiontaking	,								0 AS isautolivepositiontaking	,							    0 AS autopositiontaking	,								 0 AS autolivepositiontaking	,									0 AS old_autopositiontaking	,										0 AS old_autolivepositiontaking	,									0 AS old_isautopositiontaking	,										0 AS old_isautolivepositiontaking	,									0 AS isautov2positiontaking	,								0 AS autov2positiontaking	,									0 AS old_autov2positiontaking	,										0 AS old_isautov2positiontaking	,								0 AS isautov3positiontaking	,								0 AS autov3positiontaking	,									0 AS old_autov3positiontaking	,										0 AS old_isautov3positiontaking	,								0 AS isautov5positiontaking	,								0 AS autov5positiontaking	,									0 AS old_autov5positiontaking	,										0 AS old_isautov5positiontaking	,								0 AS isautov8positiontaking	,								0 AS autov8positiontaking	,									0 AS old_autov8positiontaking	,										0 AS old_isautov8positiontaking	,							0 AS isautov10positiontaking	,								0 AS autov10positiontaking	,									 0 AS old_autov10positiontaking	,									0 AS old_isautov10positiontaking	,							0 AS isautov11positiontaking	,								0 AS autov11positiontaking	,									0 AS old_autov11positiontaking	,									0 AS old_isautov11positiontaking	,							0 AS isautov99positiontaking	,								0 AS autov99positiontaking	,									0 AS old_autov99positiontaking	,										0 AS old_isautov99positiontaking

	OPEN CUR

	FETCH NEXT FROM CUR INTO
		@bettype, @isautopositiontaking, @isautolivepositiontaking, @autopositiontaking, @autolivepositiontaking, @old_autopositiontaking, @old_autolivepositiontaking, @old_isautopositiontaking, @old_isautolivepositiontaking,
		@isautov2positiontaking, @autov2positiontaking, @old_autov2positiontaking, @old_isautov2positiontaking,	
		@isautov3positiontaking, @autov3positiontaking, @old_autov3positiontaking, @old_isautov3positiontaking,	
		@isautov5positiontaking, @autov5positiontaking, @old_autov5positiontaking, @old_isautov5positiontaking,	
		@isautov8positiontaking, @autov8positiontaking, @old_autov8positiontaking, @old_isautov8positiontaking,	
		@isautov10positiontaking, @autov10positiontaking, @old_autov10positiontaking, @old_isautov10positiontaking,
		@isautov11positiontaking, @autov11positiontaking, @old_autov11positiontaking, @old_isautov11positiontaking,
		@isautov99positiontaking, @autov99positiontaking, @old_autov99positiontaking, @old_isautov99positiontaking
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
--		if @autopositiontaking <> @old_autopositiontaking or @isautopositiontaking <> @old_isautopositiontaking 
--		BEGIN
			if @isautopositiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=1 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking> @autopositiontaking then @autopositiontaking else @maxpos - mpositiontaking-apositiontaking end
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=1
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Soccer)'
							when 'CS' then N'更新占成数不成功(于足球)'
							when 'CT' then N'更新佔成數不成功(於足球)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาฟุตบอล)'
							when 'J' then N'Error updating auto positiontaking (for Soccer)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구)'
							else N'Error updating auto positiontaking (for Soccer)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
--		END
		---------------------------------
		--Update LIVE
		if @bettype in (1,3,7,8) --and (@autolivepositiontaking <> @old_autolivepositiontaking or @isautolivepositiontaking <> @old_isautolivepositiontaking)
		BEGIN
			if @isautolivepositiontaking >0
			BEGIN
				select @maxpos = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=1 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set slivepositiontaking = case when @maxpos - mlivepositiontaking-alivepositiontaking>@autolivepositiontaking then @autolivepositiontaking else @maxpos - mlivepositiontaking-alivepositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=1
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Soccer - LIVE)'
							when 'CS' then N'更新占成数不成功(于足球-现场)'
							when 'CT' then N'更新佔成數不成功(於足球-現場)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ ( สำหรับการเล่นสดขณะแข่งขัน ของฟุตบอล)'
							when 'J' then N'Error updating auto positiontaking (for Soccer - LIVE)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구- 생중계)'
							else N'Error updating auto positiontaking (for Soccer - LIVE)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END		
		---------------------------------
		--Update Basketball
		if @bettype in (1,2,3,7,8,9,20) --and (@autov2positiontaking <> @old_autov2positiontaking or @isautov2positiontaking <> @old_isautov2positiontaking )
		BEGIN
			if @isautov2positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=2 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov2positiontaking then @autov2positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=2
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Basketball)'
							when 'CS' then N'更新占成数不成功(于篮球))'
							when 'CT' then N'更新佔成數不成功(於籃球)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
							when 'J' then N'Error updating auto positiontaking (for Basketball)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구)'
							else N'Error updating auto positiontaking (for Basketball)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END
		
		---------------------------------
		--Update Football
		if @bettype in (1,2,3,20) --and (@autov3positiontaking <> @old_autov3positiontaking or @isautov3positiontaking <> @old_isautov3positiontaking )
		BEGIN
			if @isautov3positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=3 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov3positiontaking then @autov3positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=3
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Football)'
							when 'CS' then N'更新占成数不成功(于美式足球)'
							when 'CT' then N'更新佔成數不成功(於美式足球)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอเมริกันฟุตบอล)'
							when 'J' then N'Error updating auto positiontaking (for Football)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (풋볼)'
							else N'Error updating auto positiontaking (for Football)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END

		---------------------------------
		--Update Tennis
		if @bettype in (1,2,3,20) --and (@autov5positiontaking <> @old_autov5positiontaking or @isautov5positiontaking <> @old_isautov5positiontaking )
		BEGIN
			if @isautov5positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=5 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov5positiontaking then @autov5positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=5
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Tennis)'
							when 'CS' then N'更新占成数不成功(于网球)'
							when 'CT' then N'更新佔成數不成功(於網球)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเทนนิส)'
							when 'J' then N'Error updating auto positiontaking (for Tennis)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (테니스)'
							else N'Error updating auto positiontaking (for Tennis)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END

		---------------------------------
		--Update Baseball
		if @bettype in (1,3,20) --and (@autov8positiontaking <> @old_autov8positiontaking or @isautov8positiontaking <> @old_isautov8positiontaking )
		BEGIN
			if @isautov8positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=8 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov8positiontaking then @autov8positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=8
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Baseball)'
							when 'CS' then N'更新占成数不成功(于棒球)'
							when 'CT' then N'更新佔成數不成功(於棒球)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเบสบอล)'
							when 'J' then N'Error updating auto positiontaking (for Baseball)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (야구)'
							else N'Error updating auto positiontaking (for Baseball)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END

		---------------------------------
		--Update Golf
		if @bettype in (1,2,3,20) --and (@autov10positiontaking <> @old_autov10positiontaking or @isautov10positiontaking <> @old_isautov10positiontaking )
		BEGIN
			if @isautov10positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=10 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov10positiontaking then @autov10positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=10
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Golf)'
							when 'CS' then N'更新占成数不成功(于高尔夫球)'
							when 'CT' then N'更新佔成數不成功(於高爾夫球)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬากอฟล์)'
							when 'J' then N'Error updating auto positiontaking (for Golf)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (골프)'
							else N'Error updating auto positiontaking (for Golf)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END

		---------------------------------
		--Update Motorsports
		if @bettype in (1,20) --and (@autov11positiontaking <> @old_autov11positiontaking or @isautov11positiontaking <> @old_isautov11positiontaking )
		BEGIN
			if @isautov11positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=11 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov11positiontaking then @autov11positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=11
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Motorsports)'
							when 'CS' then N'更新占成数不成功(于赛车)'
							when 'CT' then N'更新佔成數不成功(於賽車)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬารถแข่ง)'
							when 'J' then N'Error updating auto positiontaking (for Motorsports)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (모토스포츠)'
							else N'Error updating auto positiontaking (for Motorsports)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END

		---------------------------------
		--Update Other sports
		if @bettype in (1,2,3,20) --and (@autov99positiontaking <> @old_autov99positiontaking or @isautov99positiontaking <> @old_isautov99positiontaking )
		BEGIN
			if @isautov99positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=99 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov99positiontaking then @autov99positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting
				where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=99
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Other sports)'
							when 'CS' then N'更新占成数不成功(于其他)'
							when 'CT' then N'更新佔成數不成功(於其他'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
							when 'J' then N'Error updating auto positiontaking (for Other sports)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
							else N'Error updating auto positiontaking (for Other sports)'
						end	
					RaisError (@ErrMsg, 16, 1)
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
		END

		---------------------------------	
		FETCH NEXT FROM CUR INTO
			@bettype, @isautopositiontaking, @isautolivepositiontaking, @autopositiontaking, @autolivepositiontaking, @old_autopositiontaking, @old_autolivepositiontaking, @old_isautopositiontaking, @old_isautolivepositiontaking,
			@isautov2positiontaking, @autov2positiontaking, @old_autov2positiontaking, @old_isautov2positiontaking,	
			@isautov3positiontaking, @autov3positiontaking, @old_autov3positiontaking, @old_isautov3positiontaking,	
			@isautov5positiontaking, @autov5positiontaking, @old_autov5positiontaking, @old_isautov5positiontaking,	
			@isautov8positiontaking, @autov8positiontaking, @old_autov8positiontaking, @old_isautov8positiontaking,	
			@isautov10positiontaking, @autov10positiontaking, @old_autov10positiontaking, @old_isautov10positiontaking,
			@isautov11positiontaking, @autov11positiontaking, @old_autov11positiontaking, @old_isautov11positiontaking,
			@isautov99positiontaking, @autov99positiontaking, @old_autov99positiontaking, @old_isautov99positiontaking
	END

	CLOSE CUR
	DEALLOCATE CUR

/*
declare @LogData nvarchar(1000)

Select @LogData = 
	'Super ' + convert(varchar(20), @UserID) + ' update member autopositiontaing ' + convert(varchar(20), @CustID) +
		+ '[old,new] '
		+ 'spos1['+convert(varchar(20), @old_auto_spositiontaking_1)+','+convert(varchar(20), @auto_spositiontaking_1)+']'
		+ 'spos2['+convert(varchar(20), @old_auto_spositiontaking_2)+','+convert(varchar(20), @auto_spositiontaking_2)+']'
		+ 'spos3['+convert(varchar(20), @old_auto_spositiontaking_3)+','+convert(varchar(20), @auto_spositiontaking_3)+']'
		+ 'spos4['+convert(varchar(20), @old_auto_spositiontaking_4)+','+convert(varchar(20), @auto_spositiontaking_4)+']'
		+ 'spos5['+convert(varchar(20), @old_auto_spositiontaking_5)+','+convert(varchar(20), @auto_spositiontaking_5)+']'
		+ 'spos6['+convert(varchar(20), @old_auto_spositiontaking_6)+','+convert(varchar(20), @auto_spositiontaking_6)+']'
		+ 'spos7['+convert(varchar(20), @old_auto_spositiontaking_7)+','+convert(varchar(20), @auto_spositiontaking_7)+']'
		+ 'spos8['+convert(varchar(20), @old_auto_spositiontaking_8)+','+convert(varchar(20), @auto_spositiontaking_8)+']'
		+ 'spos9['+convert(varchar(20), @old_auto_spositiontaking_9)+','+convert(varchar(20), @auto_spositiontaking_9)+']'
		+ 'spos10['+convert(varchar(20), @old_auto_spositiontaking_10)+','+convert(varchar(20), @auto_spositiontaking_10)+']'

		+ 'slpos1['+convert(varchar(20), @old_auto_slivepositiontaking_1)+','+convert(varchar(20), @auto_slivepositiontaking_1)+']'
		+ 'slpos3['+convert(varchar(20), @old_auto_slivepositiontaking_3)+','+convert(varchar(20), @auto_slivepositiontaking_3)+']'
		+ 'slpos7['+convert(varchar(20), @old_auto_slivepositiontaking_7)+','+convert(varchar(20), @auto_slivepositiontaking_7)+']'
		+ 'slpos8['+convert(varchar(20), @old_auto_slivepositiontaking_8)+','+convert(varchar(20), @auto_slivepositiontaking_8)+']'

		+ 'bspos1['+convert(varchar(20), @old_auto_v2spositiontaking_1)+','+convert(varchar(20), @auto_v2spositiontaking_1)+']'
		+ 'bspos2['+convert(varchar(20), @old_auto_v2spositiontaking_2)+','+convert(varchar(20), @auto_v2spositiontaking_2)+']'
		+ 'bspos3['+convert(varchar(20), @old_auto_v2spositiontaking_3)+','+convert(varchar(20), @auto_v2spositiontaking_3)+']'
		+ 'bspos7['+convert(varchar(20), @old_auto_v2spositiontaking_7)+','+convert(varchar(20), @auto_v2spositiontaking_7)+']'
		+ 'bspos8['+convert(varchar(20), @old_auto_v2spositiontaking_8)+','+convert(varchar(20), @auto_v2spositiontaking_8)+']'
		+ 'bspos9['+convert(varchar(20), @old_auto_v2spositiontaking_9)+','+convert(varchar(20), @auto_v2spositiontaking_9)+']'
		+ 'bspos20['+convert(varchar(20), @old_auto_v2spositiontaking_20)+','+convert(varchar(20), @auto_v2spositiontaking_20)+']'

if len(@logdata) >300
BEGIN
	select @logdata = left(@logdata,300)
END
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData


Select @LogData = 
	'Super ' + convert(varchar(20), @UserID) + ' update member isautopositiontaing ' + convert(varchar(20), @custid) +
		+ '[old,new] '
		+ 'isauto1['+convert(varchar(20), @old_isauto_spositiontaking_1)+','+convert(varchar(20), @isauto_spositiontaking_1)+']'
		+ 'isauto2['+convert(varchar(20), @old_isauto_spositiontaking_2)+','+convert(varchar(20), @isauto_spositiontaking_2)+']'
		+ 'isauto3['+convert(varchar(20), @old_isauto_spositiontaking_3)+','+convert(varchar(20), @isauto_spositiontaking_3)+']'
		+ 'isauto4['+convert(varchar(20), @old_isauto_spositiontaking_4)+','+convert(varchar(20), @isauto_spositiontaking_4)+']'
		+ 'isauto5['+convert(varchar(20), @old_isauto_spositiontaking_5)+','+convert(varchar(20), @isauto_spositiontaking_5)+']'
		+ 'isauto6['+convert(varchar(20), @old_isauto_spositiontaking_6)+','+convert(varchar(20), @isauto_spositiontaking_6)+']'
		+ 'isauto7['+convert(varchar(20), @old_isauto_spositiontaking_7)+','+convert(varchar(20), @isauto_spositiontaking_7)+']'
		+ 'isauto8['+convert(varchar(20), @old_isauto_spositiontaking_8)+','+convert(varchar(20), @isauto_spositiontaking_8)+']'
		+ 'isauto9['+convert(varchar(20), @old_isauto_spositiontaking_9)+','+convert(varchar(20), @isauto_spositiontaking_9)+']'
		+ 'isauto10['+convert(varchar(20), @old_isauto_spositiontaking_10)+','+convert(varchar(20), @isauto_spositiontaking_10)+']'

		+ 'islauto1['+convert(varchar(20), @old_isauto_slivepositiontaking_1)+','+convert(varchar(20), @isauto_slivepositiontaking_1)+']'
		+ 'islauto3['+convert(varchar(20), @old_isauto_slivepositiontaking_3)+','+convert(varchar(20), @isauto_slivepositiontaking_3)+']'
		+ 'islauto7['+convert(varchar(20), @old_isauto_slivepositiontaking_7)+','+convert(varchar(20), @isauto_slivepositiontaking_7)+']'
		+ 'islauto8['+convert(varchar(20), @old_isauto_slivepositiontaking_8)+','+convert(varchar(20), @isauto_slivepositiontaking_8)+']'

		+ 'isbauto1['+convert(varchar(20), @old_isauto_v2spositiontaking_1)+','+convert(varchar(20), @isauto_v2spositiontaking_1)+']'
		+ 'isbauto2['+convert(varchar(20), @old_isauto_v2spositiontaking_2)+','+convert(varchar(20), @isauto_v2spositiontaking_2)+']'
		+ 'isbauto3['+convert(varchar(20), @old_isauto_v2spositiontaking_3)+','+convert(varchar(20), @isauto_v2spositiontaking_3)+']'
		+ 'isbauto7['+convert(varchar(20), @old_isauto_v2spositiontaking_7)+','+convert(varchar(20), @isauto_v2spositiontaking_7)+']'
		+ 'isbauto8['+convert(varchar(20), @old_isauto_v2spositiontaking_8)+','+convert(varchar(20), @isauto_v2spositiontaking_8)+']'
		+ 'isbauto9['+convert(varchar(20), @old_isauto_v2spositiontaking_9)+','+convert(varchar(20), @isauto_v2spositiontaking_9)+']'
		+ 'isbauto20['+convert(varchar(20), @old_isauto_v2spositiontaking_20)+','+convert(varchar(20), @isauto_v2spositiontaking_20)+']'

if len(@logdata) >300
BEGIN
	select @logdata = left(@logdata,300)
END
EXEC WriteLog_UserLog @UserID = @UserID, @Doing = @LogData
*/

GO
GRANT VIEW DEFINITION ON [Acc_CustomerUpdMember_AutoPositiontaking] TO vnteam