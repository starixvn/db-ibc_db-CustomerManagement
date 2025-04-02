/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Age_LoginGetInfo
	@CustID			INT,
	@CustName		NVARCHAR(50)		OUTPUT,
	@UpLineID		INT					OUTPUT,
	@UpLineName		NVARCHAR(50)		OUTPUT,
	@LastChangedPwdDate DATETIME = NULL OUTPUT,
	@FailedCount	INT = 0				OUTPUT
AS
/*
	Created: 20250401@Dave
	Task : Get info Login for API Login Process Amenment - Solution 3
	DB: DBCUST/CustDB

	Revisions:
		- 20250401@Dave: Login Process Amenment - Solution 3 - Output @UpLineID [RedmineID: #220522]

	Param's Explanation:
		@LastChangedPwdDate: If = NULL: Login current pass, <> NULL : Login old Pass 

		DECLARE 	@CustName	NVARCHAR(50)		,
			@UpLineID	INT					,
			@UpLineName	NVARCHAR(50)		,
			@LastChangedPwdDate DATETIME ,
			@failedcount INT;
		EXECUTE Age_LoginGetInfo 
			@CustID		= 48681637,
			@CustName	= @CustName OUTPUT,
			@UpLineID	= @UpLineID OUTPUT,
			@UpLineName	= @UpLineName OUTPUT,
			@LastChangedPwdDate = @LastChangedPwdDate OUTPUT,
			@failedcount = @failedcount OUTPUT
		SELECT @CustName, @UpLineID, @UpLineName, @LastChangedPwdDate, @failedcount;

*/
BEGIN
	SET NOCOUNT ON
	SELECT
		@UpLineID = CASE WHEN (roleid = 1 AND recommend = -4) OR roleid = 3 THEN srecommend
			WHEN (roleid = 1 AND recommend = -3) OR roleid = 2 THEN mrecommend
			WHEN roleid = 1 AND recommend NOT IN (-3, -4) THEN recommend END,
		@CustName = username
	FROM	dbo.custinfo WITH (NOLOCK) 
	WHERE	custid = @CustID;

	SELECT	@UpLineName = username
	FROM	dbo.custinfo WITH (NOLOCK)
	WHERE	custid = @UpLineID;

	SELECT	@LastChangedPwdDate	= LastChangedPwdDate
	FROM	dbo.CustLoginInfo WITH (NOLOCK)
	WHERE	CustID = @CustID;

	SELECT	@FailedCount = ISNULL(logincount,0)
	FROM	dbo.customer
	WHERE	custid = @CustID;

END