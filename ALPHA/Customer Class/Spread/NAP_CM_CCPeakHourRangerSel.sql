/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_CM_CCPeakHourRangerSel] 
	@IsTest	 TINYINT = 0	
AS
/*
	Created: Winfred
	Date: 186118
	Task : [NAP CM] Customer Class - Add Peak Hour Ranger setting
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20240612@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]

	Param's Explanation:

	Example: exec NAP_CM_CCPeakHourRangerSel 
*/ 
BEGIN
	SET NOCOUNT ON;

	SELECT   RangeID
			,WeekDay
			,StartRange
			,EndRange
			,IsTest
			,LastModifiedUser
			,LastModifiedTime
	FROM CustomerClassPeakHourRanger WITH(NOLOCK)
	WHERE IsTest <= @IsTest
END
GO
