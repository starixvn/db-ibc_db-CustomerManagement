/*<info serverAlias="DBCust-CustDB" executers="bodbadminNet,bodbExtAccNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelSiteByUserName]
	@username VARCHAR(50) = '',
	@Userid INT=NULL
AS 
/*	Created by: [Khoa] 
	Date: 20100130
	Task: Get Site by username
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20160620@Winnie: #48948 Hide_special_sites_from_unautorized_users
		- 20180808@Helen: DB05.DBPOLICY migration  [Redmine:99462]
		- 20191029@Andy: Include checking special permission for internal admins only [Redmine: 121712]
		
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)
	DECLARE @IsInternalAdmin BIT = 0

	IF @Userid IS NULL
	BEGIN
		SELECT site, roleid, custid 
		FROM dbo.customer WITH (NOLOCK) 
		WHERE username = @username 
	END
	ELSE
	BEGIN
		SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
		EXEC Acc_CustomerIsInternalAdmin @CustID = @Userid, @IsInternalAdmin = @IsInternalAdmin OUTPUT
		
		IF @IsInternalAdmin = 1
		BEGIN
			INSERT INTO  @tmp (siteid , site,SpecialGroup)
			SELECT siteid , [site], SpecialGroup FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser(@tmpUserid)
		END
		
		SELECT site, roleid, custid 
		FROM dbo.customer WITH (NOLOCK) 
		WHERE username = @username AND site NOT IN (SELECT site FROM @tmp )
	
	END
END