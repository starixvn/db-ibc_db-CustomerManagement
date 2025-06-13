/*<info serverAlias="DBCUST-CustDB" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_CustServiceTypeUpdate
	@CustID				INT,
	@ServiceType			TINYINT,
	@IP					VARCHAR(50)			= '',
	@Language				VARCHAR(2)			= 'E',
	@ErrCode				INT				= 0		OUTPUT,
	@ErrMsg				NVARCHAR(1000)		= ''		OUTPUT
			
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Enable or Disable ServiceType [Redmine #223896]   
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Agency Cash Service - S4 - Change ActionID [Redmine: #228627]

	Param:

	@ServiceType : 0 - Credit  || 1 - Cash

	DECLARE @p1 INT , @p2 NVARCHAR(1000)
	EXEC Age_CashService_CustServiceTypeUpdate @CustID										     = 1176086
							     , @ServiceType									     = 1
							     , @IP											     = '1.1.1.1'
							     , @Language										     = 'E'
							     , @ErrCode										     = @p1 OUTPUT
							     , @ErrMsg										     = @p2 OUTPUT

	SELECT @p1 , @p2
*/  
BEGIN
	SET NOCOUNT ON;
	     
	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT

	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	--Check disable user
	EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 
		RETURN 

	DECLARE @Old_ServiceType TINYINT 
	
	SELECT @Old_ServiceType = (SELECT ISNULL(ServiceType,0) FROM [vw_CustInfoExtra] WITH (NOLOCK) WHERE CustID = @CustID)

	--SELECT @Old_ServiceType , @ServiceType 
	--Only update 'ServiceType' status if values are different 
	IF @Old_ServiceType = @ServiceType
		RETURN
	
	IF @ServiceType IS NOT NULL AND @Old_ServiceType != @ServiceType
	BEGIN
		UPDATE cpsu
			SET cpsu.ServiceType = @ServiceType
			,   RepUpdateTime = [dbo].[f_GetDateTime2]()
		FROM CustProductStatus cpsu WITH (ROWLOCK , UPDLOCK) 
		WHERE cpsu.CustID = @CustID  
	END
	
	IF (@@error = 0)
	BEGIN
		SELECT  
			@ErrMsg = N'Update Successful!',
			@ErrCode = 0 ;
	END

	--START LOG
	--DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue VARCHAR(MAX), TrackingValue2 VARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue VARCHAR(MAX), @TrackingValue2 VARCHAR(MAX)
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 70633
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	-- LOG NEW VALUES
	SELECT @TrackingValue = '<Age_CashService_CustServiceTypeUpdate 
							CustID="' + convert(varchar(20), @CustID) 
							+'" IP="' + convert(varchar(50), @IP)   
							+'" IsActive="' + convert(varchar(20), @ServiceType) +'" />'

	-- LOG OLD VALUES
	SELECT @TrackingValue2 = '<Age_CashService_CustServiceTypeUpdate 
							CustID="' + convert(varchar(20), @CustID) 
							+'" IP="'  + convert(varchar(50), @IP)    
							+'" IsActive="' +  convert(varchar(20), @Old_ServiceType)  +'" />'

	--INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
	SELECT 
		@CustID AS UserID ,
		@CustID AS CustID ,
		@ActionID AS ActionID ,
		@TrackingValue AS TrackingValue ,
		@TrackingValue2 AS TrackingValue2 ,
		@DurationTime AS Duration
END