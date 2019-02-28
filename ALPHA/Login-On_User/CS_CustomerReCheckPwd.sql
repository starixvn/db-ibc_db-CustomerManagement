/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_CustomerReCheckPwd]
	@CustID INT = 0,
    @UserPwd VARCHAR(50),
	@subAccID INT = 0,
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
	
AS
/*
	Created: 20190228@Johnson
	Task : recheck pwd before using old report
	DB: DBCUST/CUSTDB
	Original:  

	Revisions:
		- 20190228@Johnson: intial sp [redmine: #105660]
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @SubAccID > 0
	BEGIN
		SELECT TOP 1 1
		FROM custSub WITH (NOLOCK)
		WHERE subaccid = @SubAccID and userpwd = @UserPwd
		
		IF @@ROWCOUNT = 0  
		BEGIN			
			SELECT @ErrMsg = N'Login Failed.',@ErrCode=100   
			RETURN		
		END
	END
	ELSE
	BEGIN 
		SELECT TOP 1 1
		FROM customer c WITH (NOLOCK) 
		WHERE CustID = @CustID AND userpwd = @userpwd
		
		IF @@ROWCOUNT = 0  
		BEGIN			
			SELECT @ErrMsg = N'Login Failed.',@ErrCode=101   
			RETURN		
		END
	END
END    

