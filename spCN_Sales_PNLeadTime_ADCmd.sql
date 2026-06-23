SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--========================================================
-- CDBA_SP_Framework : 2021.1028.1800
--========================================================

-- ==========================================================================================
/*
   Author:				Jacky Lai
   Create date:			2023-08-22
   Description:			Auto Distribution for China DG MOLEX / Oplink PN Lead Time
   Last Update date:	2026-06-18
   Data Source List:	[MRS_Auto].[dbo].[FISCALMONTH]
						[MRS].[dbo].[tblMasterMaterial_Plant]
						[MRS].[dbo].[vwBB_nonMFI]
*/
-- ==========================================================================================

ALTER PROCEDURE [spCN_Sales_PNLeadTime_ADCmd]
	----------------------------------------------------------
	-- Input Parameters
	@SoldToCode AS VARCHAR(20)
	,@FMPeriod AS VARCHAR(20) 
	----------------------------------------------------------

AS
BEGIN

	SET NOCOUNT ON;

    BEGIN TRY
	
		----------------------------------------------------------
		-- ~~~~~~ Line Number ~~~~~~
		LINENO 40
		----------------------------------------------------------

		DECLARE @SPName varchar(100) = OBJECT_NAME(@@PROCID)
		DECLARE @Database varchar(20) = DB_NAME()
		DECLARE @User varchar(50) = SYSTEM_USER
		DECLARE @SP_ID bigint
		EXEC MRS_Admin..spServer_SPRunningLog @SPName,@Database,@User,'Start','',@ID=@SP_ID OUTPUT

		----------------------------------------------------------
		-- Comment block for drop temp tables, for debugging
		/*
		IF OBJECT_ID('tempdb.dbo.#temp_MaterialMaster', 'U') IS NOT NULL DROP TABLE #temp_MaterialMaster;
		IF OBJECT_ID('tempdb.dbo.#Raw', 'U') IS NOT NULL DROP TABLE #Raw;
		*/
		----------------------------------------------------------

		----------------------------------------------------------
		-- ~~~~~~ Declaration of variables ~~~~~~
		DECLARE @start_FM AS VARCHAR(20) = [MRS_Auto].[dbo].[FISCALMONTH](Getdate(), @FMPeriod)
		DECLARE @end_FM AS VARCHAR(20) = [MRS_Auto].[dbo].[FISCALMONTH](Getdate(), 0)
		-- ~~~~~~ Declaration of variables ~~~~~~
		----------------------------------------------------------

		----------------------------------------------------------
		-- ~~~~~~ Code ~~~~~~
		SELECT DISTINCT [Manufacturer Part Number]
		      ,[Plant]
		      ,[Planned Deliv. Time]
		      ,[MOQ]
		      ,[MPQ]
		      ,[Avnet Canc Win]
		      ,[Avnet Resch. Window]
		      ,[Supplier Cancel Wind]
		      ,[Supplier Resch Wind]
		      ,[NCNR Indicator]
		      ,[ABC Indicator]
		      ,[HS Code]
		INTO #temp_MaterialMaster
		FROM [MRS].[dbo].[tblMasterMaterial_Plant] WITH(NOLOCK)
		WHERE [Deletion Flag] = ''

		SELECT DISTINCT a.[Plant Code]
		      ,a.[Manufacturer Part Number]
		      ,a.[Material]
		      ,a.[Customer Material]
		      ,b.[Planned Deliv. Time]
		      ,b.[MOQ]
		      ,b.[MPQ]
		      ,b.[Avnet Canc Win]
		      ,b.[Avnet Resch. Window]
		      ,b.[NCNR Indicator]
		      ,b.[Supplier Cancel Wind]
		      ,b.[Supplier Resch Wind]
		      ,b.[ABC Indicator]
		      ,b.[HS Code]
		      ,a.[ECCN Number]
		FROM [MRS].[dbo].[vwBB_nonMFI] a WITH(NOLOCK)
		      LEFT JOIN #temp_MaterialMaster b
		            ON a.[Plant Code] = b.[Plant]
		              AND a.[Manufacturer Part Number] = b.[Manufacturer Part Number]
		WHERE a.[Sold to Party Code] = @SoldToCode
		  AND a.[Region] = 'China'
		  AND a.[Fiscal Month] BETWEEN @start_FM AND @end_FM
		  AND a.[Qty] > 0

		-- ~~~~~~ Code ~~~~~~
		----------------------------------------------------------

		EXEC MRS_Admin..spServer_SPRunningLog @SPName,@Database,@User,'Finish','',@SP_ID

	END TRY
	BEGIN CATCH

		DECLARE @Error varchar(max) = 'Line ' + CONVERT(varchar,ERROR_LINE()) + ': ' + ERROR_MESSAGE()
		EXEC MRS_Admin..spServer_SPRunningLog @SPName,@Database,@User,'Finish',@Error,@SP_ID;

		THROW

	END CATCH

END
GO
