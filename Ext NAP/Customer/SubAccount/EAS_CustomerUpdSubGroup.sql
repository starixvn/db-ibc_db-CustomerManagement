/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerUpdSubGroup]  
    @CustList	VARCHAR(MAX)
	,@GroupName VARCHAR(50)
	,@IsCheck 	BIT
	,@IP 	 	NVARCHAR(15) = ''
	,@userid 	INT
	,@errCode 	INT = 0 OUTPUT
	,@errMsg 	NVARCHAR(200) = '' OUTPUT
AS
/*	Created 20200804@Johnson  
	Task : Customer list assign supers to sub groups
	DB: DBCUST/CustDB
	
	Revisions:  
		- 20200804@Johnson: initial sp [redmine:#136501]
	
	Parameter's explanation:
		- @GroupName: sub group need to assign supers
		- @CustList : list custid need to update sub group
*/		
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
			
	DECLARE @tmpCust TABLE(custid INT, roleid INT, isValid BIT DEFAULT 0, isCheck BIT DEFAULT 0, isFinished BIT DEFAULT 0)
	
	SELECT @startRun = GETDATE()
	
	INSERT INTO @tmpCust(custid)
	SELECT val 
	FROM strSplit (@CustList,',')
	
	UPDATE t
	SET isValid = 1
		,isCheck = CASE WHEN c.custid IS NOT NULL THEN 1 ELSE 0 END
		,t.roleid = ci.roleid
	FROM @tmpCust t 		
		INNER JOIN custinfo ci WITH(NOLOCK) ON t.custid = ci.custid
		LEFT JOIN Acc_CustGroup c WITH(NOLOCK) ON t.custid = c.custid
												AND GroupName = @GroupName
	
	--delete un-change list
	DELETE @tmpCust 
	WHERE isCheck = @isCheck 
		OR isValid = 0 
		OR roleid <> 4
	
	IF @isCheck = 1
	BEGIN
		INSERT INTO Acc_CustGroup(custid,roleid,GroupName)
		SELECT custid, roleid, @GroupName
		FROM @tmpCust
	END
	ELSE
	BEGIN
		DELETE Acc_CustGroup WITH(UPDLOCK,ROWLOCK)
		WHERE custid IN (SELECT custid FROM @tmpCust)
			AND GroupName = @GroupName
	END
	
	--logging
	DECLARE @custid INT,
		@LogSPData VARCHAR(MAX),
		@TrackingValue2 VARCHAR(MAX)
	
	SELECT @LogSPData = '<EAS_CustomerUpdSubGroup						
						GroupName="'+ coalesce(@GroupName,space(1))+'" '+
						'isCheck="'+ coalesce(CAST(@isCheck AS VARCHAR(1)),space(1))+'" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" />'
						
	SELECT @TrackingValue2 = '<EAS_CustomerUpdSubGroup						
						GroupName="'+ coalesce(@GroupName,space(1))+'" '+
						'isCheck="'+ coalesce(CAST(CASE WHEN @isCheck = 1 THEN 0 ELSE 1 END AS VARCHAR(1)),space(1))+'" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" />'
	
	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	
	WHILE (1=1)
	BEGIN
		UPDATE TOP (1) t
		SET @custid = custid,	
			isFinished = 1
		FROM @tmpCust t
		WHERE isFinished = 0
		
		IF @@ROWCOUNT = 0
			BREAK;
		
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 95031,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration	
	END		
END


