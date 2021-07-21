/*<info serverAlias="DBAGE-bodb02" executers="bodbadminNet,bodbDownlineNet,bodbExtaCCNet" viewers="" isFunction="0"  ></info>*/
CREATE PROCEDURE [dbo].[SLI_CustomerSelAllInfo]
	@username VARCHAR(30),
	@CheckCustId TINYINT = 0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg Varchar(500) = '' OUTPUT
AS

/*
Created: Tiara
Task : Get Customer general information
DB: DBAGE/bodb02
Original: Acc_CustomerSelAllInfo

Revisions:
	- 20200107@Tiara: Get Customer general info to display on U3 site [Redmine: #123584]
	- 20201202@Winfred: Check Customer credit archived on U3 site [Redmine: #123584]
Param's Explanation:
	@username: username want to get all info related
*/		

BEGIN
    SET NOCOUNT ON

    DECLARE @Custid INT	  
          , @roleid TINYINT

    --Get CustID from DB06, where got index on Username aND Username2 or CustID
    EXEC @Custid = DBACC.bodb02.dbo.f_GetCustIDFromUsernameOrCustId @username, @CheckCustId

	SELECT @ErrCode = 0, @ErrMsg = ''

    IF @Custid is NULL
    BEGIN
		IF EXISTS(SELECT 1 FROM Dep_Customer_archived (NOLOCK) WHERE Username=@username)
		BEGIN
			SELECT @ErrMsg = 'This deposit customer has been archived.'
			SELECT @ErrCode = 1

			RETURN
		END
		ELSE
		BEGIN
			SELECT @ErrMsg = 'The ' + @username +' is not found.'
			SELECT @ErrCode = 1 
			RETURN
				
		END 	
    END
    ELSE
    BEGIN
	    SELECT @roleid = roleID
	    FROM Custinfo WITH(NOLOCK)
	    WHERE Custid = @Custid
    END							  									  										  							  
    ---------------------------------------------------------------------------
	--General info
    SELECT C.Custid,
		C.username, 
		C.firstname, C.lastname, 
	    C.username2, 		
	    CI.roleid, 
	    CI.Enabled,
	    C.phone, 
		C.mobilephone, 
		C.fax, 
	    C.site
    FROM Customer C WITH(NOLOCK)
	    INNER JOIN Custinfo CI WITH(NOLOCK) ON C.Custid = CI.Custid
		OUTER APPLY f_CS_GetCustomerStatus(@Custid) CS		
    WHERE C.Custid = @Custid

    -------------------------------------------------------------------------
    --Agency info
    SELECT CASE WHEN C.roleid = 1 THEN C.Custid ELSE NULL END AS memberID,
	    CASE WHEN C.roleid = 1 THEN C.username ELSE NULL END AS memberName,								    		
	    A.Custid AS agentID,
	    A.username AS agentName,	
	    A.Enabled AS agentEnabled,
	    M.Custid AS masterID,
	    M.username AS masterName,
	    M.Enabled AS masterEnabled,
	    S.Custid AS superID,
	    S.username AS superName,
	    S.Enabled AS superEnabled
    FROM Custinfo C WITH(NOLOCK)
	    LEFT JOIN Custinfo A WITH(NOLOCK) on C.recommend = A.Custid
	    LEFT JOIN Custinfo M WITH(NOLOCK) on C.mrecommend = M.Custid
	    LEFT JOIN Custinfo S WITH(NOLOCK) on C.srecommend = S.Custid
    WHERE
	    C.Custid = @Custid
  
END

GO
