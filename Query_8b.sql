-- Dla każdego dnia wyświetl 3 produkty, których cena jednostkowa (UnitPrice) była największa

SELECT OrderDate, dim_product.EnglishProductName, UnitPrice FROM (
	SELECT OrderDate, ProductKey, UnitPrice,
	ROW_NUMBER () OVER (
		PARTITION BY OrderDate
		ORDER BY UnitPrice DESC
	) row_rank
	FROM [dbo].[FactInternetSales]
) fct_internet_sales
JOIN [dbo].[DimProduct] dim_product ON fct_internet_sales.ProductKey = dim_product.ProductKey
WHERE row_rank <= 3
ORDER BY OrderDate, row_rank;