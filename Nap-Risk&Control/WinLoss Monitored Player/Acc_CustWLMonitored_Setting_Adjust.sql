/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,wsv_alp,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_CustWLMonitored_Setting_Adjust
	@CustList VARCHAR(MAX)
AS  
/*  
	Created:	20221220@Eden
	Task:		Insert/Delete data into CustWLMonitored_Setting ( From Deposit And Credit setting)
	DB:			DBAGE-bodb02
	Original:	
  
	Revisions:  
	    - 20221220@Eden: Alpha - Monitor SMA Win Loss [Redmine:#179067]
	
	Sample : 
	EXEC Acc_CustWLMonitored_Setting_Adjust
		@CustList = '<ROOT>
						<R CustID="-1" recommend="1176070" IsDeleted="0" />
						<R CustID="-1" recommend="1176083" IsDeleted="0" />
						<R CustID="-1" recommend="1176086" IsDeleted="0" />
					</ROOT>'

	EXEC Acc_CustWLMonitored_Setting_Adjust
		@CustList = '<ROOT>
						<R CustID="-1" recommend="1176070" IsDeleted="1" />
						<R CustID="-1" recommend="1176083" IsDeleted="1" />
						<R CustID="-1" recommend="1176086" IsDeleted="1" />
					</ROOT>'
	
*/  
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #CustWLMonitored_Setting(
		[CustID] [int],
		[recommend] [int],
		[IsDeleted] [BIT],
	)

	DECLARE @DocHandler INT	

	IF ISNULL(@CustList,'') <> ''
	BEGIN
		-- For read xml					
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @CustList

		INSERT INTO #CustWLMonitored_Setting(CustID,recommend,IsDeleted)
		SELECT CustID,recommend,IsDeleted
		FROM OPENXML (@DocHandler, '/ROOT/R',1) 
		WITH (
			[CustID] [int],
			[recommend] [int],
			[IsDeleted] [BIT]
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	
	END		

	IF NOT EXISTS(SELECT TOP 1 1 FROM #CustWLMonitored_Setting)
	BEGIN
		RETURN
	END

	INSERT INTO dbo.[CustWLMonitored_Setting](custid,recommend)
	SELECT t.CustID,t.recommend
	FROM #CustWLMonitored_Setting t
		LEFT JOIN [CustWLMonitored_Setting] c WITH(NOLOCK) 
			ON t.CustID = c.CustID AND t.recommend = c.recommend
	WHERE t.IsDeleted = 0
		AND c.CustID IS NULL

	DELETE c
	FROM #CustWLMonitored_Setting t
		INNER JOIN [CustWLMonitored_Setting] c WITH(ROWLOCK,UPDLOCK) 
			ON t.CustID = c.CustID AND t.recommend = c.recommend
	WHERE t.IsDeleted = 1
END	
GO