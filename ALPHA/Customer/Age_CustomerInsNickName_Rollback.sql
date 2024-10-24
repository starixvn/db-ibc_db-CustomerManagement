/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap,wsv_alp,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerInsNickName_Rollback]
(
	 @custid	INT = 0
	 ,@SubAccID	INT = 0 -- for sub account
)
AS
/*
	Created: 20240704@Louisa
	Task : rollback nick name
	DB: DBCUST/CustDB

	Revision:
		- 20240704@Louisa: Scaleout DBCUST [Redmine:#199915]
		
*/	
BEGIN
	SET NOCOUNT ON
	
	IF @SubAccID <> 0
	BEGIN
		UPDATE [dbo].CustSubMini WITH (ROWLOCK)  
			SET Username2 = NULL , RepUpdateTime = SYSDATETIME()  
		WHERE subaccid = @subaccid AND CustID = @custid 
	END
	ELSE
	BEGIN
		UPDATE [dbo].CustInfoMini WITH (ROWLOCK)  
		SET Username2 = NULL ,RepUpdateTime = SYSDATETIME()  
		WHERE CustID = @custid
	END
END
GO

