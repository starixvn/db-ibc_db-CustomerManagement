/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Acc_CustGroupAddByUsername_Multiple]
	@GroupName	VARCHAR(MAX),
	@Username	VARCHAR(MAX),
	@UserID		INT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created by: [Kan]
	Date: 2018-04-09
	Task: Insert multiple super(s) to External AccSite Group
	DB: DBAGE/bodb_AGE 
	
	Revisions:
		- 20180409@Kan: Insert multiple supers to Group [RedmineID: #77733]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TempErrMsg NVARCHAR(1000)
	
	-- Check permission for account site
	EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission
		@custid = @UserID,
		@funcname ='[Admin_ManageExAcc]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @TempErrMsg OUTPUT,
		@System = 'ACCOUNTING'
	
	IF @ErrCode <> 0
	BEGIN
		SET @ErrMsg = @TempErrMsg
		RETURN
	END

	DECLARE @TempGroupSuper TABLE(Id INT IDENTITY(1,1), GroupName VARCHAR(50), SuperName VARCHAR(50))
	DECLARE @Id INT, @Group VARCHAR(50), @Super VARCHAR(50)
	DECLARE @TempErrCode INT
	SET @ErrMsg = '<ROOT>';

	INSERT INTO @TempGroupSuper(GroupName, SuperName)
	SELECT DISTINCT LTRIM(RTRIM(g.val)), LTRIM(RTRIM(s.val))
    FROM dbo.strSplit(@GroupName,',') g
    CROSS JOIN dbo.strSplit(@Username,',') s

	WHILE (SELECT COUNT(1) FROM @TempGroupSuper) > 0
	BEGIN
		SELECT TOP 1 @Id = Id, @Group = GroupName, @Super = SuperName FROM @TempGroupSuper
		SELECT @TempErrCode = NULL, @TempErrMsg = NULL

		EXEC dbo.Acc_CustGroupAddByUsername
			@Username = @Super,
			@GroupName = @Group,
			@ErrCode = @TempErrCode OUTPUT,
			@ErrMsg = @TempErrMsg OUTPUT,
			@UserID = @UserID

		SET @ErrMsg += '<Result GroupName="' + @Group
			+ '" SuperName="' + @Super
			+ '" ErrCode="' + CAST(ISNULL(@TempErrCode,'0') AS VARCHAR(5))
			+ '" ErrMsg="' + ISNULL(@TempErrMsg,'') + '" />'

		DELETE @TempGroupSuper WHERE Id = @Id
	END

	SET @ErrMsg += '</ROOT>'
END
GO
