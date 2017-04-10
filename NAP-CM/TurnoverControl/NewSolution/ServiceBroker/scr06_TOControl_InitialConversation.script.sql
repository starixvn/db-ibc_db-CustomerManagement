-----------------------------------------------------------------------------------------
select e.conversation_handle
	 , sc.name as contract_name
	 , st.name as message_type
	 , e.state
from sb.ConversationManagement (nolock) cm
	 inner join sys.conversation_endpoints (nolock) e
		     on e.conversation_handle = cm.ConversationHandle
	 inner join sys.service_contract_message_usages (nolock) scmu
			 on e.service_contract_id = scmu.service_contract_id
	 inner join sys.service_contracts (nolock) sc
			 on scmu.service_contract_id = sc.service_contract_id
	 inner join sys.service_message_types (nolock) st
			 on scmu.message_type_id = st.message_type_id
where e.state = 'SO'
go
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- begin tran
-- rollback
declare @isPrintOrExecute int = 2  -- 1 : print only, 2 : execute

begin
create table #t
(
	ID int identity(1, 1), 
	conversation_handle uniqueidentifier,
	contract_name varchar(500),
	message_type varchar(500)
)

declare @i int = 1		
	  , @cnt int
	  , @Message NVARCHAR(128) = N'Very First Message'
	  , @conversation_handle uniqueidentifier
	  , @contract_name varchar(500)
	  , @message_type varchar(500)
	  , @sql nvarchar(max)

insert into #t(conversation_handle
			 , contract_name
			 , message_type)
select e.conversation_handle
	 , sc.name as contract_name
	 , st.name as message_type
from sb.ConversationManagement (nolock) cm
	 inner join sys.conversation_endpoints (nolock) e
		     on e.conversation_handle = cm.ConversationHandle
	 inner join sys.service_contract_message_usages (nolock) scmu
			 on e.service_contract_id = scmu.service_contract_id
	 inner join sys.service_contracts (nolock) sc
			 on scmu.service_contract_id = sc.service_contract_id
	 inner join sys.service_message_types (nolock) st
			 on scmu.message_type_id = st.message_type_id
where e.state = 'SO'

set @cnt = @@ROWCOUNT
while @i <= @cnt
begin
	select @conversation_handle = conversation_handle
		 , @contract_name = contract_name
		 , @message_type = message_type
	from #t
	where ID = @i;		
	
	set @sql = 
	'
	SEND ON CONVERSATION @conversation_handle
	MESSAGE TYPE ' + @message_type + ' (@Message)
	'
	if @isPrintOrExecute = 1
		print @sql
	else
	begin
		while exists (select top 1 1 
					  from sys.conversation_endpoints
					  where conversation_handle = @conversation_handle
						and state = 'SO')
		begin
			exec sp_executesql @sql
							 , N'@conversation_handle uniqueidentifier
							   , @Message NVARCHAR(128)'
							 , @conversation_handle
							 , @Message						
		end
	end
	
	set @i = @i + 1
end

drop table #t
end
go
-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
select e.conversation_handle
	 , sc.name as contract_name
	 , st.name as message_type
	 , e.state
from sb.ConversationManagement (nolock) cm
	 inner join sys.conversation_endpoints (nolock) e
		     on e.conversation_handle = cm.ConversationHandle
	 inner join sys.service_contract_message_usages (nolock) scmu
			 on e.service_contract_id = scmu.service_contract_id
	 inner join sys.service_contracts (nolock) sc
			 on scmu.service_contract_id = sc.service_contract_id
	 inner join sys.service_message_types (nolock) st
			 on scmu.message_type_id = st.message_type_id
where e.state = 'SO'
go
-----------------------------------------------------------------------------------------