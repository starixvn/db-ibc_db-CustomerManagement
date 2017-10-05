/*<info serverAlias="DBCUST-CustDB,DBTXN-bodb02,DB05-bodb02,DB052-bodb02,DB053-bodb02,DB054-bodb02,DB06-bodb02,DBLICAPI-bodb02,DBLicApi02-bodb02" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/

ALTER FUNCTION [dbo].[f_SiteBySystem]
(
	@System varchar(50) = 'ACCOUNTING'
)
	RETURNS @tbSite table (siteid  int PRIMARY KEY)
AS

/*
Created: 
Task : Get sites by system
DB:  DBTRANS.BODB02, DB053.BODB02, DB054.BODB02, DB052.BODB02, DB05.BODB02, DB06.BODB02, DBCUST.CustDB

Revisions:
	- 20100819@Ethan: Get sites by System
	- 20101130@Johnson: Get INDO site
	- 20110908@Johnson: Get ACCYEN789 and ACCYEN889 system
	- 20111122@Johnson: Get ACCDDD system
	- 20120809@Elodie: Get ACCIRR system
	- 20130404@Jamie: Put ACCUUS for testing 
	- 20130718@Lukas: add ACCUT group
	- 20130909@Jamie: ADD group ACCYEN668 
	- 20140117@Lukas: add group ACCYEN888
	- 20150526@Kiwi: add ACCUT2 group
	- 20150812@Amy: add ACCTHAI2 group
	- 20150817@Susan: add ACCIN group
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20151027@Francis: Add INDOBS,INDO2 group
	- 20151111@Susan: Add MKK99 group
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20160114@Helen: Cricket - [Redmine: #50027]
	- 20160427@Susan: Add new group ACCUSDOTH
	- 20160907@Susan: Add new group ACCMMK
	- 20161005@Harris: Add new group ACCYNG	for Allbet Testing
	- 20171003@Elodie: Add ACCTESTK68 group
	- 20171005@Elodie: Add TH999 group
	Param's Explanation:
	- @System: input system name 'ACCTHAI', 'ACCOUNTING'
*/

BEGIN
	IF (@System = 'ACCOUNTING')
	BEGIN
		Insert Into @tbSite(siteid)
		Select siteid 
		From [Site] (nolock)
	END
	ELSE IF(@System IN ('ACCTHAI','ACCTHAI2','ACCTHAI56','ACCTHAI99'))
	BEGIN
		Insert Into @tbSite(siteid)
		SELECT 22 --755555,...
	END
	--ELSE IF (@System IN ('ACCINDO','ACCIN') )
	--BEGIN
	--	INSERT INTO @tbSite(siteid)
	--	SELECT 11 --INDO
	--END
	ELSE IF (@System IN ('ACCINDO','ACCIN','INDOBS','INDO2','INDO56','INDOWIN','INDO56B') )
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 11 --INDO
	END
	ELSE IF (@System IN ('ACCYEN','ACCYEN789','ACCYEN889','ACCYEN668','ACCNTD','ACCIRR','ACCUSD','ACCUT','ACCYEN888','ACCUT2','ACCUSDOTH'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 3 --789y
	END
	ELSE IF (@System IN ('ACCUUS'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 1 --BEST-ODDS
		UNION ALL 
		SELECT 184 -- 766666
		UNION ALL 
		SELECT 147
		UNION ALL 
		SELECT 257 --Y987
	END
	ELSE IF (@System = 'ACCDDD')
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 11 --INDO
	END	
	ELSE IF (@System in ( 'MKK99','ACCMKK'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 184 -- 766666
	END	
	ELSE IF (@System in ( 'ACCMMK'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 188 -- 7aa666
	END	
	ELSE IF (@System in ( 'ACCYNG'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 22 --755555
		UNION ALL 
		SELECT 11 --INDO	
	END	
	ELSE IF (@System IN ('ACCTESTK68','TH999'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 257 --Y987
	END

	RETURN
END
GO
