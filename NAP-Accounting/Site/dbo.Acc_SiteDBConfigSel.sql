/*<info serverAlias="DBCUST-CustDB, DBACC-bodb02, DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_SiteDBConfigSel
	@CustID INT = NULL
AS
/*
	Created by: Elodie
	Date: 20220715
	Task : Get SiteDBConfig info
	DB: DBCUST.CustDB
	Revisions:
		- 20220721@Elodie: Initial SP

	Example:	EXEC Acc_SiteDBConfigSel @CustID = 791048 
				EXEC Acc_SiteDBConfigSel @CustID = 180090
*/
BEGIN
	SET NOCOUNT ON  
	DECLARE @Site NVARCHAR(50),
			@SiteDBGroupID SMALLINT,
			@LinkedServerName  VARCHAR(512),
			@ClientAccessName VARCHAR(512),
			@AGIP VARCHAR (50)

	IF @CustID IS NULL OR @CustID = 0
	BEGIN 
		SELECT DISTINCT sc.SiteDBGroupID, sc.LinkedServerName, sc.ClientAccessName, sc.AGIP
		FROM SiteDBConfig sc WITH (NOLOCK)
	END
	ELSE
	BEGIN 
		SELECT @Site = site FROM Customer c WITH (NOLOCK) WHERE CustID = @CustID

		SELECT	@Site = sc.Site, 
				@SiteDBGroupID = sc.SiteDBGroupID, 
				@LinkedServerName = sc.LinkedServerName, 
				@ClientAccessName = sc.ClientAccessName, 
				@AGIP = sc.AGIP
		FROM SiteDBConfig sc WITH (NOLOCK)
		WHERE site = @Site
		
		IF @@ROWCOUNT = 0
			SELECT	@Site = sc.Site, 
					@SiteDBGroupID = sc.SiteDBGroupID, 
					@LinkedServerName = sc.LinkedServerName, 
					@ClientAccessName = sc.ClientAccessName, 
					@AGIP = sc.AGIP
			FROM SiteDBConfig sc WITH (NOLOCK)
			WHERE siteid = 0

		SELECT @SiteDBGroupID AS SiteDBGroupID, @LinkedServerName AS LinkedServerName, @ClientAccessName AS ClientAccessName, @AGIP AS AGIP
	END
END
GO