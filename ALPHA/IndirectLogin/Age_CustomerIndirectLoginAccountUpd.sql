/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerIndirectLoginAccountUpd]
	@custid 	INT,
	@SubAccID 	INT = 0,
	@CustIDIndirect INT,
	@SubAccIDIndirect INT = 0,	
	@UplineUsername VARCHAR(30),
	@DownlineUsername VARCHAR(30),
	@IP 		VARCHAR(15)= '',	
	@Language	VARCHAR(3) = 'E',
	@ErrCode  	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20200527@Johnson
	Task : update LastVerifyPwd for indirect login account
	DB: DBCUST/CustDB

	Revisions:
		- 20200527@Johnson: initial sp [redmine:#133846]
	
	Parameter's explaination:
		
*/		
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Begin DATETIME, 			
			@Duration INT			
	
	SET @Begin = GETDATE() 

	IF NOT EXISTS (SELECT 1 FROM CustInDirectLogin WITH(NOLOCK)
					WHERE custid = @custid
						AND SubAccID = @subAccID
						AND CustIDIndirect = @CustIDIndirect
						AND SubAccIDIndirect = @SubAccIDIndirect
				)
	RETURN
	
	UPDATE CustInDirectLogin WITH(UPDLOCK,ROWLOCK)
	SET LastVerifyPwd = GETDATE()
	WHERE custid = @custid
		AND SubAccID = @subAccID
		AND CustIDIndirect = @CustIDIndirect
		AND SubAccIDIndirect = @SubAccIDIndirect
	
	DECLARE @LogSPData VARCHAR(4000)
	
	-- Write log
	SELECT @LogSPData = '<R '
						+CASE WHEN @SubAccID > 0 THEN 'UplineSubAccount="'  + @UplineUserName +'" ' ELSE '' END 
						+'Account="'  + @DownlineUsername +'" ' 
						+'IP="'+ @IP + '" />'						

	SELECT @Duration = DATEDIFF (MILLISECOND, @Begin, GETDATE())
			
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @custid,
		@CustId				= @CustIDIndirect,
		@ActionId			= 95022,
		@TrackingValue		= @LogSPData,		
		@Duration			= @Duration	
END	