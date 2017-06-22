ALTER PROCEDURE [dbo].[Acc_Con_FileNameSelByCustID]
               @CustID  INT,
               @System  VARCHAR(30) = 'ACCOUNTING'
AS

/*
	Created by: Henry
	Date: 2010/July/29
	Task: Get File Name List granted 
	DB: DB03.bodb02 
	
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
		- 20130313@Lukas: return groupid field 
		- 20140109@Johnson: add filter @system to support NAPU3 site [Redmine: #28316]
*/ 
SET NOCOUNT ON

  SELECT   
          distinct gp.groupid, fi.filenames, fi.funcname, (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy
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
  WHERE    mp.custid = @CustID AND
		(Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) > 0
		AND fi.System = @system
		
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FileNameSelByCustID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].Acc_Con_FileNameSelByCustID TO [bodbadminnet]
GO
GRANT EXECUTE ON [dbo].Acc_Con_FileNameSelByCustID TO [bodbExtAccNet]