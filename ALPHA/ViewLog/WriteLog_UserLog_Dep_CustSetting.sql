/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="Dot_Admin,Dot_Member,wsv_nap,bodbExtAccNet,wsv_xnap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv,wsv_lap" viewers="vnteam" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[WriteLog_UserLog_Dep_CustSetting]
		@UserID INT,
		@CustID INT = 0,
		@ActionID INT = NULL,	
		@TrackingValue VARCHAR(MAX)= NULL,
		@TrackingValue2 VARCHAR(MAX) = NULL,
		@Duration INT = NULL,
		@Language VARCHAR(3),
		@IP VARCHAR(15)
		
/* Created: Johnson
	Date: 20180921
    Task: write log for custsetting for cash	
    DB: DBLOG.bodb_CustomerLog

	Revisions:
		- @20180921@Johnson: created sp [Redmine:#101293]
    Param's Explaination:    	
	
*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;   

INSERT INTO dbo.UserLog_Dep_CustSetting
						(	UserID, 
							CustID, 							
							ActionID, 
							TrackingValue,
							TrackingValue2,
							Duration,
							Language,
							IP
							)
				  VALUES (	@UserID, 
							@CustID, 							
							@ActionId, 
							@TrackingValue,
							@TrackingValue2,
							@Duration,
							@Language,
							@IP
							)
END
GO
