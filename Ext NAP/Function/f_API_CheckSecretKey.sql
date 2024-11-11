/*<info serverAlias="DBPOL-NAP_UserControl" selecters="wsv_xnap" viewers="" isFunction="1" isNested="1"></info>*/  
CREATE FUNCTION [dbo].[f_API_CheckSecretKey] (@APISecretKey VARCHAR(100)=NULL)  
RETURNS TABLE  
AS  
/*  
	Created: Helios  
	Task : Check APISecretKey   
	DB: DBPOL/NAP_UserControl  

	Revisions:  
		- 20230511@Helios: EXT - Support API for Headline [Redmine: #188035]  
		- 20230818@Tacy: Add APISecretKey for ACCUT [Redmine: #192805]
		- 20230825@Tacy: Add APISecretKey for ACCYEN789 [Redmine: #192805]
		- 20230926@Tacy: Add APISecretKey for ACCYEN789 [Redmine: #194326]
		- 20240408@Tacy: Add APISecretKey for ACCYEN789 [Redmine: #203559]
		- 20240812@Tacy: Move to DBPOL.NAP_UserControl [RedmineId: #208402]
		- 20241112@Tacy: Add APISecretKey for ACCYNG [Redmine: #213508]
		
*/  
RETURN  
	WITH tmpAPISecretKey AS (
			  SELECT APISecretKey =  '}#U)Gw-PG7XYwvhh|8=C(bo~g6dXsNOUJ7]JpuuDtv8,-,7+i@*)rP"VQh}qb_'	, GroupName = 'ACCUT'
		UNION SELECT APISecretKey =  'qrWV6EGztqkv&DcM@S%pmuBfrPHxJp4MRvXB3m#KD$5$xntc9daWf3nQbUCM5M'	, GroupName = 'ACCUT'
		UNION SELECT APISecretKey =  '.CL}T&sA/OQ~<kDe#oA$,i=PV"WlRk~yA}Cg@E=CC+=rJR$M,?*D/npdz[Dpw^'	, GroupName = 'ACCYEN789'
		UNION SELECT APISecretKey =  '22QDDLJQc+m7&@YM(*ONgg.`EsnF>2kWwoBAQAT~"iQ}Dpm(@-$zOYR^0<EXQu'	, GroupName = 'ACCYEN789'
		UNION SELECT APISecretKey =  'EBhUvN@#M$%:)J[-OzojFO|3cSe+`X=Qd*EC?,4%4JOSZWegM0ey]_`ppN]>|'	, GroupName = 'ACCYEN889'
		UNION SELECT APISecretKey =  '}#U)Gw-PG7XYwvhh|8=C(bo~g6dXsNOUJ7]JpuuDtv8,-,7+i@*)rP"VQh}q'		, GroupName = 'ACCUUS'
		UNION SELECT APISecretKey =  'Ma2qf6VhH5@5ZP2X23nHmH!U^Vk^V$kfWZKSDoAhDi^!HZfaGPYUe5!9yQfi!u'	, GroupName = 'ACCYEN789'
		UNION SELECT APISecretKey =  '5dNgFW3sYAyjRv7nc6EARVvBL#VnaHoybv3Zs&xTrxVs762biPqGkk3zBUt%d#'	, GroupName = 'ACCYEN889'
		UNION SELECT APISecretKey =  '7<sZ4=9A]t_<h{BczlgK.hVuu:d;Pr{%f]T!~J,~0AL3>l0Gw@+26vzT~&Z&C9'	, GroupName = 'ACCYEN789'
		UNION SELECT APISecretKey =  'indY*&gU&Th>?Z~7q]w3xzsIm$}c)hB1,*Iy=Z#N<r^65d8{<.:}&>nUT&ifPvQ'	, GroupName = 'ACCYNG'
		UNION SELECT APISecretKey =  '1234aa', GroupName = 'ACCTEST'
	)
	SELECT APISecretKey, GroupName
	FROM tmpAPISecretKey t
	WHERE ISNULL(@APISecretKey,'')='' OR APISecretKey=@APISecretKey
;