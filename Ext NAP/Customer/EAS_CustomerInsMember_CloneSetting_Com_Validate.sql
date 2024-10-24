/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerInsMember_CloneSetting_Com_Validate]
(
	@UserName VARCHAR(30)
	,@Credit MONEY		
	,@ExistingCustid INT
	,@Language VARCHAR(2)= 'E'
	,@IP VARCHAR(15)=''		
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT	
)
AS
/*  
	 Created by: Johnson  
	 Date:20200330 
	 Task: Add new super from existing super for 789y from Ext NAP [Redmine:#130647]
	 DB: DBCUST/CustDB 

	Revisions:  
	- 20240704@Helen: Revise code for scaleout dbcust - [Redmine:199915]

	Explanation's Param:  
	- @ErrCode:
		= 0: Create agent successfully.
		> 0: Specific Error.
	  
	- @ErrMsg: Error description.	 
	 
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE 		
			@CreditRM MONEY
			,@GroupName VARCHAR(50)
	
	EXEC [Acc_CheckUM] @CustID = @ExistingCustid
		,@FunctionType = 2
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT
		,@ReturnUMData = 0
		,@Language = @Language

	IF @ErrCode <> 0 RETURN

	IF @credit <0
	BEGIN
		SELECT  @ErrCode = 2
		SELECT @ErrMsg = 	CASE @Language 
								WHEN 'E' THEN 'Credits must be positive.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](70025,@Language)
							END
		RETURN
	END
		 
	-- Check role of existing super
	DECLARE @existingUsername VARCHAR(30)
			,@roleid tinyint
			,@Enabled BIT

	SELECT @existingUsername =  ISNULL(username,''), 
		@roleid = ISNULL(roleid,0), 
		@Enabled = ISNULL(Enabled, 0)
	FROM dbo.CustInfo WITH(NOLOCK) 
	WHERE custid = @ExistingCustid
	
	IF @roleid <> 4
	BEGIN		
		 SELECT @ErrMsg = CASE @Language 
								WHEN 'E' THEN 'Invalid user' + ' (' + @existingUsername + ')!'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) + ' (' + @existingUsername + ')!'
								END, 
						@ErrCode = 202
		RETURN		
	END		 		
	
	IF @Enabled = 0
	BEGIN		
		 SELECT @ErrMsg = CASE @Language 
								WHEN 'E' THEN 'This account was disabled!' + ' (' + @existingUsername + ')'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](60020,@Language) + ' (' + @existingUsername + ')'
								END, 
						@ErrCode = 203
		RETURN		
	END		 
	
	SELECT @GroupName = GroupName
	FROM Acc_CustGroup WITH(NOLOCK)
	WHERE custid = @ExistingCustid 
		AND GroupName IN ('ACCUT','ACCYEN789','ACCYEN889','ACCTEST')	--789y
	
	--check perfix for new super
	IF ISNULL(@GroupName ,'') <> ''
	BEGIN
		IF NOT EXISTS(SELECT 1 FROM Acc_SuperPrefix WITH(NOLOCK)
			WHERE GroupName = @GroupName
				AND Prefix = LEFT(@Existingusername,2)
				AND AllowNewSuper = 1
			)
		BEGIN
			SELECT @ErrMsg =  'This account does not follow the prefix of the market, please choose another.',
				@ErrCode = 204
			RETURN		
		END	
		
		IF LEFT(@username,2) <> LEFT(@Existingusername,2)
		BEGIN
			SELECT @ErrMsg =  'The new account''s username prefix must follow the original account''s.',
				@ErrCode = 205
			RETURN	
		END
		

		DECLARE 
			@existingMrecommend		INT,
			@existingSrecommend		INT,
			@Prefix					VARCHAR(50),
			@IsQRCode				BIT

		EXEC Acc_CustomerLimitCreatedAccountCheck 
				@Custid = 0 , 
				@RuleID = 'EAS' , 
				@existingMrecommend = 0 , 
				@existingSrecommend = 0 , 
				@Prefix				= '' , 
				@GroupName			= @GroupName , 
				@IsQRCode			= 0 , 
				@SystemID			= 0 , 
				@IP					= @IP ,
				@Credit				= @Credit ,
				@ErrCode			= @ErrCode OUTPUT , 
				@ErrMsg				= @ErrMsg OUTPUT , 
				@Language			= @Language
		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrCode , @ErrMsg
			RETURN		
		END	

	END
		
END 
GO 

