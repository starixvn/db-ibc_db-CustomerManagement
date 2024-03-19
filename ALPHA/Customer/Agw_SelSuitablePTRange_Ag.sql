ALTER PROCEDURE [dbo].[Agw_SelSuitablePTRange_Ag]
	@custid int -- agent custid	
AS
/*

Created: 20090114@QuiNV
Task: Select suitable position taking range for new member
DB: DB05.bodb02
Original:

   Revisions:
	20090522@Lee: Excluding finance
	20100928@Johnson: include number game
	20110119@Daniel: Exclude Mix parlay Basketball when getting suitable PT range for Basketball & others
*/
SET NOCOUNT ON

DECLARE @maxPTPreset smallmoney

DECLARE @minPT1_HDP smallmoney -- 
DECLARE @maxPT1_HDP smallmoney  -- Soccer handicap

DECLARE @minPT1_1x2 smallmoney -- 
DECLARE @maxPT1_1x2 smallmoney  -- Soccer 1x2

DECLARE @minPT1_Live smallmoney -- 
DECLARE @maxPT1_Live smallmoney  -- Soccer live	

DECLARE @minPT161 smallmoney -- 
DECLARE @maxPT161 smallmoney-- Number game

DECLARE @minPT2 smallmoney -- 
DECLARE @maxPT2 smallmoney -- Basket ball and others




-- Max = GET min(custoverride.maxpositiontaking, custoverride.maxlivepositiontaking), sport 1,2,3,5,8,10,11,99
SELECT @maxPTPreset= case when(min(maxpositiontaking) < min(maxlivepositiontaking)) then min(maxpositiontaking) else min(maxlivepositiontaking) end
FROM custoverride with(nolock) 
WHERE custid=@custid and maxpositiontaking<>0 and maxlivepositiontaking<>0 and sporttype in (1,2,3,5,8,10,11,99)

-- Soccer handicap section
SELECT @maxPT1_HDP = min(apositiontaking) 
FROM custsetting with(nolock)
WHERE custid=@custid and sporttype=1 and bettype in (1,2,3,7,8) -- Handicap, Odd/Even, Over/Under, 1st Hdp, 1st OU
SELECT @maxPT1_HDP = case when(@maxPT1_HDP > @maxPTPreset) then @maxPTPreset else @maxPT1_HDP end
-- Min
SELECT @minPT1_HDP= max(minpositiontaking)
FROM custoverride with(nolock) 
WHERE custid=@custid and sporttype=1 and bettype in (1,2,3,7,8)

-- Soccer 1x2 section
SELECT @maxPT1_1x2 = min(apositiontaking) 
FROM custsetting with(nolock)
WHERE custid=@custid and sporttype=1 and bettype in (4,5,6,9,10) -- Correct score, 1x2, Total goal, Mix parlay, Outright
SELECT @maxPT1_1x2 = case when(@maxPT1_1x2 > @maxPTPreset) then @maxPTPreset else @maxPT1_1x2 end
-- Min
SELECT @minPT1_1x2= max(minpositiontaking)
FROM custoverride with(nolock) 
WHERE custid=@custid and sporttype=1 and bettype in (4,5,6,9,10)

-- Soccer live section
SELECT @maxPT1_Live = min(alivepositiontaking)
FROM custsetting with(nolock)
WHERE custid=@custid and sporttype=1 and bettype in (1,3,7,8) -- Handicap, Over/Under, 1st Hdp, 1st OU
SELECT @maxPT1_Live = case when(@maxPT1_Live > @maxPTPreset) then @maxPTPreset else @maxPT1_Live end
-- Min
SELECT @minPT1_Live= max(minlivepositiontaking)
FROM custoverride with(nolock) 
WHERE custid=@custid and sporttype=1 and bettype in (1,3,7,8)


-- Baseball and others
SELECT @maxPT2 = min(apositiontaking)
FROM custsetting with(nolock)
WHERE custid=@custid and (sporttype in(2,3,5,8,10,11,99))
   	AND NOT (sporttype = 2 AND bettype = 9)


SELECT @maxPT2 = case when(@maxPT2 > @maxPTPreset) then @maxPTPreset else @maxPT2 end
-- Min
SELECT @minPT2= max(minpositiontaking)
FROM custoverride with(nolock) 
WHERE custid=@custid and sporttype in(2,3,5,8,10,11,99)
    AND NOT (sporttype = 2 AND bettype = 9)

--Number game
SELECT @maxPT161 = min(apositiontaking)
FROM custsetting3rd with (nolock)  
WHERE custid = @custid and sporttype =161 and bettype in (81,83,85,86) 

SELECT @maxPT161 = case when @maxPT161 > min(alivepositiontaking) then min(alivepositiontaking) else @maxPT161 end
FROM custsetting3rd with (nolock)
WHERE custid = @custid and sporttype= 161 and bettype in (85,86,87)
  
SELECT @minPT161 = max(minpositiontaking)
FROM custoverride3rd with (nolock)  
WHERE custid = @custid and sporttype = 161  

SELECT @minPT161 = case when @minPT161 < max(minlivepositiontaking) then max(minlivepositiontaking) else @minPT161 end
FROM custoverride3rd with (nolock)  
WHERE custid = @custid and sporttype = 161 and bettype in (85,86,87)

SELECT @maxPT161 = case when(@maxPT161 > @maxPTPreset) then @maxPTPreset else @maxPT161 end


SELECT @minPT1_HDP as minPT1_HDP,
	   @maxPT1_HDP as maxPT1_HDP,
	   @minPT1_1x2 as minPT1_1x2,
       @maxPT1_1x2 as maxPT1_1x2,
       @minPT1_Live as minPT1_Live,
       @maxPT1_Live as maxPT1_Live,
       @minPT2 as minPT2,
       @maxPT2 as maxPT2,
       @minPT161 as minPT161,
       @maxPT161 as maxPT161


GO
GRANT EXECUTE ON [dbo].[Agw_SelSuitablePTRange_Ag] TO [bodbDownlineNet,wsv_alp]

GO

GRANT VIEW DEFINITION ON [dbo].[Agw_SelSuitablePTRange_Ag] TO [vnteam]

GO
