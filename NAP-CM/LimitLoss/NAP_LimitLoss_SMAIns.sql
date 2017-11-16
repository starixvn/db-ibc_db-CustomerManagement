/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitLoss_SMAIns]
    @Username	 NVARCHAR(50),
    @MaxLoss	 MONEY,
    @Creator	 INT = 0,
    @IP		 NVARCHAR(50) = NULL,
    
    @ErrCode	 INT = 0 OUT,
    @ErrMsg	 NVARCHAR(200) = '' OUT

AS
/*
	Created: Aaron
	Date: 20160608
	Task : SMA Loss monitor report
	DB: DBAGE/bodb_Age

	Revisions:
			 - 20171115@Vicky: change location check permission [RedmineID: #86455]
			 
	Parameter's explaination: 
	
	Example:
	
*/

BEGIN
    SET NOCOUNT ON

    DECLARE	 @startRun	DATETIME,
			 @endRun		DATETIME,
			 @duration	INT
    SET		 @startRun = GETDATE()

    --Check permission 
    EXEC DBNAP.bodb_NAP.dbo.NAP_User_CheckPermission @UserId=@Creator,@SiteKey='CustomerManagement',@FunctionKey='LossMonitor',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
    IF @ErrCode <> 0
	    RETURN
	    
    IF @MaxLoss > 0
    BEGIN
	   SELECT @ErrCode = 101, @ErrMsg = 'Max Loss should be negative!'
	   RETURN
    END	    
	    
    DECLARE @CustID INT, @roleid INT
    SELECT @CustID = ci.CustID,@roleid=ci.RoleID FROM bodb02.dbo.CustInfo ci WITH(NOLOCK) WHERE ci.UserName = @UserName

    IF @CustID IS NULL OR @roleid NOT IN (2, 3, 4)
    BEGIN
	   SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
	   RETURN
    END    

    IF EXISTS (SELECT 1 FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId)
    BEGIN
	    SELECT @ErrCode = 101, @ErrMsg = 'This customer already existed!'
	    RETURN
    END

    INSERT INTO LimitLoss_Setting(CustID, MaxLoss) VALUES(@CustID, @MaxLoss)

    DECLARE @LogData NVARCHAR(4000)

    SET @endRun = GETDATE()
    SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

    SELECT @LogData = '<NAP_LimitLoss_SMAIns Username="' + COALESCE(CAST(@Username AS VARCHAR(10)), SPACE(1)) + '" ' 					
					    + 'MaxLoss="' + COALESCE(CAST(@MaxLoss AS VARCHAR(20)), SPACE(1)) + '" ' 
					    + 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					    + 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					    + 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'

    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				    @Userid = @Creator,
				    @ActionID = 666,
				    @TrackingValue = @LogData,
				    @Duration = @duration

END
GO

