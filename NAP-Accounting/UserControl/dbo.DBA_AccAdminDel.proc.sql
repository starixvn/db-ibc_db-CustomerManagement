ALTER PROCEDURE [dbo].[DBA_AccAdminDel]
	@InputUser varchar(30),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
	/*
		Created: @DBA
		DB: DBTXN/bodb02
		Task: remove admin out system
		
		Revisions:
			- 20120718@Johnson: - change table AccCustomer to AccCustomer_1
								- check for removing out RMS system
			- 20130118@Elodie: Change link server DB03 to DBPOLICY and DB053 to DBRMS								
	*/
SET NOCOUNT ON

Declare @Custid int
if isnumeric(@InputUser) = 0
BEGIN
	select @custid = custid from customer with (nolock) where username = @InputUser
END
else
BEGIN
	select @custid = custid from customer with (nolock) where custid = @InputUser
END

IF ISNULL(@CustID,0) = 0
BEGIN 
	SELECT @ErrMsg = N'This admin does not exist!', @ErrCode = 100
	RETURN 
 
END


--IF Exists(Select 1 From customer c with(nolock) inner join 
--			db03.bodb02.dbo.AccCustomer_1 ac with(nolock) on c.custid=ac.custid
--			where c.custid=@custid and roleid  <>6 )
--BEGIN
--	select @ErrMsg = N'You can not delete this admin!', @ErrCode = 102
--	RETURN
--END

EXEC DBPOLICY.bodb02.dbo.DBA_AccAdminPolicyDel @Custid=@Custid,@Errcode=@Errcode output,@Errmsg=@Errmsg output
IF @Errcode <> 0 
	Return

EXEC DBRMS.bodb_RMS.dbo.DBA_AccAdminPolicyDel_RMS @Custid=@Custid,@Errcode=@Errcode output,@Errmsg=@Errmsg output
IF @Errcode <> 0 
	Return

BEGIN TRANSACTION
	DELETE FROM dbo.CustInfo WITH(ROWLOCK) WHERE Custid = @Custid
	DELETE FROM dbo.Customer WITH(ROWLOCK) WHERE Custid = @Custid
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = N'Delete Admin failed.', @ErrCode = 102
		RETURN
	END

COMMIT TRANSACTION 	

GO
GRANT VIEW DEFINITION ON  [dbo].[DBA_AccAdminDel] TO [vnteam]