USE [bodb_Age]
GO

/****** Object:  StoredProcedure [dbo].[NAP_LimitLoss_SMADel]    Script Date: 06/08/2016 13:17:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Stored Procedure dbo.NAP_LimitLoss_MonitorList    Script Date: 6/27/2014 1:18:44 PM ******/
CREATE PROCEDURE [dbo].[NAP_LimitLoss_SMADel]
    @CustId	 INT,
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
    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@Creator,@funcname='[LossMonitor]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
    IF @ErrCode <> 0
	    RETURN

    IF @CustId <= 0
	   OR NOT EXISTS (SELECT 1 FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId)
    BEGIN
	    SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
	    RETURN
    END

    DECLARE @MaxLoss_Old MONEY
    SELECT @MaxLoss_Old = ls.MaxLoss FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId

    DELETE LimitLoss_Setting WITH(ROWLOCK,UPDLOCK) WHERE CustID=@CustID

    DECLARE @LogData NVARCHAR(4000)

    SET @endRun = GETDATE()
    SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

    SELECT @LogData = '<NAP_LimitLoss_SMADel CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					    + 'MaxLoss="' + COALESCE(CAST(@MaxLoss_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
					    + 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					    + 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					    + 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'

    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				    @Userid = @Creator,
				    @ActionID = 665,
				    @TrackingValue = @LogData,
				    @Duration = @duration

END

/*
GO
GRANT EXECUTE ON [dbo].[NAP_LimitLoss_SMADel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_LimitLoss_SMADel] TO [bodbAdminNet]
GO
*/

GO
GRANT EXECUTE ON [dbo].[NAP_LimitLoss_SMADel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_LimitLoss_SMADel] TO [bodbAdminNet]
GO




