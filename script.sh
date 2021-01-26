#!/bin/bash

: <<'NOTES'
Utworzono: 2020/01/13
Zmodyfikowano: 2020/01/26

Skrypt majacy na celu pobranie pliku pod linkiem, przeprowadzenie walidacji danych, wyslanie raportu o rezultacie na dany adres email wraz z zalaczonym plikiem csv poprawnych wartosci.

Parametrami funkcji do edycji sa ponizsze zmienne ograniczone rzedem znakow #####
Zdecydowano sie na taki manewr ze wzgledu na ulatwienie edycji poszczegolnych elementow zamiast zgodnosci z kolejnymi numerami parametrow $1 $2 $3 itd.

Skrypt wymaga zainstalowanego programu mysql do zarzadzania baza danych.
Obecnie dostepna baza wymaga polaczenia VPN zgodny z siecia AGH

Usluga wysylania wiadomosci programem mailx wymaga wczesniejszego skonfigurowania ustawien uslugi w systemie (ssmtp)
NOTES

## Parametry uzywane podczas dzialania skryptu
######################################################## 
# Link bezposredniego dostepu do zadanego pliku
FILE_LINK="http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip"
# Haslo do zaszyfrowanej paczki
FILE_PASSWORD="bdp2agh"

# Nazwa logu
LOG_FILENAME="processing"
#Sciezka do pliku "old", zawierajacego juz inne dane
OLD_FILENAME="InternetSales_old.txt"

# Parametry dostepu do bazy mysql 
SQL_HOSTNAME="mysql.agh.edu.pl"
SQL_USERID="czana"
SQL_DATABASE="czana"
SQL_PASSWORD="ZUhwNUFZdHV0amU0YkY3dQo="

INDEX_NUMBER="290900"
# Odbiorca wiadomosci email
EMAIL_RECEIVER="czana@student.agh.edu.pl"

# Czas wykonania (MMDDYYYY)
TIMESTAMP=$(date +%m%d%Y)
########################################################

# Przygotowanie wyjscia
mkdir -p "PROCESSED"
log_file="PROCESSED/${LOG_FILENAME}_${TIMESTAMP}.log"
echo "$(date +%m%d%Y%H%M%S) -- START" > ${log_file}

## Pobieranie pliku
wget -q -O ./file.zip $FILE_LINK
if [ $? -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas pobierania pliku!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%m%d%Y%H%M%S) -- Pobieranie pliku -- OK" >> ${log_file}

## Rozpakowanie pliku
file_name=`unzip -Z -1 ./file.zip`
unzip -o -qq -P $FILE_PASSWORD -d ./ ./file.zip
if [ $? -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas rozpakowywania pliku!" 2>> ${log_file}
    exit 1
fi
rm ./file.zip
echo "$(date +%m%d%Y%H%M%S) -- Rozpakowywanie pliku -- OK" >> ${log_file}

## Walidacja danych
bad_file="PROCESSED/InternetSales_new.bad_${TIMESTAMP}"
processed_file="${TIMESTAMP}_${file_name}"

head -n 1 $file_name | awk -F '|' '{OFS=FS}{ $3="First_Name|Last_Name"; print }' > ${processed_file}

# Liczba kolumn w naglowku pliku
header_len=`awk -F '|' '{ print NF }' $file_name | head -n 1`

# Usuniecie naglowka z badanego pliku
sed '1d' InternetSales_new.txt > tmp && mv tmp $file_name

# Calkowita liczba przetwarzanych danych
total_cnt=`awk 'END{ print NR }' $file_name`

# Puste linie
awk 'NF == 0' $file_name > $bad_file
awk 'NF != 0' $file_name > tmp && mv tmp $file_name

# Duplikaty w pliku zrodlowym
awk 'seen[$0]++' $file_name >> $bad_file
awk '!seen[$0]++' $file_name > tmp && mv tmp $file_name

# Linie z rozna liczba kolumn niz w naglowku
awk -v len="$header_len" -F '|' '{ if (NF != len) { print $0 } }' $file_name >> $bad_file
awk -v len="$header_len" -F '|' '{ if (NF == len) { print $0 } }' $file_name > tmp && mv tmp $file_name

# OrderQuantity - wartosci wieksze od 100
awk -F '|' '{ if ($5 > 100) { print $0 } }' $file_name >> $bad_file
awk -F '|' '{ if ($5 <= 100) { print $0 } }' $file_name > tmp && mv tmp $file_name

# Linie zawarte juz starym pliku
duplicate_cnt=`awk 'FNR==NR {a[$0]; next} ($0 in a)' $OLD_FILENAME $file_name | wc -l`
awk 'FNR==NR {a[$0]; next} ($0 in a)' $OLD_FILENAME $file_name >> $bad_file
awk 'FNR==NR {a[$0]; next} !($0 in a)' $OLD_FILENAME $file_name > tmp && mv tmp $file_name

# Wartosc w SecretCode
awk '{ gsub(/[ \r\n\t]/, ""); print }' $file_name | awk -F '|' '{OFS=FS}{ if ($7 != "") { $7=""; print $0 }}' >> $bad_file
awk '{ gsub(/[ \r\n\t]/, ""); print }' $file_name | awk -F '|' '{OFS=FS}{ if ($7 == "") { print $0 }}' > tmp && mv tmp $file_name

# Customer_Name w blednej formie
# Poddalem sie tutaj w wyszukiwaniu innego sposobu na ten sam efekt bez wyrazenia regularnego :(
awk -F '|' '{ if ( $3 !~ "^\".+,.+\"$" ) { print } }' $file_name >> $bad_file
awk -F '|' '{ if ( $3 ~ "^\".+,.+\"$" ) { print } }' $file_name > tmp && mv tmp $file_name

# Customer_Name => First Name + Last Name
awk -F '|' '{OFS=FS}{ gsub(/\"/, ""); split($3, tab, ","); $3=(tab[2] "|" tab[1]); print }' $file_name > tmp && mv tmp $file_name

# Zamiana , na . w kolumnie zawierajacej cene (dla zgodnosci z baza danych)
awk -F '|' '{OFS=FS}{ gsub(/,/, ".", $7); print }' $file_name > tmp && mv tmp $file_name

# Zliczenie dobrych i odrzuconych wartosci
bad_cnt=`cat $bad_file | wc -l`
processed_cnt=`cat $file_name | wc -l`

if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas przetwarzania danych!" 2>> ${log_file}
    exit 1
fi
echo -e "$(date +%Y%m%d%H%M%S) -- Przetwarzanie i walidacja danych -- OK \n Przetworzono $total_cnt linii (bez naglowka) \n Poprawnych: $processed_cnt, blednych: $bad_cnt (w tym $duplicate_cnt duplikatow ze starego pliku)" >> ${log_file}

## Przygotowanie hasla do bazy
export MYSQL_PWD=`echo $SQL_PASSWORD | base64 --decode`

## Tworzenie tabeli w bazie MYSQL
sql_table_name="CUSTOMERS_${INDEX_NUMBER}"
create_table_query="CREATE TABLE IF NOT EXISTS ${sql_table_name}( ProductKey INT, CurrencyAlternateKey VARCHAR(255), First_Name VARCHAR(255), Last_Name VARCHAR(255), OrderDateKey VARCHAR(255), OrderQuantity INT, UnitPrice FLOAT, SecretCode VARCHAR(255));"
mysql -u $SQL_USERID -D $SQL_DATABASE -h $SQL_HOSTNAME -e "$create_table_query"
echo "MYSQL QUERY: ${create_table_query}" >> ${log_file}
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas tworzenia tabeli w mysql!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Tworzenie tabeli w bazie MYSQL -- OK" >> ${log_file}

## Ladowanie danych do tabeli MYSQL
load_data_query="LOAD DATA LOCAL INFILE '$file_name' INTO TABLE ${sql_table_name} FIELDS TERMINATED BY '|';"
echo "MYSQL QUERY: ${load_data_query}" >> ${log_file}
mysql -u $SQL_USERID -D $SQL_DATABASE -h $SQL_HOSTNAME -e "$load_data_query"
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas ladowania danych do tabeli mysql!" 2>> ${log_file}
    exit 1
fi

get_table_cnt_query="SELECT COUNT(*) FROM ${sql_table_name};"
echo "MYSQL QUERY: ${get_table_cnt_query}" >> ${log_file}
table_rows_cnt=`mysql -u $SQL_USERID -D $SQL_DATABASE -h $SQL_HOSTNAME -e "$get_table_cnt_query" | tr -dc '0-9'`
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas ladowania danych do tabeli mysql!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Ladowanie danych do tabeli -- OK" >> ${log_file}

## Przeniesienie przetworzonego pliku
cat ${file_name} >> ${processed_file}
mv ${processed_file} "PROCESSED/${processed_file}"
rm ${file_name}
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas przenoszenia plikow!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Przeniesienie pliku -- OK" >> ${log_file}

## Wysylanie wiadomosci email z raportem
email_title="CUSTOMERS LOAD - ${TIMESTAMP}"
email_body="- Liczba wierszy w pliku pobranym: $total_cnt \n
- Liczba poprawnych wierszy: $processed_cnt \n
- Liczba duplikatow ze starego pliku: $duplicate_cnt \n
- Liczba blednych/odrzuconych wierszy: $bad_cnt \n
- Liczba danych zaladowanych do tabeli ${sql_table_name}: ${table_rows_cnt}"
echo -e $email_body | mail -s "$email_title" ${EMAIL_RECEIVER}
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas wysylania maila!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Wyslanie raportu email -- OK" >> ${log_file}

## Update kolumny SecretCode losowym stringiem
update_secret_code_query="UPDATE ${sql_table_name} SET SecretCode = RIGHT(MD5(RAND()), 10);"
echo "MYSQL QUERY: ${update_secret_code_query}" >> ${log_file}
mysql -u $SQL_USERID -D $SQL_DATABASE -h $SQL_HOSTNAME -e "$update_secret_code_query"
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas ladowania danych do tabeli mysql!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Aktualizacja SecretCode -- OK" >> ${log_file}

## Eksport danych z tabeli do pliku csv
export_file_name="export.csv"
get_data_query="SELECT * FROM ${sql_table_name};"
echo "MYSQL QUERY: ${get_data_query}" >> ${log_file}
mysql -u $SQL_USERID -D $SQL_DATABASE -h $SQL_HOSTNAME -e "$get_data_query" | sed 's/\t/|/g' > ${export_file_name}
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas ladowania danych do tabeli mysql!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Eksportowanie tabeli do csv -- OK" >> ${log_file}

## Archiwizacja pliku csv
csv_row_cnt=$((`cat ${export_file_name} | wc -l`-1))
zip -q -m ${sql_table_name} ${export_file_name}
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad archiwizacji!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Archiwizowanie pliku csv -- OK" >> ${log_file}

## Wyslanie zarchiwizowanego pliku na mail
csv_created_time=`stat -c %y ${sql_table_name}.zip`
email_title="${sql_table_name}  TABLE EXPORT - ${TIMESTAMP}"
email_body="Czas utworzenia: $csv_created_time \n
Liczba wierszy: $csv_row_cnt"
echo -e $email_body | mail -s "$email_title" -a "${sql_table_name}.zip" ${EMAIL_RECEIVER}
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas wysylania pliku!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- Wyslanie pliku na poczte -- OK" >> ${log_file}

## Usuniecie tymczasowych plikow
rm ${sql_table_name}.zip
if [ "$?" -ne 0 ]; then
    echo "$(date +%m%d%Y%H%M%S) -- Wystapil blad podczas usuwania tymczasowych plikow!" 2>> ${log_file}
    exit 1
fi
echo "$(date +%Y%m%d%H%M%S) -- KONIEC" >> ${log_file}
