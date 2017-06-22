
	
CREATE PROCEDURE Acc_CustOverrideUpd_MaxPos
	@custid int,
	@maxpositiontaking_1 smallmoney,
	@maxpositiontaking_2 smallmoney,
	@maxpositiontaking_3 smallmoney,
	@maxpositiontaking_4 smallmoney,
	@maxpositiontaking_5 smallmoney,
	@maxpositiontaking_6 smallmoney,
	@maxpositiontaking_7 smallmoney,
	@maxpositiontaking_8 smallmoney,
	@maxpositiontaking_9 smallmoney,
	@maxpositiontaking_10 smallmoney,
	
	@maxlivepositiontaking_1 smallmoney,
	@maxlivepositiontaking_3 smallmoney,
	@maxlivepositiontaking_7 smallmoney,
	@maxlivepositiontaking_8 smallmoney,
	
	@maxv2positiontaking_1 smallmoney,
	@maxv2positiontaking_2 smallmoney,
	@maxv2positiontaking_3 smallmoney,
	@maxv2positiontaking_7 smallmoney,
	@maxv2positiontaking_8 smallmoney,
	@maxv2positiontaking_9 smallmoney,
	@maxv2positiontaking_20 smallmoney,

	@maxv3positiontaking_1 smallmoney,
	@maxv3positiontaking_2 smallmoney,
	@maxv3positiontaking_3 smallmoney,
	@maxv3positiontaking_20 smallmoney,

	@maxv5positiontaking_1 smallmoney,
	@maxv5positiontaking_2 smallmoney,
	@maxv5positiontaking_3 smallmoney,
	@maxv5positiontaking_20 smallmoney,

	@maxv8positiontaking_1 smallmoney,
	@maxv8positiontaking_3 smallmoney,
	@maxv8positiontaking_20 smallmoney,

	@maxv10positiontaking_1 smallmoney,
	@maxv10positiontaking_2 smallmoney,
	@maxv10positiontaking_3 smallmoney,
	@maxv10positiontaking_20 smallmoney,

	@maxv11positiontaking_1 smallmoney,
	@maxv11positiontaking_20 smallmoney,

	@maxv12positiontaking_2 smallmoney,
	@maxv12positiontaking_21 smallmoney,
	@maxv12positiontaking_22 smallmoney,

	@maxv99positiontaking_1 smallmoney,
	@maxv99positiontaking_2 smallmoney,
	@maxv99positiontaking_3 smallmoney,
	@maxv99positiontaking_20 smallmoney
AS
Update custoverride with (ROWLOCK, UPDLOCK) set maxpositiontaking = b.maxpositiontaking, maxlivepositiontaking = b.maxlivepositiontaking
from custoverride inner join 	
		(
			select 		@custid as custid,  1 as sporttype, 1 as bettype, @maxpositiontaking_1 as maxpositiontaking,  @maxlivepositiontaking_1 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 2 as bettype, @maxpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 3 as bettype, @maxpositiontaking_3 as maxpositiontaking,  @maxlivepositiontaking_3 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 4 as bettype, @maxpositiontaking_4 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 5 as bettype, @maxpositiontaking_5 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 6 as bettype, @maxpositiontaking_6 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 7 as bettype, @maxpositiontaking_7 as maxpositiontaking,  @maxlivepositiontaking_7 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 8 as bettype, @maxpositiontaking_8 as maxpositiontaking,  @maxlivepositiontaking_8 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 9 as bettype, @maxpositiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  1 as sporttype, 10 as bettype, @maxpositiontaking_10 as maxpositiontaking,  0 as maxlivepositiontaking
			
			union all select 	@custid as custid,  2 as sporttype, 1 as bettype, @maxv2positiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 2 as bettype, @maxv2positiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 3 as bettype, @maxv2positiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 7 as bettype, @maxv2positiontaking_7 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 8 as bettype, @maxv2positiontaking_8 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 9 as bettype, @maxv2positiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  2 as sporttype, 20 as bettype, @maxv2positiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			
			union all select 	@custid as custid,  3 as sporttype, 1 as bettype, @maxv3positiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  3 as sporttype, 2 as bettype, @maxv3positiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  3 as sporttype, 3 as bettype, @maxv3positiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  3 as sporttype, 20 as bettype, @maxv3positiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking

			union all select 	@custid as custid,  5 as sporttype, 1 as bettype, @maxv5positiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  5 as sporttype, 2 as bettype, @maxv5positiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  5 as sporttype, 3 as bettype, @maxv5positiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  5 as sporttype, 20 as bettype, @maxv5positiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking

			union all select 	@custid as custid,  8 as sporttype, 1 as bettype, @maxv8positiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  8 as sporttype, 3 as bettype, @maxv8positiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  8 as sporttype, 20 as bettype, @maxv8positiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking

			union all select 	@custid as custid,  10 as sporttype, 1 as bettype, @maxv10positiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  10 as sporttype, 2 as bettype, @maxv10positiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  10 as sporttype, 3 as bettype, @maxv10positiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  10 as sporttype, 20 as bettype, @maxv10positiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking

			union all select 	@custid as custid,  11 as sporttype, 1 as bettype, @maxv11positiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  11 as sporttype, 20 as bettype, @maxv11positiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking

			union all select 	@custid as custid,  12 as sporttype, 2 as bettype, @maxv12positiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  12 as sporttype, 21 as bettype, @maxv12positiontaking_21 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  12 as sporttype, 22 as bettype, @maxv12positiontaking_22 as maxpositiontaking,  0 as maxlivepositiontaking

			union all select 	@custid as custid,  99 as sporttype, 1 as bettype, @maxv99positiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  99 as sporttype, 2 as bettype, @maxv99positiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  99 as sporttype, 3 as bettype, @maxv99positiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
			union all select 	@custid as custid,  99 as sporttype, 20 as bettype, @maxv99positiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking			
		) as b on custoverride.custid = b.custid and custoverride.sporttype=b.sporttype and custoverride.bettype = b.bettype
where custoverride.custid = @custid
Go
