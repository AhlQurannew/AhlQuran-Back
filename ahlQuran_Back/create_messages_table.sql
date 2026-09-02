--
-- PostgreSQL database dump
--

\restrict hT2SHNifMMTt8DeAu2bDaCi4qmrVWuLkGZuzVbnKqHd0J5AKMKxO0RhX3ImAUe3

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

ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS fk_messages_president;
DROP INDEX IF EXISTS public.ix_messages_sender_role;
DROP INDEX IF EXISTS public.ix_messages_president_id;
DROP INDEX IF EXISTS public.ix_messages_id;
DROP INDEX IF EXISTS public.ix_messages_created_at;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_pkey;
ALTER TABLE IF EXISTS public.messages ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.messages_id_seq;
DROP TABLE IF EXISTS public.messages;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: ahlquran_user
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    sender_id integer NOT NULL,
    sender_name character varying(255) NOT NULL,
    sender_role public.senderrole NOT NULL,
    message text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    president_id integer NOT NULL
);


ALTER TABLE public.messages OWNER TO ahlquran_user;

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: ahlquran_user
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.messages_id_seq OWNER TO ahlquran_user;

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ahlquran_user
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: ahlquran_user
--

COPY public.messages (id, sender_id, sender_name, sender_role, message, created_at, president_id) FROM stdin;
1	25	abdou badi	teacher	hello	2026-02-09 20:30:17.419267+00	1
2	1	raouf fer	president	sup	2026-02-09 20:35:10.675894+00	1
3	27	ziki nassim	supervisor	sup	2026-02-09 20:42:07.506159+00	1
\.


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ahlquran_user
--

SELECT pg_catalog.setval('public.messages_id_seq', 3, true);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: ix_messages_created_at; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_messages_created_at ON public.messages USING btree (created_at);


--
-- Name: ix_messages_id; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_messages_id ON public.messages USING btree (id);


--
-- Name: ix_messages_president_id; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_messages_president_id ON public.messages USING btree (president_id);


--
-- Name: ix_messages_sender_role; Type: INDEX; Schema: public; Owner: ahlquran_user
--

CREATE INDEX ix_messages_sender_role ON public.messages USING btree (sender_role);


--
-- Name: messages fk_messages_president; Type: FK CONSTRAINT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_messages_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ahlquran_user
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict hT2SHNifMMTt8DeAu2bDaCi4qmrVWuLkGZuzVbnKqHd0J5AKMKxO0RhX3ImAUe3

