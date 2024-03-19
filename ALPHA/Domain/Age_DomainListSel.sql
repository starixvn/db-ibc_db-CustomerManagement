/*<info serverAlias="DBACC-bodb02" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv"  viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Age_DomainListSel] 
	-- Add the parameters for the stored procedure here
	@Site VARCHAR(50)
AS

/*
 Created: 20230222@Helios 
 Task : Select DomainList Of SiteLabel 
 DB: DBACC-bodb02

 
 Revisions:  
   - 20230222@Helios: Select DomainList Of SiteLabel [Redmine: #184101]  
   - 20231016@Tacy: NAP/Alpha - Manage Domain - Change table and Server/DB [Redmine: #194024]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @SiteID INT 

	SELECT @SiteID=siteid 
	FROM Site WITH (NOLOCK)
	WHERE site=@Site

	SELECT Domain 
		, CASE WHEN System='Agency' THEN 1 ELSE 0 END AS 'IsAgency'
	FROM dbo.DomainManagement d WITH (NOLOCK)
	WHERE @SiteID IN (SELECT TRIM(VALUE) FROM STRING_SPLIT(d.Site,','))
		AND d.Status=3 AND isDeleted=0
END
GO