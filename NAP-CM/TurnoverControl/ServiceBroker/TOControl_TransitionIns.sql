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

	DECLARE @TmpTable AS TABLE (srecommend INT, mrecommend INT, recommend INT, matchid INT, adjusted_TurnOver MONEY, adjusted_HouseTurnOver MONEY)

	BEGIN TRY
		INSERT INTO @TmpTable(srecommend, mrecommend, recommend, matchid, adjusted_TurnOver, adjusted_HouseTurnOver)
		SELECT x.v.value('(s/text())[1]','INT') AS srecommend,
			   x.v.value('(m/text())[1]','INT') AS mrecommend,
			   x.v.value('(a/text())[1]','INT') AS recommend,
			   x.v.value('(mid/text())[1]','INT') AS matchid,
			   x.v.value('(aTO/text())[1]','MONEY') AS adjusted_TurnOver,
			   x.v.value('(aHTO/text())[1]','MONEY') AS adjusted_HouseTurnOver
		FROM @XMLString.nodes('/root/r') AS x(v)
		OPTION (OPTIMIZE FOR (@XMLString = NULL))
		
		INSERT INTO dbo.TOControl_Transition (CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver)
			SELECT gl.CustID, t.matchid, t.adjusted_TurnOver, t.adjusted_HouseTurnOver
			FROM @TmpTable t INNER JOIN TOControl_GlobalSetting gl WITH (NOLOCK) 
				 ON (t.srecommend = gl.CustID OR t.mrecommend = gl.CustID OR t.recommend = gl.CustID)
				 AND gl.MaxTurnOver != 0
	END TRY
	BEGIN CATCH --Write ErrLog
		PRINT (ERROR_MESSAGE())
	END CATCH
END 