ALTER PROCEDURE dbo.Acc_CustomerSelCheckAllowedDownlines  
	@custid			int = 0   
	,@roleid		int = 0  
	,@isExecRep		bit = 0  
	,@isUpdatePT	bit	= 0 
	,@sporttype		int = 0 
	,@Language		varchar(2) = 'E'  
	,@ErrCode		int = 0 output  
	,@ErrMsg		nvarchar(200) = '' output    
AS  
  
/*  
Created by: Scott        
Date: 2012-12-06        
Task : Check Allowed downlines during peak hour at weekend    
DB: DBCUST/CustDB        
Original SP:         

Revisions:       
	- 20130809@Jamie: Apply checking for Min/Max PT UPDATEs
		+ Change message error to bodb02 of DBAGE instead of DBLOG
	- 20140614@Viet: special arrrangment for WC 2014
	- 20160601@Billy:	Special arrangement for EC2016 - [Redmine: 58621]

Param's Explanation: 
	+ @isUpdatePT: 1: Update Min/Max PT
	+ @sporttype: 1: Sportsbook 
 
*/  
  
BEGIN  
 	SET NOCOUNT ON  	
			
	DECLARE @LimitDownlinesMin int,   --Peak hours 
	  @LimitDownlinesMax int,		  -- Normal 
	  @LimitDownlines int,  
	  @TotalDownlines int  
	  
	IF @isExecRep = 0 
	BEGIN
		SET @LimitDownlinesMin = 5000  
		SET @LimitDownlinesMax = 20000  	
		
		 IF @isUpdatePT = 1 AND @sporttype = 1  -- Sportsbook Update Min/Max PT 
		 BEGIN
			SELECT	 @LimitDownlinesMin = 2000
					,@LimitDownlinesMax = 5000 		
		 END
	END   
	ELSE IF @isExecRep = 1  
	BEGIN  
		SET @LimitDownlinesMin = 50000  
		SET @LimitDownlinesMax = 200000  
		 
		IF @isUpdatePT = 1 AND @sporttype = 1  -- Sportsbook Update Min/Max PT 
		BEGIN
			SELECT	 @LimitDownlinesMin = 10000
					,@LimitDownlinesMax = 20000 
		END  
	END  
	  
	--GET TOTALDOWNLINE  
	set @TotalDownlines=1  
	  
	IF @roleid = 4   
	BEGIN  
	 SELECT  @TotalDownlines = count(1)   
	 FROM Custinfo WITH (NOLOCK)  
	 WHERE srecommend=@custID  
	END  
	IF @roleid = 3   
	BEGIN  
	 SELECT  @TotalDownlines = count(1)   
	 FROM Custinfo WITH (NOLOCK)  
	 WHERE mrecommend=@custID  
	END  
	IF @roleid = 2   
	BEGIN  
	 SELECT  @TotalDownlines = count(1)   
	 FROM Custinfo WITH (NOLOCK)  
	 WHERE recommend=@custID  
	END  
	/*  	  
	SELECT  @LimitDownlines = CASE  WHEN 
										datename(weekday, getdate()) in ('Saturday','Sunday') and 
											--datepart(hour, getdate()) between 7 and  14 --Weekend's peak hour, from 7PM - 2AM (GMT+8)	  
											datepart(hour, getdate()) between 0 and  23 --Weekend's peak hour
										THEN  @LimitDownlinesMin  
									ELSE @LimitDownlinesMax  END   
	*/
	-- BEGIN:	20140614@Viet:	special arrrangment for WC 2014		----
	--			20160601@Billy:	Special arrangment for EC 2016		----
	IF DATEPART(HOUR, GETDATE()) between 8 and 18	---- 08:00 -> 18:00	(PROD Time	GMT - 04:00)
													---- 19:00 -> 05:00	(VN Time	GMT + 07:00)
													---- 20:00 -> 06:00	(TW Time	GMT + 08:00)
	BEGIN
		SET @LimitDownlines = @LimitDownlinesMin 
	END
	ELSE 
	BEGIN
		SET @LimitDownlines = @LimitDownlinesMax 
	END
	--END: 20140614@Viet: special arrrangment for WC 2014 ----
	
	  
	IF @TotalDownlines >  @LimitDownlines  
	BEGIN       
		SELECT	@ErrMsg= CASE @Language WHEN 'E' THEN 'This function is not available during peak hour since it might affect the performance of the whole system. Please contact IT for further assistance.'
										ELSE dbo.f_Get_MsgNamebyMsgID(90010,@Language) END
				,@ErrCode = 113 	     
	END   
END
