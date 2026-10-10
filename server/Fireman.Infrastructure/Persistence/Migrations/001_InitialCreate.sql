-- =======================================================================
-- Fireman PostgreSQL 17 - Initial Schema (Idempotent)
-- Generated to align with FiremanDbContext & Entity Configurations
-- =======================================================================

CREATE TABLE IF NOT EXISTS "Users" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "Username" character varying(50) NOT NULL UNIQUE,
    "Email" character varying(256) NOT NULL UNIQUE,
    "PasswordHash" text NOT NULL,
    "Status" integer NOT NULL DEFAULT 1,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc'),
    "LastLoginAt" timestamp with time zone NULL
);

CREATE INDEX IF NOT EXISTS "IX_Users_Status" ON "Users" ("Status");

CREATE TABLE IF NOT EXISTS "Characters" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NOT NULL UNIQUE REFERENCES "Users"("Id") ON DELETE CASCADE,
    "Name" character varying(50) NOT NULL,
    "Level" integer NOT NULL DEFAULT 1,
    "ExperiencePoints" bigint NOT NULL DEFAULT 0,
    "CurrentSkinId" character varying(50) NOT NULL DEFAULT 'default_fireman',
    "SpeedModifier" real NOT NULL DEFAULT 1.0,
    "BombCapacityModifier" integer NOT NULL DEFAULT 0,
    "BombRangeModifier" integer NOT NULL DEFAULT 0,
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE TABLE IF NOT EXISTS "Wallets" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NOT NULL UNIQUE REFERENCES "Users"("Id") ON DELETE CASCADE,
    "Gold" bigint NOT NULL DEFAULT 0,
    "Gems" bigint NOT NULL DEFAULT 0,
    "xmin" xid NOT NULL
);

CREATE TABLE IF NOT EXISTS "CurrencyLedgerEntries" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "WalletId" uuid NOT NULL REFERENCES "Wallets"("Id") ON DELETE CASCADE,
    "CurrencyType" integer NOT NULL,
    "DeltaAmount" bigint NOT NULL,
    "BalanceAfter" bigint NOT NULL,
    "TransactionType" integer NOT NULL,
    "ReferenceId" character varying(100) NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE INDEX IF NOT EXISTS "IX_CurrencyLedgerEntries_WalletId_CreatedAt" ON "CurrencyLedgerEntries" ("WalletId", "CreatedAt");

CREATE TABLE IF NOT EXISTS "ItemDefinitions" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "Code" character varying(50) NOT NULL UNIQUE,
    "Name" character varying(100) NOT NULL,
    "Description" text NOT NULL,
    "Category" integer NOT NULL,
    "Rarity" integer NOT NULL,
    "BuyPriceGold" bigint NULL,
    "BuyPriceGems" bigint NULL,
    "IsActive" boolean NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS "InventoryItems" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "ItemDefinitionId" uuid NOT NULL REFERENCES "ItemDefinitions"("Id") ON DELETE RESTRICT,
    "Quantity" integer NOT NULL DEFAULT 1,
    "IsEquipped" boolean NOT NULL DEFAULT FALSE,
    "AcquiredAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE INDEX IF NOT EXISTS "IX_InventoryItems_UserId_ItemDefinitionId" ON "InventoryItems" ("UserId", "ItemDefinitionId");

CREATE TABLE IF NOT EXISTS "Matches" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "Mode" integer NOT NULL,
    "Status" integer NOT NULL DEFAULT 0,
    "Seed" integer NOT NULL DEFAULT 12345,
    "DurationSeconds" integer NOT NULL DEFAULT 0,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc'),
    "StartedAt" timestamp with time zone NULL,
    "EndedAt" timestamp with time zone NULL
);

CREATE INDEX IF NOT EXISTS "IX_Matches_Status_CreatedAt" ON "Matches" ("Status", "CreatedAt");

CREATE TABLE IF NOT EXISTS "MatchPlayers" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "MatchId" uuid NOT NULL REFERENCES "Matches"("Id") ON DELETE CASCADE,
    "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "Kills" integer NOT NULL DEFAULT 0,
    "Score" integer NOT NULL DEFAULT 0,
    "Placement" integer NOT NULL DEFAULT 0,
    "IsWinner" boolean NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS "IX_MatchPlayers_MatchId" ON "MatchPlayers" ("MatchId");
CREATE INDEX IF NOT EXISTS "IX_MatchPlayers_UserId" ON "MatchPlayers" ("UserId");

CREATE TABLE IF NOT EXISTS "Missions" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "Code" character varying(50) NOT NULL UNIQUE,
    "Title" character varying(100) NOT NULL,
    "Description" text NOT NULL,
    "Type" integer NOT NULL,
    "TargetCount" integer NOT NULL DEFAULT 1,
    "RewardGold" integer NOT NULL DEFAULT 0,
    "RewardExperience" integer NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "UserMissions" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "MissionId" uuid NOT NULL REFERENCES "Missions"("Id") ON DELETE CASCADE,
    "CurrentProgress" integer NOT NULL DEFAULT 0,
    "IsCompleted" boolean NOT NULL DEFAULT FALSE,
    "IsRewardClaimed" boolean NOT NULL DEFAULT FALSE,
    "AssignedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc'),
    "CompletedAt" timestamp with time zone NULL
);

CREATE INDEX IF NOT EXISTS "IX_UserMissions_UserId_MissionId" ON "UserMissions" ("UserId", "MissionId");

CREATE TABLE IF NOT EXISTS "AntiCheatLogs" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "Action" character varying(100) NOT NULL,
    "Reason" text NOT NULL,
    "Severity" integer NOT NULL,
    "MetadataJson" jsonb NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE INDEX IF NOT EXISTS "IX_AntiCheatLogs_UserId_CreatedAt" ON "AntiCheatLogs" ("UserId", "CreatedAt");

CREATE TABLE IF NOT EXISTS "AuditLogs" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NULL,
    "Action" character varying(100) NOT NULL,
    "EntityName" character varying(100) NOT NULL,
    "EntityId" character varying(100) NOT NULL,
    "Details" text NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE INDEX IF NOT EXISTS "IX_AuditLogs_EntityName_EntityId" ON "AuditLogs" ("EntityName", "EntityId");

CREATE TABLE IF NOT EXISTS "OutboxMessages" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "Type" character varying(200) NOT NULL,
    "Payload" text NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc'),
    "ProcessedAt" timestamp with time zone NULL,
    "RetryCount" integer NOT NULL DEFAULT 0,
    "LastError" text NULL
);

CREATE INDEX IF NOT EXISTS "IX_OutboxMessages_ProcessedAt" ON "OutboxMessages" ("ProcessedAt") WHERE "ProcessedAt" IS NULL;

CREATE TABLE IF NOT EXISTS "Seasons" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "SeasonNumber" integer NOT NULL UNIQUE,
    "Name" character varying(100) NOT NULL,
    "StartDate" timestamp with time zone NOT NULL,
    "EndDate" timestamp with time zone NOT NULL,
    "IsActive" boolean NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS "SeasonRewardTiers" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "SeasonId" uuid NOT NULL REFERENCES "Seasons"("Id") ON DELETE CASCADE,
    "TierLevel" integer NOT NULL,
    "RequiredExperience" integer NOT NULL,
    "RewardType" integer NOT NULL,
    "RewardAmount" integer NOT NULL
);

CREATE TABLE IF NOT EXISTS "UserSeasonProgresses" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "SeasonId" uuid NOT NULL REFERENCES "Seasons"("Id") ON DELETE CASCADE,
    "CurrentTier" integer NOT NULL DEFAULT 1,
    "CurrentExperience" integer NOT NULL DEFAULT 0,
    "HasPremiumPass" boolean NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS "Friendships" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "RequesterId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "AddresseeId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "Status" integer NOT NULL DEFAULT 0,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE INDEX IF NOT EXISTS "IX_Friendships_RequesterId_AddresseeId" ON "Friendships" ("RequesterId", "AddresseeId");

CREATE TABLE IF NOT EXISTS "PlayerReports" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "ReporterId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "TargetUserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "Reason" integer NOT NULL,
    "Notes" text NULL,
    "Status" integer NOT NULL DEFAULT 0,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE TABLE IF NOT EXISTS "InAppNotifications" (
    "Id" uuid NOT NULL PRIMARY KEY,
    "UserId" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "Title" character varying(100) NOT NULL,
    "Message" text NOT NULL,
    "IsRead" boolean NOT NULL DEFAULT FALSE,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE INDEX IF NOT EXISTS "IX_InAppNotifications_UserId_IsRead" ON "InAppNotifications" ("UserId", "IsRead");

CREATE TABLE IF NOT EXISTS "clans" (
    "id" uuid NOT NULL PRIMARY KEY,
    "name" character varying(50) NOT NULL,
    "tag" character varying(10) NOT NULL UNIQUE,
    "description" character varying(500) NULL,
    "badge_icon" character varying(50) NOT NULL,
    "level" integer NOT NULL DEFAULT 1,
    "experience_points" bigint NOT NULL DEFAULT 0,
    "required_trophies" integer NOT NULL DEFAULT 0,
    "is_open" boolean NOT NULL DEFAULT TRUE,
    "created_at" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc')
);

CREATE TABLE IF NOT EXISTS "clan_members" (
    "id" uuid NOT NULL PRIMARY KEY,
    "clan_id" uuid NOT NULL REFERENCES "clans"("id") ON DELETE CASCADE,
    "user_id" uuid NOT NULL REFERENCES "Users"("Id") ON DELETE CASCADE,
    "role" smallint NOT NULL DEFAULT 1,
    "joined_at" timestamp with time zone NOT NULL DEFAULT (now() at time zone 'utc'),
    CONSTRAINT "UQ_clan_members_clan_user" UNIQUE ("clan_id", "user_id")
);

CREATE INDEX IF NOT EXISTS "IX_clan_members_user_id" ON "clan_members" ("user_id");
