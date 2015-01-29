
CREATE TABLE "deal_BTCUSD" (
    id bigint NOT NULL,
    size numeric(20,15) NOT NULL,
    price numeric(20,15) NOT NULL,
    "orderBuyId" bigint NOT NULL,
    "orderSellId" bigint NOT NULL,
    "createdAt" bigint NOT NULL,
    "userBuyId" bigint NOT NULL,
    "userSellId" bigint NOT NULL,
    "buyerFee" numeric(20,15) NOT NULL,
    "sellerFee" numeric(20,15) NOT NULL,
    side boolean NOT NULL
);


ALTER TABLE public."deal_BTCUSD" OWNER TO postgres;

--
-- Name: order_BTCUSD; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "order_BTCUSD" (
    id bigint NOT NULL,
    "userId" bigint NOT NULL,
    size numeric(20,15) NOT NULL,
    "offset" numeric(20,15),
    price numeric(20,15),
    "createdAt" bigint NOT NULL,
    "updatedAt" bigint,
    status character varying(40) NOT NULL,
    type character varying(20) NOT NULL,
    side boolean NOT NULL
);


ALTER TABLE public."order_BTCUSD" OWNER TO postgres;

--
-- Name: user_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE user_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_log_id_seq OWNER TO postgres;

--
-- Name: user_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE user_log (
    id integer DEFAULT nextval('user_log_id_seq'::regclass) NOT NULL,
    "userId" integer,
    "createdAt" bigint,
    action character varying(40) DEFAULT NULL::character varying,
    data text NOT NULL,
    ip character varying(30) DEFAULT NULL::character varying
);


ALTER TABLE public.user_log OWNER TO postgres;

--
-- PostgreSQL database dump complete
--

