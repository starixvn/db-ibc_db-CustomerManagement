/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerBetSettingMultipleCheck]  
	@GroupName	VARCHAR(50),
	@UserID		INT,
    @SourceUser	VARCHAR(30)='', 
	@DestUsers	VARCHAR(MAX),  
	@IsCopy		BIT=1,
	@Errcode	INT=0 OUTPUT,
	@ErrMsg		NVARCHAR(MAX)='' OUTPUT
AS  
/*  
	Creator: 20230515@Tacy  
	Task : Validate source and destination supers before updating Bet Settings.
	DB: DBCUST/CustDB

	Revisions:  
		- 20230515@Tacy: EXT NAP - Allow headlines update Bet Settings on multiple supers [Redmine:#186773]
	
	Param's Explanation:
		* @IsCopy : 1 ~ Tab Copy Bet Setting
				    0 ~ Tab Edit Bet Setting

	Example:	
		
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @GroupID INT

	CREATE TABLE #DestUsers (CustID INT NULL, UserName VARCHAR(30))

	IF EXISTS (SELECT 1 FROM STRING_SPLIT(@DestUsers, ',') 
				WHERE TRIM(value)<>'' AND LEN(TRIM(value))>30)
	BEGIN
		SELECT  @Errcode=97,
				@ErrMsg='Invalid super account(s): '
						+ STUFF ((SELECT ', ' + TRIM(value)
								  FROM STRING_SPLIT(@DestUsers, ',') 
								  WHERE TRIM(value)<>'' AND LEN(TRIM(value))>30
								  FOR XML PATH('')),1,1,'')
		RETURN
	END

	INSERT INTO #DestUsers (CustID, UserName)
	SELECT c.custid, TRIM(value)
	FROM string_split(@DestUsers, ',') 
	LEFT JOIN Customer c WITH (NOLOCK) ON c.username=TRIM(value)
	WHERE TRIM(value)<>''

	SELECT @GroupID=GroupID
	FROM DBPOL.NAP_UserControl.dbo.eaUserInfo ui WITH (NOLOCK)
	WHERE ui.UserID=@UserID

	--check: headline (admin) belongs to current Group?
	IF @GroupID NOT IN (1,2)	--IT/Finance 
	AND
		(NOT EXISTS (SELECT 1 FROM DBPOL.NAP_UserControl.dbo.eaUserInfo ui WITH (NOLOCK)
					INNER JOIN DBPOL.NAP_UserControl.dbo.eagroup g WITH (NOLOCK) ON g.GroupID=ui.GroupID
					WHERE ui.UserID=@UserID AND g.GroupName=@GroupName)
		AND NOT EXISTS (SELECT 1 FROM DBPOL.NAP_UserControl.dbo.eaUserInfo ui WITH (NOLOCK)
					INNER JOIN DBPOL.NAP_UserControl.dbo.eagroup g WITH (NOLOCK) ON g.ParentID=ui.GroupID
					WHERE ui.UserID=@UserID AND g.GroupName=@GroupName))
	BEGIN
		SET @Errcode=98
		SET @ErrMsg='This Headline does not belong to ' + @GroupName + ' group'
		RETURN
	END

	-- Source username
	IF @IsCopy=1
	BEGIN
		IF (@SourceUser IS NULL OR @SourceUser='')
		BEGIN
			SET @Errcode=99
			SET @ErrMsg='Please input source super'
			RETURN
		END
		ELSE
		BEGIN
			--check: single source account
			IF EXISTS (SELECT 1 FROM STRING_SPLIT(@SourceUser,',') WHERE TRIM(value)<>'' HAVING COUNT(1)>1)
			BEGIN
				SET @Errcode=100
				SET @ErrMsg='Please input a single source super'
				RETURN
			END

			--check: source account is not super's username, invalid, disable, dummy
			IF NOT EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE username=@SourceUser)
				OR EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE (roleid<>4 OR Enabled=0) AND username=@SourceUser)
				OR EXISTS (SELECT 1 FROM Customer c WITH (NOLOCK)
							INNER JOIN Acc_CustDirect cd WITH (NOLOCK) ON c.custid=cd.custid
							WHERE c.username=@SourceUser)	--Dummy
			BEGIN
				SET @Errcode=101
				SET @ErrMsg='Invalid source super'
				RETURN
			END

			--check: source account belongs to Group of current Headline?
			IF NOT EXISTS (SELECT 1 FROM Acc_CustGroup ag WITH (NOLOCK)
							INNER JOIN Customer c WITH (NOLOCK) ON ag.CustID=c.custid
							WHERE c.UserName=@SourceUser AND ag.GroupName=@GroupName)
			BEGIN
				SET @Errcode=112
				SET @ErrMsg='Invalid source super'
				RETURN
			END

			--check: source account is among the destination ones
			IF EXISTS (SELECT 1 FROM #DestUsers WHERE UserName=@SourceUser)
			BEGIN
				SET @Errcode=103
				SET @ErrMsg='Source Super and destination Super are duplicated: ' + @SourceUser
				RETURN
			END
		END
	END

	--Destination username
	IF @DestUsers IS NULL OR @DestUsers=''
	BEGIN
		SET @Errcode=104
		SET @ErrMsg='Please input destination super'
		RETURN
	END

	--check: duplicate destination account
	IF EXISTS (SELECT 1 FROM #DestUsers GROUP BY UserName HAVING COUNT(1)>1)
	BEGIN
		SET @Errcode=105
		SET @ErrMsg='Duplicate super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM #DestUsers d  
							  GROUP BY UserName 
							  HAVING COUNT(1)>1
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END 

	--check: destination account is invalid username
	IF EXISTS (SELECT 1 FROM #DestUsers WHERE custid IS NULL)
	BEGIN
		SET @Errcode=106
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM #DestUsers d  
							  WHERE custid IS NULL
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	--check: destination accounts are not super
	IF EXISTS (SELECT 1 FROM #DestUsers d  
				INNER JOIN Customer c WITH (NOLOCK) ON d.custid=c.custid
				WHERE c.roleid<>4)
	BEGIN
		SET @Errcode=107
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM #DestUsers d  
							  INNER JOIN Customer c WITH (NOLOCK) ON d.custid=c.custid
							  WHERE c.roleid<>4
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	--check: destination accounts are disabled
	IF EXISTS (SELECT 1 FROM #DestUsers d  
				INNER JOIN custInfo c WITH (NOLOCK) ON d.custid=c.custid
				WHERE c.Enabled=0)
	BEGIN
		SET @Errcode=108
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM #DestUsers d  
							  INNER JOIN custInfo c WITH (NOLOCK) ON d.custid=c.custid
							  WHERE c.Enabled=0
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	--check: destination accounts are dummy
	IF EXISTS (SELECT 1 FROM #DestUsers d  
				INNER JOIN Acc_CustDirect cd WITH (NOLOCK) ON d.custid=cd.custid)
	BEGIN
		SET @Errcode=109
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM #DestUsers d  
							  INNER JOIN Acc_CustDirect cd WITH (NOLOCK) ON d.custid=cd.custid
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END
		
	--check: source account belongs to Group of current Headline?
	IF EXISTS (SELECT 1 FROM #DestUsers d WITH (NOLOCK)
				LEFT JOIN Acc_CustGroup ag WITH (NOLOCK) ON ag.CustID=d.custid
														AND ag.GroupName=@GroupName
				WHERE ag.CustID IS NULL)
	BEGIN
		SET @Errcode=113
		SET @ErrMsg='Invalid super account(s): ' 
					+ STUFF ((SELECT ', ' + d.UserName
							  FROM #DestUsers d  
							  LEFT JOIN Acc_CustGroup ag WITH (NOLOCK) ON ag.CustID=d.custid
														AND ag.GroupName=@GroupName
							  WHERE ag.CustID IS NULL
							  ORDER BY d.UserName
							  FOR XML PATH('')),1,1,'')
		RETURN
	END

	--check: the number of the destination accounts exceeds 50
	IF EXISTS (SELECT 1 FROM #DestUsers HAVING COUNT(1)>50)
	BEGIN
		SET @Errcode=111
		SET @ErrMsg='The function can only edit up to 50 accounts per request.'
		RETURN
	END

	IF @Errcode=0
	BEGIN
		IF @IsCopy=1
		BEGIN
			SELECT CustID
			FROM Customer WITH (NOLOCK)
			WHERE username=@SourceUser
			UNION ALL 
			SELECT CustID
			FROM #DestUsers
		END
		ELSE
			SELECT CustID
			FROM #DestUsers
	END
END
GO