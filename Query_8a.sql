-- Pokaż jedynie dni (wraz z liczbą zamówień) w których było mniej niż 100 zamówień,

SELECT * FROM (
	SELECT OrderDate, COUNT(OrderDateKey) as Order_cnt
	FROM [dbo].[FactInternetSales]
	GROUP BY OrderDate 
) fct_internet_sales
WHERE Order_cnt < 100
ORDER BY Order_cnt DESC