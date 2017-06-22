ALTER PROCEDURE [dbo].[Age_CustSubCheckPageAccess]
	@SubAccID int,
	@spPageAccess varchar(50),
	@Language varchar(2) = 'E',
	@UserID int = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) ='' OUTPUT
AS
/*
Created: 
Task : Check AllowUpdate of Sub-Account
DB: DB053.bodb02
Original: Age_CustSubCheckPageAccess

Revisions:
    - 20090318@Hanh: add Korean language
    - 20090818@Phuc: check upline closed.
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
Param's Explanation:
• @SubAccID: sub account id
• @spPageAccess: 
*/

--Agent
--Check AllowUpdate of Sub-Account
SET NOCOUNT ON

Declare @IsUplineClosed bit, @PageAccess VARCHAR(50), @IsSubClosed BIT, @SubAllow bit -- nqminh - 17Feb09 - check subaccount closed?
Set @SubAllow = 0

--Check Upline closed
IF @UserID > 0
BEGIN
	Select @IsUplineClosed = ISNULL(closed,0) From Custinfo (nolock) Where CustID = @UserID
	Set @SubAllow = 1
END
IF @SubAccID <> 0
BEGIN
	SELECT @PageAccess = PageAccess, @IsSubClosed = ISNULL(closed,0) from custsub with (nolock) where subaccid = @SubAccID
	IF ( CHARINDEX(@spPageAccess, @PageAccess) > 0 AND (@IsSubClosed = 0) )
		Set @SubAllow = 1
	ELSE
		Set @SubAllow = 0
END

IF @IsUplineClosed = 1 OR @IsSubClosed = 1
BEGIN
	SELECT @ErrMsg = case @Language when 'E' then 'Your account was closed so you are forced to logout. Please contact your upline for the assistance!'  
						ELSE [dbo].[f_Get_MsgNamebyMsgID](40010,@Language) 
					end ,
       @ErrCode = 105
	RETURN
END

if @SubAllow = 0
BEGIN	
	select @ErrMsg = case @Language 
		when 'E' then 'No permission for sub-account.'
		ELSE [dbo].[f_Get_MsgNamebyMsgID](40011,@Language) 
	end,
	@ErrCode = 106
END


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT EXECUTE ON [dbo].[Age_CustSubCheckPageAccess] TO [bodbAdminNet]
GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubCheckPageAccess]  TO [bodbDownlineNet]
GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubCheckPageAccess]  TO [bodbDownlineNetView]
GO