/*
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE name ='stg_dimemp')
BEGIN
	DROP TABLE stg_dimemp;
	SELECT EmployeeKey, FirstName, LastName, Title
	INTO stg_dimemp
	FROM DimEmployee
	WHERE EmployeeKey BETWEEN 270 AND 275;
END

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE name ='scd_dimemp')
BEGIN
	DROP TABLE scd_dimemp;

	/*
	SELECT TOP 0 * INTO scd_dimemp FROM stg_dimemp;
	ALTER TABLEscd_dimemp ADD STARTDATE DATETIME, ENDDATE DATETIME;
	Tabela dodawa�a si� poprawnie, ale Slowly Changing Dimension nie widzia� EmployeeKey (?) :(
	*/

	CREATE TABLE scd_dimemp (
		EmployeeKey INT,
		FirstName NVARCHAR(50),
		LastName NVARCHAR(50),
		Title  NVARCHAR(50),
		StartDate DATETIME, 
		EndDate DATETIME
	);
END
*/

-- 5 a) --
-- SSIS --
-- Uzupe�nienie kolumny StartDate o czas przekazania warto�ci, EndDate -> NULL


/*
-- 5 b) --
UPDATE stg_dimemp
SET LastName = 'Nowak'
WHERE EmployeeKey = 270;
UPDATE stg_dimemp
SET TITLE = 'Senior Design Engineer'
WHERE EmployeeKey = 274;

-- SSIS --
-- Z rekordem ze zmian� w kolumnie Title (Historical attribute)
-- do starego rekordu zosta�a dopisana warto�� EndDate
-- Utworzony zosta� r�wnie� nowy wiersz z now� warto�ci� Title i now� warto�ci� StartDate
-- Z rekordem ze zmian� w kolumnie LastName (Changing attribute)
-- w tabeli scd_dimemp zosta�a zaktualizowana warto�� bez zmiany w kolumnach StartDate i EndDate
*/

/*
UPDATE stg_dimemp
SET FirstName = 'Ryszard'
WHERE EmployeeKey = 275;
-- SSIS --
-- Proces jest zablokowany w komponencie Slowly Changing Dimnension,
-- poniewa� podczas tworzenia w kreatorze zaznaczono opcj� fail na zmian� Fixed Attribute (tutaj w�a�nie FirstName)
-- Po odznaczeniu danej opcji dane proces wykona si�, jednak w tabeli scd_dimemp nie zajd� i tak �adne zmiany
*/

SELECT * FROM stg_dimemp;
SELECT * FROM scd_dimemp;
