/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
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
DB: DBCUST/CUSTDB
Original:

Revisions:    
	- 20130125@Elodie: Change link server DB03 to DBPOLICY
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]

*/
SET NOCOUNT ON
SELECT @ErrCode = 0
IF NOT EXISTS (SELECT 1
               FROM   customer AS c WITH (NOLOCK)
                      INNER JOIN
                      NAP_UserControl.dbo.accCustomer AS ac WITH (NOLOCK)
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
GRANT EXECUTE ON [dbo].[Acc_Con_AdminSelPwdVerify] TO [bodbAdminNet,wsv_nap]

