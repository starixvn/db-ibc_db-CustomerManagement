Deployed
DBTXN-CUSTDB:Age_CustomerSelWinLimitList_Ag
o
*********************************
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Age_CustomerSelWinLimitList_Ag    Script Date: 9/9/2015 4:12:38 PM ******/
ALTER PROCEDURE [dbo].[Age_CustomerSelWinLimitList_Ag]
    @CustID int,
    @PageSize int=500,
    @PageIndex int=1,
    @Username varchar(30)=null,
    @Enabled bit = null,
    @Closed bit=null,
    @Suspended bit = null    
AS

/*
Created By: Dan
Created Date: 2012-09-27 
Task : Win Limit of members
DB: DBTXN/CustDB
Original: [Age_CustomerSelCreditBalanceList_Ag]

Revisions:    
    - 20121026@Jamie: Set WinLimit = 0 in case Credit = 0 
    - 20130708@Viet: create new param @_username to resolve parameter sniffing's issue.
    - 20131108@Elodie: Splitting bodb02 into CustDB (Call BalanceCreditGame, BalanceDebitGame by link database)
    - 20140905@Lukas: change the order of queries to reduce IO on custinfo 
    - 20141203@Lukas: use maxdop to avoid parallel processing -> reduce cpu resource
    - 20150908@Viet: enhance SP
Param's Explanation:
• @CustID: AgentID
*/
--return 
BEGIN
    SET NOCOUNT ON

    DECLARE @RowCount int, @RowStart int, @RowEnd int
    SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

    DECLARE @_Username varchar(30)
    SET @_Username = isnull(@Username, '')

    SELECT RowNumber
        ,c.custid
        ,c.username
        ,CASE 
            WHEN c.MaxWinLiveCasino = 0 THEN - 1 -- unlimited
            WHEN bc.Balance - bd.balance > 0 THEN (bc.Balance - bd.balance) * 100 / c.MaxWinLimit
        ELSE 0 END AS LCSWinPercent
    FROM (    
            SELECT custid, username, enabled, closed, isnull(reject,0) as suspended, MaxWinLiveCasino, 
                    CASE WHEN credit = 0 THEN 1 ELSE MaxWinLiveCasino*credit END as MaxWinLimit,
                    RowNumber = ROW_NUMBER() OVER (ORDER BY enabled desc, closed, isnull(reject,0), username)
            FROM CustInfo WITH(NOLOCK, INDEX=IX_custinfo_1) 
            WHERE recommend = @CustID
                AND roleid = 1
                AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
                AND isnull(closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(closed, 0)) end
                AND isnull(reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(reject, 0))end
                AND username LIKE '%' + @_Username + CASE @_Username WHEN '' THEN '' ELSE '%' END
            ) c
        LEFT JOIN (
            SELECT custid, ISNULL(SUM(balance),0) as balance
            FROM bodb02.dbo.BalanceCreditGame WITH(NOLOCK)
            GROUP BY custid
        ) bc ON c.custid = bc.custid     
        LEFT JOIN (
            SELECT custid, ISNULL(SUM(balance),0) as balance
            FROM bodb02.dbo.BalanceDebitGame WITH(NOLOCK)
            GROUP BY custid
        ) bd ON c.custid = bd.custid    
    WHERE RowNumber BETWEEN @RowStart AND @RowEND
    ORDER BY RowNumber
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelWinLimitList_Ag] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelWinLimitList_Ag] TO [bodbDownlineNetView,wsv_alpv]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelWinLimitList_Ag] TO [wsv_alp]
GO 
