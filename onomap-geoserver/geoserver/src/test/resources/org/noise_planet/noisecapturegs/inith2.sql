DROP TABLE IF EXISTS NOISECAPTURE_FREQ, NOISECAPTURE_POINT, NOISECAPTURE_TRACK, NOISECAPTURE_USER,
  NOISECAPTURE_TAG, NOISECAPTURE_TRACK_TAG, NOISECAPTURE_AREA, NOISECAPTURE_PROCESS_QUEUE,
  NOISECAPTURE_AREA_PROFILE, NOISECAPTURE_AREA_CLUSTER, NOISECAPTURE_PARTY, NOISECAPTURE_STATS_LAST_TRACKS;

 -- H2 Only
 CREATE DOMAIN IF NOT EXISTS TIMESTAMPTZ AS TIMESTAMP;

-- tables

-- Table: NOISECAPTURE_USER
CREATE TABLE NOISECAPTURE_USER (
    PK_USER serial  NOT NULL,
    USER_UUID char(36)  NOT NULL,
    PSEUDO text,
    DATE_CREATION date  NOT NULL,
    PROFILE varchar default '',
    CONSTRAINT NOISECAPTURE_USER_PK PRIMARY KEY (PK_USER)
);

COMMENT ON COLUMN NOISECAPTURE_USER.PROFILE IS 'User acoustic knowledge, one of NONE, NOVICE, EXPERT';

-- Table: NOISECAPTURE_PARTY
CREATE TABLE NOISECAPTURE_PARTY (
    PK_PARTY serial NOT NULL,
    THE_GEOM geometry NOT NULL,
    LAYER_NAME varchar UNIQUE NOT NULL,
    TITLE varchar NOT NULL,
    TAG varchar NOT NULL,
    DESCRIPTION varchar NOT NULL,
    START_TIME TIMESTAMPTZ,
    END_TIME TIMESTAMPTZ,
    FILTER_TIME boolean NOT NULL default false,
    FILTER_AREA boolean NOT NULL default false,
    CONSTRAINT NOISECAPTURE_PARTY_PK PRIMARY KEY (PK_PARTY)
);

COMMENT ON COLUMN NOISECAPTURE_PARTY.title IS 'Short NoiseParty title';
COMMENT ON COLUMN NOISECAPTURE_PARTY.description IS 'Long description of the NoiseParty';
COMMENT ON COLUMN NOISECAPTURE_PARTY.tag IS 'Tag typed by users';
COMMENT ON COLUMN NOISECAPTURE_PARTY.the_geom IS 'NoiseParty location';
COMMENT ON COLUMN NOISECAPTURE_PARTY.layer_name IS 'Layer name in leaflet url, must be unique';
COMMENT ON COLUMN NOISECAPTURE_PARTY.filter_time IS 'If enabled, reject track with time out of start_time end_time range';
COMMENT ON COLUMN NOISECAPTURE_PARTY.filter_area IS 'If enabled, reject track that does not intersects with the_geom';

-- Table: NOISECAPTURE_TRACK
CREATE TABLE NOISECAPTURE_TRACK (
    PK_TRACK serial  NOT NULL,
    PK_USER int  NOT NULL REFERENCES noisecapture_user (PK_USER) ON UPDATE CASCADE ON DELETE CASCADE,
    TRACK_UUID char(36)  NOT NULL,
	VERSION_NUMBER int NOT NULL,
	RECORD_UTC timestamptz NOT NULL,
	PLEASANTNESS float,
	DEVICE_PRODUCT text  NOT NULL,
	DEVICE_MODEL text NOT NULL,
	DEVICE_MANUFACTURER text NOT NULL,
	NOISE_LEVEL float NOT NULL,
	TIME_LENGTH float NOT NULL,
	GAIN_CALIBRATION float NOT NULL DEFAULT 0,
	CALIBRATION_METHOD text NOT NULL DEFAULT 'None',
	PK_PARTY int REFERENCES noisecapture_party (PK_PARTY) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT NOISECAPTURE_TRACK_PK PRIMARY KEY (PK_TRACK)
);

COMMENT ON COLUMN NOISECAPTURE_TRACK.NOISE_LEVEL IS 'Sound level in dB(A)';
COMMENT ON COLUMN NOISECAPTURE_TRACK.VERSION_NUMBER IS 'Application version identifier';
COMMENT ON COLUMN NOISECAPTURE_TRACK.PLEASANTNESS IS 'PLEASANTNESS ratio, from 0 to 100';
COMMENT ON COLUMN NOISECAPTURE_TRACK.GAIN_CALIBRATION IS 'Signal gain in dB, provided from user using phone calibration';
COMMENT ON COLUMN NOISECAPTURE_TRACK.TIME_LENGTH IS 'Length of measurement in seconds';

-- Table: NOISECAPTURE_POINT
CREATE TABLE NOISECAPTURE_POINT (
    PK_POINT serial NOT NULL,
    THE_GEOM geometry,
    PK_TRACK int NOT NULL REFERENCES noisecapture_track (pk_track) ON UPDATE CASCADE ON DELETE CASCADE,
    NOISE_LEVEL float  NOT NULL,
    SPEED float,
    ACCURACY float  NOT NULL,
    ORIENTATION float,
    TIME_DATE timestamptz  NOT NULL,
    TIME_LOCATION timestamptz,
    CONSTRAINT NOISECAPTURE_POINT_PK PRIMARY KEY (PK_POINT)
);

COMMENT ON COLUMN NOISECAPTURE_POINT.ORIENTATION IS 'Device movement bearing, may be null';
COMMENT ON COLUMN NOISECAPTURE_POINT.TIME_LOCATION IS 'Time of acquisition of the localisation';
COMMENT ON COLUMN NOISECAPTURE_POINT.TIME_DATE IS 'Time of the noise level measurement';
COMMENT ON COLUMN NOISECAPTURE_POINT.SPEED IS 'Device speed in m/s. May be null';
COMMENT ON COLUMN NOISECAPTURE_POINT.ACCURACY IS 'Estimated location accuracy in meter';
COMMENT ON COLUMN NOISECAPTURE_POINT.NOISE_LEVEL IS 'Sound level in dB(A)';


-- Table: NOISECAPTURE_FREQ
CREATE TABLE NOISECAPTURE_FREQ (
    PK_POINT int  NOT NULL REFERENCES noisecapture_point (pk_point) ON DELETE CASCADE ON UPDATE CASCADE,
    FREQUENCY smallint  NOT NULL,
    NOISE_LEVEL float NOT NULL   ,
    CONSTRAINT NOISECAPTURE_FREQ_PK PRIMARY KEY (PK_POINT, FREQUENCY)
);

COMMENT ON COLUMN NOISECAPTURE_FREQ.FREQUENCY IS 'Frequency Hz';
COMMENT ON COLUMN NOISECAPTURE_FREQ.NOISE_LEVEL IS 'Sound level in dB(A)';

CREATE TABLE NOISECAPTURE_TAG (
    PK_TAG serial  NOT NULL REFERENCES NOISECAPTURE_TAG (PK_TAG) ON DELETE CASCADE ON UPDATE CASCADE,
    TAG_NAME text NOT NULL
);

CREATE TABLE NOISECAPTURE_TRACK_TAG (
    PK_TRACK int NOT NULL REFERENCES NOISECAPTURE_TRACK (PK_TRACK) ON DELETE CASCADE ON UPDATE CASCADE,
    PK_TAG int NOT NULL REFERENCES NOISECAPTURE_TAG (PK_TAG) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT NOISECAPTURE_TRACK_TAG_PK PRIMARY KEY (PK_TRACK, PK_TAG)
);

-- Table: NOISECAPTURE_PROCESS_QUEUE, tracks inserted but not processed for community map
CREATE TABLE NOISECAPTURE_PROCESS_QUEUE (
    PK_TRACK int PRIMARY KEY REFERENCES noisecapture_track (pk_track) ON DELETE CASCADE ON UPDATE CASCADE
);

COMMENT ON COLUMN NOISECAPTURE_PROCESS_QUEUE.PK_TRACK IS 'Update area that contains this track';

-- Table: NOISECAPTURE_AREA_CLUSTER, Variable size hexagons that contains only the measurement count
CREATE TABLE NOISECAPTURE_AREA_CLUSTER (
    CELL_LEVEL smallint NOT NULL,
    CELL_Q bigint NOT NULL,
    CELL_R bigint NOT NULL,
    THE_GEOM geometry NOT NULL,
    MEASURE_COUNT int NOT NULL,
    CONSTRAINT NOISECAPTURE_AREA_CLUSTER_PK PRIMARY KEY (CELL_LEVEL, CELL_Q, CELL_R)
);

COMMENT ON COLUMN NOISECAPTURE_AREA_CLUSTER.CELL_LEVEL IS 'Hexagonal size exponent 3^n';
COMMENT ON COLUMN NOISECAPTURE_AREA_CLUSTER.CELL_Q IS 'Hexagonal index Q';
COMMENT ON COLUMN NOISECAPTURE_AREA_CLUSTER.CELL_R IS 'Hexagonal index R';
COMMENT ON COLUMN NOISECAPTURE_AREA_CLUSTER.THE_GEOM IS 'Area shape';
COMMENT ON COLUMN NOISECAPTURE_AREA_CLUSTER.MEASURE_COUNT IS 'noisecapture_point entities in this area';

-- Table: NOISECAPTURE_AREA, Post-processed results, merge of measurements in a regular area
CREATE TABLE NOISECAPTURE_AREA (
    PK_AREA serial  NOT NULL,
    CELL_Q bigint NOT NULL,
    CELL_R bigint NOT NULL,
    TZID VARCHAR(255) NOT NULL,
    THE_GEOM geometry NOT NULL,
    LAEQ float NOT NULL,
    LA50 float NOT NULL,
    LDEN float NOT NULL,
	MEAN_PLEASANTNESS float,
    MEASURE_COUNT int NOT NULL,
    FIRST_MEASURE timestamptz NOT NULL,
    LAST_MEASURE timestamptz NOT NULL,
    PK_PARTY int REFERENCES noisecapture_party (PK_PARTY) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT NOISECAPTURE_AREA_PK PRIMARY KEY (PK_AREA)
);

COMMENT ON COLUMN NOISECAPTURE_AREA.CELL_Q IS 'Hexagonal index Q';
COMMENT ON COLUMN NOISECAPTURE_AREA.CELL_R IS 'Hexagonal index R';
COMMENT ON COLUMN NOISECAPTURE_AREA.TZID IS 'TimeZone identifier';
COMMENT ON COLUMN NOISECAPTURE_AREA.THE_GEOM IS 'Area shape';
COMMENT ON COLUMN NOISECAPTURE_AREA.MEASURE_COUNT IS 'noisecapture_point entities in this area';


-- Table: NOISECAPTURE_AREA, Post-processed results, merge of measurements in a regular area
CREATE TABLE NOISECAPTURE_AREA_PROFILE (
    PK_AREA int  NOT NULL,
    HOUR smallint NOT NULL,
    LAEQ real NOT NULL,
    LA50 float NOT NULL,
    UNCERTAINTY smallint DEFAULT 255,
    VARIABILITY real DEFAULT 0,
    CONSTRAINT NOISECAPTURE_AREA_PROFILE_PK PRIMARY KEY (PK_AREA, HOUR),
    CONSTRAINT NOISECAPTURE_AREA_PROFILE_FK FOREIGN KEY (PK_AREA) REFERENCES NOISECAPTURE_AREA (PK_AREA) ON DELETE CASCADE
);

COMMENT ON COLUMN NOISECAPTURE_AREA_PROFILE.HOUR IS 'Hour of estimated value';
COMMENT ON COLUMN NOISECAPTURE_AREA_PROFILE.LAEQ IS 'Laeq on this hour';
COMMENT ON COLUMN NOISECAPTURE_AREA_PROFILE.LA50 IS 'LA50 on this hour';
COMMENT ON COLUMN NOISECAPTURE_AREA_PROFILE.UNCERTAINTY IS 'Uncertainty 0-255';
COMMENT ON COLUMN NOISECAPTURE_AREA_PROFILE.VARIABILITY IS 'Variability in dB(A)';

CREATE TABLE NOISECAPTURE_DUMP_TRACK_ENVELOPE(
    PK_TRACK int NOT NULL REFERENCES NOISECAPTURE_TRACK (PK_TRACK) ON DELETE CASCADE ON UPDATE CASCADE,
    THE_GEOM geometry,
    measure_count bigint);

-- Statistics cache table

CREATE TABLE noisecapture_stats_last_tracks (
    pk_track integer,
    time_length double precision,
    record_utc timestamptz,
    the_geom varchar,
    env varchar,
    start_pt varchar,
    stop_pt varchar,
    name_0 varchar,
    name_1 varchar,
    name_3 varchar,
    pk_party integer
);

--- Add index

CREATE INDEX ki_noisecapture_area_cellq
  ON noisecapture_area(cell_q);
CREATE INDEX ki_noisecapture_area_cellr
  ON noisecapture_area(cell_r);

CREATE INDEX fki_noisecapture_track_pk_user_fk
  ON noisecapture_track(pk_user);

CREATE INDEX fki_noisecapture_point_pk_track_fk
  ON noisecapture_point(pk_track);

CREATE INDEX fki_noisecapture_process_queue_pk_track_fk
  ON noisecapture_process_queue(pk_track);

CREATE INDEX fki_noisecapture_freq_pk_point_fk
  ON noisecapture_freq(pk_point);

-- H2GIS only queries

   CREATE SPATIAL INDEX ON NOISECAPTURE_POINT(THE_GEOM);
   CREATE SPATIAL INDEX ON NOISECAPTURE_AREA(THE_GEOM);
   CREATE SPATIAL INDEX ON NOISECAPTURE_AREA_CLUSTER(THE_GEOM);

 ---- PostGIS only query

 -- CREATE INDEX ON NOISECAPTURE_POINT USING GIST(THE_GEOM);
 -- CREATE INDEX ON NOISECAPTURE_AREA USING GIST(THE_GEOM);
 -- CREATE INDEX ON NOISECAPTURE_AREA_CLUSTER USING GIST(THE_GEOM);

 ---- Force SRID

-- SELECT UpdateGeometrySRID('noisecapture_dump_track_envelope','the_geom',4326);
-- SELECT UpdateGeometrySRID('noisecapture_area','the_geom',4326);
-- SELECT UpdateGeometrySRID('noisecapture_point','the_geom',4326);
-- SELECT UpdateGeometrySRID('noisecapture_area_cluster','the_geom',4326);