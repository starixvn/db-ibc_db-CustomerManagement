/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
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
	DB: DBCUST/CUSTDB 
	
	Revisions:
		- 20180409@Kan: Insert multiple supers to Group [RedmineID: #77733]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20240816@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TempErrMsg NVARCHAR(1000)

	DECLARE @TempGroupSuper TABLE(Id INT IDENTITY(1,1), GroupName VARCHAR(50), SuperName VARCHAR(50))
	DECLARE @Id INT, @Group VARCHAR(50), @Super VARCHAR(50)
	DECLARE @TempErrCode INT
	SET @ErrMsg = '<ROOT>';

	INSERT INTO @TempGroupSuper(GroupName, SuperName)
	SELECT DISTINCT LTRIM(RTRIM(g.value)), LTRIM(RTRIM(s.value))
    FROM STRING_SPLIT(@GroupName,',') g
		CROSS JOIN STRING_SPLIT(@Username,',') s

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
