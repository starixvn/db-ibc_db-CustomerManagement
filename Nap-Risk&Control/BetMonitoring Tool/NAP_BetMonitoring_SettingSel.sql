/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_ACC]
GO

ALTER PROCEDURE [dbo].[NAP_BetMonitoring_SettingSel]
AS
/*  
	Creator: Elodie
	Date: 20160705
	Task: Get customer list to send email - [Redmine:#58401]
	DB: DBACC/bodb_ACC
  
	History:  

*/
BEGIN
	SET NOCOUNT ON

	SELECT s.SettingID, s.SettingName, s.Value
	FROM dbo.BetMonitoring_Setting s
	WHERE s.SettingName IN ('MinimumTickets', 'Threshold')
END
GO