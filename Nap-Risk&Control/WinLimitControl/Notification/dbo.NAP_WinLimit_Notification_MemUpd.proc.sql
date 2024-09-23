/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemUpd](@MemNotify XML,
                                                         @ErrCode   INT           = 0 OUTPUT,
                                                         @ErrMsg    NVARCHAR(200) = '' OUTPUT)
AS

/*
Created: 20150702@bobby.nguyen
Task : #35215 - Win Limit Control - Notification update member
DB: DBCUST.CustDB
Original:
Revisions:
	- 20150702@bobby.nguyen: Initial
	- 20160507@Patrick: #57213 - Voidbridge integration
	- 20160701@Robert: CWL - Phase 2 - Support RED and Yellow level - [Redmine: 57722]
	- 20170329@Robert: CWL Phase 3A - email notification Enhancement - [Redmine: 72604]
	- 20170515@Helen: NAP Risk & Control - CHANGE REQUEST [Redmine: 75332]
	- 20240809@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
Param's Explanation:
	• @ErrCode	:
		= 0		: Transaction recorded successfully.
		> 0		: Specific Error.
	• @ErrMsg	: Error description.
	• @MemNotify: XML.format(<notify><row custid = "1" productid="1" winlostdate="" bettypeid="" /></notify>)
*/

BEGIN
         SET NOCOUNT ON;
         CREATE TABLE #tempMemNotify
         (custid      INT,
          productid   TINYINT,
          groupid     TINYINT,
          winlostdate SMALLDATETIME,
          levelid TINYINT
         );
	
         -- RESET output
         SELECT @ErrCode = 0,
                @ErrMsg = '';
         INSERT INTO #tempMemNotify
                SELECT Tbl.Col.value('@custid', 'INT'),
                       Tbl.Col.value('@productid', 'TINYINT'),
                       Tbl.Col.value('@groupid', 'TINYINT'),
                       Tbl.Col.value('@winlostdate', 'SMALLDATETIME'),
                       Tbl.Col.value('@levelid', 'TINYINT')
                FROM @MemNotify.nodes('//notify/row') Tbl(Col);
         
         IF(@@ROWCOUNT = 0)
             BEGIN
                 SELECT @ErrCode = 100,
                        @ErrMsg = 'There is no information.';
                 RETURN;
             END;
         
         UPDATE g
           SET  g.IsNotified = 1,
				g.RepUpdateTime = dbo.f_GetDateTime2()
         FROM dbo.WinLimit_CustGameMonitoring_History g WITH (ROWLOCK, UPDLOCK)
              INNER JOIN WinLimit_GameGroupSetting GGS WITH (NOLOCK) ON g.GroupID = GGS.GroupID
              INNER JOIN #tempMemNotify t ON g.custid = t.custid
                                             AND g.winlostdate = t.winlostdate
                                             AND g.productid = t.productid
                                             AND g.GroupID = t.groupid
                                             AND g.LevelID = t.levelid
END;
GO
