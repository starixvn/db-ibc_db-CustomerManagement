
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustMarkDirectCheckEnable    Script Date: 10/9/2014 4:58:02 PM ******/
CREATE PROCEDURE [dbo].[Acc_CustMarkDirectCheckEnable]
    @custid	    INT
  , @roleid	    INT
  , @ErrCode	INT = 0 OUTPUT
  , @ErrMsg	    NVARCHAR(200) = '' OUTPUT 	
AS
/*
	Created: 
	Task : Checking the availability of marking an account as Direct Account
	DB: DBACC/bodb02
	Original: 

	Revisions:		
		- 20140522@Logan: Initial version.

Param's Explanation:	
• @ErrCode:
    = 0:  This account can be updated to direct.
    > 0:  Specific Error.
  
• @ErrMsg: Error description.
		
*/
BEGIN
    SET NOCOUNT ON
    
    DECLARE @isOK BIT

    SELECT @ErrCode = 0
         , @ErrMsg = ''
    
    --Super Account
    IF @roleid = 4
    BEGIN
	    SELECT @ErrMsg = 'This is a super account!'
	         , @ErrCode = 10
	    RETURN
    END

    --Invalid user
    IF @custid = 0
    BEGIN
	    SELECT @ErrMsg = 'Invalid user!'
	         , @ErrCode = 11
	    RETURN
    END

    --Deposit Account
    SELECT @isOK = 1
      FROM dbo.Dep_CustSuper a WITH(NOLOCK)
INNER JOIN dbo.Customer b WITH(NOLOCK) on a.custid = b.srecommend
     WHERE 1 = 1
       AND b.custid = @custid
       
    IF @@ROWCOUNT <> 0
    BEGIN
	    SELECT @ErrMsg = 'This is a Deposit Account!'
	         , @ErrCode = 12
	    RETURN
    END

    --Disable Account
    SELECT @isOK = 1
      FROM dbo.custInfo WITH(NOLOCK)
     WHERE custid = @custid
       AND Enabled = 0
     
    IF @@ROWCOUNT <> 0
    BEGIN
        SELECT @ErrMsg = 'This is a Disable Account!'
             , @ErrCode = 13
	    RETURN
    END

    --Internal Account
    IF @roleid = 1
    BEGIN
        SELECT @isOK = 1
          FROM dbo.CustAgent WITH(NOLOCK)
         WHERE custid = (SELECT recommend
                           FROM dbo.custInfo WITH(NOLOCK)
                          WHERE custid = @custid)
           AND IsInternal = 1

        IF @@ROWCOUNT <> 0
        BEGIN
            SELECT @ErrMsg = 'This is an Internal Account!',
	               @ErrCode = 14
	        RETURN
        END
    END

    IF @roleid = 2
    BEGIN
        SELECT @isOK = 1
          FROM dbo.CustAgent WITH(NOLOCK)
         WHERE custid = @custid
           AND IsInternal = 1

        IF @@ROWCOUNT <> 0
        BEGIN
            SELECT @ErrMsg = 'This is an Internal Account!',
	               @ErrCode = 14
	        RETURN
        END
    END

    IF @roleid = 3
    BEGIN
        SELECT @isOK = 1
          FROM dbo.CustMaster WITH(NOLOCK)
         WHERE custid = @custid
           AND IsInternal = 1
           
        IF @@ROWCOUNT <> 0
        BEGIN
            SELECT @ErrMsg = 'This is an Internal Account!',
	               @ErrCode = 15
	        RETURN
        END
    END

    --Upline Direct Account
    --SELECT @isOK = 1
    --  FROM dbo.Customer c WITH(NOLOCK)
    -- WHERE c.custid = @custid
    --   AND ((EXISTS (SELECT 1
    --                   FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
    --                  WHERE c.mrecommend = cd.custid
    --                )
    --         AND c.roleid = 1
    --        )
    --        OR (EXISTS (SELECT 1
    --                      FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
    --                     WHERE c.srecommend = cd.custid
    --                   )
    --            AND c.roleid IN (1, 2)
    --           )
    --       )

    --IF @@ROWCOUNT <> 0
    --BEGIN
    --    SELECT @ErrMsg = 'This account is under a Direct Account!',
	   --        @ErrCode = 16
	   -- RETURN
    --END

    --Direct Account
    --SELECT 1
    --  FROM Customer c WITH(NOLOCK)
    -- WHERE c.custid = @custid
    --   AND ((EXISTS (SELECT 1
    --                   FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
    --                  WHERE c.recommend = cd.custid
    --                    AND cd.roleid = 2
    --                )
    --         AND c.roleid = 1
    --        )
    --        OR (EXISTS (SELECT 1
    --                      FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
    --                     WHERE c.mrecommend = cd.custid
    --                       AND cd.roleid = 3
    --                   )
    --            AND c.roleid = 2
    --           )
    --        OR (EXISTS (SELECT 1
    --                      FROM dbo.Acc_CustDirect cd WITH(NOLOCK)
    --                     WHERE c.srecommend = cd.custid
    --                       AND cd.roleid = 4
    --                   )
    --            AND c.roleid = 3
    --           )
    --       )

    --IF @@ROWCOUNT <> 0
    --BEGIN
    --    SELECT @ErrMsg = 'This account is a Direct Account!',
	   --        @ErrCode = 17
	   -- RETURN
    --END

    --Dummy
    SELECT @isOK = 1
      FROM dbo.Acc_CustDirect WITH(NOLOCK)
     WHERE custid = @custid
     
    IF @@ROWCOUNT <> 0
    BEGIN
        SELECT @ErrMsg = 'This account is a dummy for Direct Account!',
	           @ErrCode = 18
	    RETURN
    END
    
    --SELECT @ErrCode = 0
    --     , @ErrMsg = ''
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_CustMarkDirectCheckEnable] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustMarkDirectCheckEnable] TO [bodbAdminNet]
GO 
