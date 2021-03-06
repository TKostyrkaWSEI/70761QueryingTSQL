USE [AdventureworksDW2016CTP3];
GO

--	(1)
--	przygotować raport który porównuje wykonanie danego 
--	kraju do wykonania całości w obrębie konta
--	np. Koszty w Polsce to 10, koszty w całej organizacji to 200 - pokazać 10, 200 i 5%
---------------------------------------------------------------------

--	pogrupowane dane po Typie/Organizacji
---------------------------------------------------------------------


	SELECT 
		a.AccountType		, 
		o.OrganizationName	,
		SUM(f.Amount)		AS [Amount]
	INTO #Dane
	FROM 
				[dbo].[FactFinance]		AS	f
	INNER JOIN	[dbo].[DimAccount]		AS	a	ON a.AccountKey			= f.AccountKey
	INNER JOIN	[dbo].[DimOrganization]	AS	o	ON o.OrganizationKey	= f.OrganizationKey
	GROUP BY
		a.AccountType		, 
		o.OrganizationName		

	SELECT *
	FROM #Dane
	ORDER BY AccountType, OrganizationName

--	Agregaty - sumy bez podziału na organizację do porównania
---------------------------------------------------------------------

	SELECT 
		a.AccountType		, 
		SUM(f.Amount)		AS [Amount]
	INTO #DaneAggr
	FROM 
				[dbo].[FactFinance]		AS	f
	INNER JOIN	[dbo].[DimAccount]		AS	a	ON a.AccountKey			= f.AccountKey
	INNER JOIN	[dbo].[DimOrganization]	AS	o	ON o.OrganizationKey	= f.OrganizationKey
	GROUP BY
		a.AccountType

--	
---------------------------------------------------------------------

	SELECT *
	FROM #Dane
	ORDER BY AccountType, OrganizationName

	SELECT *
	FROM #DaneAggr
	ORDER BY AccountType

--	zestawienie wykonania z agregatami
---------------------------------------------------------------------

	SELECT d.AccountType,
           d.OrganizationName,
           d.Amount, 
           a.Amount	,
		   ROUND(100 * d.Amount / a.Amount,2)
	FROM #Dane AS d
	INNER JOIN #DaneAggr AS a ON a.AccountType = d.AccountType
	ORDER BY d.AccountType, d.OrganizationName

--	(2)
--	Przygotować raport narastający (YTD - Year Till Date)
--	prezentujący wyniki do daty a nie w dacie
--	tylko na kategorii 'Revenue'
---------------------------------------------------------------------

	SELECT 
		CAST(f.[Date] AS DATE)			AS [Date],
		a.AccountType					AS [AccountType], 
		CAST(SUM(f.Amount) AS MONEY)	AS [Amount]
	INTO #Revenue
	FROM 
				[dbo].[FactFinance]		AS	f
	INNER JOIN	[dbo].[DimAccount]		AS	a	ON a.AccountKey			= f.AccountKey
	WHERE a.AccountType = 'Revenue'
	AND YEAR(f.[Date]) = 2012
 	GROUP BY
		f.[Date]			,
		a.AccountType
	ORDER BY f.[Date]

	SELECT *
	FROM #Revenue AS f
	ORDER BY f.[Date]

--	łączymy dwa razy to samo na warunku <= 
--	potem przykombinować z CASE, żeby nie zliczało wielokrotnie
---------------------------------------------------------------------

	SELECT *
	FROM #Revenue AS f
	INNER JOIN #Revenue AS f2 ON f2.Date <= f.Date
	ORDER BY f.[Date]

--	
---------------------------------------------------------------------

	SELECT f.[Date],
           f.[AccountType],
           SUM(	CASE 
					WHEN f.[Date] = f2.[Date]
					THEN f.[Amount]
					ELSE 0
					END	) AS Amount,
           SUM(f2.[Amount]	) AS AmountCumulative
	FROM #Revenue AS f
	INNER JOIN #Revenue AS f2 ON f2.Date <= f.Date
	GROUP BY f.[Date],
           f.AccountType
	ORDER BY f.[Date]

--	w kolejnym skrypcie to samo, ale prościej za pomocą funkcji okna
--	...
--	...
--	...