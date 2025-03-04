/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_SuperPrefixDel]
	@GroupName	VARCHAR(50),
	@Prefix		VARCHAR(10),
	@UserID 	INT,
	@IP VARCHAR(15) = '',
	@ErrCode 	INT = 0 OUTPUT,
	@ErrMsg 	NVARCHAR(200) = '' OUTPUT	
AS

/*
	Created: 20200511@Johnson	
	Task: remove prefix out of external group
	DB: DBCUST-CUSTDB
	
	Revisions:
		- 20200511@Johnson: initial sp [redmine:#133846]
		- 20241231@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @duration	INT
	
	SET @startRun = GETDATE()
	
	IF NOT EXISTS (SELECT 1 FROM Acc_SuperPrefix WITH(NOLOCK) 
					WHERE GroupName = @GroupName AND Prefix =@Prefix
				)
	RETURN;
	
	IF EXISTS(SELECT 1
			FROM Acc_CustGroup cg WITH(NOLOCK)
				INNER JOIN customer c WITH(NOLOCK) ON cg.custid = c.custid
			WHERE cg.GroupName = @GroupName
				AND LEFT(c.username,2) = @prefix
			)
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg= 'Super of this prefix exists already in the same external group, please rename the super(s) before doing the action.'
		RETURN
	END
	
	DELETE Acc_SuperPrefix WITH(UPDLOCK,ROWLOCK)
	OUTPUT DELETED.GroupName, DELETED.Prefix, dbo.f_GetDateTime2()
	INTO Acc_SuperPrefix_Del_Inhouse(GroupName,Prefix,RepUpdateTime)
	WHERE GroupName = @GroupName
		AND Prefix = @Prefix
		
	-- Write log data
	DECLARE @LogData NVARCHAR(1000)
	SET @LogData = '<Acc_SuperPrefixDel GroupName="' + COALESCE(@GroupName,SPACE(1)) +'"'+
					' Prefix="' + COALESCE(@Prefix,SPACE(1)) + '"' +	 
					' IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" />'
	
	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)
	
	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper	@UserID = @UserID,	
		@ActionID = 95018,
		@TrackingValue = @LogData,
		@duration = @duration	
END	