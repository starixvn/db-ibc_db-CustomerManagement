/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [sb].[TOControl_TransitionIns]
	@XMLString XML
AS 
/*
Created: 20170324@Francis
Task : Process message from SB queue to insert data into transition table
DB: DBAGE.bodb02

Original:

Revisions:

Param explanation:

/*
	XML mapping dictionary tag when buliding and parsing XML string
	Tag		Stand_For
	---		---------
	s		srecommend
	m		mrecommend
	a		arecommend
	mid		matchid
	aTO		adjusted_TurnOver
	aHTO	adjusted_HouseTurnOver
*/

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @TmpTable AS TABLE (srecommend INT, mrecommend INT, recommend INT, matchid INT, adjusted_TurnOver MONEY, adjusted_HouseTurnOver MONEY
	, MinTransID BIGINT, MaxTransid BIGINT
							   )

	DECLARE @transidTbl AS TABLE (transid BIGINT)
	DECLARE  @FinishedTime DATETIME, @MaxBatchID BIGINT, @MinTransID BIGINT, @MaxTransID BIGINT

	BEGIN TRY
		INSERT INTO @TmpTable(srecommend, mrecommend, recommend, matchid, adjusted_TurnOver, adjusted_HouseTurnOver, MinTransID, MaxTransid)
		SELECT x.v.value('(s/text())[1]','INT') AS srecommend,
			   x.v.value('(m/text())[1]','INT') AS mrecommend,
			   x.v.value('(a/text())[1]','INT') AS recommend,
			   x.v.value('(mid/text())[1]','INT') AS matchid,
			   x.v.value('(aTO/text())[1]','MONEY') AS adjusted_TurnOver,
			   x.v.value('(aHTO/text())[1]','MONEY') AS adjusted_HouseTurnOver
			   , x.v.value('(min/text())[1]','BIGINT') AS MinTransID
			   , x.v.value('(max/text())[1]','BIGINT') AS MaxTransID
		FROM @XMLString.nodes('/root/r') AS x(v)
		OPTION (OPTIMIZE FOR (@XMLString = NULL))
		
		INSERT INTO dbo.TOControl_Transition (CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver)
			SELECT gl.CustID, t.matchid, t.adjusted_TurnOver, t.adjusted_HouseTurnOver
			FROM @TmpTable t INNER JOIN TOControl_GlobalSetting gl WITH (NOLOCK) 
				 ON (t.srecommend = gl.CustID OR t.mrecommend = gl.CustID OR t.recommend = gl.CustID)
				 AND gl.MaxTurnOver != 0

		SELECT @FinishedTime = CURRENT_TIMESTAMP

		SELECT @MinTransID = MIN(MinTransID), @MaxTransID = MAX(MaxTransid)
		FROM @TmpTable

		UPDATE b
		SET b.after_DLTO_Setting = @FinishedTime
		OUTPUT deleted.transid
		INTO @transidTbl (transid)
		FROM DownlineTO_Log_tmp b WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @TmpTable t ON b.recommend = t.recommend AND b.matchid = t.matchid 
		WHERE b.after_DLTO_Setting IS NULL
			AND b.transid BETWEEN @MinTransID AND @MaxTransID

		SELECT @MaxBatchID = ISNULL(MAX(batchid) + 1,0)
		FROM DownlineTO_Log WITH (NOLOCK)

		INSERT INTO DownlineTO_Log (batchid, transid, transdate, srecommend, mrecommend, recommend, matchid, after_DLTO_Trigger, after_DLTO_Setting, tstamp)
			SELECT @MaxBatchID, b.transid, transdate, srecommend, mrecommend, recommend, matchid, after_DLTO_Trigger, after_DLTO_Setting, tstamp
			FROM DownlineTO_Log_tmp b WITH (NOLOCK)
				INNER JOIN @transidTbl t ON b.transid = t.transid
		
		DELETE DownlineTO_Log_tmp WITH(ROWLOCK,UPDLOCK)
		WHERE transid IN (SELECT transid FROM @transidTbl)

	END TRY
	BEGIN CATCH --Write ErrLog
		PRINT (ERROR_MESSAGE())
	END CATCH
END 