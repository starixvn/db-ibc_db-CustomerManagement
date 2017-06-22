 1251139, 1251139, 1238621, 1238621, 1206998, 1206998, 1205286, 1205286, 1250242, 1250242, 1249585, 1249585, 1253301, 1253301, 1207004, 1207004, 1242096, 1242096, 1250097, 1250097, 1238619, 1238619, 1208302, 1208302, 1240425, 1240425


UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET sdiscount = cs4.sdiscount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs4 with (nolock) on c.srecommend = cs4.custid and cs1.sporttype = cs4.sporttype and cs1.bettype = cs4.bettype
WHERE c.roleid = 1 
and cs1.bettype in (31,32) and cs1.sporttype = 151
and custid in (1251139, 1251139, 1238621, 1238621, 1206998, 1206998, 1205286, 1205286, 1250242, 1250242, 1249585, 1249585, 1253301, 1253301, 1207004, 1207004, 1242096, 1242096, 1250097, 1250097, 1238619, 1238619, 1208302, 1208302, 1240425, 1240425)


UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET adiscount = cs3.adiscount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs3 with (nolock) on c.mrecommend = cs3.custid and cs1.sporttype = cs3.sporttype and cs1.bettype = cs3.bettype
WHERE c.roleid = 1 and disableHorseracing = 0
and cs1.bettype in (31,32)
and custid in (1251139, 1251139, 1238621, 1238621, 1206998, 1206998, 1205286, 1205286, 1250242, 1250242, 1249585, 1249585, 1253301, 1253301, 1207004, 1207004, 1242096, 1242096, 1250097, 1250097, 1238619, 1238619, 1208302, 1208302, 1240425, 1240425)


UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET discount = cs2.discount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs2 with (nolock) on c.recommend = cs2.custid and cs1.sporttype = cs2.sporttype and cs1.bettype = cs2.bettype
WHERE c.roleid = 1
and cs1.bettype in (31,32) and cs1.sporttype = 151
and custid in (1251139, 1251139, 1238621, 1238621, 1206998, 1206998, 1205286, 1205286, 1250242, 1250242, 1249585, 1249585, 1253301, 1253301, 1207004, 1207004, 1242096, 1242096, 1250097, 1250097, 1238619, 1238619, 1208302, 1208302, 1240425, 1240425)

------------------------------------------

UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET sdiscount = cs4.sdiscount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs4 with (nolock) on c.srecommend = cs4.custid and cs1.sporttype = cs4.sporttype and cs1.bettype = cs4.bettype
WHERE c.roleid = 1 and disableHorseracing = 0
and cs1.bettype in (31,32) and cs1.sporttype = 151


UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET adiscount = cs3.adiscount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs3 with (nolock) on c.mrecommend = cs3.custid and cs1.sporttype = cs3.sporttype and cs1.bettype = cs3.bettype
WHERE c.roleid = 1 and disableHorseracing = 0
and cs1.bettype in (31,32) and cs1.sporttype = 151


UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET discount = cs2.discount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs2 with (nolock) on c.recommend = cs2.custid and cs1.sporttype = cs2.sporttype and cs1.bettype = cs2.bettype
WHERE c.roleid = 1 and disableHorseracing = 0
and cs1.bettype in (31,32) and cs1.sporttype = 151

--------------------------------

UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET sdiscount = cs4.sdiscount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs4 with (nolock) on c.srecommend = cs4.custid and cs1.sporttype = cs4.sporttype and cs1.bettype = cs4.bettype
WHERE c.roleid = 1 and srecommend in (356937, 398437, 398636, 405017, 405422, 408317, 409524, 410722, 463265, 478396, 479690, 490037, 490215, 550155, 567372, 755409, 787938, 796555, 832992, 837904, 838210, 838215, 838370, 838377, 844818, 877768, 914842, 960134, 984549, 994735, 1150856, 1150890, 1150923, 1150941, 1150991, 1151009, 1151025, 1194960, 1308374)
and cs1.bettype in (31,32) and cs1.sporttype = 151


UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET adiscount = cs3.adiscount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs3 with (nolock) on c.mrecommend = cs3.custid and cs1.sporttype = cs3.sporttype and cs1.bettype = cs3.bettype
WHERE c.roleid = 1 and srecommend in (356937, 398437, 398636, 405017, 405422, 408317, 409524, 410722, 463265, 478396, 479690, 490037, 490215, 550155, 567372, 755409, 787938, 796555, 832992, 837904, 838210, 838215, 838370, 838377, 844818, 877768, 914842, 960134, 984549, 994735, 1150856, 1150890, 1150923, 1150941, 1150991, 1151009, 1151025, 1194960, 1308374)
and cs1.bettype in (31,32) and cs1.sporttype = 151


UPDATE cs1 with (ROWLOCK, UPDLOCK) 
		SET discount = cs2.discount
From custsetting  cs1
	inner join custinfo as c with (NOLOCK) on cs1.custid = c.custid
	inner join custsetting cs2 with (nolock) on c.recommend = cs2.custid and cs1.sporttype = cs2.sporttype and cs1.bettype = cs2.bettype
WHERE c.roleid = 1 and srecommend in (356937, 398437, 398636, 405017, 405422, 408317, 409524, 410722, 463265, 478396, 479690, 490037, 490215, 550155, 567372, 755409, 787938, 796555, 832992, 837904, 838210, 838215, 838370, 838377, 844818, 877768, 914842, 960134, 984549, 994735, 1150856, 1150890, 1150923, 1150941, 1150991, 1151009, 1151025, 1194960, 1308374)
and cs1.bettype in (31,32) and cs1.sporttype = 151