CREATE PROCEDURE Acc_CustOverrideUpd_MinPos
	@custid int,
	@minpositiontaking_1 smallmoney,
	@minpositiontaking_2 smallmoney,
	@minpositiontaking_3 smallmoney,
	@minpositiontaking_4 smallmoney,
	@minpositiontaking_5 smallmoney,
	@minpositiontaking_6 smallmoney,
	@minpositiontaking_7 smallmoney,
	@minpositiontaking_8 smallmoney,
	@minpositiontaking_9 smallmoney,
	@minpositiontaking_10 smallmoney,
	@minlivepositiontaking_1 smallmoney,
	@minlivepositiontaking_3 smallmoney,
	@minlivepositiontaking_7 smallmoney,
	@minlivepositiontaking_8 smallmoney,
	
	@minv2positiontaking_1 smallmoney,
	@minv2positiontaking_2 smallmoney,
	@minv2positiontaking_3 smallmoney,
	@minv2positiontaking_7 smallmoney,
	@minv2positiontaking_8 smallmoney,
	@minv2positiontaking_9 smallmoney,
	@minv2positiontaking_20 smallmoney,

	@minv3positiontaking_1 smallmoney,
	@minv3positiontaking_2 smallmoney,
	@minv3positiontaking_3 smallmoney,
	@minv3positiontaking_20 smallmoney,

	@minv5positiontaking_1 smallmoney,
	@minv5positiontaking_2 smallmoney,
	@minv5positiontaking_3 smallmoney,
	@minv5positiontaking_20 smallmoney,

	@minv8positiontaking_1 smallmoney,
	@minv8positiontaking_3 smallmoney,
	@minv8positiontaking_20 smallmoney,

	@minv10positiontaking_1 smallmoney,
	@minv10positiontaking_2 smallmoney,
	@minv10positiontaking_3 smallmoney,
	@minv10positiontaking_20 smallmoney,

	@minv11positiontaking_1 smallmoney,
	@minv11positiontaking_20 smallmoney,

	@minv12positiontaking_2 smallmoney,
	@minv12positiontaking_21 smallmoney,
	@minv12positiontaking_22 smallmoney,

	@minv99positiontaking_1 smallmoney,
	@minv99positiontaking_2 smallmoney,
	@minv99positiontaking_3 smallmoney,
	@minv99positiontaking_20 smallmoney
AS
--get old data for log

Update custoverride with (ROWLOCK, UPDLOCK) set minpositiontaking = b.minpositiontaking, minlivepositiontaking = b.minlivepositiontaking
from custoverride inner join 	
		(
			select 		@custid as custid,  1 as sporttype, 1 as bettype, @minpositiontaking_1 as minpositiontaking,  @minlivepositiontaking_1 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 2 as bettype, @minpositiontaking_2 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 3 as bettype, @minpositiontaking_3 as minpositiontaking,  @minlivepositiontaking_3 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 4 as bettype, @minpositiontaking_4 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 5 as bettype, @minpositiontaking_5 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 6 as bettype, @minpositiontaking_6 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 7 as bettype, @minpositiontaking_7 as minpositiontaking,  @minlivepositiontaking_7 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 8 as bettype, @minpositiontaking_8 as minpositiontaking,  @minlivepositiontaking_8 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 9 as bettype, @minpositiontaking_9 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 10 as bettype, @minpositiontaking_10 as minpositiontaking,  0 as minlivepositiontaking
			
			union all select 	@custid as custid,  2 as sporttype, 1 as bettype, @minv2positiontaking_1 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 2 as bettype, @minv2positiontaking_2 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 3 as bettype, @minv2positiontaking_3 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 7 as bettype, @minv2positiontaking_7 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 8 as bettype, @minv2positiontaking_8 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 9 as bettype, @minv2positiontaking_9 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 20 as bettype, @minv2positiontaking_20 as minpositiontaking,  0 as minlivepositiontaking

			union all select 	@custid as custid,  3 as sporttype, 1 as bettype, @minv3positiontaking_1 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  3 as sporttype, 2 as bettype, @minv3positiontaking_2 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  3 as sporttype, 3 as bettype, @minv3positiontaking_3 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  3 as sporttype, 20 as bettype, @minv3positiontaking_20 as minpositiontaking,  0 as minlivepositiontaking

			union all select 	@custid as custid,  5 as sporttype, 1 as bettype, @minv5positiontaking_1 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  5 as sporttype, 2 as bettype, @minv5positiontaking_2 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  5 as sporttype, 3 as bettype, @minv5positiontaking_3 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  5 as sporttype, 20 as bettype, @minv5positiontaking_20 as minpositiontaking,  0 as minlivepositiontaking

			union all select 	@custid as custid,  8 as sporttype, 1 as bettype, @minv8positiontaking_1 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  8 as sporttype, 3 as bettype, @minv8positiontaking_3 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  8 as sporttype, 20 as bettype, @minv8positiontaking_20 as minpositiontaking,  0 as minlivepositiontaking

			union all select 	@custid as custid,  10 as sporttype, 1 as bettype, @minv10positiontaking_1 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  10 as sporttype, 2 as bettype, @minv10positiontaking_2 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  10 as sporttype, 3 as bettype, @minv10positiontaking_3 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  10 as sporttype, 20 as bettype, @minv10positiontaking_20 as minpositiontaking,  0 as minlivepositiontaking

			union all select 	@custid as custid,  11 as sporttype, 1 as bettype, @minv11positiontaking_1 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  11 as sporttype, 20 as bettype, @minv11positiontaking_20 as minpositiontaking,  0 as minlivepositiontaking

			union all select 	@custid as custid,  12 as sporttype, 2 as bettype, @minv12positiontaking_2 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  12 as sporttype, 21 as bettype, @minv12positiontaking_21 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  12 as sporttype, 22 as bettype, @minv12positiontaking_22 as minpositiontaking,  0 as minlivepositiontaking

			union all select 	@custid as custid,  99 as sporttype, 1 as bettype, @minv99positiontaking_1 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  99 as sporttype, 2 as bettype, @minv99positiontaking_2 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  99 as sporttype, 3 as bettype, @minv99positiontaking_3 as minpositiontaking,  0 as minlivepositiontaking
			union all select 	@custid as custid,  99 as sporttype, 20 as bettype, @minv99positiontaking_20 as minpositiontaking,  0 as minlivepositiontaking
			
		) as b on custoverride.custid = b.custid and custoverride.sporttype=b.sporttype and custoverride.bettype = b.bettype
where custoverride.custid = @custid


GO