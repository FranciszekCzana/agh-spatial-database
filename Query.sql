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
	Tabela dodawa³a siê poprawnie, ale Slowly Changing Dimension nie widzia³ EmployeeKey (?) :(
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
-- Uzupe³nienie kolumny StartDate o czas przekazania wartoœci, EndDate -> NULL


/*
-- 5 b) --
UPDATE stg_dimemp
SET LastName = 'Nowak'
WHERE EmployeeKey = 270;
UPDATE stg_dimemp
SET TITLE = 'Senior Design Engineer'
WHERE EmployeeKey = 274;

-- SSIS --
-- Z rekordem ze zmian¹ w kolumnie Title (Historical attribute)
-- do starego rekordu zosta³a dopisana wartoœæ EndDate
-- Utworzony zosta³ równie¿ nowy wiersz z now¹ wartoœci¹ Title i now¹ wartoœci¹ StartDate
-- Z rekordem ze zmian¹ w kolumnie LastName (Changing attribute)
-- w tabeli scd_dimemp zosta³a zaktualizowana wartoœæ bez zmiany w kolumnach StartDate i EndDate
*/

/*
UPDATE stg_dimemp
SET FirstName = 'Ryszard'
WHERE EmployeeKey = 275;
-- SSIS --
-- Proces jest zablokowany w komponencie Slowly Changing Dimnension,
-- poniewa¿ podczas tworzenia w kreatorze zaznaczono opcjê fail na zmianê Fixed Attribute (tutaj w³aœnie FirstName)
-- Po odznaczeniu danej opcji dane proces wykona siê, jednak w tabeli scd_dimemp nie zajd¹ i tak ¿adne zmiany
*/

SELECT * FROM stg_dimemp;
SELECT * FROM scd_dimemp;
