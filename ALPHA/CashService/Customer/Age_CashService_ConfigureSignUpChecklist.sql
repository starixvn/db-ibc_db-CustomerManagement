/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Age_CashService_ConfigureSignUpChecklist]
    @AgentID INT
AS
/*
  Created: 20250619@Helios
  Task: Configure Sign Up Checklist
  DB: DBCUST-AgencyCashService
  
  Revisions:
    - 20250619@Helios: Initial SP [RedmineID: #230549]
    
*/
BEGIN
    SET NOCOUNT ON;

    /*****************************
    -- Input Parameters
    *****************************/
    DECLARE @HasDepositBank      BIT = 0;       -- Has bank account for deposit
    DECLARE @HasDepositPayment   BIT = 0;       -- Has payment provider for deposit
    DECLARE @HasWithdrawalBank   BIT = 0;       -- Has bank account for withdrawal
    DECLARE @HasWithdrawalPayment BIT = 0;      -- Has payment provider for withdrawal
    DECLARE @HasValidLineContact BIT = 0;       -- Has valid Line contact (not empty)

    /*****************************
    -- Check Bank Account Settings
    *****************************/
    /* TransTypeList values in CashAgentBankAccount:
       1 - Manual Deposit
       2 - Auto Deposit
       3 - Manual Withdraw
    */
    -- Check Deposit Bank Account
    IF EXISTS (
        SELECT TOP 1 1 
        FROM dbo.CashAgentBankAccount WITH (NOLOCK)
        WHERE AgentID = @AgentID 
            AND IsActive = 1
            AND (
                ',' + TransTypeList + ',' LIKE '%,1,%'  -- Manual Deposit
                OR ',' + TransTypeList + ',' LIKE '%,2,%'  -- Auto Deposit
            )
    )
    BEGIN
        SET @HasDepositBank = 1;
    END

    -- Check Withdrawal Bank Account
    IF EXISTS (
        SELECT TOP 1 1 
        FROM dbo.CashAgentBankAccount WITH (NOLOCK)
        WHERE AgentID = @AgentID 
            AND IsActive = 1
            AND ',' + TransTypeList + ',' LIKE '%,3,%'  -- Manual Withdraw
    )
    BEGIN
        SET @HasWithdrawalBank = 1;
    END

    /*****************************
    -- Check Payment Provider Settings
    *****************************/
    /* TransactionType in CashPaymentProviderAPIConfig:
       1 - Deposit
       2 - Withdraw
    */
    -- Check Deposit Payment Provider
    IF EXISTS (
        SELECT TOP 1 1 
        FROM dbo.CashPaymentProviderAPIConfig WITH (NOLOCK)
        WHERE AgentID = @AgentID 
            AND TransactionType = 1  -- Deposit
    )
    BEGIN
        SET @HasDepositPayment = 1;
    END

    -- Check Withdrawal Payment Provider
    IF EXISTS (
        SELECT TOP 1 1 
        FROM dbo.CashPaymentProviderAPIConfig WITH (NOLOCK)
        WHERE AgentID = @AgentID 
            AND TransactionType = 2  -- Withdraw
    )
    BEGIN
        SET @HasWithdrawalPayment = 1;
    END

    /*****************************
    -- Check Contact Settings
    *****************************/
    -- Step 1: Check if Agent exists and has valid Line contact
    IF EXISTS (
        SELECT TOP 1 1
        FROM dbo.CashAgentManagement WITH (NOLOCK)
        WHERE AgentID = @AgentID
        AND ISJSON(Contact) = 1
        AND EXISTS (
            SELECT 1
            FROM OPENJSON(Contact)
            WHERE JSON_VALUE(value, '$.type') = 'line'    -- Check if type property equals 'line' in JSON array element
                                                         -- Example: {"type":"line",...} -> returns 'line'
            AND LTRIM(RTRIM(JSON_VALUE(value, '$.value'))) <> ''  -- Check if value property is not empty after trimming spaces
                                                                 -- Example: {"type":"line","value":"  abc  "} -> returns 'abc' <> ''
        )
    )
    BEGIN
        SET @HasValidLineContact = 1;
    END

    -- Return results:
    SELECT 
        @AgentID AS CustID,
        CASE 
            WHEN @HasDepositBank = 1 OR @HasDepositPayment = 1 THEN 1
            ELSE 0
        END AS HasDeposit,
        CASE 
            WHEN @HasWithdrawalBank = 1 OR @HasWithdrawalPayment = 1 THEN 1
            ELSE 0
        END AS HasWithdrawal,
        @HasValidLineContact AS HasValidLineContact;
END;
