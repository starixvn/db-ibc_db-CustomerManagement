USE [bodb_CustomerLog]
GO
/****** Object:  StoredProcedure [dbo].[NAP_UserLog_UpdateVirtualRateSettings]    Script Date: 11/24/2017 3:14:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.NAP_UserLog_UpdateVirtualRateSettings    Script Date: 9/28/2017 10:27:26 AM ******/


ALTER PROCEDURE [dbo].[NAP_UserLog_UpdateVirtualRateSettings]	 
	 @CreatorId					INT = 0,   
	 @PunterVRSettingsDoc		VARCHAR(MAX),	 
	 @ServiceName				VARCHAR(15),	     
	 @AdjustDate				DATETIME,

	 @ErrCode					INT = 0 OUTPUT,    
	 @ErrMsg					NVARCHAR(200) = '' OUTPUT  
AS
/*
	Created: Long.Luu
	Date: 2016-04-07
	Task : Write log for Auto VR Adjustment
	DB: DBLOG/bodb_CustomerLog
	Original: New One

	Revisions: 
		- 20160525@Thai:	Auto Adjust VR of Losing Member ( Feature #56691)
		- 20170426@Elodie:	When the [VR Auto Adjustment] job runs to update members to +200%, ignore the BA accounts with margin >= 4% [RedmineID:#75075]
		- 20170522@Elodie:	When the [VR Auto Adjustment] job runs to update members to +200%, update VR = 0 for the BA accounts with margin >= 4% [RedmineID:#76701]
		- 20170927@Thai:	Add ServiceName & AdjustDate (Feature #82312)
		- 20181003@Long:	Remove the step of getting BA Info (Feature #102609)

	Param's Explanation:  
		- @PunterVRSettingsDoc = '<ROOT>
									<Rate CustID="123456" ReportDate="2016-04-04" SiteID="22" SRecommend="123" MRecommend="456" Recommend="789" OldVirtualRate="0.2" NewVirtualRate="0.8" />	
									<Rate CustID="7891011" ReportDate="2016-04-05" SiteID="122" SRecommend="21123" MRecommend="11456" Recommend="12789" OldVirtualRate="0.5" NewVirtualRate="0.7" />	
								</ROOT>'
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @idoc INT;

	CREATE TABLE #UserLog (
			CustID			INT
		,	ReportDate		DATE
		,	SiteID			SMALLINT
		,	SRecommend		INT
		,	MRecommend		INT
		,	Recommend		INT
		,	OldVirtualRate	SMALLMONEY
		,	NewVirtualRate	SMALLMONEY
		,	IsBA			BIT
	);

	--Create an internal representation of the XML document.
	EXEC sp_xml_preparedocument @idoc OUTPUT, @PunterVRSettingsDoc;

	INSERT INTO #UserLog(CustID, ReportDate, SiteID, SRecommend, MRecommend, Recommend, OldVirtualRate, NewVirtualRate, IsBA)
	SELECT Data.CustID
		,	ReportDate
		,	SiteID
		,	SRecommend
		,	MRecommend
		,	Recommend
		,	OldVirtualRate
		,	NewVirtualRate
		,	IsBA
	FROM OPENXML (@idoc, '/ROOT/Rate', 1)
		WITH (CustID		INT
		,	ReportDate		DATE
		,	SiteID			SMALLINT
		,	SRecommend		INT											
		,	MRecommend		INT											
		,	Recommend		INT
		,	OldVirtualRate	SMALLMONEY
		,	NewVirtualRate	SMALLMONEY
		,	IsBA			BIT) AS Data;
	
	INSERT INTO dbo.UserLog_VirtualRateSettings(CreatorID, CustID, AdjustDate, ReportDate, SiteID, SRecommend, MRecommend, Recommend, OldVirtualRate, NewVirtualRate, IsBA, ServiceName)
	SELECT	@CreatorId
		,	ul.CustID
		,	@AdjustDate
		,	ul.ReportDate
		,	ul.SiteID
		,	ul.SRecommend
		,	ul.MRecommend
		,	ul.Recommend
		,	ul.OldVirtualRate
		,	CASE WHEN ul.NewVirtualRate = 3 AND ul.IsBA = 1 THEN 1 ELSE NewVirtualRate END
		,	ul.IsBA
		,	@ServiceName
	FROM #UserLog ul WITH(NOLOCK);

	IF @@error <> 0  
	BEGIN    
		SELECT	@ErrMsg = N'Insert logs for Auto Adjust Virtual Rate Settings is failed.' 
			,	@ErrCode = 2209;
		      
		ROLLBACK	      
		RETURN
	END;    

	EXEC sp_xml_removedocument @idoc;
END;