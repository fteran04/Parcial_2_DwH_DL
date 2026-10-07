-- Insumo 1: Script DDL del Data Mart dwh_player_performance
-- Ejecutar dentro de la base de datos dwh_sports:
--   sudo -u postgres psql
--   \c dwh_sports
--   \i /var/lib/postgresql/ddl_dwh_player_performance.sql

-- Creación de la dimensión de Eventos
CREATE TABLE dim_events (
    id integer NOT NULL,
    event_key varchar(100) NOT NULL,
    event_status varchar(50),
    start_date timestamp,
    PRIMARY KEY (id)
);

-- Creación de la dimensión de Posiciones
CREATE TABLE dim_positions (
    id integer NOT NULL,
    abbreviation varchar(50) NOT NULL,
    PRIMARY KEY (id)
);

-- Creación de la dimensión de Personas enriquecida (SCD / Multifuente)
CREATE TABLE dim_persons_performance (
    id integer NOT NULL,
    entity_id integer NOT NULL,
    first_name varchar(50) NOT NULL DEFAULT 'N/A',
    last_name varchar(50) NOT NULL DEFAULT 'N/A',
    gender varchar(10),
    email varchar(100), -- Dato proveniente de CSV externo 1
    membership_level varchar(50), -- Dato proveniente de CSV externo 2
    version integer DEFAULT 1,
    date_from timestamp,
    date_to timestamp,
    PRIMARY KEY (id)
);

CREATE INDEX idx_dim_persons_perf_entity ON dim_persons_performance(entity_id);

-- Creación de la Tabla de Hechos: Rendimiento de Participantes en Eventos
CREATE TABLE ft_player_performance (
    dateid integer NOT NULL,
    id_event integer NOT NULL,
    id_person integer NOT NULL,
    id_position integer NOT NULL,
    score_numeric numeric(10,2) DEFAULT 0.00,
    rank integer DEFAULT 0,
    PRIMARY KEY (dateid, id_event, id_person)
);
