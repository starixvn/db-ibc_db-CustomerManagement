/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_CustomerDetectCustId
    @SearchText VARCHAR(30) = '',
	@CustId INT = NULL OUTPUT
AS
/*  
    Created: 20191115@Elodie
    Task: Detect custid from search text on Left panel of NAP
    DB: DBACC/bodb02
    
    Revisions:
        - 20191115@Elodie: Detect custid from search text on Left panel of NAP [Redmine: #123918]
    Param's Explanation:
    
    Example:
		DECLARE @CustId INT
        EXEC Acc_CustomerDetectCustId @SearchText='MKW2RMB26', @CustId = @CustId OUTPUT
		SELECT @CustId
 */  
BEGIN
    IF @SearchText <> ''
    BEGIN
		--Search username first
		SELECT @CustId = custid 
		FROM dbo.Customer c WITH (NOLOCK) 
        WHERE c.username = @SearchText AND roleid IN (0,1,2,3,4)

		IF @CustId IS NULL
		BEGIN
			--Search nickname if there is not username
			SELECT @CustId = custid 
			FROM dbo.Customer c WITH (NOLOCK) 
			WHERE c.username2 = @SearchText AND roleid IN (0,1,2,3,4)
			
			IF @CustId IS NULL AND ISNUMERIC(@SearchText) = 1				
			BEGIN
				IF LEN(@SearchText) BETWEEN 1 AND 9 OR (LEN(@SearchText) = 10 AND @SearchText <= '2147483647') --check overflow 
				BEGIN
					--Search custid if there is not nickname
					SELECT @CustId = custid 
					FROM dbo.Customer c WITH (NOLOCK) 
					WHERE c.custid = CAST(@SearchText AS INT) AND roleid IN (0,1,2,3,4)
				END
			END
		END
    END    
END
GO
