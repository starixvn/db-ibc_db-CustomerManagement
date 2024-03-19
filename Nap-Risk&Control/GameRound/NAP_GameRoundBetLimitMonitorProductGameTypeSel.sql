
/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE NAP_GameRoundBetLimitMonitorProductGameTypeSel
AS  
 
/*
Created: Robert	
Date: 2021-03-15
Task: #151686 - Implement Game Ground - Select Product & Game Type

DB: DBACC/bodb02

Revisions:
20210315@Robert: #151686 - Implement Game Ground - Select Product & Game Type
*/

    BEGIN
        SELECT 
               g.ProductID, 
               p.ProductName, 
               g.BetType, 
               b.typenamee as BetTypeName
        FROM dbo.GameRoundBetLimitSettings g WITH(NOLOCK)
             INNER JOIN dbo.Products p WITH(NOLOCK) ON g.ProductID = p.ProductID
             INNER JOIN dbo.bettype b WITH(NOLOCK) ON g.BetType = b.typeid
        ORDER BY 
                 p.ProductName, 
                 b.typenamee;

    END;
GO