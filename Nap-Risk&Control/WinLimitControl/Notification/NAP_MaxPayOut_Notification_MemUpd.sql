/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_MaxPayout_Notification_MemUpd]
	@MemNotify	 XML
    , @ErrCode   INT           = 0 OUTPUT
    , @ErrMsg    NVARCHAR(200) = '' OUTPUT
AS
/*
Created: 20230830@Luke
Task : Implement Company Max Payout Notification [Redmine: #193288]
DB: DBCUST/CustDB
Original:
Revisions:
	- 20230830@Luke: Implement Company Max Payout Notification [Redmine: #193288]
					 Clone from NAP_WinLimit_Notification_MemUpd
	- 20240808@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]				 
Param's Explanation:
	• @ErrCode	:
		= 0		: Transaction recorded successfully.
		> 0		: Specific Error.
	• @ErrMsg	: Error description.
	• @MemNotify: XML.format(<notify><row custid = "1" productid="1" transactiontime="2023-01-01 23:59:59" groupid="0" levelid = "255" ticketrefno = "165186211743268864", logid ="117432688" /></notify>)
*/

BEGIN
    SET NOCOUNT ON
    CREATE TABLE #tempMemNotify(
		custid				INT
		, productid			TINYINT
		, transactiontime	DATETIME
		, groupid			TINYINT
		, levelid			TINYINT
		, ticketrefno		BIGINT
		, logid				BIGINT
    )
	
    -- RESET output
    SELECT @ErrCode = 0,
        @ErrMsg = '';
    INSERT INTO #tempMemNotify(custid, productid, transactiontime, groupid, levelid, ticketrefno, logid)
        SELECT Tbl.Col.value('@custid', 'INT')
                , Tbl.Col.value('@productid', 'TINYINT')
                , Tbl.Col.value('@transactiontime', 'DATETIME')
                , Tbl.Col.value('@groupid', 'TINYINT')
				, Tbl.Col.value('@levelid', 'TINYINT')
				, Tbl.Col.value('@ticketrefno', 'BIGINT')
				, Tbl.Col.value('@logid', 'BIGINT')
        FROM @MemNotify.nodes('//notify/row') Tbl(Col)
         
    IF(@@ROWCOUNT = 0)
        BEGIN
            SELECT @ErrCode = 100,
                @ErrMsg = 'There is no information.'
            RETURN
        END
         
    UPDATE g
    SET  g.IsNotified = 1,
		RepUpdateTime = dbo.f_GetDateTime2()
    FROM dbo.WinLimit_CustGameMonitoring_History g WITH (ROWLOCK)
		INNER JOIN #tempMemNotify t ON g.logid = t.logid
END
GO
