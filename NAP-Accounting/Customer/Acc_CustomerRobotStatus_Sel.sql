/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerRobotStatus_Sel]
	@custids VARCHAR(4000)
AS
/*
	Created: 20190916@Johnson
	Task : check customer is robot or not
	DB: DBONUSER/ON_USER

	Revisions:
		- 20190916@Johnson: initial sp [redmine:#119714]	
		- 20191029@Johnson: get status by custid instead of username [redmine:#122643]
		- 20200302@Johnson: filter counter >= 10 [redmine:#129484]
		- 20211102@Johnson: check robot with counter > 10 [redmine:#163803ư
*/	
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tmpCust TABLE(custid INT)
	
	INSERT INTO @tmpCust(custid)
	SELECT val 
	FROM dbo.strSplit(@custids,',')
	
	SELECT t.custid, CASE WHEN r.custid IS NULL THEN 0 ELSE 1 END isRobot
	FROM @tmpCust t
		LEFT JOIN RobotUsers r WITH(NOLOCK) ON t.custid = r.custid AND counter >10
			
END
GO