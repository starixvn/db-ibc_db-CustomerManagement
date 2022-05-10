/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelUserInfo]
	@CustID INT
AS
/*
Created:
Task : Get User Information
DB: DBCUST.CustDB
Original:Accounting site

Revisions:
	- 20100109@Henry: No need to get currency Name from Exchange since it is not used
	- 20100414@Kiwi: Remove gender and answer
	- 20140519@Logan:	1.Retrieve remark for SAg, MAg, Ag from CustSuper, CustMaster & CustAgent
						2.Code aligning
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	- 20190527@Johnson: add headline info for cn88 [redmine:#112225]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @roleid TINYINT
	DECLARE @remark NVARCHAR(300) = ''

	SELECT @roleid = roleid
	FROM Customer WITH (NOLOCK)
	WHERE custid = @CustID
	 
	IF @roleid = 1 OR @roleid = 0--headline
	BEGIN
		SELECT @remark = remark
		FROM customer WITH (NOLOCK)
		WHERE custid = @CustID
	END
	IF @roleid = 2
	BEGIN
		SELECT @remark = creationRemark
		FROM CustAgent WITH (NOLOCK)
		WHERE custid = @CustID
	END
	IF @roleid = 3
	BEGIN
		SELECT @remark = creationRemark
		FROM CustMaster WITH (NOLOCK)
		WHERE custid = @CustID
	END
	IF @roleid = 4
	BEGIN
		SELECT @remark = creationRemark
		FROM CustSuper WITH (NOLOCK)
		WHERE custid = @CustID
	END

	SELECT 
		c.custid,
		c.username,
		firstname,
		lastname,
		username2,
		address,
		postal,
		city,
		state,
		country,
		phone,
		mobilephone,
		fax,
		email,
		isnull(birthday, '1990/01/01') as birthday,
		refcode1,
		refcode2,
		@remark as remark,
		isnull(important, 0) as important,
		c.currency as exchangeid
	FROM customer c WITH (NOLOCK) inner join custinfo ci WITH (NOLOCK)
		ON c.custid = ci.custid  
	-- left outer join exchange e with (nolock) on c.currency = e.exchangeid  
	WHERE c.custid = @CustID
END
GO

