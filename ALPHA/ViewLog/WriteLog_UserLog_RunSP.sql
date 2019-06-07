/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView,Dot_Admin,bodbLicenseeNet" viewers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[WriteLog_UserLog_RunSP]
		@UserID INT,
		@CustID INT = 0,
		@SPName VARCHAR(50)= NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER
		@Doing	VARCHAR(4000) = NULL, --
		@ActionID INT = NULL,	
		@TrackingValue nvarchar(MAX)= NULL,
		@TrackingValue2 nvarchar(MAX) = NULL,
		@Duration INT = NULL		
/* 
	Created:
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Revisions:
		- 20100102@Lewin: Write xml tracking value to dbo.UserLog_RunSP 	  
		- 20101019@Henry: add one more parameter: @Duration   
		- 20110519@Johnson: add new column TrackingValue2
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]

    Param's Explaination:    	
		- @UserID: UserId perform this action
		- @CustID: 
		- @ActionID: Log action Id
		- @TrackingValue: xml string format
*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON   
	DECLARE @Site VARCHAR(10)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @CustID

	IF @Site = 'CN88'
	BEGIN
		INSERT INTO dbo.CS_UserLog_RunSP(UserID, 
										CustID, 
										ActionID, 
										TrackingValue,
										TrackingValue2,
										Duration
										)
							  VALUES (	@UserID, 
										@CustID, 
										@ActionId, 
										@TrackingValue,
										@TrackingValue2,
										@Duration
										)
	END
	ELSE
	BEGIN
		INSERT INTO dbo.UserLog_RunSP(	UserID, 
										CustID, 
										SPName,
										Doing,
										ActionID, 
										TrackingValue,
										TrackingValue2,
										Duration
										)
							  VALUES (	@UserID, 
										@CustID, 
										@SPName,
										@Doing,
										@ActionId, 
										@TrackingValue,
										@TrackingValue2,
										@Duration
										)		
	END
END
