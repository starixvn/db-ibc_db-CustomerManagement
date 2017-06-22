ALTER PROCEDURE [dbo].[Acc_OperatorUpd]
	@custid INT, 
	@firstname NVARCHAR (50), 
	@lastname NVARCHAR (50), 
	@address NVARCHAR (80), 
	@state NVARCHAR (50), 
	@country NVARCHAR (50), 
	@phone NVARCHAR (50), 
	@mobilephone NVARCHAR (50), 
	@fax NVARCHAR (50), 
	@email NVARCHAR (50), 
	@roleid INT, 
	@postal NVARCHAR (50), 
	@city NVARCHAR (50), 
	@UserID INT=0, 
	@ReturnErrCode BIT=0, 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT
AS
/*
Created: 
Task : Add account in User control 
DB: DBTXN/bodb02
Original:

Revisions:
	- 20080213@phuc: Check permission for account site
	- 20110526@Tom: Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
	- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
	- 20120605@Sophia: Modify @Logdata and change the range of ActionID
	- 20130118@Elodie: Change link server DB03 to DBPOLICY	
					   Write more log on DBTXN server in case of DBLOG server failure
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
DECLARE @LogData AS NVARCHAR (2000), 
@Begin AS DATETIME, 
@End AS DATETIME, 
@Duration AS INT;
SET @Begin = GETDATE();
--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @userid, @funcname = '[UserControl]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
    BEGIN
        IF @ReturnErrCode = 0
            RAISERROR (@ErrMsg, 16, 1);
        RETURN;
    END
--end
----Get old data
DECLARE 
	@db_firstname NVARCHAR(50), 
	@db_lastname NVARCHAR(50), 
	@db_address NVARCHAR(80), 
	@db_state NVARCHAR(50), 
	@db_country NVARCHAR(50), 
	@db_phone NVARCHAR(50), 
	@db_mobilephone NVARCHAR(50), 
	@db_fax NVARCHAR(50), 
	@db_email NVARCHAR(50), 
	@db_roleid INT, 
	@db_postal NVARCHAR(50), 
	@db_city NVARCHAR(50)

SELECT	@db_firstname = firstname,
		@db_lastname = lastname, 
		@db_address = address, 
		@db_state = state, 
		@db_country= country, 
		@db_phone = phone, 
		@db_mobilephone = mobilephone, 
		@db_fax = fax, 
		@db_email = email, 
		@db_roleid = roleid, 
		@db_postal = postal, 
		@db_city = city
FROM	Customer WITH (NOLOCK)
WHERE	custid = @custid

----Update data
IF		@db_firstname <> @firstname OR
		@db_lastname <> @lastname OR 
		@db_address <> @address OR 
		@db_state <> @state OR  
		@db_country <> @country OR  
		@db_phone <> @phone OR  
		@db_mobilephone <> @mobilephone OR  
		@db_fax <> @fax OR  
		@db_email <> @email OR  
		@db_roleid <> @roleid OR  
		@db_postal <> @postal OR  
		@db_city <> @city
BEGIN 
			
	UPDATE  Customer WITH (ROWLOCK, UPDLOCK)
		SET firstname   = @firstname,
			lastname    = @lastname,
			address     = @address,
			state       = @state,
			country     = @country,
			phone       = @phone,
			mobilephone = @mobilephone,
			fax         = @fax,
			email       = @email,
			roleid      = @roleid,
			postal      = @postal,
			city        = @city
	WHERE   custid = @custid;

	/**** Write to log table ***/
	SELECT @LOGDATA =	'<Acc_OperatorUpd>'+
							'<FirstName>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_firstname),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@firstname),'') + '</New>'+
							'</FirstName>'+
							'<LastName>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_lastname),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@lastname),'') + '</New>'+
							'</LastName>'+
							'<Address>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_address),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@address),'') + '</New>'+
							'</Address>'+
							'<State>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_state),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@state),'') + '</New>'+
							'</State>'+
							'<Country>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_country),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@country),'') + '</New>'+
							'</Country>'+
							'<Phone>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_phone),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@phone),'') + '</New>'+
							'</Phone>'+
							'<MobilePhone>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_mobilephone),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@mobilephone),'') + '</New>'+
							'</MobilePhone>'+
							'<Fax>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_fax),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@fax),'') + '</New>'+
							'</Fax>'+
							'<Email>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_email),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@email),'') + '</New>'+
							'</Email>'+
							'<Roleid>'+
								'<Old>'+ ISNULL(CONVERT(VARCHAR(10),@db_roleid),'') + '</Old>'+
								'<New>'+ ISNULL(CONVERT(VARCHAR(10),@roleid),'') + '</New>'+
							'</Roleid>'+
							'<Postal>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_postal),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@postal),'') + '</New>'+
							'</Postal>'+
							'<City>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_city),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@city),'') + '</New>'+
							'</City>'+
						'</Acc_OperatorUpd>'
								
	SET @End = GETDATE();
	SET @Duration = DATEDIFF(millisecond, @Begin, @End);
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
			@custID = @custid, 
			@Doing = @LogData, 
			@userid = @UserID, 
			@TypeID = 1, 
			@actionid = 1852, 
			@duration = @Duration
	END TRY
	BEGIN CATCH
		SELECT @LOGDATA =	'<Acc_OperatorUpd> ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							'<FirstName>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_firstname),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@firstname),'') + '</New>'+
							'</FirstName>'+
							'<LastName>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_lastname),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@lastname),'') + '</New>'+
							'</LastName>'+
							'<Address>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_address),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@address),'') + '</New>'+
							'</Address>'+
							'<State>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_state),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@state),'') + '</New>'+
							'</State>'+
							'<Country>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_country),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@country),'') + '</New>'+
							'</Country>'+
							'<Phone>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_phone),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@phone),'') + '</New>'+
							'</Phone>'+
							'<MobilePhone>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_mobilephone),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@mobilephone),'') + '</New>'+
							'</MobilePhone>'+
							'<Fax>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_fax),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@fax),'') + '</New>'+
							'</Fax>'+
							'<Email>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_email),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@email),'') + '</New>'+
							'</Email>'+
							'<Roleid>'+
								'<Old>'+ ISNULL(CONVERT(VARCHAR(10),@db_roleid),'') + '</Old>'+
								'<New>'+ ISNULL(CONVERT(VARCHAR(10),@roleid),'') + '</New>'+
							'</Roleid>'+
							'<Postal>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_postal),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@postal),'') + '</New>'+
							'</Postal>'+
							'<City>'+
								'<Old>'+ ISNULL([dbo].[f_EncodeXMLValue](@db_city),'') + '</Old>'+
								'<New>'+ ISNULL([dbo].[f_EncodeXMLValue](@city),'') + '</New>'+
							'</City>'+
						'</Acc_OperatorUpd>'
		EXEC bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
			@custID = @custid, 
			@Doing = @LogData, 
			@userid = @UserID, 
			@TypeID = 1, 
			@actionid = 1852, 
			@duration = @Duration
	END CATCH
END

GO
SET QUOTED_IDENTIFIER OFF;


GO
SET ANSI_NULLS ON;


GO
GRANT EXECUTE ON [dbo].[Acc_OperatorUpd] TO [bodbAdminNet]


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_OperatorUpd] TO [vnteam]

