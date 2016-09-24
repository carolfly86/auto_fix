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
300	Anar 2	\N	239	fcdf	\N					\N								\N	\N	f	831a035f-17ff-4269-adf6-5400dadb769e	5	5	Anar 2	300	\N	\N	f	\N	f	f	f	f	f	f	t	2	f	f	t	t	1	f	f	0	8	\N	5	8	t	\N	satisfied	PH0
1587	EricBStudy (Dev)	\N	284	ericbstudy	\N					\N								\N	\N	f	df1b63d5-29de-4347-9b91-96459805a03f	19	21	EricBStudy (Dev)	1587	\N	\N	f	\N	f	f	f	f	f	f	t	2	f	t	t	f	0	f	f	0	317	\N	19	317	f	ebitzegaio@mdsol.com	satisfied	PH1
2021	BalRaveSandboxRandAPILock001 (QTP)	\N	284	BRS-randlock-qtp	\N					\N								\N	\N	t	a9aac433-86b7-4013-a717-208c1fbc4364	27	33	BalRaveSandboxRandAPILock001 (QTP)	2021	\N	\N	t	\N	f	f	f	f	f	f	f	0	f	\N	f	f	1	f	t	0	63	\N	27	63	t	\N	excluded	
\.


--
-- PostgreSQL database dump complete
--

