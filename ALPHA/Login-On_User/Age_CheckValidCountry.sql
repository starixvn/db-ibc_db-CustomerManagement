USE [CustDB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_CheckValidCountry]
	@IP NVARCHAR(15),
	@countryCode VARCHAR(2) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 2014-11-18
		Task: Check IP from block countries	
		DB: DBCUST/CustDB
		
		Revisions:
			- 20160507@Sophia: Block users from CountryCode except Office IPs [Redmine: #60347]
			- 20160714@Victor: Allow users that have IP in White list [Redmine: #60347]
		
		Parameter's Explanation:
	*/
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @countryLONG nvarchar(64)

	DECLARE @PrefixLoginIP NVARCHAR(11)						
	SELECT  @PrefixLoginIP = left(@IP, (len(@IP) - (charindex('.',reverse(@IP)))+1))

	EXEC IPDB.dbo.GetIPInfo_out @IP= @IP, @countrySHORT = @countryCode OUTPUT, @countryLONG = @countryLONG OUTPUT

	IF @IP IN (select IP FROM IPDB.dbo.IPOffice WITH (NOLOCK)) -- In IP's Office then return CountryCode as 'OF'
	BEGIN 
		SELECT @CountryCode = 'OF'
	END
	IF (@CountryCode = 'PH' AND @IP IN (SELECT IP FROM IPDB.dbo.IPWhiteList WITH (NOLOCK) WHERE IsActive = 1)) -- IP in PH and in White list then return CountryCode as 'WL'	
	BEGIN 
		SELECT @CountryCode = 'WL'
	END
END
GO

GRANT EXECUTE ON [dbo].[Age_CheckValidCountry] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CheckValidCountry] TO [bodbDownlineNetView]
GO