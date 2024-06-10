/*<info serverAlias="DBACC-bodb02,DBCust-CustDB,DBTP-bodb02" selecters="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION	dbo.f_SmallIntToOfferValue(
					@FunctionInfo SMALLINT
				)  
RETURNS TABLE
AS
/*
	Created:	20231002@Winfred
	Database:	DBCust/CustDB,DBTP-bodb02
	Original:	
	Revision:
		- 20231002@Winfred: [NAP CM] Customer Class - Allow to offer Parlay Boost on rule setting [RedmineID: #190607] 
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297] 
	Param's Explanation:
*/
RETURN 
	WITH tmpValue(col_val)
	AS
	(
		SELECT CAST(ISNULL((
				  CASE WHEN @FunctionInfo&POWER(2,0) > 0 THEN '1,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,1) > 0 THEN '2,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,2) > 0 THEN '3,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,3) > 0 THEN '4,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,4) > 0 THEN '5,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,5) > 0 THEN '6,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,6) > 0 THEN '7,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,7) > 0 THEN '8,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,8) > 0 THEN '9,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,9) > 0 THEN '10,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,10) > 0 THEN '11,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,11) > 0 THEN '12,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,12) > 0 THEN '13,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,13) > 0 THEN '14,' ELSE '' END
				+ CASE WHEN @FunctionInfo&POWER(2,14) > 0 THEN '15,' ELSE '' END
			),'') AS VARCHAR(500))
	)
	SELECT CASE WHEN col_val <> '' THEN LEFT(col_val, LEN(col_val) - 1) ELSE '' END AS Value
	FROM tmpValue