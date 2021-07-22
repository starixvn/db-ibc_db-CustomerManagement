/*<info serverAlias="DBTXN-CustDB" executers="" selecters="" viewers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20210526@Tina
	Task: add table CustProductStatus to pub CustDB_DBTrans_CustInfo [RedmineID: 148600]
	DB: DBTXN.Custdb
*/
GO
PRINT('Create function f_GenerateProductStatus_multiple')
GO
CREATE FUNCTION [dbo].[f_GenerateProductStatus_multiple] (@bitmap binary(32), @xmlStr varchar(max))   
RETURNS @outputTemp TABLE  
 (  
  bitmap binary(32)  
 )  
AS  
 /*  
  Created: Viet @ 7.OCT.2015  
  DB: DBCust.custDB  
  
  Revision:      
  Param's Explanation:   
   @xmlStr:   
    + FORMAT: <root><r b="" s="" /></root>  
    + r: row  
    + b: bitmapOrder  
    + s: statusValue  
 */  
BEGIN  
	DECLARE @xml XML = CONVERT(XML, @xmlStr)    
	DECLARE @temp AS TABLE (bytepos tinyint, bm_colPos binary(1), bm_statusValue binary(1), rn tinyint primary key)    

	INSERT INTO @temp(bytepos, bm_colPos, bm_statusValue, rn)    
	SELECT 1+((bitmapOrder-1)/8) --bytepos      
		,SUM(POWER(2, 1+((bitmapOrder-1)%8)-1))    
		,SUM(CASE statusValue WHEN 1 THEN POWER(2, 1+((bitmapOrder-1)%8)-1) ELSE 0 END)      
		,ROW_NUMBER() OVER (ORDER BY 1+((bitmapOrder-1)/8))    
	FROM (    
		SELECT bitmapOrder = T.C.value('./@b', 'tinyint')    
			,statusValue = T.C.value('./@s', 'bit')    
		FROM @xml.nodes('/root/r') as [T](C) --T: table, C: column    
		)s    
	GROUP BY 1+((bitmapOrder-1)/8)    

	DECLARE @bytepos tinyint, @bm_colPos binary(1), @bm_statusValue binary(1), @sub_bitmap binary(1)    

	DECLARE @current_rn tinyint = 0    
	WHILE (1 = 1)    
	BEGIN    
		SET @current_rn += 1    

		SELECT @bytepos = bytepos, @bm_colPos = bm_colPos, @bm_statusValue = bm_statusValue    
		FROM @temp    
		WHERE rn = @current_rn    
		IF @@ROWCOUNT = 0 BREAK    

		SET @sub_bitmap = substring(@bitmap, @bytePos, 1)    
		    
		SELECT @sub_bitmap = @sub_bitmap    
		+ CASE @bm_colPos & POWER(2,0) WHEN 0 THEN 0 ELSE POWER(2,0) *(CASE @bm_statusValue & POWER(2,0) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,0) WHEN 0 THEN 0 ELSE 1 END) END    
		+ CASE @bm_colPos & POWER(2,1) WHEN 0 THEN 0 ELSE POWER(2,1) *(CASE @bm_statusValue & POWER(2,1) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,1) WHEN 0 THEN 0 ELSE 1 END) END    
		+ CASE @bm_colPos & POWER(2,2) WHEN 0 THEN 0 ELSE POWER(2,2) *(CASE @bm_statusValue & POWER(2,2) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,2) WHEN 0 THEN 0 ELSE 1 END) END    
		+ CASE @bm_colPos & POWER(2,3) WHEN 0 THEN 0 ELSE POWER(2,3) *(CASE @bm_statusValue & POWER(2,3) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,3) WHEN 0 THEN 0 ELSE 1 END) END    
		+ CASE @bm_colPos & POWER(2,4) WHEN 0 THEN 0 ELSE POWER(2,4) *(CASE @bm_statusValue & POWER(2,4) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,4) WHEN 0 THEN 0 ELSE 1 END) END    
		+ CASE @bm_colPos & POWER(2,5) WHEN 0 THEN 0 ELSE POWER(2,5) *(CASE @bm_statusValue & POWER(2,5) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,5) WHEN 0 THEN 0 ELSE 1 END) END    
		+ CASE @bm_colPos & POWER(2,6) WHEN 0 THEN 0 ELSE POWER(2,6) *(CASE @bm_statusValue & POWER(2,6) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,6) WHEN 0 THEN 0 ELSE 1 END) END    
		+ CASE @bm_colPos & POWER(2,7) WHEN 0 THEN 0 ELSE POWER(2,7) *(CASE @bm_statusValue & POWER(2,7) WHEN 0 THEN 0 ELSE 1 END - CASE @sub_bitmap & POWER(2,7) WHEN 0 THEN 0 ELSE 1 END) END    
		  
		SET @bitmap = CONVERT(binary(32), STUFF(@bitmap, @bytePos, 1, @sub_bitmap))     
	END     

	INSERT INTO @outputTemp(bitmap)  
	SELECT @bitmap  

	RETURN  
END


GO
PRINT('Create function f_GenerateSuspendInfo')
GO
CREATE FUNCTION dbo.f_GenerateSuspendInfo(@bitOrder TINYINT,@suspend BIT,@SuspendInfo TINYINT)
RETURNS TABLE
AS 
/*
	Created by:Johnson
	Date:2019-04-08
	Task: get downlines suspend info status
	DB: DBCUST/CustDB
	
	Revisions:
		- 20190408@Johnson: initial sp [redmine: #105587]
	Parameter's Explanation:
	
*/
RETURN(SELECT CASE WHEN @suspend = 1 THEN @SuspendInfo|power(2,@bitOrder-1)
			ELSE @SuspendInfo&(CASE @bitOrder WHEN 4 THEN 7 WHEN 3 THEN 11 WHEN 2 THEN 13 WHEN 1 THEN 14 END) END
		as suspendInfo		
	)
GO

GO
PRINT('Create function f_CustSetting_ProductStatusSel')
GO
CREATE FUNCTION	dbo.f_CustSetting_ProductStatusSel (
					@bitmap			BINARY(32)
				,	@bitmapOrder	TINYINT
				)  
RETURNS TABLE
AS
/*
	Created:	20160415@Billy
	Database:	DBCust/CustDB,DBCTS/bodb02
	
	Revision:
		-20160415@Billy : Initial SP [Redmine: #121876]

	Param's Explanation:
*/
RETURN
	SELECT	CAST(	CASE SUBSTRING(@bitmap, 1 + ((@bitmapOrder - 1) / 8), 1) & POWER(2, (@bitmapOrder - 1) % 8)
						WHEN 0 THEN 0
						ELSE 1
					END AS BIT
			) value
GO

PRINT('Create function f_GetInfoStatus')
GO
CREATE FUNCTION dbo.f_GetInfoStatus(@StatusInfo TINYINT)
RETURNS TABLE
AS 
/*
	Created by:Tina
	Date:2021-05-06
	Task: get close info status
	DB: DBCUST/CustDB
	
	Revisions:
		- 20210506@Tina: All Sites - Lock account & indirect close account [redmine: #148600]
	Parameter's Explanation:
*/
	RETURN(SELECT CASE WHEN @StatusInfo&power(2,3) > 0 THEN 1 ELSE 0 END AS SuperStatus,
				  CASE WHEN @StatusInfo&power(2,2) > 0 THEN 1 ELSE 0 END AS MasterStatus,
				  CASE WHEN @StatusInfo&power(2,1) > 0 THEN 1 ELSE 0 END AS AgentStatus,
				  CASE WHEN @StatusInfo&power(2,0) > 0 THEN 1 ELSE 0 END AS MemberStatus)
GO
GO