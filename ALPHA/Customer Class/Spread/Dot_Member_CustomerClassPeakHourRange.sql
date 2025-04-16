/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_Admin,svc_tig" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Dot_Member_CustomerClassPeakHourRange] 
	@IsTest BIT = 0
AS
/*
	Created: Winfred
	Date: 20241024
	Task : [NAP CM] Customer Class Peak Hour Spread - SP Integrate [#186118]
	DB: DBCUST/CustDB

	Revisions:
		- 20241024@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]

	Param's Explanation:
	Example: Dot_Member_CustomerClassSpreadSel @SiteID = 25, @Currency = 1, @CustomerClass =13 , @Platform =3 , @IsTest=0, @IsLicensee = 0
	
*/ 
BEGIN
	SET NOCOUNT ON;
	
	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT 
		r.WeekDay,
		r.StartRange,
		r.EndRange
	FROM CustomerClassPeakHourRanger r WITH(NOLOCK)
	WHERE r.IsTest = @IsTest
END