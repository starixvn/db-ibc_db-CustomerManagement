/*<info serverAlias="DBTXN-bodb02" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ChangeRate_Main_Upd] 
	@TableName	VARCHAR(200),
	@IsSiteDB	BIT				= 0,
	@ErrCode	INT				= 0		OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''	OUTPUT	
AS
/*
	Created: 20211229@Malcolm
	DB: DBTXN-bodb02
	Task: Update rates for all existed tickets once financial change rates

	Revisions:
		- 20211229@Malcolm: Initialize SP [RedmineID: #163417]
		- 20220801@Sophia: Scale out, call at SiteDB [RedmineID: #175253]

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
	 
	DECLARE @Winlostdate SMALLDATETIME
	SELECT @winlostdate = CONVERT(VARCHAR(10), GETDATE(), 23)
	
	BEGIN TRY
		EXEC dbo.ExecRep_00 @Winlostdate = @winlostdate
				, @Target = 'DBTXN' -- DBTXN/REPLICATED
				, @TableName = @TableName
				, @IsSiteDB = @IsSiteDB

		EXEC dbo.ExecRep_00 @Winlostdate = @winlostdate
				, @Target = 'REPLICATED' -- DBTXN/REPLICATED
				, @TableName = @TableName
				, @IsSiteDB = @IsSiteDB
	 END TRY
	 BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	 END CATCH


END