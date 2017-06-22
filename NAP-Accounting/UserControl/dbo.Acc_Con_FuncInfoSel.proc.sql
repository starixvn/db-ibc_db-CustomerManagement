ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoSel]
	@system varchar(50) = 'ACCOUNTING'
AS
/*
Task: Select function Info 
DB: DB03.BODB02 

Revision
	Shifu@20100612: Get function files by system type
	-Henry@20100714: Allow to search by System (Default: ACCOUNTING)
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20150112@Johnson: change default system is Accounting [Redmine: #28979]
*/

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



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoSel] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].Acc_Con_FuncInfoSel TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].Acc_Con_FuncInfoSel TO [bodbExtAccNet]
GO