
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustDirectMulUpd    Script Date: 10/9/2014 4:58:03 PM ******/
CREATE PROCEDURE [dbo].[Acc_CustDirectMulUpd]
    @UserID     INT,    
    @IP         VARCHAR(15) = '',
    @ErrCode    INT = 0 OUTPUT,
    @ErrMsg     NVARCHAR(200) = '' OUTPUT
AS 
/*
    Created: 20140523
    Task : Update new multi direct accounts for username
    DB: DBTXN/CustDB
    Original: 
    Revisions:	
	    - 20140523@Logan: Initial version.
*/
BEGIN

    SET NOCOUNT ON

    DECLARE @tmpCustDirect TABLE
    (
        custid INT
      , roleid TINYINT
      , seq    INT
    )
            
    --DECLARE temp TABLEs to store success and fail customer
    DECLARE @Fail TABLE
    (
        Seq INT
      , Username NVARCHAR(50)
      , Position VARCHAR(30)
      , Reason NVARCHAR(100)
    )    

    DECLARE @Success TABLE
    (
        Seq INT
      , Username NVARCHAR(50)
      , Position VARCHAR(30)
    )

    INSERT INTO @tmpCustDirect
    (
        custid
      , roleid
      , seq
    )
    SELECT custid
         , roleid
         , ROW_NUMBER() OVER(ORDER BY custid, roleid)
      FROM DBACC.bodb_ACC.dbo.Acc_CustDirectTmp WITH(NOLOCK)
     WHERE creator = @UserID

    DECLARE @seq INT = 1
          , @maxSeq INT

    SELECT @maxSeq = MAX(seq)
      FROM @tmpCustDirect

    DECLARE @custid   INT
          , @roleid   TINYINT
          , @username NVARCHAR(50)

    WHILE @seq <= @maxSeq
    BEGIN
        SELECT @custid = cd.custid
             , @username = ci.username
             , @roleid = cd.roleid
          FROM @tmpCustDirect cd
    INNER JOIN dbo.custInfo ci WITH(NOLOCK) ON ci.custid = cd.custid
         WHERE cd.seq = @seq

        EXEC dbo.Acc_CustomerUpdDirectStatus
            @custid = @custid
          , @creator = @UserID
          , @IP = @IP
          , @ErrCode = @ErrCode OUTPUT
          , @ErrMsg = @ErrMsg OUTPUT
        
        IF @ErrCode > 0
        BEGIN
            INSERT INTO @Fail(Seq, Username, Position, Reason)
                 SELECT @seq
                      , @username
                      , CASE
                          WHEN @roleid = 1 THEN 'Member'
                          WHEN @roleid = 2 THEN 'Agent'
                          WHEN @roleid = 3 THEN 'Master'
                        END
                      , @ErrMsg
        END
        ELSE
        BEGIN
            INSERT INTO @Success(Seq, Username, Position)
                 SELECT @seq
                      , @username
                      , CASE
                          WHEN @roleid = 1 THEN 'Member'
                          WHEN @roleid = 2 THEN 'Agent'
                          WHEN @roleid = 3 THEN 'Master'
                        END
        END

        SET @seq = @seq + 1
    END

    --Return failed TABLE and success TABLE
    SELECT @ErrCode = 0
         , @ErrMsg = ''

    SELECT * FROM @Fail ORDER BY seq ASC

    SELECT * FROM @Success ORDER BY seq ASC

END	


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Acc_CustDirectMulUpd] TO [bodbAdminNet]
GO 
