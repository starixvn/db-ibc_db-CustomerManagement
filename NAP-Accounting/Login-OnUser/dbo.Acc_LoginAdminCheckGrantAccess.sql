ALTER PROCEDURE [dbo].[Acc_LoginAdminCheckGrantAccess]
	@custid		int,
	@LoginIP	nvarchar(15),
	@isAccess	BIT = 1 OUTPUT
AS
	/*
		Created: Johnson
		Date: 2012-12-05
		Task: Check ABS's admins login from VPN
		DB: DBTXNIP/IPDB
		
		Revisions:
			- 20130118@Elodie: Move SP from DBTRANS.BODB02 to DBTXNIP.IPDB
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON
	IF @custid IN (5452633,5452634,5452636)--ABSSS1,ABSSS2,ABSSS3
	BEGIN
		SELECT @isAccess = 1
		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM IPOffice WITH(NOLOCK) WHERE IP = @LoginIP AND remark LIKE 'VPN%')
		SELECT @IsAccess = 0	
GO
