CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE TABLE agency_geometries (
    agency_id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    geometry geography(Polygon,4326),
    centroid geography(Point,4326)
);
CREATE TABLE agency_places (
    id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    agency_id bigint NOT NULL,
    count integer NOT NULL,
    rank double precision NOT NULL,
    name character varying,
    adm1name character varying NOT NULL,
    adm0name character varying NOT NULL
);
CREATE SEQUENCE agency_places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE agency_places_id_seq OWNED BY agency_places.id;
CREATE TABLE change_payloads (
    id integer NOT NULL,
    payload json,
    changeset_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE change_payloads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE change_payloads_id_seq OWNED BY change_payloads.id;
CREATE TABLE changesets (
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
CREATE SEQUENCE changesets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE changesets_id_seq OWNED BY changesets.id;
CREATE TABLE current_feeds (
    id bigint NOT NULL,
    onestop_id character varying NOT NULL,
    url character varying,
    spec character varying DEFAULT 'gtfs'::character varying NOT NULL,
    tags hstore,
    last_fetched_at timestamp without time zone,
    last_imported_at timestamp without time zone,
    version integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    created_or_updated_in_changeset_id integer,
    geometry geography(Geometry,4326),
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
CREATE SEQUENCE current_feeds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_feeds_id_seq OWNED BY current_feeds.id;
CREATE TABLE current_operators (
    id integer NOT NULL,
    name character varying,
    tags hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    onestop_id character varying,
    geometry geography(Geometry,4326),
    created_or_updated_in_changeset_id integer,
    version integer,
    timezone character varying,
    short_name character varying,
    website character varying,
    country character varying,
    state character varying,
    metro character varying,
    edited_attributes character varying[] DEFAULT '{}'::character varying[]
);
CREATE SEQUENCE current_operators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_operators_id_seq OWNED BY current_operators.id;
CREATE TABLE current_operators_in_feed (
    id integer NOT NULL,
    gtfs_agency_id character varying,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    operator_id integer,
    feed_id integer,
    created_or_updated_in_changeset_id integer
);
CREATE SEQUENCE current_operators_in_feed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_operators_in_feed_id_seq OWNED BY current_operators_in_feed.id;
CREATE TABLE current_operators_serving_stop (
    id integer NOT NULL,
    stop_id integer NOT NULL,
    operator_id integer NOT NULL,
    tags hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    created_or_updated_in_changeset_id integer,
    version integer
);
CREATE SEQUENCE current_operators_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_operators_serving_stop_id_seq OWNED BY current_operators_serving_stop.id;
CREATE TABLE current_route_stop_patterns (
    id integer NOT NULL,
    onestop_id character varying,
    geometry geography(Geometry,4326),
    tags hstore,
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
CREATE SEQUENCE current_route_stop_patterns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_route_stop_patterns_id_seq OWNED BY current_route_stop_patterns.id;
CREATE TABLE current_routes (
    id integer NOT NULL,
    onestop_id character varying,
    name character varying,
    tags hstore,
    operator_id integer,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    geometry geography(Geometry,4326),
    vehicle_type integer,
    color character varying,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    wheelchair_accessible character varying DEFAULT 'unknown'::character varying,
    bikes_allowed character varying DEFAULT 'unknown'::character varying
);
CREATE SEQUENCE current_routes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_routes_id_seq OWNED BY current_routes.id;
CREATE TABLE current_routes_serving_stop (
    id integer NOT NULL,
    route_id integer,
    stop_id integer,
    tags hstore,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE current_routes_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_routes_serving_stop_id_seq OWNED BY current_routes_serving_stop.id;
CREATE TABLE current_schedule_stop_pairs (
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
    tags hstore,
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
CREATE SEQUENCE current_schedule_stop_pairs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_schedule_stop_pairs_id_seq OWNED BY current_schedule_stop_pairs.id;
CREATE TABLE current_stop_transfers (
    id integer NOT NULL,
    transfer_type character varying,
    min_transfer_time integer,
    tags hstore,
    stop_id integer,
    to_stop_id integer,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE current_stop_transfers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_stop_transfers_id_seq OWNED BY current_stop_transfers.id;
CREATE TABLE current_stops (
    id integer NOT NULL,
    onestop_id character varying,
    geometry geography(Geometry,4326),
    tags hstore,
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
    geometry_reversegeo geography(Point,4326)
);
CREATE SEQUENCE current_stops_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE current_stops_id_seq OWNED BY current_stops.id;
CREATE TABLE entities_imported_from_feed (
    id integer NOT NULL,
    entity_id integer,
    entity_type character varying,
    feed_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    feed_version_id integer,
    gtfs_id character varying
);
CREATE SEQUENCE entities_imported_from_feed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE entities_imported_from_feed_id_seq OWNED BY entities_imported_from_feed.id;
CREATE TABLE entities_with_issues (
    id integer NOT NULL,
    entity_id integer,
    entity_type character varying,
    entity_attribute character varying,
    issue_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE entities_with_issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE entities_with_issues_id_seq OWNED BY entities_with_issues.id;
CREATE TABLE feed_schedule_imports (
    id integer NOT NULL,
    success boolean,
    import_log text,
    exception_log text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_import_id integer
);
CREATE SEQUENCE feed_schedule_imports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE feed_schedule_imports_id_seq OWNED BY feed_schedule_imports.id;
CREATE TABLE feed_states (
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
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE feed_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE feed_states_id_seq OWNED BY feed_states.id;
CREATE TABLE feed_version_geometries (
    feed_version_id bigint NOT NULL,
    geometry geography(Polygon,4326),
    centroid geography(Point,4326)
);
CREATE TABLE feed_version_gtfs_imports (
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
CREATE SEQUENCE feed_version_gtfs_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE feed_version_gtfs_imports_id_seq OWNED BY feed_version_gtfs_imports.id;
CREATE TABLE feed_version_imports (
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
CREATE SEQUENCE feed_version_imports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE feed_version_imports_id_seq OWNED BY feed_version_imports.id;
CREATE TABLE feed_version_infos (
    id integer NOT NULL,
    type character varying,
    data json,
    feed_version_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE feed_version_infos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE feed_version_infos_id_seq OWNED BY feed_version_infos.id;
CREATE TABLE feed_versions (
    id bigint NOT NULL,
    feed_id bigint NOT NULL,
    feed_type character varying DEFAULT 'gtfs'::character varying NOT NULL,
    file character varying DEFAULT ''::character varying NOT NULL,
    earliest_calendar_date date NOT NULL,
    latest_calendar_date date NOT NULL,
    sha1 character varying NOT NULL,
    md5 character varying,
    tags hstore,
    fetched_at timestamp without time zone NOT NULL,
    imported_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    import_level integer DEFAULT 0 NOT NULL,
    url character varying DEFAULT ''::character varying NOT NULL,
    file_raw character varying,
    sha1_raw character varying,
    md5_raw character varying,
    file_feedvalidator character varying,
    deleted_at timestamp without time zone,
    sha1_dir character varying
);
CREATE SEQUENCE feed_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE feed_versions_id_seq OWNED BY feed_versions.id;
CREATE TABLE gtfs_agencies (
    id bigint NOT NULL,
    agency_id character varying NOT NULL,
    agency_name character varying NOT NULL,
    agency_url character varying NOT NULL,
    agency_timezone character varying NOT NULL,
    agency_lang character varying NOT NULL,
    agency_phone character varying NOT NULL,
    agency_fare_url character varying NOT NULL,
    agency_email character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_agencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_agencies_id_seq OWNED BY gtfs_agencies.id;
CREATE TABLE gtfs_calendar_dates (
    id bigint NOT NULL,
    date date NOT NULL,
    exception_type integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    service_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_calendar_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_calendar_dates_id_seq OWNED BY gtfs_calendar_dates.id;
CREATE TABLE gtfs_calendars (
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    generated boolean NOT NULL
);
CREATE SEQUENCE gtfs_calendars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_calendars_id_seq OWNED BY gtfs_calendars.id;
CREATE TABLE gtfs_fare_attributes (
    id bigint NOT NULL,
    fare_id character varying NOT NULL,
    price double precision NOT NULL,
    currency_type character varying NOT NULL,
    payment_method integer NOT NULL,
    transfer_duration integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    agency_id bigint,
    transfers integer NOT NULL
);
CREATE SEQUENCE gtfs_fare_attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_fare_attributes_id_seq OWNED BY gtfs_fare_attributes.id;
CREATE TABLE gtfs_fare_rules (
    id bigint NOT NULL,
    origin_id character varying NOT NULL,
    destination_id character varying NOT NULL,
    contains_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    route_id bigint,
    fare_id bigint
);
CREATE SEQUENCE gtfs_fare_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_fare_rules_id_seq OWNED BY gtfs_fare_rules.id;
CREATE TABLE gtfs_feed_infos (
    id bigint NOT NULL,
    feed_publisher_name character varying NOT NULL,
    feed_publisher_url character varying NOT NULL,
    feed_lang character varying NOT NULL,
    feed_start_date date,
    feed_end_date date,
    feed_version_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_feed_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_feed_infos_id_seq OWNED BY gtfs_feed_infos.id;
CREATE TABLE gtfs_frequencies (
    id bigint NOT NULL,
    start_time integer NOT NULL,
    end_time integer NOT NULL,
    headway_secs integer NOT NULL,
    exact_times integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_frequencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_frequencies_id_seq OWNED BY gtfs_frequencies.id;
CREATE TABLE gtfs_levels (
    id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    level_id character varying NOT NULL,
    level_index double precision NOT NULL,
    level_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE gtfs_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_levels_id_seq OWNED BY gtfs_levels.id;
CREATE TABLE gtfs_pathways (
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE gtfs_pathways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_pathways_id_seq OWNED BY gtfs_pathways.id;
CREATE TABLE gtfs_routes (
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    agency_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_routes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_routes_id_seq OWNED BY gtfs_routes.id;
CREATE TABLE gtfs_shapes (
    id bigint NOT NULL,
    shape_id character varying NOT NULL,
    generated boolean DEFAULT false NOT NULL,
    geometry geography(LineStringM,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_shapes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_shapes_id_seq OWNED BY gtfs_shapes.id;
CREATE TABLE gtfs_stop_times (
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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    trip_id bigint NOT NULL,
    stop_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_stop_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_stop_times_id_seq OWNED BY gtfs_stop_times.id;
CREATE TABLE gtfs_stops (
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
    geometry geography(Point,4326) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    parent_station bigint,
    level_id bigint
);
CREATE SEQUENCE gtfs_stops_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_stops_id_seq OWNED BY gtfs_stops.id;
CREATE TABLE gtfs_transfers (
    id bigint NOT NULL,
    transfer_type integer NOT NULL,
    min_transfer_time integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    from_stop_id bigint NOT NULL,
    to_stop_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_transfers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_transfers_id_seq OWNED BY gtfs_transfers.id;
CREATE TABLE gtfs_trips (
    id bigint NOT NULL,
    trip_id character varying NOT NULL,
    trip_headsign character varying NOT NULL,
    trip_short_name character varying NOT NULL,
    direction_id integer NOT NULL,
    block_id character varying NOT NULL,
    wheelchair_accessible integer NOT NULL,
    bikes_allowed integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    feed_version_id bigint NOT NULL,
    route_id bigint NOT NULL,
    shape_id bigint,
    stop_pattern_id integer NOT NULL,
    service_id bigint NOT NULL
);
CREATE SEQUENCE gtfs_trips_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gtfs_trips_id_seq OWNED BY gtfs_trips.id;
CREATE TABLE issues (
    id integer NOT NULL,
    created_by_changeset_id integer,
    resolved_by_changeset_id integer,
    details character varying,
    issue_type character varying,
    open boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE issues_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE issues_id_seq OWNED BY issues.id;
CREATE TABLE old_feeds (
    id integer NOT NULL,
    onestop_id character varying NOT NULL,
    url character varying,
    spec character varying DEFAULT 'gtfs'::character varying NOT NULL,
    tags hstore,
    last_fetched_at timestamp without time zone,
    last_imported_at timestamp without time zone,
    version integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    current_id integer,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    geometry geography(Geometry,4326),
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
CREATE SEQUENCE old_feeds_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_feeds_id_seq OWNED BY old_feeds.id;
CREATE TABLE old_operators (
    name character varying,
    tags hstore,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    onestop_id character varying,
    geometry geography(Geometry,4326),
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
CREATE SEQUENCE old_operators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_operators_id_seq OWNED BY old_operators.id;
CREATE TABLE old_operators_in_feed (
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
CREATE SEQUENCE old_operators_in_feed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_operators_in_feed_id_seq OWNED BY old_operators_in_feed.id;
CREATE TABLE old_operators_serving_stop (
    stop_id integer,
    operator_id integer,
    tags hstore,
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
CREATE SEQUENCE old_operators_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_operators_serving_stop_id_seq OWNED BY old_operators_serving_stop.id;
CREATE TABLE old_route_stop_patterns (
    id integer NOT NULL,
    onestop_id character varying,
    geometry geography(Geometry,4326),
    tags hstore,
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
CREATE SEQUENCE old_route_stop_patterns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_route_stop_patterns_id_seq OWNED BY old_route_stop_patterns.id;
CREATE TABLE old_routes (
    id integer NOT NULL,
    onestop_id character varying,
    name character varying,
    tags hstore,
    operator_id integer,
    operator_type character varying,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    current_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    geometry geography(Geometry,4326),
    vehicle_type integer,
    color character varying,
    edited_attributes character varying[] DEFAULT '{}'::character varying[],
    wheelchair_accessible character varying DEFAULT 'unknown'::character varying,
    bikes_allowed character varying DEFAULT 'unknown'::character varying,
    action character varying
);
CREATE SEQUENCE old_routes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_routes_id_seq OWNED BY old_routes.id;
CREATE TABLE old_routes_serving_stop (
    id integer NOT NULL,
    route_id integer,
    route_type character varying,
    stop_id integer,
    stop_type character varying,
    tags hstore,
    created_or_updated_in_changeset_id integer,
    destroyed_in_changeset_id integer,
    current_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);
CREATE SEQUENCE old_routes_serving_stop_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_routes_serving_stop_id_seq OWNED BY old_routes_serving_stop.id;
CREATE TABLE old_schedule_stop_pairs (
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
    tags hstore,
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
CREATE SEQUENCE old_schedule_stop_pairs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_schedule_stop_pairs_id_seq OWNED BY old_schedule_stop_pairs.id;
CREATE TABLE old_stop_transfers (
    id integer NOT NULL,
    transfer_type character varying,
    min_transfer_time integer,
    tags hstore,
    stop_id integer,
    to_stop_id integer,
    created_or_updated_in_changeset_id integer,
    version integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    destroyed_in_changeset_id integer,
    current_id integer
);
CREATE SEQUENCE old_stop_transfers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_stop_transfers_id_seq OWNED BY old_stop_transfers.id;
CREATE TABLE old_stops (
    onestop_id character varying,
    geometry geography(Geometry,4326),
    tags hstore,
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
    geometry_reversegeo geography(Point,4326)
);
CREATE SEQUENCE old_stops_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE old_stops_id_seq OWNED BY old_stops.id;
CREATE TABLE route_geometries (
    route_id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    shape_id bigint NOT NULL,
    direction_id integer NOT NULL,
    generated boolean NOT NULL,
    geometry geography(LineString,4326) NOT NULL,
    geometry_z14 geography(LineString,4326) NOT NULL,
    geometry_z10 geography(LineString,4326) NOT NULL,
    geometry_z6 geography(LineString,4326) NOT NULL,
    centroid geography(Point,4326) NOT NULL
);
CREATE TABLE route_headways (
    id bigint NOT NULL,
    feed_version_id bigint NOT NULL,
    route_id bigint NOT NULL,
    selected_stop_id bigint NOT NULL,
    service_id bigint NOT NULL,
    direction_id integer,
    headway_secs integer
);
CREATE SEQUENCE route_headways_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE route_headways_id_seq OWNED BY route_headways.id;
CREATE TABLE route_stops (
    feed_version_id bigint NOT NULL,
    agency_id bigint NOT NULL,
    route_id bigint NOT NULL,
    stop_id bigint NOT NULL
);
CREATE TABLE users (
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
CREATE SEQUENCE users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE users_id_seq OWNED BY users.id;
ALTER TABLE ONLY agency_places ALTER COLUMN id SET DEFAULT nextval('agency_places_id_seq'::regclass);
ALTER TABLE ONLY change_payloads ALTER COLUMN id SET DEFAULT nextval('change_payloads_id_seq'::regclass);
ALTER TABLE ONLY changesets ALTER COLUMN id SET DEFAULT nextval('changesets_id_seq'::regclass);
ALTER TABLE ONLY current_feeds ALTER COLUMN id SET DEFAULT nextval('current_feeds_id_seq'::regclass);
ALTER TABLE ONLY current_operators ALTER COLUMN id SET DEFAULT nextval('current_operators_id_seq'::regclass);
ALTER TABLE ONLY current_operators_in_feed ALTER COLUMN id SET DEFAULT nextval('current_operators_in_feed_id_seq'::regclass);
ALTER TABLE ONLY current_operators_serving_stop ALTER COLUMN id SET DEFAULT nextval('current_operators_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY current_route_stop_patterns ALTER COLUMN id SET DEFAULT nextval('current_route_stop_patterns_id_seq'::regclass);
ALTER TABLE ONLY current_routes ALTER COLUMN id SET DEFAULT nextval('current_routes_id_seq'::regclass);
ALTER TABLE ONLY current_routes_serving_stop ALTER COLUMN id SET DEFAULT nextval('current_routes_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY current_schedule_stop_pairs ALTER COLUMN id SET DEFAULT nextval('current_schedule_stop_pairs_id_seq'::regclass);
ALTER TABLE ONLY current_stop_transfers ALTER COLUMN id SET DEFAULT nextval('current_stop_transfers_id_seq'::regclass);
ALTER TABLE ONLY current_stops ALTER COLUMN id SET DEFAULT nextval('current_stops_id_seq'::regclass);
ALTER TABLE ONLY entities_imported_from_feed ALTER COLUMN id SET DEFAULT nextval('entities_imported_from_feed_id_seq'::regclass);
ALTER TABLE ONLY entities_with_issues ALTER COLUMN id SET DEFAULT nextval('entities_with_issues_id_seq'::regclass);
ALTER TABLE ONLY feed_schedule_imports ALTER COLUMN id SET DEFAULT nextval('feed_schedule_imports_id_seq'::regclass);
ALTER TABLE ONLY feed_states ALTER COLUMN id SET DEFAULT nextval('feed_states_id_seq'::regclass);
ALTER TABLE ONLY feed_version_gtfs_imports ALTER COLUMN id SET DEFAULT nextval('feed_version_gtfs_imports_id_seq'::regclass);
ALTER TABLE ONLY feed_version_imports ALTER COLUMN id SET DEFAULT nextval('feed_version_imports_id_seq'::regclass);
ALTER TABLE ONLY feed_version_infos ALTER COLUMN id SET DEFAULT nextval('feed_version_infos_id_seq'::regclass);
ALTER TABLE ONLY feed_versions ALTER COLUMN id SET DEFAULT nextval('feed_versions_id_seq'::regclass);
ALTER TABLE ONLY gtfs_agencies ALTER COLUMN id SET DEFAULT nextval('gtfs_agencies_id_seq'::regclass);
ALTER TABLE ONLY gtfs_calendar_dates ALTER COLUMN id SET DEFAULT nextval('gtfs_calendar_dates_id_seq'::regclass);
ALTER TABLE ONLY gtfs_calendars ALTER COLUMN id SET DEFAULT nextval('gtfs_calendars_id_seq'::regclass);
ALTER TABLE ONLY gtfs_fare_attributes ALTER COLUMN id SET DEFAULT nextval('gtfs_fare_attributes_id_seq'::regclass);
ALTER TABLE ONLY gtfs_fare_rules ALTER COLUMN id SET DEFAULT nextval('gtfs_fare_rules_id_seq'::regclass);
ALTER TABLE ONLY gtfs_feed_infos ALTER COLUMN id SET DEFAULT nextval('gtfs_feed_infos_id_seq'::regclass);
ALTER TABLE ONLY gtfs_frequencies ALTER COLUMN id SET DEFAULT nextval('gtfs_frequencies_id_seq'::regclass);
ALTER TABLE ONLY gtfs_levels ALTER COLUMN id SET DEFAULT nextval('gtfs_levels_id_seq'::regclass);
ALTER TABLE ONLY gtfs_pathways ALTER COLUMN id SET DEFAULT nextval('gtfs_pathways_id_seq'::regclass);
ALTER TABLE ONLY gtfs_routes ALTER COLUMN id SET DEFAULT nextval('gtfs_routes_id_seq'::regclass);
ALTER TABLE ONLY gtfs_shapes ALTER COLUMN id SET DEFAULT nextval('gtfs_shapes_id_seq'::regclass);
ALTER TABLE ONLY gtfs_stop_times ALTER COLUMN id SET DEFAULT nextval('gtfs_stop_times_id_seq'::regclass);
ALTER TABLE ONLY gtfs_stops ALTER COLUMN id SET DEFAULT nextval('gtfs_stops_id_seq'::regclass);
ALTER TABLE ONLY gtfs_transfers ALTER COLUMN id SET DEFAULT nextval('gtfs_transfers_id_seq'::regclass);
ALTER TABLE ONLY gtfs_trips ALTER COLUMN id SET DEFAULT nextval('gtfs_trips_id_seq'::regclass);
ALTER TABLE ONLY issues ALTER COLUMN id SET DEFAULT nextval('issues_id_seq'::regclass);
ALTER TABLE ONLY old_feeds ALTER COLUMN id SET DEFAULT nextval('old_feeds_id_seq'::regclass);
ALTER TABLE ONLY old_operators ALTER COLUMN id SET DEFAULT nextval('old_operators_id_seq'::regclass);
ALTER TABLE ONLY old_operators_in_feed ALTER COLUMN id SET DEFAULT nextval('old_operators_in_feed_id_seq'::regclass);
ALTER TABLE ONLY old_operators_serving_stop ALTER COLUMN id SET DEFAULT nextval('old_operators_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY old_route_stop_patterns ALTER COLUMN id SET DEFAULT nextval('old_route_stop_patterns_id_seq'::regclass);
ALTER TABLE ONLY old_routes ALTER COLUMN id SET DEFAULT nextval('old_routes_id_seq'::regclass);
ALTER TABLE ONLY old_routes_serving_stop ALTER COLUMN id SET DEFAULT nextval('old_routes_serving_stop_id_seq'::regclass);
ALTER TABLE ONLY old_schedule_stop_pairs ALTER COLUMN id SET DEFAULT nextval('old_schedule_stop_pairs_id_seq'::regclass);
ALTER TABLE ONLY old_stop_transfers ALTER COLUMN id SET DEFAULT nextval('old_stop_transfers_id_seq'::regclass);
ALTER TABLE ONLY old_stops ALTER COLUMN id SET DEFAULT nextval('old_stops_id_seq'::regclass);
ALTER TABLE ONLY route_headways ALTER COLUMN id SET DEFAULT nextval('route_headways_id_seq'::regclass);
ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);
ALTER TABLE ONLY agency_places
    ADD CONSTRAINT agency_places_pkey PRIMARY KEY (id);
ALTER TABLE ONLY change_payloads
    ADD CONSTRAINT change_payloads_pkey PRIMARY KEY (id);
ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_feeds
    ADD CONSTRAINT current_feeds_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_operators_in_feed
    ADD CONSTRAINT current_operators_in_feed_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_operators
    ADD CONSTRAINT current_operators_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_operators_serving_stop
    ADD CONSTRAINT current_operators_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_route_stop_patterns
    ADD CONSTRAINT current_route_stop_patterns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_routes
    ADD CONSTRAINT current_routes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_routes_serving_stop
    ADD CONSTRAINT current_routes_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_schedule_stop_pairs
    ADD CONSTRAINT current_schedule_stop_pairs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_stop_transfers
    ADD CONSTRAINT current_stop_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY current_stops
    ADD CONSTRAINT current_stops_pkey PRIMARY KEY (id);
ALTER TABLE ONLY entities_imported_from_feed
    ADD CONSTRAINT entities_imported_from_feed_pkey PRIMARY KEY (id);
ALTER TABLE ONLY entities_with_issues
    ADD CONSTRAINT entities_with_issues_pkey PRIMARY KEY (id);
ALTER TABLE ONLY feed_schedule_imports
    ADD CONSTRAINT feed_schedule_imports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY feed_states
    ADD CONSTRAINT feed_states_pkey PRIMARY KEY (id);
ALTER TABLE ONLY feed_version_gtfs_imports
    ADD CONSTRAINT feed_version_gtfs_imports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY feed_version_imports
    ADD CONSTRAINT feed_version_imports_pkey PRIMARY KEY (id);
ALTER TABLE ONLY feed_version_infos
    ADD CONSTRAINT feed_version_infos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY feed_versions
    ADD CONSTRAINT feed_versions_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_agencies
    ADD CONSTRAINT gtfs_agencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_calendar_dates
    ADD CONSTRAINT gtfs_calendar_dates_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_calendars
    ADD CONSTRAINT gtfs_calendars_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_fare_attributes
    ADD CONSTRAINT gtfs_fare_attributes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_fare_rules
    ADD CONSTRAINT gtfs_fare_rules_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_feed_infos
    ADD CONSTRAINT gtfs_feed_infos_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_frequencies
    ADD CONSTRAINT gtfs_frequencies_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_levels
    ADD CONSTRAINT gtfs_levels_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_pathways
    ADD CONSTRAINT gtfs_pathways_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_routes
    ADD CONSTRAINT gtfs_routes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_shapes
    ADD CONSTRAINT gtfs_shapes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_stop_times
    ADD CONSTRAINT gtfs_stop_times_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_stops
    ADD CONSTRAINT gtfs_stops_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_transfers
    ADD CONSTRAINT gtfs_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY gtfs_trips
    ADD CONSTRAINT gtfs_trips_pkey PRIMARY KEY (id);
ALTER TABLE ONLY issues
    ADD CONSTRAINT issues_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_feeds
    ADD CONSTRAINT old_feeds_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_operators_in_feed
    ADD CONSTRAINT old_operators_in_feed_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_operators
    ADD CONSTRAINT old_operators_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_operators_serving_stop
    ADD CONSTRAINT old_operators_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_route_stop_patterns
    ADD CONSTRAINT old_route_stop_patterns_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_routes
    ADD CONSTRAINT old_routes_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_routes_serving_stop
    ADD CONSTRAINT old_routes_serving_stop_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_schedule_stop_pairs
    ADD CONSTRAINT old_schedule_stop_pairs_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_stop_transfers
    ADD CONSTRAINT old_stop_transfers_pkey PRIMARY KEY (id);
ALTER TABLE ONLY old_stops
    ADD CONSTRAINT old_stops_pkey PRIMARY KEY (id);
ALTER TABLE ONLY route_headways
    ADD CONSTRAINT route_headways_pkey PRIMARY KEY (id);
ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);
CREATE INDEX "#c_operators_cu_in_changeset_id_index" ON current_operators USING btree (created_or_updated_in_changeset_id);
CREATE INDEX "#c_operators_serving_stop_cu_in_changeset_id_index" ON current_operators_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX "#c_stops_cu_in_changeset_id_index" ON current_stops USING btree (created_or_updated_in_changeset_id);
CREATE INDEX agency_places_agency_id_idx ON agency_places USING btree (agency_id);
CREATE INDEX agency_places_feed_version_id_idx ON agency_places USING btree (feed_version_id);
CREATE INDEX c_route_cu_in_changeset ON current_routes USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_rsp_cu_in_changeset ON current_route_stop_patterns USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_rss_cu_in_changeset ON current_routes_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_ssp_cu_in_changeset ON current_schedule_stop_pairs USING btree (created_or_updated_in_changeset_id);
CREATE INDEX c_ssp_destination ON current_schedule_stop_pairs USING btree (destination_id);
CREATE INDEX c_ssp_origin ON current_schedule_stop_pairs USING btree (origin_id);
CREATE INDEX c_ssp_route ON current_schedule_stop_pairs USING btree (route_id);
CREATE INDEX c_ssp_service_end_date ON current_schedule_stop_pairs USING btree (service_end_date);
CREATE INDEX c_ssp_service_start_date ON current_schedule_stop_pairs USING btree (service_start_date);
CREATE INDEX c_ssp_trip ON current_schedule_stop_pairs USING btree (trip);
CREATE INDEX current_oif ON current_operators_in_feed USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_agency_geometries_on_centroid ON agency_geometries USING gist (centroid);
CREATE INDEX index_agency_geometries_on_feed_version_id ON agency_geometries USING btree (feed_version_id);
CREATE INDEX index_agency_geometries_on_geometry ON agency_geometries USING gist (geometry);
CREATE UNIQUE INDEX index_agency_geometries_unique ON agency_geometries USING btree (agency_id);
CREATE INDEX index_change_payloads_on_changeset_id ON change_payloads USING btree (changeset_id);
CREATE INDEX index_changesets_on_feed_id ON changesets USING btree (feed_id);
CREATE INDEX index_changesets_on_feed_version_id ON changesets USING btree (feed_version_id);
CREATE INDEX index_changesets_on_user_id ON changesets USING btree (user_id);
CREATE INDEX index_current_feeds_on_active_feed_version_id ON current_feeds USING btree (active_feed_version_id);
CREATE INDEX index_current_feeds_on_auth ON current_feeds USING btree (auth);
CREATE INDEX index_current_feeds_on_created_or_updated_in_changeset_id ON current_feeds USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_current_feeds_on_geometry ON current_feeds USING gist (geometry);
CREATE UNIQUE INDEX index_current_feeds_on_onestop_id ON current_feeds USING btree (onestop_id);
CREATE INDEX index_current_feeds_on_urls ON current_feeds USING btree (urls);
CREATE INDEX index_current_operators_in_feed_on_feed_id ON current_operators_in_feed USING btree (feed_id);
CREATE INDEX index_current_operators_in_feed_on_operator_id ON current_operators_in_feed USING btree (operator_id);
CREATE INDEX index_current_operators_on_geometry ON current_operators USING gist (geometry);
CREATE UNIQUE INDEX index_current_operators_on_onestop_id ON current_operators USING btree (onestop_id);
CREATE INDEX index_current_operators_on_tags ON current_operators USING btree (tags);
CREATE INDEX index_current_operators_on_updated_at ON current_operators USING btree (updated_at);
CREATE INDEX index_current_operators_serving_stop_on_operator_id ON current_operators_serving_stop USING btree (operator_id);
CREATE UNIQUE INDEX index_current_operators_serving_stop_on_stop_id_and_operator_id ON current_operators_serving_stop USING btree (stop_id, operator_id);
CREATE UNIQUE INDEX index_current_route_stop_patterns_on_onestop_id ON current_route_stop_patterns USING btree (onestop_id);
CREATE INDEX index_current_route_stop_patterns_on_route_id ON current_route_stop_patterns USING btree (route_id);
CREATE INDEX index_current_route_stop_patterns_on_stop_pattern ON current_route_stop_patterns USING gin (stop_pattern);
CREATE INDEX index_current_routes_on_bikes_allowed ON current_routes USING btree (bikes_allowed);
CREATE INDEX index_current_routes_on_geometry ON current_routes USING gist (geometry);
CREATE UNIQUE INDEX index_current_routes_on_onestop_id ON current_routes USING btree (onestop_id);
CREATE INDEX index_current_routes_on_operator_id ON current_routes USING btree (operator_id);
CREATE INDEX index_current_routes_on_tags ON current_routes USING btree (tags);
CREATE INDEX index_current_routes_on_updated_at ON current_routes USING btree (updated_at);
CREATE INDEX index_current_routes_on_vehicle_type ON current_routes USING btree (vehicle_type);
CREATE INDEX index_current_routes_on_wheelchair_accessible ON current_routes USING btree (wheelchair_accessible);
CREATE INDEX index_current_routes_serving_stop_on_route_id ON current_routes_serving_stop USING btree (route_id);
CREATE INDEX index_current_routes_serving_stop_on_stop_id ON current_routes_serving_stop USING btree (stop_id);
CREATE INDEX index_current_schedule_stop_pairs_on_feed_id_and_id ON current_schedule_stop_pairs USING btree (feed_id, id);
CREATE INDEX index_current_schedule_stop_pairs_on_feed_version_id_and_id ON current_schedule_stop_pairs USING btree (feed_version_id, id);
CREATE INDEX index_current_schedule_stop_pairs_on_frequency_type ON current_schedule_stop_pairs USING btree (frequency_type);
CREATE INDEX index_current_schedule_stop_pairs_on_operator_id_and_id ON current_schedule_stop_pairs USING btree (operator_id, id);
CREATE INDEX index_current_schedule_stop_pairs_on_origin_departure_time ON current_schedule_stop_pairs USING btree (origin_departure_time);
CREATE INDEX index_current_schedule_stop_pairs_on_route_stop_pattern_id ON current_schedule_stop_pairs USING btree (route_stop_pattern_id);
CREATE INDEX index_current_schedule_stop_pairs_on_updated_at ON current_schedule_stop_pairs USING btree (updated_at);
CREATE INDEX index_current_stop_transfers_changeset_id ON current_stop_transfers USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_current_stop_transfers_on_min_transfer_time ON current_stop_transfers USING btree (min_transfer_time);
CREATE INDEX index_current_stop_transfers_on_stop_id ON current_stop_transfers USING btree (stop_id);
CREATE INDEX index_current_stop_transfers_on_to_stop_id ON current_stop_transfers USING btree (to_stop_id);
CREATE INDEX index_current_stop_transfers_on_transfer_type ON current_stop_transfers USING btree (transfer_type);
CREATE INDEX index_current_stops_on_geometry ON current_stops USING gist (geometry);
CREATE INDEX index_current_stops_on_geometry_reversegeo ON current_stops USING gist (geometry_reversegeo);
CREATE UNIQUE INDEX index_current_stops_on_onestop_id ON current_stops USING btree (onestop_id);
CREATE INDEX index_current_stops_on_parent_stop_id ON current_stops USING btree (parent_stop_id);
CREATE INDEX index_current_stops_on_tags ON current_stops USING btree (tags);
CREATE INDEX index_current_stops_on_updated_at ON current_stops USING btree (updated_at);
CREATE INDEX index_current_stops_on_wheelchair_boarding ON current_stops USING btree (wheelchair_boarding);
CREATE INDEX index_entities_imported_from_feed_on_entity_type_and_entity_id ON entities_imported_from_feed USING btree (entity_type, entity_id);
CREATE INDEX index_entities_imported_from_feed_on_feed_id ON entities_imported_from_feed USING btree (feed_id);
CREATE INDEX index_entities_imported_from_feed_on_feed_version_id ON entities_imported_from_feed USING btree (feed_version_id);
CREATE INDEX index_entities_with_issues_on_entity_type_and_entity_id ON entities_with_issues USING btree (entity_type, entity_id);
CREATE INDEX index_feed_schedule_imports_on_feed_version_import_id ON feed_schedule_imports USING btree (feed_version_import_id);
CREATE UNIQUE INDEX index_feed_states_on_feed_id ON feed_states USING btree (feed_id);
CREATE UNIQUE INDEX index_feed_states_on_feed_priority ON feed_states USING btree (feed_priority);
CREATE UNIQUE INDEX index_feed_states_on_feed_version_id ON feed_states USING btree (feed_version_id);
CREATE INDEX index_feed_version_geometries_on_centroid ON feed_version_geometries USING gist (centroid);
CREATE INDEX index_feed_version_geometries_on_geometry ON feed_version_geometries USING gist (geometry);
CREATE UNIQUE INDEX index_feed_version_geometries_unique ON feed_version_geometries USING btree (feed_version_id);
CREATE UNIQUE INDEX index_feed_version_gtfs_imports_on_feed_version_id ON feed_version_gtfs_imports USING btree (feed_version_id);
CREATE INDEX index_feed_version_gtfs_imports_on_success ON feed_version_gtfs_imports USING btree (success);
CREATE INDEX index_feed_version_imports_on_feed_version_id ON feed_version_imports USING btree (feed_version_id);
CREATE INDEX index_feed_version_infos_on_feed_version_id ON feed_version_infos USING btree (feed_version_id);
CREATE UNIQUE INDEX index_feed_version_infos_on_feed_version_id_and_type ON feed_version_infos USING btree (feed_version_id, type);
CREATE INDEX index_feed_versions_on_earliest_calendar_date ON feed_versions USING btree (earliest_calendar_date);
CREATE INDEX index_feed_versions_on_feed_type_and_feed_id ON feed_versions USING btree (feed_type, feed_id);
CREATE INDEX index_feed_versions_on_latest_calendar_date ON feed_versions USING btree (latest_calendar_date);
CREATE INDEX index_gtfs_agencies_on_agency_id ON gtfs_agencies USING btree (agency_id);
CREATE INDEX index_gtfs_agencies_on_agency_name ON gtfs_agencies USING btree (agency_name);
CREATE UNIQUE INDEX index_gtfs_agencies_unique ON gtfs_agencies USING btree (feed_version_id, agency_id);
CREATE INDEX index_gtfs_calendar_dates_on_date ON gtfs_calendar_dates USING btree (date);
CREATE INDEX index_gtfs_calendar_dates_on_exception_type ON gtfs_calendar_dates USING btree (exception_type);
CREATE INDEX index_gtfs_calendar_dates_on_feed_version_id ON gtfs_calendar_dates USING btree (feed_version_id);
CREATE INDEX index_gtfs_calendar_dates_on_service_id ON gtfs_calendar_dates USING btree (service_id);
CREATE INDEX index_gtfs_calendars_on_end_date ON gtfs_calendars USING btree (end_date);
CREATE UNIQUE INDEX index_gtfs_calendars_on_feed_version_id_and_service_id ON gtfs_calendars USING btree (feed_version_id, service_id);
CREATE INDEX index_gtfs_calendars_on_friday ON gtfs_calendars USING btree (friday);
CREATE INDEX index_gtfs_calendars_on_monday ON gtfs_calendars USING btree (monday);
CREATE INDEX index_gtfs_calendars_on_saturday ON gtfs_calendars USING btree (saturday);
CREATE INDEX index_gtfs_calendars_on_service_id ON gtfs_calendars USING btree (service_id);
CREATE INDEX index_gtfs_calendars_on_start_date ON gtfs_calendars USING btree (start_date);
CREATE INDEX index_gtfs_calendars_on_sunday ON gtfs_calendars USING btree (sunday);
CREATE INDEX index_gtfs_calendars_on_thursday ON gtfs_calendars USING btree (thursday);
CREATE INDEX index_gtfs_calendars_on_tuesday ON gtfs_calendars USING btree (tuesday);
CREATE INDEX index_gtfs_calendars_on_wednesday ON gtfs_calendars USING btree (wednesday);
CREATE INDEX index_gtfs_fare_attributes_on_agency_id ON gtfs_fare_attributes USING btree (agency_id);
CREATE INDEX index_gtfs_fare_attributes_on_fare_id ON gtfs_fare_attributes USING btree (fare_id);
CREATE UNIQUE INDEX index_gtfs_fare_attributes_unique ON gtfs_fare_attributes USING btree (feed_version_id, fare_id);
CREATE INDEX index_gtfs_fare_rules_on_fare_id ON gtfs_fare_rules USING btree (fare_id);
CREATE INDEX index_gtfs_fare_rules_on_feed_version_id ON gtfs_fare_rules USING btree (feed_version_id);
CREATE INDEX index_gtfs_fare_rules_on_route_id ON gtfs_fare_rules USING btree (route_id);
CREATE UNIQUE INDEX index_gtfs_feed_info_unique ON gtfs_feed_infos USING btree (feed_version_id);
CREATE INDEX index_gtfs_frequencies_on_feed_version_id ON gtfs_frequencies USING btree (feed_version_id);
CREATE INDEX index_gtfs_frequencies_on_trip_id ON gtfs_frequencies USING btree (trip_id);
CREATE UNIQUE INDEX index_gtfs_levels_unique ON gtfs_levels USING btree (feed_version_id, level_id);
CREATE INDEX index_gtfs_pathways_on_from_stop_id ON gtfs_pathways USING btree (from_stop_id);
CREATE INDEX index_gtfs_pathways_on_level_id ON gtfs_levels USING btree (level_id);
CREATE INDEX index_gtfs_pathways_on_pathway_id ON gtfs_pathways USING btree (pathway_id);
CREATE INDEX index_gtfs_pathways_on_to_stop_id ON gtfs_pathways USING btree (to_stop_id);
CREATE UNIQUE INDEX index_gtfs_pathways_unique ON gtfs_pathways USING btree (feed_version_id, pathway_id);
CREATE INDEX index_gtfs_routes_on_agency_id ON gtfs_routes USING btree (agency_id);
CREATE INDEX index_gtfs_routes_on_feed_version_id_agency_id ON gtfs_routes USING btree (feed_version_id, id, agency_id);
CREATE INDEX index_gtfs_routes_on_route_desc ON gtfs_routes USING btree (route_desc);
CREATE INDEX index_gtfs_routes_on_route_id ON gtfs_routes USING btree (route_id);
CREATE INDEX index_gtfs_routes_on_route_long_name ON gtfs_routes USING btree (route_long_name);
CREATE INDEX index_gtfs_routes_on_route_short_name ON gtfs_routes USING btree (route_short_name);
CREATE INDEX index_gtfs_routes_on_route_type ON gtfs_routes USING btree (route_type);
CREATE UNIQUE INDEX index_gtfs_routes_unique ON gtfs_routes USING btree (feed_version_id, route_id);
CREATE INDEX index_gtfs_shapes_on_generated ON gtfs_shapes USING btree (generated);
CREATE INDEX index_gtfs_shapes_on_geometry ON gtfs_shapes USING gist (geometry);
CREATE INDEX index_gtfs_shapes_on_shape_id ON gtfs_shapes USING btree (shape_id);
CREATE UNIQUE INDEX index_gtfs_shapes_unique ON gtfs_shapes USING btree (feed_version_id, shape_id);
CREATE INDEX index_gtfs_stop_times_on_feed_version_id_trip_id_stop_id ON gtfs_stop_times USING btree (feed_version_id, trip_id, stop_id);
CREATE INDEX index_gtfs_stop_times_on_stop_id ON gtfs_stop_times USING btree (stop_id);
CREATE INDEX index_gtfs_stop_times_on_trip_id ON gtfs_stop_times USING btree (trip_id);
CREATE UNIQUE INDEX index_gtfs_stop_times_unique ON gtfs_stop_times USING btree (feed_version_id, trip_id, stop_sequence);
CREATE INDEX index_gtfs_stops_on_geometry ON gtfs_stops USING gist (geometry);
CREATE INDEX index_gtfs_stops_on_location_type ON gtfs_stops USING btree (location_type);
CREATE INDEX index_gtfs_stops_on_parent_station ON gtfs_stops USING btree (parent_station);
CREATE INDEX index_gtfs_stops_on_stop_code ON gtfs_stops USING btree (stop_code);
CREATE INDEX index_gtfs_stops_on_stop_desc ON gtfs_stops USING btree (stop_desc);
CREATE INDEX index_gtfs_stops_on_stop_id ON gtfs_stops USING btree (stop_id);
CREATE INDEX index_gtfs_stops_on_stop_name ON gtfs_stops USING btree (stop_name);
CREATE UNIQUE INDEX index_gtfs_stops_unique ON gtfs_stops USING btree (feed_version_id, stop_id);
CREATE INDEX index_gtfs_transfers_on_feed_version_id ON gtfs_transfers USING btree (feed_version_id);
CREATE INDEX index_gtfs_transfers_on_from_stop_id ON gtfs_transfers USING btree (from_stop_id);
CREATE INDEX index_gtfs_transfers_on_to_stop_id ON gtfs_transfers USING btree (to_stop_id);
CREATE INDEX index_gtfs_trips_on_route_id ON gtfs_trips USING btree (route_id);
CREATE INDEX index_gtfs_trips_on_service_id ON gtfs_trips USING btree (service_id);
CREATE INDEX index_gtfs_trips_on_shape_id ON gtfs_trips USING btree (shape_id);
CREATE INDEX index_gtfs_trips_on_trip_headsign ON gtfs_trips USING btree (trip_headsign);
CREATE INDEX index_gtfs_trips_on_trip_id ON gtfs_trips USING btree (trip_id);
CREATE INDEX index_gtfs_trips_on_trip_short_name ON gtfs_trips USING btree (trip_short_name);
CREATE UNIQUE INDEX index_gtfs_trips_unique ON gtfs_trips USING btree (feed_version_id, trip_id);
CREATE INDEX index_old_feeds_on_active_feed_version_id ON old_feeds USING btree (active_feed_version_id);
CREATE INDEX index_old_feeds_on_created_or_updated_in_changeset_id ON old_feeds USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_old_feeds_on_current_id ON old_feeds USING btree (current_id);
CREATE INDEX index_old_feeds_on_destroyed_in_changeset_id ON old_feeds USING btree (destroyed_in_changeset_id);
CREATE INDEX index_old_feeds_on_geometry ON old_feeds USING gist (geometry);
CREATE INDEX index_old_operators_in_feed_on_current_id ON old_operators_in_feed USING btree (current_id);
CREATE INDEX index_old_operators_in_feed_on_destroyed_in_changeset_id ON old_operators_in_feed USING btree (destroyed_in_changeset_id);
CREATE INDEX index_old_operators_in_feed_on_feed_type_and_feed_id ON old_operators_in_feed USING btree (feed_type, feed_id);
CREATE INDEX index_old_operators_in_feed_on_operator_type_and_operator_id ON old_operators_in_feed USING btree (operator_type, operator_id);
CREATE INDEX index_old_operators_on_current_id ON old_operators USING btree (current_id);
CREATE INDEX index_old_operators_on_geometry ON old_operators USING gist (geometry);
CREATE INDEX index_old_operators_serving_stop_on_current_id ON old_operators_serving_stop USING btree (current_id);
CREATE INDEX index_old_route_stop_patterns_on_current_id ON old_route_stop_patterns USING btree (current_id);
CREATE INDEX index_old_route_stop_patterns_on_onestop_id ON old_route_stop_patterns USING btree (onestop_id);
CREATE INDEX index_old_route_stop_patterns_on_route_type_and_route_id ON old_route_stop_patterns USING btree (route_type, route_id);
CREATE INDEX index_old_route_stop_patterns_on_stop_pattern ON old_route_stop_patterns USING gin (stop_pattern);
CREATE INDEX index_old_routes_on_bikes_allowed ON old_routes USING btree (bikes_allowed);
CREATE INDEX index_old_routes_on_current_id ON old_routes USING btree (current_id);
CREATE INDEX index_old_routes_on_geometry ON old_routes USING gist (geometry);
CREATE INDEX index_old_routes_on_operator_type_and_operator_id ON old_routes USING btree (operator_type, operator_id);
CREATE INDEX index_old_routes_on_vehicle_type ON old_routes USING btree (vehicle_type);
CREATE INDEX index_old_routes_on_wheelchair_accessible ON old_routes USING btree (wheelchair_accessible);
CREATE INDEX index_old_routes_serving_stop_on_current_id ON old_routes_serving_stop USING btree (current_id);
CREATE INDEX index_old_routes_serving_stop_on_route_type_and_route_id ON old_routes_serving_stop USING btree (route_type, route_id);
CREATE INDEX index_old_routes_serving_stop_on_stop_type_and_stop_id ON old_routes_serving_stop USING btree (stop_type, stop_id);
CREATE INDEX index_old_schedule_stop_pairs_on_current_id ON old_schedule_stop_pairs USING btree (current_id);
CREATE INDEX index_old_schedule_stop_pairs_on_feed_id ON old_schedule_stop_pairs USING btree (feed_id);
CREATE INDEX index_old_schedule_stop_pairs_on_feed_version_id ON old_schedule_stop_pairs USING btree (feed_version_id);
CREATE INDEX index_old_schedule_stop_pairs_on_frequency_type ON old_schedule_stop_pairs USING btree (frequency_type);
CREATE INDEX index_old_schedule_stop_pairs_on_operator_id ON old_schedule_stop_pairs USING btree (operator_id);
CREATE INDEX index_old_schedule_stop_pairs_on_route_stop_pattern_id ON old_schedule_stop_pairs USING btree (route_stop_pattern_id);
CREATE INDEX index_old_stop_transfers_changeset_id ON old_stop_transfers USING btree (created_or_updated_in_changeset_id);
CREATE INDEX index_old_stop_transfers_on_current_id ON old_stop_transfers USING btree (current_id);
CREATE INDEX index_old_stop_transfers_on_destroyed_in_changeset_id ON old_stop_transfers USING btree (destroyed_in_changeset_id);
CREATE INDEX index_old_stop_transfers_on_min_transfer_time ON old_stop_transfers USING btree (min_transfer_time);
CREATE INDEX index_old_stop_transfers_on_stop_id ON old_stop_transfers USING btree (stop_id);
CREATE INDEX index_old_stop_transfers_on_to_stop_id ON old_stop_transfers USING btree (to_stop_id);
CREATE INDEX index_old_stop_transfers_on_transfer_type ON old_stop_transfers USING btree (transfer_type);
CREATE INDEX index_old_stops_on_current_id ON old_stops USING btree (current_id);
CREATE INDEX index_old_stops_on_geometry ON old_stops USING gist (geometry);
CREATE INDEX index_old_stops_on_geometry_reversegeo ON old_stops USING gist (geometry_reversegeo);
CREATE INDEX index_old_stops_on_parent_stop_id ON old_stops USING btree (parent_stop_id);
CREATE INDEX index_old_stops_on_wheelchair_boarding ON old_stops USING btree (wheelchair_boarding);
CREATE INDEX index_route_geometries_on_centroid ON route_geometries USING gist (centroid);
CREATE INDEX index_route_geometries_on_feed_version_id ON route_geometries USING btree (feed_version_id);
CREATE INDEX index_route_geometries_on_geometry ON route_geometries USING gist (geometry);
CREATE INDEX index_route_geometries_on_shape_id ON route_geometries USING btree (shape_id);
CREATE UNIQUE INDEX index_route_geometries_unique ON route_geometries USING btree (route_id, direction_id);
CREATE INDEX index_route_stops_on_agency_id ON route_stops USING btree (agency_id);
CREATE INDEX index_route_stops_on_feed_version_id ON route_stops USING btree (feed_version_id);
CREATE INDEX index_route_stops_on_route_id ON route_stops USING btree (route_id);
CREATE INDEX index_route_stops_on_stop_id ON route_stops USING btree (stop_id);
CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);
CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);
CREATE INDEX o_operators_cu_in_changeset_id_index ON old_operators USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_operators_serving_stop_cu_in_changeset_id_index ON old_operators_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_route_cu_in_changeset ON old_routes USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_route_d_in_changeset ON old_routes USING btree (destroyed_in_changeset_id);
CREATE INDEX o_rsp_cu_in_changeset ON old_route_stop_patterns USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_rss_cu_in_changeset ON old_routes_serving_stop USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_rss_d_in_changeset ON old_routes_serving_stop USING btree (destroyed_in_changeset_id);
CREATE INDEX o_ssp_cu_in_changeset ON old_schedule_stop_pairs USING btree (created_or_updated_in_changeset_id);
CREATE INDEX o_ssp_d_in_changeset ON old_schedule_stop_pairs USING btree (destroyed_in_changeset_id);
CREATE INDEX o_ssp_destination ON old_schedule_stop_pairs USING btree (destination_type, destination_id);
CREATE INDEX o_ssp_origin ON old_schedule_stop_pairs USING btree (origin_type, origin_id);
CREATE INDEX o_ssp_route ON old_schedule_stop_pairs USING btree (route_type, route_id);
CREATE INDEX o_ssp_service_end_date ON old_schedule_stop_pairs USING btree (service_end_date);
CREATE INDEX o_ssp_service_start_date ON old_schedule_stop_pairs USING btree (service_start_date);
CREATE INDEX o_ssp_trip ON old_schedule_stop_pairs USING btree (trip);
CREATE INDEX o_stops_cu_in_changeset_id_index ON old_stops USING btree (created_or_updated_in_changeset_id);
CREATE INDEX old_oif ON old_operators_in_feed USING btree (created_or_updated_in_changeset_id);
CREATE INDEX operators_d_in_changeset_id_index ON old_operators USING btree (destroyed_in_changeset_id);
CREATE INDEX operators_serving_stop_d_in_changeset_id_index ON old_operators_serving_stop USING btree (destroyed_in_changeset_id);
CREATE INDEX operators_serving_stop_operator ON old_operators_serving_stop USING btree (operator_type, operator_id);
CREATE INDEX operators_serving_stop_stop ON old_operators_serving_stop USING btree (stop_type, stop_id);
CREATE INDEX route_headways_feed_version_id_idx ON route_headways USING btree (feed_version_id);
CREATE UNIQUE INDEX route_headways_route_id_idx ON route_headways USING btree (route_id);
CREATE INDEX stops_d_in_changeset_id_index ON old_stops USING btree (destroyed_in_changeset_id);
ALTER TABLE ONLY gtfs_trips
    ADD CONSTRAINT fk_rails_05ead08753 FOREIGN KEY (shape_id) REFERENCES gtfs_shapes(id);
ALTER TABLE ONLY route_headways
    ADD CONSTRAINT fk_rails_078ffc5894 FOREIGN KEY (service_id) REFERENCES gtfs_calendars(id);
ALTER TABLE ONLY gtfs_transfers
    ADD CONSTRAINT fk_rails_0cc6ff288a FOREIGN KEY (from_stop_id) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY route_headways
    ADD CONSTRAINT fk_rails_19cb5c8c5c FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY agency_geometries
    ADD CONSTRAINT fk_rails_1bfa787783 FOREIGN KEY (agency_id) REFERENCES gtfs_agencies(id);
ALTER TABLE ONLY route_stops
    ADD CONSTRAINT fk_rails_1dee96ee31 FOREIGN KEY (agency_id) REFERENCES gtfs_agencies(id);
ALTER TABLE ONLY route_stops
    ADD CONSTRAINT fk_rails_1f4cc828f8 FOREIGN KEY (route_id) REFERENCES gtfs_routes(id);
ALTER TABLE ONLY gtfs_stop_times
    ADD CONSTRAINT fk_rails_22a671077b FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY feed_version_gtfs_imports
    ADD CONSTRAINT fk_rails_2d141782c9 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_stop_times
    ADD CONSTRAINT fk_rails_30ced0baa8 FOREIGN KEY (stop_id) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY gtfs_fare_rules
    ADD CONSTRAINT fk_rails_33e9869c97 FOREIGN KEY (route_id) REFERENCES gtfs_routes(id);
ALTER TABLE ONLY gtfs_stops
    ADD CONSTRAINT fk_rails_3a83952954 FOREIGN KEY (parent_station) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY change_payloads
    ADD CONSTRAINT fk_rails_3f6887766c FOREIGN KEY (changeset_id) REFERENCES changesets(id);
ALTER TABLE ONLY gtfs_calendars
    ADD CONSTRAINT fk_rails_42538db9b2 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_trips
    ADD CONSTRAINT fk_rails_5093550f50 FOREIGN KEY (route_id) REFERENCES gtfs_routes(id);
ALTER TABLE ONLY feed_states
    ADD CONSTRAINT fk_rails_5189447149 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_frequencies
    ADD CONSTRAINT fk_rails_6e6295037f FOREIGN KEY (trip_id) REFERENCES gtfs_trips(id);
ALTER TABLE ONLY route_geometries
    ADD CONSTRAINT fk_rails_71ddc895e1 FOREIGN KEY (route_id) REFERENCES gtfs_routes(id);
ALTER TABLE ONLY agency_places
    ADD CONSTRAINT fk_rails_736d85abf8 FOREIGN KEY (agency_id) REFERENCES gtfs_agencies(id);
ALTER TABLE ONLY agency_places
    ADD CONSTRAINT fk_rails_782a6056d8 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_calendar_dates
    ADD CONSTRAINT fk_rails_7a365f570b FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY feed_version_geometries
    ADD CONSTRAINT fk_rails_8398615a04 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_shapes
    ADD CONSTRAINT fk_rails_84a74e83d8 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_stops
    ADD CONSTRAINT fk_rails_860ffa5a40 FOREIGN KEY (level_id) REFERENCES gtfs_levels(id);
ALTER TABLE ONLY route_stops
    ADD CONSTRAINT fk_rails_86271126ad FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY agency_geometries
    ADD CONSTRAINT fk_rails_8a1bd61db9 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_fare_attributes
    ADD CONSTRAINT fk_rails_8a3ca847de FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_pathways
    ADD CONSTRAINT fk_rails_8d7bf46256 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY route_headways
    ADD CONSTRAINT fk_rails_93324ef20d FOREIGN KEY (selected_stop_id) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY feed_states
    ADD CONSTRAINT fk_rails_99eaedcf98 FOREIGN KEY (feed_id) REFERENCES current_feeds(id);
ALTER TABLE ONLY route_headways
    ADD CONSTRAINT fk_rails_9a487f871b FOREIGN KEY (route_id) REFERENCES gtfs_routes(id);
ALTER TABLE ONLY gtfs_transfers
    ADD CONSTRAINT fk_rails_a030c4a2a9 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_routes
    ADD CONSTRAINT fk_rails_a5ff5a2ceb FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_pathways
    ADD CONSTRAINT fk_rails_a668e1e0ac FOREIGN KEY (to_stop_id) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY gtfs_agencies
    ADD CONSTRAINT fk_rails_a7e0c4685b FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_trips
    ADD CONSTRAINT fk_rails_a839da033a FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_fare_attributes
    ADD CONSTRAINT fk_rails_b096f74e03 FOREIGN KEY (agency_id) REFERENCES gtfs_agencies(id);
ALTER TABLE ONLY feed_versions
    ADD CONSTRAINT fk_rails_b5365c3cf3 FOREIGN KEY (feed_id) REFERENCES current_feeds(id);
ALTER TABLE ONLY gtfs_stop_times
    ADD CONSTRAINT fk_rails_b5a47190ac FOREIGN KEY (trip_id) REFERENCES gtfs_trips(id);
ALTER TABLE ONLY route_geometries
    ADD CONSTRAINT fk_rails_b9fc0ae4ad FOREIGN KEY (shape_id) REFERENCES gtfs_shapes(id);
ALTER TABLE ONLY gtfs_fare_rules
    ADD CONSTRAINT fk_rails_bd7d178423 FOREIGN KEY (fare_id) REFERENCES gtfs_fare_attributes(id);
ALTER TABLE ONLY gtfs_fare_rules
    ADD CONSTRAINT fk_rails_c336ea9f1a FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_levels
    ADD CONSTRAINT fk_rails_c5fba46e47 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY route_geometries
    ADD CONSTRAINT fk_rails_c858a218e2 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_calendar_dates
    ADD CONSTRAINT fk_rails_ca504bc01f FOREIGN KEY (service_id) REFERENCES gtfs_calendars(id);
ALTER TABLE ONLY route_stops
    ADD CONSTRAINT fk_rails_cc9fde6bb7 FOREIGN KEY (stop_id) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY gtfs_stops
    ADD CONSTRAINT fk_rails_cf4bc79180 FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_frequencies
    ADD CONSTRAINT fk_rails_d1b468024b FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
ALTER TABLE ONLY gtfs_trips
    ADD CONSTRAINT fk_rails_d2c6f99d5e FOREIGN KEY (service_id) REFERENCES gtfs_calendars(id);
ALTER TABLE ONLY gtfs_pathways
    ADD CONSTRAINT fk_rails_df846a6b54 FOREIGN KEY (from_stop_id) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY gtfs_transfers
    ADD CONSTRAINT fk_rails_e1c56f7da4 FOREIGN KEY (to_stop_id) REFERENCES gtfs_stops(id);
ALTER TABLE ONLY gtfs_routes
    ADD CONSTRAINT fk_rails_e5eb0f1573 FOREIGN KEY (agency_id) REFERENCES gtfs_agencies(id);
ALTER TABLE ONLY gtfs_feed_infos
    ADD CONSTRAINT fk_rails_eb863abbac FOREIGN KEY (feed_version_id) REFERENCES feed_versions(id);
