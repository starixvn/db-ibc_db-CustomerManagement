/*<info serverAlias="DBCUST-CustDB" selecters="bodbExtAccNet,wsv_xnap" viewers="" isFunction="1" isNested="1"></info>*/  
CREATE FUNCTION [dbo].[f_API_CheckSecretKey] ( @APISecretKey VARCHAR(100) )  
RETURNS TABLE  
AS  
/*  
	Created: Helios  
	Task : Check APISecretKey   
	DB: DBCUST/CustDB  
	Revisions:  
		- 20230511@Helios: EXT - Support API for Headline [Redmine: #188035]  
		- 20230818@Tacy: Add APISecretKey for ACCUT [Redmine: #192805]
		- 20230825@Tacy: Add APISecretKey for ACCYEN789 [Redmine: #192805]
		- 20230926@Tacy: Add APISecretKey for ACCYEN789 [Redmine: #194326]
		- 20240408@Tacy: Add APISecretKey for ACCYEN789 [Redmine: #203559]
*/  
RETURN  

 SELECT   
  CASE   
    --ACCUUS
   WHEN @APISecretKey =  '}#U)Gw-PG7XYwvhh|8=C(bo~g6dXsNOUJ7]JpuuDtv8,-,7+i@*)rP"VQh}qb_' THEN 'ACCUT'
   WHEN @APISecretKey =  'qrWV6EGztqkv&DcM@S%pmuBfrPHxJp4MRvXB3m#KD$5$xntc9daWf3nQbUCM5M' THEN 'ACCUT'
   WHEN @APISecretKey =  '.CL}T&sA/OQ~<kDe#oA$,i=PV"WlRk~yA}Cg@E=CC+=rJR$M,?*D/npdz[Dpw^' THEN 'ACCYEN789'
   WHEN @APISecretKey =  '22QDDLJQc+m7&@YM(*ONgg.`EsnF>2kWwoBAQAT~"iQ}Dpm(@-$zOYR^0<EXQu' THEN 'ACCYEN789'
   WHEN @APISecretKey =  'EBhUvN@#M$%:)J[-OzojFO|3cSe+`X=Qd*EC?,4%4JOSZWegM0ey]_`ppN]>|'  THEN 'ACCYEN889'
   WHEN @APISecretKey =  '}#U)Gw-PG7XYwvhh|8=C(bo~g6dXsNOUJ7]JpuuDtv8,-,7+i@*)rP"VQh}q'	  THEN 'ACCUUS'
   WHEN @APISecretKey =  'Ma2qf6VhH5@5ZP2X23nHmH!U^Vk^V$kfWZKSDoAhDi^!HZfaGPYUe5!9yQfi!u' THEN 'ACCYEN789'
   WHEN @APISecretKey =  '5dNgFW3sYAyjRv7nc6EARVvBL#VnaHoybv3Zs&xTrxVs762biPqGkk3zBUt%d#' THEN 'ACCYEN889'
   WHEN @APISecretKey =  '7<sZ4=9A]t_<h{BczlgK.hVuu:d;Pr{%f]T!~J,~0AL3>l0Gw@+26vzT~&Z&C9' THEN 'ACCYEN789'
   WHEN @APISecretKey =  '1234aa' THEN 'ACCTEST'

  END GroupName  
 
