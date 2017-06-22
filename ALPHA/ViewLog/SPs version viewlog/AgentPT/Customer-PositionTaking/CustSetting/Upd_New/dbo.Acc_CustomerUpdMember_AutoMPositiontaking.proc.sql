ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_AutoMPositiontaking]
	@custid int,
	--um1
	@auto_mpositiontaking_mem_1 smallmoney = 0,
	@auto_mpositiontaking_mem_2 smallmoney = 0,
	@auto_mpositiontaking_mem_3 smallmoney = 0,
	@auto_mpositiontaking_mem_4 smallmoney = 0,
	@auto_mpositiontaking_mem_5 smallmoney= 0,
	@auto_mpositiontaking_mem_6 smallmoney = 0,
	@auto_mpositiontaking_mem_7 smallmoney = 0,
	@auto_mpositiontaking_mem_8 smallmoney = 0,
	@auto_mpositiontaking_mem_9 smallmoney = 0,
	@auto_mpositiontaking_mem_10 smallmoney = 0,
	@auto_mlivepositiontaking_mem_1 smallmoney = 0,
	@auto_mlivepositiontaking_mem_3 smallmoney = 0,
	@auto_mlivepositiontaking_mem_7 smallmoney = 0,
	@auto_mlivepositiontaking_mem_8 smallmoney = 0,
	
	@auto_v2mpositiontaking_mem_1 smallmoney = 0,
	@auto_v2mpositiontaking_mem_2 smallmoney = 0,
	@auto_v2mpositiontaking_mem_3 smallmoney = 0,
	@auto_v2mpositiontaking_mem_7 smallmoney = 0, 
	@auto_v2mpositiontaking_mem_8 smallmoney = 0,
	@auto_v2mpositiontaking_mem_9 smallmoney = 0,
	@auto_v2mpositiontaking_mem_20 smallmoney = 0,
	
	@auto_v3mpositiontaking_mem_1 smallmoney = 0,
	@auto_v3mpositiontaking_mem_2 smallmoney = 0,
	@auto_v3mpositiontaking_mem_3 smallmoney = 0,
	@auto_v3mpositiontaking_mem_20 smallmoney = 0,

	@auto_v5mpositiontaking_mem_1 smallmoney = 0,
	@auto_v5mpositiontaking_mem_2 smallmoney = 0,
	@auto_v5mpositiontaking_mem_3 smallmoney = 0,
	@auto_v5mpositiontaking_mem_20 smallmoney = 0,

	@auto_v8mpositiontaking_mem_1 smallmoney = 0,
	@auto_v8mpositiontaking_mem_3 smallmoney = 0,
	@auto_v8mpositiontaking_mem_20 smallmoney = 0,

	@auto_v10mpositiontaking_mem_1 smallmoney = 0,
	@auto_v10mpositiontaking_mem_2 smallmoney = 0,
	@auto_v10mpositiontaking_mem_3 smallmoney = 0,
	@auto_v10mpositiontaking_mem_20 smallmoney = 0,

	@auto_v11mpositiontaking_mem_1 smallmoney = 0,
	@auto_v11mpositiontaking_mem_20 smallmoney = 0,

	@auto_v99mpositiontaking_mem_1 smallmoney = 0,
	@auto_v99mpositiontaking_mem_2 smallmoney = 0,
	@auto_v99mpositiontaking_mem_3 smallmoney = 0,
	@auto_v99mpositiontaking_mem_20 smallmoney = 0,
	--im1
	@isauto_mpositiontaking_mem_1 bit = 0,
	@isauto_mpositiontaking_mem_2 bit = 0,
	@isauto_mpositiontaking_mem_3 bit = 0,
	@isauto_mpositiontaking_mem_4 bit = 0,
	@isauto_mpositiontaking_mem_5 bit= 0,
	@isauto_mpositiontaking_mem_6 bit = 0,
	@isauto_mpositiontaking_mem_7 bit = 0,
	@isauto_mpositiontaking_mem_8 bit = 0,
	@isauto_mpositiontaking_mem_9 bit = 0,
	@isauto_mpositiontaking_mem_10 bit = 0,
	
	@isauto_mlivepositiontaking_mem_1 bit = 0,
	@isauto_mlivepositiontaking_mem_3 bit = 0,
	@isauto_mlivepositiontaking_mem_7 bit = 0,
	@isauto_mlivepositiontaking_mem_8 bit = 0,
	
	@isauto_v2mpositiontaking_mem_1 bit = 0,
	@isauto_v2mpositiontaking_mem_2 bit = 0,
	@isauto_v2mpositiontaking_mem_3 bit = 0,
	@isauto_v2mpositiontaking_mem_7 bit = 0,
	@isauto_v2mpositiontaking_mem_8 bit = 0,
	@isauto_v2mpositiontaking_mem_9 bit = 0,
	@isauto_v2mpositiontaking_mem_20 bit = 0,
	
	@isauto_v3mpositiontaking_mem_1 bit = 0,
	@isauto_v3mpositiontaking_mem_2 bit = 0,
	@isauto_v3mpositiontaking_mem_3 bit = 0,
	@isauto_v3mpositiontaking_mem_20 bit = 0,

	@isauto_v5mpositiontaking_mem_1 bit = 0,
	@isauto_v5mpositiontaking_mem_2 bit = 0,
	@isauto_v5mpositiontaking_mem_3 bit = 0,
	@isauto_v5mpositiontaking_mem_20 bit = 0,

	@isauto_v8mpositiontaking_mem_1 bit = 0,
	@isauto_v8mpositiontaking_mem_3 bit = 0,
	@isauto_v8mpositiontaking_mem_20 bit = 0,

	@isauto_v10mpositiontaking_mem_1 bit = 0,
	@isauto_v10mpositiontaking_mem_2 bit = 0,
	@isauto_v10mpositiontaking_mem_3 bit = 0,
	@isauto_v10mpositiontaking_mem_20 bit = 0,

	@isauto_v11mpositiontaking_mem_1 bit = 0,
	@isauto_v11mpositiontaking_mem_20 bit = 0,

	@isauto_v99mpositiontaking_mem_1 bit = 0,
	@isauto_v99mpositiontaking_mem_2 bit = 0,
	@isauto_v99mpositiontaking_mem_3 bit = 0,
	@isauto_v99mpositiontaking_mem_20 bit = 0,

	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT,
	@language varchar(2) = 'E',
	@userid int
AS
--@Source Control
/*
Created: 20090619@Phuc
Task : Update master auto PT at member level
DB: DB02.bodb02

Revisions:
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/



SET NOCOUNT ON
Declare @bettype int,
	@autopositiontaking smallmoney, 	
	@isautopositiontaking bit,	
	
	@autolivepositiontaking smallmoney,
	@isautolivepositiontaking bit,	

	@maxpos smallmoney,	
	
	@autov2positiontaking smallmoney,
	@isautov2positiontaking bit, 

	@autov3positiontaking smallmoney,
	@isautov3positiontaking bit, 

	@autov5positiontaking smallmoney,
	@isautov5positiontaking bit, 

	@autov8positiontaking smallmoney,
	@isautov8positiontaking bit, 

	@autov10positiontaking smallmoney,
	@isautov10positiontaking bit, 

	@autov11positiontaking smallmoney,
	@isautov11positiontaking bit, 

	@autov99positiontaking smallmoney,
	@isautov99positiontaking bit, 
	
	@srecommend int,
	@mrecommend int,
	@recommend int
declare 
	--um2
	@auto_mpositiontaking_1 smallmoney,
	@auto_mpositiontaking_2 smallmoney,
	@auto_mpositiontaking_3 smallmoney,
	@auto_mpositiontaking_4 smallmoney,
	@auto_mpositiontaking_5 smallmoney,
	@auto_mpositiontaking_6 smallmoney,
	@auto_mpositiontaking_7 smallmoney,
	@auto_mpositiontaking_8 smallmoney,
	@auto_mpositiontaking_9 smallmoney,
	@auto_mpositiontaking_10 smallmoney,
	
	@auto_mlivepositiontaking_1 smallmoney,
	@auto_mlivepositiontaking_3 smallmoney,
	@auto_mlivepositiontaking_7 smallmoney,
	@auto_mlivepositiontaking_8 smallmoney,
	
	@auto_v2mpositiontaking_1 smallmoney,
	@auto_v2mpositiontaking_2 smallmoney,
	@auto_v2mpositiontaking_3 smallmoney,
	@auto_v2mpositiontaking_7 smallmoney,
	@auto_v2mpositiontaking_8 smallmoney,
	@auto_v2mpositiontaking_9 smallmoney,
	@auto_v2mpositiontaking_20 smallmoney,
	
	@auto_v3mpositiontaking_1 smallmoney,
	@auto_v3mpositiontaking_2 smallmoney,
	@auto_v3mpositiontaking_3 smallmoney,
	@auto_v3mpositiontaking_20 smallmoney,

	@auto_v5mpositiontaking_1 smallmoney,
	@auto_v5mpositiontaking_2 smallmoney,
	@auto_v5mpositiontaking_3 smallmoney,
	@auto_v5mpositiontaking_20 smallmoney,

	@auto_v8mpositiontaking_1 smallmoney,
	@auto_v8mpositiontaking_3 smallmoney,
	@auto_v8mpositiontaking_20 smallmoney,

	@auto_v10mpositiontaking_1 smallmoney,
	@auto_v10mpositiontaking_2 smallmoney,
	@auto_v10mpositiontaking_3 smallmoney,
	@auto_v10mpositiontaking_20 smallmoney,

	@auto_v11mpositiontaking_1 smallmoney,
	@auto_v11mpositiontaking_20 smallmoney,

	@auto_v99mpositiontaking_1 smallmoney,
	@auto_v99mpositiontaking_2 smallmoney,
	@auto_v99mpositiontaking_3 smallmoney,
	@auto_v99mpositiontaking_20 smallmoney,
	
	--im2
	@isauto_mpositiontaking_1 bit,
	@isauto_mpositiontaking_2 bit,
	@isauto_mpositiontaking_3 bit,
	@isauto_mpositiontaking_4 bit,
	@isauto_mpositiontaking_5 bit,
	@isauto_mpositiontaking_6 bit,
	@isauto_mpositiontaking_7 bit,
	@isauto_mpositiontaking_8 bit,
	@isauto_mpositiontaking_9 bit,
	@isauto_mpositiontaking_10 bit,
	
	@isauto_mlivepositiontaking_1 bit,
	@isauto_mlivepositiontaking_3 bit,
	@isauto_mlivepositiontaking_7 bit,
	@isauto_mlivepositiontaking_8 bit,
	
	@isauto_v2mpositiontaking_1 bit,
	@isauto_v2mpositiontaking_2 bit,
	@isauto_v2mpositiontaking_3 bit,
	@isauto_v2mpositiontaking_7 bit,
	@isauto_v2mpositiontaking_8 bit,
	@isauto_v2mpositiontaking_9 bit,
	@isauto_v2mpositiontaking_20 bit,

	@isauto_v3mpositiontaking_1 bit,
	@isauto_v3mpositiontaking_2 bit,
	@isauto_v3mpositiontaking_3 bit,
	@isauto_v3mpositiontaking_20 bit,

	@isauto_v5mpositiontaking_1 bit,
	@isauto_v5mpositiontaking_2 bit,
	@isauto_v5mpositiontaking_3 bit,
	@isauto_v5mpositiontaking_20 bit,

	@isauto_v8mpositiontaking_1 bit,
	@isauto_v8mpositiontaking_3 bit,
	@isauto_v8mpositiontaking_20 bit,

	@isauto_v10mpositiontaking_1 bit,
	@isauto_v10mpositiontaking_2 bit,
	@isauto_v10mpositiontaking_3 bit,
	@isauto_v10mpositiontaking_20 bit,

	@isauto_v11mpositiontaking_1 bit,
	@isauto_v11mpositiontaking_20 bit,

	@isauto_v99mpositiontaking_1 bit,
	@isauto_v99mpositiontaking_2 bit,
	@isauto_v99mpositiontaking_3 bit,
	@isauto_v99mpositiontaking_20 bit

select @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend from custinfo with (NOLOCK) where custid = @custid

--------------------------------------------------------
--Get Auto PT of member from agent
--um2,im2
select @auto_mpositiontaking_1 = autompositiontaking, @auto_mlivepositiontaking_1 = autolivempositiontaking, @isauto_mpositiontaking_1 = isautompositiontaking, @isauto_mlivepositiontaking_1 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=1 and sporttype=1
select @auto_mpositiontaking_3 = autompositiontaking, @auto_mlivepositiontaking_3 = autolivempositiontaking, @isauto_mpositiontaking_3 = isautompositiontaking, @isauto_mlivepositiontaking_3 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=3 and sporttype=1
select @auto_mpositiontaking_7 = autompositiontaking, @auto_mlivepositiontaking_7 = autolivempositiontaking, @isauto_mpositiontaking_7 = isautompositiontaking, @isauto_mlivepositiontaking_7 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=7 and sporttype=1
select @auto_mpositiontaking_8 = autompositiontaking, @auto_mlivepositiontaking_8 = autolivempositiontaking, @isauto_mpositiontaking_8 = isautompositiontaking, @isauto_mlivepositiontaking_8 = isautolivempositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=8 and sporttype=1
select @auto_mpositiontaking_2 = autompositiontaking, @isauto_mpositiontaking_2 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=2 and sporttype=1
select @auto_mpositiontaking_4 = autompositiontaking, @isauto_mpositiontaking_4 = isautompositiontaking from custsetting with (NOLOCK) where custid = @recommend and bettype=4 and sporttype=1
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


--------------------------------------------------------

--Update Member account (autompositiontaking field)
update custsetting with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autompositiontaking, autolivempositiontaking = b.autolivempositiontaking, isautompositiontaking = b.isautompositiontaking, isautolivempositiontaking = b.isautolivempositiontaking
from custsetting inner join 
		(
						select 1 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_1 as autompositiontaking, @auto_mlivepositiontaking_mem_1	as autolivempositiontaking, @isauto_mpositiontaking_mem_1 as isautompositiontaking, @isauto_mlivepositiontaking_mem_1	as isautolivempositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_2 as autompositiontaking, 0				as autolivempositiontaking, @isauto_mpositiontaking_mem_2 as isautompositiontaking, 0				as isautolivempositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_3 as autompositiontaking, @auto_mlivepositiontaking_mem_3 	as autolivempositiontaking, @isauto_mpositiontaking_mem_3 as isautompositiontaking, @isauto_mlivepositiontaking_mem_3	as isautolivempositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_4 as autompositiontaking, 0				as autolivempositiontaking, @isauto_mpositiontaking_mem_4 as isautompositiontaking, 0				as isautolivempositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_5 as autompositiontaking, 0				as autolivempositiontaking, @isauto_mpositiontaking_mem_5 as isautompositiontaking, 0				as isautolivempositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_6 as autompositiontaking, 0				as autolivempositiontaking, @isauto_mpositiontaking_mem_6 as isautompositiontaking, 0				as isautolivempositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_7 as autompositiontaking, @auto_mlivepositiontaking_mem_7 	as autolivempositiontaking, @isauto_mpositiontaking_mem_7 as isautompositiontaking, @isauto_mlivepositiontaking_mem_7	as isautolivempositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_8 as autompositiontaking, @auto_mlivepositiontaking_mem_8 	as autolivempositiontaking, @isauto_mpositiontaking_mem_8 as isautompositiontaking, @isauto_mlivepositiontaking_mem_8	as isautolivempositiontaking			
			union all 	select 9 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_9 as autompositiontaking, 0				as autolivempositiontaking, @isauto_mpositiontaking_mem_9 as isautompositiontaking, 0				as isautolivempositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @auto_mpositiontaking_mem_10 as autompositiontaking, 0				as autolivempositiontaking, @isauto_mpositiontaking_mem_10 as isautompositiontaking, 0				as isautolivempositiontaking
			
			union all 	select 1 as bettype, 2 as sporttype, @auto_v2mpositiontaking_mem_1 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v2mpositiontaking_mem_1 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @auto_v2mpositiontaking_mem_2 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v2mpositiontaking_mem_2 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @auto_v2mpositiontaking_mem_3 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v2mpositiontaking_mem_3 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 7 as bettype, 2 as sporttype, @auto_v2mpositiontaking_mem_7 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v2mpositiontaking_mem_7 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 8 as bettype, 2 as sporttype, @auto_v2mpositiontaking_mem_8 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v2mpositiontaking_mem_8 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @auto_v2mpositiontaking_mem_9 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v2mpositiontaking_mem_9 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @auto_v2mpositiontaking_mem_20 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v2mpositiontaking_mem_20 as isautompositiontaking, 0	as isautolivempositiontaking
			
			union all 	select 1 as bettype, 3 as sporttype, @auto_v3mpositiontaking_mem_1 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v3mpositiontaking_mem_1 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @auto_v3mpositiontaking_mem_2 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v3mpositiontaking_mem_2 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @auto_v3mpositiontaking_mem_3 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v3mpositiontaking_mem_3 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @auto_v3mpositiontaking_mem_20 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v3mpositiontaking_mem_20 as isautompositiontaking, 0	as isautolivempositiontaking

			union all 	select 1 as bettype, 5 as sporttype, @auto_v5mpositiontaking_mem_1 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v5mpositiontaking_mem_1 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @auto_v5mpositiontaking_mem_2 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v5mpositiontaking_mem_2 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @auto_v5mpositiontaking_mem_3 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v5mpositiontaking_mem_3 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @auto_v5mpositiontaking_mem_20 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v5mpositiontaking_mem_20 as isautompositiontaking, 0	as isautolivempositiontaking

			union all 	select 1 as bettype, 8 as sporttype, @auto_v8mpositiontaking_mem_1 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v8mpositiontaking_mem_1 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @auto_v8mpositiontaking_mem_3 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v8mpositiontaking_mem_3 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @auto_v8mpositiontaking_mem_20 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v8mpositiontaking_mem_20 as isautompositiontaking, 0	as isautolivempositiontaking

			union all 	select 1 as bettype, 10 as sporttype, @auto_v10mpositiontaking_mem_1 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v10mpositiontaking_mem_1 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @auto_v10mpositiontaking_mem_2 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v10mpositiontaking_mem_2 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @auto_v10mpositiontaking_mem_3 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v10mpositiontaking_mem_3 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @auto_v10mpositiontaking_mem_20 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v10mpositiontaking_mem_20 as isautompositiontaking, 0	as isautolivempositiontaking

			union all 	select 1 as bettype, 11 as sporttype, @auto_v11mpositiontaking_mem_1 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v11mpositiontaking_mem_1 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @auto_v11mpositiontaking_mem_20 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v11mpositiontaking_mem_20 as isautompositiontaking, 0	as isautolivempositiontaking

			union all 	select 1 as bettype, 99 as sporttype, @auto_v99mpositiontaking_mem_1 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v99mpositiontaking_mem_1 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @auto_v99mpositiontaking_mem_2 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v99mpositiontaking_mem_2 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @auto_v99mpositiontaking_mem_3 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v99mpositiontaking_mem_3 as isautompositiontaking, 0	as isautolivempositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @auto_v99mpositiontaking_mem_20 as autompositiontaking, 0	as autolivempositiontaking, @isauto_v99mpositiontaking_mem_20 as isautompositiontaking, 0	as isautolivempositiontaking
		
		) as b on b.bettype = custsetting.bettype and b.sporttype = custsetting.sporttype
where custsetting.custid = @custid
if @@Error <> 0
BEGIN
	
	SELECT @ErrCode = 101,
			@ErrMsg =  
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
	return
END
	
---------------------------------------------------------------------------------------------------------------------------------------------
--CHOOSE MEMBER AUTOPOSITIONTAKING IF MEMBER IS SET AUTO (regardless of the setting in agent account)
select 
	@auto_mpositiontaking_1 = case when @isauto_mpositiontaking_mem_1>0 then @auto_mpositiontaking_mem_1 else @auto_mpositiontaking_1 end,
	@auto_mpositiontaking_2 = case when @isauto_mpositiontaking_mem_2>0 then @auto_mpositiontaking_mem_2 else @auto_mpositiontaking_2 end,
	@auto_mpositiontaking_3 = case when @isauto_mpositiontaking_mem_3>0 then @auto_mpositiontaking_mem_3 else @auto_mpositiontaking_3 end,
	@auto_mpositiontaking_4 = case when @isauto_mpositiontaking_mem_4>0 then @auto_mpositiontaking_mem_4 else @auto_mpositiontaking_4 end,
	@auto_mpositiontaking_5 = case when @isauto_mpositiontaking_mem_5>0 then @auto_mpositiontaking_mem_5 else @auto_mpositiontaking_5 end,
	@auto_mpositiontaking_6 = case when @isauto_mpositiontaking_mem_6>0 then @auto_mpositiontaking_mem_6 else @auto_mpositiontaking_6 end,
	@auto_mpositiontaking_7 = case when @isauto_mpositiontaking_mem_7>0 then @auto_mpositiontaking_mem_7 else @auto_mpositiontaking_7 end,
	@auto_mpositiontaking_8 = case when @isauto_mpositiontaking_mem_8>0 then @auto_mpositiontaking_mem_8 else @auto_mpositiontaking_8 end,
	@auto_mpositiontaking_9 = case when @isauto_mpositiontaking_mem_9>0 then @auto_mpositiontaking_mem_9 else @auto_mpositiontaking_9 end,
	@auto_mpositiontaking_10 = case when @isauto_mpositiontaking_mem_10>0 then @auto_mpositiontaking_mem_10 else @auto_mpositiontaking_10 end,

	@auto_mlivepositiontaking_1 = case when @isauto_mlivepositiontaking_mem_1>0 then @auto_mlivepositiontaking_mem_1 else @auto_mlivepositiontaking_1 end,
	@auto_mlivepositiontaking_3 = case when @isauto_mlivepositiontaking_mem_3>0 then @auto_mlivepositiontaking_mem_3 else @auto_mlivepositiontaking_3 end,
	@auto_mlivepositiontaking_7 = case when @isauto_mlivepositiontaking_mem_7>0 then @auto_mlivepositiontaking_mem_7 else @auto_mlivepositiontaking_7 end,
	@auto_mlivepositiontaking_8 = case when @isauto_mlivepositiontaking_mem_8>0 then @auto_mlivepositiontaking_mem_8 else @auto_mlivepositiontaking_8 end,

	@auto_v2mpositiontaking_1 = case when @isauto_v2mpositiontaking_mem_1>0 then @auto_v2mpositiontaking_mem_1 else @auto_v2mpositiontaking_1 end,
	@auto_v2mpositiontaking_2 = case when @isauto_v2mpositiontaking_mem_2>0 then @auto_v2mpositiontaking_mem_2 else @auto_v2mpositiontaking_2 end,
	@auto_v2mpositiontaking_3 = case when @isauto_v2mpositiontaking_mem_3>0 then @auto_v2mpositiontaking_mem_3 else @auto_v2mpositiontaking_3 end,
	@auto_v2mpositiontaking_7 = case when @isauto_v2mpositiontaking_mem_7>0 then @auto_v2mpositiontaking_mem_7 else @auto_v2mpositiontaking_7 end,
	@auto_v2mpositiontaking_8 = case when @isauto_v2mpositiontaking_mem_8>0 then @auto_v2mpositiontaking_mem_8 else @auto_v2mpositiontaking_8 end,
	@auto_v2mpositiontaking_9 = case when @isauto_v2mpositiontaking_mem_9>0 then @auto_v2mpositiontaking_mem_9 else @auto_v2mpositiontaking_9 end,
	@auto_v2mpositiontaking_20 = case when @isauto_v2mpositiontaking_mem_20>0 then @auto_v2mpositiontaking_mem_20 else @auto_v2mpositiontaking_20 end,
	
	@auto_v3mpositiontaking_1 = case when @isauto_v3mpositiontaking_mem_1>0 then @auto_v3mpositiontaking_mem_1 else @auto_v3mpositiontaking_1 end,
	@auto_v3mpositiontaking_2 = case when @isauto_v3mpositiontaking_mem_2>0 then @auto_v3mpositiontaking_mem_2 else @auto_v3mpositiontaking_2 end,
	@auto_v3mpositiontaking_3 = case when @isauto_v3mpositiontaking_mem_3>0 then @auto_v3mpositiontaking_mem_3 else @auto_v3mpositiontaking_3 end,
	@auto_v3mpositiontaking_20 = case when @isauto_v3mpositiontaking_mem_20>0 then @auto_v3mpositiontaking_mem_20 else @auto_v3mpositiontaking_20 end,
	
	@auto_v5mpositiontaking_1 = case when @isauto_v5mpositiontaking_mem_1>0 then @auto_v5mpositiontaking_mem_1 else @auto_v5mpositiontaking_1 end,
	@auto_v5mpositiontaking_2 = case when @isauto_v5mpositiontaking_mem_2>0 then @auto_v5mpositiontaking_mem_2 else @auto_v5mpositiontaking_2 end,
	@auto_v5mpositiontaking_3 = case when @isauto_v5mpositiontaking_mem_3>0 then @auto_v5mpositiontaking_mem_3 else @auto_v5mpositiontaking_3 end,
	@auto_v5mpositiontaking_20 = case when @isauto_v5mpositiontaking_mem_20>0 then @auto_v5mpositiontaking_mem_20 else @auto_v5mpositiontaking_20 end,
	
	@auto_v8mpositiontaking_1 = case when @isauto_v8mpositiontaking_mem_1>0 then @auto_v8mpositiontaking_mem_1 else @auto_v8mpositiontaking_1 end,
	@auto_v8mpositiontaking_3 = case when @isauto_v8mpositiontaking_mem_3>0 then @auto_v8mpositiontaking_mem_3 else @auto_v8mpositiontaking_3 end,
	@auto_v8mpositiontaking_20 = case when @isauto_v8mpositiontaking_mem_20>0 then @auto_v8mpositiontaking_mem_20 else @auto_v8mpositiontaking_20 end,
	
	@auto_v10mpositiontaking_1 = case when @isauto_v10mpositiontaking_mem_1>0 then @auto_v10mpositiontaking_mem_1 else @auto_v10mpositiontaking_1 end,
	@auto_v10mpositiontaking_2 = case when @isauto_v10mpositiontaking_mem_2>0 then @auto_v10mpositiontaking_mem_2 else @auto_v10mpositiontaking_2 end,
	@auto_v10mpositiontaking_3 = case when @isauto_v10mpositiontaking_mem_3>0 then @auto_v10mpositiontaking_mem_3 else @auto_v10mpositiontaking_3 end,
	@auto_v10mpositiontaking_20 = case when @isauto_v10mpositiontaking_mem_20>0 then @auto_v10mpositiontaking_mem_20 else @auto_v10mpositiontaking_20 end,

	@auto_v11mpositiontaking_1 = case when @isauto_v11mpositiontaking_mem_1>0 then @auto_v11mpositiontaking_mem_1 else @auto_v11mpositiontaking_1 end,
	@auto_v11mpositiontaking_20 = case when @isauto_v11mpositiontaking_mem_20>0 then @auto_v11mpositiontaking_mem_20 else @auto_v11mpositiontaking_20 end,

	@auto_v99mpositiontaking_1 = case when @isauto_v99mpositiontaking_mem_1>0 then @auto_v99mpositiontaking_mem_1 else @auto_v99mpositiontaking_1 end,
	@auto_v99mpositiontaking_2 = case when @isauto_v99mpositiontaking_mem_2>0 then @auto_v99mpositiontaking_mem_2 else @auto_v99mpositiontaking_2 end,
	@auto_v99mpositiontaking_3 = case when @isauto_v99mpositiontaking_mem_3>0 then @auto_v99mpositiontaking_mem_3 else @auto_v99mpositiontaking_3 end,
	@auto_v99mpositiontaking_20 = case when @isauto_v99mpositiontaking_mem_20>0 then @auto_v99mpositiontaking_mem_20 else @auto_v99mpositiontaking_20 end,

	@isauto_mpositiontaking_1 = case when @isauto_mpositiontaking_mem_1>0 then @isauto_mpositiontaking_mem_1 else @isauto_mpositiontaking_1 end,
	@isauto_mpositiontaking_2 = case when @isauto_mpositiontaking_mem_2>0 then @isauto_mpositiontaking_mem_2 else @isauto_mpositiontaking_2 end,
	@isauto_mpositiontaking_3 = case when @isauto_mpositiontaking_mem_3>0 then @isauto_mpositiontaking_mem_3 else @isauto_mpositiontaking_3 end,
	@isauto_mpositiontaking_4 = case when @isauto_mpositiontaking_mem_4>0 then @isauto_mpositiontaking_mem_4 else @isauto_mpositiontaking_4 end,
	@isauto_mpositiontaking_5 = case when @isauto_mpositiontaking_mem_5>0 then @isauto_mpositiontaking_mem_5 else @isauto_mpositiontaking_5 end,
	@isauto_mpositiontaking_6 = case when @isauto_mpositiontaking_mem_6>0 then @isauto_mpositiontaking_mem_6 else @isauto_mpositiontaking_6 end,
	@isauto_mpositiontaking_7 = case when @isauto_mpositiontaking_mem_7>0 then @isauto_mpositiontaking_mem_7 else @isauto_mpositiontaking_7 end,
	@isauto_mpositiontaking_8 = case when @isauto_mpositiontaking_mem_8>0 then @isauto_mpositiontaking_mem_8 else @isauto_mpositiontaking_8 end,
	@isauto_mpositiontaking_9 = case when @isauto_mpositiontaking_mem_9>0 then @isauto_mpositiontaking_mem_9 else @isauto_mpositiontaking_9 end,
	@isauto_mpositiontaking_10 = case when @isauto_mpositiontaking_mem_10>0 then @isauto_mpositiontaking_mem_10 else @isauto_mpositiontaking_10 end,

	@isauto_mlivepositiontaking_1 = case when @isauto_mlivepositiontaking_mem_1>0 then @isauto_mlivepositiontaking_mem_1 else @isauto_mlivepositiontaking_1 end,
	@isauto_mlivepositiontaking_3 = case when @isauto_mlivepositiontaking_mem_3>0 then @isauto_mlivepositiontaking_mem_3 else @isauto_mlivepositiontaking_3 end,
	@isauto_mlivepositiontaking_7 = case when @isauto_mlivepositiontaking_mem_7>0 then @isauto_mlivepositiontaking_mem_7 else @isauto_mlivepositiontaking_7 end,
	@isauto_mlivepositiontaking_8 = case when @isauto_mlivepositiontaking_mem_8>0 then @isauto_mlivepositiontaking_mem_8 else @isauto_mlivepositiontaking_8 end,

	@isauto_v2mpositiontaking_1 = case when @isauto_v2mpositiontaking_mem_1>0 then @isauto_v2mpositiontaking_mem_1 else @isauto_v2mpositiontaking_1 end,
	@isauto_v2mpositiontaking_2 = case when @isauto_v2mpositiontaking_mem_2>0 then @isauto_v2mpositiontaking_mem_2 else @isauto_v2mpositiontaking_2 end,
	@isauto_v2mpositiontaking_3 = case when @isauto_v2mpositiontaking_mem_3>0 then @isauto_v2mpositiontaking_mem_3 else @isauto_v2mpositiontaking_3 end,
	@isauto_v2mpositiontaking_7 = case when @isauto_v2mpositiontaking_mem_7>0 then @isauto_v2mpositiontaking_mem_7 else @isauto_v2mpositiontaking_7 end,
	@isauto_v2mpositiontaking_8 = case when @isauto_v2mpositiontaking_mem_8>0 then @isauto_v2mpositiontaking_mem_8 else @isauto_v2mpositiontaking_8 end,
	@isauto_v2mpositiontaking_9 = case when @isauto_v2mpositiontaking_mem_9>0 then @isauto_v2mpositiontaking_mem_9 else @isauto_v2mpositiontaking_9 end,
	@isauto_v2mpositiontaking_20 = case when @isauto_v2mpositiontaking_mem_20>0 then @isauto_v2mpositiontaking_mem_20 else @isauto_v2mpositiontaking_20 end,

	@isauto_v3mpositiontaking_1 = case when @isauto_v3mpositiontaking_mem_1>0 then @isauto_v3mpositiontaking_mem_1 else @isauto_v3mpositiontaking_1 end,
	@isauto_v3mpositiontaking_2 = case when @isauto_v3mpositiontaking_mem_2>0 then @isauto_v3mpositiontaking_mem_2 else @isauto_v3mpositiontaking_2 end,
	@isauto_v3mpositiontaking_3 = case when @isauto_v3mpositiontaking_mem_3>0 then @isauto_v3mpositiontaking_mem_3 else @isauto_v3mpositiontaking_3 end,
	@isauto_v3mpositiontaking_20 = case when @isauto_v3mpositiontaking_mem_20>0 then @isauto_v3mpositiontaking_mem_20 else @isauto_v3mpositiontaking_20 end,

	@isauto_v5mpositiontaking_1 = case when @isauto_v5mpositiontaking_mem_1>0 then @isauto_v5mpositiontaking_mem_1 else @isauto_v5mpositiontaking_1 end,
	@isauto_v5mpositiontaking_2 = case when @isauto_v5mpositiontaking_mem_2>0 then @isauto_v5mpositiontaking_mem_2 else @isauto_v5mpositiontaking_2 end,
	@isauto_v5mpositiontaking_3 = case when @isauto_v5mpositiontaking_mem_3>0 then @isauto_v5mpositiontaking_mem_3 else @isauto_v5mpositiontaking_3 end,
	@isauto_v5mpositiontaking_20 = case when @isauto_v5mpositiontaking_mem_20>0 then @isauto_v5mpositiontaking_mem_20 else @isauto_v5mpositiontaking_20 end,

	@isauto_v8mpositiontaking_1 = case when @isauto_v8mpositiontaking_mem_1>0 then @isauto_v8mpositiontaking_mem_1 else @isauto_v8mpositiontaking_1 end,
	@isauto_v8mpositiontaking_3 = case when @isauto_v8mpositiontaking_mem_3>0 then @isauto_v8mpositiontaking_mem_3 else @isauto_v8mpositiontaking_3 end,
	@isauto_v8mpositiontaking_20 = case when @isauto_v8mpositiontaking_mem_20>0 then @isauto_v8mpositiontaking_mem_20 else @isauto_v8mpositiontaking_20 end,

	@isauto_v10mpositiontaking_1 = case when @isauto_v10mpositiontaking_mem_1>0 then @isauto_v10mpositiontaking_mem_1 else @isauto_v10mpositiontaking_1 end,
	@isauto_v10mpositiontaking_2 = case when @isauto_v10mpositiontaking_mem_2>0 then @isauto_v10mpositiontaking_mem_2 else @isauto_v10mpositiontaking_2 end,
	@isauto_v10mpositiontaking_3 = case when @isauto_v10mpositiontaking_mem_3>0 then @isauto_v10mpositiontaking_mem_3 else @isauto_v10mpositiontaking_3 end,
	@isauto_v10mpositiontaking_20 = case when @isauto_v10mpositiontaking_mem_20>0 then @isauto_v10mpositiontaking_mem_20 else @isauto_v10mpositiontaking_20 end,

	@isauto_v11mpositiontaking_1 = case when @isauto_v11mpositiontaking_mem_1>0 then @isauto_v11mpositiontaking_mem_1 else @isauto_v11mpositiontaking_1 end,
	@isauto_v11mpositiontaking_20 = case when @isauto_v11mpositiontaking_mem_20>0 then @isauto_v11mpositiontaking_mem_20 else @isauto_v11mpositiontaking_20 end,

	@isauto_v99mpositiontaking_1 = case when @isauto_v99mpositiontaking_mem_1>0 then @isauto_v99mpositiontaking_mem_1 else @isauto_v99mpositiontaking_1 end,
	@isauto_v99mpositiontaking_2 = case when @isauto_v99mpositiontaking_mem_2>0 then @isauto_v99mpositiontaking_mem_2 else @isauto_v99mpositiontaking_2 end,
	@isauto_v99mpositiontaking_3 = case when @isauto_v99mpositiontaking_mem_3>0 then @isauto_v99mpositiontaking_mem_3 else @isauto_v99mpositiontaking_3 end,
	@isauto_v99mpositiontaking_20 = case when @isauto_v99mpositiontaking_mem_20>0 then @isauto_v99mpositiontaking_mem_20 else @isauto_v99mpositiontaking_20 end
---------------------------------------------------------------------------------------------------------------------------------------------

	--Update member account
	--Using Cursor (mpositiontaking field)
	DECLARE CUR CURSOR FOR 
			SELECT 1 AS bettype		,		   @isauto_mpositiontaking_1 AS isautopositiontaking		,		  @isauto_mlivepositiontaking_1 AS isautolivepositiontaking		,		  @auto_mpositiontaking_1 AS autopositiontaking	    	,		   @auto_mlivepositiontaking_1 AS autolivepositiontaking		,		   @isauto_v2mpositiontaking_1 AS isautov2positiontaking		,		   @auto_v2mpositiontaking_1 AS autov2positiontaking		,		@isauto_v3mpositiontaking_1 AS isautov3positiontaking		,		   @auto_v3mpositiontaking_1 AS autov3positiontaking,			@isauto_v5mpositiontaking_1 AS isautov5positiontaking		,		   @auto_v5mpositiontaking_1 AS autov5positiontaking		,		@isauto_v8mpositiontaking_1 AS isautov8positiontaking		,		   @auto_v8mpositiontaking_1 AS autov8positiontaking		,		@isauto_v10mpositiontaking_1 AS isautov10positiontaking		,		   @auto_v10mpositiontaking_1 AS autov10positiontaking		,		@isauto_v11mpositiontaking_1 AS isautov11positiontaking		,		   @auto_v11mpositiontaking_1 AS autov11positiontaking		,		@isauto_v99mpositiontaking_1 AS isautov99positiontaking		,		   @auto_v99mpositiontaking_1 AS autov99positiontaking	
UNION ALL  	SELECT 2 AS bettype		,		   @isauto_mpositiontaking_2 AS isautopositiontaking		,									0 AS isautolivepositiontaking		,		  @auto_mpositiontaking_2 AS autopositiontaking	    	,									 0 AS autolivepositiontaking		,		   @isauto_v2mpositiontaking_2 AS isautov2positiontaking		,		   @auto_v2mpositiontaking_2 AS autov2positiontaking		,		@isauto_v3mpositiontaking_2 AS isautov3positiontaking		,		   @auto_v3mpositiontaking_2 AS autov3positiontaking,			@isauto_v5mpositiontaking_2 AS isautov5positiontaking		,		   @auto_v5mpositiontaking_2 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									0 AS autov8positiontaking		,		@isauto_v10mpositiontaking_2 AS isautov10positiontaking		,		   @auto_v10mpositiontaking_2 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,		@isauto_v99mpositiontaking_2 AS isautov99positiontaking		,		   @auto_v99mpositiontaking_2 AS autov99positiontaking	
UNION ALL 	SELECT 3 AS bettype		,		   @isauto_mpositiontaking_3 AS isautopositiontaking		,		  @isauto_mlivepositiontaking_3 AS isautolivepositiontaking		,		   @auto_mpositiontaking_3 AS autopositiontaking		,		   @auto_mlivepositiontaking_3 AS autolivepositiontaking		,		   @isauto_v2mpositiontaking_3 AS isautov2positiontaking		,		   @auto_v2mpositiontaking_3 AS autov2positiontaking		,		@isauto_v3mpositiontaking_3 AS isautov3positiontaking		,		   @auto_v3mpositiontaking_3 AS autov3positiontaking,			@isauto_v5mpositiontaking_3 AS isautov5positiontaking		,		   @auto_v5mpositiontaking_3 AS autov5positiontaking		,		@isauto_v8mpositiontaking_3 AS isautov8positiontaking		,		   @auto_v8mpositiontaking_3 AS autov8positiontaking		,		@isauto_v10mpositiontaking_3 AS isautov10positiontaking		,		   @auto_v10mpositiontaking_3 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,		@isauto_v99mpositiontaking_3 AS isautov99positiontaking		,		   @auto_v99mpositiontaking_3 AS autov99positiontaking	
UNION ALL  	SELECT 4 AS bettype		,		   @isauto_mpositiontaking_4 AS isautopositiontaking		,									0 AS isautolivepositiontaking		,		   @auto_mpositiontaking_4 AS autopositiontaking		,									 0 AS autolivepositiontaking		,										0 AS isautov2positiontaking		,									0 AS autov2positiontaking		,									0 AS isautov3positiontaking		,									0 AS autov3positiontaking,										0 AS isautov5positiontaking		,									0 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									0 AS autov8positiontaking		,								0 AS isautov10positiontaking		,									0 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,								0 AS isautov99positiontaking		,									0 AS autov99positiontaking	
UNION ALL 	SELECT 5 AS bettype		,		   @isauto_mpositiontaking_5 AS isautopositiontaking		,									0 AS isautolivepositiontaking		,		   @auto_mpositiontaking_5 AS autopositiontaking		,									 0 AS autolivepositiontaking		,										0 AS isautov2positiontaking		,									0 AS autov2positiontaking		,									0 AS isautov3positiontaking		,									0 AS autov3positiontaking,										0 AS isautov5positiontaking		,									0 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									0 AS autov8positiontaking		,								0 AS isautov10positiontaking		,									0 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,								0 AS isautov99positiontaking		,									0 AS autov99positiontaking	
UNION ALL  	SELECT 6 AS bettype		,		   @isauto_mpositiontaking_6 AS isautopositiontaking		,									0 AS isautolivepositiontaking		,		   @auto_mpositiontaking_6 AS autopositiontaking		,									 0 AS autolivepositiontaking		,										0 AS isautov2positiontaking		,									0 AS autov2positiontaking		,									0 AS isautov3positiontaking		,									0 AS autov3positiontaking,										0 AS isautov5positiontaking		,									0 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									0 AS autov8positiontaking		,								0 AS isautov10positiontaking		,									0 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,								0 AS isautov99positiontaking		,									0 AS autov99positiontaking	
UNION ALL  	SELECT 7 AS bettype		,		   @isauto_mpositiontaking_7 AS isautopositiontaking		,		  @isauto_mlivepositiontaking_7 AS isautolivepositiontaking		,		  @auto_mpositiontaking_7 AS autopositiontaking	    	,		   @auto_mlivepositiontaking_7 AS autolivepositiontaking		,		   @isauto_v2mpositiontaking_7 AS isautov2positiontaking		,		   @auto_v2mpositiontaking_7 AS autov2positiontaking		,									0 AS isautov3positiontaking		,									0 AS autov3positiontaking,										0 AS isautov5positiontaking		,									0 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									 0 AS autov8positiontaking		,								0 AS isautov10positiontaking		,									0 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,								0 AS isautov99positiontaking		,									0 AS autov99positiontaking	
UNION ALL  	SELECT 8 AS bettype		,		   @isauto_mpositiontaking_8 AS isautopositiontaking		,		  @isauto_mlivepositiontaking_8 AS isautolivepositiontaking		,		  @auto_mpositiontaking_8 AS autopositiontaking	    	,		   @auto_mlivepositiontaking_8 AS autolivepositiontaking		,		   @isauto_v2mpositiontaking_8 AS isautov2positiontaking		,		   @auto_v2mpositiontaking_8 AS autov2positiontaking		,									0 AS isautov3positiontaking		,									0 AS autov3positiontaking,										0 AS isautov5positiontaking		,									0 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									 0 AS autov8positiontaking		,								0 AS isautov10positiontaking		,									0 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,								0 AS isautov99positiontaking		,									0 AS autov99positiontaking	
UNION ALL  	SELECT 9 AS bettype		,		   @isauto_mpositiontaking_9 AS isautopositiontaking		,									 0 AS isautolivepositiontaking		,		   @auto_mpositiontaking_9 AS autopositiontaking		,									 0 AS autolivepositiontaking		,		   @isauto_v2mpositiontaking_9 AS isautov2positiontaking		,		   @auto_v2mpositiontaking_9 AS autov2positiontaking		,									0 AS isautov3positiontaking		,									0 AS autov3positiontaking,										0 AS isautov5positiontaking		,									0 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									0 AS autov8positiontaking		,								0 AS isautov10positiontaking		,									0 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,								0 AS isautov99positiontaking		,									0 AS autov99positiontaking	
UNION ALL  	SELECT 10 AS bettype	,		   @isauto_mpositiontaking_10 AS isautopositiontaking		,									  0 AS isautolivepositiontaking		,		   @auto_mpositiontaking_10 AS autopositiontaking		,									 0 AS autolivepositiontaking		,										0 AS isautov2positiontaking		,									0 AS autov2positiontaking		,									0 AS isautov3positiontaking		,									0 AS autov3positiontaking,										0 AS isautov5positiontaking		,									0 AS autov5positiontaking		,									0 AS isautov8positiontaking		,									0 AS autov8positiontaking		,								0 AS isautov10positiontaking		,									 0 AS autov10positiontaking		,								0 AS isautov11positiontaking		,									0 AS autov11positiontaking		,								0 AS isautov99positiontaking		,									0 AS autov99positiontaking	
UNION ALL 	SELECT 20 AS bettype	,									 0 AS isautopositiontaking		,									  0 AS isautolivepositiontaking		,									0 AS autopositiontaking		,									 0 AS autolivepositiontaking		,		   @isauto_v2mpositiontaking_20 AS isautov2positiontaking		,		   @auto_v2mpositiontaking_20 AS autov2positiontaking		,		@isauto_v3mpositiontaking_20 AS isautov3positiontaking		,		   @auto_v3mpositiontaking_20 AS autov3positiontaking,			@isauto_v5mpositiontaking_20 AS isautov5positiontaking		,		   @auto_v5mpositiontaking_20 AS autov5positiontaking		,		@isauto_v8mpositiontaking_20 AS isautov8positiontaking		,		   @auto_v8mpositiontaking_20 AS autov8positiontaking		,		@isauto_v10mpositiontaking_20 AS isautov10positiontaking	,		   @auto_v10mpositiontaking_20 AS autov10positiontaking		,		@isauto_v11mpositiontaking_20 AS isautov11positiontaking	,		   @auto_v11mpositiontaking_20 AS autov11positiontaking		,	@isauto_v99mpositiontaking_20 AS isautov99positiontaking		,		   @auto_v99mpositiontaking_20 AS autov99positiontaking	

OPEN CUR

FETCH NEXT FROM CUR INTO
	@bettype, @isautopositiontaking, @isautolivepositiontaking, @autopositiontaking, @autolivepositiontaking, 
	@isautov2positiontaking, @autov2positiontaking,	
	@isautov3positiontaking, @autov3positiontaking, 
	@isautov5positiontaking, @autov5positiontaking, 	
	@isautov8positiontaking, @autov8positiontaking, 
	@isautov10positiontaking, @autov10positiontaking,
	@isautov11positiontaking, @autov11positiontaking, 
	@isautov99positiontaking, @autov99positiontaking
--m1=min(u,m3-a1)
WHILE @@FETCH_STATUS = 0
BEGIN
		if @isautopositiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=1 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking> @autopositiontaking then @autopositiontaking else @maxpos - apositiontaking end
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=1
			if @@Error <> 0
			BEGIN
				SELECT @ErrCode = 102,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Soccer)'
									when 'CS' then N'更新占成数不成功(于足球)'
									when 'CT' then N'更新佔成數不成功(於足球)'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาฟุตบอล)'
									when 'J' then N'Error updating auto positiontaking (for Soccer)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구)'
									else N'Error updating auto positiontaking (for Soccer)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	---------------------------------
	--Update LIVE
	if @bettype in (1,3,7,8) 
	BEGIN
		if @isautolivepositiontaking >0
		BEGIN
			select @maxpos = mlivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=1 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mlivepositiontaking = case when @maxpos - alivepositiontaking>@autolivepositiontaking then @autolivepositiontaking else @maxpos - alivepositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=1
			if @@Error <> 0
			BEGIN
				SELECT @ErrCode = 103,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Soccer - LIVE)'
									when 'CS' then N'更新占成数不成功(于足球-现场)'
									when 'CT' then N'更新佔成數不成功(於足球-現場)'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ ( สำหรับการเล่นสดขณะแข่งขัน ของฟุตบอล)'
									when 'J' then N'Error updating auto positiontaking (for Soccer - LIVE)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (축구- 생중계)'
									else N'Error updating auto positiontaking (for Soccer - LIVE)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END		
	---------------------------------
	--Update Basketball
	if @bettype in (1,2,3,7,8,9,20) 
	BEGIN
		if @isautov2positiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=2 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov2positiontaking then @autov2positiontaking else @maxpos - apositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=2
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrCode = 104,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Basketball)'
									when 'CS' then N'更新占成数不成功(于篮球))'
									when 'CT' then N'更新佔成數不成功(於籃球)'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาบาสเก็ตบอล)'
									when 'J' then N'Error updating auto positiontaking (for Basketball)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (농구)'
									else N'Error updating auto positiontaking (for Basketball)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END
	
	---------------------------------
	--Update Football
	if @bettype in (1,2,3,20) 
	BEGIN
		if @isautov3positiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=3 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov3positiontaking then @autov3positiontaking else @maxpos - apositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=3
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrCode = 105,
					@ErrMsg =  
							case @Language 
								when 'E' then 'Error updating auto positiontaking (for Football)'
								when 'CS' then N'更新占成数不成功(于美式足球)'
								when 'CT' then N'更新佔成數不成功(於美式足球)'
								when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอเมริกันฟุตบอล)'
								when 'J' then N'Error updating auto positiontaking (for Football)'
								when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (풋볼)'
								else N'Error updating auto positiontaking (for Football)'
							end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END

	---------------------------------
	--Update Tennis
	if @bettype in (1,2,3,20) 
	BEGIN
		if @isautov5positiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=5 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov5positiontaking then @autov5positiontaking else @maxpos - apositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=5
			if @@Error <> 0
			BEGIN
				SELECT @ErrCode = 106,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Tennis)'
									when 'CS' then N'更新占成数不成功(于网球)'
									when 'CT' then N'更新佔成數不成功(於網球)'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเทนนิส)'
									when 'J' then N'Error updating auto positiontaking (for Tennis)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (테니스)'
									else N'Error updating auto positiontaking (for Tennis)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END

	---------------------------------
	--Update Baseball
	if @bettype in (1,3,20) 
	BEGIN
		if @isautov8positiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=8 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov8positiontaking then @autov8positiontaking else @maxpos - apositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=8
			if @@Error <> 0
			BEGIN
				SELECT @ErrCode = 107,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Baseball)'
									when 'CS' then N'更新占成数不成功(于棒球)'
									when 'CT' then N'更新佔成數不成功(於棒球)'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาเบสบอล)'
									when 'J' then N'Error updating auto positiontaking (for Baseball)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (야구)'
									else N'Error updating auto positiontaking (for Baseball)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END

	---------------------------------
	--Update Golf
	if @bettype in (1,2,3,20)
	BEGIN
		if @isautov10positiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=10 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov10positiontaking then @autov10positiontaking else @maxpos - apositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=10
			if @@Error <> 0
			BEGIN
				SELECT @ErrCode = 108,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Golf)'
									when 'CS' then N'更新占成数不成功(于高尔夫球)'
									when 'CT' then N'更新佔成數不成功(於高爾夫球)'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬากอฟล์)'
									when 'J' then N'Error updating auto positiontaking (for Golf)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (골프)'
									else N'Error updating auto positiontaking (for Golf)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END

	---------------------------------
	--Update Motorsports
	if @bettype in (1,20)
	BEGIN
		if @isautov11positiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=11 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov11positiontaking then @autov11positiontaking else @maxpos - apositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=11
			if @@Error <> 0
			BEGIN
				SELECT @ErrCode = 109,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Motorsports)'
									when 'CS' then N'更新占成数不成功(于赛车)'
									when 'CT' then N'更新佔成數不成功(於賽車)'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬารถแข่ง)'
									when 'J' then N'Error updating auto positiontaking (for Motorsports)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (모토스포츠)'
									else N'Error updating auto positiontaking (for Motorsports)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END

	---------------------------------
	--Update Other sports
	if @bettype in (1,2,3,20) 
	BEGIN
		if @isautov99positiontaking >0
		BEGIN
			select @maxpos = mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and sporttype=99 and bettype = @bettype
			update custsetting with (ROWLOCK, UPDLOCK) set mpositiontaking = case when @maxpos - apositiontaking>@autov99positiontaking then @autov99positiontaking else @maxpos - apositiontaking end
			from custsetting
			where custid = @custid and custsetting.bettype = @bettype and custsetting.sporttype=99
			if @@Error <> 0
			BEGIN
				SELECT @ErrCode = 110,
						@ErrMsg =  
								case @Language 
									when 'E' then 'Error updating auto positiontaking (for Other sports)'
									when 'CS' then N'更新占成数不成功(于其他)'
									when 'CT' then N'更新佔成數不成功(於其他'
									when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับกีฬาอื่นๆ)'
									when 'J' then N'Error updating auto positiontaking (for Other sports)'
									when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (기타 스포츠)'
									else N'Error updating auto positiontaking (for Other sports)'
								end	
				DEALLOCATE CUR
				CLOSE CUR
				return
			END
		END
	END

	---------------------------------	
	FETCH NEXT FROM CUR INTO
		@bettype, @isautopositiontaking, @isautolivepositiontaking, @autopositiontaking, @autolivepositiontaking, 
		@isautov2positiontaking, @autov2positiontaking, 
		@isautov3positiontaking, @autov3positiontaking,
		@isautov5positiontaking, @autov5positiontaking, 
		@isautov8positiontaking, @autov8positiontaking, 
		@isautov10positiontaking, @autov10positiontaking, 
		@isautov11positiontaking, @autov11positiontaking, 
		@isautov99positiontaking, @autov99positiontaking
END

CLOSE CUR
DEALLOCATE CUR

GO
GRANT VIEW DEFINITION ON [Acc_CustomerUpdMember_AutoMPositiontaking] TO vnteam