CREATE EXTENSION postgis;
CREATE EXTENSION hstore;
CREATE TABLE public.gtfs_calendars (
    id bigint NOT NULL,
    service_id character varying NOT NULL,
    monday integer NOT NULL,
    tuesday integer NOT NULL,
    wednesday integer NOT NULL,
    thursday integer NOT NULL,
    friday integer NOT NULL,
    saturday integer NOT NULL,
    sunday integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    generated boolean NOT NULL
);
CREATE TABLE public.feed_versions (
    id bigint NOT NULL,
    feed_id bigint NOT NULL,
    feed_type character varying DEFAULT 'gtfs'::character varying NOT NULL,
    file character varying DEFAULT ''::character varying NOT NULL,
    earliest_calendar_date date NOT NULL,
    latest_calendar_date date NOT NULL,
    sha1 character varying NOT NULL,
    md5 character varying,
    tags public.hstore,
    fetched_at timestamp without time zone NOT NULL,
    imported_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    import_level integer DEFAULT 0 NOT NULL,
    url character varying DEFAULT ''::character varying NOT NULL,
    file_raw character varying,
    sha1_raw character varying,
    md5_raw character varying,
    file_feedvalidator character varying,
    deleted_at timestamp without time zone,
    sha1_dir character varying
);
CREATE TABLE public.change_payloads (
    id integer NOT NULL,
    payload json,
    changeset_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE public.change_payloads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.change_payloads_id_seq OWNED BY public.change_payloads.id;
CREATE TABLE public.changesets (
    id integer NOT NULL,
    notes text,
    applied boolean,
    applied_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    feed_id integer,
    feed_version_id integer
);
CREATE SEQUENCE public.changesets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.changesets_id_seq OWNED BY public.changesets.id;
CREATE TABLE public.current_feeds (
    id bigint NOT NULL,
    onestop_id character varying NOT NULL,
    url character varying,
    spec character varying DEFAULT 'gtfs'::character varying NOT NULL,
    tags public.hstore,
    last_fetched_at timestamp without time zone,
    last_imported_at timestamp without time zone,
    version integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    created_or_updated_in_changeset_id integer,
    geometry public.geography(Geometry,4326),
    active_feed_version_id integer,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    name character varying,
    type character varying,
    auth jsonb DEFAULT '{}'::jsonb NOT NULL,
    urls jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp without time zone,
    last_successful_fetch_at timestamp without time zone,
    last_fetch_error character varying DEFAULT ''::character varying NOT NULL,
    license jsonb DEFAULT '{}'::jsonb NOT NULL,
    other_ids jsonb DEFAULT '{}'::jsonb NOT NULL,
    associated_feeds jsonb DEFAULT '{}'::jsonb NOT NULL,
    languages jsonb DEFAULT '{}'::jsonb NOT NULL,
    feed_namespace_id character varying DEFAULT ''::character varying NOT NULL,
    file character varying DEFAULT ''::character varying NOT NULL
);
CREATE SEQUENCE public.current_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_feeds_id_seq OWNED BY public.current_feeds.id;
CREATE TABLE public.current_operators (
    id integer NOT NULL,
    name character varying,
    tags public.hstore,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    onestop_id character varying,
    geometry public.geography(Geometry,4326),
    created_or_updated_in_changeset_id integer,
    version integer,
    timezone character varying,
    short_name character varying,
    website character varying,
    country character varying,
    state character varying,
    metro character varying,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    associated_feeds jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp without time zone
);
CREATE SEQUENCE public.current_operators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_operators_id_seq OWNED BY public.current_operators.id;
CREATE TABLE public.current_operators_in_feed (
    id integer NOT NULL,
    gtfs_agency_id character varying,
    version integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    operator_id integer,
    feed_id integer,
    created_or_updated_in_changeset_id integer
);
CREATE SEQUENCE public.current_operators_in_feed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_operators_in_feed_id_seq OWNED BY public.current_operators_in_feed.id;
CREATE TABLE public.current_operators_serving_stop (
    id integer NOT NULL,
    stop_id integer NOT NULL,
    operator_id integer NOT NULL,
    tags public.hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_or_updated_in_changeset_id integer,
    version integer
);
CREATE SEQUENCE public.current_operators_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_operators_serving_stop_id_seq OWNED BY public.current_operators_serving_stop.id;
CREATE TABLE public.current_route_stop_patterns (
    id integer NOT NULL,
    onestop_id character varying,
    geometry public.geography(Geometry,4326),
    tags public.hstore,
    stop_pattern character varying[] DEFAULT '{}'::character varying[],
    version integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_or_updated_in_changeset_id integer,
    route_id integer,
    stop_distances double precision[] DEFAULT '{}'::double precision[],
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    geometry_source character varying
);
CREATE SEQUENCE public.current_route_stop_patterns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_route_stop_patterns_id_seq OWNED BY public.current_route_stop_patterns.id;
CREATE TABLE public.current_routes (
    id integer NOT NULL,
    onestop_id character varying,
    name character varying,
    tags public.hstore,
    operator_id integer,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    geometry public.geography(Geometry,4326),
    vehicle_type integer,
    color character varying,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    wheelchair_accessible character varying DEFAULT 'unknown'::character varying,
    bikes_allowed character varying DEFAULT 'unknown'::character varying
);
CREATE SEQUENCE public.current_routes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_routes_id_seq OWNED BY public.current_routes.id;
CREATE TABLE public.current_routes_serving_stop (
    id integer NOT NULL,
    route_id integer,
    stop_id integer,
    tags public.hstore,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE public.current_routes_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_routes_serving_stop_id_seq OWNED BY public.current_routes_serving_stop.id;
CREATE TABLE public.current_schedule_stop_pairs (
    id bigint NOT NULL,
    origin_id integer,
    destination_id integer,
    route_id integer,
    trip character varying,
    created_or_updated_in_changeset_id integer,
    version integer,
    trip_headsign character varying,
    origin_arrival_time character varying,
    origin_departure_time character varying,
    destination_arrival_time character varying,
    destination_departure_time character varying,
    frequency_start_time character varying,
    frequency_end_time character varying,
    tags public.hstore,
    service_start_date date,
    service_end_date date,
    service_added_dates date[] DEFAULT '{}'::date[],
    service_except_dates date[] DEFAULT '{}'::date[],
    service_days_of_week boolean[] DEFAULT '{}'::boolean[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    block_id character varying,
    trip_short_name character varying,
    shape_dist_traveled double precision,
    origin_timezone character varying,
    destination_timezone character varying,
    window_start character varying,
    window_end character varying,
    origin_timepoint_source character varying,
    destination_timepoint_source character varying,
    operator_id integer,
    wheelchair_accessible boolean,
    bikes_allowed boolean,
    pickup_type character varying,
    drop_off_type character varying,
    route_stop_pattern_id integer,
    origin_dist_traveled double precision,
    destination_dist_traveled double precision,
    feed_id integer,
    feed_version_id integer,
    frequency_type character varying,
    frequency_headway_seconds integer
);
CREATE SEQUENCE public.current_schedule_stop_pairs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_schedule_stop_pairs_id_seq OWNED BY public.current_schedule_stop_pairs.id;
CREATE TABLE public.current_stop_transfers (
    id integer NOT NULL,
    transfer_type character varying,
    min_transfer_time integer,
    tags public.hstore,
    stop_id integer,
    to_stop_id integer,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE public.current_stop_transfers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_stop_transfers_id_seq OWNED BY public.current_stop_transfers.id;
CREATE TABLE public.current_stops (
    id integer NOT NULL,
    onestop_id character varying,
    geometry public.geography(Geometry,4326),
    tags public.hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying,
    created_or_updated_in_changeset_id integer,
    version integer,
    timezone character varying,
    last_conflated_at timestamp without time zone,
    type character varying,
    parent_stop_id integer,
    osm_way_id integer,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    wheelchair_boarding boolean,
    directionality integer,
    geometry_reversegeo public.geography(Point,4326)
);
CREATE SEQUENCE public.current_stops_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.current_stops_id_seq OWNED BY public.current_stops.id;
CREATE TABLE public.entities_imported_from_feed (
    id integer NOT NULL,
    entity_id integer,
    entity_type character varying,
    feed_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    feed_version_id integer,
    gtfs_id character varying
);
CREATE SEQUENCE public.entities_imported_from_feed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.entities_imported_from_feed_id_seq OWNED BY public.entities_imported_from_feed.id;
CREATE TABLE public.entities_with_issues (
    id integer NOT NULL,
    entity_id integer,
    entity_type character varying,
    entity_attribute character varying,
    issue_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE public.entities_with_issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.entities_with_issues_id_seq OWNED BY public.entities_with_issues.id;
CREATE TABLE public.feed_schedule_imports (
    id integer NOT NULL,
    success boolean,
    import_log text,
    exception_log text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_import_id integer
);
CREATE SEQUENCE public.feed_schedule_imports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_schedule_imports_id_seq OWNED BY public.feed_schedule_imports.id;
CREATE TABLE public.feed_states (
    id bigint NOT NULL,
    feed_id bigint NOT NULL,
    feed_version_id bigint,
    last_fetched_at timestamp without time zone,
    last_successful_fetch_at timestamp without time zone,
    last_fetch_error character varying DEFAULT ''::character varying NOT NULL,
    feed_realtime_enabled boolean DEFAULT false NOT NULL,
    feed_priority integer,
    tags json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_import_retention_period integer DEFAULT 90 NOT NULL
);
CREATE SEQUENCE public.feed_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_states_id_seq OWNED BY public.feed_states.id;
CREATE TABLE public.feed_version_file_infos (
    id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    name text NOT NULL,
    size bigint NOT NULL,
    rows bigint NOT NULL,
    columns integer NOT NULL,
    sha1 text NOT NULL,
    header text NOT NULL,
    csv_like boolean NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE public.feed_version_file_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_version_file_infos_id_seq OWNED BY public.feed_version_file_infos.id;
CREATE TABLE public.feed_version_gtfs_imports (
    id bigint NOT NULL,
    success boolean NOT NULL,
    import_log text NOT NULL,
    exception_log text NOT NULL,
    import_level integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    in_progress boolean DEFAULT false NOT NULL,
    skip_entity_error_count jsonb,
    warning_count jsonb,
    entity_count jsonb,
    generated_count jsonb,
    skip_entity_reference_count jsonb,
    skip_entity_filter_count jsonb,
    skip_entity_marked_count jsonb,
    interpolated_stop_time_count integer
);
CREATE SEQUENCE public.feed_version_gtfs_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_version_gtfs_imports_id_seq OWNED BY public.feed_version_gtfs_imports.id;
CREATE TABLE public.feed_version_imports (
    id integer NOT NULL,
    feed_version_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    success boolean,
    import_log text,
    exception_log text,
    validation_report text,
    import_level integer,
    operators_in_feed json
);
CREATE SEQUENCE public.feed_version_imports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_version_imports_id_seq OWNED BY public.feed_version_imports.id;
CREATE TABLE public.feed_version_infos (
    id integer NOT NULL,
    type character varying,
    data json,
    feed_version_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE public.feed_version_infos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_version_infos_id_seq OWNED BY public.feed_version_infos.id;
CREATE TABLE public.feed_version_service_levels (
    id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    route_id text,
    start_date date NOT NULL,
    end_date date NOT NULL,
    agency_name text NOT NULL,
    route_short_name text NOT NULL,
    route_long_name text NOT NULL,
    route_type integer NOT NULL,
    monday bigint NOT NULL,
    tuesday bigint NOT NULL,
    wednesday bigint NOT NULL,
    thursday bigint NOT NULL,
    friday bigint NOT NULL,
    saturday bigint NOT NULL,
    sunday bigint NOT NULL
);
CREATE SEQUENCE public.feed_version_service_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_version_service_levels_id_seq OWNED BY public.feed_version_service_levels.id;
CREATE SEQUENCE public.feed_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.feed_versions_id_seq OWNED BY public.feed_versions.id;
CREATE TABLE public.gtfs_agencies (
    id bigint NOT NULL,
    agency_id character varying NOT NULL,
    agency_name character varying NOT NULL,
    agency_url character varying NOT NULL,
    agency_timezone character varying NOT NULL,
    agency_lang character varying NOT NULL,
    agency_phone character varying NOT NULL,
    agency_fare_url character varying NOT NULL,
    agency_email character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_agencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_agencies_id_seq OWNED BY public.gtfs_agencies.id;
CREATE TABLE public.gtfs_calendar_dates (
    id bigint NOT NULL,
    date date NOT NULL,
    exception_type integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    service_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_calendar_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_calendar_dates_id_seq OWNED BY public.gtfs_calendar_dates.id;
CREATE SEQUENCE public.gtfs_calendars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_calendars_id_seq OWNED BY public.gtfs_calendars.id;
CREATE TABLE public.gtfs_fare_attributes (
    id bigint NOT NULL,
    fare_id character varying NOT NULL,
    price double precision NOT NULL,
    currency_type character varying NOT NULL,
    payment_method integer NOT NULL,
    transfer_duration integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    agency_id bigint,
    transfers integer
);
CREATE SEQUENCE public.gtfs_fare_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_fare_attributes_id_seq OWNED BY public.gtfs_fare_attributes.id;
CREATE TABLE public.gtfs_fare_rules (
    id bigint NOT NULL,
    origin_id character varying NOT NULL,
    destination_id character varying NOT NULL,
    contains_id character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    route_id bigint,
    fare_id bigint
);
CREATE SEQUENCE public.gtfs_fare_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_fare_rules_id_seq OWNED BY public.gtfs_fare_rules.id;
CREATE TABLE public.gtfs_feed_infos (
    id bigint NOT NULL,
    feed_publisher_name character varying NOT NULL,
    feed_publisher_url character varying NOT NULL,
    feed_lang character varying NOT NULL,
    feed_start_date date,
    feed_end_date date,
    feed_version_name character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_feed_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_feed_infos_id_seq OWNED BY public.gtfs_feed_infos.id;
CREATE TABLE public.gtfs_frequencies (
    id bigint NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    headway_secs integer NOT NULL,
    exact_times integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_frequencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_frequencies_id_seq OWNED BY public.gtfs_frequencies.id;
CREATE TABLE public.gtfs_levels (
    id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    level_id character varying NOT NULL,
    level_index double precision NOT NULL,
    level_name character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE public.gtfs_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_levels_id_seq OWNED BY public.gtfs_levels.id;
CREATE TABLE public.gtfs_pathways (
    id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    pathway_id character varying NOT NULL,
    from_stop_id bigint NOT NULL,
    to_stop_id bigint NOT NULL,
    pathway_mode integer NOT NULL,
    is_bidirectional integer NOT NULL,
    length double precision NOT NULL,
    traversal_time integer NOT NULL,
    stair_count integer NOT NULL,
    max_slope double precision NOT NULL,
    min_width double precision NOT NULL,
    signposted_as character varying NOT NULL,
    reverse_signposted_as character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);
CREATE SEQUENCE public.gtfs_pathways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_pathways_id_seq OWNED BY public.gtfs_pathways.id;
CREATE TABLE public.gtfs_routes (
    id bigint NOT NULL,
    route_id character varying NOT NULL,
    route_short_name character varying NOT NULL,
    route_long_name character varying NOT NULL,
    route_desc character varying NOT NULL,
    route_type integer NOT NULL,
    route_url character varying NOT NULL,
    route_color character varying NOT NULL,
    route_text_color character varying NOT NULL,
    route_sort_order integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    agency_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_routes_id_seq OWNED BY public.gtfs_routes.id;
CREATE TABLE public.gtfs_shapes (
    id bigint NOT NULL,
    shape_id character varying NOT NULL,
    generated boolean DEFAULT false NOT NULL,
    geometry public.geography(LineStringM,4326) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_shapes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_shapes_id_seq OWNED BY public.gtfs_shapes.id;
CREATE TABLE public.gtfs_stop_times (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
)
PARTITION BY HASH (feed_version_id);
CREATE TABLE public.gtfs_stop_times_0 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_0 FOR VALUES WITH (modulus 10, remainder 0);
CREATE TABLE public.gtfs_stop_times_1 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_1 FOR VALUES WITH (modulus 10, remainder 1);
CREATE TABLE public.gtfs_stop_times_2 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_2 FOR VALUES WITH (modulus 10, remainder 2);
CREATE TABLE public.gtfs_stop_times_3 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_3 FOR VALUES WITH (modulus 10, remainder 3);
CREATE TABLE public.gtfs_stop_times_4 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_4 FOR VALUES WITH (modulus 10, remainder 4);
CREATE TABLE public.gtfs_stop_times_5 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_5 FOR VALUES WITH (modulus 10, remainder 5);
CREATE TABLE public.gtfs_stop_times_6 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_6 FOR VALUES WITH (modulus 10, remainder 6);
CREATE TABLE public.gtfs_stop_times_7 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_7 FOR VALUES WITH (modulus 10, remainder 7);
CREATE TABLE public.gtfs_stop_times_8 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_8 FOR VALUES WITH (modulus 10, remainder 8);
CREATE TABLE public.gtfs_stop_times_9 (
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    shape_dist_traveled real,
    pickup_type smallint,
    drop_off_type smallint,
    timepoint smallint,
    interpolated smallint,
    stop_headsign text
);
ALTER TABLE ONLY public.gtfs_stop_times ATTACH PARTITION public.gtfs_stop_times_9 FOR VALUES WITH (modulus 10, remainder 9);
CREATE TABLE public.gtfs_stop_times_unpartitioned (
    id bigint NOT NULL,
    arrival_time integer NOT NULL,
    departure_time integer NOT NULL,
    stop_sequence integer NOT NULL,
    stop_headsign character varying NOT NULL,
    pickup_type integer NOT NULL,
    drop_off_type integer NOT NULL,
    shape_dist_traveled double precision NOT NULL,
    timepoint integer NOT NULL,
    interpolated integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_stop_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_stop_times_id_seq OWNED BY public.gtfs_stop_times_unpartitioned.id;
CREATE TABLE public.gtfs_stops (
    id bigint NOT NULL,
    stop_id character varying NOT NULL,
    stop_code character varying NOT NULL,
    stop_name character varying NOT NULL,
    stop_desc character varying NOT NULL,
    zone_id character varying NOT NULL,
    stop_url character varying NOT NULL,
    location_type integer NOT NULL,
    stop_timezone character varying NOT NULL,
    wheelchair_boarding integer NOT NULL,
    geometry public.geography(Point,4326) NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    parent_station bigint,
    level_id bigint
);
CREATE SEQUENCE public.gtfs_stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_stops_id_seq OWNED BY public.gtfs_stops.id;
CREATE TABLE public.gtfs_transfers (
    id bigint NOT NULL,
    transfer_type integer NOT NULL,
    min_transfer_time integer,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    from_stop_id bigint NOT NULL,
    to_stop_id bigint NOT NULL
);
CREATE SEQUENCE public.gtfs_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_transfers_id_seq OWNED BY public.gtfs_transfers.id;
CREATE TABLE public.gtfs_trips (
    id bigint NOT NULL,
    trip_id character varying NOT NULL,
    trip_headsign character varying NOT NULL,
    trip_short_name character varying NOT NULL,
    direction_id integer NOT NULL,
    block_id character varying NOT NULL,
    wheelchair_accessible integer NOT NULL,
    bikes_allowed integer NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    feed_version_id bigint NOT NULL,
    route_id bigint NOT NULL,
    shape_id bigint,
    stop_pattern_id integer NOT NULL,
    service_id bigint NOT NULL,
    journey_pattern_id text NOT NULL,
    journey_pattern_offset integer NOT NULL
);
CREATE SEQUENCE public.gtfs_trips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.gtfs_trips_id_seq OWNED BY public.gtfs_trips.id;
CREATE TABLE public.issues (
    id integer NOT NULL,
    created_by_changeset_id integer,
    resolved_by_changeset_id integer,
    details character varying,
    issue_type character varying,
    open boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE public.issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.issues_id_seq OWNED BY public.issues.id;
CREATE TABLE public.old_feeds (
    id integer NOT NULL,
    onestop_id character varying NOT NULL,
    url character varying,
    spec character varying DEFAULT 'gtfs'::character varying NOT NULL,
    tags public.hstore,
    last_fetched_at timestamp without time zone,
    last_imported_at timestamp without time zone,
    version integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    current_id integer,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    geometry public.geography(Geometry,4326),
    active_feed_version_id integer,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    action character varying,
    name character varying,
    type character varying,
    auth jsonb DEFAULT '{}'::jsonb NOT NULL,
    urls jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at timestamp without time zone,
    last_successful_fetch_at timestamp without time zone,
    last_fetch_error character varying DEFAULT ''::character varying NOT NULL,
    license jsonb DEFAULT '{}'::jsonb NOT NULL,
    other_ids jsonb DEFAULT '{}'::jsonb NOT NULL,
    associated_feeds jsonb DEFAULT '{}'::jsonb NOT NULL,
    languages jsonb DEFAULT '{}'::jsonb NOT NULL,
    feed_namespace_id character varying DEFAULT ''::character varying NOT NULL,
    file character varying
);
CREATE SEQUENCE public.old_feeds_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_feeds_id_seq OWNED BY public.old_feeds.id;
CREATE TABLE public.old_operators (
    name character varying,
    tags public.hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    onestop_id character varying,
    geometry public.geography(Geometry,4326),
    id integer NOT NULL,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    current_id integer,
    version integer,
    timezone character varying,
    short_name character varying,
    website character varying,
    country character varying,
    state character varying,
    metro character varying,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    action character varying
);
CREATE SEQUENCE public.old_operators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_operators_id_seq OWNED BY public.old_operators.id;
CREATE TABLE public.old_operators_in_feed (
    id integer NOT NULL,
    gtfs_agency_id character varying,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    operator_id integer,
    operator_type character varying,
    feed_id integer,
    feed_type character varying,
    current_id integer,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer
);
CREATE SEQUENCE public.old_operators_in_feed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_operators_in_feed_id_seq OWNED BY public.old_operators_in_feed.id;
CREATE TABLE public.old_operators_serving_stop (
    stop_id integer,
    operator_id integer,
    tags public.hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id integer NOT NULL,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    current_id integer,
    version integer,
    stop_type character varying,
    operator_type character varying
);
CREATE SEQUENCE public.old_operators_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_operators_serving_stop_id_seq OWNED BY public.old_operators_serving_stop.id;
CREATE TABLE public.old_route_stop_patterns (
    id integer NOT NULL,
    onestop_id character varying,
    geometry public.geography(Geometry,4326),
    tags public.hstore,
    stop_pattern character varying[] DEFAULT '{}'::character varying[],
    version integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    route_id integer,
    route_type character varying,
    current_id integer,
    stop_distances double precision[] DEFAULT '{}'::double precision[],
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    action character varying,
    geometry_source character varying
);
CREATE SEQUENCE public.old_route_stop_patterns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_route_stop_patterns_id_seq OWNED BY public.old_route_stop_patterns.id;
CREATE TABLE public.old_routes (
    id integer NOT NULL,
    onestop_id character varying,
    name character varying,
    tags public.hstore,
    operator_id integer,
    operator_type character varying,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    current_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    geometry public.geography(Geometry,4326),
    vehicle_type integer,
    color character varying,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    wheelchair_accessible character varying DEFAULT 'unknown'::character varying,
    bikes_allowed character varying DEFAULT 'unknown'::character varying,
    action character varying
);
CREATE SEQUENCE public.old_routes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_routes_id_seq OWNED BY public.old_routes.id;
CREATE TABLE public.old_routes_serving_stop (
    id integer NOT NULL,
    route_id integer,
    route_type character varying,
    stop_id integer,
    stop_type character varying,
    tags public.hstore,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    current_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE public.old_routes_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_routes_serving_stop_id_seq OWNED BY public.old_routes_serving_stop.id;
CREATE TABLE public.old_schedule_stop_pairs (
    id bigint NOT NULL,
    origin_id integer,
    origin_type character varying,
    destination_id integer,
    destination_type character varying,
    route_id integer,
    route_type character varying,
    trip character varying,
    current_id integer,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    version integer,
    trip_headsign character varying,
    origin_arrival_time character varying,
    origin_departure_time character varying,
    destination_arrival_time character varying,
    destination_departure_time character varying,
    frequency_start_time character varying,
    frequency_end_time character varying,
    tags public.hstore,
    service_start_date date,
    service_end_date date,
    service_added_dates date[] DEFAULT '{}'::date[],
    service_except_dates date[] DEFAULT '{}'::date[],
    service_days_of_week boolean[] DEFAULT '{}'::boolean[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    block_id character varying,
    trip_short_name character varying,
    shape_dist_traveled double precision,
    origin_timezone character varying,
    destination_timezone character varying,
    window_start character varying,
    window_end character varying,
    origin_timepoint_source character varying,
    destination_timepoint_source character varying,
    operator_id integer,
    wheelchair_accessible boolean,
    bikes_allowed boolean,
    pickup_type character varying,
    drop_off_type character varying,
    route_stop_pattern_id integer,
    origin_dist_traveled double precision,
    destination_dist_traveled double precision,
    feed_id integer,
    feed_version_id integer,
    frequency_type character varying,
    frequency_headway_seconds integer
);
CREATE SEQUENCE public.old_schedule_stop_pairs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_schedule_stop_pairs_id_seq OWNED BY public.old_schedule_stop_pairs.id;
CREATE TABLE public.old_stop_transfers (
    id integer NOT NULL,
    transfer_type character varying,
    min_transfer_time integer,
    tags public.hstore,
    stop_id integer,
    to_stop_id integer,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    destroyed_in_changeset_id integer,
    current_id integer
);
CREATE SEQUENCE public.old_stop_transfers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_stop_transfers_id_seq OWNED BY public.old_stop_transfers.id;
CREATE TABLE public.old_stops (
    onestop_id character varying,
    geometry public.geography(Geometry,4326),
    tags public.hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying,
    id integer NOT NULL,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    current_id integer,
    version integer,
    timezone character varying,
    last_conflated_at timestamp without time zone,
    type character varying,
    parent_stop_id integer,
    osm_way_id integer,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    wheelchair_boarding boolean,
    action character varying,
    directionality integer,
    geometry_reversegeo public.geography(Point,4326)
);
CREATE SEQUENCE public.old_stops_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.old_stops_id_seq OWNED BY public.old_stops.id;
CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying NOT NULL,
    name character varying,
    affiliation character varying,
    user_type character varying,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    admin boolean DEFAULT false
);
CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;
ALTER TABLE ONLY public.change_payloads ALTER COLUMN id SET DEFAULT nextval('public.change_payloads_id_seq'::regclass);
ALTER TABLE ONLY public.changesets ALTER COLUMN id SET DEFAULT nextval('public.changesets_id_seq'::regclass);
ALTER TABLE ONLY public.current_feeds ALTER COLUMN id SET DEFAULT nextval('public.current_feeds_id_seq'::regclass);
ALTER TABLE ONLY public.current_operators ALTER COLUMN id SET DEFAULT nextval('public.current_operators_id_seq'::regclass);
ALTER TABLE ONLY public.current_operators_in_feed ALTER COLUMN id SET DEFAULT nextval('public.current_operators_in_feed_id_seq'::regclass);
ALTER TABLE ONLY public.current_operators_serving_stop ALTER COLUMN id SET DEFAULT nextval('public.current_operators_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY public.current_route_stop_patterns ALTER COLUMN id SET DEFAULT nextval('public.current_route_stop_patterns_id_seq'::regclass);
ALTER TABLE ONLY public.current_routes ALTER COLUMN id SET DEFAULT nextval('public.current_routes_id_seq'::regclass);
ALTER TABLE ONLY public.current_routes_serving_stop ALTER COLUMN id SET DEFAULT nextval('public.current_routes_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY public.current_schedule_stop_pairs ALTER COLUMN id SET DEFAULT nextval('public.current_schedule_stop_pairs_id_seq'::regclass);
ALTER TABLE ONLY public.current_stop_transfers ALTER COLUMN id SET DEFAULT nextval('public.current_stop_transfers_id_seq'::regclass);
ALTER TABLE ONLY public.current_stops ALTER COLUMN id SET DEFAULT nextval('public.current_stops_id_seq'::regclass);
ALTER TABLE ONLY public.entities_imported_from_feed ALTER COLUMN id SET DEFAULT nextval('public.entities_imported_from_feed_id_seq'::regclass);
ALTER TABLE ONLY public.entities_with_issues ALTER COLUMN id SET DEFAULT nextval('public.entities_with_issues_id_seq'::regclass);
ALTER TABLE ONLY public.feed_schedule_imports ALTER COLUMN id SET DEFAULT nextval('public.feed_schedule_imports_id_seq'::regclass);
ALTER TABLE ONLY public.feed_states ALTER COLUMN id SET DEFAULT nextval('public.feed_states_id_seq'::regclass);
ALTER TABLE ONLY public.feed_version_file_infos ALTER COLUMN id SET DEFAULT nextval('public.feed_version_file_infos_id_seq'::regclass);
ALTER TABLE ONLY public.feed_version_gtfs_imports ALTER COLUMN id SET DEFAULT nextval('public.feed_version_gtfs_imports_id_seq'::regclass);
ALTER TABLE ONLY public.feed_version_imports ALTER COLUMN id SET DEFAULT nextval('public.feed_version_imports_id_seq'::regclass);
ALTER TABLE ONLY public.feed_version_infos ALTER COLUMN id SET DEFAULT nextval('public.feed_version_infos_id_seq'::regclass);
ALTER TABLE ONLY public.feed_version_service_levels ALTER COLUMN id SET DEFAULT nextval('public.feed_version_service_levels_id_seq'::regclass);
ALTER TABLE ONLY public.feed_versions ALTER COLUMN id SET DEFAULT nextval('public.feed_versions_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_agencies ALTER COLUMN id SET DEFAULT nextval('public.gtfs_agencies_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_calendar_dates ALTER COLUMN id SET DEFAULT nextval('public.gtfs_calendar_dates_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_calendars ALTER COLUMN id SET DEFAULT nextval('public.gtfs_calendars_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_fare_attributes ALTER COLUMN id SET DEFAULT nextval('public.gtfs_fare_attributes_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_fare_rules ALTER COLUMN id SET DEFAULT nextval('public.gtfs_fare_rules_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_feed_infos ALTER COLUMN id SET DEFAULT nextval('public.gtfs_feed_infos_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_frequencies ALTER COLUMN id SET DEFAULT nextval('public.gtfs_frequencies_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_levels ALTER COLUMN id SET DEFAULT nextval('public.gtfs_levels_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_pathways ALTER COLUMN id SET DEFAULT nextval('public.gtfs_pathways_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_routes ALTER COLUMN id SET DEFAULT nextval('public.gtfs_routes_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_shapes ALTER COLUMN id SET DEFAULT nextval('public.gtfs_shapes_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_stop_times_unpartitioned ALTER COLUMN id SET DEFAULT nextval('public.gtfs_stop_times_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_stops ALTER COLUMN id SET DEFAULT nextval('public.gtfs_stops_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_transfers ALTER COLUMN id SET DEFAULT nextval('public.gtfs_transfers_id_seq'::regclass);
ALTER TABLE ONLY public.gtfs_trips ALTER COLUMN id SET DEFAULT nextval('public.gtfs_trips_id_seq'::regclass);
ALTER TABLE ONLY public.issues ALTER COLUMN id SET DEFAULT nextval('public.issues_id_seq'::regclass);
ALTER TABLE ONLY public.old_feeds ALTER COLUMN id SET DEFAULT nextval('public.old_feeds_id_seq'::regclass);
ALTER TABLE ONLY public.old_operators ALTER COLUMN id SET DEFAULT nextval('public.old_operators_id_seq'::regclass);
ALTER TABLE ONLY public.old_operators_in_feed ALTER COLUMN id SET DEFAULT nextval('public.old_operators_in_feed_id_seq'::regclass);
ALTER TABLE ONLY public.old_operators_serving_stop ALTER COLUMN id SET DEFAULT nextval('public.old_operators_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY public.old_route_stop_patterns ALTER COLUMN id SET DEFAULT nextval('public.old_route_stop_patterns_id_seq'::regclass);
ALTER TABLE ONLY public.old_routes ALTER COLUMN id SET DEFAULT nextval('public.old_routes_id_seq'::regclass);
ALTER TABLE ONLY public.old_routes_serving_stop ALTER COLUMN id SET DEFAULT nextval('public.old_routes_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY public.old_schedule_stop_pairs ALTER COLUMN id SET DEFAULT nextval('public.old_schedule_stop_pairs_id_seq'::regclass);
ALTER TABLE ONLY public.old_stop_transfers ALTER COLUMN id SET DEFAULT nextval('public.old_stop_transfers_id_seq'::regclass);
ALTER TABLE ONLY public.old_stops ALTER COLUMN id SET DEFAULT nextval('public.old_stops_id_seq'::regclass);
ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);
ALTER TABLE ONLY public.change_payloads
    ADD CONSTRAINT change_payloads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_feeds
    ADD CONSTRAINT current_feeds_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_operators_in_feed
    ADD CONSTRAINT current_operators_in_feed_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_operators
    ADD CONSTRAINT current_operators_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_operators_serving_stop
    ADD CONSTRAINT current_operators_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_route_stop_patterns
    ADD CONSTRAINT current_route_stop_patterns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_routes
    ADD CONSTRAINT current_routes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_routes_serving_stop
    ADD CONSTRAINT current_routes_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_schedule_stop_pairs
    ADD CONSTRAINT current_schedule_stop_pairs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_stop_transfers
    ADD CONSTRAINT current_stop_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.current_stops
    ADD CONSTRAINT current_stops_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.entities_imported_from_feed
    ADD CONSTRAINT entities_imported_from_feed_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.entities_with_issues
    ADD CONSTRAINT entities_with_issues_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_schedule_imports
    ADD CONSTRAINT feed_schedule_imports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_states
    ADD CONSTRAINT feed_states_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_version_file_infos
    ADD CONSTRAINT feed_version_file_infos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_version_gtfs_imports
    ADD CONSTRAINT feed_version_gtfs_imports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_version_imports
    ADD CONSTRAINT feed_version_imports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_version_infos
    ADD CONSTRAINT feed_version_infos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_version_service_levels
    ADD CONSTRAINT feed_version_service_levels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.feed_versions
    ADD CONSTRAINT feed_versions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_agencies
    ADD CONSTRAINT gtfs_agencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_calendar_dates
    ADD CONSTRAINT gtfs_calendar_dates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_calendars
    ADD CONSTRAINT gtfs_calendars_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_fare_attributes
    ADD CONSTRAINT gtfs_fare_attributes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_fare_rules
    ADD CONSTRAINT gtfs_fare_rules_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_feed_infos
    ADD CONSTRAINT gtfs_feed_infos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_frequencies
    ADD CONSTRAINT gtfs_frequencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_levels
    ADD CONSTRAINT gtfs_levels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_pathways
    ADD CONSTRAINT gtfs_pathways_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_routes
    ADD CONSTRAINT gtfs_routes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_shapes
    ADD CONSTRAINT gtfs_shapes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_stop_times
    ADD CONSTRAINT gtfs_stop_times_pkey1 PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_0
    ADD CONSTRAINT gtfs_stop_times_0_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_1
    ADD CONSTRAINT gtfs_stop_times_1_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_2
    ADD CONSTRAINT gtfs_stop_times_2_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_3
    ADD CONSTRAINT gtfs_stop_times_3_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_4
    ADD CONSTRAINT gtfs_stop_times_4_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_5
    ADD CONSTRAINT gtfs_stop_times_5_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_6
    ADD CONSTRAINT gtfs_stop_times_6_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_7
    ADD CONSTRAINT gtfs_stop_times_7_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_8
    ADD CONSTRAINT gtfs_stop_times_8_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_9
    ADD CONSTRAINT gtfs_stop_times_9_pkey PRIMARY KEY (feed_version_id, trip_id, stop_sequence);
ALTER TABLE ONLY public.gtfs_stop_times_unpartitioned
    ADD CONSTRAINT gtfs_stop_times_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_stops
    ADD CONSTRAINT gtfs_stops_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_transfers
    ADD CONSTRAINT gtfs_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.gtfs_trips
    ADD CONSTRAINT gtfs_trips_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_feeds
    ADD CONSTRAINT old_feeds_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_operators_in_feed
    ADD CONSTRAINT old_operators_in_feed_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_operators
    ADD CONSTRAINT old_operators_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_operators_serving_stop
    ADD CONSTRAINT old_operators_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_route_stop_patterns
    ADD CONSTRAINT old_route_stop_patterns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_routes
    ADD CONSTRAINT old_routes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_routes_serving_stop
    ADD CONSTRAINT old_routes_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_schedule_stop_pairs
    ADD CONSTRAINT old_schedule_stop_pairs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_stop_transfers
    ADD CONSTRAINT old_stop_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.old_stops
    ADD CONSTRAINT old_stops_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
CREATE INDEX "#c_operators_cu_in_changeset_id_index" ON public.current_operators USING btree (created_or_updated_in_changeset_id);
CREATE INDEX "#c_operators_serving_stop_cu_in_changeset_id_index" ON public.current_operators_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX "#c_stops_cu_in_changeset_id_index" ON public.current_stops USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_route_cu_in_changeset ON public.current_routes USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_rsp_cu_in_changeset ON public.current_route_stop_patterns USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_rss_cu_in_changeset ON public.current_routes_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_ssp_cu_in_changeset ON public.current_schedule_stop_pairs USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_ssp_destination ON public.current_schedule_stop_pairs USING btree (destination_id);
CREATE INDEX c_ssp_origin ON public.current_schedule_stop_pairs USING btree (origin_id);
CREATE INDEX c_ssp_route ON public.current_schedule_stop_pairs USING btree (route_id);
CREATE INDEX c_ssp_service_end_date ON public.current_schedule_stop_pairs USING btree (service_end_date);
CREATE INDEX c_ssp_service_start_date ON public.current_schedule_stop_pairs USING btree (service_start_date);
CREATE INDEX c_ssp_trip ON public.current_schedule_stop_pairs USING btree (trip);
CREATE INDEX current_oif ON public.current_operators_in_feed USING btree (created_or_updated_in_changeset_id);
CREATE INDEX feed_version_file_infos_feed_version_id_idx ON public.feed_version_file_infos USING btree (feed_version_id);
CREATE INDEX feed_version_file_infos_name_idx ON public.feed_version_file_infos USING btree (name);
CREATE INDEX feed_version_file_infos_sha1_idx ON public.feed_version_file_infos USING btree (sha1);
CREATE INDEX feed_version_service_levels_end_date_idx ON public.feed_version_service_levels USING btree (end_date);
CREATE INDEX feed_version_service_levels_feed_version_id_idx ON public.feed_version_service_levels USING btree (feed_version_id);
CREATE UNIQUE INDEX feed_version_service_levels_feed_version_id_route_id_start__idx ON public.feed_version_service_levels USING btree (feed_version_id, route_id, start_date, end_date);
CREATE INDEX feed_version_service_levels_route_id_idx ON public.feed_version_service_levels USING btree (route_id);
CREATE INDEX feed_version_service_levels_start_date_idx ON public.feed_version_service_levels USING btree (start_date);
CREATE INDEX gtfs_calendar_dates_service_id_exception_type_date_idx ON public.gtfs_calendar_dates USING btree (service_id, exception_type, date);
CREATE INDEX gtfs_feed_infos_feed_version_id_idx ON public.gtfs_feed_infos USING btree (feed_version_id);
CREATE INDEX gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ON ONLY public.gtfs_stop_times USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_0_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_0 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_stop_id_idx ON ONLY public.gtfs_stop_times USING btree (stop_id);
CREATE INDEX gtfs_stop_times_0_stop_id_idx ON public.gtfs_stop_times_0 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_trip_id_idx ON ONLY public.gtfs_stop_times USING btree (trip_id);
CREATE INDEX gtfs_stop_times_0_trip_id_idx ON public.gtfs_stop_times_0 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_1_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_1 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_1_stop_id_idx ON public.gtfs_stop_times_1 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_1_trip_id_idx ON public.gtfs_stop_times_1 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_2_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_2 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_2_stop_id_idx ON public.gtfs_stop_times_2 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_2_trip_id_idx ON public.gtfs_stop_times_2 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_3_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_3 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_3_stop_id_idx ON public.gtfs_stop_times_3 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_3_trip_id_idx ON public.gtfs_stop_times_3 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_4_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_4 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_4_stop_id_idx ON public.gtfs_stop_times_4 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_4_trip_id_idx ON public.gtfs_stop_times_4 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_5_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_5 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_5_stop_id_idx ON public.gtfs_stop_times_5 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_5_trip_id_idx ON public.gtfs_stop_times_5 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_6_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_6 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_6_stop_id_idx ON public.gtfs_stop_times_6 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_6_trip_id_idx ON public.gtfs_stop_times_6 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_7_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_7 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_7_stop_id_idx ON public.gtfs_stop_times_7 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_7_trip_id_idx ON public.gtfs_stop_times_7 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_8_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_8 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_8_stop_id_idx ON public.gtfs_stop_times_8 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_8_trip_id_idx ON public.gtfs_stop_times_8 USING btree (trip_id);
CREATE INDEX gtfs_stop_times_9_feed_version_id_trip_id_stop_id_idx ON public.gtfs_stop_times_9 USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX gtfs_stop_times_9_stop_id_idx ON public.gtfs_stop_times_9 USING btree (stop_id);
CREATE INDEX gtfs_stop_times_9_trip_id_idx ON public.gtfs_stop_times_9 USING btree (trip_id);
CREATE INDEX gtfs_trips_journey_pattern_id_idx ON public.gtfs_trips USING btree (journey_pattern_id);
CREATE INDEX index_change_payloads_on_changeset_id ON public.change_payloads USING btree (changeset_id);
CREATE INDEX index_changesets_on_feed_id ON public.changesets USING btree (feed_id);
CREATE INDEX index_changesets_on_feed_version_id ON public.changesets USING btree (feed_version_id);
CREATE INDEX index_changesets_on_user_id ON public.changesets USING btree (user_id);
CREATE INDEX index_current_feeds_on_active_feed_version_id ON public.current_feeds USING btree (active_feed_version_id);
CREATE INDEX index_current_feeds_on_auth ON public.current_feeds USING btree (auth);
CREATE INDEX index_current_feeds_on_created_or_updated_in_changeset_id ON public.current_feeds USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_current_feeds_on_geometry ON public.current_feeds USING gist (geometry);
CREATE UNIQUE INDEX index_current_feeds_on_onestop_id ON public.current_feeds USING btree (onestop_id);
CREATE INDEX index_current_feeds_on_urls ON public.current_feeds USING btree (urls);
CREATE INDEX index_current_operators_in_feed_on_feed_id ON public.current_operators_in_feed USING btree (feed_id);
CREATE INDEX index_current_operators_in_feed_on_operator_id ON public.current_operators_in_feed USING btree (operator_id);
CREATE INDEX index_current_operators_on_geometry ON public.current_operators USING gist (geometry);
CREATE UNIQUE INDEX index_current_operators_on_onestop_id ON public.current_operators USING btree (onestop_id);
CREATE INDEX index_current_operators_on_tags ON public.current_operators USING btree (tags);
CREATE INDEX index_current_operators_on_updated_at ON public.current_operators USING btree (updated_at);
CREATE INDEX index_current_operators_serving_stop_on_operator_id ON public.current_operators_serving_stop USING btree (operator_id);
CREATE UNIQUE INDEX index_current_operators_serving_stop_on_stop_id_and_operator_id ON public.current_operators_serving_stop USING btree (stop_id, operator_id);
CREATE UNIQUE INDEX index_current_route_stop_patterns_on_onestop_id ON public.current_route_stop_patterns USING btree (onestop_id);
CREATE INDEX index_current_route_stop_patterns_on_route_id ON public.current_route_stop_patterns USING btree (route_id);
CREATE INDEX index_current_route_stop_patterns_on_stop_pattern ON public.current_route_stop_patterns USING gin (stop_pattern);
CREATE INDEX index_current_routes_on_bikes_allowed ON public.current_routes USING btree (bikes_allowed);
CREATE INDEX index_current_routes_on_geometry ON public.current_routes USING gist (geometry);
CREATE UNIQUE INDEX index_current_routes_on_onestop_id ON public.current_routes USING btree (onestop_id);
CREATE INDEX index_current_routes_on_operator_id ON public.current_routes USING btree (operator_id);
CREATE INDEX index_current_routes_on_tags ON public.current_routes USING btree (tags);
CREATE INDEX index_current_routes_on_updated_at ON public.current_routes USING btree (updated_at);
CREATE INDEX index_current_routes_on_vehicle_type ON public.current_routes USING btree (vehicle_type);
CREATE INDEX index_current_routes_on_wheelchair_accessible ON public.current_routes USING btree (wheelchair_accessible);
CREATE INDEX index_current_routes_serving_stop_on_route_id ON public.current_routes_serving_stop USING btree (route_id);
CREATE INDEX index_current_routes_serving_stop_on_stop_id ON public.current_routes_serving_stop USING btree (stop_id);
CREATE INDEX index_current_schedule_stop_pairs_on_feed_id_and_id ON public.current_schedule_stop_pairs USING btree (feed_id, id);
CREATE INDEX index_current_schedule_stop_pairs_on_feed_version_id_and_id ON public.current_schedule_stop_pairs USING btree (feed_version_id, id);
CREATE INDEX index_current_schedule_stop_pairs_on_frequency_type ON public.current_schedule_stop_pairs USING btree (frequency_type);
CREATE INDEX index_current_schedule_stop_pairs_on_operator_id_and_id ON public.current_schedule_stop_pairs USING btree (operator_id, id);
CREATE INDEX index_current_schedule_stop_pairs_on_origin_departure_time ON public.current_schedule_stop_pairs USING btree (origin_departure_time);
CREATE INDEX index_current_schedule_stop_pairs_on_route_stop_pattern_id ON public.current_schedule_stop_pairs USING btree (route_stop_pattern_id);
CREATE INDEX index_current_schedule_stop_pairs_on_updated_at ON public.current_schedule_stop_pairs USING btree (updated_at);
CREATE INDEX index_current_stop_transfers_changeset_id ON public.current_stop_transfers USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_current_stop_transfers_on_min_transfer_time ON public.current_stop_transfers USING btree (min_transfer_time);
CREATE INDEX index_current_stop_transfers_on_stop_id ON public.current_stop_transfers USING btree (stop_id);
CREATE INDEX index_current_stop_transfers_on_to_stop_id ON public.current_stop_transfers USING btree (to_stop_id);
CREATE INDEX index_current_stop_transfers_on_transfer_type ON public.current_stop_transfers USING btree (transfer_type);
CREATE INDEX index_current_stops_on_geometry ON public.current_stops USING gist (geometry);
CREATE INDEX index_current_stops_on_geometry_reversegeo ON public.current_stops USING gist (geometry_reversegeo);
CREATE UNIQUE INDEX index_current_stops_on_onestop_id ON public.current_stops USING btree (onestop_id);
CREATE INDEX index_current_stops_on_parent_stop_id ON public.current_stops USING btree (parent_stop_id);
CREATE INDEX index_current_stops_on_tags ON public.current_stops USING btree (tags);
CREATE INDEX index_current_stops_on_updated_at ON public.current_stops USING btree (updated_at);
CREATE INDEX index_current_stops_on_wheelchair_boarding ON public.current_stops USING btree (wheelchair_boarding);
CREATE INDEX index_entities_imported_from_feed_on_entity_type_and_entity_id ON public.entities_imported_from_feed USING btree (entity_type, entity_id);
CREATE INDEX index_entities_imported_from_feed_on_feed_id ON public.entities_imported_from_feed USING btree (feed_id);
CREATE INDEX index_entities_imported_from_feed_on_feed_version_id ON public.entities_imported_from_feed USING btree (feed_version_id);
CREATE INDEX index_entities_with_issues_on_entity_type_and_entity_id ON public.entities_with_issues USING btree (entity_type, entity_id);
CREATE INDEX index_feed_schedule_imports_on_feed_version_import_id ON public.feed_schedule_imports USING btree (feed_version_import_id);
CREATE UNIQUE INDEX index_feed_states_on_feed_id ON public.feed_states USING btree (feed_id);
CREATE UNIQUE INDEX index_feed_states_on_feed_priority ON public.feed_states USING btree (feed_priority);
CREATE UNIQUE INDEX index_feed_states_on_feed_version_id ON public.feed_states USING btree (feed_version_id);
CREATE UNIQUE INDEX index_feed_version_gtfs_imports_on_feed_version_id ON public.feed_version_gtfs_imports USING btree (feed_version_id);
CREATE INDEX index_feed_version_gtfs_imports_on_success ON public.feed_version_gtfs_imports USING btree (success);
CREATE INDEX index_feed_version_imports_on_feed_version_id ON public.feed_version_imports USING btree (feed_version_id);
CREATE INDEX index_feed_version_infos_on_feed_version_id ON public.feed_version_infos USING btree (feed_version_id);
CREATE UNIQUE INDEX index_feed_version_infos_on_feed_version_id_and_type ON public.feed_version_infos USING btree (feed_version_id, type);
CREATE INDEX index_feed_versions_on_earliest_calendar_date ON public.feed_versions USING btree (earliest_calendar_date);
CREATE INDEX index_feed_versions_on_feed_type_and_feed_id ON public.feed_versions USING btree (feed_type, feed_id);
CREATE INDEX index_feed_versions_on_latest_calendar_date ON public.feed_versions USING btree (latest_calendar_date);
CREATE INDEX index_gtfs_agencies_on_agency_id ON public.gtfs_agencies USING btree (agency_id);
CREATE INDEX index_gtfs_agencies_on_agency_name ON public.gtfs_agencies USING btree (agency_name);
CREATE UNIQUE INDEX index_gtfs_agencies_unique ON public.gtfs_agencies USING btree (feed_version_id, agency_id);
CREATE INDEX index_gtfs_calendar_dates_on_date ON public.gtfs_calendar_dates USING btree (date);
CREATE INDEX index_gtfs_calendar_dates_on_exception_type ON public.gtfs_calendar_dates USING btree (exception_type);
CREATE INDEX index_gtfs_calendar_dates_on_feed_version_id ON public.gtfs_calendar_dates USING btree (feed_version_id);
CREATE INDEX index_gtfs_calendar_dates_on_service_id ON public.gtfs_calendar_dates USING btree (service_id);
CREATE INDEX index_gtfs_calendars_on_end_date ON public.gtfs_calendars USING btree (end_date);
CREATE UNIQUE INDEX index_gtfs_calendars_on_feed_version_id_and_service_id ON public.gtfs_calendars USING btree (feed_version_id, service_id);
CREATE INDEX index_gtfs_calendars_on_friday ON public.gtfs_calendars USING btree (friday);
CREATE INDEX index_gtfs_calendars_on_monday ON public.gtfs_calendars USING btree (monday);
CREATE INDEX index_gtfs_calendars_on_saturday ON public.gtfs_calendars USING btree (saturday);
CREATE INDEX index_gtfs_calendars_on_service_id ON public.gtfs_calendars USING btree (service_id);
CREATE INDEX index_gtfs_calendars_on_start_date ON public.gtfs_calendars USING btree (start_date);
CREATE INDEX index_gtfs_calendars_on_sunday ON public.gtfs_calendars USING btree (sunday);
CREATE INDEX index_gtfs_calendars_on_thursday ON public.gtfs_calendars USING btree (thursday);
CREATE INDEX index_gtfs_calendars_on_tuesday ON public.gtfs_calendars USING btree (tuesday);
CREATE INDEX index_gtfs_calendars_on_wednesday ON public.gtfs_calendars USING btree (wednesday);
CREATE INDEX index_gtfs_fare_attributes_on_agency_id ON public.gtfs_fare_attributes USING btree (agency_id);
CREATE INDEX index_gtfs_fare_attributes_on_fare_id ON public.gtfs_fare_attributes USING btree (fare_id);
CREATE UNIQUE INDEX index_gtfs_fare_attributes_unique ON public.gtfs_fare_attributes USING btree (feed_version_id, fare_id);
CREATE INDEX index_gtfs_fare_rules_on_fare_id ON public.gtfs_fare_rules USING btree (fare_id);
CREATE INDEX index_gtfs_fare_rules_on_feed_version_id ON public.gtfs_fare_rules USING btree (feed_version_id);
CREATE INDEX index_gtfs_fare_rules_on_route_id ON public.gtfs_fare_rules USING btree (route_id);
CREATE INDEX index_gtfs_frequencies_on_feed_version_id ON public.gtfs_frequencies USING btree (feed_version_id);
CREATE INDEX index_gtfs_frequencies_on_trip_id ON public.gtfs_frequencies USING btree (trip_id);
CREATE UNIQUE INDEX index_gtfs_levels_unique ON public.gtfs_levels USING btree (feed_version_id, level_id);
CREATE INDEX index_gtfs_pathways_on_from_stop_id ON public.gtfs_pathways USING btree (from_stop_id);
CREATE INDEX index_gtfs_pathways_on_level_id ON public.gtfs_levels USING btree (level_id);
CREATE INDEX index_gtfs_pathways_on_pathway_id ON public.gtfs_pathways USING btree (pathway_id);
CREATE INDEX index_gtfs_pathways_on_to_stop_id ON public.gtfs_pathways USING btree (to_stop_id);
CREATE UNIQUE INDEX index_gtfs_pathways_unique ON public.gtfs_pathways USING btree (feed_version_id, pathway_id);
CREATE INDEX index_gtfs_routes_on_agency_id ON public.gtfs_routes USING btree (agency_id);
CREATE INDEX index_gtfs_routes_on_feed_version_id_agency_id ON public.gtfs_routes USING btree (feed_version_id, id, agency_id);
CREATE INDEX index_gtfs_routes_on_route_desc ON public.gtfs_routes USING btree (route_desc);
CREATE INDEX index_gtfs_routes_on_route_id ON public.gtfs_routes USING btree (route_id);
CREATE INDEX index_gtfs_routes_on_route_long_name ON public.gtfs_routes USING btree (route_long_name);
CREATE INDEX index_gtfs_routes_on_route_short_name ON public.gtfs_routes USING btree (route_short_name);
CREATE INDEX index_gtfs_routes_on_route_type ON public.gtfs_routes USING btree (route_type);
CREATE UNIQUE INDEX index_gtfs_routes_unique ON public.gtfs_routes USING btree (feed_version_id, route_id);
CREATE INDEX index_gtfs_shapes_on_generated ON public.gtfs_shapes USING btree (generated);
CREATE INDEX index_gtfs_shapes_on_geometry ON public.gtfs_shapes USING gist (geometry);
CREATE INDEX index_gtfs_shapes_on_shape_id ON public.gtfs_shapes USING btree (shape_id);
CREATE UNIQUE INDEX index_gtfs_shapes_unique ON public.gtfs_shapes USING btree (feed_version_id, shape_id);
CREATE INDEX index_gtfs_stop_times_on_feed_version_id_trip_id_stop_id ON public.gtfs_stop_times_unpartitioned USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX index_gtfs_stop_times_on_stop_id ON public.gtfs_stop_times_unpartitioned USING btree (stop_id);
CREATE INDEX index_gtfs_stop_times_on_trip_id ON public.gtfs_stop_times_unpartitioned USING btree (trip_id);
CREATE UNIQUE INDEX index_gtfs_stop_times_unique ON public.gtfs_stop_times_unpartitioned USING btree (feed_version_id, trip_id, stop_sequence);
CREATE INDEX index_gtfs_stops_on_geometry ON public.gtfs_stops USING gist (geometry);
CREATE INDEX index_gtfs_stops_on_location_type ON public.gtfs_stops USING btree (location_type);
CREATE INDEX index_gtfs_stops_on_parent_station ON public.gtfs_stops USING btree (parent_station);
CREATE INDEX index_gtfs_stops_on_stop_code ON public.gtfs_stops USING btree (stop_code);
CREATE INDEX index_gtfs_stops_on_stop_desc ON public.gtfs_stops USING btree (stop_desc);
CREATE INDEX index_gtfs_stops_on_stop_id ON public.gtfs_stops USING btree (stop_id);
CREATE INDEX index_gtfs_stops_on_stop_name ON public.gtfs_stops USING btree (stop_name);
CREATE UNIQUE INDEX index_gtfs_stops_unique ON public.gtfs_stops USING btree (feed_version_id, stop_id);
CREATE INDEX index_gtfs_transfers_on_feed_version_id ON public.gtfs_transfers USING btree (feed_version_id);
CREATE INDEX index_gtfs_transfers_on_from_stop_id ON public.gtfs_transfers USING btree (from_stop_id);
CREATE INDEX index_gtfs_transfers_on_to_stop_id ON public.gtfs_transfers USING btree (to_stop_id);
CREATE INDEX index_gtfs_trips_on_route_id ON public.gtfs_trips USING btree (route_id);
CREATE INDEX index_gtfs_trips_on_service_id ON public.gtfs_trips USING btree (service_id);
CREATE INDEX index_gtfs_trips_on_shape_id ON public.gtfs_trips USING btree (shape_id);
CREATE INDEX index_gtfs_trips_on_trip_headsign ON public.gtfs_trips USING btree (trip_headsign);
CREATE INDEX index_gtfs_trips_on_trip_id ON public.gtfs_trips USING btree (trip_id);
CREATE INDEX index_gtfs_trips_on_trip_short_name ON public.gtfs_trips USING btree (trip_short_name);
CREATE UNIQUE INDEX index_gtfs_trips_unique ON public.gtfs_trips USING btree (feed_version_id, trip_id);
CREATE INDEX index_old_feeds_on_active_feed_version_id ON public.old_feeds USING btree (active_feed_version_id);
CREATE INDEX index_old_feeds_on_created_or_updated_in_changeset_id ON public.old_feeds USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_old_feeds_on_current_id ON public.old_feeds USING btree (current_id);
CREATE INDEX index_old_feeds_on_destroyed_in_changeset_id ON public.old_feeds USING btree (destroyed_in_changeset_id);
CREATE INDEX index_old_feeds_on_geometry ON public.old_feeds USING gist (geometry);
CREATE INDEX index_old_operators_in_feed_on_current_id ON public.old_operators_in_feed USING btree (current_id);
CREATE INDEX index_old_operators_in_feed_on_destroyed_in_changeset_id ON public.old_operators_in_feed USING btree (destroyed_in_changeset_id);
CREATE INDEX index_old_operators_in_feed_on_feed_type_and_feed_id ON public.old_operators_in_feed USING btree (feed_type, feed_id);
CREATE INDEX index_old_operators_in_feed_on_operator_type_and_operator_id ON public.old_operators_in_feed USING btree (operator_type, operator_id);
CREATE INDEX index_old_operators_on_current_id ON public.old_operators USING btree (current_id);
CREATE INDEX index_old_operators_on_geometry ON public.old_operators USING gist (geometry);
CREATE INDEX index_old_operators_serving_stop_on_current_id ON public.old_operators_serving_stop USING btree (current_id);
CREATE INDEX index_old_route_stop_patterns_on_current_id ON public.old_route_stop_patterns USING btree (current_id);
CREATE INDEX index_old_route_stop_patterns_on_onestop_id ON public.old_route_stop_patterns USING btree (onestop_id);
CREATE INDEX index_old_route_stop_patterns_on_route_type_and_route_id ON public.old_route_stop_patterns USING btree (route_type, route_id);
CREATE INDEX index_old_route_stop_patterns_on_stop_pattern ON public.old_route_stop_patterns USING gin (stop_pattern);
CREATE INDEX index_old_routes_on_bikes_allowed ON public.old_routes USING btree (bikes_allowed);
CREATE INDEX index_old_routes_on_current_id ON public.old_routes USING btree (current_id);
CREATE INDEX index_old_routes_on_geometry ON public.old_routes USING gist (geometry);
CREATE INDEX index_old_routes_on_operator_type_and_operator_id ON public.old_routes USING btree (operator_type, operator_id);
CREATE INDEX index_old_routes_on_vehicle_type ON public.old_routes USING btree (vehicle_type);
CREATE INDEX index_old_routes_on_wheelchair_accessible ON public.old_routes USING btree (wheelchair_accessible);
CREATE INDEX index_old_routes_serving_stop_on_current_id ON public.old_routes_serving_stop USING btree (current_id);
CREATE INDEX index_old_routes_serving_stop_on_route_type_and_route_id ON public.old_routes_serving_stop USING btree (route_type, route_id);
CREATE INDEX index_old_routes_serving_stop_on_stop_type_and_stop_id ON public.old_routes_serving_stop USING btree (stop_type, stop_id);
CREATE INDEX index_old_schedule_stop_pairs_on_current_id ON public.old_schedule_stop_pairs USING btree (current_id);
CREATE INDEX index_old_schedule_stop_pairs_on_feed_id ON public.old_schedule_stop_pairs USING btree (feed_id);
CREATE INDEX index_old_schedule_stop_pairs_on_feed_version_id ON public.old_schedule_stop_pairs USING btree (feed_version_id);
CREATE INDEX index_old_schedule_stop_pairs_on_frequency_type ON public.old_schedule_stop_pairs USING btree (frequency_type);
CREATE INDEX index_old_schedule_stop_pairs_on_operator_id ON public.old_schedule_stop_pairs USING btree (operator_id);
CREATE INDEX index_old_schedule_stop_pairs_on_route_stop_pattern_id ON public.old_schedule_stop_pairs USING btree (route_stop_pattern_id);
CREATE INDEX index_old_stop_transfers_changeset_id ON public.old_stop_transfers USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_old_stop_transfers_on_current_id ON public.old_stop_transfers USING btree (current_id);
CREATE INDEX index_old_stop_transfers_on_destroyed_in_changeset_id ON public.old_stop_transfers USING btree (destroyed_in_changeset_id);
CREATE INDEX index_old_stop_transfers_on_min_transfer_time ON public.old_stop_transfers USING btree (min_transfer_time);
CREATE INDEX index_old_stop_transfers_on_stop_id ON public.old_stop_transfers USING btree (stop_id);
CREATE INDEX index_old_stop_transfers_on_to_stop_id ON public.old_stop_transfers USING btree (to_stop_id);
CREATE INDEX index_old_stop_transfers_on_transfer_type ON public.old_stop_transfers USING btree (transfer_type);
CREATE INDEX index_old_stops_on_current_id ON public.old_stops USING btree (current_id);
CREATE INDEX index_old_stops_on_geometry ON public.old_stops USING gist (geometry);
CREATE INDEX index_old_stops_on_geometry_reversegeo ON public.old_stops USING gist (geometry_reversegeo);
CREATE INDEX index_old_stops_on_parent_stop_id ON public.old_stops USING btree (parent_stop_id);
CREATE INDEX index_old_stops_on_wheelchair_boarding ON public.old_stops USING btree (wheelchair_boarding);
CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);
CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);
CREATE INDEX o_operators_cu_in_changeset_id_index ON public.old_operators USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_operators_serving_stop_cu_in_changeset_id_index ON public.old_operators_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_route_cu_in_changeset ON public.old_routes USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_route_d_in_changeset ON public.old_routes USING btree (destroyed_in_changeset_id);
CREATE INDEX o_rsp_cu_in_changeset ON public.old_route_stop_patterns USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_rss_cu_in_changeset ON public.old_routes_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_rss_d_in_changeset ON public.old_routes_serving_stop USING btree (destroyed_in_changeset_id);
CREATE INDEX o_ssp_cu_in_changeset ON public.old_schedule_stop_pairs USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_ssp_d_in_changeset ON public.old_schedule_stop_pairs USING btree (destroyed_in_changeset_id);
CREATE INDEX o_ssp_destination ON public.old_schedule_stop_pairs USING btree (destination_type, destination_id);
CREATE INDEX o_ssp_origin ON public.old_schedule_stop_pairs USING btree (origin_type, origin_id);
CREATE INDEX o_ssp_route ON public.old_schedule_stop_pairs USING btree (route_type, route_id);
CREATE INDEX o_ssp_service_end_date ON public.old_schedule_stop_pairs USING btree (service_end_date);
CREATE INDEX o_ssp_service_start_date ON public.old_schedule_stop_pairs USING btree (service_start_date);
CREATE INDEX o_ssp_trip ON public.old_schedule_stop_pairs USING btree (trip);
CREATE INDEX o_stops_cu_in_changeset_id_index ON public.old_stops USING btree (created_or_updated_in_changeset_id);
CREATE INDEX old_oif ON public.old_operators_in_feed USING btree (created_or_updated_in_changeset_id);
CREATE INDEX operators_d_in_changeset_id_index ON public.old_operators USING btree (destroyed_in_changeset_id);
CREATE INDEX operators_serving_stop_d_in_changeset_id_index ON public.old_operators_serving_stop USING btree (destroyed_in_changeset_id);
CREATE INDEX operators_serving_stop_operator ON public.old_operators_serving_stop USING btree (operator_type, operator_id);
CREATE INDEX operators_serving_stop_stop ON public.old_operators_serving_stop USING btree (stop_type, stop_id);
CREATE INDEX stops_d_in_changeset_id_index ON public.old_stops USING btree (destroyed_in_changeset_id);
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_0_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_0_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_0_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_0_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_1_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_1_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_1_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_1_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_2_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_2_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_2_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_2_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_3_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_3_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_3_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_3_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_4_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_4_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_4_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_4_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_5_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_5_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_5_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_5_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_6_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_6_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_6_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_6_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_7_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_7_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_7_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_7_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_8_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_8_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_8_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_8_trip_id_idx;
ALTER INDEX public.gtfs_stop_times_feed_version_id_trip_id_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_9_feed_version_id_trip_id_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_pkey1 ATTACH PARTITION public.gtfs_stop_times_9_pkey;
ALTER INDEX public.gtfs_stop_times_stop_id_idx ATTACH PARTITION public.gtfs_stop_times_9_stop_id_idx;
ALTER INDEX public.gtfs_stop_times_trip_id_idx ATTACH PARTITION public.gtfs_stop_times_9_trip_id_idx;
ALTER TABLE ONLY public.feed_version_file_infos
    ADD CONSTRAINT feed_version_file_infos_feed_version_id_fkey FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.feed_version_service_levels
    ADD CONSTRAINT feed_version_service_levels_feed_version_id_fkey FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_trips
    ADD CONSTRAINT fk_rails_05ead08753 FOREIGN KEY (shape_id) REFERENCES public.gtfs_shapes(id);
ALTER TABLE ONLY public.gtfs_transfers
    ADD CONSTRAINT fk_rails_0cc6ff288a FOREIGN KEY (from_stop_id) REFERENCES public.gtfs_stops(id);
ALTER TABLE ONLY public.gtfs_stop_times_unpartitioned
    ADD CONSTRAINT fk_rails_22a671077b FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.feed_version_gtfs_imports
    ADD CONSTRAINT fk_rails_2d141782c9 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_stop_times_unpartitioned
    ADD CONSTRAINT fk_rails_30ced0baa8 FOREIGN KEY (stop_id) REFERENCES public.gtfs_stops(id);
ALTER TABLE ONLY public.gtfs_fare_rules
    ADD CONSTRAINT fk_rails_33e9869c97 FOREIGN KEY (route_id) REFERENCES public.gtfs_routes(id);
ALTER TABLE ONLY public.gtfs_stops
    ADD CONSTRAINT fk_rails_3a83952954 FOREIGN KEY (parent_station) REFERENCES public.gtfs_stops(id);
ALTER TABLE ONLY public.change_payloads
    ADD CONSTRAINT fk_rails_3f6887766c FOREIGN KEY (changeset_id) REFERENCES public.changesets(id);
ALTER TABLE ONLY public.gtfs_calendars
    ADD CONSTRAINT fk_rails_42538db9b2 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.feed_states
    ADD CONSTRAINT fk_rails_5189447149 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_frequencies
    ADD CONSTRAINT fk_rails_6e6295037f FOREIGN KEY (trip_id) REFERENCES public.gtfs_trips(id);
ALTER TABLE ONLY public.gtfs_calendar_dates
    ADD CONSTRAINT fk_rails_7a365f570b FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_shapes
    ADD CONSTRAINT fk_rails_84a74e83d8 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_stops
    ADD CONSTRAINT fk_rails_860ffa5a40 FOREIGN KEY (level_id) REFERENCES public.gtfs_levels(id);
ALTER TABLE ONLY public.gtfs_fare_attributes
    ADD CONSTRAINT fk_rails_8a3ca847de FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_pathways
    ADD CONSTRAINT fk_rails_8d7bf46256 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.feed_states
    ADD CONSTRAINT fk_rails_99eaedcf98 FOREIGN KEY (feed_id) REFERENCES public.current_feeds(id);
ALTER TABLE ONLY public.gtfs_transfers
    ADD CONSTRAINT fk_rails_a030c4a2a9 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_routes
    ADD CONSTRAINT fk_rails_a5ff5a2ceb FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_pathways
    ADD CONSTRAINT fk_rails_a668e1e0ac FOREIGN KEY (to_stop_id) REFERENCES public.gtfs_stops(id);
ALTER TABLE ONLY public.gtfs_agencies
    ADD CONSTRAINT fk_rails_a7e0c4685b FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_trips
    ADD CONSTRAINT fk_rails_a839da033a FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_fare_attributes
    ADD CONSTRAINT fk_rails_b096f74e03 FOREIGN KEY (agency_id) REFERENCES public.gtfs_agencies(id);
ALTER TABLE ONLY public.feed_versions
    ADD CONSTRAINT fk_rails_b5365c3cf3 FOREIGN KEY (feed_id) REFERENCES public.current_feeds(id);
ALTER TABLE ONLY public.gtfs_stop_times_unpartitioned
    ADD CONSTRAINT fk_rails_b5a47190ac FOREIGN KEY (trip_id) REFERENCES public.gtfs_trips(id);
ALTER TABLE ONLY public.gtfs_fare_rules
    ADD CONSTRAINT fk_rails_bd7d178423 FOREIGN KEY (fare_id) REFERENCES public.gtfs_fare_attributes(id);
ALTER TABLE ONLY public.gtfs_fare_rules
    ADD CONSTRAINT fk_rails_c336ea9f1a FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_levels
    ADD CONSTRAINT fk_rails_c5fba46e47 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_calendar_dates
    ADD CONSTRAINT fk_rails_ca504bc01f FOREIGN KEY (service_id) REFERENCES public.gtfs_calendars(id);
ALTER TABLE ONLY public.gtfs_stops
    ADD CONSTRAINT fk_rails_cf4bc79180 FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_frequencies
    ADD CONSTRAINT fk_rails_d1b468024b FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_trips
    ADD CONSTRAINT fk_rails_d2c6f99d5e FOREIGN KEY (service_id) REFERENCES public.gtfs_calendars(id);
ALTER TABLE ONLY public.gtfs_pathways
    ADD CONSTRAINT fk_rails_df846a6b54 FOREIGN KEY (from_stop_id) REFERENCES public.gtfs_stops(id);
ALTER TABLE ONLY public.gtfs_transfers
    ADD CONSTRAINT fk_rails_e1c56f7da4 FOREIGN KEY (to_stop_id) REFERENCES public.gtfs_stops(id);
ALTER TABLE ONLY public.gtfs_routes
    ADD CONSTRAINT fk_rails_e5eb0f1573 FOREIGN KEY (agency_id) REFERENCES public.gtfs_agencies(id);
ALTER TABLE ONLY public.gtfs_feed_infos
    ADD CONSTRAINT fk_rails_eb863abbac FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE ONLY public.gtfs_trips
    ADD CONSTRAINT fk_rails_mid93550f50 FOREIGN KEY (route_id) REFERENCES public.gtfs_routes(id);
ALTER TABLE public.gtfs_stop_times
    ADD CONSTRAINT gtfs_stop_times_feed_version_id_fkey FOREIGN KEY (feed_version_id) REFERENCES public.feed_versions(id);
ALTER TABLE public.gtfs_stop_times
    ADD CONSTRAINT gtfs_stop_times_stop_id_fkey FOREIGN KEY (stop_id) REFERENCES public.gtfs_stops(id);
ALTER TABLE public.gtfs_stop_times
    ADD CONSTRAINT gtfs_stop_times_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.gtfs_trips(id);