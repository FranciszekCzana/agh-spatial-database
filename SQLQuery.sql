-- =========================================
-- Główną różnicą między sposobami są głównie operatory: ||/&& vs. OR/AND, == vs. LIKE, "" vs. ''.
-- Podczas pisania kwerendy łatwiej na boku przetestować funkcje daty i porównać.
-- W ETL trudniej było zbadać, dlaczego Porównanie atrybutu Date do GETDATE()-8 zwraca 0 wyników (różnica godzin :) )
-- W ETL również prawdopodobnie nie ma funkcji CONVERT, a CAST nie chciał działać, co też komplikowało sposób wykonania zadania.
-- Choć sporą (acz tylko subiektywną) przewagą kwerend jest po prostu przyzwyczajenie do konsolowych wersji pisania skryptów.
-- =============================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Czana
-- Create date: 04/11/2020
-- Description:	Shows GBP and EUR values @YearsAgo from actual day
-- =============================================
CREATE PROCEDURE CurrencyRateXYearsAgo 
	-- Add the parameters for the stored procedure here
	@YearsAgo int = 8
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- CONVERT here is used to get full date without hours and minutes

	SELECT cr.AverageRate, cr.EndOfDayRate, dc.CurrencyAlternateKey , cr.date
	FROM dbo.FactCurrencyRate AS cr 
	JOIN dbo.DimCurrency AS dc ON cr.CurrencyKey = dc.CurrencyKey
	WHERE (dc.CurrencyAlternateKey LIKE 'EUR' OR dc.CurrencyAlternateKey LIKE 'GBP')
	AND CONVERT(VARCHAR(10), cr.date, 103) LIKE CONVERT(VARCHAR(10), DATEADD(year, @YearsAgo*(-1),GETDATE()), 103);
	
END
GO

