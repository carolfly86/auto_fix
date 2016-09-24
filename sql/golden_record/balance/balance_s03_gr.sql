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
    medidata_studies_id bigint,
    medidata_studies_name text,
    medidata_studies_etag text,
    medidata_studies_parent_id bigint,
    medidata_studies_oid text,
    medidata_studies_type text,
    medidata_studies_title text,
    medidata_studies_summary text,
    medidata_studies_drug_device text,
    medidata_studies_compound_code text,
    medidata_studies_number text,
    medidata_studies_program text,
    medidata_studies_protocol text,
    medidata_studies_indication text,
    medidata_studies_responsible_party text,
    medidata_studies_enrollment_target text,
    medidata_studies_investigator text,
    medidata_studies_full_description text,
    medidata_studies_live_date timestamp with time zone,
    medidata_studies_close_date timestamp with time zone,
    medidata_studies_is_production boolean,
    medidata_studies_uuid text,
    studies_id bigint,
    studies_study_design_id bigint,
    studies_name text,
    studies_external_id bigint,
    studies_parent_study_id bigint,
    studies_environment_id bigint,
    studies_live boolean,
    studies_external_name text,
    studies_rand_only boolean,
    studies_unblinded boolean,
    studies_is_shipping_algorithm_running boolean,
    studies_randomization_api_locked boolean,
    studies_dispensation_api_locked boolean,
    studies_include_address_in_shipping_email boolean,
    studies_allow_quarantining boolean,
    studies_file_upload_rules bigint,
    studies_needs_design_by_wizard boolean,
    studies_can_generate_blocks boolean,
    studies_advanced_dosing boolean,
    studies_capping boolean,
    studies_subject_identification_version bigint,
    studies_new_countries_require_qp_release boolean,
    studies_lots_are_blinded boolean,
    studies_conditional_treatment_unblinded_subjects bigint,
    type character varying(30),
    branch character varying(30)
);


ALTER TABLE golden_record OWNER TO yguo;

--
-- Data for Name: golden_record; Type: TABLE DATA; Schema: public; Owner: yguo
--

COPY golden_record (medidata_studies_id, medidata_studies_name, medidata_studies_etag, medidata_studies_parent_id, medidata_studies_oid, medidata_studies_type, medidata_studies_title, medidata_studies_summary, medidata_studies_drug_device, medidata_studies_compound_code, medidata_studies_number, medidata_studies_program, medidata_studies_protocol, medidata_studies_indication, medidata_studies_responsible_party, medidata_studies_enrollment_target, medidata_studies_investigator, medidata_studies_full_description, medidata_studies_live_date, medidata_studies_close_date, medidata_studies_is_production, medidata_studies_uuid, studies_id, studies_study_design_id, studies_name, studies_external_id, studies_parent_study_id, studies_environment_id, studies_live, studies_external_name, studies_rand_only, studies_unblinded, studies_is_shipping_algorithm_running, studies_randomization_api_locked, studies_dispensation_api_locked, studies_include_address_in_shipping_email, studies_allow_quarantining, studies_file_upload_rules, studies_needs_design_by_wizard, studies_can_generate_blocks, studies_advanced_dosing, studies_capping, studies_subject_identification_version, studies_new_countries_require_qp_release, studies_lots_are_blinded, studies_conditional_treatment_unblinded_subjects, type, branch) FROM stdin;
159	Mediflexs	\N	135	Mediflexs	\N					\N								\N	\N	t	1e829b5f-039d-4636-9a9a-8d3ea6512e5f	580	643	Mediflexs	159	\N	\N	f	\N	f	f	f	f	f	f	f	0	f	f	t	f	1	f	t	0	excluded	
45231	SmokeTest_756657411 (DEV)	\N	27856	protocol_756657411	\N					\N								\N	\N	f	bb20c086-79e0-4be9-8cb0-5f15446e1f94	1032	1178	SmokeTest_756657411 (DEV)	45231	\N	\N	f	\N	f	f	f	f	f	f	f	0	f	t	t	f	1	f	f	0	satisfied	PH0
\.


--
-- PostgreSQL database dump complete
--

