/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelMaxTransDate]
	@username VARCHAR(50),
	@uplineid INT = -1,
	@isInternalAgent BIT = 0
AS
/*
	Created: 20230922@Bobby
	DB: DBAGE/bodb02
	Task: Alpha - Increase performance of SP to get customer's info

	Revisions:
		- 20230922@Bobby: Init [Redmine: #194274]

	Param's Explanation:
		• @username: username of customer that need to be viewed.   
		• @uplineId: the ID of the upline.
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @custid INT, @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT
		, @transid BIGINT, @transferid BIGINT, @transdate DATETIME;

    SELECT @username = RTRIM(LTRIM(@username))

    SELECT @custid = custid, @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM customer WITH(NOLOCK)
    WHERE username = @username 
	   AND (srecommend = @uplineid OR mrecommend = @uplineid OR recommend = @uplineid)

    ------20110721: If @isInternal = 1 then searching by nickname, else do not allow
    IF (@custid IS NULL) AND @isInternalAgent = 1
    BEGIN
	    SELECT @custid = custid , @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
        FROM customer WITH (NOLOCK)
        WHERE username2 = @username
	       AND (srecommend = @uplineid OR mrecommend = @uplineid OR recommend = @uplineid)
    END
	
	IF (@custid IS NULL) AND @isInternalAgent = 0
	BEGIN
	    SELECT @custid = custid , @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
        FROM customer WITH (NOLOCK)
        WHERE username2 = @username
			AND ((srecommend = @uplineid AND roleid = 3)
				OR (mrecommend = @uplineid AND roleid = 2)
				OR (recommend = @uplineid AND roleid = 1))
    END
    --end
	
    --Check valid access!
    IF @custid > 0
	BEGIN
		IF (@recommend <> @uplineid AND @mrecommend <> @uplineid AND @srecommend <> @uplineid) RETURN
    	
		IF @roleID=1 --for member
		BEGIN	
					
			SELECT @transdate = MAX(x.transdate) 
			FROM
			(
				SELECT MAX(transdate)  AS transdate
				FROM bettrans WITH (NOLOCK) WHERE custid = @custid
				UNION ALL
				SELECT MAX(transdate)  AS transdate
				FROM dbo.transfer WITH (NOLOCK) WHERE custid = @custid
			) x
			OPTION(OPTIMIZE FOR	(@custid = -1))
		END 
		ELSE IF @roleID = 2 --for agent
		BEGIN
						
			SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
			WHERE recommend = @custid
			OPTION(OPTIMIZE FOR	(@custid = -1))

			SELECT @transferid = MAX(transid) FROM dbo.transfer WITH (NOLOCK) 
			WHERE recommend = @custid
				AND bettype NOT IN (20000,19999)
			OPTION(OPTIMIZE FOR	(@custid = -1))
			
			SELECT @transdate = MAX(transdate)
			FROM 
			(
				SELECT  transdate FROM bettrans WITH (NOLOCK) WHERE transid = @transid
				UNION ALL
				SELECT  transdate FROM dbo.transfer WITH (NOLOCK) WHERE transid = @transferid
			) x
		END
		ELSE IF @roleID = 3 --for master
		BEGIN
			
			SELECT @transid = MAX(transid) FROM bettrans WITH (NOLOCK) 
			WHERE mrecommend = @custid
			OPTION(OPTIMIZE FOR	(@custid = -1))

			SELECT @transferid = MAX(transid) FROM dbo.transfer WITH (NOLOCK) 
			WHERE mrecommend = @custid
				AND bettype NOT IN (20000,19999)
			OPTION(OPTIMIZE FOR	(@custid = -1))
			
			SELECT @transdate = MAX(transdate)
			FROM 
			(
				SELECT  transdate FROM bettrans WITH (NOLOCK) WHERE transid = @transid
				UNION ALL
				SELECT  transdate FROM dbo.transfer WITH (NOLOCK) WHERE transid = @transferid
			) x
		END
	END
	
	-------------------------------------------------------------------------
    SELECT @transdate AS MaxTransDate

END	
GO
