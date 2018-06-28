ALTER TRIGGER [dbo].[bettrans_TOControl_INSERT]
   ON  [dbo].[bettrans]
   AFTER INSERT
AS 
/*
	Created: Helen
	Date: 2017-09-20
	Task: Insert new CustId to Gobal setting (multiple insert)
	DB: DB053.bodb02
	
	- Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20171110@Helen: Enhance performance for TO trigger - [Redmine: 86052]
		- 20171212@Helen: Support UUS - Implement some change request from OPS Team - [Redmine: 85638]
		- 20180315@Helen: Integrate Super Live product - [Redmine:89986]
		- 20180622@Don: Tuning trigger - [Redmine:97313]
		- 20180626@Helen: Tuning trigger - [Redmine:97442]
	
*/
BEGIN
	--DECLARE @XMLString XML = NULL, @HasError BIT = 0 
			
	SET NOCOUNT ON;

	DECLARE @srecommend INT, @bettype INT, @statusID TINYINT, @TransID BIGINT
	SELECT @srecommend = srecommend, @bettype = bettype, @statusID = statusID, @TransID = transid
	FROM inserted 

	IF @bettype >= 2000 RETURN -- Process for sportbook bettype for TO Control only

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

	-- SUPER LIVE, tickets running in translog, then void/reject/refund
	IF (@bettype BETWEEN 801 AND 899) AND (@statusID NOT BETWEEN 101 AND 103)
		RETURN
	
	INSERT INTO TOControl_TicketDetails_Insert (transid,bettype, statusID)
	VALUES (@TransID,@bettype, @statusID)
		
	
END 
