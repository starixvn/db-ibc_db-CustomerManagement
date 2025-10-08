/*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02" selecters="wsv_nap,wsv_xnap" viewers="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_CurrencyBySystem]
(
	@System VARCHAR(50) = 'ACCOUNTING'
)
	RETURNS @tbCurrency TABLE (exchangeID  INT PRIMARY KEY)
AS

/*
Created: 
Task : Get currencies by system
DB:   DBCUST/CustDB; DBAGE/bodb02

Revisions:
	- 20100720@Shifu: Get currencies by System
	- 20101119@Henry: Add ACCINDO
	- 20110908@Johnson: Add two system ACCYEN789, ACCYEN889
	- 20111122@Johnson: Add ACCDDD system
	- 20120809@Elodie: Add ACCIRR system
	- 2O130404@Jamie: Put UUS for Testing 
	- 20130513@Lukas: add group ACCUSD
	- 20130718@Lukas: add group ACCUT
	- 20140521@Kiwi: add NTD currency into group ACCUT
	- 20150526@Kiwi: add new group ACCUT2
	- 20150812@Amy: add ACCTHAI2 group
	- 20150817@Susan:add ACCIN group
	- 20150909@Susan: add ACCYEN668 group
	- 20151027@Francis: add INDOBS, INDO2 group
	- 20151111@Susan: Add MKK99 group
	- 20160427@Susan: Add ACCUSDOTH group
	- 20160907@Susan: Add ACCMMK group
	- 20161005@Harris: Add ACCYNG group for Allbet
	- 20171003@Elodie: Add ACCTESTK68 group
	- 20171005@Elodie: Add TH999 group
	- 20180601@Elodie: Add SQ88 group - [Redmine: #94865]
	- 20180605@Elodie: Add THEU, 899EU, 789EU group - [Redmine: #94865]
	- 20180611@Elodie: Add SQUS - [Redmine: #96736]
	- 20180901@Elodie: Add ACCTEST - [Redmine: #100925]
	- 20190221@Elodie: Add TH001,TH002,TH003 group
	- 20191021@Gary: add ACCINDO2 group - [Redmine: #122340]
	- 20200508@Elodie: add IBCIndo group - [Redmine: #133858]
	- 20200619@Elodie: add USD into IBCIndo, INDOWIN group - [Redmine: #136096]
	- 20200923@Elodie: Add MMK into ACCMMKMyanmar group, Add UUS into ACCUUSMyanmar group - [Redmine: #141926]
	- 20201102@Winfred: rename group ACCMMKMyanmar to IBCMMR - [Redmine: #141926]
	- 20210301@Percy: Make BC to real group [RedmineID: #146710]
	- 20210305@Tina: add more group ACCSABA789 - [Redmine: #151213]
	- 20210309@Tina: add more group ACCAthena000
	- 20210812@Percy: Add back ACCTHAI2, ACCTHAI56, ACCTHAI99 as normal group [RedmineID: #146710]
	- 20220408@Elodie: Add ACCTHAITT - [Redmine: #171299]
	- 20231027@Johnson: Add ACCThaiSK [redmine: #195550]
	- 20231206@Johnson: Add ACCS56RM [redmine: #197031]
	- 20240227@Johnson: Add ACCHHRM,ACCCH1,ACCMG7,ACCNV1,ACCA951 [redmine: #201332]
	- 20240227@Johnson: Add ACCTW1,ACCSB1 [redmine: #201452]
	- 20240321@Johnson: Add ACCDS17,ACCS359M,ACC801AH,ACCC1,ACCS222H,ACCD77M,ACCAHM,ACCWT,ACC222,ACCHPO,ACCKKM [redmine: #202663]
	- 20241119@Elodie: Add ACCPBTH - [Redmine: #213793]
	- 20241119@Elodie: Add $US for ACCPBTH - [Redmine: #213893]
	- 20250122@Elodie: Add ACCTHAI9TA - [Redmine: #217269]
	- 20250908@Helios: Add currencies - by System ExtraPTRM - [Redmine: #238079]
	- 20251008@Dave: Add ACCGTHB [Redmine: #241127]
	
Param's Explanation:
	- @System: input system name 'ACCTHAI', 'ACCOUNTING', 'ACCINDO'
*/

BEGIN
	IF (@System IN ('ACCOUNTING','ACCTEST'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT ExchangeID 
		FROM dbo.Exchange WITH (NOLOCK);
	END	
	ELSE IF(@System IN ('ACCTHAI', 'BC', 'ACCTHAI2', 'ACCTHAI56', 'ACCTHAI99','ACCTHAITT','ACCThaiSK','ACCTHAI9TA','ACCGTHB'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 43; --THB,...
	END
	ELSE IF (@System IN('ACCINDO', 'ACCIN','INDOBS','INDO2','ACCINDO2'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 22 --IND
		UNION SELECT 33 --IDD
		UNION SELECT 34 --IDR
		UNION SELECT 47 --DDD
		UNION SELECT 15; --IN
	END	
	ELSE IF (@System IN ('ACCYEN','ACCYEN789','ACCYEN889','ACCYEN668','ACCYEN888'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 16; --YEN					
	END	
	ELSE IF (@System = 'ACCNTD')
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 17; --NTD		
	END
	ELSE IF (@system = 'ACCDDD')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 47; --DDD
	END
	ELSE IF (@system = 'ACCIRR')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 40; --IRR
	END
	ELSE IF (@system IN ('ACCUUS','ACCUUSMyanmar','AccThaiSKUUS'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 20; --UUS
	END
	ELSE IF (@system = 'ACCUSD')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 16	--- 	Yen
		UNION ALL SELECT 17	--- 	NTD
		UNION ALL SELECT 35	--- 	$US
		UNION ALL SELECT 40	--- 	IRR
		UNION ALL SELECT 64; ---		UT
	END
	ELSE IF (@system IN ('ACCUT','ACCUT2'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 64	--- 	UT	
		UNION ALL 
		SELECT 17;	--- 	NTD			
	END
	ELSE IF (@System IN ( 'MKK99','ACCMKK'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 70; --MKK
	END
	ELSE IF (@System IN('INDO56','INDO56B'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 22 --IND
		UNION SELECT 33 --IDD
		UNION SELECT 34 --IDR
		UNION SELECT 15; --IN
	END	
	ELSE IF (@System IN('IBCIndo','INDOWIN'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 22 --IND
		UNION SELECT 33 --IDD
		UNION SELECT 34 --IDR
		UNION SELECT 15 --IN
		UNION SELECT 95; --USD
	END	
	ELSE IF (@system = 'ACCUSDOTH')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 16	--- 	Yen
		UNION ALL SELECT 17	--- 	NTD
		UNION ALL SELECT 40;	--- 	IRR
	END
	ELSE IF (@System IN ( 'ACCMMK'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 69; --MMK
	END
	ELSE IF (@System IN ( 'ACCYNG'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 72; --YNG
	END
	ELSE IF (@System IN ( 'ACCTESTK68'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 74 --TH
		UNION ALL SELECT 20;	--UUS
	END
	ELSE IF (@System IN ( 'TH999','TH001','TH002','TH003'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 74; --TH
	END
	ELSE IF (@System IN ( 'SQ88','THEU','899EU','789EU'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 78; --EUR
	END
	ELSE IF (@System IN ( 'SQUS'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 3; --US$
	END
	ELSE IF (@System IN ( 'IBCMMR'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 69; --MMK
	END
	ELSE IF (@System IN ( 'ACCAthena000'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 20; --UUS
	END
	ELSE IF (@System IN ('ACCSABA789'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)		
		SELECT 51; --INH		
	END		
	ELSE IF(@System IN ('ACCPBTH'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 43 --THB,...
		UNION ALL SELECT 35;	--- 	$US
	END
	ELSE IF(@System IN ('ExtraPTRM'))
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT 2; --RM,...
	END
	
	--Malaysia HL
	ELSE IF(@System IN ('ACCS56RM','ACCHHRM','ACCCH1','ACCMG7','ACCNV1','ACCA951','ACCTW1','ACCSB1',
						'ACCDS17','ACCS359M','ACC801AH','ACCC1','ACCS222H','ACCD77M','ACCAHM','ACCWT','ACC222','ACCHPO','ACCKKM'
						)
			)
	BEGIN
		INSERT INTO @tbCurrency(exchangeID)
		SELECT ExchangeID 
		FROM dbo.Exchange WITH (NOLOCK);
	END
	RETURN;

END;

