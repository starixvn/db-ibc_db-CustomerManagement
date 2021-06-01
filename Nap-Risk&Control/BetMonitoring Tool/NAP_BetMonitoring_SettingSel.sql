/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_BetMonitoring_SettingSel]
AS
/*  
	Creator: Elodie
	Date: 20160705
	Task: Get customer list to send email - [Redmine:#58401]
	DB: DBACC/bodb02
  
	Revisions:		
		- 20210512@Eden: Migrate bodb_Acc to main server [#152636]

*/
BEGIN
	SET NOCOUNT ON

	SELECT s.SettingID, s.SettingName, s.Value
	FROM dbo.BetMonitoring_Setting s WITH(NOLOCK)
	WHERE s.SettingName IN ('MinimumTickets', 'Threshold')
END
GO