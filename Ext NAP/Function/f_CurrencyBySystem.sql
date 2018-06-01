ALTER FUNCTION [dbo].[f_CurrencyBySystem]
(
	@System varchar(50) = 'ACCOUNTING'
)
	
	RETURNS @tbCurrency table (exchangeID  int PRIMARY KEY)
AS

/*
Created: 
Task : Get currencies by system
DB:   DBTXN/bodb02; DBAGE/bodb02

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
	- 20180601@Elodie: Add SQ88 group
Param's Explanation:
	- @System: input system name 'ACCTHAI', 'ACCOUNTING', 'ACCINDO'
*/

BEGIN
	IF (@System = 'ACCOUNTING')
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		Select ExchangeID 
		From Exchange (nolock)
	END
	ELSE IF(@System IN ('ACCTHAI','ACCTHAI2','ACCTHAI56','ACCTHAI99'))
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 43 --THB,...
	END
	ELSE IF (@System IN('ACCINDO', 'ACCIN','INDOBS','INDO2'))
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 22 --IND
		UNION SELECT 33 --IDD
		UNION SELECT 34 --IDR
		UNION SELECT 47 --DDD
		UNION SELECT 15 --IN
	END	
	ELSE IF (@System IN ('ACCYEN','ACCYEN789','ACCYEN889','ACCYEN668','ACCYEN888'))
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 16 --YEN		
	END	
	ELSE IF (@System = 'ACCNTD')
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 17 --NTD		
	END
	ELSE IF (@system = 'ACCDDD')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 47 --DDD
	END
	ELSE IF (@system = 'ACCIRR')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 40 --IRR
	END
	ELSE IF (@system = 'ACCUUS')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 20 --UUS
	END
	ELSE IF (@system = 'ACCUSD')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 16	--- 	Yen
		UNION ALL SELECT 17	--- 	NTD
		UNION ALL SELECT 35	--- 	$US
		UNION ALL SELECT 40	--- 	IRR
		UNION ALL SELECT 64 ---		UT
	END
	ELSE IF (@system IN ('ACCUT','ACCUT2'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 64	--- 	UT	
		UNION ALL 
		SELECT 17	--- 	NTD	
	END
	ELSE IF (@System in ( 'MKK99','ACCMKK'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 70 --MKK
	END
	ELSE IF (@System IN('INDO56','INDOWIN','INDO56B'))
	BEGIN
		Insert Into @tbCurrency(exchangeID)
		SELECT 22 --IND
		UNION SELECT 33 --IDD
		UNION SELECT 34 --IDR
		UNION SELECT 15 --IN
	END	
	ELSE IF (@system = 'ACCUSDOTH')
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 16	--- 	Yen
		UNION ALL SELECT 17	--- 	NTD
		UNION ALL SELECT 40	--- 	IRR
	END
	ELSE IF (@System in ( 'ACCMMK'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 69 --MMK
	END
	ELSE IF (@System in ( 'ACCYNG'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 72 --YNG
	END
	ELSE IF (@System in ( 'ACCTESTK68'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 74 --TH
		UNION ALL SELECT 20	--UUS
	END
	ELSE IF (@System in ( 'TH999'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 74 --TH
	END
	ELSE IF (@System in ( 'SQ88'))
	BEGIN
		INSERT INTO @tbCurrency(ExchangeID)
		SELECT 78 --EUR
	END
	RETURN
END

GO
GRANT SELECT ON [dbo].[f_CurrencyBySystem] TO [bodbAdminNet] AS [dbo]
GO
GRANT SELECT ON [dbo].[f_CurrencyBySystem] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[f_CurrencyBySystem] TO [vnteam] AS [dbo]