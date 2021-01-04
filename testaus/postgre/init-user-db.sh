#!/bin/bash
set -e
test -z "$DB_USER" && echo "Environment variable DB_USER is not defined!" && exit 1
test -z "$DB_PASS" && echo "Environment variable DB_PASS is not defined!" && exit 1
test -z "$DB_NAME" && echo "Environment variable DB_NAME is not defined!" && exit 1

psql --username $POSTGRES_USER --dbname $POSTGRES_DB <<-EOSQL
    CREATE USER $DB_USER WITH LOGIN ENCRYPTED PASSWORD '$DB_PASS';
    CREATE DATABASE $DB_NAME OWNER $DB_USER;
    ALTER DATABASE $DB_NAME SET search_path TO "\$user", public, data;
EOSQL
psql --username $POSTGRES_USER --dbname $DB_NAME <<-EOSQL
    CREATE EXTENSION postgis;

EOSQL
psql --username $DB_USER --dbname $DB_NAME <<-EOSQL
    CREATE TABLE public.metadata(
        id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
        event_date date not null,
        event_desc text not null
    );
EOSQL
test -n "$DB_DUMP" && pg_restore --username $DB_USER --dbname $DB_NAME --format=c --no-owner --role=$DB_USER --verbose $DB_DUMP
test -z "$DB_DUMP" && psql --username $DB_USER --dbname $DB_NAME <<-EOSQL
    CREATE SCHEMA data
        CREATE TABLE feature_collection (
            id VARCHAR(255) PRIMARY KEY,
            created_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            collection JSONB NOT NULL,
            geom geometry
        )
        CREATE TABLE plan_regulation (
            id VARCHAR(255) PRIMARY KEY,
            created_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            properties JSONB NOT NULL,
            geom geometry
        )
        CREATE TABLE plan_regulation_object (
            id VARCHAR(255) PRIMARY KEY,
            created_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            properties JSONB NOT NULL,
            geom geometry NOT NULL
        )
        CREATE TABLE spatial_plan (
            id VARCHAR(255) PRIMARY KEY,
            created_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            properties JSONB NOT NULL,
            geom geometry NOT NULL
        );
EOSQL
psql --username $DB_USER --dbname $DB_NAME <<-EOSQL
    CREATE VIEW public.v_plan_regulation AS
        SELECT
            id,
            created_time AS "_createdTime",
            properties::jsonb->>'identityId' AS "identityId",
            properties::jsonb->>'versionId' AS "versionId",
            properties::jsonb->>'localId' AS "localId",
            properties::jsonb->>'latestChange' AS "latestChange",
            properties::jsonb->'spatialPlan'->>'linkedFeatureType' AS "spatialPlanLinkedFeatureType",
            properties::jsonb->'spatialPlan'->>'linkedFeatureId' AS "spatialPlanLinkedFeatureId",
            properties::jsonb->'spatialPlan'->>'href' AS "spatialPlanHref",
            properties::jsonb->'targetObject'->>'linkedFeatureType' AS "targetObjectLinkedFeatureType",
            properties::jsonb->'targetObject'->>'linkedFeatureId' AS "targetObjectLinkedFeatureId",
            properties::jsonb->'targetObject'->>'href' AS "targetObjectHref",
            properties::jsonb->'type'->> 'code' AS "typeCode",
            properties::jsonb->'type'->'title'->> 'fin' AS "typeTitle",
            properties::jsonb->'themes' AS "themes",
            properties::jsonb->'values' AS "values",
            properties::jsonb->'lifecycleStatus'->>'code' AS "lifecycleStatusCode",
            properties::jsonb->'lifecycleStatus'->'title'->>'fin' AS "lifecycleStatusTitle",
            properties::jsonb->>'validFrom' AS "validFrom",
            geom
        FROM data.plan_regulation;
    CREATE VIEW public.v_plan_regulation_object AS
        SELECT
            id,
            created_time AS "_createdTime",
            properties::jsonb->>'identityId' AS "identityId",
            properties::jsonb->>'versionId' AS "versionId",
            properties::jsonb->>'localId' AS "localId",
            properties::jsonb->>'latestChange' AS "latestChange",
            properties::jsonb->'spatialPlan'->>'linkedFeatureType' AS "spatialPlanLinkedFeatureType",
            properties::jsonb->'spatialPlan'->>'linkedFeatureId' AS "spatialPlanLinkedFeatureId",
            properties::jsonb->'spatialPlan'->>'href' AS "spatialPlanHref",
            properties::jsonb->'verticalLimits' AS "verticalLimits",
            properties::jsonb->'bindingnessOfLocation'->>'code' AS "bindingnessOfLocationCode",
            properties::jsonb->'bindingnessOfLocation'->'title'->>'fin' AS "bindingnessOfLocationTitle",
            properties::jsonb->'undergroundness'->>'code' AS "undergroundnessCode",
            properties::jsonb->'undergroundness'->'title'->>'fin' AS "undergroundnessTitle",
            properties::jsonb->'regulations' AS "regulations",
            properties::jsonb->'lifecycleStatus'->>'code' AS "lifecycleStatusCode",
            properties::jsonb->'lifecycleStatus'->'title'->>'fin' AS "lifecycleStatusTitle",
            properties::jsonb->>'validFrom' AS "validFrom",
            properties::jsonb->'groundRelativePosition'->>'code' AS "groundRelativePositionCode",
            properties::jsonb->'groundRelativePosition'->'title'->>'fin' AS "groundRelativePositionTitle",
            geom
        FROM data.plan_regulation_object;
    CREATE VIEW public.v_spatial_plan AS
        SELECT
            id,
            created_time AS "_createdTime",
            properties::jsonb->>'identityId' AS "identityId",
            properties::jsonb->>'versionId' AS "versionId",
            properties::jsonb->>'localId' AS "localId",
            properties::jsonb->>'latestChange' AS "latestChange",
            properties::jsonb->>'planId' AS "planId",
            properties::jsonb->'planType'->>'code' AS "planTypeCode",
            properties::jsonb->'planType'->'title'->>'fin' AS "planTypeTitle",
            properties::jsonb->'name'->>'fin' AS "name",
            properties::jsonb->'description'->>'fin' AS "description",
            properties::jsonb->'planObjects' AS "planObjects",
            properties::jsonb->'generalRegulations' AS "generalRegulations",
            properties::jsonb->'administrativeAreaIds' AS "administrativeAreaIds",
            properties::jsonb->'legalEffectiveness'->>'code' AS "legalEffectivenessCode",
            properties::jsonb->'legalEffectiveness'->'title'->>'fin' AS "legalEffectivenessTitle",
            properties::jsonb->'usedInputDatasets' AS "usedInputDatasets",
            properties::jsonb->'responsibleOrganisation'->>'linkedFeatureType' AS "responsibleOrganisationLinkedFeatureType",
            properties::jsonb->'responsibleOrganisation'->>'linkedFeatureId' AS "responsibleOrganisationLinkedFeatureId",
            properties::jsonb->'responsibleOrganisation'->>'href' AS "responsibleOrganisationHref",
            properties::jsonb->'responsibleOrganisation'->'title'->>'fin' AS "responsibleOrganisationTitle",
            properties::jsonb->'undergroundness'->>'code' AS "undergroundnessCode",
            properties::jsonb->'undergroundness'->'title'->>'fin' AS "undergroundnessTitle",
            properties::jsonb->'planners' AS "planners",
            properties::jsonb->'planCommentary'->>'linkedFeatureType' AS "planCommentaryLinkedFeatureType",
            properties::jsonb->'planCommentary'->>'linkedFeatureId' AS "planCommentaryLinkedFeatureId",
            properties::jsonb->'planCommentary'->>'href' AS "planCommentaryHref",
            properties::jsonb->'attachments' AS "attachments",
            properties::jsonb->'cancellations' AS "cancellations",
            properties::jsonb->'lifecycleStatus'->>'code' AS "lifecycleStatusCode",
            properties::jsonb->'lifecycleStatus'->'title'->>'fin' AS "lifecycleStatusTitle",
            properties::jsonb->'digitalOrigin'->>'code' AS "digitalOriginCode",
            properties::jsonb->'digitalOrigin'->'title'->>'fin' AS "digitalOriginTitle",
            properties::jsonb->>'metadata' AS "metadata",
            properties::jsonb->>'initiationTime' AS "initiationTime",
            properties::jsonb->>'approvalTime' AS "approvalTime",
            properties::jsonb->>'validFrom' AS "validFrom",
            geom
        FROM data.spatial_plan;
    INSERT INTO public.metadata(event_date, event_desc) VALUES(NOW(),'Database restore done!');
EOSQL