/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_AGE]
GO

ALTER PROCEDURE [dbo].[NAP_LimitLoss_SMAIns]
    @Username	NVARCHAR(50),
    @MaxLoss	MONEY,
	@Mode		BIT = 0,
    @UserID		INT = 0,
    @IP			NVARCHAR(50) = NULL,
    @System		BIT = 0,

    @ErrCode	INT = 0 OUT,
    @ErrMsg		NVARCHAR(200) = '' OUT

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
		- System =  0: insert from Nap-CM system (write log in this SP)
					1: insert from Nap accounting system (write log in Acc_CustDirectUpd SP)

	Example:
	
*/

BEGIN
    SET NOCOUNT ON

    DECLARE	@startRun DATETIME, @endRun	DATETIME, @duration	INT
	DECLARE @CustID INT, @roleid INT, @GroupHeadlineID SMALLINT

    SET	@startRun = GETDATE()

    --Check permission 
	IF @System = 0
	BEGIN
		EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[LossMonitor]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
		IF @ErrCode <> 0
			RETURN
	END
	   
    IF @MaxLoss >= 0
    BEGIN
	   SELECT @ErrCode = 101, @ErrMsg = 'Max Loss should be negative!'
	   RETURN
    END	    
	        
    SELECT @CustID = ci.CustID,@roleid=ci.RoleID FROM bodb02.dbo.CustInfo ci WITH(NOLOCK) WHERE ci.UserName = @UserName

	--Insert SMA setting
	IF @Mode = 0
	BEGIN
		IF @CustID IS NULL OR @roleid NOT IN (2, 3, 4)
		BEGIN
		   SELECT @ErrCode = 102, @ErrMsg = 'Invalid Super/Master/Agent.'
		   RETURN
		END    

		IF EXISTS (SELECT 1 FROM dbo.LimitLoss_Setting ls WITH (NOLOCK) WHERE ls.CustId = @CustId AND ls.MaxLoss IS NOT NULL)
		BEGIN
			SELECT @ErrCode = 103, @ErrMsg = 'This customer already existed!'
			RETURN
		END

		UPDATE ls 
		SET ls.MaxLoss = @MaxLoss
		FROM LimitLoss_Setting ls WITH (ROWLOCK,UPDLOCK)
		WHERE ls.CustID = @CustID

		IF @@ROWCOUNT = 0
			INSERT INTO LimitLoss_Setting(CustID, MaxLoss) VALUES(@CustID, @MaxLoss)
	END
    
	--Insert Headline setting
	IF @Mode = 1
	BEGIN
		SELECT @GroupHeadlineID = groupID FROM bodb02.dbo.custAccount WITH (NOLOCK) WHERE custid = @CustID AND IsGroupHeadLine = 1

		IF @CustID IS NULL OR @roleid NOT IN (1, 2, 3, 4) OR @GroupHeadlineID IS NULL
		BEGIN
		   SELECT @ErrCode = 104, @ErrMsg = 'Invalid Headline.'
		   RETURN
		END  

		IF EXISTS (SELECT 1 FROM dbo.LimitLoss_HeadlineSetting ls WITH (NOLOCK) WHERE ls.GroupHeadlineID = @GroupHeadlineID)
		BEGIN
			SELECT @ErrCode = 105, @ErrMsg = 'This headline already existed!'
			RETURN
		END
		
		INSERT INTO LimitLoss_HeadlineSetting(GroupHeadlineID, MaxLoss) VALUES(@GroupHeadlineID, @MaxLoss)

		INSERT INTO LimitLoss_Setting(CustID, MaxLoss) 
		SELECT ca.custid, NULL
		FROM bodb02.dbo.custAccount ca WITH (NOLOCK)
		WHERE groupID = @GroupHeadlineID
			AND NOT EXISTS (SELECT 1 FROM dbo.LimitLoss_Setting WITH (NOLOCK) WHERE custid = ca.custid)
	END
    
	IF @System = 0
	BEGIN
		DECLARE @LogData NVARCHAR(4000)

		SET @endRun = GETDATE()
		SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

		IF @Mode = 0
		BEGIN
			SELECT @LogData = '<NAP_LimitLoss_SMAIns Username="' + COALESCE(CAST(@Username AS VARCHAR(10)), SPACE(1)) + '" ' 					
								+ 'MaxLoss="' + COALESCE(CAST(@MaxLoss AS VARCHAR(20)), SPACE(1)) + '" ' 
								+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
								+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
								+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
								+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
		END
		ELSE 
		BEGIN
			SELECT @LogData = '<NAP_LimitLoss_SMAIns Username="' + COALESCE(CAST(@Username AS VARCHAR(10)), SPACE(1)) + '" ' 					
								+ 'MaxLossHeadline="' + COALESCE(CAST(@MaxLoss AS VARCHAR(20)), SPACE(1)) + '" ' 
								+ 'Mode="' + COALESCE(CAST(@Mode AS VARCHAR(1)), SPACE(1)) + '" ' 
								+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
								+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
								+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
		END
		
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@CustID = @CustID,
				@ActionID = 666,
				@TrackingValue = @LogData,
				@Duration = @duration			
		END TRY
		BEGIN CATCH
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@CustID = @CustID,
				@ActionID = 666,
				@TrackingValue = @LogData,
				@Duration = @duration	
		END CATCH
	END
END



