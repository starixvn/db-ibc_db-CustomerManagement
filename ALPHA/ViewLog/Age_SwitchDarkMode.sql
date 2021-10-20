/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Age_SwitchDarkMode]
	@CustID INT = 0, 
	@SubAccID INT,  	
	@IsDarkMode BIT = 0,
	@IP VARCHAR(20)= '', 
	@Location VARCHAR(30)= 'HeaderMenu'
/* 
	Created: 20211019@Winfred
    Task: Alpha Support Dark Mode
    DB: DBCUST/CustDB
    
    Revisions:
		- 20211019@Winfred: Create SP add log Alpha Support Dark Mode [Redmine: #151816]

    Param's Explaination:    	
		- @CustID: CustID perform this action
		- @IsDarkMode: Light - Dark Mode
		- @IP: 
		- @Location: Login Page / Header Menu
*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON  
	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT,@LogData NVARCHAR(200),@xml				XML
	SET @Begin = GETDATE()
	
	SELECT @LogData = '<R CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '+  
	'SubAccName="'+ COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) as VARCHAR(30)), SPACE(1)) + '" ' +
	'DarkMode="'+  CASE WHEN @IsDarkMode = 0 THEN  'Light' ELSE 'Dark' END +  '" '+    		
	'Location="'+ coalesce(cast(@Location as varchar(30)),space(1)) + '" '+   
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'    
  
	SET @End = GETDATE()    
	SET @Duration  = DATEDIFF (MILLISECOND,@Begin,@End)    

	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper @Userid = @CustID
		, @CustId = @CustId
		, @ActionID = 1342
		, @TrackingValue = @LogData
		, @Duration = @Duration;	
				
END
GO

