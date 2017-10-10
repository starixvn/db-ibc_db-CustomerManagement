/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_AGE]
GO

ALTER PROCEDURE [dbo].[NAP_LimitLoss_SMAMaxLossUpd]
    @CustId		INT,
    @MaxLoss	MONEY,
	@Mode		BIT = 0,
    @UserID		INT = 0,
    @IP			NVARCHAR(50) = NULL,
    
    @ErrCode	INT = 0 OUT,
    @ErrMsg		NVARCHAR(200)='' OUT

AS
/*
	Created: Aaron
	Date: 20160608
	Task : SMA Loss monitor report
	DB: DBAGE/bodb_Age

	Revisions:
		- 20170915@Elodie: Support Group Headline Setting [Redmine: #82892]

	Parameter's explaination: 
		- Mode =	0: SMA setting
					1: Group Headline Setting
	
	Example:
	
*/

BEGIN
    SET NOCOUNT ON

	DECLARE	@startRun			DATETIME,
			@endRun				DATETIME,
			@duration			INT,
			@MaxLoss_Old		MONEY,
			@GroupHeadlineID	SMALLINT

    SET		 @startRun = GETDATE()

    --Check permission 
    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[LossMonitor]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
    IF @ErrCode <> 0
	    RETURN
	    
    IF @MaxLoss >= 0
    BEGIN
	   SELECT @ErrCode = 101, @ErrMsg = 'Max Loss should be negative!'
	   RETURN
    END	    

	IF @Mode = 0
	BEGIN
		IF @CustId <= 0
		   OR NOT EXISTS (SELECT 1 FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
			RETURN
		END
		
		SELECT @MaxLoss_Old = ls.MaxLoss FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId

		UPDATE LimitLoss_Setting WITH(ROWLOCK,UPDLOCK) 
		SET MaxLoss = @MaxLoss
		WHERE CustID = @CustID
	END

	IF @Mode = 1
	BEGIN
		SELECT @GroupHeadlineID = groupID FROM bodb02.dbo.custAccount WITH (NOLOCK) WHERE custid = @CustID AND IsGroupHeadLine = 1

		IF @CustId <= 0
		   OR NOT EXISTS (SELECT 1 FROM dbo.LimitLoss_HeadlineSetting ls WITH (NOLOCK) WHERE ls.GroupHeadlineID = @GroupHeadlineID)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Headline.'
			RETURN
		END
		
		SELECT @MaxLoss_Old = ls.MaxLoss FROM dbo.LimitLoss_HeadlineSetting ls WITH (NOLOCK) WHERE ls.GroupHeadlineID = @GroupHeadlineID

		UPDATE LimitLoss_HeadlineSetting WITH(ROWLOCK,UPDLOCK) 
		SET MaxLoss = @MaxLoss
		WHERE GroupHeadlineID = @GroupHeadlineID
	END

    DECLARE @LogData NVARCHAR(4000), @LogData2 NVARCHAR(4000)

    SET @endRun = GETDATE()
    SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

    SELECT @LogData = '<NAP_LimitLoss_SMAMaxLossUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					    + 'MaxLoss="' + COALESCE(CAST(@MaxLoss_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
						+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
					    + 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					    + 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					    + 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
					    
    SELECT @LogData2 = '<NAP_LimitLoss_SMAMaxLossUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
					    + 'MaxLoss="' + COALESCE(CAST(@MaxLoss AS VARCHAR(20)), SPACE(1)) + '" ' 
						+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
					    + 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					    + 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					    + 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'					    

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @UserID,
			@CustID = @CustID,
			@ActionID = 667,
			@TrackingValue = @LogData,
			@TrackingValue2 = @LogData2,
			@Duration = @duration			
	END TRY
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @UserID,
			@CustID = @CustID,
			@ActionID = 667,
			@TrackingValue = @LogData,
			@TrackingValue2 = @LogData2,
			@Duration = @duration	
	END CATCH
END


