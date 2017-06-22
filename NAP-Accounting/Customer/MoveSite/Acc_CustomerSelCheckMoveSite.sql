ALTER PROCEDURE [dbo].[Acc_CustomerSelCheckMoveSite]
	@CustId			INT,
	@UserId			INT,
	@IsAllow		BIT OUTPUT,
	@RoleId			INT OUTPUT
AS
/*	Created by: [Khoa]
	Date: 20091224
	Task: Check the customer allow to move site or not
	DB: DBAGE/bodb02

	Revisions:		
		- 20130121@Dan: change linked server DB03 to DBPOLICY	
		- 20160707@Winnie: #48948 Hide_special_sites_from_unautorized_users
	Param's Explanation:
		@CustID: Custid of customer want to move site. We do not allow Member move site

*/
SET NOCOUNT ON 
BEGIN
	DECLARE @SearchQuery varchar(1024)
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)
	DECLARE @site VARCHAR(50)
	SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
	SELECT @SearchQuery = 'SELECT * 
	FROM OPENQUERY(DBPOLICY, 
	''SELECT siteid , site,SpecialGroup FROM bodb02.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	EXECUTE(@SearchQuery)
	

	SELECT @IsAllow = 0, @RoleId = 0

	--Check permission for account site: @phuc20080213
	DECLARE @ErrCode int, @ErrMsg varchar(200)
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[MoveSite]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	
	SELECT @RoleId = ISNULL(roleid,0),@site=site FROM customer (NOLOCK) WHERE custid=@CustId	
	
	IF @RoleId IN(4,3,2) AND @site NOT IN (SELECT site FROM @tmp )-- for Super, Master , Agent
		SELECT @IsAllow = 1		
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelCheckMoveSite] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelCheckMoveSite] TO [vnteam]

