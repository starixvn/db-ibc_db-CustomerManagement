
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Acc_CustDirectListAffected    Script Date: 10/9/2014 4:58:03 PM ******/
CREATE PROCEDURE [dbo].[Acc_CustDirectListAffected]
    @custid	INT
  , @mode   INT = 0
AS
/*
	Created: 
	Task : List out all accounts that will be affected
	DB: DBTXN/CustDB
	Original: 

	Revisions:		
		- 20140915@Logan:   Initial version.

    Param's Explanation:
    • @mode:
        0: list of username
        1: list of custid

    • @ErrCode:
        = 0:  Successful update.
        > 0:  Specific Error.

    • @ErrMsg: Error description.
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT

    SELECT @roleid = roleid
      FROM dbo.custInfo WITH(NOLOCK)
     WHERE custid = @custid

    IF @mode = 0
    BEGIN
        IF @roleid = 3
        BEGIN
            SELECT aff.username
                 , CASE
                     WHEN aff.closed = 1 THEN 'Closed'
                     ELSE CASE
                            WHEN Aff.reject = 1 THEN 'Suspended'
                            ELSE 'Open'
                          END
                   END Status
                 , 'Master' Position
              FROM dbo.custInfo aff WITH(NOLOCK)
        INNER JOIN dbo.CustMaster cm WITH(NOLOCK) ON cm.custid = aff.custid
        INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.srecommend = ori.srecommend
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND cm.IsInternal = 0
        END
        ELSE IF @roleid = 2
        BEGIN
            SELECT aff.username
                 , CASE
                     WHEN aff.closed = 1 THEN 'Closed'
                     ELSE CASE
                            WHEN Aff.reject = 1 THEN 'Suspended'
                            ELSE 'Open'
                          END
                   END Status
                 , 'Agent' Position
              FROM dbo.custInfo aff WITH(NOLOCK)
        INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = aff.custid
        INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.mrecommend = ori.mrecommend
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND ca.IsInternal = 0
        END
        ELSE IF @roleid = 1
        BEGIN
            SELECT aff.username
                 , CASE
                     WHEN aff.closed = 1 THEN 'Closed'
                     ELSE CASE
                            WHEN aff.reject = 1 THEN 'Suspended'
                            ELSE 'Open'
                          END
                   END Status
                 , 'Member' Position
              FROM dbo.custInfo aff WITH(NOLOCK)
        INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.recommend = ori.recommend
        INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = aff.recommend
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND ca.IsInternal = 0

        END
    END
    ELSE IF @mode = 1
    BEGIN
        IF @roleid = 3
        BEGIN
            SELECT aff.custid
              FROM dbo.custInfo aff WITH(NOLOCK)
        INNER JOIN dbo.CustMaster cm WITH(NOLOCK) ON cm.custid = aff.custid
        INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.srecommend = ori.srecommend
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND cm.IsInternal = 0
        END
        ELSE IF @roleid = 2
        BEGIN
            SELECT aff.custid
              FROM dbo.custInfo aff WITH(NOLOCK)
        INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = aff.custid
        INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.mrecommend = ori.mrecommend
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND ca.IsInternal = 0
        END
        ELSE IF @roleid = 1
        BEGIN
            SELECT aff.custid
              FROM dbo.custInfo aff WITH(NOLOCK)
        INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.recommend = ori.recommend
        INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = aff.recommend
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND ca.IsInternal = 0
        END
    END
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Acc_CustDirectListAffected] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Acc_CustDirectListAffected] TO [bodbAdminNet]
GO 
