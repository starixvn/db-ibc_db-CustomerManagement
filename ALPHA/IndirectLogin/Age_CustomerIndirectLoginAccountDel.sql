/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerIndirectLoginAccountDel]
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
	Created: 20200526@Johnson
	Task : disconnect indirect login account by upline
	DB: DBCUST/CustDB

	Revisions:
		- 20200526@Johnson: initial sp [redmine:#133846]
		- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
	
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
	BEGIN
		SELECT @ErrMsg = CASE @Language 
				WHEN 'E' THEN 'Invalid account or it is not your downline.'
				ELSE [dbo].[f_Get_MsgNamebyMsgID](40052,@Language)
			END	,@ErrCode=101		
		RETURN	
	END

	DELETE CustInDirectLogin WITH(UPDLOCK,ROWLOCK)
	OUTPUT DELETED.custid,DELETED.SubAccID,DELETED.CustIDIndirect,DELETED.SubAccIDIndirect, dbo.f_GetDateTime2()
	INTO CustInDirectLogin_Del_Inhouse(custid,SubAccID,CustIDIndirect,SubAccIDIndirect,RepUpdateTime)
	WHERE custid = @custid
		AND SubAccID = @subAccID
		AND CustIDIndirect = @CustIDIndirect
		AND SubAccIDIndirect = @SubAccIDIndirect

	
	DECLARE @LogSPData VARCHAR(4000)
	
	-- Write log
	SELECT @LogSPData = '<R '
						+CASE WHEN @SubAccID > 0 THEN 'UplineSubAccount="'  + COALESCE(@UplineUserName,SPACE(1)) +'" ' ELSE '' END 
						+'Account="'  + COALESCE(@DownlineUsername,SPACE(1)) +'" ' 
						+'IP="'+ COALESCE(@IP,SPACE(1)) + '" />'						

	SELECT @Duration = DATEDIFF (MILLISECOND, @Begin, GETDATE())
			
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @custid,
		@CustId				= @CustIDIndirect,
		@ActionId			= 95020,
		@TrackingValue		= @LogSPData,		
		@Duration			= @Duration	
END			