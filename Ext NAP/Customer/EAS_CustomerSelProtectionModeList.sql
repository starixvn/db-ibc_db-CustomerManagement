/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE EAS_CustomerSelProtectionModeList
	@GroupName		VARCHAR(50),
	@Roleid			TINYINT,
	@UserId			INT,
	@CustList		VARCHAR(MAX)
 AS
 /*
	Created: Elodie
	Date: 20210824
	Task: Get Protection Mode for EXTNAP
	DB: DBCUST/CustDB
	Revisions:
		- 20210824@Elodie: Initial sp [Redmine: #160151]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 

	Parameter's Explanation:

	Example: exec EAS_CustomerSelProtectionModeList_uat2 @GroupName='ACCTEST',@Roleid=2,@UserId=52523910,@CustList='14373897,19989098,54298539,54298542,54298575,54298577,54298578,54298579'

*/ 
BEGIN	
	SET NOCOUNT ON
	DECLARE @IsInternalAdmin BIT = 0
	DECLARE @CustListTmp TABLE (CustId INT)

	INSERT INTO @CustListTmp (CustId)
	SELECT  value
	FROM STRING_SPLIT (@CustList, ',')
	WHERE value <> ''

	-- check belong to group 
	IF EXISTS (	SELECT 1 
				FROM CustInfo ci WITH (NOLOCK)
					INNER JOIN @CustListTmp t ON t.custid = ci.custid
				WHERE NOT EXISTS (SELECT custid FROM dbo.Acc_CustGroup cg WITH(NOLOCK) WHERE GroupName = @GroupName AND cg.CustID = ci.srecommend))
	BEGIN
		RETURN
	END

	EXEC dbo.Acc_CustomerIsInternalAdmin @CustId = @UserID, @IsInternalAdmin = @IsInternalAdmin OUTPUT

	--Check special site
	DECLARE @DenySite TABLE (siteid INT, site NVARCHAR(50), SpecialGroup TINYINT)
	INSERT INTO  @DenySite (siteid , site,SpecialGroup)
	SELECT siteid , site,SpecialGroup 
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser (@UserId)

	IF (@IsInternalAdmin = 1 
		AND EXISTS (SELECT 1 
					FROM @DenySite s
						INNER JOIN Customer c WITH (NOLOCK) ON s.site = c.site 
						INNER JOIN @CustListTmp t ON t.custid = c.custid))
		RETURN

	SELECT ci.custid, ci.username, ci.roleid, ISNULL(IsProtectedMode,0) AS IsProtectedMode
	FROM CustLoginInfo cl WITH(NOLOCK)
		INNER JOIN CustInfo ci WITH (NOLOCK) ON cl.custid = ci.custid
		INNER JOIN @CustListTmp t ON ci.custid = t.custid
	WHERE roleid = @Roleid
END
GO
