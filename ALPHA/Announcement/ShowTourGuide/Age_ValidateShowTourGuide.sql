/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp, wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ValidateShowTourGuide]  
	@CustID INT,			-- SMA_ID Input
      @IsShow BIT = 0 OUTPUT
AS 
BEGIN 
/*  
	Created By: Helios
	Created Date: 2025-03-21
	Description: Alpha - Credit Reward - Show tour guide for selected SMA [Redmine #221208]
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Alpha - Credit Reward - Show tour guide for selected SMA [Redmine: #221208] 

	Param:
		@IsShow = 0 : Don't Show Tour Guide
		@IsShow = 1 : Show Tour Guide

	DECLARE 	@IsShow BIT;
	EXEC Age_ValidateShowTourGuide @CustID = 187899101
					 , @IsShow = @IsShow OUTPUT;
	SELECT
		@IsShow AS IsShowResult;
*/  
 SET NOCOUNT ON;

    DECLARE @RoleID TINYINT
    , @Get_Date DATE

    SET @IsShow = 0
    SET @Get_Date = CAST(GETDATE() AS DATE)

    SELECT @RoleID = (SELECT RoleID FROM  Customer WITH (NOLOCK) WHERE custid = @CustID)

    IF @RoleID = 4
    BEGIN
	    IF EXISTS (
		  SELECT TOP 1 1
		  FROM custInfo  c WITH (NOLOCK)
		  INNER JOIN Age_CreditRewardCustomers cr WITH (NOLOCK) ON c.custid = cr.custID
		  WHERE c.srecommend = @CustID
		  AND c.roleid = 1
		  AND @Get_Date BETWEEN cr.FromDate AND cr.ToDate
		  )

	    BEGIN
			SET @IsShow = 1;
	    END
    END

    ELSE IF @RoleID = 3
    BEGIN
	    IF EXISTS (
		  SELECT TOP 1 1
		  FROM custInfo  c WITH (NOLOCK)
		  INNER JOIN Age_CreditRewardCustomers cr WITH (NOLOCK) ON c.custid = cr.custID
		  WHERE c.mrecommend = @CustID
		  AND c.roleid = 1
		  AND @Get_Date BETWEEN cr.FromDate AND cr.ToDate
		  )

	    BEGIN
			SET @IsShow = 1;
	    END
    END
    ELSE IF @RoleID = 2
    BEGIN
	    IF EXISTS (
			  SELECT TOP 1 1
			  FROM custInfo  c WITH (NOLOCK)
			  INNER JOIN Age_CreditRewardCustomers cr WITH (NOLOCK) ON c.custid = cr.custID
			  WHERE c.recommend = @CustID
			  AND c.roleid = 1
			  AND @Get_Date BETWEEN cr.FromDate AND cr.ToDate
		  )

	    BEGIN
			SET @IsShow = 1;
	    END
    END

END
GO
