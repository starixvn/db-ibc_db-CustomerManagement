/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[CS_Acc_CustomerInfo_HeadlineSel]
	@custid INT
AS
/*
	Created: 20190425@Johnson
	Task : Get headline info for cn88
	DB: DBAGE/bodb02
	
	Revisions:
		- 20190425@Johnson: initial sp [redmine: 105338]
		
	Param's Explanation:		
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE  
			@roleID TINYINT,
			@TotalSAgentActive INT,
		    @TotalSAgentClosed INT,
		    @TotalSAgentSuspended INT, 
			@TotalMAgentActive INT,
		    @TotalMAgentClosed INT,
		    @TotalMAgentSuspended INT,
		    @TotalAgentActive INT,
		    @TotalAgentClosed INT,
		    @TotalAgentSuspended INT,
		    @TotalMemberActive INT,
		    @TotalMemberClosed INT,
		    @TotalMemberSuspended INT,
			@LastChangedSecurityCodeDate DATETIME
			
	DECLARE @tblSupers TABLE(CustID INT)
		
	SELECT @roleid = roleID
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @roleid <> 0
		RETURN
	
	INSERT INTO @tblSupers(custid)
	SELECT custid
	FROM CustSuper WITH(NOLOCK)
	WHERE uplineID = @custid
	
	SELECT @TotalSAgentActive =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 4 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
	                          ELSE 0
	                        END
	                       ), 0
	                   )
	         , @TotalSAgentClosed =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 4 AND Closed = 1 THEN 1
	                          ELSE 0 END
	                       ), 0
	                   )
             , @TotalSAgentSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 4 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
			,@TotalMAgentActive =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 3 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
	                          ELSE 0
	                        END
	                       ), 0
	                   )
	         , @TotalMAgentClosed =
	             ISNULL(SUM(CASE
	                          WHEN RoleID = 3 AND Closed = 1 THEN 1
	                          ELSE 0 END
	                       ), 0
	                   )
             , @TotalMAgentSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 3 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentActive =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentClosed =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND Closed = 1 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalAgentSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 2 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberActive =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND Closed = 0 AND ISNULL(reject, 0) = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberClosed =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND Closed = 1 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
             , @TotalMemberSuspended =
                 ISNULL(SUM(CASE
                              WHEN RoleID = 1 AND ISNULL(reject, 0) = 1 AND Closed = 0 THEN 1
                              ELSE 0
                            END
                           ), 0
                       )
	FROM dbo.custInfo WITH(NOLOCK)
	WHERE srecommend IN (SELECT custid FROM @tblSupers)
	
	SELECT @LastChangedSecurityCodeDate = LastChangedSecurityCodeDate
	FROM DBCUST.CustDB.dbo.CustLoginInfo WITH(NOLOCK)
	WHERE custid = @custid
		
	SELECT custid,
		roleID,
		username,
		e.currency,
		firstname,
		lastname,
		username2,
		phone, 
		mobilephone, 
		fax,
		site,
		lastlogged,
		c.creatdate as createdate,
		iplogin lastloginip, 
	    pwdexpiry, 
		@LastChangedSecurityCodeDate as LastChangedSecurityCodeDate
	FROM customer c WITH(NOLOCK)
		INNER JOIN exchange e WITH(NOLOCK) on c.currency = e.exchangeid
	WHERE custid = @custid	
	
	--hardcode to return data table for web to map current model
	SELECT custID as CustID, Enabled as headlineEnabled
	FROM custinfo (NOLOCK)
	WHERE custid = @custid 
	
	--hardcode to return data table for web to map current cash table
	SELECT 0 as Cash
	
	SELECT @TotalSAgentActive SAgentActive,
		@TotalSAgentClosed SAgentClosed,
		@TotalSAgentSuspended SAgentSuspended,
		
		@TotalMAgentActive MAgentActive,
		@TotalMAgentClosed MAgentClosed,
		@TotalMAgentSuspended MAgentSuspended,
		
		@TotalAgentActive AgentActive,
		@TotalAgentClosed AgentClosed,
		@TotalAgentSuspended AgentSuspended,
		
		@TotalMemberActive MemberActive,
		@TotalMemberClosed MemberClosed,
		@TotalMemberSuspended MemberSuspended
	
	--hardcode to return data table for web to map current Product status table
	SELECT 0 as ProductID 
	
END
GO

