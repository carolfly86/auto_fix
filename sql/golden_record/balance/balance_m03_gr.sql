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
    depots_id bigint,
    depots_parent_id bigint,
    depots_study_id bigint,
    depots_medidata_depot_id bigint,
    depots_active_for_drug_shipping boolean,
    depots_emails text,
    type character varying(30),
    branch character varying(30)
);


ALTER TABLE golden_record OWNER TO yguo;

--
-- Data for Name: golden_record; Type: TABLE DATA; Schema: public; Owner: yguo
--

COPY golden_record (medidata_studies_id, medidata_studies_name, medidata_studies_etag, medidata_studies_parent_id, medidata_studies_oid, medidata_studies_type, medidata_studies_title, medidata_studies_summary, medidata_studies_drug_device, medidata_studies_compound_code, medidata_studies_number, medidata_studies_program, medidata_studies_protocol, medidata_studies_indication, medidata_studies_responsible_party, medidata_studies_enrollment_target, medidata_studies_investigator, medidata_studies_full_description, medidata_studies_live_date, medidata_studies_close_date, medidata_studies_is_production, medidata_studies_uuid, studies_id, studies_study_design_id, studies_name, studies_external_id, studies_parent_study_id, studies_environment_id, studies_live, studies_external_name, studies_rand_only, studies_unblinded, studies_is_shipping_algorithm_running, studies_randomization_api_locked, studies_dispensation_api_locked, studies_include_address_in_shipping_email, studies_allow_quarantining, studies_file_upload_rules, studies_needs_design_by_wizard, studies_can_generate_blocks, studies_advanced_dosing, studies_capping, studies_subject_identification_version, studies_new_countries_require_qp_release, studies_lots_are_blinded, studies_conditional_treatment_unblinded_subjects, depots_id, depots_parent_id, depots_study_id, depots_medidata_depot_id, depots_active_for_drug_shipping, depots_emails, type, branch) FROM stdin;
278	TestStudy1	\N	239	2435431	\N					\N								\N	\N	f	1a18ad1f-5a1c-42cf-8698-1b27b2cfe1c1	1	1	TestStudy1	278	\N	\N	f	\N	f	f	f	f	f	f	t	2	f	t	f	f	1	f	t	0	12	\N	1	12	t	\N	satisfied	PH0
159	Mediflexs	\N	135	Mediflexs	\N					\N								\N	\N	t	1e829b5f-039d-4636-9a9a-8d3ea6512e5f	580	643	Mediflexs	159	\N	\N	f	\N	f	f	f	f	f	f	f	0	f	f	t	f	1	f	t	0	1878	\N	580	1877	t	\N	satisfied	PH1
161	Mediflexs (UAT)	\N	135	MediflexsUAT	\N					\N		Mediflex UAT Protocol						\N	\N	f	167fbbef-f5f9-4108-a609-010b83d3ae15	582	646	Mediflexs (UAT)	161	\N	\N	f	\N	f	f	f	f	f	f	f	0	f	f	t	t	1	f	t	0	1880	\N	582	1879	t	\N	satisfied	PH2
315	BalRaveSandboxStudy001 (UAT)	\N	284	BRS-001	\N					\N								\N	2016-10-12 04:00:00-04	f	b7a02355-7afd-4c7d-8183-3a5dbbc00c4b	12	12	BalRaveSandboxStudy001 (UAT)	315	\N	\N	f	\N	f	t	f	f	f	f	f	0	f	f	t	f	1	f	t	0	28	\N	12	28	t	\N	satisfied	PH3
20147	KChiu_testing	\N	239	9001	\N					\N								\N	\N	f	a221bc7a-42ea-4584-b132-1bc99c838208	588	657	KChiu_testing	20147	\N	\N	f	\N	f	f	f	f	f	f	t	2	f	f	t	f	1	f	f	0	1955	\N	588	1954	t	\N	satisfied	PH4
20155	NandanStudy	\N	239	101	\N					\N								\N	\N	f	e76dda3b-0085-4e89-9902-973184fc07e4	589	658	NandanStudy	20155	\N	\N	f	\N	f	f	f	f	f	f	t	2	f	t	t	t	1	f	f	0	1960	\N	589	1959	t	\N	satisfied	PH5
314	MRK Study	\N	239	MRKSTUDY	\N					\N								\N	\N	f	73cd58b2-3efc-4556-91f7-dfe031805b20	11	11	MRK Study	314	\N	\N	f	\N	f	f	f	f	f	f	t	1	f	t	t	t	1	f	f	0	2009	\N	11	2008	t	\N	satisfied	PH6
159	Mediflexs	\N	135	Mediflexs	\N					\N								\N	\N	t	1e829b5f-039d-4636-9a9a-8d3ea6512e5f	580	643	Mediflexs	159	\N	\N	f	\N	f	f	f	f	f	f	f	0	f	f	t	f	1	f	t	0	1878	\N	580	1877	t	\N	satisfied	PH7
302	DemophyneKD	\N	301	122134	\N					\N								\N	2014-01-01 00:00:00-05	f	4ad52a99-779a-4ea7-a412-6f9c8474a41a	6	6	DemophyneKD	302	\N	\N	f	\N	f	f	f	f	f	f	f	0	f	t	t	t	1	f	t	0	30	\N	6	30	t	\N	excluded	
\.


--
-- PostgreSQL database dump complete
--

