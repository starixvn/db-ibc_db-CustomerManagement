USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_GetDownlineTurnOver_Setting_Change]    Script Date: 01/26/2015 03:48:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_GetDownlineTurnOver_Setting_Change]
	@GetOption char(1) = '' -- C/D : Change/Delete
AS
--SELECT custid, matchid, maxturnover, totalturnover from dbo.DownlineTurnOver_Setting
--GO

	SET NOCOUNT ON
	
	--SELECT custid, matchid, maxturnover, totalturnover
	--FROM @temp
	DELETE FROM DownlineTurnOver_Setting_tmp

	IF @GetOption = 'D'
		DELETE D
		OUTPUT deleted.custid, deleted.matchid INTO DownlineTurnOver_Setting_tmp (custid, matchid)
		FROM dbo.DownlineTurnOver_Setting_Delete D
	ELSE IF @GetOption = 'C'
	BEGIN
		Declare @GetValue sql_variant, @Last_tstamp binary(8), @Max_tstamp binary(8)
		
		EXEC sp_GetGlobalVariable 'TurnOver_Last_tstamp', @GetValue OUTPUT, 1
		SET @Last_tstamp = CONVERT(binary(8), @GetValue)
		
		INSERT INTO DownlineTurnOver_Setting_tmp (custid, matchid, maxturnover, totalturnover, houseturnover, tstamp)
		SELECT custid, matchid, maxturnover, totalturnover, houseturnover, tstamp
		FROM dbo.DownlineTurnOver_Setting with (nolock)
		WHERE tstamp > @Last_tstamp
		
		
		SELECT @Max_tstamp = MAX(tstamp) FROM DownlineTurnOver_Setting_tmp
		IF @Max_tstamp IS NOT NULL
			EXEC sp_SetGlobalVariable 'TurnOver_Last_tstamp', @Max_tstamp
	END
	
	SET NOCOUNT OFF
	

GO


