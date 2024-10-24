/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Age_CustSubIns_Detail
(
	 @subaccid	int
	,@custid	int -- agentid or masterid or superid
	,@username	varchar(30)
	,@userpwd	varchar(40)
	,@firstname nvarchar(50) = '-'
	,@lastname	nvarchar(50) = '-'
	,@PageAccess varchar(50)
	,@Language	varchar(2) = 'E'
	
	,@ErrCode	int = 0 OUTPUT
	,@ErrMsg	nvarchar(4000) = '' OUTPUT
)
WITH EXECUTE AS OWNER
AS
/*
	Created: 20240704@Louisa
	Task: Scaleout DBCUST Redmine:#199915
	DB: DBCUST/CUSTDB
		
	Revisions:
		- 20240704@Louisa: initial Redmine:#199915

	Parameter's Explanation:

*/
BEGIN
	BEGIN TRY
		SET IDENTITY_INSERT custsub ON
		INSERT INTO custsub
		(
			subaccid,
			custid,
			username,
			userpwd,
			firstname,
			lastname,
			PageAccess,
			createdate			
		)
		VALUES
		(
			@subaccid,
			@custid,
			@username,			
			@userpwd,
			@firstname,
			@lastname,
			@PageAccess,
			getdate()
		)
		SET IDENTITY_INSERT custsub OFF
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = ERROR_MESSAGE()
			 , @ErrCode = 104
		RETURN	
	END CATCH
END
GO
