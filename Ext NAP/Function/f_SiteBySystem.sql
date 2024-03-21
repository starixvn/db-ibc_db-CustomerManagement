/*<info serverAlias="DBCUST-CustDB,DBONUSER-bodb02,DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" selecters="bodbAdminNet,wsv_nap,bodbExtAccNet,wsv_xnap" viewers="" isFunction="1" isNested="1"></info>*/

ALTER FUNCTION [dbo].[f_SiteBySystem]
(
	@System varchar(50) = 'ACCOUNTING'
)
	RETURNS @tbSite table (siteid  int PRIMARY KEY)
AS

/*
Created: 
Task : Get sites by system
DB:  DB053.BODB02, DB054.BODB02, DB052.BODB02, DB05.BODB02, DB06.BODB02, DBCUST.CustDB

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
	- 20180601@Elodie: Add SQ88 group - [Redmine: #94865]
	- 20180605@Elodie: Add THEU, 899EU, 789EU group - [Redmine: #94865]
	- 20180611@Elodie: Add SQUS - [Redmine: #96736]
	- 20180901@Elodie: Add ACCTEST - [Redmine: #100925]
	- 20190221@Elodie: Add TH001,TH002,TH003 group
	- 20191021@Gary: add ACCINDO2 group - [Redmine: #122340]
	- 20200508@Elodie: add IBCIndo group - [Redmine: #133858]
	- 20200617@Elodie: Allow IBCIndo for INDOWIN group - [Redmine: #136032]
	- 20200629@Johnson: Allow IBCIndo for INDOBS group [redmine: #136467]
	- 20200923@Elodie: Allow 76666B for ACCMMKMyanmar, ACCUUSMyanmar group - [Redmine: #141926]
	- 20201102@Winfred: rename group ACCMMKMyanmar to IBCMMR - [Redmine: #141926]
	- 20210301@Percy: Make BC to real group [RedmineID: #146710]
	- 20210305@Tina: add more group ACCSABA789 - [Redmine: #151213]
	- 20210309@Tina: add more group ACCAthena000
	- 20210812@Percy: Add back ACCTHAI2, ACCTHAI56, ACCTHAI99 as normal group [RedmineID: #146710]
	- 20220408@Elodie: Add ACCTHAITT - [Redmine: #171299]
	- 20221226@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
	- 20231027@Johnson: Add ACCThaiSK [redmine: #195550]
	- 20231206@Johnson: Add ACCS56RM [redmine: #197031]
	- 20240227@Johnson: Add ACCHHRM,ACCCH1,ACCMG7,ACCNV1,ACCA951 [redmine: #201332]
	- 20240227@Johnson: Add ACCTW1,ACCSB1 [redmine: #201452]
	- 20240321@Johnson: Add ACCDS17,ACCS359M,ACC801AH,ACCC1,ACCS222H,ACCD77M,ACCAHM,ACCWT,ACC222,ACCHPO,ACCKKM [redmine: #202663]
	Param's Explanation:
	- @System: input system name 'ACCTHAI', 'ACCOUNTING'
*/

BEGIN
	IF (@System = 'ACCOUNTING')
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT siteid 
		FROM [Site] WITH (NOLOCK)
	END
	ELSE IF (@System = 'ACCTEST')
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT siteid 
		FROM [Site] WITH (NOLOCK)
		WHERE isLicensee = 0 AND isActive = 1
	END
	ELSE IF(@System IN ('ACCTHAI', 'BC', 'ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99','ACCTHAITT'))
	BEGIN
		Insert Into @tbSite(siteid)
		SELECT 22 --755555,...
	END
	--ELSE IF (@System IN ('ACCINDO','ACCIN') )
	--BEGIN
	--	INSERT INTO @tbSite(siteid)
	--	SELECT 11 --INDO
	--END
	ELSE IF (@System IN ('ACCINDO','ACCIN','INDO2','INDO56','INDO56B','ACCINDO2') )
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT 11 --INDO
	END
	ELSE IF (@System IN ('ACCYEN','ACCYEN789','ACCYEN889','ACCYEN668','ACCNTD','ACCIRR','ACCUSD','ACCUT','ACCYEN888','ACCUT2','ACCUSDOTH'))
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT siteid
		FROM Site s WITH (NOLOCK)
		WHERE SiteLabel='789y' AND isActive=1
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
		UNION ALL 
		SELECT 294 --EU88
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
	ELSE IF (@System IN ('ACCTESTK68','TH999','TH001','TH002','TH003'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 257 --Y987
	END
	ELSE IF (@System IN ('SQ88','THEU','899EU','789EU','SQUS'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 294 --EU88
	END
	ELSE IF (@System IN ('IBCIndo'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 487 --IBCIndo
	END
	ELSE IF (@System IN ('INDOWIN','INDOBS'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 487 --IBCIndo
		UNION ALL 
		SELECT 11 --INDO
	END	
	ELSE IF (@System IN ('IBCMMR', 'ACCUUSMyanmar'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 547 --76666B		
	END	
	ELSE IF (@System IN ('IBCMMR', 'ACCUUSMyanmar'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 547 --76666B		
	END	
	ELSE IF (@System IN ('ACCSABA789'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 557 --Saba789		
	END
	ELSE IF (@System IN ('ACCAthena000'))
	BEGIN
		INSERT INTO @tbSite(siteid)		
		SELECT 66 --Athena000
		UNION ALL
		SELECT 1 --BEST-ODDS		
	END
	ELSE IF(@System IN ('ACCTHaiSK','AccThaiSKUUS'))
	BEGIN
		Insert Into @tbSite(siteid)
		SELECT 1233 --7a5555,...
	END
	--Malaysia HL
	ELSE IF(@System IN ('ACCS56RM','ACCHHRM','ACCCH1','ACCMG7','ACCNV1','ACCA951','ACCTW1','ACCSB1',
						'ACCDS17','ACCS359M','ACC801AH','ACCC1','ACCS222H','ACCD77M','ACCAHM','ACCWT','ACC222','ACCHPO','ACCKKM'
						)
		)
	BEGIN
		INSERT INTO @tbSite(siteid)
		SELECT siteid 
		FROM [Site] WITH (NOLOCK)
		WHERE isLicensee = 0 
			AND SiteLabel = 'MBC'
			AND isActive=1
	END
	RETURN
END

GO
