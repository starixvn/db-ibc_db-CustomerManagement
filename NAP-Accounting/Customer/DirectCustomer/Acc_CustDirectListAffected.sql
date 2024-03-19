/*<info serverAlias="DBCUST-CustDB,DBTXN-CustDB" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustDirectListAffected]
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
		- 20210510@Tina: Lock account & indirect close account [redmine: #148600]

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
                     WHEN ISNULL(cs.closed, aff.closed) = 1 THEN 'Closed'
                     ELSE CASE
                            WHEN ISNULL(cs.reject,Aff.reject) = 1 THEN 'Suspended'
                            ELSE 'Open'
                          END
                   END Status
                 , 'Master' Position
              FROM dbo.custInfo aff WITH(NOLOCK)
					INNER JOIN dbo.CustMaster cm WITH(NOLOCK) ON cm.custid = aff.custid
					INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.srecommend = ori.srecommend
					OUTER APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = aff.custid
								) AS cs
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND cm.IsInternal = 0
        END
        ELSE IF @roleid = 2
        BEGIN
            SELECT aff.username
                 , CASE
                     WHEN ISNULL(cs.closed,aff.closed) = 1 THEN 'Closed'
                     ELSE CASE
                            WHEN ISNULL(cs.reject,aff.reject) = 1 THEN 'Suspended'
                            ELSE 'Open'
                          END
                   END Status
                 , 'Agent' Position
              FROM dbo.custInfo aff WITH(NOLOCK)
					INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = aff.custid
					INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
                                                AND aff.mrecommend = ori.mrecommend
					OUTER APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = aff.custid
								) AS cs
             WHERE ori.custid = @custid
               AND aff.Enabled = 1
               AND ca.IsInternal = 0
        END
        ELSE IF @roleid = 1
        BEGIN
            SELECT aff.username
                 , CASE
                     WHEN ISNULL(cs.closed,aff.closed) = 1 THEN 'Closed'
                     ELSE CASE
                            WHEN ISNULL(cs.reject,aff.reject) = 1 THEN 'Suspended'
                            ELSE 'Open'
                          END
                   END Status
                 , 'Member' Position
              FROM dbo.custInfo aff WITH(NOLOCK)
					INNER JOIN dbo.custInfo ori WITH(NOLOCK) ON aff.roleid = ori.roleid
															AND aff.recommend = ori.recommend
					INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = aff.recommend
					OUTER APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = aff.custid
								) AS cs
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
