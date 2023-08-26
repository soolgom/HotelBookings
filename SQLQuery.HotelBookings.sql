-- Original Table
SELECT *
FROM HotelBookings..hotel_bookings





-- COUNTS OF CANCELATIONS


SELECT COUNT(*) AS cxl_res
	, (SELECT COUNT(*) FROM HotelBookings..hotel_bookings WHERE is_canceled = 0) AS non_cxl_res
	, (SELECT COUNT(*) FROM HotelBookings..hotel_bookings) AS total
FROM HotelBookings..hotel_bookings
WHERE is_canceled = 1





-- PERCENTAGE OF CANCELATIONS


-- 0: Not Cancelled , 1: Cancelled

SELECT is_canceled, CAST(COUNT(*) * 100 / (SELECT COUNT(*) FROM HotelBookings..hotel_bookings) AS nvarchar(MAX)) + '%' AS pct
FROM HotelBookings..hotel_bookings
GROUP BY is_canceled





-- COUNTS OF CANCELATIONS BY REPEAT GUESTS


-- Check total number of repeat guests

SELECT COUNT(is_repeated_guest)
FROM HotelBookings..hotel_bookings
WHERE is_repeated_guest = 1


-- Count total repeat guests by cancellation status

WITH repeat AS (
	SELECT COUNT(is_repeated_guest) AS repeat_guests, is_canceled
	FROM HotelBookings..hotel_bookings
	WHERE is_repeated_guest = 1
	GROUP BY is_canceled
	)
SELECT is_canceled, repeat_guests
FROM repeat





-- PERCENTAGE OF CANCELATIONS BY REPEAT GUESTS


SELECT is_canceled, CAST(COUNT(*) * 100 / (SELECT COUNT(is_repeated_guest) FROM HotelBookings..hotel_bookings WHERE is_repeated_guest = 1) AS nvarchar(5)) + '%' AS pct_of_repeat_guests
FROM HotelBookings..hotel_bookings
WHERE is_repeated_guest = 1
GROUP BY is_canceled





-- COUNTS OF CANCELATIONS BY NONREPEAT GUESTS 


-- Check total number of nonrepeat guests

SELECT COUNT(is_repeated_guest)
FROM HotelBookings..hotel_bookings
WHERE is_repeated_guest = 0


-- Count total nonrepeat guests by cancellation status

WITH repeat AS (
	SELECT COUNT(is_repeated_guest) AS nonrepeat_guests, is_canceled
	FROM HotelBookings..hotel_bookings
	WHERE is_repeated_guest = 0
	GROUP BY is_canceled
	)
SELECT is_canceled, nonrepeat_guests
FROM repeat





-- PERCENTAGE OF CANCELATIONS BY NONREPEAT GUESTS 


SELECT is_canceled, CAST(COUNT(*) * 100 / (SELECT COUNT(is_repeated_guest) FROM HotelBookings..hotel_bookings WHERE is_repeated_guest = 0) AS nvarchar(5)) + '%' AS pct_of_nonrepeat_guests
FROM HotelBookings..hotel_bookings
WHERE is_repeated_guest = 0
GROUP BY is_canceled





-- AVERAGE DAILY RATE PER MONTH CHRONOLOGICALLY FOR CANCELLED AND NONCANCELLED RESERVATIONS


-- Create Table for ADR of Cancelled Reservations Chronologically

DROP TABLE IF EXISTS adrcxl
CREATE TABLE adrcxl (
	Cxl_ADR INT,
	month VARCHAR(MAX),
	year INT
)

INSERT INTO adrcxl
	SELECT AVG(adr) AS Cxl_ADR
	, arrival_date_month
	, arrival_date_year
FROM HotelBookings..hotel_bookings
WHERE is_canceled = 1
GROUP BY arrival_date_month
	, arrival_date_year
ORDER BY arrival_date_year
	, DATEPART(mm,CAST(arrival_date_month+ ' 1900' AS DATETIME)) asc

SELECT *
FROM adrcxl
ORDER BY year
	, DATEPART(mm,CAST(month+ ' 1900' AS DATETIME)) asc



-- Create Table for ADR of NonCancelled Reservations Chronologically

DROP TABLE IF EXISTS adrnoncxl
CREATE TABLE adrnoncxl (
	NonCxl_ADR INT,
	month VARCHAR(MAX),
	year INT
)

INSERT INTO adrnoncxl
	SELECT AVG(adr) AS NonCxl_ADR
	, arrival_date_month
	, arrival_date_year
FROM HotelBookings..hotel_bookings
WHERE is_canceled = 0
GROUP BY arrival_date_month
	, arrival_date_year
ORDER BY arrival_date_year
	, DATEPART(mm,CAST(arrival_date_month+ ' 1900' AS DATETIME)) asc

SELECT *
FROM adrnoncxl
ORDER BY year
	, DATEPART(mm,CAST(month+ ' 1900' AS DATETIME)) asc


-- Join tables in chronological order
SELECT Cxl_ADR, NonCxl_ADR, cxl.month, cxl.year
FROM adrcxl cxl
 JOIN adrnoncxl noncxl ON cxl.month=noncxl.month AND cxl.year=noncxl.year
ORDER BY cxl.year
	, DATEPART(mm,CAST(cxl.month+ ' 1900' AS DATETIME)) asc





-- PERCENTAGES OF CXL PER MONTH


SELECT cxl.year
	, cxl.month
	, (CAST(Cancelations AS decimal) / Reservations)*100 AS Percent_Cxl
FROM num_of_cxl cxl
 JOIN num_of_res res ON cxl.Month=res.Month AND cxl.Year=res.Year
ORDER BY cxl.year,
	DATEPART(mm,CAST(cxl.month+ ' 1900' AS DATETIME)) asc
	




-- TOP 15 COUNT OF RESERVATIONS BY COUNTRY


SELECT country, COUNT(*) as reservations
FROM HotelBookings..hotel_bookings
GROUP BY country
ORDER BY 2 DESC

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

-- Table NOT INCLUDED

-- COMPARE COUNTS OF MEAL PLANS IN CXL VS NONCXL RESERVATIONS


-- Create Table to count meal types of noncxl reservations

DROP TABLE IF EXISTS noncxl_mealplan
CREATE TABLE noncxl_mealplan (
	noncxl INT,
	meal VARCHAR(MAX)
)

INSERT INTO noncxl_mealplan
	SELECT COUNT(meal) AS noncxl, 
		   meal
	FROM HotelBookings..hotel_bookings
	WHERE is_canceled = 0
	GROUP BY meal


-- Create Table to count meal types of cxl reservations

DROP TABLE IF EXISTS cxl_mealplan
CREATE TABLE cxl_mealplan (
	cxl INT,
	meal VARCHAR(MAX)
)

INSERT INTO cxl_mealplan
	SELECT COUNT(meal) AS cxl, 
		   meal
	FROM HotelBookings..hotel_bookings
	WHERE is_canceled = 1
	GROUP BY meal


-- Join temp tables to show NonCxl and Cxl totals by meal type
SELECT noncxl_mealplan.meal, cxl_mealplan.cxl, noncxl_mealplan.noncxl
FROM noncxl_mealplan
 JOIN cxl_mealplan ON noncxl_mealplan.meal=cxl_mealplan.meal





 -- Table NOT INCLUDED

 -- RESERVATIONS AND CANCELATIONS COUNTS BY MONTH AND YEAR CHRONOLOGICALLY


 -- Create Table of all reservations by month and year

DROP TABLE IF EXISTS num_of_res
CREATE TABLE num_of_res (
	Reservations INT,
	Year INT,
	Month VARCHAR(MAX)
)
INSERT INTO num_of_res
	SELECT COUNT(*) AS Reservations,
	arrival_date_year, 
	arrival_date_month
FROM HotelBookings..hotel_bookings
GROUP BY arrival_date_year, 
	arrival_date_month

SELECT *
FROM num_of_res
ORDER BY year,
	DATEPART(mm,CAST(month+ ' 1900' AS DATETIME)) asc


-- Create Table of all canceled reservations by month and year

DROP TABLE IF EXISTS num_of_cxl
CREATE TABLE num_of_cxl (
	Cancelations INT,
	Year INT,
	Month VARCHAR(MAX)
)
INSERT INTO num_of_cxl
	SELECT COUNT(*) AS CxlReservations,
	arrival_date_year, 
	arrival_date_month
FROM HotelBookings..hotel_bookings
WHERE is_canceled = 1
GROUP BY arrival_date_year, 
	arrival_date_month

SELECT *
FROM num_of_cxl
ORDER BY year,
	DATEPART(mm,CAST(month+ ' 1900' AS DATETIME)) asc


-- Join tables to show both total reservations and cancelations chronologically
SELECT cxl.Year, cxl.Month, cxl.Cancelations, res.Reservations
FROM num_of_cxl cxl
 JOIN num_of_res res ON cxl.Month=res.Month AND cxl.Year=res.Year
ORDER BY cxl.year,
	DATEPART(mm,CAST(cxl.month+ ' 1900' AS DATETIME)) asc




-- Table NOT INCLUDED

-- AVERAGE DAILY RATE PER YEAR FOR CXL AND NONCXL RESERVATIONS


-- ADR per year for CXL Reservations

SELECT AVG(adr) AS Avg_Daily_Rate, arrival_date_year
FROM HotelBookings..hotel_bookings
WHERE is_canceled = 1
GROUP BY arrival_date_year
ORDER BY AVG(adr)


-- ADR per year for NONCXL Reservations

SELECT AVG(adr) AS Avg_Daily_Rate, arrival_date_year
FROM HotelBookings..hotel_bookings
WHERE is_canceled = 0
GROUP BY arrival_date_year
ORDER BY AVG(adr)