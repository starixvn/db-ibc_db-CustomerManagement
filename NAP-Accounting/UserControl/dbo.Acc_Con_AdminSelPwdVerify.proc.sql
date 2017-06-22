ALTER PROCEDURE [dbo].[Acc_Con_AdminSelPwdVerify]
	@Username VARCHAR (30), 
	@UserPwd NVARCHAR (50), 
	@UserID INT, 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT
AS
/*
Created: 
Task : 
DB: DBTXN/BODB02
Original:

Revisions:    
	- 20130125@Elodie: Change link server DB03 to DBPOLICY

*/
SET NOCOUNT ON
SELECT @ErrCode = 0
IF NOT EXISTS (SELECT 1
               FROM   customer AS c WITH (NOLOCK)
                      INNER JOIN
                      DBPOLICY.bodb02.dbo.accCustomer_1 AS ac WITH (NOLOCK)
                      ON c.custid = ac.custid
               WHERE  c.custid = @userID
                      AND username = @username
                      AND userpwd = @userpwd)
    BEGIN
        SELECT @ErrMsg = 'Wrong username or password',
               @ErrCode = 101
        RETURN;
    END


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminSelPwdVerify] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminSelPwdVerify] TO [bodbAdminNet]

