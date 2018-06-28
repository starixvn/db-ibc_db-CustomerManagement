ALTER TRIGGER [dbo].[translog_TOControl_INSERT]
   ON  [dbo].[translog]
   AFTER INSERT
AS 
/*
	Created: Helen
	Date: 2018-03-15
	Task: Integrate Super Live product
	DB: DB053.bodb02
	
	- Revisions:
		- 20180315@Helen: Integrate Super Live product - [Redmine:89986]
		- 20180622@Don: Tuning trigger - [Redmine:97313]
		- 20180626@Helen: Tuning trigger - [Redmine:97442]
	
*/
BEGIN
	
	SET NOCOUNT ON;
	
	--DECLARE @XMLString XML = NULL, @HasError BIT = 0 
	DECLARE  @srecommend INT, @statusID TINYINT, @TransID BIGINT, @bettype INT, @eventID INT
	
	SELECT @srecommend = srecommend, @statusID = statusID, @TransID = translogid, @eventID = eventID, @bettype = gameID
	FROM inserted 
		
	-- SUPER LIVE, tickets insert into translog
	--IF (EXISTS (SELECT 1 FROM inserted WHERE eventID > 0 AND gameID BETWEEN 801 AND 899))
	IF @srecommend in ( 
		836203,--12BETSuperTB
		836226,--12BETSuperRMB
		932181,--AB88SuperTB
		932253,--AB88SuperRMB
		1574008,--MS88SuperRMB
		1574102,--MS88SuperIN
		2747989,--ALogSuperTB
		3167631,--12BETSuperINH
		3287311,--MS88SuperINH
		3293743,--TLCSuperRMB
		3752050,--MFSuperRMB
		4359240,--HAIFASuperRMB
		4833492,--AB88SuperINH
		6630778,--MacaubetSuperIN
		10566445,--AVIASuperRMB
		10580767,--W88SuperTB
		10580785,--W88SuperINH
		14373729,--KeenOceanSuperRMB
		14442433,--XTD3SuperRMB
		17126538,--GamingSoftSuperRMB
		17433116--NewhonbetSuperRMB
	) RETURN -- do not need to control TO for big licensee supers
	
	IF (@eventID > 0 AND @bettype BETWEEN 801 AND 899)
	BEGIN
		INSERT INTO TOControl_TicketDetails_Insert (transid,bettype, statusID)
		VALUES (@TransID,@bettype, @statusID)
	END
	ELSE
	BEGIN
		RETURN
	END
END 


