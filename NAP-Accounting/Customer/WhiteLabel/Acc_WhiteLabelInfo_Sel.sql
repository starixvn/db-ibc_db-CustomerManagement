/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_WhiteLabelInfo_Sel
	-- Add the parameters for the stored procedure here
	 @WhiteLabel VARCHAR(16)=NULL
AS
/*
	Created: Tacy
	Task: NAP - Configure White Label rate
	DB: DBCUST-CUSTDB

	Revisions:
		- 20240827@Tacy: Create SP [Redmine: #209807]

*/
BEGIN 
	SET NOCOUNT ON;

	SELECT CustID, WhiteLabel
	FROM WhiteLabelInfo WITH (NOLOCK)
	WHERE ISNULL(@WhiteLabel,'')='' OR WhiteLabel=@WhiteLabel
	ORDER BY WhiteLabel
END
GO