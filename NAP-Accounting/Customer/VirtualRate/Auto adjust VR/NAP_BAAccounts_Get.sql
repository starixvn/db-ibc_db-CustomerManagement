USE [bodb_CustomerLog]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_BAAccounts_Get]
AS
/*
	Created: Long.Luu
	Date: 2018-10-03
	Task : Get all BA Account
	DB: DBLOG/bodb_CustomerLog
	Original: New One

	Revisions:	
		- 20181003@Long:	Create new (Feature #102609)

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON;

	SELECT ba.CustID
	FROM bodb_licensee.dbo.[LicenseeBAHistory] ba WITH (NOLOCK)
	WHERE ba.Status = 'Running'; 
END;

/*  
GO  
GRANT EXECUTE ON [dbo].[NAP_BAAccounts_Get] TO [bodbAdminNet]  
GO  
GRANT VIEW DEFINITION ON [dbo].[NAP_BAAccounts_Get] TO [bodbAdminNet]  
GO  
*/