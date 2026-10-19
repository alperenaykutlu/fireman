-- Adds persistent appearance profiles for installations created before this feature.
CREATE TABLE IF NOT EXISTS character_customizations (
    "ProfileId" uuid NOT NULL PRIMARY KEY,
    "Gender" character varying(10) NOT NULL DEFAULT 'male',
    "Hat" character varying(80) NOT NULL DEFAULT 'Standart kask',
    "HatStyle" integer NOT NULL DEFAULT 0,
    "Suit" character varying(80) NOT NULL DEFAULT 'Klasik itfaiye ceketi',
    "SuitStyle" integer NOT NULL DEFAULT 0,
    "Accessory" character varying(80) NOT NULL DEFAULT 'Hortum seti',
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);
