--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: golden_record; Type: TABLE; Schema: public; Owner: yguo; Tablespace: 
--

CREATE TABLE golden_record (
    employees_emp_no integer,
    employees_birth_date date,
    employees_first_name character varying(14),
    employees_last_name character varying(16),
    employees_gender gender_enum,
    employees_hire_date date,
    salaries_emp_no integer,
    salaries_salary integer,
    salaries_from_date date,
    salaries_to_date date,
    titles_emp_no integer,
    titles_title character varying(50),
    titles_from_date date,
    titles_to_date date,
    dept_emp_emp_no integer,
    dept_emp_dept_no character(4),
    dept_emp_from_date date,
    dept_emp_to_date date,
    departments_dept_no character(4),
    departments_dept_name character varying(40),
    type character varying(30),
    branch character varying(30)
);


ALTER TABLE golden_record OWNER TO yguo;

--
-- Data for Name: golden_record; Type: TABLE DATA; Schema: public; Owner: yguo
--

COPY golden_record (employees_emp_no, employees_birth_date, employees_first_name, employees_last_name, employees_gender, employees_hire_date, salaries_emp_no, salaries_salary, salaries_from_date, salaries_to_date, titles_emp_no, titles_title, titles_from_date, titles_to_date, dept_emp_emp_no, dept_emp_dept_no, dept_emp_from_date, dept_emp_to_date, departments_dept_no, departments_dept_name, type, branch) FROM stdin;
41173	1953-08-06	Maren	Aseltine	F	1986-04-04	41173	42081	1994-03-29	1995-03-29	41173	Engineer	1994-03-29	2002-03-29	41173	d005	1994-03-29	9999-01-01	d005	Development	satisfied	PH0
20196	1960-09-20	LiMin	Redmiles	F	1988-01-02	20196	40000	1988-01-02	1989-01-01	20196	Engineer	1988-01-02	1997-01-01	20196	d005	1988-01-02	9999-01-01	d005	Development	satisfied	PH1
10144	1949-06-17	Marla	Brendel	M	1985-10-14	10144	36720	1985-10-14	1986-10-14	10144	Staff	1985-10-14	1992-10-14	10144	d002	1985-10-14	1988-09-02	d002	Finance	excluded	
\.


--
-- PostgreSQL database dump complete
--

