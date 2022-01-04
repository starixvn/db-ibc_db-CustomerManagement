/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ChangeRate_Main_Upd] 
	@TableName VARCHAR(200)
AS
/*
	Created: 20211229@Malcolm
	DB: DBTXN-bodb02
	Task: Update rates for all existed tickets once financial change rates

	Revisions:
		- 20211229@Malcolm: Initialize SP [RedmineID: #163417]

	Param's Explanation:
	
	@TableName :
		1-bettransRnG
		2-bettransLC
		3-translog
		4-bettrans
		5-Transfer_Coll
		6-bettransG
 */
BEGIN
	SET NOCOUNT ON 
		  
	IF @TableName IS NULL OR @TableName = ''
	BEGIN
		RAISERROR('pls check @TableName!!!', 16, 1)
		RETURN
	END
	 
	DECLARE @__winlostdate SMALLDATETIME
	SELECT @__winlostdate = CONVERT(VARCHAR(10), GETDATE(), 23)

	EXEC dbo.ExecRep_00 @Winlostdate = @__winlostdate
			, @Target = 'DBTRANS' -- DBTRANS/REPLICATED
			, @TableName = @TableName

	EXEC dbo.ExecRep_00 @Winlostdate = @__winlostdate
			, @Target = 'REPLICATED' -- DBTRANS/REPLICATED
			, @TableName = @TableName


END