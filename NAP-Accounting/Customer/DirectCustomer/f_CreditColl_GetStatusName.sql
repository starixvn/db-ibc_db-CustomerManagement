/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_CreditColl_GetStatusName] 
(
	@Status		INT
)
RETURNS NVARCHAR(20)
AS
/*
	Created: Louis
	Date: 2018-11-05
	Task: Credit Collection Summary
	DB: DBCust/CustDB

	Revisions:
		--20181105@Louis: Credit Collection Summary  [RedmineID: #98621]
	Parameter's explaination: 		
		• @Status: 			0: Normal 
							1: Alert
							2: Unused
*/
BEGIN	
	DECLARE @StatusName NVARCHAR(20) = '';	
		
	IF @Status = 1
		SELECT @StatusName = 'Alert'
	ELSE IF @Status = 2
		SELECT @StatusName = 'Unused'
	ELSE IF @Status = 0
		SELECT @StatusName = 'Normal'; 	
	ELSE 
		SELECT @StatusName = ''; 	
	
    RETURN @StatusName
END;




