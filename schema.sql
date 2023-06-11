CREATE EXTENSION IF NOT EXISTS postgis;

DROP TABLE IF EXISTS sa2_regions CASCADE;
DROP TABLE IF EXISTS businesses;
DROP TABLE IF EXISTS income;
DROP TABLE IF EXISTS population;
DROP TABLE IF EXISTS births;
DROP TABLE IF EXISTS crime;
DROP TABLE IF EXISTS polling_places;
DROP TABLE IF EXISTS stops;
DROP TABLE IF EXISTS schools;

-- Schema for the 'sa2_regions' DataFrame
CREATE TABLE sa2_regions (
  "SA2_CODE21" INT PRIMARY KEY,
  "SA2_NAME21" VARCHAR(255),
  "CHG_FLAG21" VARCHAR(255),
  "CHG_LBL21" VARCHAR(255),
  "SA3_CODE21" INT,
  "SA3_NAME21" VARCHAR(255),
  "SA4_CODE21" INT,
  "SA4_NAME21" VARCHAR(255),
  "AREASQKM21" FLOAT,
  "geom" GEOMETRY(MULTIPOLYGON, 4326)
);

-- Schema for the 'crime' DataFrame
CREATE TABLE crime (
    "objectid" INT PRIMARY KEY,
    "contour" FLOAT,
    "density" VARCHAR(255),
    "shape_leng" NUMERIC,
    "shape_area" NUMERIC,
    "geom" GEOMETRY(MULTIPOLYGON, 4326)
);

-- Schema for the 'births' DataFrame
CREATE TABLE births (
    "id" INTEGER PRIMARY KEY,
    "sa2_code" INT REFERENCES sa2_regions("SA2_CODE21"),
    "sa2_name" VARCHAR(255),
    "births_no" INTEGER,
    "total_fertility_rate" FLOAT,
    "geom" GEOMETRY(MULTIPOLYGON, 4326)
);

-- Schema for the 'businesses' DataFrame
CREATE TABLE businesses (
  "business_id" INT PRIMARY KEY,
  "industry_code" VARCHAR(255),
  "industry_name" VARCHAR(255),
  "sa2_code" INT REFERENCES sa2_regions("SA2_CODE21"),
  "sa2_name" VARCHAR(255),
  "total_businesses" INT
);

-- Schema for the 'income' DataFrame
CREATE TABLE income (
  "income_id" INT PRIMARY KEY,
  "sa2_code" INT REFERENCES sa2_regions("SA2_CODE21"),
  "sa2_name" VARCHAR(255),
  "earners" INT,
  "median_age" FLOAT,
  "median_income" FLOAT,
  "mean_income" FLOAT
);

-- Schema for the 'polling_places' DataFrame
CREATE TABLE polling_places (
  "FID" VARCHAR(255) PRIMARY KEY,
  "division_id" INT,
  "division_name" VARCHAR(255),
  "polling_place_id" INT,
  "polling_place_type_id" INT,
  "polling_place_name" VARCHAR(255),
  "premises_name" VARCHAR(255),
  "premises_address_1" VARCHAR(255),
  "premises_address_2" VARCHAR(255),
  "premises_address_3" VARCHAR(255),
  "premises_suburb" VARCHAR(255),
  "premises_state_abbreviation" VARCHAR(255),
  "premises_post_code" INT,
  "geom" GEOMETRY(POINT, 4326)
);

-- Schema for the 'population' DataFrame
CREATE TABLE population (
  "population_id" INT PRIMARY KEY,
  "sa2_code" INT REFERENCES sa2_regions("SA2_CODE21"),
  "sa2_name" VARCHAR(255),
  "young_people" INT,
  "total_people" INT
);

-- Schema for the 'stops' DataFrame
CREATE TABLE stops (
  "stop_id" VARCHAR(255) PRIMARY KEY,
  "stop_code" VARCHAR(255),
  "stop_name" VARCHAR(255),
  "location_type" VARCHAR(255),
  "parent_station" VARCHAR(255),
  "wheelchair_boarding" VARCHAR(255),
  "platform_code" VARCHAR(255),
  "geom" GEOMETRY(POINT, 4326)
);

-- Schema for the 'schools' DataFrame
CREATE TABLE schools (
  "USE_ID" INT PRIMARY KEY,
  "CATCH_TYPE" VARCHAR(255),
  "USE_DESC" VARCHAR(255),
  "geom" GEOMETRY(MULTIPOLYGON, 4326)
);

-- create indexes
CREATE INDEX idx_population_sa2_code ON population (sa2_code);
CREATE INDEX idx_businesses_sa2_code ON businesses (sa2_code);
CREATE INDEX idx_businesses_industry_name ON businesses (industry_name);
CREATE INDEX idx_crime_contour ON crime (contour);
CREATE INDEX idx_births_sa2_code ON births (sa2_code);

-- create spatial indexes
CREATE INDEX idx_sa2_regions_geom ON sa2_regions USING GIST (geom);
CREATE INDEX idx_schools_geom ON schools USING GIST (geom);
CREATE INDEX idx_polling_places_geom ON polling_places USING GIST (geom);
CREATE INDEX idx_stops_geom ON stops USING GIST (geom);
CREATE INDEX idx_births_geom ON births USING GIST (geom);