/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CheckExpiredDate_Admin]
	@UserID INT,
	@IsExpired BIT = 0 OUTPUT
AS
/*
	Created: 20240725@Tacy
	Task: Check ExpiredDate's Admin
	Database: DBPOL/NAP_UserControl
	
	Revisions:
		- 20240725@Tacy: Create SP [RedmineId: #208402]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM DBCUST.NAP_UserControl.dbo.AccCustomer WITH (NOLOCK) 
				WHERE custid=@UserID AND ExpiredDate<GETDATE())
	BEGIN
		SELECT @IsExpired=1
	END
END
GO