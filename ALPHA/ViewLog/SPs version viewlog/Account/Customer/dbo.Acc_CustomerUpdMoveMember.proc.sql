ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveMember]
    @agentname VARCHAR(40) ,
    @membername VARCHAR(40) ,
    @userid INT ,
    @IP VARCHAR(15) = '' ,
    @ReturnErrCode BIT = 0 ,
    @ErrCode INT = 0 OUTPUT ,
    @ErrMsg NVARCHAR(200) = '' OUTPUT
AS /*
Created: 
Task : Move a member to another agent
DB: DB02.bodb02
Original:

Revisions:
    - 20080213@Tommy: Check permission for account site
	- 20090525@Daniel: add check contraints for Horse & Finance
	- 20090528@Daniel: Fix check commission for all sports
	- 20090716@Jamie: Check auto master PT on agent 
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
	- 20090917@Phuc: Write log to dblog	
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091112@Jamie: Check DisableOutright before moving
	- 200911224@Kiwi: Use loop to update in case number of tickets is huge
	- 20091214@Jamie: Correct member's commission
	- 20091216@Jamie: Separate 3rd Party to CustSetting3rd 
	- 20091222@Kiwi: Apply Execution Replication (dbo.Acc_ExecRep_00)
	- 20100109@Lewin: Change sp format
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    
• @ErrMsg: Error description.
*/

    EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID,
        @funcname = '[OtherCust]', @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
--end


    DECLARE @srecommend INT ,
        @mrecommend INT ,
        @recommend INT ,
        @acurrency TINYINT ,
		--==Member Info ==--
        @srecommend_old INT ,
        @mrecommend_old INT ,
        @recommend_old INT ,
        @currency_old TINYINT ,
        @custid INT , 
		--== Enable/Disable HR, FI  ==--- 
        @adisableHR BIT ,
        @disableHR BIT ,
        @adisableFI BIT ,
        @disableFI BIT ,
        @aDisableOutright BIT ,
        @DisableOutright BIT 
		
    SELECT  @srecommend = srecommend ,
            @mrecommend = mrecommend ,
            @recommend = recommend ,
            @acurrency = currency ,
            @adisableHR = DisableHorseracing ,
            @adisableFI = DisableFinancial ,
            @aDisableOutright = DisableOutright
    FROM    custinfo WITH ( NOLOCK )
    WHERE   username = @agentname
            AND roleid = 2

    SELECT  @custid = custid ,
            @recommend_old = recommend ,
            @srecommend_old = srecommend ,
            @mrecommend_old = mrecommend ,
            @currency_old = currency ,
            @disableHR = DisableHorseracing ,
            @disableFI = DisableFinancial ,
            @DisableOutright = DisableOutright
    FROM    custinfo WITH ( NOLOCK )
    WHERE   username = @membername
            AND roleid = 1


    IF ISNULL(@recommend, 0) = 0 
        BEGIN
            SELECT  @ErrMsg = 'Error agent ' + @agentname
                    + ': agent not found.' ,
                    @ErrCode = 101					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

    IF ISNULL(@recommend_old, 0) = 0 
        BEGIN
            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname + ': agent not found.' ,
                    @ErrCode = 102					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

    IF ISNULL(@recommend, 0) = @recommend_old 
        BEGIN
            SELECT  @ErrMsg = 'Error occurs. The member ' + @membername
                    + ' already belongs to agent ' + @agentname + '.' ,
                    @ErrCode = 103					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END
--check an account disabled or not 
    EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @username = @membername,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT 
    IF @ErrCode <> 0 
        RETURN 

    EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @username = @agentname,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT 
    IF @ErrCode <> 0 
        RETURN 

    IF @currency_old <> @acurrency 
        BEGIN
            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname
                    + ': currency of new agent and member does not match.' ,
                    @ErrCode = 104					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

----------------------------------
--Check Horse, FI enable status:
    IF @adisableHR = 1
        AND @disableHR = 0 
        BEGIN
            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname
                    + ': member is enabled Horse Racing but new agent is not enabled Horse Racing.' ,
                    @ErrCode = 108					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

    IF @adisableFI = 1
        AND @disableFI = 0 
        BEGIN
            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname
                    + ': member is enabled Finance but new agent is not enabled Finance.' ,
                    @ErrCode = 109
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

----------------------------------
--Check Horse, FI, Casino sync status:
    IF EXISTS ( SELECT  1
                FROM    custsetting3rd WITH ( NOLOCK )
                WHERE   custid = @custid
                        AND sporttype = 151 )
        AND NOT EXISTS ( SELECT 1
                         FROM   custsetting3rd WITH ( NOLOCK )
                         WHERE  custid = @recommend
                                AND sporttype = 151 ) 
        BEGIN
            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname
                    + ': agent does not have Horse Racing setting.' ,
                    @ErrCode = 110					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

    IF EXISTS ( SELECT  1
                FROM    custsetting3rd WITH ( NOLOCK )
                WHERE   custid = @custid
                        AND sporttype = 201 )
        AND NOT EXISTS ( SELECT 1
                         FROM   custsetting3rd WITH ( NOLOCK )
                         WHERE  custid = @recommend
                                AND sporttype = 201 ) 
        BEGIN
            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname + ': agent does not have Finance setting.' ,
                    @ErrCode = 111					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

    IF EXISTS ( SELECT  1
                FROM    custinfo WITH ( NOLOCK )
                WHERE   custid = @custid
                        AND SyncCasino = 1 ) 
        BEGIN
            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname + ': member is already Casino-synchronized.' ,
                    @ErrCode = 112					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

--Check identical auto master position taking
    IF EXISTS ( SELECT  1
                FROM    custsetting AS acs_old WITH ( NOLOCK )
                        INNER JOIN custsetting AS acs_new WITH ( NOLOCK ) ON acs_old.sporttype = acs_new.sporttype
                                                              AND acs_old.bettype = acs_new.bettype
                WHERE   acs_old.custid = @recommend_old
                        AND acs_new.custid = @recommend
                        AND ( acs_old.isautompositiontaking <> acs_new.isautompositiontaking
                              OR acs_old.isautolivempositiontaking <> acs_new.isautolivempositiontaking
                            ) ) 
        BEGIN
	
            SELECT  @ErrMsg = 'Error agent ' + @agentname
                    + ': Auto Mater Position Taking of new agent is not matched with old agent.' ,
                    @ErrCode = 115					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

--Check identical auto master position taking 3rd
    IF EXISTS ( SELECT  1
                FROM    custsetting3rd AS acs_old WITH ( NOLOCK )
                        INNER JOIN custsetting3rd AS acs_new WITH ( NOLOCK ) ON acs_old.sporttype = acs_new.sporttype
                                                              AND acs_old.bettype = acs_new.bettype
                WHERE   acs_old.custid = @recommend_old
                        AND acs_new.custid = @recommend
                        AND acs_old.isautompositiontaking <> acs_new.isautompositiontaking ) 
        BEGIN
	
            SELECT  @ErrMsg = 'Error agent ' + @agentname
                    + ': Auto Mater Position Taking of new agent is not matched with old agent.' ,
                    @ErrCode = 119					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

----------------------------
    DECLARE @apositiontaking_1 SMALLMONEY ,
        @apositiontaking_2 SMALLMONEY ,
        @apositiontaking_3 SMALLMONEY ,
        @apositiontaking_4 SMALLMONEY ,
        @apositiontaking_5 SMALLMONEY ,
        @apositiontaking_6 SMALLMONEY ,
        @apositiontaking_7 SMALLMONEY ,
        @apositiontaking_8 SMALLMONEY ,
        @apositiontaking_9 SMALLMONEY ,
        @apositiontaking_10 SMALLMONEY ,
        @alivepositiontaking_1 SMALLMONEY ,
        @alivepositiontaking_3 SMALLMONEY ,
        @alivepositiontaking_7 SMALLMONEY ,
        @alivepositiontaking_8 SMALLMONEY ,
        @v2apositiontaking_1 SMALLMONEY ,
        @v2apositiontaking_2 SMALLMONEY ,
        @v2apositiontaking_3 SMALLMONEY ,
        @v2apositiontaking_7 SMALLMONEY ,
        @v2apositiontaking_8 SMALLMONEY ,
        @v2apositiontaking_9 SMALLMONEY ,
        @v2apositiontaking_20 SMALLMONEY ,
        @v3apositiontaking_1 SMALLMONEY ,
        @v3apositiontaking_2 SMALLMONEY ,
        @v3apositiontaking_3 SMALLMONEY ,
        @v3apositiontaking_20 SMALLMONEY ,
        @v5apositiontaking_1 SMALLMONEY ,
        @v5apositiontaking_2 SMALLMONEY ,
        @v5apositiontaking_3 SMALLMONEY ,
        @v5apositiontaking_20 SMALLMONEY ,
        @v8apositiontaking_1 SMALLMONEY ,
        @v8apositiontaking_3 SMALLMONEY ,
        @v8apositiontaking_20 SMALLMONEY ,
        @v10apositiontaking_1 SMALLMONEY ,
        @v10apositiontaking_2 SMALLMONEY ,
        @v10apositiontaking_3 SMALLMONEY ,
        @v10apositiontaking_20 SMALLMONEY ,
        @v11apositiontaking_1 SMALLMONEY ,
        @v11apositiontaking_20 SMALLMONEY ,
        @v99apositiontaking_1 SMALLMONEY ,
        @v99apositiontaking_2 SMALLMONEY ,
        @v99apositiontaking_3 SMALLMONEY ,
        @v99apositiontaking_20 SMALLMONEY ,
        @v201apositiontaking_2 SMALLMONEY ,
        @v201apositiontaking_3 SMALLMONEY ,
        @v151apositiontaking_31 SMALLMONEY ,
        @v151apositiontaking_32 SMALLMONEY ,
        @v151apositiontaking_41 SMALLMONEY ,
        @v151apositiontaking_42 SMALLMONEY

    SELECT  @apositiontaking_1 = apositiontaking ,
            @alivepositiontaking_1 = alivepositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 1
    SELECT  @apositiontaking_3 = apositiontaking ,
            @alivepositiontaking_3 = alivepositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 1
    SELECT  @apositiontaking_7 = apositiontaking ,
            @alivepositiontaking_7 = alivepositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 7
            AND sporttype = 1
    SELECT  @apositiontaking_8 = apositiontaking ,
            @alivepositiontaking_8 = alivepositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 8
            AND sporttype = 1
    SELECT  @apositiontaking_2 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 2
            AND sporttype = 1
    SELECT  @apositiontaking_4 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 4
            AND sporttype = 1
    SELECT  @apositiontaking_5 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 5
            AND sporttype = 1
    SELECT  @apositiontaking_6 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 6
            AND sporttype = 1
    SELECT  @apositiontaking_9 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 9
            AND sporttype = 1
    SELECT  @apositiontaking_10 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 10
            AND sporttype = 1

    SELECT  @v2apositiontaking_1 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 2
    SELECT  @v2apositiontaking_2 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 2
            AND sporttype = 2
    SELECT  @v2apositiontaking_3 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 2
    SELECT  @v2apositiontaking_7 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 7
            AND sporttype = 2
    SELECT  @v2apositiontaking_8 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 8
            AND sporttype = 2
    SELECT  @v2apositiontaking_9 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 9
            AND sporttype = 2
    SELECT  @v2apositiontaking_20 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 20
            AND sporttype = 2

    SELECT  @v3apositiontaking_1 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 3
    SELECT  @v3apositiontaking_2 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 2
            AND sporttype = 3
    SELECT  @v3apositiontaking_3 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 3
    SELECT  @v3apositiontaking_20 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 20
            AND sporttype = 3

    SELECT  @v5apositiontaking_1 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 5
    SELECT  @v5apositiontaking_2 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 2
            AND sporttype = 5
    SELECT  @v5apositiontaking_3 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 5
    SELECT  @v5apositiontaking_20 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 20
            AND sporttype = 5

    SELECT  @v8apositiontaking_1 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 8
    SELECT  @v8apositiontaking_3 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 8
    SELECT  @v8apositiontaking_20 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 20
            AND sporttype = 8

    SELECT  @v10apositiontaking_1 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 10
    SELECT  @v10apositiontaking_2 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 2
            AND sporttype = 10
    SELECT  @v10apositiontaking_3 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 10
    SELECT  @v10apositiontaking_20 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 20
            AND sporttype = 10

    SELECT  @v11apositiontaking_1 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 11
    SELECT  @v11apositiontaking_20 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 20
            AND sporttype = 11

    SELECT  @v99apositiontaking_1 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 1
            AND sporttype = 99
    SELECT  @v99apositiontaking_2 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 2
            AND sporttype = 99
    SELECT  @v99apositiontaking_3 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 99
    SELECT  @v99apositiontaking_20 = apositiontaking
    FROM    custsetting WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 20
            AND sporttype = 99

    SELECT  @v201apositiontaking_2 = apositiontaking
    FROM    custsetting3rd WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 2
            AND sporttype = 201
    SELECT  @v201apositiontaking_3 = apositiontaking
    FROM    custsetting3rd WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 3
            AND sporttype = 201

    SELECT  @v151apositiontaking_31 = apositiontaking
    FROM    custsetting3rd WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 31
            AND sporttype = 151
    SELECT  @v151apositiontaking_32 = apositiontaking
    FROM    custsetting3rd WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 32
            AND sporttype = 151
    SELECT  @v151apositiontaking_41 = apositiontaking
    FROM    custsetting3rd WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 41
            AND sporttype = 151
    SELECT  @v151apositiontaking_42 = apositiontaking
    FROM    custsetting3rd WITH ( NOLOCK )
    WHERE   custid = @custid
            AND bettype = 42
            AND sporttype = 151


    PRINT 'Move member ' + @membername + ' from agent id '
        + CONVERT(VARCHAR(20), @recommend_old) + ' to agent ' + @agentname
        + ' (id ' + CONVERT(VARCHAR(20), @recommend) + ')'

--customer table
    UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
    SET     srecommend = @srecommend ,
            mrecommend = @mrecommend ,
            recommend = @recommend
    WHERE   custid = @custid
    IF @@Error <> 0 
        BEGIN
	
	--ROLLBACK TRANSACTION MANUALLY
            UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid

            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname + ': update unsuccessfully (customer).' ,
                    @ErrCode = 110					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
	
            RETURN
        END

--custinfo table
    UPDATE  custinfo WITH ( ROWLOCK, UPDLOCK )
    SET     srecommend = @srecommend ,
            mrecommend = @mrecommend ,
            recommend = @recommend
    WHERE   custid = @custid
    IF @@Error <> 0 
        BEGIN
	--ROLLBACK TRANSACTION MANUALLY
            UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid
	
            UPDATE  custinfo WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid

            SELECT  @ErrMsg = 'Error member ' + @membername + ', agent '
                    + @agentname + ': update unsuccessfully (custinfo).' ,
                    @ErrCode = 111					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
	
            RETURN
        END

    EXEC dbo.Acc_CustomerUpdMember_PositionTaking @custid = @custid,
        @apositiontaking_1 = @apositiontaking_1,
        @apositiontaking_2 = @apositiontaking_2,
        @apositiontaking_3 = @apositiontaking_3,
        @apositiontaking_4 = @apositiontaking_4,
        @apositiontaking_5 = @apositiontaking_5,
        @apositiontaking_6 = @apositiontaking_6,
        @apositiontaking_7 = @apositiontaking_7,
        @apositiontaking_8 = @apositiontaking_8,
        @apositiontaking_9 = @apositiontaking_9,
        @apositiontaking_10 = @apositiontaking_10,
        @alivepositiontaking_1 = @alivepositiontaking_1,
        @alivepositiontaking_3 = @alivepositiontaking_3,
        @alivepositiontaking_7 = @alivepositiontaking_7,
        @alivepositiontaking_8 = @alivepositiontaking_8,
        @v2apositiontaking_1 = @v2apositiontaking_1,
        @v2apositiontaking_2 = @v2apositiontaking_2,
        @v2apositiontaking_3 = @v2apositiontaking_3,
        @v2apositiontaking_7 = @v2apositiontaking_7,
        @v2apositiontaking_8 = @v2apositiontaking_8,
        @v2apositiontaking_9 = @v2apositiontaking_9,
        @v2apositiontaking_20 = @v2apositiontaking_20,
        @v3apositiontaking_1 = @v3apositiontaking_1,
        @v3apositiontaking_2 = @v3apositiontaking_2,
        @v3apositiontaking_3 = @v3apositiontaking_3,
        @v3apositiontaking_20 = @v3apositiontaking_20,
        @v5apositiontaking_1 = @v5apositiontaking_1,
        @v5apositiontaking_2 = @v5apositiontaking_2,
        @v5apositiontaking_3 = @v5apositiontaking_3,
        @v5apositiontaking_20 = @v5apositiontaking_20,
        @v8apositiontaking_1 = @v8apositiontaking_1,
        @v8apositiontaking_3 = @v8apositiontaking_3,
        @v8apositiontaking_20 = @v8apositiontaking_20,
        @v10apositiontaking_1 = @v10apositiontaking_1,
        @v10apositiontaking_2 = @v10apositiontaking_2,
        @v10apositiontaking_3 = @v10apositiontaking_3,
        @v10apositiontaking_20 = @v10apositiontaking_20,
        @v11apositiontaking_1 = @v11apositiontaking_1,
        @v11apositiontaking_20 = @v11apositiontaking_20,
        @v99apositiontaking_1 = @v99apositiontaking_1,
        @v99apositiontaking_2 = @v99apositiontaking_2,
        @v99apositiontaking_3 = @v99apositiontaking_3,
        @v99apositiontaking_20 = @v99apositiontaking_20, @UserID = @UserID,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode > 0 
        BEGIN
	--ROLLBACK TRANSACTION MANUALLY
            UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid
	
            UPDATE  custinfo WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid
	
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)	
            RETURN
        END

    EXEC dbo.Acc_CustomerUpdMemberFI_PositionTaking @custid = @custid,
        @v201apositiontaking_2 = @v201apositiontaking_2,
        @v201apositiontaking_3 = @v201apositiontaking_3, @UserID = @UserID,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode > 0 
        BEGIN
	--ROLLBACK TRANSACTION MANUALLY
            UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid
	
            UPDATE  custinfo WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid
	
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)	
            RETURN
        END

    EXEC dbo.Acc_CustomerUpdMemberHR_PositionTaking @custid = @custid,
        @v151apositiontaking_31 = @v151apositiontaking_31,
        @v151apositiontaking_32 = @v151apositiontaking_32,
        @v151apositiontaking_41 = @v151apositiontaking_41,
        @v151apositiontaking_42 = @v151apositiontaking_42, @UserID = @UserID,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode > 0 
        BEGIN
	--ROLLBACK TRANSACTION MANUALLY
            UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid
	
            UPDATE  custinfo WITH ( ROWLOCK, UPDLOCK )
            SET     srecommend = @srecommend_old ,
                    mrecommend = @mrecommend_old ,
                    recommend = @recommend_old
            WHERE   custid = @custid
	
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)	
            RETURN
        END


    IF @aDisableOutright = 1
        AND ( @aDisableOutright <> @DisableOutright ) 
        BEGIN 

            UPDATE  Custinfo WITH ( UPDLOCK, ROWLOCK )
            SET     DisableOutright = 1
            WHERE   custid = @custid 
            IF @@ERROR <> 0 
                BEGIN
                    SELECT  @ErrMsg = 'Error member ' + @membername
                            + ', agent ' + @agentname
                            + ': update unsuccessfully (custinfo).' ,
                            @ErrCode = 115
                    IF @ReturnErrCode = 0 
                        RAISERROR (@ErrMsg, 16, 1)
                    RETURN
                END 
        END 

--Apply ExeReplication
    EXEC dbo.Acc_ExecRep_00 @custid = @custid, @recommend = @recommend,
        @recommend_old = @recommend_old, @mrecommend = @mrecommend,
        @mrecommend_old = @mrecommend_old, @srecommend = @srecommend,
        @srecommend_old = @srecommend_old, @roleid = 1,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode <> 0 
        RETURN

--Update Member's Comm
    DECLARE @ugroup VARCHAR(5)
    SELECT  @ugroup = ugroup
    FROM    Customer WITH ( NOLOCK )
    WHERE   custid = @custid
--super 
    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     sdiscount = CASE WHEN scs.bettype IN ( 1, 2, 3, 7, 8 )
                             THEN ( CASE WHEN @ugroup IN ( 'a', 'hka' )
                                         THEN scs.groupa
                                         WHEN @ugroup IN ( 'b', 'hkb' )
                                         THEN scs.groupb
                                         WHEN @ugroup IN ( 'c', 'hkc' )
                                         THEN scs.groupc
                                         WHEN @ugroup IN ( 'd', 'hkd' )
                                         THEN scs.groupd
                                         ELSE scs.sdiscount
                                    END )
                             ELSE scs.sdiscount
                        END
    FROM    CustSetting scs WITH ( NOLOCK )
            INNER JOIN CustSetting cs ON scs.custid = @srecommend
                                         AND cs.custid = @custid
                                         AND scs.sporttype = cs.sporttype
                                         AND scs.bettype = cs.bettype
    WHERE   ( scs.bettype IN ( 1, 2, 3, 7, 8 )
              AND cs.sdiscount > CASE WHEN @ugroup IN ( 'a', 'hka' )
                                      THEN scs.groupa
                                      WHEN @ugroup IN ( 'b', 'hkb' )
                                      THEN scs.groupb
                                      WHEN @ugroup IN ( 'c', 'hkc' )
                                      THEN scs.groupc
                                      WHEN @ugroup IN ( 'd', 'hkd' )
                                      THEN scs.groupd
                                      ELSE scs.sdiscount
                                 END
            )
            OR ( scs.bettype NOT IN ( 1, 2, 3, 7, 8 )
                 AND scs.sdiscount < cs.sdiscount
               )

    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update super commission unsuccessfully.' ,
                    @ErrCode = 115					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

--super 3rd

    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     sdiscount = scs.sdiscount
    FROM    CustSetting3rd scs WITH ( NOLOCK )
            INNER JOIN CustSetting3rd cs ON scs.custid = @srecommend
                                            AND cs.custid = @custid
                                            AND scs.sporttype = cs.sporttype
                                            AND scs.bettype = cs.bettype
    WHERE   scs.sdiscount < cs.sdiscount
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update super commission unsuccessfully.' ,
                    @ErrCode = 120				 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END


--master
    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     adiscount = CASE WHEN mcs.bettype IN ( 1, 2, 3, 7, 8 )
                             THEN ( CASE WHEN @ugroup IN ( 'a', 'hka' )
                                         THEN mcs.groupa
                                         WHEN @ugroup IN ( 'b', 'hkb' )
                                         THEN mcs.groupb
                                         WHEN @ugroup IN ( 'c', 'hkc' )
                                         THEN mcs.groupc
                                         WHEN @ugroup IN ( 'd', 'hkd' )
                                         THEN mcs.groupd
                                         ELSE mcs.adiscount
                                    END )
                             ELSE mcs.adiscount
                        END
    FROM    CustSetting mcs WITH ( NOLOCK )
            INNER JOIN CustSetting cs ON mcs.custid = @mrecommend
                                         AND cs.custid = @custid
                                         AND mcs.sporttype = cs.sporttype
                                         AND mcs.bettype = cs.bettype
    WHERE   ( mcs.bettype IN ( 1, 2, 3, 7, 8 )
              AND cs.adiscount > CASE WHEN @ugroup IN ( 'a', 'hka' )
                                      THEN mcs.groupa
                                      WHEN @ugroup IN ( 'b', 'hkb' )
                                      THEN mcs.groupb
                                      WHEN @ugroup IN ( 'c', 'hkc' )
                                      THEN mcs.groupc
                                      WHEN @ugroup IN ( 'd', 'hkd' )
                                      THEN mcs.groupd
                                      ELSE mcs.adiscount
                                 END
            )
            OR ( mcs.bettype NOT IN ( 1, 2, 3, 7, 8 )
                 AND mcs.adiscount < cs.adiscount
               )
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update master commission unsuccessfully.' ,
                    @ErrCode = 116					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

--master 3rd
    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     adiscount = mcs.adiscount
    FROM    CustSetting3rd mcs WITH ( NOLOCK )
            INNER JOIN CustSetting3rd cs ON mcs.custid = @mrecommend
                                            AND cs.custid = @custid
                                            AND mcs.sporttype = cs.sporttype
                                            AND mcs.bettype = cs.bettype
    WHERE   mcs.adiscount < cs.adiscount
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update master commission unsuccessfully.' ,
                    @ErrCode = 121					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END
--agent 
    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     cs.discount = CASE WHEN acs.bettype IN ( 1, 2, 3, 7, 8 )
                               THEN ( CASE WHEN @ugroup IN ( 'a', 'hka' )
                                           THEN acs.groupa
                                           WHEN @ugroup IN ( 'b', 'hkb' )
                                           THEN acs.groupb
                                           WHEN @ugroup IN ( 'c', 'hkc' )
                                           THEN acs.groupc
                                           WHEN @ugroup IN ( 'd', 'hkd' )
                                           THEN acs.groupd
                                           ELSE acs.discount
                                      END )
                               ELSE acs.discount
                          END
    FROM    CustSetting acs WITH ( NOLOCK )
            INNER JOIN CustSetting cs ON acs.custid = @recommend
                                         AND cs.custid = @custid
                                         AND acs.sporttype = cs.sporttype
                                         AND acs.bettype = cs.bettype
    WHERE   ( acs.bettype IN ( 1, 2, 3, 7, 8 )
              AND cs.discount > CASE WHEN @ugroup IN ( 'a', 'hka' )
                                     THEN acs.groupa
                                     WHEN @ugroup IN ( 'b', 'hkb' )
                                     THEN acs.groupb
                                     WHEN @ugroup IN ( 'c', 'hkc' )
                                     THEN acs.groupc
                                     WHEN @ugroup IN ( 'd', 'hkd' )
                                     THEN acs.groupd
                                     ELSE acs.discount
                                END
            )
            OR ( acs.bettype NOT IN ( 1, 2, 3, 7, 8 )
                 AND acs.discount < cs.discount
               )
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update agent commission unsuccessfully.' ,
                    @ErrCode = 117					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END

--agent 3rd
    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     cs.discount = acs.discount
    FROM    CustSetting3rd acs WITH ( NOLOCK )
            INNER JOIN CustSetting3rd cs ON acs.custid = @recommend
                                            AND cs.custid = @custid
                                            AND acs.sporttype = cs.sporttype
                                            AND acs.bettype = cs.bettype
    WHERE   acs.discount < cs.discount
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update agent commission unsuccessfully.' ,
                    @ErrCode = 122					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END
--member 
    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     playerdiscount = CASE WHEN acs.bettype IN ( 1, 2, 3, 7, 8 )
                                  THEN ( CASE WHEN @ugroup IN ( 'a', 'hka' )
                                              THEN acs.groupa
                                              WHEN @ugroup IN ( 'b', 'hkb' )
                                              THEN acs.groupb
                                              WHEN @ugroup IN ( 'c', 'hkc' )
                                              THEN acs.groupc
                                              WHEN @ugroup IN ( 'd', 'hkd' )
                                              THEN acs.groupd
                                              ELSE acs.discount
                                         END )
                                  ELSE acs.discount
                             END
    FROM    CustSetting acs WITH ( NOLOCK )
            INNER JOIN CustSetting cs ON acs.custid = @recommend
                                         AND cs.custid = @custid
                                         AND acs.sporttype = cs.sporttype
                                         AND acs.bettype = cs.bettype
    WHERE   ( acs.bettype IN ( 1, 2, 3, 7, 8 )
              AND cs.playerdiscount > CASE WHEN @ugroup IN ( 'a', 'hka' )
                                           THEN acs.groupa
                                           WHEN @ugroup IN ( 'b', 'hkb' )
                                           THEN acs.groupb
                                           WHEN @ugroup IN ( 'c', 'hkc' )
                                           THEN acs.groupc
                                           WHEN @ugroup IN ( 'd', 'hkd' )
                                           THEN acs.groupd
                                           ELSE acs.discount
                                      END
            )
            OR ( acs.bettype NOT IN ( 1, 2, 3, 7, 8 )
                 AND acs.discount < cs.playerdiscount
               )
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update commission unsuccessfully.' ,
                    @ErrCode = 118					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END
--member 3rd
    UPDATE  cs WITH ( UPDLOCK, ROWLOCK )
    SET     playerdiscount = acs.discount
    FROM    CustSetting3rd acs WITH ( NOLOCK )
            INNER JOIN CustSetting3rd cs ON acs.custid = @recommend
                                            AND cs.custid = @custid
                                            AND acs.sporttype = cs.sporttype
                                            AND acs.bettype = cs.bettype
    WHERE   acs.discount < cs.playerdiscount
    IF @@ERROR <> 0 
        BEGIN
            SELECT  @ErrMsg = 'update commission unsuccessfully.' ,
                    @ErrCode = 123					 
            IF @ReturnErrCode = 0 
                RAISERROR (@ErrMsg, 16, 1)
            RETURN
        END
    DECLARE @LogSPData VARCHAR(4000)

    SELECT  @LogSPData = '<Acc_CustomerUpdMoveMember  MemberName="' + @membername + '" OldAgentId="'
            + CONVERT(VARCHAR(20), @recommend_old) + '" NewAgentName="' + @agentname+ '" '
            + 'NewAgentId="' + CONVERT(VARCHAR(20), @recommend) + '" '  
			+'userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + '" '
			+'ReturnErrCode="' + COALESCE(CAST(@ReturnErrCode AS VARCHAR(50)), SPACE(1)) + '" '
			+'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
			+'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

/*615	Acc_CustomerUpdMoveMember	Move member to new Agent*/
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
		@UserID = @UserID,
		@CustID = @custid,
        @ActionID = 615, 
		@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveMember] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveMember] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMoveMember] TO [vnteam]