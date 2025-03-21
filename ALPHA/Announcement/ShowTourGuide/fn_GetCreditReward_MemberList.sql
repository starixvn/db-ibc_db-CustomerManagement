/*<info serverAlias="DBCUST-CUSTDB" selecters="wsv_alp, wsv_alpv" viewers="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION fn_GetCreditReward_MemberList (@CustID INT)
RETURNS @ListCust TABLE (
    CustID INT,
    FromDate DATE,
    ToDate DATE
)
AS
/*
	Created By: Helios
	Created Date: 2025-03-21
	Description: Alpha - Credit Reward - Show tour guide for selected SMA [Redmine #221208]
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Alpha - Credit Reward - Show tour guide for selected SMA [Redmine: #221208]
*/
BEGIN
    -- Insert hardcoded values into the table variable
    INSERT INTO @ListCust (CustID, FromDate, ToDate)
    VALUES 
	  (46755897, '2025-03-28', '2030-03-28'),
	  (23052753, '2025-03-01', '2025-03-27'),
	  (81024799, '2025-03-01', '2025-03-28'),
	  (92501690, '2025-03-29', '9999-12-30');

    -- Filter rows based on @CustID and GETDATE()
    DELETE FROM @ListCust
    WHERE CustID <> @CustID OR CAST(GETDATE() AS DATE) NOT BETWEEN FromDate AND ToDate;

    RETURN;
END;
GO