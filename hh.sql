CREATE TABLE area
(
	area_id serial primary key,
	country text not null,
	city text not null,
	UNIQUE(country, city)
);

CREATE TABLE employer
(
	employer_id serial primary key,
	area_id integer REFERENCES area(area_id),
	employer_name text not null,
	employer_description text not null
);

CREATE TABLE vacancy
(
	vacancy_id serial primary key,
	employer_id integer not null REFERENCES employer(employer_id),
	publication_date date not null,
	position_title text not null,
	position_description text not null,
	compensation_from integer,
	compensation_to integer,
	gross boolean
);

CREATE TABLE employee
(
	employee_id serial primary key,
	employee_name text not null,
	area_id integer REFERENCES area(area_id),
	email text not null,
	phone_number text
);

CREATE TABLE cv
(
	cv_id serial primary key,
	employee_id integer not null REFERENCES employee(employee_id),
	title text not null,
	publication_date date not null,
	compensation integer,
	gross boolean,
	employment text,
	work_schedule text,
	work_experience text,
	education text,
	citizenship text,
	permission_to_work text
);

CREATE TABLE specialization
(
	specialization_id serial primary key,
	specialization_name text not null
);

CREATE TABLE vacancy_specialization
(
	vacancy_id integer not null REFERENCES vacancy(vacancy_id),
	specialization_id integer not null REFERENCES specialization(specialization_id),
	PRIMARY KEY (vacancy_id, specialization_id )
);

CREATE TABLE cv_specialization
(
	cv_id integer not null REFERENCES cv(cv_id),
	specialization_id integer not null REFERENCES specialization(specialization_id),
	PRIMARY KEY (cv_id, specialization_id )
);

CREATE TYPE status AS ENUM ('invitation', 'viewed', 'not viewed', 'refusal');

CREATE TABLE response
(
	response_status status not null,
	vacancy_id integer not null REFERENCES vacancy(vacancy_id),
	cv_id integer not null REFERENCES cv(cv_id),
	response_date date not null,
	PRIMARY KEY (vacancy_id, cv_id )
);

INSERT INTO area (country, city) VALUES
    ('Russia', 'Moscow'),
    ('Russia', 'Spb');

INSERT INTO employer (area_id, employer_name, employer_description) VALUES
    (1, 'hh', 'description'),
    (2, 'yandex', 'description');

INSERT INTO specialization (specialization_name) VALUES
    ('IT');

with test_vacancy_data(id, 
			   employer_id, 
			   publication_date, 
			   position_title, 
			   position_description, 
			   salary) AS(
	SELECT generate_series(1, 10000) AS id, 
				   random()::int % 2 + 1 AS employer_id,
				   timestamp '2021-01-01 00:00:00' + random() * (timestamp '2021-01-01 00:00:00' - timestamp '2021-12-31 00:00:00') AS publication_date,
				   left(md5(random()::text), 10) AS position_title,
				   md5(random()::text) AS position_description,
				   round((random() * 100000)::int, -3) AS salary
)
INSERT INTO vacancy (
    employer_id, publication_date, position_title, position_description, compensation_from, compensation_to, gross
)
SELECT
    employer_id,
    publication_date,
    position_title,
	position_description,
	salary,
	salary + 10000,
	false
FROM test_vacancy_data;

with test_employee_data(id, 
			   area_id, 
			   employee_name, 
			   email) AS (
	SELECT generate_series(1, 50000) AS id, 
				   random()::int % 2 + 1 AS area_id,
				   left(md5(random()::text), 10) AS employee_name,
				   left(md5(random()::text), 10) AS email
)
INSERT INTO employee (
    area_id, employee_name, email
)
SELECT
    area_id,
    employee_name,
    email
FROM test_employee_data;

with test_cv_data(id, 
			   employee_id, 
			   title, 
			   publication_date) AS (
	SELECT generate_series(1, 100000) AS id, 
				   random()::int % 50000 + 1 AS employee_id,
				   left(md5(random()::text), 10) AS title,
				   timestamp '2021-01-01 00:00:00' + random() * (timestamp '2021-01-01 00:00:00' - timestamp '2021-12-31 00:00:00') AS publication_date
)
INSERT INTO cv (
    employee_id, title, publication_date
)
SELECT
    employee_id,
    title,
    publication_date
FROM test_cv_data;

with test_vacancy_specialization(id) AS (
	SELECT generate_series(1, 10000) AS id
)
INSERT INTO vacancy_specialization (
    vacancy_id, specialization_id
)
SELECT
    id,
    1
FROM test_vacancy_specialization;

with test_cv_specialization(id) AS (
	SELECT generate_series(1, 100000) AS id
)
INSERT INTO cv_specialization (
    cv_id, specialization_id
)
SELECT
    id,
    1
FROM test_cv_specialization;

with test_response(id,
			   vacancy_id,
			   response_status,
			   response_date) AS (
	SELECT generate_series(1, 50000) AS id,
				   random()::int % 10000 + 1 AS vacancy_id,
				   random()::int % 4 AS responce_status,
				   timestamp '2021-01-01 00:00:00' + random() * (timestamp '2021-01-01 00:00:00' - timestamp '2021-12-31 00:00:00') AS response_date
)
INSERT INTO response (
    response_status, vacancy_id, cv_id, response_date
)
SELECT
	CASE WHEN response_status = 0 THEN 'invitation'::status
		 WHEN response_status = 1 THEN 'viewed'::status
		 WHEN response_status = 2 THEN 'not viewed'::status
         ELSE 'refusal'::status
    END,
    vacancy_id, 
	id,
    response_date
FROM test_response;

CREATE INDEX employer_id_index ON employer USING hash(employer_id, area_id);
--DROP INDEX employer_id_index;

SELECT area_id, 
AVG(compensation_from) as avg_compensation_from, 
AVG(compensation_to) as avg_compensation_to,
(AVG(compensation_to) + AVG(compensation_from)) / 2 as avg_compensation_from_to
FROM vacancy 
INNER JOIN employer on vacancy.employer_id = employer.employer_id
GROUP BY area_id;


CREATE INDEX vacancy_date_index ON vacancy(EXTRACT(MONTH FROM publication_date), vacancy_id);
--DROP INDEX vacancy_date_index;


SELECT EXTRACT(MONTH FROM publication_date) as month,
COUNT(vacancy_id) as vacancies_count
FROM vacancy
GROUP BY month
ORDER BY vacancies_count DESC
LIMIT 1;

CREATE INDEX cv_date_index ON cv(EXTRACT(MONTH FROM publication_date), cv_id);
--DROP INDEX vacancy_date_index;

SELECT EXTRACT(MONTH FROM publication_date) as month,
COUNT(cv_id) as cv_count
FROM cv
GROUP BY month
ORDER BY cv_count DESC
LIMIT 1;

CREATE INDEX response_vacancy_id_index ON response(vacancy_id);
--DROP INDEX response_vacancy_id_index;

SELECT vacancy.vacancy_id, vacancy.position_title
FROM vacancy
LEFT JOIN response on vacancy.vacancy_id = response.vacancy_id
WHERE response.response_date::TIMESTAMP - vacancy.publication_date::TIMESTAMP <= interval '7' day 
AND response.response_date - vacancy.publication_date >= 0
GROUP BY response.vacancy_id
HAVING COUNT(vacancy.vacancy_id) >= 5;

