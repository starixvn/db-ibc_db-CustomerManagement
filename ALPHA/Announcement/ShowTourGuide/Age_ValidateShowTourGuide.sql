/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp, wsv_alpv" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Age_ValidateShowTourGuide]  
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

    -- Check SMA_ID input validate show tour guide or not 
    IF EXISTS (
        SELECT 1
        FROM custInfo  c WITH (NOLOCK)
        WHERE ((c.srecommend = @CustID) OR (c.mrecommend = @CustID) OR (c.recommend = @CustID))
	  AND c.roleid = 1
	  AND EXISTS (
              SELECT 1
              FROM dbo.fn_GetCreditReward_MemberList(c.CustID) h
          )
    )
    BEGIN
        SET @IsShow = 1;
    END
    ELSE
    BEGIN
        SET @IsShow = 0;
    END
END
GO
