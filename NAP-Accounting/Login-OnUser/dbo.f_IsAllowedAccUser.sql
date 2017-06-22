ALTER FUNCTION [dbo].[f_IsAllowedAccUser]
(
	@username varchar(50)
)
RETURNS bit
/*
Created: 
Task : Check allowed users accessing main Acc Site
DB: DBTXN/BODB02
Original:

Revisions:
	- 20100609@Daniel: Created
	- 20130118@Elodie: Change link server DB03 to DBPOLICY	

Param's Explanation:
*/
AS
BEGIN
	declare @allowedUser table (username nvarchar(50))
	declare @allowedGroup table (groupname varchar(50))
	declare @custid int, @Groupname nvarchar(50)

	--hard code some user groups can access main acc site
	insert into @allowedGroup
		select 'Finance'
		union all
		select 'Unit 8'	
		
	--hard code some users can access main acc site
	insert into @allowedUser
		select 'sa'
		union all
		select 'Samuel'
		union all
		select 'Khoo2'
		union all
		select 'Thomas'
		union all
		select 'unit8'		
		union all
		select 'dbaThien'
		union all
		select 'dbaVinh'
		union all
		select 'dbaJamie'
		union all
		select 'dbaPhuc'
		union all
		select 'pgmDung'
		union all
		select 'pgmViet'
		union all
		select 'pgmPhuong'
		union all
		select 'pgmShifu'
		union all
		select 'pgmKhoa'
		union all
		select 'pgmHanh'
		union all
		select 'PgmKiwi'
		union all
		select 'pgmTerry'			


	SELECT @CustID = custid FROM customer with (nolock) WHERE username = @UserName
	if (@CustID is null)
	BEGIN
		RETURN 0
	END

	--Get user group
	select @Groupname = GroupName 
	from DBPOLICY.bodb02.dbo.AccCustomer_1 c with (nolock)
		inner join DBPOLICY.bodb02.dbo.Acc_GroupInfo_1 cg with (nolock) on c.GroupID = cg.GroupID
	where c.custid = @custid

	IF((@GroupName NOT IN(select groupname from @allowedGroup)) AND
	  (@username NOT IN(select username from @allowedUser)))
	BEGIN
		RETURN 0
	END

	RETURN 1

END

GO
GRANT EXECUTE ON [dbo].[f_IsAllowedAccUser] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[f_IsAllowedAccUser] TO [vnteam]