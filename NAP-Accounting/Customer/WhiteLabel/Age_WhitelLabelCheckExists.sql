/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_WhitelLabelCheckExists]  
	@CustID INT,
	@IsExists BIT=0 OUTPUT
AS  
/*  
	Creator: 20241001@Tacy  
	Task : Check exists Whitelabel.
	DB: DBAGE/bodb02

	Revisions:  
		- 20241001@Tacy: Create SP [Redmine: #209807]
	
	Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON;

	DECLARE @today DATETIME
	
	SELECT  @today = CONVERT(DATE, GETDATE())

	SELECT @IsExists=1
	FROM WhiteLabelInfo wi WITH (NOLOCK)
	CROSS APPLY (SELECT TOP 1 1 AS val
				 FROM WhiteLabelSetting wls WITH (NOLOCK)
				 WHERE wi.CustID=wls.CustID
				 AND wls.ToDate > @today) wls
	WHERE wi.CustID=@CustID

	SELECT @IsExists = ISNULL(@IsExists,0)
END
GO