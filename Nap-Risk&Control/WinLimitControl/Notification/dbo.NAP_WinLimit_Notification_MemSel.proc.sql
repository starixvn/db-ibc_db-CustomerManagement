SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

/****** Object:  Stored Procedure dbo.NAP_WinLimit_Notification_MemSel    Script Date: 4/5/2017 1:04:53 PM ******/

ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemSel]
AS

/*
Created: 20150702@bobby.nguyen
Task : #35215 - Win Limit Control - Notification select member
DB: DBCUST.CustDB
Original:
Revisions:
	- 20150702@bobby.nguyen: Initial
	- 20160507@Patrick: #57213 - Voidbridge integration
	- 20160523@Helen: Hardcode for UUS - [Redmine: 57940]
	- 20160524@Helen: Change condition to send email - [Redmine: 57940]
	- 20160701@Robert: CWL - Phase 2 - Support RED and Yellow level - [Redmine: 57722]
	- 20160802@Robert: CWL Phase 2 - Wrong Exchange Rate using in the email notification - [Redmine: 61839]
	- 20160802@Robert: CWL Phase 2 - email notification Enhancement - [Redmine: 62253]
	- 20161027@Robert: CWL Phase 3 - email notification Enhancement - [Redmine: 61220]
	- 20170306@Robert: CWL Phase 3 - email notification Enhancement - [Redmine: 61220]
	- 20170306@Helen: CWL Phase 3A - email notification Enhancement - [Redmine: 72604]
	- 20170515@Helen: NAP Risk & Control - CHANGE REQUEST [Redmine: 75332]
	
Param's Explanation:
	• @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	• @ErrMsg: Error description.
*/

     BEGIN
         SELECT wl.custid,
                c.username,
                CASE
                    WHEN e.exchangeid = 20
                    THEN 'UUS'
                    ELSE e.currency
                END AS code,
                ag.site,
                s.isLicensee AS IsDeposit,
                p.ProductName,
                p.ProductId,
                wl.GroupID,
                CASE
                    WHEN wl.Levelid = 1
                    THEN wl.MaxWinLimitSetting.value('(/MaxWinLimitSetting/@Level1)[1]', 'MONEY')
                    WHEN wl.LevelID = 2
                    THEN wl.MaxWinLimitSetting.value('(/MaxWinLimitSetting/@Level2)[1]', 'MONEY')
                    WHEN wl.LevelID = 3
                    THEN wl.MaxWinLimitSetting.value('(/MaxWinLimitSetting/@Level3)[1]', 'MONEY')
                END AS WinlimitAmount,
                wl.TotalWinAmt AS TotalWinAmt_OriginalCurrency,
                wl.TotalWinAmt_RM AS TotalWinAmt_BaseCurrency,
                wl.ModifiedDate,
                wl.WinlostDate,
                wl.LevelId,
                l.LevelName
         FROM WinLimit_CustGameMonitoring_History wl WITH (NOLOCK)
              INNER JOIN Customer c WITH (NOLOCK) ON c.custid = wl.CustID
              INNER JOIN Customer ag WITH (NOLOCK) ON ag.custid = c.recommend
              INNER JOIN Site S WITH (NOLOCK) ON S.site = ag.site
              INNER JOIN DBPRO.bodb02.dbo.Products p WITH (NOLOCK) ON p.ProductID = wl.ProductID
              INNER JOIN Winlimit_LevelSetting l WITH (NOLOCK) ON l.LevelId = wl.LevelId
              INNER JOIN exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
         WHERE wl.IsNotified = 0
               AND S.isActive = 1;
     END;
GO
SET QUOTED_IDENTIFIER OFF;
GO
SET ANSI_NULLS ON;
GO
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [vnteam];
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_Notification_MemSel] TO [bodbAdminNet];
GO