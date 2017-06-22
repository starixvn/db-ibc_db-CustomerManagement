ALTER PROCEDURE [dbo].[Acc_LoginAdminCheckTimeConstraint]
(
	@custid		int,	
	@isAccess	BIT = 1 OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
)
AS
/*
	Created: 20130327@Lukas
	Task: constraint login time for some particular admins
	DB: DBCUST/CustDB
	
	Revision: 
		- 20130328@Lukas: set constrain time in between 9AM and 9PM (GMT+8)
		- 20151209@Elodie: set constrain time in between 11AM and 12PM (GMT+8)
		- 20151209@Elodie: set constrain time in between 10AM and 12PM (GMT+8)
		- 20160601@Elodie: Remove 2 accounts from the account site login time constrain
*/
BEGIN
	SET NOCOUNT ON 
	
	IF @custid IN (	32648	, ---ALYN
					--2937	, ---CRYSTAL
					--347009	, ---CRYSTAL1
					630505	, ---doreen1
					1089853	, ---Foong
					610439	, ---june3
					2340	, ---pin
					8811	  ---YEAN
					)
				AND DATEPART(HOUR,GETDATE()) BETWEEN 12 AND 21
	BEGIN		
		SELECT	@isAccess = 0,
				@ErrMsg = 'You are not authorized to access at this time. Please contact your supervisor.',
				@ErrCode = 100
		RETURN
	END
END

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_LoginAdminCheckTimeConstraint] TO [vnteam] AS [dbo]