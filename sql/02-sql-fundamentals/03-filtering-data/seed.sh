#!/usr/bin/env bash
# Runs INSIDE the container. Fresh ~/sandbox + the "my_db" database for this section.
set -euo pipefail
SB="$HOME/sandbox"; DB=my_db
rm -rf "$SB"; mkdir -p "$SB"
for _ in $(seq 1 50); do pg_isready -q && break; sleep 0.2; done

# The person table from "Up and Running with SQL" (no keys yet - that's section 06).
person_table(){ cat <<'SQL'
CREATE TABLE person (
    id INTEGER,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    gender CHAR(1),
    dob DATE,
    phone_number VARCHAR(15),
    country_of_origin VARCHAR(50)
);
SQL
}
# The 100 sample people from the "Sample Data" lecture.
person_rows(){ cat <<'SQL'
INSERT INTO person (id, first_name, last_name, gender, dob, phone_number, country_of_origin) VALUES
(1, 'Ahmed', 'Khan', 'M', '1980-01-15', NULL, 'Pakistan'),
(2, 'Aisha', 'Ali', 'F', '1991-02-20', '123-456-0002', 'Egypt'),
(3, 'John', 'Smith', 'M', '1985-03-25', '123-456-0003', 'USA'),
(4, 'Fatima', 'Zahra', 'F', '1992-04-30', '123-456-0004', 'Morocco'),
(5, 'Ali', 'Hussein', 'M', '1987-05-05', NULL, 'Iraq'),
(6, 'Maryam', 'Hassan', 'F', '1994-06-10', '123-456-0006', 'Jordan'),
(7, 'Robert', 'Brown', 'M', '1981-07-15', '123-456-0007', 'UK'),
(8, 'Nadia', 'Kamal', 'F', '1993-08-20', '123-456-0008', 'Saudi Arabia'),
(9, 'David', 'Johnson', 'M', '1982-09-25', NULL, 'USA'),
(10, 'Sara', 'Yusuf', 'F', '1995-10-30', '123-456-0010', 'Turkey'),
(11, 'Mohammed', 'Saeed', 'M', '1983-11-15', '123-456-0011', 'UAE'),
(12, 'Layla', 'Omar', 'F', '1996-12-20', '123-456-0012', 'Sudan'),
(13, 'Michael', 'Williams', 'M', '1984-01-10', '123-456-0013', 'Canada'),
(14, 'Khadija', 'Ahmed', 'F', '1997-02-15', NULL, 'Somalia'),
(15, 'Omar', 'Nasir', 'M', '1986-03-20', '123-456-0015', 'Egypt'),
(16, 'Iman', 'Rahman', 'F', '1998-04-25', '123-456-0016', 'Lebanon'),
(17, 'James', 'Taylor', 'M', '1987-05-30', '123-456-0017', 'Australia'),
(18, 'Zainab', 'Qureshi', 'F', '1999-06-05', '123-456-0018', 'Pakistan'),
(19, 'William', 'Jones', 'M', '1988-07-10', '123-456-0019', 'USA'),
(20, 'Amina', 'Salim', 'F', '2000-08-15', '123-456-0020', 'India'),
(21, 'Isaac', 'Green', 'M', '1989-09-20', NULL, 'South Africa'),
(22, 'Hana', 'Mahmoud', 'F', '2001-10-25', '123-456-0022', 'Indonesia'),
(23, 'Abdullah', 'Sheikh', 'M', '1990-11-30', '123-456-0023', 'Bangladesh'),
(24, 'Sahar', 'Fahad', 'F', '2002-12-05', '123-456-0024', 'Kuwait'),
(25, 'Chris', 'Martinez', 'M', '1991-01-10', '123-456-0025', 'Mexico'),
(26, 'Fatma', 'Adel', 'F', '2003-02-15', '123-456-0026', 'Libya'),
(27, 'Hassan', 'Ibrahim', 'M', '1992-03-20', NULL, 'Algeria'),
(28, 'Noura', 'Yassin', 'F', '2004-04-25', '123-456-0028', 'Syria'),
(29, 'Adam', 'Garcia', 'M', '1993-05-30', '123-456-0029', 'Spain'),
(30, 'Lina', 'Najeeb', 'F', '2005-06-05', '123-456-0030', 'Palestine'),
(31, 'Jacob', 'White', 'M', '1994-07-10', '123-456-0031', 'New Zealand'),
(32, 'Maha', 'Halim', 'F', '2006-08-15', '123-456-0032', 'Oman'),
(33, 'Ethan', 'Clark', 'M', '1995-09-20', NULL, 'USA'),
(34, 'Rania', 'Saleh', 'F', '2007-10-25', '123-456-0034', 'Tunisia'),
(35, 'Noah', 'Lewis', 'M', '1996-11-30', '123-456-0035', 'UK'),
(36, 'Salma', 'Othman', 'F', '2008-12-05', '123-456-0036', 'Yemen'),
(37, 'Isa', 'Hadi', 'M', '1997-01-10', '123-456-0037', 'Iraq'),
(38, 'Dina', 'Gamal', 'F', '2009-02-15', '123-456-0038', 'Egypt'),
(39, 'Jack', 'Walker', 'M', '1998-03-20', '123-456-0039', 'Australia'),
(40, 'Reem', 'Aziz', 'F', '2010-04-25', '123-456-0040', 'Saudi Arabia'),
(41, 'Daniel', 'Young', 'M', '1999-05-30', '123-456-0041', 'Canada'),
(42, 'Yasmin', 'Hassan', 'F', '2011-06-05', NULL, 'Jordan'),
(43, 'Charles', 'Hall', 'M', '2000-07-10', '123-456-0043', 'USA'),
(44, 'Hiba', 'Tariq', 'F', '2012-08-15', '123-456-0044', 'Sudan'),
(45, 'Thomas', 'Allen', 'M', '2001-09-20', '123-456-0045', 'UK'),
(46, 'Mona', 'Faisal', 'F', '2013-10-25', NULL, 'Somalia'),
(47, 'Henry', 'King', 'M', '2002-11-30', '123-456-0047', 'USA'),
(48, 'Noor', 'Latif', 'F', '2014-12-05', '123-456-0048', 'Lebanon'),
(49, 'Samuel', 'Scott', 'M', '2003-01-10', '123-456-0049', 'Australia'),
(50, 'Aya', 'Shahid', 'F', '2015-02-15', '123-456-0050', 'Pakistan'),
(51, 'Joseph', 'Nelson', 'M', '2004-03-20', '123-456-0051', 'Canada'),
(52, 'Haleema', 'Fawad', 'F', '2016-04-25', '123-456-0052', 'India'),
(53, 'George', 'Carter', 'M', '2005-05-30', '123-456-0053', 'USA'),
(54, 'Amira', 'Hassan', 'F', '2017-06-05', '123-456-0054', 'Egypt'),
(55, 'Edward', 'Mitchell', 'M', '2006-07-10', NULL, 'UK'),
(56, 'Laila', 'Hamed', 'F', '2018-08-15', '123-456-0056', 'Morocco'),
(57, 'Louis', 'Perez', 'M', '2007-09-20', '123-456-0057', 'Spain'),
(58, 'Ruqayya', 'Zaid', 'F', '2019-10-25', '123-456-0058', 'Algeria'),
(59, 'Oscar', 'Edwards', 'M', '2008-11-30', '123-456-0059', 'USA'),
(60, 'Sana', 'Nawaz', 'F', '2020-12-05', '123-456-0060', 'Bangladesh'),
(61, 'Leo', 'Stewart', 'M', '2009-01-10', '123-456-0061', 'Australia'),
(62, 'Bushra', 'Iqbal', 'F', '2021-02-15', NULL, 'Jordan'),
(63, 'Peter', 'Baker', 'M', '2010-03-20', '123-456-0063', 'Canada'),
(64, 'Farah', 'Qasim', 'F', '2022-04-25', '123-456-0064', 'Iraq'),
(65, 'Patrick', 'Campbell', 'M', '2011-05-30', '123-456-0065', 'USA'),
(66, 'Mariam', 'Abbas', 'F', '2023-06-05', '123-456-0066', 'Lebanon'),
(67, 'Gabriel', 'Morgan', 'M', '2012-07-10', NULL, 'UK'),
(68, 'Salwa', 'Ashraf', 'F', '2024-08-15', '123-456-0068', 'Saudi Arabia'),
(69, 'Ryan', 'Bell', 'M', '2013-09-20', '123-456-0069', 'Australia'),
(70, 'Nour', 'Mubarak', 'F', '2025-10-25', '123-456-0070', 'Egypt'),
(71, 'Jonathan', 'Hill', 'M', '2014-11-30', '123-456-0071', 'Canada'),
(72, 'Alya', 'Esmail', 'F', '2026-12-05', '123-456-0072', 'Sudan'),
(73, 'Richard', 'Adams', 'M', '2015-01-10', NULL, 'USA'),
(74, 'Lina', 'Farid', 'F', '2027-02-15', '123-456-0074', 'Tunisia'),
(75, 'Bruce', 'Ward', 'M', '2016-03-20', '123-456-0075', 'UK'),
(76, 'Hiba', 'Salah', 'F', '2028-04-25', '123-456-0076', 'Yemen'),
(77, 'Oliver', 'Gray', 'M', '2017-05-30', '123-456-0077', 'Australia'),
(78, 'Jana', 'Mustafa', 'F', '2029-06-05', '123-456-0078', 'Saudi Arabia'),
(79, 'Arthur', 'James', 'M', '2018-07-10', '123-456-0079', 'Canada'),
(80, 'Maha', 'Sharif', 'F', '2030-08-15', '123-456-0080', 'Jordan'),
(81, 'Albert', 'Hughes', 'M', '2019-09-20', '123-456-0081', 'USA'),
(82, 'Sumaya', 'Jawad', 'F', '2031-10-25', '123-456-0082', 'Lebanon'),
(83, 'Steven', 'Anderson', 'M', '2020-11-30', '123-456-0083', 'UK'),
(84, 'Farah', 'Rashid', 'F', '2032-12-05', '123-456-0084', 'Pakistan'),
(85, 'Kevin', 'Harris', 'M', '2021-01-10', '123-456-0085', 'Australia'),
(86, 'Noor', 'Salman', 'F', '2033-02-15', NULL, 'Egypt'),
(87, 'David', 'Robinson', 'M', '2022-03-20', '123-456-0087', 'USA'),
(88, 'Leila', 'Abdul', 'F', '2034-04-25', '123-456-0088', 'Jordan'),
(89, 'Charles', 'Garcia', 'M', '2023-05-30', '123-456-0089', 'Canada'),
(90, 'Zainab', 'Amir', 'F', '2035-06-05', '123-456-0090', 'Sudan'),
(91, 'Jacob', 'Martinez', 'M', '2024-07-10', NULL, 'USA'),
(92, 'Yara', 'Sami', 'F', '2036-08-15', '123-456-0092', 'Lebanon'),
(93, 'Joseph', 'Thomas', 'M', '2025-09-20', '123-456-0093', 'UK'),
(94, 'Nada', 'Hasan', 'F', '2037-10-25', '123-456-0094', 'Egypt'),
(95, 'Brian', 'Lee', 'M', '2026-11-30', '123-456-0095', 'Australia'),
(96, 'Hiba', 'Zayed', 'F', '2038-12-05', NULL, 'Jordan'),
(97, 'Paul', 'Walker', 'M', '2027-01-10', '123-456-0097', 'Canada'),
(98, 'Mariam', 'Faisal', 'F', '2039-02-15', '123-456-0098', 'Sudan'),
(99, 'Mark', 'Nelson', 'M', '2028-03-20', '123-456-0099', 'USA'),
(100, 'Aya', 'Karim', 'F', '2040-04-25', '123-456-0100', 'Lebanon');
SQL
}

# my_db: the 100 sample people, where Insert and Select left off.
dropdb --if-exists "$DB"; createdb "$DB"
{ person_table; person_rows; } | psql -X -q -v ON_ERROR_STOP=1 -d "$DB"

# An untouched copy the grader runs your saved queries against, so whatever you do to
# the data while experimenting can't change what a query is expected to return. It
# already has the lowercase "nelson" from 3.3, so LIKE and ILIKE give different answers.
dropdb --if-exists "${DB}_ref"; createdb -T "$DB" "${DB}_ref"
psql -X -q -v ON_ERROR_STOP=1 -d "${DB}_ref" -c "INSERT INTO person (id, last_name) VALUES (101, 'nelson');"

# The Academy opens psql connected to the database named here (exactly this line).
sed -i '/^export PGDATABASE=/d' ~/.bashrc 2>/dev/null || true
echo "export PGDATABASE=$DB" >> ~/.bashrc
grep -qx "export PGDATABASE=$DB" ~/.bashrc || { echo "seed: could not write PGDATABASE to ~/.bashrc" >&2; exit 1; }
echo "Sandbox ready: psql opens in the '$DB' database."
