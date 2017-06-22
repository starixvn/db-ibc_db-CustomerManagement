/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdAutoPositiontaking_Master]    Script Date: 11/05/2007 11:35:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].Acc_CustomerUpdMaster_AutoPositiontaking
	@mrecommend int,
	@srecommend int,
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
	
	@updatemultiple bit = 0,
	@updatepositiontaking bit = 1,
	
	@updatepositiontakingv2 bit = 1,
	@updatepositiontakingv3 bit = 1,
	@updatepositiontakingv5 bit = 1,
	@updatepositiontakingv8 bit = 1,
	@updatepositiontakingv10 bit = 1,
	@updatepositiontakingv11 bit = 1,
	@updatepositiontakingv99 bit = 1,
	

	@language varchar(2),
	@updateallmembers bit = 0,
	@newspositiontaking smallmoney,
	@userid int,
	
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
	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080514@Thien
Task : update auto super PT at master level
DB: DB02.bodb02
Original: Acc_CustomerUpdAutoPositiontaking_Master

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3.
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/


SET NOCOUNT ON
if @updatepositiontaking = 0 and @updatepositiontakingv2 = 0 and @updatepositiontakingv3 = 0 and @updatepositiontakingv5 = 0 and @updatepositiontakingv8 = 0 and @updatepositiontakingv10 = 0 and @updatepositiontakingv11 = 0  and @updatepositiontakingv99 = 0 and @updatemultiple=1
BEGIN
	return
END

Declare
	@bettype int,
	@autopositiontaking smallmoney,
	@autolivepositiontaking smallmoney,
	@old_autopositiontaking smallmoney,
	@old_autolivepositiontaking smallmoney,

	@autov2positiontaking smallmoney,
	@autov3positiontaking smallmoney,
	@autov5positiontaking smallmoney,
	@autov8positiontaking smallmoney,
	@autov10positiontaking smallmoney,
	@autov11positiontaking smallmoney,
	@autov99positiontaking smallmoney,
	
	@old_autov2positiontaking smallmoney,
	@old_autov3positiontaking smallmoney,
	@old_autov5positiontaking smallmoney,
	@old_autov8positiontaking smallmoney,
	@old_autov10positiontaking smallmoney,
	@old_autov11positiontaking smallmoney,
	@old_autov99positiontaking smallmoney,
	
	@maxpos smallmoney,
	@isautopositiontaking bit, 
	@isautolivepositiontaking bit, 
	
	@isautov2positiontaking bit,
	@isautov3positiontaking bit,
	@isautov5positiontaking bit,
	@isautov8positiontaking bit,
	@isautov10positiontaking bit,
	@isautov11positiontaking bit,
	@isautov99positiontaking bit,
	
	@old_isautopositiontaking smallmoney, 
	@old_isautolivepositiontaking smallmoney, 
	
	@old_isautov2positiontaking smallmoney,
	@old_isautov3positiontaking smallmoney,
	@old_isautov5positiontaking smallmoney,
	@old_isautov8positiontaking smallmoney,
	@old_isautov10positiontaking smallmoney,
	@old_isautov11positiontaking smallmoney,
	@old_isautov99positiontaking smallmoney
	
Declare 
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
	@old_isauto_v99spositiontaking_20 bit
--------------------------------------------------------
--Get old Auto PT from Master
select 	@old_auto_spositiontaking_1	=	autopositiontaking		,	@old_isauto_spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	1
select 	@old_auto_spositiontaking_2	=	autopositiontaking		,	@old_isauto_spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	2
select 	@old_auto_spositiontaking_3	=	autopositiontaking		,	@old_isauto_spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	3
select 	@old_auto_spositiontaking_4	=	autopositiontaking		,	@old_isauto_spositiontaking_4	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	4
select 	@old_auto_spositiontaking_5	=	autopositiontaking		,	@old_isauto_spositiontaking_5	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	5
select 	@old_auto_spositiontaking_6	=	autopositiontaking		,	@old_isauto_spositiontaking_6	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	6
select 	@old_auto_spositiontaking_7	=	autopositiontaking		,	@old_isauto_spositiontaking_7	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	7
select 	@old_auto_spositiontaking_8	=	autopositiontaking		,	@old_isauto_spositiontaking_8	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	8
select 	@old_auto_spositiontaking_9	=	autopositiontaking		,	@old_isauto_spositiontaking_9	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	9
select 	@old_auto_spositiontaking_10	=	autopositiontaking		,	@old_isauto_spositiontaking_10	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	10
select 	@old_auto_slivepositiontaking_1	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_1	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	1
select 	@old_auto_slivepositiontaking_3	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_3	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	3
select 	@old_auto_slivepositiontaking_7	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_7	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	7
select 	@old_auto_slivepositiontaking_8	=	autolivepositiontaking		,	@old_isauto_slivepositiontaking_8	=	isautolivepositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype =	1	and bettype=	8

select 	@old_auto_v2spositiontaking_1	=	autopositiontaking		,	@old_isauto_v2spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=2	and bettype=	1
select 	@old_auto_v2spositiontaking_2	=	autopositiontaking		,	@old_isauto_v2spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=2	and bettype=	2
select 	@old_auto_v2spositiontaking_3	=	autopositiontaking		,	@old_isauto_v2spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=2	and bettype=	3
select 	@old_auto_v2spositiontaking_7	=	autopositiontaking		,	@old_isauto_v2spositiontaking_7	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=2	and bettype=	7
select 	@old_auto_v2spositiontaking_8	=	autopositiontaking		,	@old_isauto_v2spositiontaking_8	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=2	and bettype=	8
select 	@old_auto_v2spositiontaking_9	=	autopositiontaking		,	@old_isauto_v2spositiontaking_9	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=2	and bettype=	9
select 	@old_auto_v2spositiontaking_20	=	autopositiontaking		,	@old_isauto_v2spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=2	and bettype=	20

select 	@old_auto_v3spositiontaking_1	=	autopositiontaking		,	@old_isauto_v3spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=3	and bettype=	1
select 	@old_auto_v3spositiontaking_2	=	autopositiontaking		,	@old_isauto_v3spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=3	and bettype=	2
select 	@old_auto_v3spositiontaking_3	=	autopositiontaking		,	@old_isauto_v3spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=3	and bettype=	3
select 	@old_auto_v3spositiontaking_20	=	autopositiontaking		,	@old_isauto_v3spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=3	and bettype=	20

select 	@old_auto_v5spositiontaking_1	=	autopositiontaking		,	@old_isauto_v5spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=5	and bettype=	1
select 	@old_auto_v5spositiontaking_2	=	autopositiontaking		,	@old_isauto_v5spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=5	and bettype=	2
select 	@old_auto_v5spositiontaking_3	=	autopositiontaking		,	@old_isauto_v5spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=5	and bettype=	3
select 	@old_auto_v5spositiontaking_20	=	autopositiontaking		,	@old_isauto_v5spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=5	and bettype=	20

select 	@old_auto_v8spositiontaking_1	=	autopositiontaking		,	@old_isauto_v8spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=8	and bettype=	1
select 	@old_auto_v8spositiontaking_3	=	autopositiontaking		,	@old_isauto_v8spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=8	and bettype=	3
select 	@old_auto_v8spositiontaking_20	=	autopositiontaking		,	@old_isauto_v8spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=8	and bettype=	20

select 	@old_auto_v10spositiontaking_1	=	autopositiontaking		,	@old_isauto_v10spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=10	and bettype=	1
select 	@old_auto_v10spositiontaking_2	=	autopositiontaking		,	@old_isauto_v10spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=10	and bettype=	2
select 	@old_auto_v10spositiontaking_3	=	autopositiontaking		,	@old_isauto_v10spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=10	and bettype=	3
select 	@old_auto_v10spositiontaking_20	=	autopositiontaking		,	@old_isauto_v10spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=10	and bettype=	20

select 	@old_auto_v11spositiontaking_1	=	autopositiontaking		,	@old_isauto_v11spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=11	and bettype=	1
select 	@old_auto_v11spositiontaking_20	=	autopositiontaking		,	@old_isauto_v11spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=11	and bettype=	20

select 	@old_auto_v99spositiontaking_1	=	autopositiontaking		,	@old_isauto_v99spositiontaking_1	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=99	and bettype=	1
select 	@old_auto_v99spositiontaking_2	=	autopositiontaking		,	@old_isauto_v99spositiontaking_2	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=99	and bettype=	2
select 	@old_auto_v99spositiontaking_3	=	autopositiontaking		,	@old_isauto_v99spositiontaking_3	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=99	and bettype=	3
select 	@old_auto_v99spositiontaking_20	=	autopositiontaking		,	@old_isauto_v99spositiontaking_20	=	isautopositiontaking		from custsetting with (nolock) where custid = @mrecommend and sporttype=99	and bettype=	20



if @updatepositiontaking = 1 or @updatemultiple=0
BEGIN
	--Update Master Agent account (autopositiontaking field)
	--For Football
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_spositiontaking_1 as autopositiontaking, @auto_slivepositiontaking_1	as autolivepositiontaking, @isauto_spositiontaking_1 as isautopositiontaking, @isauto_slivepositiontaking_1	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_spositiontaking_2 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_2 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_spositiontaking_3 as autopositiontaking, @auto_slivepositiontaking_3 	as autolivepositiontaking, @isauto_spositiontaking_3 as isautopositiontaking, @isauto_slivepositiontaking_3	as isautolivepositiontaking
				union all 	select 4 as bettype, @auto_spositiontaking_4 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_4 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 5 as bettype, @auto_spositiontaking_5 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_5 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 6 as bettype, @auto_spositiontaking_6 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_6 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 7 as bettype, @auto_spositiontaking_7 as autopositiontaking, @auto_slivepositiontaking_7 	as autolivepositiontaking, @isauto_spositiontaking_7 as isautopositiontaking, @isauto_slivepositiontaking_7	as isautolivepositiontaking
				union all 	select 8 as bettype, @auto_spositiontaking_8 as autopositiontaking, @auto_slivepositiontaking_8 	as autolivepositiontaking, @isauto_spositiontaking_8 as isautopositiontaking, @isauto_slivepositiontaking_8	as isautolivepositiontaking			
				union all 	select 9 as bettype, @auto_spositiontaking_9 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_9 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 10 as bettype, @auto_spositiontaking_10 as autopositiontaking, 0				as autolivepositiontaking, @isauto_spositiontaking_10 as isautopositiontaking, 0				as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=1
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
			,  @ErrCode=201
		return
	END
END
if (@updatepositiontakingv2 = 1 or @updatemultiple=0)
BEGIN
	--Update Master Agent account
	--For Basketball
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_v2spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v2spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v2spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 7 as bettype, @auto_v2spositiontaking_7 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_7 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 8 as bettype, @auto_v2spositiontaking_8 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_8 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 9 as bettype, @auto_v2spositiontaking_9 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_9 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v2spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=2
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Basketball)'
				when 'CS' then N'更新占成数不成功(于篮球)'
				when 'CT' then N'更新佔成數不成功(於籃球)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
				when 'J' then N'Error updating auto positiontaking (for Basketball)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구)'
				else N'Error updating auto positiontaking (for Basketball)'
			end	
			,  @ErrCode=202
		return
	END
END

if (@updatepositiontakingv3 = 1 or @updatemultiple=0)
BEGIN
	--Update Master Agent account
	--For Football
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_v3spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v3spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v3spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v3spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=3
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
			,  @ErrCode=203
		return
	END
END

if (@updatepositiontakingv5 = 1 or @updatemultiple=0)
BEGIN
	--Update Master Agent account
	--For Tennis
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_v5spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v5spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v5spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v5spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=5
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
			,  @ErrCode=204
		return
	END
END

if (@updatepositiontakingv8 = 1 or @updatemultiple=0)
BEGIN
	--Update Master Agent account
	--For Baseball
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_v8spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v8spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v8spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=8
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
			,  @ErrCode=205
		return
	END
END

if (@updatepositiontakingv10 = 1 or @updatemultiple=0)
BEGIN
	--Update Master Agent account
	--For Golf
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_v10spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v10spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v10spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v10spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=10
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
			,  @ErrCode=206
		return
	END
END

if (@updatepositiontakingv11 = 1 or @updatemultiple=0)
BEGIN
	--Update Master Agent account
	--For Motorsports
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_v11spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v11spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=11
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
			,  @ErrCode=207
		return
	END
END

if (@updatepositiontakingv99 = 1 or @updatemultiple=0)
BEGIN
	--Update Master Agent account
	--For Other sports
	update custsetting with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, autolivepositiontaking = b.autolivepositiontaking, isautopositiontaking = b.isautopositiontaking, isautolivepositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
						select 1 as bettype, @auto_v99spositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v99spositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v99spositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v99spositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99spositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @mrecommend and custsetting.sporttype=99
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Other sports)'
				when 'CS' then N'更新占成数不成功(于其他)'
				when 'CT' then N'更新佔成數不成功(於其他)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
				when 'J' then N'Error updating auto positiontaking (for Other sports)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
				else N'Error updating auto positiontaking (for Other sports)'
			end	
			,  @ErrCode=208
		return
	END
END
/*
																																																																																																
		select 1 as bettype	,	   @isauto_spositiontaking_1 as isautopositiontaking	,	  @isauto_slivepositiontaking_1 as isautolivepositiontaking			,	  @auto_spositiontaking_1 as autopositiontaking	,	   @auto_slivepositiontaking_1 as autolivepositiontaking			,	  @old_auto_spositiontaking_1 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_1 as old_autolivepositiontaking			,	  @old_isauto_spositiontaking_1 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_1 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_1 as isautov2positiontaking	,	   @auto_v2spositiontaking_1 as autov2positiontaking	,	   @old_auto_v2spositiontaking_1 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_1 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_1 as isautov2positiontaking	,	   @auto_v2spositiontaking_1 as autov2positiontaking	,	   @old_auto_v2spositiontaking_1 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_1 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_1 as isautov3positiontaking	,	   @auto_v3spositiontaking_1 as autov3positiontaking	,	   @old_auto_v3spositiontaking_1 as old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_1 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_1 as isautov5positiontaking	,	   @auto_v5spositiontaking_1 as autov5positiontaking	,	   @old_auto_v5spositiontaking_1 as old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_1 as old_isautov5positiontaking	,	@isauto_v8spositiontaking_1 as isautov8positiontaking	,	   @auto_v8spositiontaking_1 as autov8positiontaking	,	   @old_auto_v8spositiontaking_1 as old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_1 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_1 as isautov10positiontaking	,	   @auto_v10spositiontaking_1 as autov10positiontaking	,	   @old_auto_v10spositiontaking_1 as old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_1 as old_isautov10positiontaking	,	@isauto_v11spositiontaking_1 as isautov11positiontaking	,	   @auto_v11spositiontaking_1 as autov11positiontaking	,	   @old_auto_v11spositiontaking_1 as old_autov11positiontaking	,	   @old_isauto_v11spositiontaking_1 as old_isautov11positiontaking	,	@isauto_v12spositiontaking_1 as isautov12positiontaking	,	   @auto_v12spositiontaking_1 as autov12positiontaking	,	   0 as old_autov12positiontaking	,	   @old_isauto_v12spositiontaking_1 as old_isautov12positiontaking	,	@isauto_v99spositiontaking_1 as isautov99positiontaking	,	   @auto_v99spositiontaking_1 as autov99positiontaking	,	   @old_auto_v99spositiontaking_1 as old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_1 as old_isautov99positiontaking	
	union all  	select 2 as bettype	,	   @isauto_spositiontaking_2 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	  @auto_spositiontaking_2 as autopositiontaking	,	  0 as autolivepositiontaking			,	  @old_auto_spositiontaking_2 as old_autopositiontaking	,	  0 as old_autolivepositiontaking			,	  @old_isauto_spositiontaking_2 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_2 as isautov2positiontaking	,	   @auto_v2spositiontaking_2 as autov2positiontaking	,	       @old_auto_v2spositiontaking_2 as old_autov2positiontaking	,	       @old_isauto_v2spositiontaking_2 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_2 as isautov2positiontaking	,	   @auto_v2spositiontaking_2 as autov2positiontaking	,	       @old_auto_v2spositiontaking_2 as old_autov2positiontaking	,	       @old_isauto_v2spositiontaking_2 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_2 as isautov3positiontaking	,	   @auto_v3spositiontaking_2 as autov3positiontaking	,	       @old_auto_v3spositiontaking_2 as old_autov3positiontaking	,	       @old_isauto_v3spositiontaking_2 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_2 as isautov5positiontaking	,	   @auto_v5spositiontaking_2 as autov5positiontaking	,	       @old_auto_v5spositiontaking_2 as old_autov5positiontaking	,	       @old_isauto_v5spositiontaking_2 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_2 as isautov10positiontaking	,	   @auto_v10spositiontaking_2 as autov10positiontaking	,	       @old_auto_v10spositiontaking_2 as old_autov10positiontaking	,	       @old_isauto_v10spositiontaking_2 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	@isauto_v12spositiontaking_2 as isautov12positiontaking	,	   @auto_v12spositiontaking_2 as autov12positiontaking	,	       @old_auto_v12spositiontaking_2 as old_autov12positiontaking	,	       @old_isauto_v12spositiontaking_2 as old_isautov12positiontaking	,	@isauto_v99spositiontaking_2 as isautov99positiontaking	,	   @auto_v99spositiontaking_2 as autov99positiontaking	,	       @old_auto_v99spositiontaking_2 as old_autov99positiontaking	,	       @old_isauto_v99spositiontaking_2 as old_isautov99positiontaking	
	union all 	select 3 as bettype	,	   @isauto_spositiontaking_3 as isautopositiontaking	,	  @isauto_slivepositiontaking_3 as isautolivepositiontaking			,	  @auto_spositiontaking_3 as autopositiontaking	,	   @auto_slivepositiontaking_3 as autolivepositiontaking			,	  @old_auto_spositiontaking_3 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_3 as old_autolivepositiontaking			,	  @old_isauto_spositiontaking_3 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_3 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_3 as isautov2positiontaking	,	   @auto_v2spositiontaking_3 as autov2positiontaking	,	   @old_auto_v2spositiontaking_3 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_3 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_3 as isautov2positiontaking	,	   @auto_v2spositiontaking_3 as autov2positiontaking	,	   @old_auto_v2spositiontaking_3 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_3 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_3 as isautov3positiontaking	,	   @auto_v3spositiontaking_3 as autov3positiontaking	,	   @old_auto_v3spositiontaking_3 as old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_3 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_3 as isautov5positiontaking	,	   @auto_v5spositiontaking_3 as autov5positiontaking	,	   @old_auto_v5spositiontaking_3 as old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_3 as old_isautov5positiontaking	,	@isauto_v8spositiontaking_3 as isautov8positiontaking	,	   @auto_v8spositiontaking_3 as autov8positiontaking	,	   @old_auto_v8spositiontaking_3 as old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_3 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_3 as isautov10positiontaking	,	   @auto_v10spositiontaking_3 as autov10positiontaking	,	   @old_auto_v10spositiontaking_3 as old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_3 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	   0 as old_autov11positiontaking	,	   0 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	   0 as old_autov12positiontaking	,	   0 as old_isautov12positiontaking	,	@isauto_v99spositiontaking_3 as isautov99positiontaking	,	   @auto_v99spositiontaking_3 as autov99positiontaking	,	   @old_auto_v99spositiontaking_3 as old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_3 as old_isautov99positiontaking	
	union all  	select 4 as bettype	,	   @isauto_spositiontaking_4 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	   @auto_spositiontaking_4 as autopositiontaking	,	  0 as autolivepositiontaking			,	   @old_auto_spositiontaking_4 as old_autopositiontaking	,	  0 as old_autolivepositiontaking			,	   @old_isauto_spositiontaking_4 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	   0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	       0 as old_autov12positiontaking	,	       0 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking  	
	union all 	select 5 as bettype	,	   @isauto_spositiontaking_5 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	   @auto_spositiontaking_5 as autopositiontaking	,	  0 as autolivepositiontaking			,	   @old_auto_spositiontaking_5 as old_autopositiontaking	,	  0 as old_autolivepositiontaking			,	   @old_isauto_spositiontaking_5 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	   0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	       0 as old_autov12positiontaking	,	       0 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking	
	union all  	select 6 as bettype	,	   @isauto_spositiontaking_6 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	   @auto_spositiontaking_6 as autopositiontaking	,	  0 as autolivepositiontaking			,	   @old_auto_spositiontaking_6 as old_autopositiontaking	,	  0 as old_autolivepositiontaking			,	   @old_isauto_spositiontaking_6 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	   0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking																																																									
	union all  	select 7 as bettype	,	   @isauto_spositiontaking_7 as isautopositiontaking	,	  @isauto_slivepositiontaking_7 as isautolivepositiontaking			,	  @auto_spositiontaking_7 as autopositiontaking	,	   @auto_slivepositiontaking_7 as autolivepositiontaking			,	  @old_auto_spositiontaking_7 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_7 as old_autolivepositiontaking			,	  @old_isauto_spositiontaking_7 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_7 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_7 as isautov2positiontaking	,	   @auto_v2spositiontaking_7 as autov2positiontaking	,	   @old_auto_v2spositiontaking_7 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_7 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_7 as isautov2positiontaking	,	   @auto_v2spositiontaking_7 as autov2positiontaking	,	   @old_auto_v2spositiontaking_7 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_7 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	       0 as old_autov12positiontaking	,	       0 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking	
	union all  	select 8 as bettype	,	   @isauto_spositiontaking_8 as isautopositiontaking	,	  @isauto_slivepositiontaking_8 as isautolivepositiontaking			,	  @auto_spositiontaking_8 as autopositiontaking	,	   @auto_slivepositiontaking_8 as autolivepositiontaking			,	  @old_auto_spositiontaking_8 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_8 as old_autolivepositiontaking			,	  @old_isauto_spositiontaking_8 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_8 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_8 as isautov2positiontaking	,	   @auto_v2spositiontaking_8 as autov2positiontaking	,	   @old_auto_v2spositiontaking_8 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_8 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_8 as isautov2positiontaking	,	   @auto_v2spositiontaking_8 as autov2positiontaking	,	   @old_auto_v2spositiontaking_8 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_8 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	       0 as old_autov12positiontaking	,	       0 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking	
	union all  	select 9 as bettype	,	   @isauto_spositiontaking_9 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	   @auto_spositiontaking_9 as autopositiontaking	,	  0 as autolivepositiontaking			,	   @old_auto_spositiontaking_9 as old_autopositiontaking	,	  0 as old_autolivepositiontaking			,	   @old_isauto_spositiontaking_9 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	   0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	       0 as old_autov12positiontaking	,	       0 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking  	
	union all  	select 10 as bettype	,	   @isauto_spositiontaking_10 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	   @auto_spositiontaking_10 as autopositiontaking	,	  0 as autolivepositiontaking			,	   @old_auto_spositiontaking_10 as old_autopositiontaking	,	  0 as old_autolivepositiontaking			,	   @old_isauto_spositiontaking_10 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	   0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	       0 as old_autov2positiontaking	,	       0 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	       0 as old_autov12positiontaking	,	       0 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking	
	union all 	select 20 as bettype	,	   0 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	  0 as autopositiontaking	,	   0 as autolivepositiontaking			,	  0 as old_autopositiontaking	,	   0 as old_autolivepositiontaking			,	  0 as old_isautopositiontaking	,	   0 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_20 as isautov2positiontaking	,	   @auto_v2spositiontaking_20 as autov2positiontaking	,	   @old_auto_v2spositiontaking_20 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_20 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_20 as isautov2positiontaking	,	   @auto_v2spositiontaking_20 as autov2positiontaking	,	   @old_auto_v2spositiontaking_20 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_20 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_20 as isautov3positiontaking	,	   @auto_v3spositiontaking_20 as autov3positiontaking	,	   @old_auto_v3spositiontaking_20 as old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_20 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_20 as isautov5positiontaking	,	   @auto_v5spositiontaking_20 as autov5positiontaking	,	   @old_auto_v5spositiontaking_20 as old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_20 as old_isautov5positiontaking	,	@isauto_v8spositiontaking_20 as isautov8positiontaking	,	   @auto_v8spositiontaking_20 as autov8positiontaking	,	   @old_auto_v8spositiontaking_20 as old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_20 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_20 as isautov10positiontaking	,	   @auto_v10spositiontaking_20 as autov10positiontaking	,	   @old_auto_v10spositiontaking_20 as old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_20 as old_isautov10positiontaking	,	@isauto_v11spositiontaking_20 as isautov11positiontaking	,	   @auto_v11spositiontaking_20 as autov11positiontaking	,	   @old_auto_v11spositiontaking_20 as old_autov11positiontaking	,	   @old_isauto_v11spositiontaking_20 as old_isautov11positiontaking	,	0 as isautov12positiontaking	,	   0 as autov12positiontaking	,	   0 as old_autov12positiontaking	,	   0 as old_isautov12positiontaking	,	@isauto_v99spositiontaking_20 as isautov99positiontaking	,	   @auto_v99spositiontaking_20 as autov99positiontaking	,	   @old_auto_v99spositiontaking_20 as old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_20 as old_isautov99positiontaking	
	union all  	select 21 as bettype	,	   0 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	  0 as autopositiontaking	,	   0 as autolivepositiontaking			,	  0 as old_autopositiontaking	,	   0 as old_autolivepositiontaking			,	  0 as old_isautopositiontaking	,	   0 as old_isautolivepositiontaking	,	   0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	   0 as old_autov2positiontaking	,	   0 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_7 as isautov2positiontaking	,	   @auto_v2spositiontaking_7 as autov2positiontaking	,	   @old_auto_v2spositiontaking_7 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_7 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	@isauto_v2spositiontaking_21 as isautov12positiontaking	,	   @auto_v2spositiontaking_21 as autov12positiontaking	,	       @old_auto_v2spositiontaking_21 as old_autov12positiontaking	,	       @old_isauto_v2spositiontaking_21 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking	
	union all  	select 22 as bettype	,	   0 as isautopositiontaking	,	  0 as isautolivepositiontaking			,	  0 as autopositiontaking	,	   0 as autolivepositiontaking			,	  0 as old_autopositiontaking	,	   0 as old_autolivepositiontaking			,	  0 as old_isautopositiontaking	,	   0 as old_isautolivepositiontaking	,	   0 as isautov2positiontaking	,	   0 as autov2positiontaking	,	   0 as old_autov2positiontaking	,	   0 as old_isautov2positiontaking	,	@isauto_v2spositiontaking_8 as isautov2positiontaking	,	   @auto_v2spositiontaking_8 as autov2positiontaking	,	   @old_auto_v2spositiontaking_8 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_8 as old_isautov2positiontaking	,	0 as isautov3positiontaking	,	   0 as autov3positiontaking	,	       0 as old_autov3positiontaking	,	       0 as old_isautov3positiontaking	,	0 as isautov5positiontaking	,	   0 as autov5positiontaking	,	       0 as old_autov5positiontaking	,	       0 as old_isautov5positiontaking	,	0 as isautov8positiontaking	,	   0 as autov8positiontaking	,	       0 as old_autov8positiontaking	,	       0 as old_isautov8positiontaking	,	0 as isautov10positiontaking	,	   0 as autov10positiontaking	,	       0 as old_autov10positiontaking	,	       0 as old_isautov10positiontaking	,	0 as isautov11positiontaking	,	   0 as autov11positiontaking	,	       0 as old_autov11positiontaking	,	       0 as old_isautov11positiontaking	,	@isauto_v2spositiontaking_22 as isautov12positiontaking	,	   @auto_v2spositiontaking_22 as autov12positiontaking	,	       @old_auto_v2spositiontaking_22 as old_autov12positiontaking	,	       @old_isauto_v2spositiontaking_22 as old_isautov12positiontaking	,	0 as isautov99positiontaking	,	   0 as autov99positiontaking	,	       0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking

*/

	--Update member accounts
	--Using CURSOR to update spositiontaking field



/*--old code
						select 1 as bettype	,	   @isauto_spositiontaking_1 as isautopositiontaking	,	  @isauto_slivepositiontaking_1 as isautolivepositiontaking	,	   @isauto_v2spositiontaking_1 as isautobpositiontaking	,	  @auto_spositiontaking_1 as autopositiontaking	,	   @auto_slivepositiontaking_1 as autolivepositiontaking	,	   @auto_v2spositiontaking_1 as autobpositiontaking	,	  @old_auto_spositiontaking_1 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_1 as old_autolivepositiontaking	,	   @old_auto_v2spositiontaking_1 as old_autobpositiontaking	,	  @old_isauto_spositiontaking_1 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_1 as old_isautolivepositiontaking	,	   @old_isauto_v2spositiontaking_1 as old_isautobpositiontaking
				union all  	select 2 as bettype	,	   @isauto_spositiontaking_2 as isautopositiontaking	,	  0 as isautolivepositiontaking	,	   @isauto_v2spositiontaking_2 as isautobpositiontaking	,	  @auto_spositiontaking_2 as autopositiontaking	,	  0 as autolivepositiontaking	,	   @auto_v2spositiontaking_2 as autobpositiontaking	,	  @old_auto_spositiontaking_2 as old_autopositiontaking	,	  0 as old_autolivepositiontaking	,	       @old_auto_v2spositiontaking_2 as old_autobpositiontaking	,	  @old_isauto_spositiontaking_2 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	       @old_isauto_v2spositiontaking_2 as old_isautobpositiontaking
				union all 	select 3 as bettype	,	   @isauto_spositiontaking_3 as isautopositiontaking	,	  @isauto_slivepositiontaking_3 as isautolivepositiontaking	,	   @isauto_v2spositiontaking_3 as isautobpositiontaking	,	  @auto_spositiontaking_3 as autopositiontaking	,	   @auto_slivepositiontaking_3 as autolivepositiontaking	,	   @auto_v2spositiontaking_3 as autobpositiontaking	,	  @old_auto_spositiontaking_3 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_3 as old_autolivepositiontaking	,	   @old_auto_v2spositiontaking_3 as old_autobpositiontaking	,	  @old_isauto_spositiontaking_3 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_3 as old_isautolivepositiontaking	,	   @old_isauto_v2spositiontaking_3 as old_isautobpositiontaking
				union all  	select 4 as bettype	,	   @isauto_spositiontaking_4 as isautopositiontaking	,	  0 as isautolivepositiontaking	,	   0 as isautobpositiontaking	,	   @auto_spositiontaking_4 as autopositiontaking	,	  0 as autolivepositiontaking	,	   0 as autobpositiontaking	,	   @old_auto_spositiontaking_4 as old_autopositiontaking	,	  0 as old_autolivepositiontaking	,	       0 as old_autobpositiontaking	,	   @old_isauto_spositiontaking_4 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	       0 as old_isautobpositiontaking
				union all 	select 5 as bettype	,	   @isauto_spositiontaking_5 as isautopositiontaking	,	  0 as isautolivepositiontaking	,	   0 as isautobpositiontaking	,	   @auto_spositiontaking_5 as autopositiontaking	,	  0 as autolivepositiontaking	,	   0 as autobpositiontaking	,	   @old_auto_spositiontaking_5 as old_autopositiontaking	,	  0 as old_autolivepositiontaking	,	       0 as old_autobpositiontaking	,	   @old_isauto_spositiontaking_5 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	       0 as old_isautobpositiontaking
				union all  	select 6 as bettype	,	   @isauto_spositiontaking_6 as isautopositiontaking	,	  0 as isautolivepositiontaking	,	   0 as isautobpositiontaking	,	   @auto_spositiontaking_6 as autopositiontaking	,	  0 as autolivepositiontaking	,	   0 as autobpositiontaking	,	   @old_auto_spositiontaking_6 as old_autopositiontaking	,	  0 as old_autolivepositiontaking	,	       0 as old_autobpositiontaking	,	   @old_isauto_spositiontaking_6 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	       0 as old_isautobpositiontaking
				union all  	select 7 as bettype	,	   @isauto_spositiontaking_7 as isautopositiontaking	,	  @isauto_slivepositiontaking_7 as isautolivepositiontaking	,	   @isauto_v2spositiontaking_7 as isautobpositiontaking	,	  @auto_spositiontaking_7 as autopositiontaking	,	   @auto_slivepositiontaking_7 as autolivepositiontaking	,	   @auto_v2spositiontaking_7 as autobpositiontaking	,	  @old_auto_spositiontaking_7 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_7 as old_autolivepositiontaking	,	   @old_auto_v2spositiontaking_7 as old_autobpositiontaking	,	  @old_isauto_spositiontaking_7 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_7 as old_isautolivepositiontaking	,	   @old_isauto_v2spositiontaking_7 as old_isautobpositiontaking
				union all  	select 8 as bettype	,	   @isauto_spositiontaking_8 as isautopositiontaking	,	  @isauto_slivepositiontaking_8 as isautolivepositiontaking	,	   @isauto_v2spositiontaking_8 as isautobpositiontaking	,	  @auto_spositiontaking_8 as autopositiontaking	,	   @auto_slivepositiontaking_8 as autolivepositiontaking	,	   @auto_v2spositiontaking_8 as autobpositiontaking	,	  @old_auto_spositiontaking_8 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_8 as old_autolivepositiontaking	,	   @old_auto_v2spositiontaking_8 as old_autobpositiontaking	,	  @old_isauto_spositiontaking_8 as old_isautopositiontaking	,	   @old_isauto_slivepositiontaking_8 as old_isautolivepositiontaking	,	   @old_isauto_v2spositiontaking_8 as old_isautobpositiontaking
				union all  	select 9 as bettype	,	   @isauto_spositiontaking_9 as isautopositiontaking	,	  0 as isautolivepositiontaking	,	   0 as isautobpositiontaking	,	   @auto_spositiontaking_9 as autopositiontaking	,	  0 as autolivepositiontaking	,	   0 as autobpositiontaking	,	   @old_auto_spositiontaking_9 as old_autopositiontaking	,	  0 as old_autolivepositiontaking	,	       0 as old_autobpositiontaking	,	   @old_isauto_spositiontaking_9 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	       0 as old_isautobpositiontaking
				union all  	select 10 as bettype	,	   @isauto_spositiontaking_10 as isautopositiontaking	,	  0 as isautolivepositiontaking	,	   0 as isautobpositiontaking	,	   @auto_spositiontaking_10 as autopositiontaking	,	  0 as autolivepositiontaking	,	   0 as autobpositiontaking	,	   @old_auto_spositiontaking_10 as old_autopositiontaking	,	  0 as old_autolivepositiontaking	,	       0 as old_autobpositiontaking	,	   @old_isauto_spositiontaking_10 as old_isautopositiontaking	,	  0 as old_isautolivepositiontaking	,	       0 as old_isautobpositiontaking
*/--end old code


	Declare CUR CURSOR FOR 
			select 1 as bettype	,	   @isauto_spositiontaking_1 as isautopositiontaking	,	  @isauto_slivepositiontaking_1 as isautolivepositiontaking	,	  @auto_spositiontaking_1 as autopositiontaking	,	   @auto_slivepositiontaking_1 as autolivepositiontaking	,	  @old_auto_spositiontaking_1 as old_autopositiontaking	    ,	   @old_auto_slivepositiontaking_1 as old_autolivepositiontaking	,	  @old_isauto_spositiontaking_1 as old_isautopositiontaking	    ,	   @old_isauto_slivepositiontaking_1 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_1 as isautov2positiontaking	,	   @auto_v2spositiontaking_1 as autov2positiontaking	,	   @old_auto_v2spositiontaking_1 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_1 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_1 as isautov3positiontaking	,	   @auto_v3spositiontaking_1 as autov3positiontaking	,	   @old_auto_v3spositiontaking_1 as old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_1 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_1 as isautov5positiontaking	,	   @auto_v5spositiontaking_1 as autov5positiontaking	,	   @old_auto_v5spositiontaking_1 as old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_1 as old_isautov5positiontaking	,	@isauto_v8spositiontaking_1 as isautov8positiontaking	,	   @auto_v8spositiontaking_1 as autov8positiontaking	,	   @old_auto_v8spositiontaking_1 as old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_1 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_1 as isautov10positiontaking	,	   @auto_v10spositiontaking_1 as autov10positiontaking	,	   @old_auto_v10spositiontaking_1 as old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_1 as old_isautov10positiontaking	,	@isauto_v11spositiontaking_1 as isautov11positiontaking	,	   @auto_v11spositiontaking_1 as autov11positiontaking	,	   @old_auto_v11spositiontaking_1 as old_autov11positiontaking	,	   @old_isauto_v11spositiontaking_1 as old_isautov11positiontaking	,	@isauto_v99spositiontaking_1 as isautov99positiontaking	,		@auto_v99spositiontaking_1 as autov99positiontaking	,	   @old_auto_v99spositiontaking_1 as old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_1 as old_isautov99positiontaking
union all  	select 2 as bettype	,	   @isauto_spositiontaking_2 as isautopositiontaking	,								0 as isautolivepositiontaking	,	  @auto_spositiontaking_2 as autopositiontaking	,									0 as autolivepositiontaking	,		@old_auto_spositiontaking_2 as old_autopositiontaking	,										0 as old_autolivepositiontaking	,	  @old_isauto_spositiontaking_2 as old_isautopositiontaking    	,										0 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_2 as isautov2positiontaking	,	   @auto_v2spositiontaking_2 as autov2positiontaking	,	     @old_auto_v2spositiontaking_2 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_2 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_2 as isautov3positiontaking	,	   @auto_v3spositiontaking_2 as autov3positiontaking	,	   @old_auto_v3spositiontaking_2 as old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_2 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_2 as isautov5positiontaking	,	   @auto_v5spositiontaking_2 as autov5positiontaking	,	   @old_auto_v5spositiontaking_2 as old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_2 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_2 as isautov10positiontaking	,	   @auto_v10spositiontaking_2 as autov10positiontaking	,	   @old_auto_v10spositiontaking_2 as old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_2 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,	@isauto_v99spositiontaking_2 as isautov99positiontaking	,		@auto_v99spositiontaking_2 as autov99positiontaking	,	   @old_auto_v99spositiontaking_2 as old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_2 as old_isautov99positiontaking
union all 	select 3 as bettype	,	   @isauto_spositiontaking_3 as isautopositiontaking	,	  @isauto_slivepositiontaking_3 as isautolivepositiontaking	,	  @auto_spositiontaking_3 as autopositiontaking	,	   @auto_slivepositiontaking_3 as autolivepositiontaking	,		@old_auto_spositiontaking_3 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_3 as old_autolivepositiontaking	,	  @old_isauto_spositiontaking_3 as old_isautopositiontaking	    ,		@old_isauto_slivepositiontaking_3 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_3 as isautov2positiontaking	,	   @auto_v2spositiontaking_3 as autov2positiontaking	,	   @old_auto_v2spositiontaking_3 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_3 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_3 as isautov3positiontaking	,	   @auto_v3spositiontaking_3 as autov3positiontaking	,	   @old_auto_v3spositiontaking_3 as old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_3 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_3 as isautov5positiontaking	,	   @auto_v5spositiontaking_3 as autov5positiontaking	,	   @old_auto_v5spositiontaking_3 as old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_3 as old_isautov5positiontaking	,	@isauto_v8spositiontaking_3 as isautov8positiontaking	,	   @auto_v8spositiontaking_3 as autov8positiontaking	,	   @old_auto_v8spositiontaking_3 as old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_3 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_3 as isautov10positiontaking	,	   @auto_v10spositiontaking_3 as autov10positiontaking	,	   @old_auto_v10spositiontaking_3 as old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_3 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,	@isauto_v99spositiontaking_3 as isautov99positiontaking	,		@auto_v99spositiontaking_3 as autov99positiontaking	,	   @old_auto_v99spositiontaking_3 as old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_3 as old_isautov99positiontaking
union all  	select 4 as bettype	,	   @isauto_spositiontaking_4 as isautopositiontaking	,								0 as isautolivepositiontaking	,	  @auto_spositiontaking_4 as autopositiontaking	,									0 as autolivepositiontaking	,		@old_auto_spositiontaking_4 as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,	   @old_isauto_spositiontaking_4 as old_isautopositiontaking	,										 0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,									 0 as old_autov2positiontaking	,									    0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,							 0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking  
union all 	select 5 as bettype	,	   @isauto_spositiontaking_5 as isautopositiontaking	,								0 as isautolivepositiontaking	,	  @auto_spositiontaking_5 as autopositiontaking	,									0 as autolivepositiontaking	,		@old_auto_spositiontaking_5 as old_autopositiontaking	,									  0 as old_autolivepositiontaking	,	   @old_isauto_spositiontaking_5 as old_isautopositiontaking	,										0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,									 0 as old_autov2positiontaking	,									  0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,							 0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking
union all  	select 6 as bettype	,	   @isauto_spositiontaking_6 as isautopositiontaking	,								0 as isautolivepositiontaking	,	  @auto_spositiontaking_6 as autopositiontaking	,									0 as autolivepositiontaking	,		@old_auto_spositiontaking_6 as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,	   @old_isauto_spositiontaking_6 as old_isautopositiontaking	,										0 as old_isautolivepositiontaking	,								 0 as isautov2positiontaking	,								 0 as autov2positiontaking	,									 0 as old_autov2positiontaking	,									 0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,						     0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,						      0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,						             0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,   0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking
union all  	select 7 as bettype	,	   @isauto_spositiontaking_7 as isautopositiontaking	,	  @isauto_slivepositiontaking_7 as isautolivepositiontaking	,	  @auto_spositiontaking_7 as autopositiontaking	,	   @auto_slivepositiontaking_7 as autolivepositiontaking	,		@old_auto_spositiontaking_7 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_7 as old_autolivepositiontaking	,	  @old_isauto_spositiontaking_7 as old_isautopositiontaking	    ,		 @old_isauto_slivepositiontaking_7 as old_isautolivepositiontaking	,		@isauto_v2spositiontaking_7 as isautov2positiontaking	,	   @auto_v2spositiontaking_7 as autov2positiontaking	,	   @old_auto_v2spositiontaking_7 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_7 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,							 0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking
union all  	select 8 as bettype	,	   @isauto_spositiontaking_8 as isautopositiontaking	,	  @isauto_slivepositiontaking_8 as isautolivepositiontaking	,	  @auto_spositiontaking_8 as autopositiontaking	,	   @auto_slivepositiontaking_8 as autolivepositiontaking	,		@old_auto_spositiontaking_8 as old_autopositiontaking	,	   @old_auto_slivepositiontaking_8 as old_autolivepositiontaking	,	  @old_isauto_spositiontaking_8 as old_isautopositiontaking	    ,	   @old_isauto_slivepositiontaking_8 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_8 as isautov2positiontaking	,	   @auto_v2spositiontaking_8 as autov2positiontaking	,	   @old_auto_v2spositiontaking_8 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_8 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,							 0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking
union all  	select 9 as bettype	,	   @isauto_spositiontaking_9 as isautopositiontaking	,								0 as isautolivepositiontaking	,	  @auto_spositiontaking_9 as autopositiontaking	,									0 as autolivepositiontaking	,		@old_auto_spositiontaking_9 as old_autopositiontaking	,										0 as old_autolivepositiontaking	,	   @old_isauto_spositiontaking_9 as old_isautopositiontaking	,										0 as old_isautolivepositiontaking	,	   @isauto_v2spositiontaking_9 as isautov2positiontaking	,		@auto_v2spositiontaking_9 as autov2positiontaking	,		@old_auto_v2spositiontaking_9 as old_autov2positiontaking	,		@old_isauto_v2spositiontaking_9 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,							 0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	, 	0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking  
union all  	select 10 as bettype,	   @isauto_spositiontaking_10 as isautopositiontaking	,								0 as isautolivepositiontaking	,	  @auto_spositiontaking_10 as autopositiontaking,									0 as autolivepositiontaking	,		@old_auto_spositiontaking_10 as old_autopositiontaking	,									  0 as old_autolivepositiontaking	,	   @old_isauto_spositiontaking_10 as old_isautopositiontaking	,										0 as old_isautolivepositiontaking	,								 0 as isautov2positiontaking	,								0 as autov2positiontaking	,									  0 as old_autov2positiontaking	,									 0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,							 0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,								   0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking
union all 	select 20 as bettype,	   0 as isautopositiontaking							,								0 as isautolivepositiontaking	,							0 as autopositiontaking	,									0 as autolivepositiontaking	,									0 as old_autopositiontaking	,									  0 as old_autolivepositiontaking	,									 0 as old_isautopositiontaking	,									  0 as old_isautolivepositiontaking  	,		@isauto_v2spositiontaking_20 as isautov2positiontaking	,	   @auto_v2spositiontaking_20 as autov2positiontaking	,	   @old_auto_v2spositiontaking_20 as old_autov2positiontaking	,	   @old_isauto_v2spositiontaking_20 as old_isautov2positiontaking	,	@isauto_v3spositiontaking_20 as isautov3positiontaking	,	   @auto_v3spositiontaking_20 as autov3positiontaking	,	   @old_auto_v3spositiontaking_20 as old_autov3positiontaking	,	   @old_isauto_v3spositiontaking_20 as old_isautov3positiontaking	,	@isauto_v5spositiontaking_20 as isautov5positiontaking	,	   @auto_v5spositiontaking_20 as autov5positiontaking	,	   @old_auto_v5spositiontaking_20 as old_autov5positiontaking	,	   @old_isauto_v5spositiontaking_20 as old_isautov5positiontaking	,	@isauto_v8spositiontaking_20 as isautov8positiontaking	,	   @auto_v8spositiontaking_20 as autov8positiontaking	,	   @old_auto_v8spositiontaking_20 as old_autov8positiontaking	,	   @old_isauto_v8spositiontaking_20 as old_isautov8positiontaking	,	@isauto_v10spositiontaking_20 as isautov10positiontaking,		@auto_v10spositiontaking_20 as autov10positiontaking,	   @old_auto_v10spositiontaking_20 as old_autov10positiontaking	,	   @old_isauto_v10spositiontaking_20 as old_isautov10positiontaking	,	@isauto_v11spositiontaking_20 as isautov11positiontaking,	   @auto_v11spositiontaking_20 as autov11positiontaking	,	   @old_auto_v11spositiontaking_20 as old_autov11positiontaking	,	   @old_isauto_v11spositiontaking_20 as old_isautov11positiontaking	,	@isauto_v99spositiontaking_20 as isautov99positiontaking,		@auto_v99spositiontaking_20 as autov99positiontaking,	   @old_auto_v99spositiontaking_20 as old_autov99positiontaking	,	   @old_isauto_v99spositiontaking_20 as old_isautov99positiontaking
union all  	select 22 as bettype,	   0 as isautopositiontaking							,								0 as isautolivepositiontaking	,							0 as autopositiontaking	,									0 as autolivepositiontaking	,									0 as old_autopositiontaking	,										0 as old_autolivepositiontaking	,									 0 as old_isautopositiontaking	,									  0 as old_isautolivepositiontaking	    ,								 0 as isautov2positiontaking	,								0 as autov2positiontaking	,									 0 as old_autov2positiontaking	,									 0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,									  0 as old_isautov3positiontaking	,							 0 as isautov5positiontaking	,								 0 as autov5positiontaking	,								   0 as old_autov5positiontaking	,									  0 as old_isautov5positiontaking	,							  0 as isautov8positiontaking	,								 0 as autov8positiontaking	,									0 as old_autov8positiontaking	,									 0 as old_isautov8positiontaking	,							0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									0 as old_isautov11positiontaking	,   0 as isautov99positiontaking							,		0 as autov99positiontaking							,			0 as old_autov99positiontaking							,	       0 as old_isautov99positiontaking

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
		if (@autopositiontaking <> @old_autopositiontaking or @isautopositiontaking <> @old_isautopositiontaking) and (@updatepositiontaking = 1 or @updatemultiple=0)
		BEGIN
			if @isautopositiontaking >0 --auto PT is used
			BEGIN
				--Update use Auto_SPT at master for all members only when:
					--(autoSPT at master changes AND isauto at master = 1
					--OR isauto at master changes from 0 to 1)
					--AND isauto at member = 0
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=1 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking> @autopositiontaking then @autopositiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where
					c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1
					and custsetting.isautopositiontaking=0 -- only update members without AutoSPT at member
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
						,  @ErrCode=209
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautopositiontaking <> @old_isautopositiontaking  --auto PT is NOT used
			BEGIN
				if @updateallmembers = 1 -- Update All Member option is used
				BEGIN
					--Update a specific SPT for all members only when:
						--@updateallmembers = 1
						--AND isauto at master = 0
						--AND isauto at master change from 1 to 0
						--AND isauto at member = 0
					
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1 and custsetting.isautopositiontaking=0				
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
						,  @ErrCode=210
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END
		---------------------------------
		--Update LIVE
		if @bettype in (1,3,7,8) and (@autolivepositiontaking <> @old_autolivepositiontaking or @isautolivepositiontaking <> @old_isautolivepositiontaking ) and (@updatepositiontaking = 1 or @updatemultiple=0)
		BEGIN
			if @isautolivepositiontaking >0
			BEGIN
				select @maxpos = slivepositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=1 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set slivepositiontaking = case when @maxpos - mlivepositiontaking-alivepositiontaking>@autolivepositiontaking then @autolivepositiontaking else @maxpos - mlivepositiontaking-alivepositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1 and custsetting.isautolivepositiontaking=0
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
						,  @ErrCode=211
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautolivepositiontaking <> @old_isautolivepositiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set slivepositiontaking = case when mcs.slivepositiontaking<@newspositiontaking then mcs.slivepositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1 and custsetting.isautolivepositiontaking=0				
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
						,  @ErrCode=212
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END
		---------------------------------
		--Update Basketball
		if @bettype in (1,2,3,7,8,9,20) and (@autov2positiontaking <> @old_autov2positiontaking or @isautov2positiontaking <> @old_isautov2positiontaking ) and (@updatepositiontakingv2 = 1 or @updatemultiple=0)
		BEGIN
			if @isautov2positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=2 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov2positiontaking then @autov2positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=2 and custsetting.isautopositiontaking=0
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Basketball)'
								when 'CS' then N'更新占成数不成功(于篮球)'
								when 'CT' then N'更新佔成數不成功(於籃球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Basketball)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구)'
								else N'Error updating auto positiontaking (for Basketball)'
							end	
						,  @ErrCode=213
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov2positiontaking <> @old_isautov2positiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=2 and custsetting.isautopositiontaking=0
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Basketball)'
								when 'CS' then N'更新占成数不成功(于篮球)'
								when 'CT' then N'更新佔成數不成功(於籃球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Basketball)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구)'
								else N'Error updating auto positiontaking (for Basketball)'
							end	
							,  @ErrCode=214
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END	
		
				---------------------------------
		--Update Football
		if @bettype in (1,2,3,20) and (@autov3positiontaking <> @old_autov3positiontaking or @isautov3positiontaking <> @old_isautov3positiontaking ) and (@updatepositiontakingv3 = 1 or @updatemultiple=0)
		BEGIN
			if @isautov3positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=3 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov3positiontaking then @autov3positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=3 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=215
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov3positiontaking <> @old_isautov3positiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=3 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=216
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END	

		---------------------------------
		--Update Tennis
		if @bettype in (1,2,3,20) and (@autov5positiontaking <> @old_autov5positiontaking or @isautov5positiontaking <> @old_isautov5positiontaking ) and (@updatepositiontakingv5 = 1 or @updatemultiple=0)
		BEGIN
			if @isautov5positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=5 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov5positiontaking then @autov5positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=5 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=217
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov5positiontaking <> @old_isautov5positiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=5 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=218
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END	

		---------------------------------
		--Update Baseball
		if @bettype in (1,3,20) and (@autov8positiontaking <> @old_autov8positiontaking or @isautov8positiontaking <> @old_isautov8positiontaking ) and (@updatepositiontakingv8 = 1 or @updatemultiple=0)
		BEGIN
			if @isautov8positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=8 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov8positiontaking then @autov8positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=8 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=219
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov8positiontaking <> @old_isautov8positiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=8 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=220
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END	

		---------------------------------
		--Update Golf
		if @bettype in (1,2,3,20) and (@autov10positiontaking <> @old_autov10positiontaking or @isautov10positiontaking <> @old_isautov10positiontaking ) and (@updatepositiontakingv10 = 1 or @updatemultiple=0)
		BEGIN
			if @isautov10positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=10 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov10positiontaking then @autov10positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=10 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=221
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov10positiontaking <> @old_isautov10positiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=10 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=222
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END	

		---------------------------------
		--Update Motorsports
		if @bettype in (1,20) and (@autov11positiontaking <> @old_autov11positiontaking or @isautov11positiontaking <> @old_isautov11positiontaking ) and (@updatepositiontakingv11 = 1 or @updatemultiple=0)
		BEGIN
			if @isautov11positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=11 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov11positiontaking then @autov11positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=11 and custsetting.isautopositiontaking=0
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
							,  @ErrCode=223
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov11positiontaking <> @old_isautov11positiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=11 and custsetting.isautopositiontaking=0
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Motorsports)'
								when 'CS' then N'更新佔成數不成功(於賽車)'
								when 'CT' then N'更新佔成數不成功(於賽車)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬารถแข่ง)'
								when 'J' then N'Error updating auto positiontaking (for Motorsports)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (모토스포츠)'
								else N'Error updating auto positiontaking (for Motorsports)'
							end	
							,  @ErrCode=224
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END	
		---------------------------------
		--Update Other sports
		if @bettype in (1,2,3,20) and (@autov99positiontaking <> @old_autov99positiontaking or @isautov99positiontaking <> @old_isautov99positiontaking ) and (@updatepositiontakingv99 = 1 or @updatemultiple=0)
		BEGIN
			if @isautov99positiontaking >0
			BEGIN
				select @maxpos = spositiontaking from custsetting with (NOLOCK) where custid = @srecommend and sporttype=99 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@autov99positiontaking then @autov99positiontaking else @maxpos - mpositiontaking-apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=99 and custsetting.isautopositiontaking=0
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Other sports)'
								when 'CS' then N'更新占成数不成功(于其他)'
								when 'CT' then N'更新佔成數不成功(於其他)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
								when 'J' then N'Error updating auto positiontaking (for Other sports)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
								else N'Error updating auto positiontaking (for Other sports)'
							end	
							,  @ErrCode=225
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov99positiontaking <> @old_isautov99positiontaking
			BEGIN
				if @updateallmembers = 1
				BEGIN
					update custsetting with (ROWLOCK, UPDLOCK) set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and custsetting.sporttype=mcs.sporttype and custsetting.bettype=mcs.bettype
					where c.mrecommend = @mrecommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=99 and custsetting.isautopositiontaking=0
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Other sports)'
								when 'CS' then N'更新占成数不成功(于其他)'
								when 'CT' then N'更新佔成數不成功(於其他)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
								when 'J' then N'Error updating auto positiontaking (for Other sports)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
								else N'Error updating auto positiontaking (for Other sports)'
							end	
							,  @ErrCode=226
						DEALLOCATE CUR
						CLOSE CUR
						return
					END
				END
			END
		END			
			
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
--END


GO
GRANT EXECUTE ON [dbo].Acc_CustomerUpdMaster_AutoPositiontaking TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].Acc_CustomerUpdMaster_AutoPositiontaking TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_CustomerUpdMaster_AutoPositiontaking TO vnteam
GO

