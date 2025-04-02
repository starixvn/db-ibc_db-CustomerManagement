/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE API_LoginNotifyInfoSel
	@CustID			INT,
	@CustName		NVARCHAR(50)		OUTPUT,
	@UpLineID		INT					OUTPUT,
	@UpLineName		NVARCHAR(50)		OUTPUT,
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
		EXECUTE API_LoginNotifyInfoSel 
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
		@FailedCount = ISNULL(logincount,0),
		@UpLineID = CASE WHEN recommend = -4 THEN srecommend
						WHEN  recommend = -3 THEN mrecommend
						WHEN recommend NOT IN (-3, -4) THEN recommend END,
		@CustName = username
	FROM	dbo.customer WITH (NOLOCK)
	WHERE	custid = @CustID AND roleid = 1;

	SELECT	@UpLineName = username
	FROM	dbo.custinfo WITH (NOLOCK)
	WHERE	custid = @UpLineID;

END
