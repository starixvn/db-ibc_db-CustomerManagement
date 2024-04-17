/*<info serverAlias="DBCUST-CustDB, DBTXN-CustDB, DBACC-bodb02, DBAGE-bodb02, DBEXT-bodb02" executers="bodbAdminNet,wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv,bodbExtAccNet,wsv_xnap,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_SiteDBConfigSel
	@CustID INT = NULL,
	@username VARCHAR(30) = NULL,
	@SiteDBGroupID SMALLINT = NULL
AS
/*
	Created by: Elodie
	Date: 20220715
	Task : Get SiteDBConfig info
	DB: DBCUST/CustDB
	Revisions:
		- 20220721@Elodie: Initial SP

	Example:	EXEC Acc_SiteDBConfigSel @CustID = 791048 
				EXEC Acc_SiteDBConfigSel @CustID = 180090
				EXEC Acc_SiteDBConfigSel @SiteDBGroupID = 1
				EXEC Acc_SiteDBConfigSel @Username = ''
				EXEC Acc_SiteDBConfigSel
*/
BEGIN
	SET NOCOUNT ON  
	
	IF @CustID IS NOT NULL
	BEGIN 
		SELECT	sc.SiteDBGroupID, 
				sc.LinkedServerName, 
				sc.ClientAccessName, 
				sc.AGIP
		FROM SiteDBConfig sc WITH (NOLOCK)
			INNER JOIN site s WITH (NOLOCK) ON sc.SiteDBGroupID = s.SiteDBGroupID
			INNER JOIN Customer c WITH (NOLOCK) ON s.site = c.site
		WHERE CustID = @CustID
	END
	ELSE IF @username IS NOT NULL
	BEGIN 
		SELECT	sc.SiteDBGroupID, 
				sc.LinkedServerName, 
				sc.ClientAccessName, 
				sc.AGIP
		FROM SiteDBConfig sc WITH (NOLOCK)
			INNER JOIN site s WITH (NOLOCK) ON sc.SiteDBGroupID = s.SiteDBGroupID
			INNER JOIN Customer c WITH (NOLOCK) ON s.site = c.site
		WHERE username = @username
	END
	ELSE IF @SiteDBGroupID IS NOT NULL
	BEGIN
		SELECT	sc.SiteDBGroupID, 
				sc.LinkedServerName, 
				sc.ClientAccessName, 
				sc.AGIP
		FROM SiteDBConfig sc WITH (NOLOCK)
		WHERE SiteDBGroupID = @SiteDBGroupID
	END
	ELSE
	BEGIN 
		SELECT sc.SiteDBGroupID, sc.LinkedServerName, sc.ClientAccessName, sc.AGIP
		FROM SiteDBConfig sc WITH (NOLOCK)
	END		
END
GO