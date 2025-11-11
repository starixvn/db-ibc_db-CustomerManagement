/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerMoveSite_Validate]
	@UserId			INT,
	@CustId			INT,
	@Site			varchar(50),
	@DeniedList		NVARCHAR(MAX)=NULL,
	@ErrCode		INT OUTPUT,
	@ErrMsg			varchar(200) OUTPUT

AS
/*	Created by: [Khoa] 
	Date: 20091224
	Task: Move Site for customer
	DB: DBCUST-CUSTDB

	Revisions:		
		- 20241010@Helen: move site for CREDIT - [Redmine:#212007]
		- 20251010@Helios: Upgrade ExchangeID DataType [Redmine:#242140] 

	Param's Explanation:
		@CustID: Custid of customer want to move site. We allow to move all customers
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @SiteLabel VARCHAR(50)

	SELECT @SiteLabel=SiteLabel
	FROM SITE WITH (NOLOCK)
	WHERE SITE=@Site

	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT)
	
	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmp (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	END
	
	IF (@site IN (SELECT site FROM @tmp))
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg ='You don''t have permission to access'
		RETURN
	END
	
	IF NOT EXISTS(SELECT 1 FROM Site (NOLOCK) WHERE SITE = @Site)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Do not exist any site name as ' + @Site + ' in the system.'
		RETURN
	END
	
	IF EXISTS(SELECT 1 FROM customer (NOLOCK) 
			WHERE custid = @custid
				AND srecommend IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))
			)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Cannot move site for deposit customer.'
		RETURN
	END
	
	DECLARE @OldSite varchar(50), @OldSiteLabel varchar(50), @LogSPData varchar(8000)
	DECLARE @userName VARCHAR(50),@currency SMALLINT

	SELECT @OldSite =  c.site, @OldSiteLabel = s.SiteLabel
	from customer c with(nolock) 
	inner join site s with (nolock) on s.site=c.site
	where custid = @CustId	

	SELECT @userName = username,@currency = currency FROM custInfo WITH (NOLOCK) WHERE custid = @CustId
	--IF @OldSite = '766666' OR @Site = '766666'
	-- 20151026@Don - Support moving site from 766666 to other sites
	IF @currency <> 20 -- UUS For Myanma Odds
	BEGIN
		IF  dbo.fn_IsMyanmarOddsBySite(@OldSite) =  1 OR dbo.fn_IsMyanmarOddsBySite(@Site) = 1
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'Cannot move site for ' + @userName + ' since amongs its new and old sites, one has Myanmar Odds.'
			RETURN
		END
	END
	
	IF @site = 'CN88' OR @OldSite = 'CN88'
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Cannot move site for CN88.'
		RETURN
	END
	
	--
	IF  (@OldSiteLabel = '789y' AND @SiteLabel <> '789y' AND @currency NOT IN (20,72)) --UUS, YNG (Testing)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Cannot move site for ' + @OldSite + ' (' + SiteLabel + ')'
		FROM Site WITH (NOLOCK)
		WHERE site=@OldSite
		RETURN
	END

END