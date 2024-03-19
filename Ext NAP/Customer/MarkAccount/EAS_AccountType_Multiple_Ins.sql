/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_AccountType_Multiple_Ins]
	  @GroupName	VARCHAR(50)
	, @UserID		INT
	, @Usernames	NVARCHAR(MAX)	
	, @TypeID		TINYINT
	, @Remark		NVARCHAR(2000)=NULL
	, @ErrCode	INT=0				OUTPUT
	, @ErrMsg	NVARCHAR(200)=''	OUTPUT
	, @IP			VARCHAR(20)=''	
AS
/*
	Creator: 20230525@Tacy  
	Task : Mark account type.
	DB: DBCUST/CustDB

	Revisions:  
		- 20230525@Tacy: Ext NAP - Function for Headline to provide customer class based on their knowledge [Redmine:#188025]
	
	Param's Explanation:

	Example:	
*/		
BEGIN
    SET NOCOUNT ON

	DECLARE @CustID INT

	DECLARE @Err_Tbl TABLE(
		CustID INT, 
		Username VARCHAR(30),
		ErrCode INT DEFAULT 0,
		ErrMsg VARCHAR(500) DEFAULT '',
		Isfinished BIT DEFAULT 0
	)

	INSERT INTO @Err_Tbl (CustID, Username, ErrCode, ErrMsg)
	EXEC EAS_AccountType_Check @GroupName=@GroupName, @Usernames=@Usernames

	IF EXISTS (SELECT 1 FROM @Err_Tbl HAVING COUNT(1)>500)
	BEGIN
		SELECT  @ErrCode=99,
				@ErrMsg='The system supports up to 500 usernames at one time.'

		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM @Err_Tbl WHERE ErrCode<>0)
	BEGIN
		SELECT CustID, Username, ErrCode, ErrMsg
		FROM @Err_Tbl
		WHERE ErrCode<>0

		RETURN
	END
	
	WHILE (1=1)
	BEGIN
		SELECT TOP (1) @CustID= CustID
		FROM @Err_Tbl
		WHERE Isfinished = 0 
			AND CustID IS NOT NULL

		IF @@ROWCOUNT = 0 
			BREAK

		-- Mark account
		EXEC EAS_AccountType_Ins 
			  @UserID=@UserID
			, @CustID=@CustID
			, @TypeID=@TypeID
			, @Remark=@Remark
			, @ErrCode=@ErrCode OUTPUT
			, @ErrMsg=@ErrMsg OUTPUT
			, @IP=@IP	
		
		IF @ErrCode<>0
			BREAK

		UPDATE t
		SET t.Isfinished = 1
		FROM @Err_Tbl t
		WHERE custid = @CustID 
	END
END
GO