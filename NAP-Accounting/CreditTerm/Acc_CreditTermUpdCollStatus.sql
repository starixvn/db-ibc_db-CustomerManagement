/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermUpdCollStatus] 
	@CustId 				INT,
	@UserId 				INT,	
	@IP						VARCHAR(15) = '',
	@Language				VARCHAR(2) = 'E',
	@Mode					TINYINT,
	@OldGroupId				INT,	
	@NewGroupId				INT,	
	@Old_IsGroupHeadline	BIT,	
	@New_IsGroupHeadline	BIT,	
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Louis
	Date: 2018-11-05
	Task: Credit Collection Summary
	DB: DBCust/CustDB

	Revisions:
		--20181105@Louis: Credit Collection Summary  [RedmineID: #98621]
	Parameter's explaination: 		
		• @Mode: 			1: Customer Not in any group then assign to groupId <> 0 and not check headline		=> reset status to 0
							2: Set headline from non-headline customer of group g1 <> 0 to group g2 <> 0		=> reset status of old headline to 0, customer has status of old headline
							3: Customer Is Direct in no group, Not headline then assign to groupId <> 0			=> reset status to 0 (function add to group)
*/
BEGIN
	SET NOCOUNT ON	 
	DECLARE @startRun DATETIME;
	DECLARE @endRun DATETIME;
	DECLARE @duration INT;
	SET @startRun = GETDATE();
	
	DECLARE @LogData NVARCHAR(4000);
	DECLARE @LogOldData NVARCHAR(4000);
	
	SET @ErrMsg = '';
	
	DECLARE @oldColl_Status TINYINT = NULL;
	SELECT @oldColl_Status = Coll_Status
	FROM CustDirectAccount WITH(NOLOCK)
	WHERE CustId = @CustId;		
	
	IF @Mode = 1 AND @NewGroupId <> 0 AND @oldColl_Status IS NOT NULL	
	BEGIN
		UPDATE CustDirectAccount WITH(ROWLOCK, UPDLOCK)
		SET Coll_Status = 0
		WHERE CustId = @CustId;
	
		SELECT @LogData = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@NewGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="' + COALESCE(CAST(@New_IsGroupHeadline AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](0) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';

		SELECT @LogOldData = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@OldGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="' + COALESCE(CAST(@Old_IsGroupHeadline AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](@oldColl_Status) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';
					
		SET @endRun = GETDATE();
		SET @duration  = DATEDIFF(MILLISECOND, @startRun, @endRun);

		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @Userid = @UserId
			, @CustId = @CustId
			, @ActionID = 1167
			, @TrackingValue = @LogData
			, @TrackingValue2 = @LogOldData
			, @Duration = @duration;		
	END
	ELSE IF @Mode = 2
	BEGIN
		DECLARE @CustId_Headline INT
		SELECT @CustId_Headline = CustID FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupID = @NewGroupId
	
		DECLARE @oldColl_StatusHeadline INT = NULL;
		SELECT @oldColl_StatusHeadline = Coll_Status FROM CustDirectAccount WITH (NOLOCK) WHERE CustId = @CustId_Headline
		
		IF @oldColl_StatusHeadline IS NULL
			SELECT @oldColl_StatusHeadline = 0
		 		
		UPDATE CustDirectAccount WITH(ROWLOCK, UPDLOCK)
		SET Coll_Status = @oldColl_StatusHeadline
		WHERE CustId = @CustId;		
		
		UPDATE CustDirectAccount WITH(ROWLOCK, UPDLOCK)
		SET Coll_Status = 0
		WHERE CustId = @CustId_Headline;		
		
		SELECT @LogData = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@NewGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="' + COALESCE(CAST(@New_IsGroupHeadline AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](@oldColl_StatusHeadline) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';
					
		SELECT @LogOldData = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@OldGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="' + COALESCE(CAST(@Old_IsGroupHeadline AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](@oldColl_Status) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';			 			 		
		 		
		DECLARE @LogDataHeadline NVARCHAR(4000);
		DECLARE @LogOldDataHeadline NVARCHAR(4000);		
		
		SELECT @LogDataHeadline = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId_Headline AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@NewGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="0" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](0) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';

		SELECT @LogOldDataHeadline = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId_Headline AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@NewGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="1" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](@oldColl_StatusHeadline) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';		
		
		SET @endRun = GETDATE();
		SET @duration  = DATEDIFF(MILLISECOND, @startRun, @endRun);

		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @Userid = @UserId
			, @CustId = @CustId_Headline
			, @ActionID = 1167
			, @TrackingValue = @LogDataHeadline
			, @TrackingValue2 = @LogOldDataHeadline
			, @Duration = @duration;
						
		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @Userid = @UserId
			, @CustId = @CustId
			, @ActionID = 1167
			, @TrackingValue = @LogData
			, @TrackingValue2 = @LogOldData
			, @Duration = @duration;	
	END
	ELSE IF @Mode = 3 AND @oldColl_Status IS NOT NULL	
	BEGIN		
		SELECT @OldGroupId = groupId FROM custaccount WITH (NOLOCK) WHERE custid = @custid AND isgroupheadline = 0		
		
		IF @OldGroupId IS NOT NULL AND @OldGroupId <> 0
			RETURN
			
		UPDATE CustDirectAccount WITH(ROWLOCK, UPDLOCK)
		SET Coll_Status = 0
		WHERE CustId = @CustId;
			
		SELECT @LogData = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@NewGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="' + COALESCE(CAST(@New_IsGroupHeadline AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](0) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';

		SELECT @LogOldData = '<Acc_CreditTermUpdCollStatus ' 
					+ 'CustId="' + COALESCE(CAST(@CustId AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'GroupID="' + COALESCE(CAST(@OldGroupId AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'IsGroupHeadline="' + COALESCE(CAST(@Old_IsGroupHeadline AS VARCHAR(50)), SPACE(1)) + '" '
					+ 'Coll_Status="' + [dbo].[f_CreditColl_GetStatusName](@oldColl_Status) + '" '
					+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
					+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)),SPACE(1)) + '" '
					+ 'ErrMsg="' + @ErrMsg + '" '
					+ '/>';
					
		SET @endRun = GETDATE();
		SET @duration  = DATEDIFF(MILLISECOND, @startRun, @endRun);

		EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @Userid = @UserId
			, @CustId = @CustId
			, @ActionID = 1167
			, @TrackingValue = @LogData
			, @TrackingValue2 = @LogOldData
			, @Duration = @duration;			
	END
					
END

GO




