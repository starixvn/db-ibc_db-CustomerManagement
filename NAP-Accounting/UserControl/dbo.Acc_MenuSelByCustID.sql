 ALTER PROCEDURE [dbo].[Acc_MenuSelByCustID]  
	@CustID  INT,
	@System varchar(50) = ''  
                 
AS  
/*
Created by: 
Task : SP select menu by user
DB: DB03.bodb02


Revisions:
Param's Explanation: 
	- 20101129@Steven: change to use acc_functioninfo instead of acc_functioninfo_1
	- 20150112@Johnson: filter function and menu by @sytem to support NAPU3 [Redmine: #28516]
	- 20150114@Johnson: get menu for Beart from accounting
*/
SET NOCOUNT ON

begin
	IF @system = 'Beart'
	BEGIN
		select MenuId, Menu,  url, p.funcname,  parentid, IsNull(Target, '') as Target, IsHide, [Order], System
		from 
		(
			  SELECT     
					  distinct fi.filenames, fi.funcname, (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy  
			  FROM     acc_memberpolicy_1 mp WITH (nolock)  
					   INNER JOIN acccustomer_1 ac WITH (nolock)  
						 ON ac.custid = mp.custid  
					   INNER JOIN acc_functioninfo fi WITH (nolock)  
						 ON mp.funcid = fi.funcid  
					   INNER JOIN customer c WITH (nolock)  
						 ON c.custid = mp.custid  
					   INNER JOIN acc_grouppolicy_1 gp WITH (nolock)  
						 ON gp.groupid = ac.groupid  
							AND gp.funcid = mp.funcid  	
			  WHERE    mp.custid = @CustID   				
				AND (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) > 0  
		) as p inner join Acc_Menu m (nolock) on p.funcname = m.funcname
		where System=@System and IsHide = 0
		order by parentid, [order]
	END
	ELSE
	BEGIN
		select MenuId, Menu,  url, p.funcname,  parentid, IsNull(Target, '') as Target, IsHide, [Order], System
		from 
		(
			  SELECT     
					  distinct fi.filenames, fi.funcname, (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy  
			  FROM     acc_memberpolicy_1 mp WITH (nolock)  
					   INNER JOIN acccustomer_1 ac WITH (nolock)  
						 ON ac.custid = mp.custid  
					   INNER JOIN acc_functioninfo fi WITH (nolock)  
						 ON mp.funcid = fi.funcid  
					   INNER JOIN customer c WITH (nolock)  
						 ON c.custid = mp.custid  
					   INNER JOIN acc_grouppolicy_1 gp WITH (nolock)  
						 ON gp.groupid = ac.groupid  
							AND gp.funcid = mp.funcid  	
			  WHERE    mp.custid = @CustID   
				AND fi.system = @system
				AND (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) > 0  
		) as p inner join Acc_Menu m (nolock) on p.funcname = m.funcname
		where System=@System and IsHide = 0
		order by parentid, [order]
	END
end


GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelByCustID] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelByCustID] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuSelByCustID] TO [vnteam] AS [dbo]



