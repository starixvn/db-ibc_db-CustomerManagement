/*<info serverAlias="DBCUST-CustDB" selecters="bodbExtAccNet" viewers="" isFunction="1" isNested="1"></info>*/  
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
*/  
RETURN  

 SELECT   
  CASE   
    --ACCUUS
   WHEN @APISecretKey =  '}#U)Gw-PG7XYwvhh|8=C(bo~g6dXsNOUJ7]JpuuDtv8,-,7+i@*)rP"VQh}qb_' THEN 'ACCUT'
   WHEN @APISecretKey =  'qrWV6EGztqkv&DcM@S%pmuBfrPHxJp4MRvXB3m#KD$5$xntc9daWf3nQbUCM5M' THEN 'ACCUT'
   WHEN @APISecretKey =  '.CL}T&sA/OQ~<kDe#oA$,i=PV"WlRk~yA}Cg@E=CC+=rJR$M,?*D/npdz[Dpw^' THEN 'ACCYEN789'
   WHEN @APISecretKey =  '22QDDLJQc+m7&@YM(*ONgg.`EsnF>2kWwoBAQAT~"iQ}Dpm(@-$zOYR^0<EXQu' THEN 'ACCYEN789'
   WHEN @APISecretKey =  'EBhUvN@#M$%:)J[-OzojFO|3cSe+`X=Qd*EC?,4%4JOSZWegM0ey]_`ppN]>|' THEN 'ACCYEN889'
   WHEN @APISecretKey =  '}#U)Gw-PG7XYwvhh|8=C(bo~g6dXsNOUJ7]JpuuDtv8,-,7+i@*)rP"VQh}q' THEN 'ACCUUS'
   WHEN @APISecretKey =  '1234aa' THEN 'ACCTEST'

  END GroupName  
 
