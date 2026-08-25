--
-- PostgreSQL database dump
--

\restrict l9JCAbKgAfFeORg1TDxGjYlGKHcVFfjQdELGM4QV0adM4EXdHe6UnzUkrh3huBV

-- Dumped from database version 15.15
-- Dumped by pg_dump version 15.15

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.teacher_attendances DROP CONSTRAINT IF EXISTS teacher_attendances_teacher_id_fkey;
ALTER TABLE IF EXISTS ONLY public.teacher_attendances DROP CONSTRAINT IF EXISTS teacher_attendances_president_id_fkey;
DROP INDEX IF EXISTS public.ix_teacher_attendances_teacher_id;
DROP INDEX IF EXISTS public.ix_teacher_attendances_teacher_date;
DROP INDEX IF EXISTS public.ix_teacher_attendances_president_id;
DROP INDEX IF EXISTS public.ix_teacher_attendances_id;
DROP INDEX IF EXISTS public.ix_teacher_attendances_date;
ALTER TABLE IF EXISTS ONLY public.teacher_attendances DROP CONSTRAINT IF EXISTS teacher_attendances_pkey;
ALTER TABLE IF EXISTS public.teacher_attendances ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.teacher_attendances_id_seq;
DROP TABLE IF EXISTS public.teacher_attendances;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: teacher_attendances; Type: TABLE; Schema: public; Owner: ahlquran_user
--

CREATE TABLE public.teacher_attendances (
    id integer NOT NULL,
    teacher_id integer NOT NULL,
    president_id integer,
    date character varying(10) NOT NULL,
    status character varying(20) NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    CONSTRAINT teacher_attendances_status_check CHECK (((status)::text = ANY ((ARRAY['present'::character varying, 'late'::character varying, 'absent'::character varying, 'excused'::character varying])::text[])))
);


ALTER TABLE public.teacher_attendances OWNER TO ahlquran_user;

--
-- Name: teacher_attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: ahlquran_user
--

CREATE SEQUENCE public.teacher_attendances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_attendances_id_seq OWNER TO ahlquran_user;

--
-- Name: teacher_attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ahlquran_user
--

ALTER SEQUENCE public.teacher_attendances_id_seq OWNED BY public.teacher_attendances.id;


--
-- Name: teacher_attendances id; Type: DEFAULT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.teacher_attendances ALTER COLUMN id SET DEFAULT nextval('public.teacher_attendances_id_seq'::regclass);


--
-- Data for Name: teacher_attendances; Type: TABLE DATA; Schema: public; Owner: ahlquran_user
--

COPY public.teacher_attendances (id, teacher_id, president_id, date, status, notes, created_at, updated_at) FROM stdin;
1	3	1	09-02-2026	late	\N	2026-02-09 12:44:28.98233+00	\N
2	4	1	09-02-2026	late	\N	2026-02-09 12:44:29.104423+00	2026-02-09 13:20:28.16855+00
3	5	1	09-02-2026	late	\N	2026-02-09 12:44:29.196994+00	2026-02-09 13:20:28.25933+00
\.


--
-- Name: teacher_attendances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ahlquran_user
--

SELECT pg_catalog.setval('public.teacher_attendances_id_seq', 3, true);


--
-- Name: teacher_attendances teacher_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.teacher_attendances
    ADD CONSTRAINT teacher_attendances_pkey PRIMARY KEY (id);


--
-- Name: ix_teacher_attendances_date; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_teacher_attendances_date ON public.teacher_attendances USING btree (date);


--
-- Name: ix_teacher_attendances_id; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_teacher_attendances_id ON public.teacher_attendances USING btree (id);


--
-- Name: ix_teacher_attendances_president_id; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_teacher_attendances_president_id ON public.teacher_attendances USING btree (president_id);


--
-- Name: ix_teacher_attendances_teacher_date; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE UNIQUE INDEX ix_teacher_attendances_teacher_date ON public.teacher_attendances USING btree (teacher_id, date);


--
-- Name: ix_teacher_attendances_teacher_id; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_teacher_attendances_teacher_id ON public.teacher_attendances USING btree (teacher_id);


--
-- Name: teacher_attendances teacher_attendances_president_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.teacher_attendances
    ADD CONSTRAINT teacher_attendances_president_id_fkey FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: teacher_attendances teacher_attendances_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.teacher_attendances
    ADD CONSTRAINT teacher_attendances_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict l9JCAbKgAfFeORg1TDxGjYlGKHcVFfjQdELGM4QV0adM4EXdHe6UnzUkrh3huBV

