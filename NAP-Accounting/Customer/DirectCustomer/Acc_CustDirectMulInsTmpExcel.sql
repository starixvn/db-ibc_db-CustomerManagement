SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustDirectMulInsTmpExcel    Script Date: 10/9/2014 4:58:01 PM ******/
CREATE PROCEDURE [dbo].[Acc_CustDirectMulInsTmpExcel]	
	@UserID         INT,
	@ListTransfer   XML,	
	@ErrCode        INT = 0 OUTPUT,
	@ErrMsg         NVARCHAR(80) = '' OUTPUT
AS
/*
	Created: 
	Task : Insert multiple Direct Accounts
	DB: DBACC/bodb_ACC
	Original: 

	Revisions:		
		- 20140522@Logan: Initial version.
*/
BEGIN
    SET NOCOUNT ON
    	
    DECLARE @tblCust TABLE
    (
        seq      INT
      , username NVARCHAR(50)
    )
    	
    DECLARE @tblSucc TABLE
    (
        seq      INT
      , username NVARCHAR(50)
      , position VARCHAR(30)
    )

    DECLARE @tblFail TABLE
    (
        seq      INT
      , username NVARCHAR(50)
      , position VARCHAR(30)
      , reason   VARCHAR(300)
    )
    
    DECLARE @dupCust TABLE
    (
        username NVARCHAR(50)
    )

    INSERT INTO @tblCust(seq, username)
    SELECT T.C.value('./@Seq', 'int'),
           T.C.value('./@Username', 'nvarchar(50)')
      FROM @ListTransfer.nodes('/ListCustDirect/User') AS T(C)
    
    --select * from @tblCust
    --return

    IF @@ROWCOUNT = 0
    BEGIN
        SELECT @ErrMsg = 'The file is empty!'
             , @ErrCode = 10
	    RETURN
    END

    DECLARE @custid INT
          , @roleid TINYINT
          , @seq    INT = 1
          , @maxseq INT
          , @isOK   BIT
          
    SELECT @isOK = SUM(1)
      FROM @tblCust
  GROUP BY username
    HAVING COUNT(*) > 1
    
    IF @@ROWCOUNT > 0
    BEGIN
        SELECT @ErrMsg = 'There is duplicate data in the file!'
             , @ErrCode = 104

        RETURN
    END

    --Remove accounts with same upline
    --INSERT INTO @dupCust(username)
    --SELECT b.username
    --  FROM (SELECT MIN(a.Username) username
    --             , a.upline
    --             , COUNT(*) dup
    --          FROM (SELECT tc.Username
    --                     , CASE
	   --                      WHEN ci.roleid = 1 THEN ci.recommend
	   --                      WHEN ci.roleid = 2 THEN ci.mrecommend
	   --                      WHEN ci.roleid = 3 THEN ci.srecommend
	   --                    END upline
    --                  FROM @tblCust tc
    --            INNER JOIN bodb02.dbo.custInfo ci WITH(NOLOCK) ON tc.Username = ci.username
    --               ) a
    --      GROUP BY upline
    --        HAVING COUNT(*) > 1
    --       ) b

    --IF @@ROWCOUNT > 0
    --BEGIN
    --    INSERT INTO @tblSucc
    --    (
    --        seq
    --      , username
    --      , position
    --      , dup
    --    )
    --    SELECT tc.seq
    --         , dc.username
    --         , CASE
    --             WHEN ci.roleid = 1 THEN 'Member'
    --             WHEN ci.roleid = 2 THEN 'Agent'
    --             WHEN ci.roleid = 3 THEN 'Master'
    --           END
    --         , 1
    --      FROM @tblCust tc
    --INNER JOIN bodb02.dbo.custInfo ci WITH(NOLOCK) ON tc.username = ci.username
    --INNER JOIN @dupCust dc ON tc.username = dc.username

    --    DELETE @tblCust
    --     WHERE username IN (SELECT username
    --                          FROM @dupCust
    --                       )
    --END

    SELECT @maxseq = MAX(seq)
      FROM @tblCust

    WHILE @seq <= @maxseq
    BEGIN
        SELECT @custid = ci.custid
             , @roleid = ci.roleid
          FROM @tblCust c
    INNER JOIN bodb02.dbo.custInfo ci WITH(NOLOCK) ON c.username = ci.username
         WHERE c.seq = @seq

        IF @@ROWCOUNT > 0
        BEGIN
            --Validating data
            EXEC bodb02.dbo.Acc_CustMarkDirectCheckEnable
                @custid = @custid
              , @roleid = @roleid
              , @ErrCode = @ErrCode OUTPUT
              , @ErrMsg = @ErrMsg OUTPUT

            IF @ErrCode = 0
            BEGIN
                INSERT INTO @tblSucc(seq, username, position)
                SELECT seq
                     , username
                     , CASE
                         WHEN @roleid = 1 THEN 'Member'
                         WHEN @roleid = 2 THEN 'Agent'
                         WHEN @roleid = 3 THEN 'Master'
                       END
                  FROM @tblCust
                 WHERE seq = @seq
            END
            ELSE
            BEGIN
                INSERT INTO @tblFail(Seq, Username, Position, Reason)
                SELECT seq
                     , username
                     , CASE
                         WHEN @roleid = 1 THEN 'Member'
                         WHEN @roleid = 2 THEN 'Agent'
                         WHEN @roleid = 3 THEN 'Master'
                         ELSE 'Invalid'
                       END
                     , @ErrMsg
                  FROM @tblCust
                 WHERE seq = @seq
            END
        END
        ELSE
        BEGIN
            INSERT INTO @tblFail(Seq, Username, Position, Reason)
            SELECT seq
                 , username
                 , 'Invalid'
                 , 'Invalid username.'
              FROM @tblCust
             WHERE seq = @seq
        END
	    SELECT @seq = @seq + 1
    END

    --Insert data to temp table Acc_CustDirectTmp to change to direct account after clicking "Update Now" button
    DELETE dbo.Acc_CustDirectTmp
     WHERE creator = @UserID

    BEGIN TRY
        INSERT INTO dbo.Acc_CustDirectTmp
        (
            custid
          , roleid
          , creator
        )
        SELECT a.custid,
               CASE
                 WHEN t.position  = 'Member' THEN 1
	             WHEN t.position  = 'Agent' THEN 2
	             WHEN t.position  = 'Master' THEN 3
               END,
               @UserID
          FROM bodb02.dbo.custInfo a WITH(NOLOCK)
    INNER JOIN @tblSucc t ON a.username = t.username
    END TRY

    BEGIN CATCH
        IF @@ERROR = 2627
        BEGIN
            SELECT @ErrMsg = 'There is data waiting to update!',
		           @ErrCode = 105

	        RETURN
        END
        
        IF @@ERROR <> 0
        BEGIN
            SELECT @ErrMsg = 'Error while importing file. Please try again.',
		           @ErrCode = 106
    		       
            SELECT @ErrMsg, @ErrCode

            DELETE dbo.Acc_CustDirectTmp
             WHERE creator = @UserID

	        RETURN
        END
    END CATCH

    SELECT @ErrMsg = '',
		   @ErrCode = 0

    SELECT * FROM @tblSucc ORDER BY seq ASC

    SELECT * FROM @tblFail ORDER BY seq ASC
    
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Acc_CustDirectMulInsTmpExcel] TO [bodbAdminNet]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_CustDirectMulInsTmpExcel] TO [vnteam]
GO 
