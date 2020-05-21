/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_SuperPrefixIns]
	@GroupName	VARCHAR(50),
	@Prefix		VARCHAR(10),
	@UserID 	INT,
	@IP VARCHAR(15) = '',
	@ErrCode 	INT = 0 OUTPUT,
	@ErrMsg 	NVARCHAR(200) = '' OUTPUT	
AS

/*
	Created: 20200511@Johnson	
	Task: add new prefix for external group
	DB: DBCUST-CUSTDB
	
	Revisions:
		- 20200511@Johnson: initial sp [redmine:#133846]
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @duration	INT
	
	SET @startRun = GETDATE()
	
	IF EXISTS (SELECT 1 FROM Acc_SuperPrefix WITH(NOLOCK) WHERE Prefix = @Prefix)
	BEGIN
		SELECT @ErrCode = 100,
			@ErrMsg= 'The input prefix exists already, please choose a new one.'
		RETURN	
	END
	
	IF EXISTS(SELECT 1
			FROM Acc_CustGroup cg WITH(NOLOCK)
				INNER JOIN customer c WITH(NOLOCK) ON cg.custid = c.custid
			WHERE cg.GroupName IN ('ACCUT','ACCYEN789','ACCYEN889','ACCTEST')	--789y
				AND cg.GroupName <> @GroupName
				AND LEFT(c.username,2) = @prefix
			)
	BEGIN
		SELECT @ErrCode = 101,
			@ErrMsg= 'The prefix is not available because it belongs to a super of another group.'
		RETURN
	END	
	
	INSERT INTO Acc_SuperPrefix(GroupName,Prefix,AllowNewSuper)
	SELECT @GroupName,@Prefix,1
	
	-- Write log data
	DECLARE @LogData NVARCHAR(1000)
	SET @LogData = '<Acc_SuperPefixIns GroupName="' + COALESCE(@GroupName,SPACE(1)) +'"'+
					' Prefix="' + COALESCE(@Prefix,SPACE(1)) + '"' +	 
					' IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" />'
	
	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)
	
	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper	@UserID = @UserID,	
		@ActionID = 95017,
		@TrackingValue = @LogData,
		@duration = @duration
END	