/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_Winlimit_GameGroupSettingIns] 
	@ProductId  INT, 
	@GroupId    INT, 
	@BettypeIds VARCHAR(MAX) = '', 
	@UserID     INT          = 0, 
	@IP         VARCHAR(20)  = ''
AS

/*
Created: Robert	 
Date: 2022-07-07
Task: 20220707@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page

DB: DBCUST/CustDB

Revisions:
    - 20220707@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page
	- 20240809@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
Parameters Explanation:	    
 
*/

    BEGIN
	   SET NOCOUNT ON;

	   DECLARE 
		   @StartRun       DATETIME
		 , @EndRun         DATETIME
		 , @Duration       INT
		 , @TrackingValue1 VARCHAR(MAX);

	   SELECT 
			@StartRun = GETDATE();

	   DECLARE 
		   @Bettype TABLE
					   (
		   Bettype INT
					   );
	   INSERT INTO @Bettype
		 (
			Bettype
		 )
			SELECT 
				  t.value
			FROM STRING_SPLIT(@BettypeIds, ',') t
			WHERE t.value <> '';

	   INSERT INTO dbo.Winlimit_GameGroupSetting
		 (
			ProductID, 
			BetTypeID, 
			GroupID,
			RepUpdateTime
		 )
			SELECT 
				  @ProductId, 
				  t.Bettype, 
				  @GroupId,
				  SYSDATETIME()
			FROM @Bettype t;


	   BEGIN -- Write Log
		  SELECT 
			    @EndRun = GETDATE(), 
			    @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
		  SET @TrackingValue1 = '<NAP_Winlimit_GameGroupSettingIns';
		  SET @TrackingValue1 = @TrackingValue1 + '" @ProductID ="' + CONVERT(VARCHAR(50), @ProductID);
		  SET @TrackingValue1 = @TrackingValue1 + '" BettypeIDs ="' + CONVERT(VARCHAR(2000), @BettypeIDs);
		  SET @TrackingValue1 = @TrackingValue1 + '" GroupId="' + CONVERT(VARCHAR(20), @GroupId);

		  SET @TrackingValue1 = @TrackingValue1 + '" UserId="' + CONVERT(VARCHAR(20), @UserId);
		  SET @TrackingValue1 = @TrackingValue1 + '" IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" />';
		  BEGIN TRY
			 EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
				 @UserID = @UserID, 
				 @ActionID = 31211, 
				 @TrackingValue = @TrackingValue1, 
				 @Duration = @Duration;
		  END TRY
		  BEGIN CATCH
		  END CATCH;
	   END;
    END;


