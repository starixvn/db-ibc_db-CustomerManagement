/*<info serverAlias="DBCust-CustDB" selecters="svc_tig" viewers="" isFunction="1"></info>*/

ALTER FUNCTION [dbo].[f_SetValueBitmap_multiple] (@bitmap BINARY(128), @ProductsOffer VARCHAR(max))   
RETURNS @outputTemp TABLE ( bitmap BINARY(32) )  
AS  
 /*  
  Created:	20231002@Winfred
  Database:	DBCust/CustDB,DBTP-bodb02
  Original: f_GenerateProductStatus_multiple
  
  Revision:     
		- 20231002@Winfred: [NAP CM] Customer Class - Support for Non-Sports [RedmineID: #186116] 
  Param's Explanation: 
  
   @ProductsOffer : '3,8,18,28,40,63,256' 
     
 */  
BEGIN  
	DECLARE @temp AS TABLE (bytepos smallint, bm_colPos binary(1), bm_statusValue binary(1), rn smallint primary key)    

	INSERT INTO @temp(bytepos, bm_colPos, bm_statusValue, rn)    
	SELECT 1+((bitmapOrder-1)/8) --bytepos      
		,SUM(POWER(2, 1+((bitmapOrder-1)%8)-1))    
		,SUM(CASE statusValue WHEN 1 THEN POWER(2, 1+((bitmapOrder-1)%8)-1) ELSE 0 END)      
		,ROW_NUMBER() OVER (ORDER BY 1+((bitmapOrder-1)/8))    
	FROM (    
		SELECT DISTINCT VALUE AS bitmapOrder, 1 AS statusValue
		FROM STRING_SPLIT(@ProductsOffer,',') 
		WHERE VALUE <> ''
		)s    
	GROUP BY 1+((bitmapOrder-1)/8)    

	DECLARE @bytepos smallint, @bm_colPos binary(1), @bm_statusValue binary(1), @sub_bitmap binary(1)    

	DECLARE @current_rn smallint = 0    
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