/*<info serverAlias="DBACC-bodb02, DBAGE-bodb02, DBEXT-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_CustDBConfigSel	
	@CustDBGroupID SMALLINT = NULL
AS
/*
	Created by: Elodie
	Date: 20240716
	Task : Get CustDBSiteConfig info
	DB: DBCUST/CustDB
	Revisions:
		- 20240716@Elodie: Initial SP 

	Example:	EXEC Acc_CustDBConfigSel @SiteDBGroupID = 1				
				EXEC Acc_CustDBConfigSel
*/
BEGIN
	SET NOCOUNT ON  
	
	IF @CustDBGroupID IS NOT NULL
	BEGIN
		SELECT	cc.CustDBGroupID, 
				cc.LinkedServerName, 
				cc.ClientAccessName, 
				cc.AGIP
		FROM CustDBSiteConfig cc WITH (NOLOCK)
		WHERE CustDBGroupID = @CustDBGroupID
	END
	ELSE
	BEGIN 
		SELECT cc.CustDBGroupID, cc.LinkedServerName, cc.ClientAccessName, cc.AGIP
		FROM CustDBSiteConfig cc WITH (NOLOCK)
	END		
END
GO