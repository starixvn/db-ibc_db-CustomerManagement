
/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet,Dot_Intg" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_GameRoundBetLimitSettingSel] @ProductId VARCHAR(200) = NULL
AS

/*
Created: Jacob	
Date: 2019-03-12
Task: #109866 - Implement Game Ground Bet Limit Control

DB: DBCUST/CustDB

Revisions:
20190312@Jacob: Implement Game Ground Bet Limit Control [#109866].


Example:
EXEC [NAP_GameRoundBetLimitSettingSel] @ProductId=0
*/

     SET NOCOUNT ON;
     DECLARE @Products TABLE(Id INT);
     INSERT INTO @Products
            SELECT CAST(val AS INT)
            FROM dbo.strSplit(@ProductId, ',');
     SELECT b.ProductId,
            b.SportType,
            b.BetType,
            b.GameRoundBetLimit
     FROM dbo.GameRoundBetLimitSettings b WITH (NOLOCK)
          INNER JOIN @Products p ON b.ProductId = p.Id;
GO
