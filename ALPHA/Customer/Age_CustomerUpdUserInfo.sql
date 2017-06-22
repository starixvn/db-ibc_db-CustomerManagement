USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustomerUpdUserInfo]    Script Date: 06/11/2015 12:53:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Age_CustomerUpdUserInfo    Script Date: 6/3/2014 3:25:38 AM ******/
/****** Object:  Stored Procedure dbo.Age_CustomerUpdUserInfo    Script Date: 6/3/2014 11:33:37 AM ******/
ALTER PROCEDURE [dbo].[Age_CustomerUpdUserInfo]  
    @custid         int , --customer to be updated  
    @firstname      nvarchar(50),
    @lastname       nvarchar(50),
    @phone          nvarchar(50),
    @mobilephone    nvarchar(50),
    @email          nvarchar(50),
    @fax            nvarchar(50),
    @discasino      bit = 0,
    @remark         nvarchar(300) = NULL,
    @IP             as nvarchar(15) = '',
    @userid         int ,       --updater Id
    @subaccid       int = 0 ,   --Sub-AccountID
    @language       nvarchar(2) = 'E',
    @errorcode      int = 0 OUTPUT,
    @errormsg       nvarchar(200) = '' OUTPUT
AS /*  
Created: 20090211@nqminh  
Task : Select customer information  
DB: DBCUST/CUSTDB
Original:  
  
Revisions:  
    - 20090318@Hanh: add Korean language  
 - 20090729@Phuc: Write log subaccname instead of subaccid.  
 - 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)  
 - 20090917@Phuc: write log into DBLOG.  
 - 20091008@Kiwi: Remove WriteLog_UserLog  
 - 20091125@Terry: Check disable casino  
 - 20100108@Lewin: Change SP format  
 - 20100917@Kiwi: Correct "convert wrong datatype when writing log"  
 - 20101021@Henry: Record execution time  
 - 20110606@Amy: Write log old values  
 - 20110907@Sophia: Change Linked Server from DB052 to DB053   
 - 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language  
 - 20130311@Dan: Change linked server DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure  
 - 20140520@Logan:   1.Update remark for SAg, MAg, Ag and member.  
                     2.Code aligning  
 - 20150611@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
 - 20160614@Helen: Security Prevention Step 1 - Cross level update -  [Redmine:55377]
                      
Param's Explanation:  
• @custid: custid that need to be viewed.     
*/  
BEGIN
	SET NOCOUNT ON
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	Declare @Old_firstname NVARCHAR(50),
			@Old_lastname NVARCHAR(50),
			@Old_phone NVARCHAR(50),
			@Old_mobilephone NVARCHAR(50),
			@Old_email NVARCHAR(50),
			@Old_fax NVARCHAR(50),
			@Old_remark nvarchar(300),
			@roleid tinyint

	
	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable
			@custid = @custid,
			@ErrCode = @errorcode OUTPUT,
			@ErrMsg = @errormsg OUTPUT
	IF @errorcode <> 0
		RETURN
	--end
	
	SELECT @Old_firstname = firstname,
		   @Old_lastname =lastname,
		   @Old_phone = phone,
		   @Old_mobilephone = mobilephone,
		   @Old_email = email,
		   @Old_fax = fax,
		   @Old_remark = remark,
		   @roleid = roleid
	  FROM Customer WITH(NOLOCK)
	 WHERE custid = @custid
	
	-- Only direct upline have update permission
	IF NOT EXISTS (SELECT 1 FROM dbo.f_AGE_IsCrossLevelUpdate (@custid,@roleid,@userid))
	BEGIN
		SELECT @errormsg = 'You don''t have permission to perform this action.',
			   @errorcode = 103
		RETURN
	END
		
	if @roleid = 2
	begin
		select @Old_remark = creationRemark
		  from CustAgent with(nolock)
		 where custid = @CustID
	end

	if @roleid = 3
	begin
		select @Old_remark = creationRemark
		  from CustMaster with(nolock)
		 where custid = @CustID
	end

	if @roleid = 4
	begin
		select @Old_remark = creationRemark
		  from CustSuper with(nolock)
		 where custid = @CustID
	end

	IF @disCasino = 1
	BEGIN
		SELECT @errormsg = CASE @Language
							 WHEN 'E' THEN 'This USER INFO function is temporarily unavailable, please update later.'
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](40005,@Language)
						   END,
			   @errorcode = 100
		RETURN
	END

	IF @Old_firstname = @firstname AND
	   @Old_lastname = @lastname AND
	   @Old_phone = @phone AND
	   @Old_mobilephone = @mobilephone AND
	   @Old_email = @email AND
	   @Old_fax = @fax AND
	   (@Old_remark = @remark OR @remark IS NULL)
		RETURN

	--Do update
	UPDATE Customer WITH(ROWLOCK)
	   SET firstname = @firstname,
		   lastname = @lastname,
		   phone = @phone,
		   mobilephone = @mobilephone,
		   email = @email,
		   fax = @fax
	 WHERE custid = @custid
	 
	if @roleid = 1
	begin
		update customer with(rowlock, updlock)
		   set remark = case when @remark is null then remark else SUBSTRING(@remark, 1, 50) end
		 where custid = @custid
	end

	if @roleid = 2
	begin
		update CustAgent with(rowlock, updlock)
		   set creationRemark = case when @remark is null then creationRemark else @remark end
		 where custid = @custid
	end

	if @roleid = 3
	begin
		update CustMaster with(rowlock, updlock)
		   set creationRemark = case when @remark is null then creationRemark else @remark end
		 where custid = @custid
	end

	if @roleid = 4
	begin
		update CustSuper with(rowlock, updlock)
		   set creationRemark = case when @remark is null then creationRemark else @remark end
		 where custid = @custid
	end

	--Error return
	IF (@@error <> 0)
	BEGIN
		SELECT @ErrorMsg = CASE @language
							 WHEN 'E' THEN 'Update process is unsuccessful.'
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](90001, @Language)
						   END,
			   @ErrorCode = 102
		RETURN
	END

	------------------------
	--Write log file
	DECLARE @LogSPData NVARCHAR(4000)
	DECLARE @TrackingValue2 NVARCHAR(4000)

	SELECT @LogSPData = '<Age_CustomerUpdUserInfo CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'FirstName="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@firstname AS NVARCHAR(50)),SPACE(1))) + '" '
		  + 'LastName="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@lastname AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Phone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@phone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'MobilePhone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@mobilephone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Email="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@email AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Fax="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@fax AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Remark="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@remark AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" '
		  + 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
		  + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" '
		  + 'ErrCode="' + COALESCE(CAST(@ErrorCode AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'ErrMsg="' + COALESCE(CAST(@ErrorMsg AS VARCHAR(2000)), SPACE(1)) + '" />'

	SELECT @TrackingValue2 = '<Age_CustomerUpdUserInfo CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'FirstName="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_firstname AS NVARCHAR(50)),SPACE(1))) + '" '
		  + 'LastName="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_lastname AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Phone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_phone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'MobilePhone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_mobilephone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Email="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_email AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Fax="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_fax AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Remark="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_remark AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" '
		  + 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
		  + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" '
		  + 'ErrCode="' + COALESCE(CAST(@ErrorCode AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'ErrMsg="' + COALESCE(CAST(@ErrorMsg AS VARCHAR(2000)), SPACE(1)) + '" />'

	set @endRun = getdate()
	set @duration  = datediff(millisecond, @startRun, @endRun)

	BEGIN TRY
	 /*609 Age_CustomerUpdUserInfo Update downline's info*/
	 EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	  @UserID = @UserID,
	  @CustID = @CustID,
	  @ActionID = 609,
	  @TrackingValue = @LogSPData,
	  @TrackingValue2 = @TrackingValue2,
	  @duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Age_CustomerUpdUserInfo CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'FirstName="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@firstname AS NVARCHAR(50)),SPACE(1))) + '" '
		  + 'LastName="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@lastname AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Phone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@phone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'MobilePhone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@mobilephone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Email="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@email AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Fax="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@fax AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Remark="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@remark AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" '
		  + 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
		  + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" '
		  + 'ErrCode="' + COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'ErrMsg="' + COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(2000)), SPACE(1)) + '" />'

	 SELECT @TrackingValue2 = '<Age_CustomerUpdUserInfo CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'FirstName="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_firstname AS NVARCHAR(50)),SPACE(1))) + '" '
		  + 'LastName="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_lastname AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Phone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_phone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'MobilePhone="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_mobilephone AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Email="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_email AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Fax="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_fax AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'Remark="' + dbo.f_EncodeXMLValue(COALESCE(CAST(@Old_remark AS NVARCHAR(50)), SPACE(1))) + '" '
		  + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" '
		  + 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
		  + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" '
		  + 'ErrCode="' + COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)), SPACE(1)) + '" '
		  + 'ErrMsg="' + COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(2000)), SPACE(1)) + '" />'

	/*609 Age_CustomerUpdUserInfo Update downline's info*/
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 609,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdUserInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdUserInfo] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerUpdUserInfo] TO [vnteam] AS [dbo]