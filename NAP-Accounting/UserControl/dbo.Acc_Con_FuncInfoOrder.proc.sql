ALTER PROCEDURE  [dbo].[Acc_Con_FuncInfoOrder]
	@FuncID int, 
	@OrderNo int
AS

/*
	Created by: []
	Task: Re-order sub-function 
	DB: DB03.BODB02 
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1

*/

SET NOCOUNT ON
--used to re-order sub-function
declare 
	@ParentID int,
	@FuncCount int,
	@c int
	
declare @tmp table (funcID int, DisplayOrder tinyint)	
	
select @ParentID = ParentID from acc_functioninfo with (nolock) 
where funcID = @FuncID and funcID <> ParentID
if (@ParentID is null) return--invalid sub-function

--Count functions
select @FuncCount = count(*) from acc_functioninfo with (nolock)
where parentid = @ParentID and FuncID <> ParentID

if (@OrderNo < 1 or @OrderNo > @FuncCount) return --invalid order position

if (@OrderNo = 1)
begin
	insert into @tmp(funcID)
	select funcID from acc_functioninfo with (nolock)
	where funcID = @funcID
	
	insert into @tmp(funcID)
	select funcID from acc_functioninfo with (nolock)
	where parentid = @ParentID and FuncID <> ParentID and funcID <> @funcID
	order by displayorder
end
else if (@OrderNo = @FuncCount)
begin
	insert into @tmp(funcID)
	select funcID from acc_functioninfo with (nolock)
	where parentid = @ParentID and FuncID <> ParentID and funcID <> @funcID
	order by displayorder

	insert into @tmp(funcID)
	select funcID from acc_functioninfo with (nolock)
	where funcID = @funcID
end
else
begin
	insert into @tmp(funcID)
	select top (select @OrderNo-1) funcID from acc_functioninfo with (nolock)
	where parentid = @ParentID and FuncID <> ParentID and funcID <> @funcID
	order by displayorder

	insert into @tmp(funcID)
	select funcID from acc_functioninfo with (nolock)
	where funcID = @funcID
	
	insert into @tmp(funcID)
	select funcID from acc_functioninfo with (nolock)
	where 
		parentid = @ParentID and FuncID <> ParentID
		and funcID not in(select funcID from @tmp)
	order by displayorder
end

select @c = 0
update @tmp set @c = @c + 1, displayorder = @c 

update acc_functioninfo set displayorder = t.displayorder
from @tmp t inner join acc_functioninfo with (nolock) on t.funcID = acc_functioninfo.funcID

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoOrder] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoOrder] TO [bodbAdminNet]
