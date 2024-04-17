/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_alp,bodbExtAccNet,wsv_xnap,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CheckQRFirstLogin]
	@CustID INT 
/*
Created: 20200309@Eden
Task :  Check to show function Alpha --> Fist Login QR Code
DB: DBCUST/CustDB
Original:  
Revisions:
    - 20200309@Eden: Alpha - New function to let new member sign in via QR Code [RM#129373]
*/

AS
BEGIN
	DECLARE @IsShowQRMenu BIT = 0

	IF NOT EXISTS(	SELECT TOP  1 1 FROM [dbo].[CustQRCode] WITH(NOLOCK) WHERE CustID = @CustID )
	BEGIN
		SELECT @IsShowQRMenu AS IsShowQRMenu
		RETURN
	END

	IF EXISTS(	SELECT TOP 1 1 FROM Customer WITH(NOLOCK) WHERE CustID = @CustID AND lastlogged IS NOT NULL)
	BEGIN
		SELECT @IsShowQRMenu AS IsShowQRMenu
		RETURN
	END

	SET @IsShowQRMenu = 1
	SELECT @IsShowQRMenu AS IsShowQRMenu
 
END
GO