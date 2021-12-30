/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[ExecRep_1411915] 
	@TableName VARCHAR(200) = ''
	,@Target VARCHAR(30) = 'DBTRANS' -- DBTRANS/REPLICATED
	,@ids VARCHAR(MAX)
AS
/*
	Created: 20211230@Malcolm
 	DB: DBTXN/bodb02
 	Task : 
 	
 	Revisions:	
		- 20211230@Malcolm: Initialize SP [RedmineID: #163417]
	
 	Param's Explanation: 
 		
 */

BEGIN
	SET NOCOUNT ON 
	IF @Target NOT IN ('DBTRANS', 'REPLICATED') RETURN
	IF @Target = 'DBTRANS' AND @@SERVERNAME <> 'DBTRANS' RETURN
	IF @Target = 'REPLICATED' AND @@SERVERNAME = 'DBTRANS' RETURN

	DECLARE @XmlData XML = CONVERT(XML, @ids)

	IF @@SERVERNAME <> 'DBTRANS'
	BEGIN
		IF (
			SELECT COUNT(1)
			FROM sysobjects
			WHERE NAME IN ('custinfo', 'bettrans', 'exchange') AND type = 'U'
		) < 3 
		RETURN
	END 

	DECLARE @table TABLE (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)

	INSERT INTO @table (transid, actualrate, virtualrate)
	SELECT 
		t.c.value('@transid', 'BIGINT') AS transid
		,t.c.value('@actualrate', 'FLOAT') AS actualrate
		,t.c.value('@virtualrate', 'FLOAT') AS virtualrate
	FROM @XMLData.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@XMLData = NULL))
	
	IF @TableName = 'bettransRnG'
	BEGIN	
		UPDATE b WITH(ROWLOCK)
		SET b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		FROM @table t 
			INNER JOIN bettransRnG b ON t.transid = b.transid
	END
	
	IF @TableName = 'bettransLC'
	BEGIN	
		UPDATE b WITH(ROWLOCK)
		SET b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		FROM @table t 
			INNER JOIN bettransLC b ON t.transid = b.transid 
	END
	
	IF @TableName = 'translog'
		UPDATE b WITH(ROWLOCK)
		SET b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		FROM @table t 
			INNER JOIN translog b ON t.transid = b.translogid 
	END
	
	IF @TableName = 'bettrans'
	BEGIN
		UPDATE b WITH(ROWLOCK)
		SET b.actualrate = t.actualrate,
			b.virtualrate = t.virtualrate
		FROM @table t 
			INNER JOIN bettrans b ON t.transid = b.transid 
	END
	
	IF @TableName = 'Transfer_Coll' AND EXISTS (SELECT 1 FROM sys.objects WHERE Object_Name(Object_ID) = 'Transfer_Coll')
	BEGIN 
			UPDATE b WITH(ROWLOCK)
			SET b.actualrate = t.actualrate			
			FROM @table t 
				INNER JOIN Transfer_Coll b ON t.transid = b.transid 
	END 
	
	IF @TableName = 'bettransG'
	BEGIN
		UPDATE b WITH (ROWLOCK)
		SET b.actualrate = t.actualrate, b.virtualrate = t.virtualrate
		FROM @table t 
			INNER JOIN dbo.bettransG b ON t.transid = b.transid 	
	END
GO