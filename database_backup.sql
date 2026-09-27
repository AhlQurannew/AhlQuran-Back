--
-- PostgreSQL database dump
--

\restrict xWLuV2jEjX2VqxygeDzQhlCb53dDAJqUmiqUyukYLc4P6ktSlow9g3hSCp20ok4

-- Dumped from database version 15.16
-- Dumped by pg_dump version 15.16

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

--
-- Name: achievementtype; Type: TYPE; Schema: public; Owner: Rahim
--

CREATE TYPE public.achievementtype AS ENUM (
    'normal',
    'small',
    'big'
);


ALTER TYPE public.achievementtype OWNER TO "Rahim";

--
-- Name: attendancestatus; Type: TYPE; Schema: public; Owner: Rahim
--

CREATE TYPE public.attendancestatus AS ENUM (
    'present',
    'late',
    'absent',
    'excused'
);


ALTER TYPE public.attendancestatus OWNER TO "Rahim";

--
-- Name: participationstatus; Type: TYPE; Schema: public; Owner: Rahim
--

CREATE TYPE public.participationstatus AS ENUM (
    'PRESENT',
    'ABSENT',
    'EXCUSED',
    'LATE',
    'LEFT_EARLY'
);


ALTER TYPE public.participationstatus OWNER TO "Rahim";

--
-- Name: senderrole; Type: TYPE; Schema: public; Owner: Rahim
--

CREATE TYPE public.senderrole AS ENUM (
    'teacher',
    'supervisor',
    'president'
);


ALTER TYPE public.senderrole OWNER TO "Rahim";

--
-- Name: userroleenum; Type: TYPE; Schema: public; Owner: Rahim
--

CREATE TYPE public.userroleenum AS ENUM (
    'PRESIDENT',
    'SUPERVISOR',
    'TEACHER',
    'STUDENT',
    'GUARDIAN'
);


ALTER TYPE public.userroleenum OWNER TO "Rahim";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: achievements; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.achievements (
    id integer NOT NULL,
    student_id integer NOT NULL,
    from_surah integer NOT NULL,
    to_surah integer NOT NULL,
    from_verse integer NOT NULL,
    to_verse integer NOT NULL,
    note text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    achievement_type public.achievementtype DEFAULT 'normal'::public.achievementtype NOT NULL,
    date character varying(10),
    president_id integer NOT NULL
);


ALTER TABLE public.achievements OWNER TO "Rahim";

--
-- Name: achievements_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.achievements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.achievements_id_seq OWNER TO "Rahim";

--
-- Name: achievements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.achievements_id_seq OWNED BY public.achievements.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.admins (
    id integer NOT NULL,
    "user" character varying NOT NULL,
    password character varying NOT NULL,
    role character varying NOT NULL,
    created_by_id integer,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.admins OWNER TO "Rahim";

--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.admins_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admins_id_seq OWNER TO "Rahim";

--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.admins_id_seq OWNED BY public.admins.id;


--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO "Rahim";

--
-- Name: attendances; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.attendances (
    id integer NOT NULL,
    student_id integer NOT NULL,
    date character varying(10) NOT NULL,
    status character varying(20) NOT NULL,
    notes text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    president_id integer NOT NULL,
    CONSTRAINT attendances_status_check CHECK (((status)::text = ANY (ARRAY[('present'::character varying)::text, ('late'::character varying)::text, ('absent'::character varying)::text, ('excused'::character varying)::text])))
);


ALTER TABLE public.attendances OWNER TO "Rahim";

--
-- Name: attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.attendances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendances_id_seq OWNER TO "Rahim";

--
-- Name: attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.attendances_id_seq OWNED BY public.attendances.id;


--
-- Name: guardians; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.guardians (
    id integer NOT NULL,
    user_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    relationship_to_student character varying(50) NOT NULL,
    date_of_birth character varying(20),
    phone_number character varying(20),
    email character varying(255),
    job character varying(100),
    address character varying(255),
    created_at timestamp with time zone NOT NULL,
    created_by_id integer NOT NULL,
    student_id integer,
    president_id integer NOT NULL
);


ALTER TABLE public.guardians OWNER TO "Rahim";

--
-- Name: guardians_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.guardians_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.guardians_id_seq OWNER TO "Rahim";

--
-- Name: guardians_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.guardians_id_seq OWNED BY public.guardians.id;


--
-- Name: lecture_teachers; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.lecture_teachers (
    lecture_id integer NOT NULL,
    teacher_id integer NOT NULL
);


ALTER TABLE public.lecture_teachers OWNER TO "Rahim";

--
-- Name: lectures; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.lectures (
    id integer NOT NULL,
    lecture_name_ar character varying(200) NOT NULL,
    lecture_name_en character varying(200) NOT NULL,
    circle_type character varying(100) NOT NULL,
    category character varying(50) NOT NULL,
    shown_on_website boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    president_id integer NOT NULL
);


ALTER TABLE public.lectures OWNER TO "Rahim";

--
-- Name: lectures_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.lectures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lectures_id_seq OWNER TO "Rahim";

--
-- Name: lectures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.lectures_id_seq OWNED BY public.lectures.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: Rahim
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


ALTER TABLE public.messages OWNER TO "Rahim";

--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.messages_id_seq OWNER TO "Rahim";

--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: presidents; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.presidents (
    id integer NOT NULL,
    user_id integer NOT NULL,
    school_name character varying(100) NOT NULL,
    phone_number character varying(20),
    approval_date timestamp without time zone,
    approved_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    is_verified boolean DEFAULT false NOT NULL
);


ALTER TABLE public.presidents OWNER TO "Rahim";

--
-- Name: presidents_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.presidents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.presidents_id_seq OWNER TO "Rahim";

--
-- Name: presidents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.presidents_id_seq OWNED BY public.presidents.id;


--
-- Name: session_participations; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.session_participations (
    id integer NOT NULL,
    student_id integer NOT NULL,
    session_id integer,
    status public.participationstatus NOT NULL,
    notes text,
    score double precision,
    verses_recited character varying(100),
    mistakes_count integer,
    memorized_verses character varying(100),
    revision_verses character varying(100),
    behavior_rating integer,
    participation_level integer,
    marked_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone,
    recorded_by_id integer,
    lecture_id integer
);


ALTER TABLE public.session_participations OWNER TO "Rahim";

--
-- Name: session_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.session_participations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.session_participations_id_seq OWNER TO "Rahim";

--
-- Name: session_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.session_participations_id_seq OWNED BY public.session_participations.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    teacher_id integer,
    session_date timestamp without time zone NOT NULL,
    session_time character varying(20) NOT NULL,
    duration_minutes integer NOT NULL,
    topic character varying(200) NOT NULL,
    description text,
    location character varying(100),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp without time zone
);


ALTER TABLE public.sessions OWNER TO "Rahim";

--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.sessions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sessions_id_seq OWNER TO "Rahim";

--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: students; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.students (
    id integer NOT NULL,
    user_id integer NOT NULL,
    enrollment_date timestamp with time zone NOT NULL,
    parent_name character varying(255),
    parent_phone character varying(20),
    guardian_email character varying(255),
    created_by_id integer NOT NULL,
    "Golden" boolean,
    sex character varying(10),
    date_of_birth character varying(20),
    place_of_birth character varying(100),
    home_address character varying(255),
    nationality character varying(50),
    academic_level character varying(50),
    grade character varying(50),
    school_name character varying(100),
    guardian_id integer,
    first_name_en character varying(50),
    last_name_en character varying(50),
    father_status character varying(50),
    mother_status character varying(50),
    president_id integer NOT NULL
);


ALTER TABLE public.students OWNER TO "Rahim";

--
-- Name: students_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.students_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.students_id_seq OWNER TO "Rahim";

--
-- Name: students_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.students_id_seq OWNED BY public.students.id;


--
-- Name: supervisors; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.supervisors (
    id integer NOT NULL,
    user_id integer NOT NULL,
    created_by_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    president_id integer NOT NULL
);


ALTER TABLE public.supervisors OWNER TO "Rahim";

--
-- Name: supervisors_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.supervisors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.supervisors_id_seq OWNER TO "Rahim";

--
-- Name: supervisors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.supervisors_id_seq OWNED BY public.supervisors.id;


--
-- Name: teacher_attendances; Type: TABLE; Schema: public; Owner: Rahim
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
    CONSTRAINT teacher_attendances_status_check CHECK (((status)::text = ANY (ARRAY[('present'::character varying)::text, ('late'::character varying)::text, ('absent'::character varying)::text, ('excused'::character varying)::text])))
);


ALTER TABLE public.teacher_attendances OWNER TO "Rahim";

--
-- Name: teacher_attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.teacher_attendances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teacher_attendances_id_seq OWNER TO "Rahim";

--
-- Name: teacher_attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.teacher_attendances_id_seq OWNED BY public.teacher_attendances.id;


--
-- Name: teachers; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.teachers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    riwaya character varying(100) NOT NULL,
    hire_date timestamp with time zone NOT NULL,
    created_by_id integer NOT NULL,
    president_id integer NOT NULL
);


ALTER TABLE public.teachers OWNER TO "Rahim";

--
-- Name: teachers_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.teachers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teachers_id_seq OWNER TO "Rahim";

--
-- Name: teachers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.teachers_id_seq OWNED BY public.teachers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.users (
    id integer NOT NULL,
    firstname character varying(50) NOT NULL,
    lastname character varying(50) NOT NULL,
    email character varying(255) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    role public.userroleenum NOT NULL,
    is_active boolean NOT NULL
);


ALTER TABLE public.users OWNER TO "Rahim";

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO "Rahim";

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: weekly_schedules; Type: TABLE; Schema: public; Owner: Rahim
--

CREATE TABLE public.weekly_schedules (
    id integer NOT NULL,
    lecture_id integer NOT NULL,
    day_of_week character varying(20) NOT NULL,
    start_time character varying(10) NOT NULL,
    end_time character varying(10) NOT NULL,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.weekly_schedules OWNER TO "Rahim";

--
-- Name: weekly_schedules_id_seq; Type: SEQUENCE; Schema: public; Owner: Rahim
--

CREATE SEQUENCE public.weekly_schedules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.weekly_schedules_id_seq OWNER TO "Rahim";

--
-- Name: weekly_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Rahim
--

ALTER SEQUENCE public.weekly_schedules_id_seq OWNED BY public.weekly_schedules.id;


--
-- Name: achievements id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.achievements ALTER COLUMN id SET DEFAULT nextval('public.achievements_id_seq'::regclass);


--
-- Name: admins id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.admins ALTER COLUMN id SET DEFAULT nextval('public.admins_id_seq'::regclass);


--
-- Name: attendances id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.attendances ALTER COLUMN id SET DEFAULT nextval('public.attendances_id_seq'::regclass);


--
-- Name: guardians id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.guardians ALTER COLUMN id SET DEFAULT nextval('public.guardians_id_seq'::regclass);


--
-- Name: lectures id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.lectures ALTER COLUMN id SET DEFAULT nextval('public.lectures_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: presidents id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.presidents ALTER COLUMN id SET DEFAULT nextval('public.presidents_id_seq'::regclass);


--
-- Name: session_participations id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.session_participations ALTER COLUMN id SET DEFAULT nextval('public.session_participations_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: students id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.students ALTER COLUMN id SET DEFAULT nextval('public.students_id_seq'::regclass);


--
-- Name: supervisors id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.supervisors ALTER COLUMN id SET DEFAULT nextval('public.supervisors_id_seq'::regclass);


--
-- Name: teacher_attendances id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teacher_attendances ALTER COLUMN id SET DEFAULT nextval('public.teacher_attendances_id_seq'::regclass);


--
-- Name: teachers id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teachers ALTER COLUMN id SET DEFAULT nextval('public.teachers_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: weekly_schedules id; Type: DEFAULT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.weekly_schedules ALTER COLUMN id SET DEFAULT nextval('public.weekly_schedules_id_seq'::regclass);


--
-- Data for Name: achievements; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.achievements (id, student_id, from_surah, to_surah, from_verse, to_verse, note, created_at, updated_at, achievement_type, date, president_id) FROM stdin;
3	3	1	2	1	1	19	2026-02-07 22:47:42.394409+00	\N	normal	07-02-2026	1
4	3	2	6	6	5	19	2026-02-08 18:42:02.603741+00	\N	normal	08-02-2026	1
6	4	1	1	3	4	\N	2026-02-08 22:07:13.88608+00	\N	normal	08-02-2026	1
7	4	1	1	1	2	\N	2026-02-08 22:07:28.209831+00	\N	normal	08-02-2026	1
10	3	6	8	6	1	19	2026-02-16 20:11:56.341602+00	\N	normal	16-02-2026	1
11	3	8	10	2	2	20	2026-02-19 00:25:21.863759+00	\N	normal	19-02-2026	1
12	5	1	2	1	1	19	2026-02-20 22:09:36.805847+00	\N	normal	20-02-2026	1
13	3	1	2	1	1	19	2026-02-20 22:22:12.13417+00	\N	small	20-02-2026	1
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.admins (id, "user", password, role, created_by_id, created_at) FROM stdin;
1	admin	admin123	admin	\N	2025-12-12 18:38:55.268902+00
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.alembic_version (version_num) FROM stdin;
001
\.


--
-- Data for Name: attendances; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.attendances (id, student_id, date, status, notes, created_at, updated_at, president_id) FROM stdin;
4	3	06-02-2026	absent	\N	2026-02-06 14:02:31.807883+00	\N	1
5	4	06-02-2026	late	\N	2026-02-06 14:02:31.964174+00	\N	1
6	5	06-02-2026	present	\N	2026-02-06 14:02:32.045823+00	\N	1
7	3	07-02-2026	late	\N	2026-02-07 08:25:43.005486+00	\N	1
8	4	07-02-2026	present	\N	2026-02-07 08:25:43.082546+00	\N	1
9	5	07-02-2026	present	\N	2026-02-07 08:25:43.163047+00	\N	1
11	4	08-02-2026	present	\N	2026-02-08 12:37:31.640007+00	2026-02-08 17:56:02.950007+00	1
10	3	08-02-2026	late	\N	2026-02-08 12:37:31.532407+00	2026-02-08 21:56:20.086884+00	1
12	5	08-02-2026	present	\N	2026-02-08 12:37:31.727827+00	2026-02-08 21:56:20.2589+00	1
14	3	09-02-2026	present	\N	2026-02-09 19:47:43.365905+00	\N	1
15	4	09-02-2026	present	\N	2026-02-09 19:47:43.51031+00	\N	1
16	5	09-02-2026	present	\N	2026-02-09 19:47:43.569873+00	\N	1
17	3	15-02-2026	present	\N	2026-02-15 09:16:04.717966+00	\N	1
18	4	15-02-2026	present	\N	2026-02-15 09:16:04.781369+00	\N	1
19	5	15-02-2026	present	\N	2026-02-15 09:16:04.861883+00	\N	1
20	6	15-02-2026	present	\N	2026-02-15 09:16:04.917269+00	\N	1
24	6	16-02-2026	present	\N	2026-02-16 11:01:44.064351+00	\N	1
21	3	16-02-2026	late	\N	2026-02-16 11:01:43.870499+00	2026-02-16 20:12:06.455691+00	1
23	5	16-02-2026	absent	\N	2026-02-16 11:01:44.004102+00	2026-02-16 20:12:20.46495+00	1
22	4	16-02-2026	present	\N	2026-02-16 11:01:43.943509+00	2026-02-16 20:14:23.570942+00	1
25	3	06-01-2026	present	\N	2026-02-18 23:52:22.097833+00	\N	1
26	4	06-01-2026	present	\N	2026-02-18 23:52:22.288755+00	\N	1
27	5	06-01-2026	present	\N	2026-02-18 23:52:22.338774+00	\N	1
28	6	06-01-2026	present	\N	2026-02-18 23:52:22.393353+00	\N	1
29	3	20-02-2026	present	\N	2026-02-20 22:10:05.4024+00	\N	1
30	4	20-02-2026	present	\N	2026-02-20 22:10:05.479357+00	\N	1
31	5	20-02-2026	present	\N	2026-02-20 22:10:05.533081+00	\N	1
32	6	20-02-2026	present	\N	2026-02-20 22:10:05.599879+00	\N	1
\.


--
-- Data for Name: guardians; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.guardians (id, user_id, first_name, last_name, relationship_to_student, date_of_birth, phone_number, email, job, address, created_at, created_by_id, student_id, president_id) FROM stdin;
4	24	brahim	khadraoui	father	2000-12-04	0554290442	brahimlabo@gmail.com	teacher	bab ezzouar	2025-12-16 07:37:39.72651+00	1	4	1
5	32	lanoub	taroub	father	1952-02-20	0442928834	lanoub12@gmail.com	prof	lanoub	2026-02-15 09:15:41.297193+00	1	6	1
1	15	jakopa	boswait	father	2004-12-16	0554290994	abdoufourbadidud@gmail.com			2025-12-15 05:11:05.060642+00	1	2	1
9	34	Test	Guardian	Father		1234567890	guardian@test.com			2026-02-18 14:44:34.334261+00	1	3	1
2	16	farid	fergua	father	1969-04-18	0555541829	faridFerg@gmail.com			2025-12-15 07:41:56.256593+00	1	\N	1
\.


--
-- Data for Name: lecture_teachers; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.lecture_teachers (lecture_id, teacher_id) FROM stdin;
1	3
5	3
1	4
5	5
1	5
6	3
6	5
6	6
\.


--
-- Data for Name: lectures; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.lectures (id, lecture_name_ar, lecture_name_en, circle_type, category, shown_on_website, created_at, updated_at, president_id) FROM stdin;
5	رؤوف	raouf	memorization and revision	both	t	2025-12-16 07:54:11.582474+00	\N	1
1	حلقة أحمد 	ahmed lecture	memorization and revision	male	t	2025-12-14 14:15:30.300166+00	2026-04-30 09:29:14.82462+00	1
6	حلقة طياب	tyabo lecture	memorization and revision	both	t	2026-02-15 09:14:12.914713+00	2026-04-30 09:29:56.940357+00	1
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.messages (id, sender_id, sender_name, sender_role, message, created_at, president_id) FROM stdin;
1	25	abdou badi	teacher	hello	2026-02-09 20:30:17.419267+00	1
2	1	raouf fer	president	sup	2026-02-09 20:35:10.675894+00	1
3	27	ziki nassim	supervisor	sup	2026-02-09 20:42:07.506159+00	1
4	25	abdou badi	teacher	سلام	2026-02-16 20:13:33.235342+00	1
\.


--
-- Data for Name: presidents; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.presidents (id, user_id, school_name, phone_number, approval_date, approved_by, created_at, is_verified) FROM stdin;
2	2	سلمان الفارسي	\N	\N	\N	2025-12-12 18:45:21.434315+00	f
3	3	سلمان الفارسي	\N	\N	\N	2025-12-12 18:45:42.422488+00	f
4	4	سلمان الفارسي	\N	\N	\N	2025-12-12 18:48:52.842527+00	f
5	5	سلمان الفارسي	\N	\N	\N	2025-12-12 18:50:44.476185+00	f
1	1	سلمان الفارسي	\N	2025-12-12 19:06:07.652237	\N	2025-12-12 18:41:23.41316+00	f
6	26	nouz school	0555555555	2026-02-08 21:29:28.275675	\N	2026-02-08 21:26:43.59202+00	f
7	28	yakoub school	0554290992	2026-02-09 11:51:49.543296	\N	2026-02-09 11:51:26.306271+00	f
8	29	yakub school	0554290993	2026-02-09 12:00:44.542338	\N	2026-02-09 11:59:39.912285+00	f
\.


--
-- Data for Name: session_participations; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.session_participations (id, student_id, session_id, status, notes, score, verses_recited, mistakes_count, memorized_verses, revision_verses, behavior_rating, participation_level, marked_at, updated_at, recorded_by_id, lecture_id) FROM stdin;
3	5	\N	PRESENT	\N	\N	\N	0	\N	\N	\N	\N	2025-12-16 07:33:00.446243+00	\N	\N	1
7	6	\N	PRESENT	\N	\N	\N	0	\N	\N	\N	\N	2026-02-15 09:12:46.536213+00	\N	\N	1
8	3	\N	PRESENT	\N	\N	\N	0	\N	\N	\N	\N	2026-02-16 20:15:52.385445+00	\N	\N	1
9	4	\N	PRESENT	\N	\N	\N	0	\N	\N	\N	\N	2026-04-30 09:30:14.167201+00	\N	\N	1
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.sessions (id, teacher_id, session_date, session_time, duration_minutes, topic, description, location, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.students (id, user_id, enrollment_date, parent_name, parent_phone, guardian_email, created_by_id, "Golden", sex, date_of_birth, place_of_birth, home_address, nationality, academic_level, grade, school_name, guardian_id, first_name_en, last_name_en, father_status, mother_status, president_id) FROM stdin;
2	13	2025-12-13 16:02:05.966482+00	hd dfd	0555368741	df@gmail.com	1	f	male	2011-12-13	bourouba	aadl	Algerian	متوسط	سنة اولى متوسط	lyayda	\N			alive	alive	1
4	21	2025-12-16 07:26:02.205469+00	\N	0554290994	\N	1	f	male	1992-12-17	fordlo	bab ezzouar	Algerian	تحضيري	تحضيري		\N	raouf	nigro	alive	alive	1
5	22	2025-12-16 07:33:00.444777+00	\N	0554290334	\N	1	f	male	2025-12-03	boubsila	bab eloued	Algerian	تحضيري	تحضيري		\N	abdou	moutasim	alive	alive	1
6	30	2026-02-15 09:12:46.529734+00	\N	0554190991	\N	1	f	male	2004-02-16	borj el kiffan	bab ezzouar	Algerian	جامعي	ماستر	univ 1 dentaire	\N	djalil	stayfi	alive	alive	1
3	14	2025-12-14 12:02:15.39731+00	سليم معلم	055889966	slim@gmail.com	1	f	male	2012-12-14	alharachh	aadl	Algerian	تحضيري	تحضيري	ad	\N	ahmedr	moutasim	alive	alive	1
\.


--
-- Data for Name: supervisors; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.supervisors (id, user_id, created_by_id, created_at, president_id) FROM stdin;
1	27	26	2026-02-08 22:00:39.19422+00	1
2	33	1	2026-02-15 09:16:38.301648+00	1
\.


--
-- Data for Name: teacher_attendances; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.teacher_attendances (id, teacher_id, president_id, date, status, notes, created_at, updated_at) FROM stdin;
1	3	1	09-02-2026	late	\N	2026-02-09 12:44:28.98233+00	\N
2	4	1	09-02-2026	late	\N	2026-02-09 12:44:29.104423+00	2026-02-09 13:20:28.16855+00
3	5	1	09-02-2026	late	\N	2026-02-09 12:44:29.196994+00	2026-02-09 13:20:28.25933+00
4	3	1	15-02-2026	present	\N	2026-02-15 09:16:14.686453+00	\N
5	4	1	15-02-2026	late	\N	2026-02-15 09:16:14.759651+00	\N
6	5	1	15-02-2026	present	\N	2026-02-15 09:16:14.819851+00	\N
7	6	1	15-02-2026	absent	\N	2026-02-15 09:16:14.876447+00	\N
8	3	1	20-02-2026	present	\N	2026-02-20 22:09:54.782674+00	\N
9	4	1	20-02-2026	present	\N	2026-02-20 22:09:54.885326+00	\N
10	5	1	20-02-2026	present	\N	2026-02-20 22:09:54.954683+00	\N
11	6	1	20-02-2026	present	\N	2026-02-20 22:09:55.012506+00	\N
\.


--
-- Data for Name: teachers; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.teachers (id, user_id, riwaya, hire_date, created_by_id, president_id) FROM stdin;
3	20	hafs	2025-12-15 23:02:58.437413+00	1	1
4	23	hafs	2025-12-16 07:34:49.31114+00	1	1
5	25	hafs	2026-02-04 11:16:25.992559+00	1	1
6	31	hafs	2026-02-15 09:13:15.741383+00	1	1
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.users (id, firstname, lastname, email, hashed_password, role, is_active) FROM stdin;
2	younes	pres	younew@gmail.com	koko1234_?	PRESIDENT	f
3	younes	pres	younes@gmail.com	koko1234_?	PRESIDENT	f
4	abdou	abd	abdou@gmail.com	koko1234_?	PRESIDENT	f
5	abdou	abd	abdouu@gmail.com	koko1234_?	PRESIDENT	f
12	'rtrty	terte	ertert@gmail.com	$2b$12$jNTMshJ7zx4moSZwuduOKuDhJ44I.3egvbkmvJl8La0e/rcEooX8y	STUDENT	t
13	أحمد	يعقوب	yakoube@gmail.com	$2b$12$1eIsEjFhRUesL/0WfAxOqelBm5wjSF54xXnQ.EwWH3U7Y9.YDV0Y2	STUDENT	t
14	أحمد	معتصم	ahmedmoutasim@gmail.com	$2b$12$px3lATnkXd5IiJtvr1CuJ.zR6S7QknYNE8gw44E7bJNTj0MVRTbJe	STUDENT	t
18	raouf	sauzxa	raoufFer@gmail.com	l9vJlyOf1x	TEACHER	t
19	raouf	ferg	ferg@gmail.com	V0vsb02yk%	TEACHER	t
22	عبدو	معتصم	abdoulabbid@gmail.com	$2b$12$NGkbDdUsZ2tF/OXHxHkqtONVSesyYfDkm7eqlsJBfm6ai5Yzautri	STUDENT	t
23	houssam	rmila	houssam@gmail.com	cGatcybLTT	TEACHER	t
20	farid	chikh	chikh@gmail.com	$2b$12$hCnDwlsD8VZMuN05w6XXW.QqMtLgxV57nR5dpZ.4YSbFhQn4jkmI6	TEACHER	t
25	abdou	badi	abdou123@gmail.com	$2b$12$IcZJlT1gd4zFg1WrkTR9WuWjD8C2KIe3mr.iHwRDKX6vb71x3Pl6W	TEACHER	t
1	raouf	fer	raoufer@gmail.com	$2b$12$AuP8QWmdWBl6HJw9bwL0AeGm5Ac3HYPcKvcLgW4WURVSbrJrg8Pea	PRESIDENT	t
26	abdou	badido	abdoubadido@gmail.com	$2b$12$UwrTN2VkkQcpRx6G8qeetumldFxkkjc1NvShxQjgULViSLZxptq96	PRESIDENT	t
27	ziki	nassim	zikinassim@gmail.com	$2b$12$FpnQ7Z9t7xYdw6g4SiXWfuLVIjEaKmrd3PNZF4gpSr7JnqT8H2c8G	SUPERVISOR	t
28	yakoub	zamil	yakou@gmail.com	$2b$12$re4x8Ok4V8aamsKR9AHLAez5vw3iF4yBrAyezebPyPx3o5P970v/.	PRESIDENT	t
29	yakoub	ozamil	yakoub@gmail.com	$2b$12$nh9kyR9BOoqd2CaGW1rtGOfVkpIpzHOyZ4vUn95QZ4pNif9D1ZHoC	PRESIDENT	t
30	جليل	صطايفي	djalilstyfi@gmail.com	$2b$12$Ra0vVHkizd9ahANE3mjzvODnFp4EcXhsLrhbup1VMjOKZ/ugINYGe	STUDENT	t
31	nouz 	broz	nouzbroz@gmail.com	$2b$12$yBv7qDrXfHKO.Mst75/wX.33chmKHvBVx95X72klu3vwQDLIk4M/O	TEACHER	t
33	lanoub	taboub	lanoub1234@gmail.com	$2b$12$BVKXpawMM3/tcf54R8NG.O3cIB1rI41Kw0o3MA9DlJ8bfhm8n5U4K	SUPERVISOR	t
24	brahim	khadraoui	brahimlabo@gmail.com	$2b$12$GdStQ222/s6YVAoX2fdeau0pZbDCy9kPBftrEZL0Ar6VinNAgkhs6	GUARDIAN	t
32	lanoub	taroub	lanoub12@gmail.com	$2b$12$GdStQ222/s6YVAoX2fdeau0pZbDCy9kPBftrEZL0Ar6VinNAgkhs6	GUARDIAN	t
15	jakopa	boswait	abdoufourbadidud@gmail.com	$2b$12$GdStQ222/s6YVAoX2fdeau0pZbDCy9kPBftrEZL0Ar6VinNAgkhs6	GUARDIAN	t
34	Test	Guardian	guardian@test.com	$2b$12$ZdZGmH3uQjguzYJl.1t9Ye6yJe6U72XMtPjaJYX8jsC.O33Fn0J0C	GUARDIAN	t
16	farid	fergua	farfer3	$2b$12$k8T122scEITLlqBuNxAeP.XICPWceo5DxC3GjhGS0HfSSuA7xDRjO	GUARDIAN	t
21	رؤوف	ب	abdouforbadidud@gmail.com	$2b$12$1XNC.4skmKREDZNudTeCLuwakABXn.IJ8G.hNgtFf2R5fBhNFRQf2	STUDENT	t
\.


--
-- Data for Name: weekly_schedules; Type: TABLE DATA; Schema: public; Owner: Rahim
--

COPY public.weekly_schedules (id, lecture_id, day_of_week, start_time, end_time, created_at) FROM stdin;
48	5	الجمعة	08:53	08:59	2026-02-08 21:48:09.28547+00
51	1	السبت	15:15	17:15	2026-04-30 09:29:14.833376+00
53	6	الجمعة	10:14	10:16	2026-04-30 09:29:56.944787+00
\.


--
-- Name: achievements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.achievements_id_seq', 13, true);


--
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.admins_id_seq', 1, true);


--
-- Name: attendances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.attendances_id_seq', 32, true);


--
-- Name: guardians_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.guardians_id_seq', 9, true);


--
-- Name: lectures_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.lectures_id_seq', 6, true);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.messages_id_seq', 4, true);


--
-- Name: presidents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.presidents_id_seq', 8, true);


--
-- Name: session_participations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.session_participations_id_seq', 9, true);


--
-- Name: sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.sessions_id_seq', 1, false);


--
-- Name: students_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.students_id_seq', 6, true);


--
-- Name: supervisors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.supervisors_id_seq', 2, true);


--
-- Name: teacher_attendances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.teacher_attendances_id_seq', 11, true);


--
-- Name: teachers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.teachers_id_seq', 6, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.users_id_seq', 34, true);


--
-- Name: weekly_schedules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Rahim
--

SELECT pg_catalog.setval('public.weekly_schedules_id_seq', 53, true);


--
-- Name: achievements achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT achievements_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: attendances attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_pkey PRIMARY KEY (id);


--
-- Name: guardians guardians_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT guardians_pkey PRIMARY KEY (id);


--
-- Name: guardians guardians_user_id_key; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT guardians_user_id_key UNIQUE (user_id);


--
-- Name: lecture_teachers lecture_teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.lecture_teachers
    ADD CONSTRAINT lecture_teachers_pkey PRIMARY KEY (lecture_id, teacher_id);


--
-- Name: lectures lectures_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.lectures
    ADD CONSTRAINT lectures_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: presidents presidents_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.presidents
    ADD CONSTRAINT presidents_pkey PRIMARY KEY (id);


--
-- Name: session_participations session_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.session_participations
    ADD CONSTRAINT session_participations_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: students students_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_pkey PRIMARY KEY (id);


--
-- Name: students students_user_id_key; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_key UNIQUE (user_id);


--
-- Name: supervisors supervisors_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.supervisors
    ADD CONSTRAINT supervisors_pkey PRIMARY KEY (id);


--
-- Name: supervisors supervisors_user_id_key; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.supervisors
    ADD CONSTRAINT supervisors_user_id_key UNIQUE (user_id);


--
-- Name: teacher_attendances teacher_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teacher_attendances
    ADD CONSTRAINT teacher_attendances_pkey PRIMARY KEY (id);


--
-- Name: teachers teachers_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_pkey PRIMARY KEY (id);


--
-- Name: teachers teachers_user_id_key; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_user_id_key UNIQUE (user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: weekly_schedules weekly_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.weekly_schedules
    ADD CONSTRAINT weekly_schedules_pkey PRIMARY KEY (id);


--
-- Name: ix_achievements_date; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_achievements_date ON public.achievements USING btree (date);


--
-- Name: ix_achievements_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_achievements_id ON public.achievements USING btree (id);


--
-- Name: ix_achievements_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_achievements_president_id ON public.achievements USING btree (president_id);


--
-- Name: ix_admins_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_admins_id ON public.admins USING btree (id);


--
-- Name: ix_admins_user; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE UNIQUE INDEX ix_admins_user ON public.admins USING btree ("user");


--
-- Name: ix_attendance_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_attendance_president_id ON public.attendances USING btree (president_id);


--
-- Name: ix_attendances_date; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_attendances_date ON public.attendances USING btree (date);


--
-- Name: ix_attendances_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_attendances_id ON public.attendances USING btree (id);


--
-- Name: ix_attendances_student_date; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE UNIQUE INDEX ix_attendances_student_date ON public.attendances USING btree (student_id, date);


--
-- Name: ix_attendances_student_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_attendances_student_id ON public.attendances USING btree (student_id);


--
-- Name: ix_guardians_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_guardians_id ON public.guardians USING btree (id);


--
-- Name: ix_guardians_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_guardians_president_id ON public.guardians USING btree (president_id);


--
-- Name: ix_guardians_student_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_guardians_student_id ON public.guardians USING btree (student_id);


--
-- Name: ix_lectures_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_lectures_id ON public.lectures USING btree (id);


--
-- Name: ix_lectures_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_lectures_president_id ON public.lectures USING btree (president_id);


--
-- Name: ix_messages_created_at; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_messages_created_at ON public.messages USING btree (created_at);


--
-- Name: ix_messages_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_messages_id ON public.messages USING btree (id);


--
-- Name: ix_messages_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_messages_president_id ON public.messages USING btree (president_id);


--
-- Name: ix_messages_sender_role; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_messages_sender_role ON public.messages USING btree (sender_role);


--
-- Name: ix_presidents_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_presidents_id ON public.presidents USING btree (id);


--
-- Name: ix_presidents_user_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE UNIQUE INDEX ix_presidents_user_id ON public.presidents USING btree (user_id);


--
-- Name: ix_session_participations_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_session_participations_id ON public.session_participations USING btree (id);


--
-- Name: ix_session_participations_lecture_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_session_participations_lecture_id ON public.session_participations USING btree (lecture_id);


--
-- Name: ix_session_participations_session_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_session_participations_session_id ON public.session_participations USING btree (session_id);


--
-- Name: ix_session_participations_student_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_session_participations_student_id ON public.session_participations USING btree (student_id);


--
-- Name: ix_sessions_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_sessions_id ON public.sessions USING btree (id);


--
-- Name: ix_students_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_students_id ON public.students USING btree (id);


--
-- Name: ix_students_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_students_president_id ON public.students USING btree (president_id);


--
-- Name: ix_supervisors_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_supervisors_id ON public.supervisors USING btree (id);


--
-- Name: ix_supervisors_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_supervisors_president_id ON public.supervisors USING btree (president_id);


--
-- Name: ix_teacher_attendances_date; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_teacher_attendances_date ON public.teacher_attendances USING btree (date);


--
-- Name: ix_teacher_attendances_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_teacher_attendances_id ON public.teacher_attendances USING btree (id);


--
-- Name: ix_teacher_attendances_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_teacher_attendances_president_id ON public.teacher_attendances USING btree (president_id);


--
-- Name: ix_teacher_attendances_teacher_date; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE UNIQUE INDEX ix_teacher_attendances_teacher_date ON public.teacher_attendances USING btree (teacher_id, date);


--
-- Name: ix_teacher_attendances_teacher_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_teacher_attendances_teacher_id ON public.teacher_attendances USING btree (teacher_id);


--
-- Name: ix_teachers_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_teachers_id ON public.teachers USING btree (id);


--
-- Name: ix_teachers_president_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_teachers_president_id ON public.teachers USING btree (president_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_weekly_schedules_id; Type: INDEX; Schema: public; Owner: Rahim
--

CREATE INDEX ix_weekly_schedules_id ON public.weekly_schedules USING btree (id);


--
-- Name: achievements achievements_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT achievements_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: attendances attendances_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: achievements fk_achievements_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.achievements
    ADD CONSTRAINT fk_achievements_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: attendances fk_attendance_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT fk_attendance_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: guardians fk_guardians_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT fk_guardians_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: guardians fk_guardians_student_id; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT fk_guardians_student_id FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE SET NULL;


--
-- Name: lectures fk_lectures_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.lectures
    ADD CONSTRAINT fk_lectures_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: messages fk_messages_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT fk_messages_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: students fk_students_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT fk_students_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: supervisors fk_supervisors_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.supervisors
    ADD CONSTRAINT fk_supervisors_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: teachers fk_teachers_president; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT fk_teachers_president FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: guardians guardians_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT guardians_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: guardians guardians_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.guardians
    ADD CONSTRAINT guardians_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: lecture_teachers lecture_teachers_lecture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.lecture_teachers
    ADD CONSTRAINT lecture_teachers_lecture_id_fkey FOREIGN KEY (lecture_id) REFERENCES public.lectures(id) ON DELETE CASCADE;


--
-- Name: lecture_teachers lecture_teachers_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.lecture_teachers
    ADD CONSTRAINT lecture_teachers_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: messages messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: presidents presidents_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.presidents
    ADD CONSTRAINT presidents_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.admins(id) ON DELETE SET NULL;


--
-- Name: presidents presidents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.presidents
    ADD CONSTRAINT presidents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: session_participations session_participations_lecture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.session_participations
    ADD CONSTRAINT session_participations_lecture_id_fkey FOREIGN KEY (lecture_id) REFERENCES public.lectures(id) ON DELETE SET NULL;


--
-- Name: session_participations session_participations_recorded_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.session_participations
    ADD CONSTRAINT session_participations_recorded_by_id_fkey FOREIGN KEY (recorded_by_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: session_participations session_participations_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.session_participations
    ADD CONSTRAINT session_participations_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.sessions(id) ON DELETE CASCADE;


--
-- Name: session_participations session_participations_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.session_participations
    ADD CONSTRAINT session_participations_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: students students_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: students students_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.students
    ADD CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: supervisors supervisors_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.supervisors
    ADD CONSTRAINT supervisors_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: supervisors supervisors_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.supervisors
    ADD CONSTRAINT supervisors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: teacher_attendances teacher_attendances_president_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teacher_attendances
    ADD CONSTRAINT teacher_attendances_president_id_fkey FOREIGN KEY (president_id) REFERENCES public.presidents(id) ON DELETE CASCADE;


--
-- Name: teacher_attendances teacher_attendances_teacher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teacher_attendances
    ADD CONSTRAINT teacher_attendances_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.teachers(id) ON DELETE CASCADE;


--
-- Name: teachers teachers_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: teachers teachers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.teachers
    ADD CONSTRAINT teachers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: weekly_schedules weekly_schedules_lecture_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Rahim
--

ALTER TABLE ONLY public.weekly_schedules
    ADD CONSTRAINT weekly_schedules_lecture_id_fkey FOREIGN KEY (lecture_id) REFERENCES public.lectures(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict xWLuV2jEjX2VqxygeDzQhlCb53dDAJqUmiqUyukYLc4P6ktSlow9g3hSCp20ok4

