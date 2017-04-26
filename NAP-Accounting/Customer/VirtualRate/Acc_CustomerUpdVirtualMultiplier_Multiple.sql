ALTER PROCEDURE	[dbo].[Acc_CustomerUpdVirtualMultiplier_Multiple]
					@VirtualMultiplier		VARCHAR(MAX)	= ''
				,	@UserID					INT  
				,	@IP						VARCHAR(15)		= ''
				,	@ErrCode				INT				= 0			OUTPUT 
				,	@ErrMsg					NVARCHAR(4000)	= ''		OUTPUT  
AS  
/*  
	Created:	20160406@Billy
	Task:		Multiple update Virtual Multiplier for multiple customers
	DB:			DBCUST/CustDB
	Original:  
  
	Revisions: 
		- 20160614@Elodie: Update enable virtualrate [Redmine:#58700]
		- 20170328@Elodie: Expand the range of VR setting [RedmineID:#73808]

	Param's Explanation:  
		- @VirtualMultiplier = '<ROOT>
									<Rate CustIds="1,2,3,4,5,6" VirtualMultiplier="0.7" />	
									<Rate CustIds="11,22,33,44,55,66" VirtualMultiplier="1.5" />
								</ROOT>'
*/  
BEGIN  
	SET NOCOUNT ON;  

	CREATE TABLE	#log (
						CustID		INT
					,	LogValue	NVARCHAR(MAX)
					,	isFinished	BIT
							CONSTRAINT DF_#log_isFinished DEFAULT 0
					);
	  
	DECLARE	@startRun		DATETIME;  
	DECLARE	@endRun			DATETIME;  
	DECLARE	@duration		INT; 

	DECLARE	@tblVirtualrate	TABLE (
								CustIDs				VARCHAR(MAX)
							,	VirtualMultiplier	SMALLMONEY	
								);
	DECLARE	@DocHandler		INT;														
	 
	SET	@startRun = GETDATE();  
	
	IF	@VirtualMultiplier <> ''
	BEGIN
		-- For read xml					
		EXECUTE	sp_xml_preparedocument
					@DocHandler			OUTPUT
				,	@virtualmultiplier;

		INSERT INTO	@tblVirtualrate (
						CustIDs
					,	VirtualMultiplier
					)
		SELECT	Data.CustIds
			,	Data.VirtualMultiplier
		FROM OPENXML (@DocHandler, '/ROOT/Rate', 1) 
		WITH (
			CustIds				VARCHAR(MAX)
		,	VirtualMultiplier	SMALLMONEY	
		) AS Data;

		EXECUTE	sp_xml_removedocument
					@DocHandler;
		-- end read xml	
	END;		
		  
	IF	EXISTS	(	SELECT	1
					FROM	@tblVirtualrate
					WHERE	virtualmultiplier > 3.0 
						OR	virtualmultiplier < 0.1
				)  
	BEGIN  
		SELECT	@ErrMsg = N'Invalid virtual rate.'
			,	@ErrCode = 101;
		RETURN;
	END;
	
	-- Update via Execrep
	EXECUTE	dbo.Acc_CustSetting_10 
				@VirtualMultiplier = @VirtualMultiplier;

	-- Update enable virtual rate via Execrep
	EXECUTE	dbo.Acc_CustomerInfo_Execrep_04 @custid = 0, @roleid = 0, @action = 'EnableVirtualMultiplier', @EnableVirtualMultiplier = @VirtualMultiplier;

	-- Log data for each customer
	DECLARE	@CustID			INT
		,	@LogSPData		NVARCHAR(MAX) = '';
	
	INSERT INTO #log
		(	CustID, LogValue, isFinished)
	SELECT	CAST(ss.val AS INT)
		,	(	SELECT	ss.val		AS '@CustID'
					,	@UserID		AS '@UserID'
					,	@ErrCode	AS '@ErrCode'
					,	@ErrMsg		AS '@ErrMsg'
					,	@IP			AS '@IP'
					,	1			AS '@EnableVirtualrate'
					,	(	SELECT	pvs.sporttype			AS '@SportType'
								,	pvs.bettype				AS '@BetType'
								,	pvs.islive				AS '@IsLive'
								,	tv.VirtualMultiplier	AS '@VirtualMultiplier'
							FROM	dbo.ProfileVirtualSetting AS pvs WITH (NOLOCK)
							ORDER BY pvs.sporttype ASC, pvs.islive DESC, pvs.bettype ASC
							FOR XML PATH ('s')
						,	TYPE
						)
				FOR XML PATH ('Acc_CustomerUpdVirtualMultiplier_Multiple')
			)
		,	0
	FROM		@tblVirtualrate AS tv
	CROSS APPLY	dbo.strSplit(tv.CustIDs, ',') AS ss;

	SET	@endRun = GETDATE();
	SET	@duration = DATEDIFF(MILLISECOND, @startRun, @endRun);

	WHILE 0 = 0
	BEGIN
	    UPDATE	TOP(1) #log
		SET	isFinished = 1
		,	@CustID = CustID
		,	@LogSPData = LogValue
		WHERE	isFinished = 0;

		IF	@@ROWCOUNT = 0
			BREAK;

		BEGIN TRY
			EXECUTE	DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = @UserID
					,	@CustID = @CustID
					,	@ActionID = 807
					,	@TrackingValue = @LogSPData
					,	@Duration = @duration;			
		END TRY
		BEGIN CATCH
			EXECUTE	bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = @UserID
					,	@CustID = @CustID
					,	@ActionID = 807
					,	@TrackingValue = @LogSPData
					,	@Duration = @duration;
		END CATCH;
	END;

	DROP TABLE #log;
END

GO
GRANT EXECUTE ON Acc_CustomerUpdVirtualMultiplier_Multiple TO bodbAdminNet 