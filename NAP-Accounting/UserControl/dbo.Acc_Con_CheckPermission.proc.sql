ALTER PROCEDURE [dbo].[Acc_Con_CheckPermission]
	@CustID int, 
	@FuncID int=null,
	@FuncName nvarchar(50)='',
	@System nvarchar(50) = 'ACCOUNTING',
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by: []
	Task: Check permission by CustID and Function 
	DB: DB03.BODB02
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
		- 20110526@Tom: Remove condition @System
*/
	SET NOCOUNT ON 
	IF @FuncID is null
		Select @FuncID=funcid from acc_functioninfo with(nolock) where System = @System and FuncName=@Funcname
	
	-- Permission: bitwise(OR) permission of the group that user belong to and permission of this user
	-- IsAllow: 1:Readonly, 2:Host, 3:All
	-- Just check permission for admin, ignore when roleid < 5 
	Declare @roleid tinyint,@IsAllow tinyint
	Select @roleid = roleid From customer with(nolock) where custid=@custid
	IF @RoleID Between 5 and 10
		BEGIN 
			SELECT @IsAllow=(isnull(mp.policy,0)|isnull(gp.policy,0)) & isnull(fi.FuncRender,0)
			FROM AccCustomer_1 ac with(nolock) inner join custinfo ci with(nolock) on ac.custid=ci.custid
				Left JOIN acc_functioninfo fi with(nolock) on fi.funcid=@funcid
				LEFT JOIN Acc_MemberPolicy_1 mp with(nolock) on mp.custid=ac.custid and mp.funcid=@funcid
				LEFT JOIN Acc_GroupPolicy_1 gp with(nolock) on gp.groupid=ac.groupid and gp.funcid=@funcid
			WHERE ac.Custid=@Custid and ci.closed=0
			SELECT @IsAllow = isnull(@IsAllow,0)		
		END
	ELSE IF @Roleid > 1
		BEGIN
			SELECT @IsAllow=2
		END 
	ELSE
		SELECT @IsAllow=0
		
	IF @IsAllow <2
	BEGIN
		SELECT @ErrMsg =  case @Language
							when 'E' then N'You are not authorized on this function'
							when 'CS' then N'You are not authorized on this function'
							when 'J' then N'You are not authorized on this function'
							else N'You are not authorized on this function'
							--else N'You are not authorized to create/edit this information'
						end, @ErrCode = 500
		RETURN 
	END
	ELSE
		SET @ErrCode=0
	

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_CheckPermission] TO [vnteam]	
GO
GRANT EXECUTE ON [dbo].[Acc_Con_CheckPermission] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_CheckPermission] TO [bodbExtAccNet]
Go
GRANT EXECUTE ON [dbo].[Acc_Con_CheckPermission] TO [bodbDownlineNet]
	
