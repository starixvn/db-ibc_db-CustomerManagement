ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgent_AutoPositiontaking]
	@recommend int,
	@mrecommend int,
	@auto_mpositiontaking_1 smallmoney = 0, 
	@auto_mpositiontaking_2 smallmoney = 0,
	@auto_mpositiontaking_3 smallmoney = 0,
	@auto_mpositiontaking_4 smallmoney = 0,
	@auto_mpositiontaking_5 smallmoney= 0,
	@auto_mpositiontaking_6 smallmoney = 0,
	@auto_mpositiontaking_7 smallmoney = 0,
	@auto_mpositiontaking_8 smallmoney = 0,
	@auto_mpositiontaking_9 smallmoney = 0,
	@auto_mpositiontaking_10 smallmoney = 0,
	@auto_mlivepositiontaking_1 smallmoney = 0,
	@auto_mlivepositiontaking_3 smallmoney = 0,
	@auto_mlivepositiontaking_7 smallmoney = 0,
	@auto_mlivepositiontaking_8 smallmoney = 0,
	
	@auto_v2mpositiontaking_1 smallmoney = 0,
	@auto_v2mpositiontaking_2 smallmoney = 0,
	@auto_v2mpositiontaking_3 smallmoney = 0,
	@auto_v2mpositiontaking_7 smallmoney = 0,
	@auto_v2mpositiontaking_8 smallmoney = 0,
	@auto_v2mpositiontaking_9 smallmoney = 0,
	@auto_v2mpositiontaking_20 smallmoney = 0,
	
	@auto_v3mpositiontaking_1 smallmoney = 0,
	@auto_v3mpositiontaking_2 smallmoney = 0,
	@auto_v3mpositiontaking_3 smallmoney = 0,
	@auto_v3mpositiontaking_20 smallmoney = 0,

	@auto_v5mpositiontaking_1 smallmoney = 0,
	@auto_v5mpositiontaking_2 smallmoney = 0,
	@auto_v5mpositiontaking_3 smallmoney = 0,
	@auto_v5mpositiontaking_20 smallmoney = 0,

	@auto_v8mpositiontaking_1 smallmoney = 0,
	@auto_v8mpositiontaking_3 smallmoney = 0,
	@auto_v8mpositiontaking_20 smallmoney = 0,

	@auto_v10mpositiontaking_1 smallmoney = 0,
	@auto_v10mpositiontaking_2 smallmoney = 0,
	@auto_v10mpositiontaking_3 smallmoney = 0,
	@auto_v10mpositiontaking_20 smallmoney = 0,

	@auto_v11mpositiontaking_1 smallmoney = 0,
	@auto_v11mpositiontaking_20 smallmoney = 0,
	@auto_v99mpositiontaking_1 smallmoney = 0,
	@auto_v99mpositiontaking_2 smallmoney = 0,
	@auto_v99mpositiontaking_3 smallmoney = 0,
	@auto_v99mpositiontaking_20 smallmoney = 0,
	
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
	@newmpositiontaking smallmoney,
	@userid int,
	
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

	@isauto_v99mpositiontaking_1 bit = 0,
	@isauto_v99mpositiontaking_2 bit = 0,
	@isauto_v99mpositiontaking_3 bit = 0,
	@isauto_v99mpositiontaking_20 bit = 0,
	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090121@Thien
Task : Update auto PT at agent level
DB: DB02.bodb02
Original:[Acc_CustomerUpdAutoPositiontaking_Master]

Revisions:
    - 20081009@Phuc: Auto Master PT  
		Update use Auto_MPT at agent for all members only when:
		(autoMPT at agent changes AND isauto at agent = 1
		OR isauto at agent changes from 0 to 1)
		 m1=min(m3-a1,u2)

		Update a specific MPT for all members only when:
		@updateallmembers = 1
		AND isauto at agent = 0
		AND isauto at agent change from 1 to 0
		m1=min(m2,@newmpositiontaking)
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090630@Phuc: auto master PT on member level.
    
Param's Explanation:
• @ErrCode:
    = 0: update successfully.
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
	@old_auto_mpositiontaking_1 smallmoney,
	@old_auto_mpositiontaking_2 smallmoney,
	@old_auto_mpositiontaking_3 smallmoney,
	@old_auto_mpositiontaking_4 smallmoney,
	@old_auto_mpositiontaking_5 smallmoney,
	@old_auto_mpositiontaking_6 smallmoney,
	@old_auto_mpositiontaking_7 smallmoney,
	@old_auto_mpositiontaking_8 smallmoney,
	@old_auto_mpositiontaking_9 smallmoney,
	@old_auto_mpositiontaking_10 smallmoney,
	@old_auto_mlivepositiontaking_1 smallmoney,
	@old_auto_mlivepositiontaking_3 smallmoney,
	@old_auto_mlivepositiontaking_7 smallmoney,
	@old_auto_mlivepositiontaking_8 smallmoney,
	
	@old_auto_v2mpositiontaking_1 smallmoney,
	@old_auto_v2mpositiontaking_2 smallmoney,
	@old_auto_v2mpositiontaking_3 smallmoney,
	@old_auto_v2mpositiontaking_7 smallmoney,
	@old_auto_v2mpositiontaking_8 smallmoney,
	@old_auto_v2mpositiontaking_9 smallmoney,
	@old_auto_v2mpositiontaking_20 smallmoney,
	
	@old_auto_v3mpositiontaking_1 smallmoney,
	@old_auto_v3mpositiontaking_2 smallmoney,
	@old_auto_v3mpositiontaking_3 smallmoney,
	@old_auto_v3mpositiontaking_20 smallmoney,

	@old_auto_v5mpositiontaking_1 smallmoney,
	@old_auto_v5mpositiontaking_2 smallmoney,
	@old_auto_v5mpositiontaking_3 smallmoney,
	@old_auto_v5mpositiontaking_20 smallmoney,

	@old_auto_v8mpositiontaking_1 smallmoney,
	@old_auto_v8mpositiontaking_3 smallmoney,
	@old_auto_v8mpositiontaking_20 smallmoney,

	@old_auto_v10mpositiontaking_1 smallmoney,
	@old_auto_v10mpositiontaking_2 smallmoney,
	@old_auto_v10mpositiontaking_3 smallmoney,
	@old_auto_v10mpositiontaking_20 smallmoney,

	@old_auto_v11mpositiontaking_1 smallmoney,
	@old_auto_v11mpositiontaking_20 smallmoney,

	@old_auto_v99mpositiontaking_1 smallmoney,
	@old_auto_v99mpositiontaking_2 smallmoney,
	@old_auto_v99mpositiontaking_3 smallmoney,
	@old_auto_v99mpositiontaking_20 smallmoney,

	@old_isauto_mpositiontaking_1 bit,
	@old_isauto_mpositiontaking_2 bit,
	@old_isauto_mpositiontaking_3 bit,
	@old_isauto_mpositiontaking_4 bit,
	@old_isauto_mpositiontaking_5 bit,
	@old_isauto_mpositiontaking_6 bit,
	@old_isauto_mpositiontaking_7 bit,
	@old_isauto_mpositiontaking_8 bit,
	@old_isauto_mpositiontaking_9 bit,
	@old_isauto_mpositiontaking_10 bit,
	
	@old_isauto_mlivepositiontaking_1 bit,
	@old_isauto_mlivepositiontaking_3 bit,
	@old_isauto_mlivepositiontaking_7 bit,
	@old_isauto_mlivepositiontaking_8 bit,
	
	@old_isauto_v2mpositiontaking_1 bit,
	@old_isauto_v2mpositiontaking_2 bit,
	@old_isauto_v2mpositiontaking_3 bit,
	@old_isauto_v2mpositiontaking_7 bit,
	@old_isauto_v2mpositiontaking_8 bit,
	@old_isauto_v2mpositiontaking_9 bit,
	@old_isauto_v2mpositiontaking_20 bit,
	
	@old_isauto_v3mpositiontaking_1 bit,
	@old_isauto_v3mpositiontaking_2 bit,
	@old_isauto_v3mpositiontaking_3 bit,
	@old_isauto_v3mpositiontaking_20 bit,

	@old_isauto_v5mpositiontaking_1 bit,
	@old_isauto_v5mpositiontaking_2 bit,
	@old_isauto_v5mpositiontaking_3 bit,
	@old_isauto_v5mpositiontaking_20 bit,

	@old_isauto_v8mpositiontaking_1 bit,
	@old_isauto_v8mpositiontaking_3 bit,
	@old_isauto_v8mpositiontaking_20 bit,

	@old_isauto_v10mpositiontaking_1 bit,
	@old_isauto_v10mpositiontaking_2 bit,
	@old_isauto_v10mpositiontaking_3 bit,
	@old_isauto_v10mpositiontaking_20 bit,

	@old_isauto_v11mpositiontaking_1 bit,
	@old_isauto_v11mpositiontaking_20 bit,

	@old_isauto_v99mpositiontaking_1 bit,
	@old_isauto_v99mpositiontaking_2 bit,
	@old_isauto_v99mpositiontaking_3 bit,
	@old_isauto_v99mpositiontaking_20 bit
--------------------------------------------------------
--Get old Auto PT from Agent
select 	@old_auto_mpositiontaking_1	=	autompositiontaking		,	@old_isauto_mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	1
select 	@old_auto_mpositiontaking_2	=	autompositiontaking		,	@old_isauto_mpositiontaking_2	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	2
select 	@old_auto_mpositiontaking_3	=	autompositiontaking		,	@old_isauto_mpositiontaking_3	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	3
select 	@old_auto_mpositiontaking_4	=	autompositiontaking		,	@old_isauto_mpositiontaking_4	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	4
select 	@old_auto_mpositiontaking_5	=	autompositiontaking		,	@old_isauto_mpositiontaking_5	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	5
select 	@old_auto_mpositiontaking_6	=	autompositiontaking		,	@old_isauto_mpositiontaking_6	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	6
select 	@old_auto_mpositiontaking_7	=	autompositiontaking		,	@old_isauto_mpositiontaking_7	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	7
select 	@old_auto_mpositiontaking_8	=	autompositiontaking		,	@old_isauto_mpositiontaking_8	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	8
select 	@old_auto_mpositiontaking_9	=	autompositiontaking		,	@old_isauto_mpositiontaking_9	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	9
select 	@old_auto_mpositiontaking_10	=	autompositiontaking		,	@old_isauto_mpositiontaking_10	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	10
select 	@old_auto_mlivepositiontaking_1	=	autolivempositiontaking		,	@old_isauto_mlivepositiontaking_1	=	isautolivempositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	1
select 	@old_auto_mlivepositiontaking_3	=	autolivempositiontaking		,	@old_isauto_mlivepositiontaking_3	=	isautolivempositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	3
select 	@old_auto_mlivepositiontaking_7	=	autolivempositiontaking		,	@old_isauto_mlivepositiontaking_7	=	isautolivempositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	7
select 	@old_auto_mlivepositiontaking_8	=	autolivempositiontaking		,	@old_isauto_mlivepositiontaking_8	=	isautolivempositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype =	1	and bettype=	8

select 	@old_auto_v2mpositiontaking_1	=	autompositiontaking		,	@old_isauto_v2mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=2	and bettype=	1
select 	@old_auto_v2mpositiontaking_2	=	autompositiontaking		,	@old_isauto_v2mpositiontaking_2	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=2	and bettype=	2
select 	@old_auto_v2mpositiontaking_3	=	autompositiontaking		,	@old_isauto_v2mpositiontaking_3	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=2	and bettype=	3
select 	@old_auto_v2mpositiontaking_7	=	autompositiontaking		,	@old_isauto_v2mpositiontaking_7	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=2	and bettype=	7
select 	@old_auto_v2mpositiontaking_8	=	autompositiontaking		,	@old_isauto_v2mpositiontaking_8	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=2	and bettype=	8
select 	@old_auto_v2mpositiontaking_9	=	autompositiontaking		,	@old_isauto_v2mpositiontaking_9	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=2	and bettype=	9
select 	@old_auto_v2mpositiontaking_20	=	autompositiontaking		,	@old_isauto_v2mpositiontaking_20	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=2	and bettype=	20

select 	@old_auto_v3mpositiontaking_1	=	autompositiontaking		,	@old_isauto_v3mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=3	and bettype=	1
select 	@old_auto_v3mpositiontaking_2	=	autompositiontaking		,	@old_isauto_v3mpositiontaking_2	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=3	and bettype=	2
select 	@old_auto_v3mpositiontaking_3	=	autompositiontaking		,	@old_isauto_v3mpositiontaking_3	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=3	and bettype=	3
select 	@old_auto_v3mpositiontaking_20	=	autompositiontaking		,	@old_isauto_v3mpositiontaking_20	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=3	and bettype=	20

select 	@old_auto_v5mpositiontaking_1	=	autompositiontaking		,	@old_isauto_v5mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=5	and bettype=	1
select 	@old_auto_v5mpositiontaking_2	=	autompositiontaking		,	@old_isauto_v5mpositiontaking_2	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=5	and bettype=	2
select 	@old_auto_v5mpositiontaking_3	=	autompositiontaking		,	@old_isauto_v5mpositiontaking_3	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=5	and bettype=	3
select 	@old_auto_v5mpositiontaking_20	=	autompositiontaking		,	@old_isauto_v5mpositiontaking_20	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=5	and bettype=	20

select 	@old_auto_v8mpositiontaking_1	=	autompositiontaking		,	@old_isauto_v8mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=8	and bettype=	1
select 	@old_auto_v8mpositiontaking_3	=	autompositiontaking		,	@old_isauto_v8mpositiontaking_3	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=8	and bettype=	3
select 	@old_auto_v8mpositiontaking_20	=	autompositiontaking		,	@old_isauto_v8mpositiontaking_20	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=8	and bettype=	20

select 	@old_auto_v10mpositiontaking_1	=	autompositiontaking		,	@old_isauto_v10mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=10	and bettype=	1
select 	@old_auto_v10mpositiontaking_2	=	autompositiontaking		,	@old_isauto_v10mpositiontaking_2	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=10	and bettype=	2
select 	@old_auto_v10mpositiontaking_3	=	autompositiontaking		,	@old_isauto_v10mpositiontaking_3	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=10	and bettype=	3
select 	@old_auto_v10mpositiontaking_20	=	autompositiontaking		,	@old_isauto_v10mpositiontaking_20	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=10	and bettype=	20

select 	@old_auto_v11mpositiontaking_1	=	autompositiontaking		,	@old_isauto_v11mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=11	and bettype=	1
select 	@old_auto_v11mpositiontaking_20	=	autompositiontaking		,	@old_isauto_v11mpositiontaking_20	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=11	and bettype=	20

select 	@old_auto_v99mpositiontaking_1	=	autompositiontaking		,	@old_isauto_v99mpositiontaking_1	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=99	and bettype=	1
select 	@old_auto_v99mpositiontaking_2	=	autompositiontaking		,	@old_isauto_v99mpositiontaking_2	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=99	and bettype=	2
select 	@old_auto_v99mpositiontaking_3	=	autompositiontaking		,	@old_isauto_v99mpositiontaking_3	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=99	and bettype=	3
select 	@old_auto_v99mpositiontaking_20	=	autompositiontaking		,	@old_isauto_v99mpositiontaking_20	=	isautompositiontaking		from custsetting with (nolock) where custid = @recommend and sporttype=99	and bettype=	20



if @updatepositiontaking = 1 or @updatemultiple=0
BEGIN
	--Update Master Agent account (autopositiontaking field)
	--For Football
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_mpositiontaking_1 as autopositiontaking, @auto_mlivepositiontaking_1	as autolivepositiontaking, @isauto_mpositiontaking_1 as isautopositiontaking, @isauto_mlivepositiontaking_1	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_mpositiontaking_2 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_2 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_mpositiontaking_3 as autopositiontaking, @auto_mlivepositiontaking_3 	as autolivepositiontaking, @isauto_mpositiontaking_3 as isautopositiontaking, @isauto_mlivepositiontaking_3	as isautolivepositiontaking
				union all 	select 4 as bettype, @auto_mpositiontaking_4 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_4 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 5 as bettype, @auto_mpositiontaking_5 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_5 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 6 as bettype, @auto_mpositiontaking_6 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_6 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 7 as bettype, @auto_mpositiontaking_7 as autopositiontaking, @auto_mlivepositiontaking_7 	as autolivepositiontaking, @isauto_mpositiontaking_7 as isautopositiontaking, @isauto_mlivepositiontaking_7	as isautolivepositiontaking
				union all 	select 8 as bettype, @auto_mpositiontaking_8 as autopositiontaking, @auto_mlivepositiontaking_8 	as autolivepositiontaking, @isauto_mpositiontaking_8 as isautopositiontaking, @isauto_mlivepositiontaking_8	as isautolivepositiontaking			
				union all 	select 9 as bettype, @auto_mpositiontaking_9 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_9 as isautopositiontaking, 0				as isautolivepositiontaking
				union all 	select 10 as bettype, @auto_mpositiontaking_10 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_10 as isautopositiontaking, 0				as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=1
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Soccer)'
				when 'CS' then N'更新占成数不成功(于足球)'
				when 'CT' then N'更新佔成數不成功(於足球)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาฟุตบอล)'
				when 'J' then N'Error updating auto positiontaking (for Soccer)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구).'
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
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_v2mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v2mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v2mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 7 as bettype, @auto_v2mpositiontaking_7 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_7 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 8 as bettype, @auto_v2mpositiontaking_8 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_8 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 9 as bettype, @auto_v2mpositiontaking_9 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_9 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v2mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=2
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Basketball)'
				when 'CS' then N'更新占成数不成功(于篮球)'
				when 'CT' then N'更新佔成數不成功(於籃球)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
				when 'J' then N'Error updating auto positiontaking (for Basketball)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구).'
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
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_v3mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v3mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v3mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v3mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=3
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Football)'
				when 'CS' then N'更新占成数不成功(于美式足球)'
				when 'CT' then N'更新佔成數不成功(於美式足球)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอเมริกันฟุตบอล)'
				when 'J' then N'Error updating auto positiontaking (for Football)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (풋볼).'
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
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_v5mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v5mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v5mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v5mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=5
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Tennis)'
				when 'CS' then N'更新占成数不成功(于网球)'
				when 'CT' then N'更新佔成數不成功(於網球)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเทนนิส)'
				when 'J' then N'Error updating auto positiontaking (for Tennis)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (테니스).'
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
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_v8mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v8mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v8mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=8
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Baseball)'
				when 'CS' then N'更新占成数不成功(于棒球)'
				when 'CT' then N'更新佔成數不成功(於棒球)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเบสบอล)'
				when 'J' then N'Error updating auto positiontaking (for Baseball)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (야구).'
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
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_v10mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v10mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v10mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v10mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=10
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Golf)'
				when 'CS' then N'更新占成数不成功(于高尔夫球)'
				when 'CT' then N'更新佔成數不成功(於高爾夫球)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬากอฟล์)'
				when 'J' then N'Error updating auto positiontaking (for Golf)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (골프).'
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
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_v11mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v11mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=11
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Motorsports)'
				when 'CS' then N'更新占成数不成功(于赛车)'
				when 'CT' then N'更新佔成數不成功(於賽車)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬารถแข่ง)'
				when 'J' then N'Error updating auto positiontaking (for Motorsports)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (모토스포츠).'
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
	update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, autolivempositiontaking = b.autolivepositiontaking, isautompositiontaking = b.isautopositiontaking, isautolivempositiontaking = b.isautolivepositiontaking
	from custsetting inner join 
			(
							select 1 as bettype, @auto_v99mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 2 as bettype, @auto_v99mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 3 as bettype, @auto_v99mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking
				union all 	select 20 as bettype, @auto_v99mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking
			) as b on b.bettype = custsetting.bettype
	where custsetting.custid = @recommend and custsetting.sporttype=99
	if @@Error <> 0
	BEGIN
		
		SELECT @ErrMsg =  
			case @Language 
				when 'E' then 'Error updating auto positiontaking (for Other sports)'
				when 'CS' then N'更新占成数不成功(于其他)'
				when 'CT' then N'更新佔成數不成功(於其他)'
				when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
				when 'J' then N'Error updating auto positiontaking (for Other sports)'
				when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠).'
				else N'Error updating auto positiontaking (for Other sports)'
			end	
			,  @ErrCode=208
		return
	END
END

	Declare CUR CURSOR FOR 
			select 1 as bettype	,	   @isauto_mpositiontaking_1  as isautopositiontaking	,	  @isauto_mlivepositiontaking_1 as isautolivepositiontaking	,	  @auto_mpositiontaking_1 as autopositiontaking	,	   @auto_mlivepositiontaking_1 as autolivepositiontaking	,	    @old_auto_mpositiontaking_1  as old_autopositiontaking	,	   @old_auto_mlivepositiontaking_1 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_1  as old_isautopositiontaking	 ,	   @old_isauto_mlivepositiontaking_1 as old_isautolivepositiontaking	,	   @isauto_v2mpositiontaking_1 as isautov2positiontaking	,	   @auto_v2mpositiontaking_1 as autov2positiontaking	,	   @old_auto_v2mpositiontaking_1 as old_autov2positiontaking	,	   @old_isauto_v2mpositiontaking_1 as old_isautov2positiontaking	,	@isauto_v3mpositiontaking_1 as isautov3positiontaking	,	   @auto_v3mpositiontaking_1 as autov3positiontaking	,	   @old_auto_v3mpositiontaking_1 as old_autov3positiontaking	,	   @old_isauto_v3mpositiontaking_1 as old_isautov3positiontaking	,	@isauto_v5mpositiontaking_1 as isautov5positiontaking	,	   @auto_v5mpositiontaking_1 as autov5positiontaking	,	   @old_auto_v5mpositiontaking_1 as old_autov5positiontaking	,	   @old_isauto_v5mpositiontaking_1 as old_isautov5positiontaking	,	@isauto_v8mpositiontaking_1 as isautov8positiontaking	,	   @auto_v8mpositiontaking_1 as autov8positiontaking	,	   @old_auto_v8mpositiontaking_1 as old_autov8positiontaking	,	   @old_isauto_v8mpositiontaking_1 as old_isautov8positiontaking	,	@isauto_v10mpositiontaking_1 as isautov10positiontaking	,	   @auto_v10mpositiontaking_1 as autov10positiontaking	,	   @old_auto_v10mpositiontaking_1 as old_autov10positiontaking	,	   @old_isauto_v10mpositiontaking_1 as old_isautov10positiontaking	,	@isauto_v11mpositiontaking_1 as isautov11positiontaking	,	   @auto_v11mpositiontaking_1 as autov11positiontaking	,	   @old_auto_v11mpositiontaking_1 as old_autov11positiontaking	,	   @old_isauto_v11mpositiontaking_1 as old_isautov11positiontaking	,	@isauto_v99mpositiontaking_1 as isautov99positiontaking	,	   @auto_v99mpositiontaking_1 as autov99positiontaking	,	   @old_auto_v99mpositiontaking_1 as old_autov99positiontaking	,	   @old_isauto_v99mpositiontaking_1 as old_isautov99positiontaking
union all  	select 2 as bettype	,	   @isauto_mpositiontaking_2  as isautopositiontaking	,								  0 as isautolivepositiontaking	,	  @auto_mpositiontaking_2 as autopositiontaking	,							     0 as autolivepositiontaking	,		@old_auto_mpositiontaking_2  as old_autopositiontaking	,	   								 0 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_2  as old_isautopositiontaking	 ,									   0 as old_isautolivepositiontaking	,	   @isauto_v2mpositiontaking_2 as isautov2positiontaking	,	   @auto_v2mpositiontaking_2 as autov2positiontaking	,	   @old_auto_v2mpositiontaking_2 as old_autov2positiontaking	,	   @old_isauto_v2mpositiontaking_2 as old_isautov2positiontaking	,	@isauto_v3mpositiontaking_2 as isautov3positiontaking	,	   @auto_v3mpositiontaking_2 as autov3positiontaking	,	   @old_auto_v3mpositiontaking_2 as old_autov3positiontaking	,	   @old_isauto_v3mpositiontaking_2 as old_isautov3positiontaking	,	@isauto_v5mpositiontaking_2 as isautov5positiontaking	,	   @auto_v5mpositiontaking_2 as autov5positiontaking	,	   @old_auto_v5mpositiontaking_2 as old_autov5positiontaking	,	   @old_isauto_v5mpositiontaking_2 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								0 as autov8positiontaking	,									0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,	@isauto_v10mpositiontaking_2 as isautov10positiontaking	,	   @auto_v10mpositiontaking_2 as autov10positiontaking	,	   @old_auto_v10mpositiontaking_2 as old_autov10positiontaking	,	   @old_isauto_v10mpositiontaking_2 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	@isauto_v99mpositiontaking_2 as isautov99positiontaking	,	   @auto_v99mpositiontaking_2 as autov99positiontaking	,	   @old_auto_v99mpositiontaking_2 as old_autov99positiontaking	,	   @old_isauto_v99mpositiontaking_2 as old_isautov99positiontaking
union all 	select 3 as bettype	,	   @isauto_mpositiontaking_3  as isautopositiontaking	,	  @isauto_mlivepositiontaking_3 as isautolivepositiontaking	,	  @auto_mpositiontaking_3 as autopositiontaking	,	   @auto_mlivepositiontaking_3 as autolivepositiontaking	,		@old_auto_mpositiontaking_3  as old_autopositiontaking	,	   @old_auto_mlivepositiontaking_3 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_3  as old_isautopositiontaking	 ,	   @old_isauto_mlivepositiontaking_3 as old_isautolivepositiontaking	,	   @isauto_v2mpositiontaking_3 as isautov2positiontaking	,	   @auto_v2mpositiontaking_3 as autov2positiontaking	,	   @old_auto_v2mpositiontaking_3 as old_autov2positiontaking	,	   @old_isauto_v2mpositiontaking_3 as old_isautov2positiontaking	,	@isauto_v3mpositiontaking_3 as isautov3positiontaking	,	   @auto_v3mpositiontaking_3 as autov3positiontaking	,	   @old_auto_v3mpositiontaking_3 as old_autov3positiontaking	,	   @old_isauto_v3mpositiontaking_3 as old_isautov3positiontaking	,	@isauto_v5mpositiontaking_3 as isautov5positiontaking	,	   @auto_v5mpositiontaking_3 as autov5positiontaking	,	   @old_auto_v5mpositiontaking_3 as old_autov5positiontaking	,	   @old_isauto_v5mpositiontaking_3 as old_isautov5positiontaking	,	@isauto_v8mpositiontaking_3 as isautov8positiontaking	,	   @auto_v8mpositiontaking_3 as autov8positiontaking	,	   @old_auto_v8mpositiontaking_3 as old_autov8positiontaking	,	   @old_isauto_v8mpositiontaking_3 as old_isautov8positiontaking	,	@isauto_v10mpositiontaking_3 as isautov10positiontaking	,	   @auto_v10mpositiontaking_3 as autov10positiontaking	,	   @old_auto_v10mpositiontaking_3 as old_autov10positiontaking	,	   @old_isauto_v10mpositiontaking_3 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	@isauto_v99mpositiontaking_3 as isautov99positiontaking	,	   @auto_v99mpositiontaking_3 as autov99positiontaking	,	   @old_auto_v99mpositiontaking_3 as old_autov99positiontaking	,	   @old_isauto_v99mpositiontaking_3 as old_isautov99positiontaking
union all  	select 4 as bettype	,	   @isauto_mpositiontaking_4  as isautopositiontaking	,								  0 as isautolivepositiontaking	,	  @auto_mpositiontaking_4 as autopositiontaking	,								 0 as autolivepositiontaking	,		@old_auto_mpositiontaking_4  as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_4  as old_isautopositiontaking     ,									   0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,								    0 as old_autov2positiontaking	,									    0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								0 as autov8positiontaking	,									  0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking  
union all 	select 5 as bettype	,	   @isauto_mpositiontaking_5  as isautopositiontaking	,								  0 as isautolivepositiontaking	,	  @auto_mpositiontaking_5 as autopositiontaking	,								 0 as autolivepositiontaking	,		@old_auto_mpositiontaking_5  as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_5  as old_isautopositiontaking     ,										0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,									0 as old_autov2positiontaking	,										0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								0 as autov8positiontaking	,									 0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking
union all  	select 6 as bettype	,	   @isauto_mpositiontaking_6  as isautopositiontaking	,								  0 as isautolivepositiontaking	,	  @auto_mpositiontaking_6 as autopositiontaking	,								 0 as autolivepositiontaking	,		@old_auto_mpositiontaking_6  as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_6  as old_isautopositiontaking     ,										0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,									0 as old_autov2positiontaking	,										0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								0 as autov8positiontaking	,									 0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking
union all  	select 7 as bettype	,	   @isauto_mpositiontaking_7  as isautopositiontaking	,	  @isauto_mlivepositiontaking_7 as isautolivepositiontaking	,	  @auto_mpositiontaking_7 as autopositiontaking	,	   @auto_mlivepositiontaking_7 as autolivepositiontaking	,		@old_auto_mpositiontaking_7  as old_autopositiontaking	,	   @old_auto_mlivepositiontaking_7 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_7  as old_isautopositiontaking	 ,		@old_isauto_mlivepositiontaking_7 as old_isautolivepositiontaking	,	   @isauto_v2mpositiontaking_7 as isautov2positiontaking	,	   @auto_v2mpositiontaking_7 as autov2positiontaking	,	   @old_auto_v2mpositiontaking_7 as old_autov2positiontaking	,	   @old_isauto_v2mpositiontaking_7 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								 0 as autov8positiontaking	,									0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking
union all  	select 8 as bettype	,	   @isauto_mpositiontaking_8  as isautopositiontaking	,	  @isauto_mlivepositiontaking_8 as isautolivepositiontaking	,	  @auto_mpositiontaking_8 as autopositiontaking	,	   @auto_mlivepositiontaking_8 as autolivepositiontaking	,		@old_auto_mpositiontaking_8  as old_autopositiontaking	,	   @old_auto_mlivepositiontaking_8 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_8  as old_isautopositiontaking	 ,	   @old_isauto_mlivepositiontaking_8 as old_isautolivepositiontaking	,	   @isauto_v2mpositiontaking_8 as isautov2positiontaking	,	   @auto_v2mpositiontaking_8 as autov2positiontaking	,	   @old_auto_v2mpositiontaking_8 as old_autov2positiontaking	,	   @old_isauto_v2mpositiontaking_8 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								 0 as autov8positiontaking	,									0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,							    0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking
union all  	select 9 as bettype	,	   @isauto_mpositiontaking_9  as isautopositiontaking	,								  0 as isautolivepositiontaking	,	  @auto_mpositiontaking_9 as autopositiontaking	,								 0 as autolivepositiontaking	,		@old_auto_mpositiontaking_9  as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_9  as old_isautopositiontaking     ,										0 as old_isautolivepositiontaking	,	   @isauto_v2mpositiontaking_9 as isautov2positiontaking	,	   @auto_v2mpositiontaking_9 as autov2positiontaking	,	   @old_auto_v2mpositiontaking_9 as old_autov2positiontaking	,	   @old_isauto_v2mpositiontaking_9 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								0 as autov8positiontaking	,									0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking  
union all  	select 10 as bettype,	   @isauto_mpositiontaking_10 as isautopositiontaking	,								  0 as isautolivepositiontaking	,	  @auto_mpositiontaking_10 as autopositiontaking,								 0 as autolivepositiontaking	,		@old_auto_mpositiontaking_10 as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,	  @old_isauto_mpositiontaking_10 as old_isautopositiontaking     ,										0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,									0 as old_autov2positiontaking	,										0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								 0 as autov8positiontaking	,									0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking
union all 	select 20 as bettype,	   0 as isautopositiontaking							,								  0 as isautolivepositiontaking	,							0 as autopositiontaking	,								 0 as autolivepositiontaking	,								   0 as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,								   0 as old_isautopositiontaking     ,										0 as old_isautolivepositiontaking	,	   @isauto_v2mpositiontaking_20 as isautov2positiontaking	,	   @auto_v2mpositiontaking_20 as autov2positiontaking	,	   @old_auto_v2mpositiontaking_20 as old_autov2positiontaking	,	   @old_isauto_v2mpositiontaking_20 as old_isautov2positiontaking	,	@isauto_v3mpositiontaking_20 as isautov3positiontaking	,	   @auto_v3mpositiontaking_20 as autov3positiontaking	,	   @old_auto_v3mpositiontaking_20 as old_autov3positiontaking	,	   @old_isauto_v3mpositiontaking_20 as old_isautov3positiontaking	,	@isauto_v5mpositiontaking_20 as isautov5positiontaking	,	   @auto_v5mpositiontaking_20 as autov5positiontaking	,	   @old_auto_v5mpositiontaking_20 as old_autov5positiontaking	,	  @old_isauto_v5mpositiontaking_20 as old_isautov5positiontaking	,    @isauto_v8mpositiontaking_20 as isautov8positiontaking	,		@auto_v8mpositiontaking_20 as autov8positiontaking	,		@old_auto_v8mpositiontaking_20 as old_autov8positiontaking	,	   @old_isauto_v8mpositiontaking_20 as old_isautov8positiontaking	,	@isauto_v10mpositiontaking_20 as isautov10positiontaking,	   @auto_v10mpositiontaking_20 as autov10positiontaking	,	   @old_auto_v10mpositiontaking_20 as old_autov10positiontaking	,	   @old_isauto_v10mpositiontaking_20 as old_isautov10positiontaking	,	@isauto_v11mpositiontaking_20 as isautov11positiontaking,	   @auto_v11mpositiontaking_20 as autov11positiontaking	,	   @old_auto_v11mpositiontaking_20 as old_autov11positiontaking	,	   @old_isauto_v11mpositiontaking_20 as old_isautov11positiontaking	,	@isauto_v99mpositiontaking_20 as isautov99positiontaking,	   @auto_v99mpositiontaking_20 as autov99positiontaking	,	   @old_auto_v99mpositiontaking_20 as old_autov99positiontaking	,	   @old_isauto_v99mpositiontaking_20 as old_isautov99positiontaking
union all  	select 21 as bettype,	   0 as isautopositiontaking							,								  0 as isautolivepositiontaking	,							0 as autopositiontaking	,								 0 as autolivepositiontaking	,								   0 as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,								   0 as old_isautopositiontaking     ,										0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,									0 as old_autov2positiontaking	,										0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									 0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								0 as autov8positiontaking	,									0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									  0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking
union all  	select 22 as bettype,	   0 as isautopositiontaking							,								  0 as isautolivepositiontaking	,							0 as autopositiontaking	,								 0 as autolivepositiontaking	,								   0 as old_autopositiontaking	,									 0 as old_autolivepositiontaking	,								   0 as old_isautopositiontaking     ,										0 as old_isautolivepositiontaking	,									0 as isautov2positiontaking	,								0 as autov2positiontaking	,									0 as old_autov2positiontaking	,										0 as old_isautov2positiontaking	,								0 as isautov3positiontaking	,								0 as autov3positiontaking	,									0 as old_autov3positiontaking	,										0 as old_isautov3positiontaking	,	0 as isautov5positiontaking								,	   0 as autov5positiontaking							,									0 as old_autov5positiontaking	,									 0 as old_isautov5positiontaking	,								0 as isautov8positiontaking	,								0 as autov8positiontaking	,									 0 as old_autov8positiontaking	,									0 as old_isautov8positiontaking		,							   0 as isautov10positiontaking	,								0 as autov10positiontaking	,									0 as old_autov10positiontaking	,									   0 as old_isautov10positiontaking	,							0 as isautov11positiontaking	,								0 as autov11positiontaking	,									0 as old_autov11positiontaking	,									  0 as old_isautov11positiontaking	,	0 as isautov99positiontaking							,	   0 as autov99positiontaking							,									0 as old_autov99positiontaking	,	       0 as old_isautov99positiontaking

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

	--Update use Auto_MPT at agent for all members only when:
	--(autoMPT at agent changes AND isauto at agent = 1
	--OR isauto at agent changes from 0 to 1)
	-- m1=min(m3-a1,u2)
	
	--Update a specific MPT for all members only when:
	--@updateallmembers = 1
	--AND isauto at agent = 0
	--AND isauto at agent change from 1 to 0
	--m1=min(m2,@newmpositiontaking)
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		if (@autopositiontaking <> @old_autopositiontaking or @isautopositiontaking <> @old_isautopositiontaking) and (@updatepositiontaking = 1 or @updatemultiple=0)
		BEGIN
			if @isautopositiontaking >0 --auto PT is used
			BEGIN
				-- m1=min(m3-a1,u2)				
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=1 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking> @autopositiontaking then @autopositiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where
					c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Soccer)'
							when 'CS' then N'更新占成数不成功(于足球)'
							when 'CT' then N'更新佔成數不成功(於足球)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาฟุตบอล)'
							when 'J' then N'Error updating auto positiontaking (for Soccer)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구).'
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
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1 				
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Soccer)'
								when 'CS' then N'更新占成数不成功(于足球)'
								when 'CT' then N'更新佔成數不成功(於足球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาฟุตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Soccer)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구).'
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
			if @isautolivepositiontaking >0 --Use AUTO_MPT
			BEGIN
				--m1=min(m3-a1,u2)
				select @maxpos = mlivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=1 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mlivepositiontaking = case when @maxpos - alivepositiontaking>@autolivepositiontaking then @autolivepositiontaking else @maxpos - alivepositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1 
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Soccer - LIVE)'
							when 'CS' then N'更新占成数不成功(于足球-现场)'
							when 'CT' then N'更新佔成數不成功(於足球-現場)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ ( สำหรับการเล่นสดขณะแข่งขัน ของฟุตบอล)'
							when 'J' then N'Error updating auto positiontaking (for Soccer - LIVE)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구- 생중계).'
							else N'Error updating auto positiontaking (for Soccer - LIVE)'
						end	
						,  @ErrCode=211
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautolivepositiontaking <> @old_isautolivepositiontaking --Not use AUTO_PT
			BEGIN
				if @updateallmembers = 1--Update all member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mlivepositiontaking = case when acs.mlivepositiontaking<@newmpositiontaking then acs.mlivepositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=1 			
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
						case @Language 
							when 'E' then 'Error updating auto positiontaking (for Soccer - LIVE)'
							when 'CS' then N'更新占成数不成功(于足球-现场)'
							when 'CT' then N'更新佔成數不成功(於足球-現場)'
							when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ ( สำหรับการเล่นสดขณะแข่งขัน ของฟุตบอล)'
							when 'J' then N'Error updating auto positiontaking (for Soccer - LIVE)'
							when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구- 생중계).'
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
				--update m1=min(m3-a1,u2)
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=2 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov2positiontaking then @autov2positiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=2
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Basketball)'
								when 'CS' then N'更新占成数不成功(于篮球)'
								when 'CT' then N'更新佔成數不成功(於籃球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Basketball)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구).'
								else N'Error updating auto positiontaking (for Basketball)'
							end	
						,  @ErrCode=213
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov2positiontaking <> @old_isautov2positiontaking -- Not use AUTO_PT
			BEGIN
				if @updateallmembers = 1 --Update all member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=2 
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Basketball)'
								when 'CS' then N'更新占成数不成功(于篮球)'
								when 'CT' then N'更新佔成數不成功(於籃球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Basketball)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구).'
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
			if @isautov3positiontaking >0 --Use AUTO_MPT
			BEGIN
				--m1=min(m3-a1,u2)
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=3 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov3positiontaking then @autov3positiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=3 
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Football)'
								when 'CS' then N'更新占成数不成功(于美式足球)'
								when 'CT' then N'更新佔成數不成功(於美式足球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอเมริกันฟุตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Football)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (풋볼).'
								else N'Error updating auto positiontaking (for Football)'
							end	
							,  @ErrCode=215
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov3positiontaking <> @old_isautov3positiontaking --Not use AUTO_MPT
			BEGIN
				if @updateallmembers = 1 --Update all member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=3 
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Football)'
								when 'CS' then N'更新占成数不成功(于美式足球)'
								when 'CT' then N'更新佔成數不成功(於美式足球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอเมริกันฟุตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Football)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (풋볼).'
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
				-- m1=min(m3-a1,u2)
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=5 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov5positiontaking then @autov5positiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=5 
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Tennis)'
								when 'CS' then N'更新占成数不成功(于网球)'
								when 'CT' then N'更新佔成數不成功(於網球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเทนนิส)'
								when 'J' then N'Error updating auto positiontaking (for Tennis)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (테니스).'
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
				if @updateallmembers = 1--update all member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=5
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Tennis)'
								when 'CS' then N'更新占成数不成功(于网球)'
								when 'CT' then N'更新佔成數不成功(於網球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเทนนิส)'
								when 'J' then N'Error updating auto positiontaking (for Tennis)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (테니스).'
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
			if @isautov8positiontaking >0--Use AUTO MPT
			BEGIN
				--m1=min(m3-a1,u2)
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=8 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov8positiontaking then @autov8positiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=8 
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Baseball)'
								when 'CS' then N'更新占成数不成功(于棒球)'
								when 'CT' then N'更新佔成數不成功(於棒球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเบสบอล)'
								when 'J' then N'Error updating auto positiontaking (for Baseball)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (야구).'
								else N'Error updating auto positiontaking (for Baseball)'
							end	
							,  @ErrCode=219
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov8positiontaking <> @old_isautov8positiontaking -- Not use AUTO MPT
			BEGIN
				if @updateallmembers = 1--All member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=8 and custsetting.isautopositiontaking=0
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Baseball)'
								when 'CS' then N'更新占成数不成功(于棒球)'
								when 'CT' then N'更新佔成數不成功(於棒球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเบสบอล)'
								when 'J' then N'Error updating auto positiontaking (for Baseball)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (야구).'
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
			if @isautov10positiontaking >0 --Use AUTO MPT
			BEGIN
				--m1=min(m3-a1,u2)
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=10 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov10positiontaking then @autov10positiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=10 
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Golf)'
								when 'CS' then N'更新占成数不成功(于高尔夫球)'
								when 'CT' then N'更新佔成數不成功(於高爾夫球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬากอฟล์)'
								when 'J' then N'Error updating auto positiontaking (for Golf)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (골프).'
								else N'Error updating auto positiontaking (for Golf)'
							end	
							,  @ErrCode=221
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov10positiontaking <> @old_isautov10positiontaking --Not use AUTO MPT
			BEGIN
				if @updateallmembers = 1 -- all member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=10 
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Golf)'
								when 'CS' then N'更新占成数不成功(于高尔夫球)'
								when 'CT' then N'更新佔成數不成功(於高爾夫球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬากอฟล์)'
								when 'J' then N'Error updating auto positiontaking (for Golf)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (골프).'
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
			if @isautov11positiontaking >0 --Use AUTO MPT
			BEGIN
				--m1=min(m3-a1,u2)
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=11 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov11positiontaking then @autov11positiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=11 
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Motorsports)'
								when 'CS' then N'更新占成数不成功(于赛车)'
								when 'CT' then N'更新佔成數不成功(於賽車)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬารถแข่ง)'
								when 'J' then N'Error updating auto positiontaking (for Motorsports)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (모토스포츠).'
								else N'Error updating auto positiontaking (for Motorsports)'
							end	
							,  @ErrCode=223
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov11positiontaking <> @old_isautov11positiontaking -- Not use AUTO MPT
			BEGIN
				if @updateallmembers = 1 -- all member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=11 
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Motorsports)'
								when 'CS' then N'更新佔成數不成功(於賽車)'
								when 'CT' then N'更新佔成數不成功(於賽車)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬารถแข่ง)'
								when 'J' then N'Error updating auto positiontaking (for Motorsports)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (모토스포츠).'
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
			if @isautov99positiontaking >0 --Use AUTO MPT
			BEGIN 
				--m1=min(m3-a1,u2)
				select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=99 and bettype = @bettype
				update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov99positiontaking then @autov99positiontaking else @maxpos - apositiontaking end
				from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
				where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=99 
				if @@Error <> 0
				BEGIN
					
					SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Other sports)'
								when 'CS' then N'更新占成数不成功(于其他)'
								when 'CT' then N'更新佔成數不成功(於其他)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
								when 'J' then N'Error updating auto positiontaking (for Other sports)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠).'
								else N'Error updating auto positiontaking (for Other sports)'
							end	
							,  @ErrCode=225
					DEALLOCATE CUR
					CLOSE CUR
					return
				END
			END
			else if @isautov99positiontaking <> @old_isautov99positiontaking --Not use AUTO MPT
			BEGIN
				if @updateallmembers = 1 --All member
				BEGIN
					--m1=min(m2,@newmpositiontaking)
					update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
					from custsetting inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
					inner join custsetting as acs with (NOLOCK) on acs.custid = @recommend and custsetting.sporttype=acs.sporttype and custsetting.bettype=acs.bettype
					where c.recommend = @recommend and c.roleid = 1 and custsetting.bettype = @bettype and custsetting.sporttype=99
					if @@Error <> 0
					BEGIN
						
						SELECT @ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Other sports)'
								when 'CS' then N'更新占成数不成功(于其他)'
								when 'CT' then N'更新佔成數不成功(於其他)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
								when 'J' then N'Error updating auto positiontaking (for Other sports)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠).'
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
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_AutoPositiontaking] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_AutoPositiontaking] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgent_AutoPositiontaking] TO vnteam
GO

