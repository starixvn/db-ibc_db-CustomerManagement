/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoSel]
	@system varchar(50) = 'ACCOUNTING'
AS
/*
Task: Select function Info 
DB: DBCUST/NAP_UserControl

Revision
	Shifu@20100612: Get function files by system type
	-Henry@20100714: Allow to search by System (Default: ACCOUNTING)
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20150112@Johnson: change default system is Accounting [Redmine: #28979]
	- 20180808@Helen: DB05.DBPOLICY migration  [Redmine:99462]
*/
BEGIN
	SET NOCOUNT ON

	IF @system = 'ALL'
	BEGIN
		select acc.FuncId, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames, acc.parentid, count(acc1.funcID) as SubFuncCount,acc.System
		from 
			acc_functioninfo acc with (nolock)
			left join acc_functioninfo acc1 with (nolock) on acc.funcID = acc1.ParentID and acc1.parentid <> acc1.funcid
		--where acc.[system] = @system
		group by acc.FuncId, acc.parentid, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames,acc.System
		order by acc.System,acc.parentid, SubFuncCount desc, acc.DisplayOrder
	END
	ELSE
	BEGIN
		select acc.FuncId, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames, acc.parentid, count(acc1.funcID) as SubFuncCount,acc.System
		from 
			acc_functioninfo acc with (nolock)
			left join acc_functioninfo acc1 with (nolock) on acc.funcID = acc1.ParentID and acc1.parentid <> acc1.funcid
		where acc.[system] = @system
		group by acc.FuncId, acc.parentid, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames,acc.System
		order by acc.System,acc.parentid, SubFuncCount desc, acc.DisplayOrder
	END	
END


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoSel] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].Acc_Con_FuncInfoSel TO [bodbAdminNet,wsv_nap]
GO
GRANT EXECUTE ON [dbo].Acc_Con_FuncInfoSel TO [wsv_xnap]
GO