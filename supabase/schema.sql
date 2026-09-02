-- ============================================================
-- Board Game Queue & Booking Database - Create Tables Schema
-- Fundamental of Database Systems
-- Group: ????????????????
-- Compatible with PostgreSQL & Supabase
-- -------------------------------------------------------------
-- Column names follow the ER Diagram / Relational Schema
-- exactly. 7 tables, matching the 7 entities in the diagram.
-- ============================================================

-- Required for the EXCLUDE constraint on BOOKING (see section 7).
-- btree_gist allows mixing an equality operator (=) with a range
-- overlap operator (&&) inside the same GiST index.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ------------------------------------------------------------
DROP TABLE IF EXISTS BOOKING CASCADE;
DROP TABLE IF EXISTS GAME_CATEGORY CASCADE;
DROP TABLE IF EXISTS GAME_COPY CASCADE;
DROP TABLE IF EXISTS BOARD_GAME CASCADE;
DROP TABLE IF EXISTS CATEGORY CASCADE;
DROP TABLE IF EXISTS EMPLOYEE CASCADE;
DROP TABLE IF EXISTS USERS CASCADE;

-- ============================================================
-- 1. USERS
-- -------------------------------------------------------------
-- Named USERS (plural) because USER is a reserved keyword in
-- PostgreSQL - it is a shorthand for CURRENT_USER, so
-- CREATE TABLE USER would fail. Matches the ER entity "Users".
-- ============================================================
CREATE TABLE USERS (
    User_ID             VARCHAR(20) PRIMARY KEY,
    First_Name          VARCHAR(100) NOT NULL,
    Last_Name           VARCHAR(100) NOT NULL,
    Email               VARCHAR(120) NOT NULL UNIQUE,
    Phone               VARCHAR(10)
);

-- ============================================================
-- 2. EMPLOYEE
-- ============================================================
CREATE TABLE EMPLOYEE (
    Employee_ID         VARCHAR(20) PRIMARY KEY,
    First_Name          VARCHAR(100) NOT NULL,
    Last_Name           VARCHAR(100) NOT NULL,
    Email               VARCHAR(120) NOT NULL UNIQUE,
    Phone               VARCHAR(10)
);

-- ============================================================
-- 3. CATEGORY
-- ============================================================
CREATE TABLE CATEGORY (
    Categories_ID       VARCHAR(20) PRIMARY KEY,
    Categories_Name     VARCHAR(100) NOT NULL UNIQUE
);

-- ============================================================
-- 4. BOARD_GAME
-- -------------------------------------------------------------
-- The game TITLE only (e.g. "Catan"). The physical boxes that
-- are actually lent out live in GAME_COPY.
-- ============================================================
CREATE TABLE BOARD_GAME (
    Game_ID             VARCHAR(50) PRIMARY KEY,
    Game_Name           VARCHAR(150) NOT NULL,
    Description         TEXT,
    Min_Players         INTEGER NOT NULL CHECK (Min_Players >= 1),
    Max_Players         INTEGER NOT NULL,
    Play_Time_Mins      INTEGER NOT NULL CHECK (Play_Time_Mins > 0),
    CONSTRAINT CHK_GAME_PLAYER_RANGE
        CHECK (Max_Players >= Min_Players)
);

-- ============================================================
-- 5. GAME_CATEGORY
-- -------------------------------------------------------------
-- Bridge table resolving the M:N relationship between
-- BOARD_GAME and CATEGORY. Composite primary key.
-- ============================================================
CREATE TABLE GAME_CATEGORY (
    Game_ID             VARCHAR(50) NOT NULL,
    Categories_ID       VARCHAR(20) NOT NULL,
    CONSTRAINT PK_GAME_CATEGORY
        PRIMARY KEY (Game_ID, Categories_ID),
    CONSTRAINT FK_GAMECAT_GAME
        FOREIGN KEY (Game_ID)
        REFERENCES BOARD_GAME(Game_ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_GAMECAT_CATEGORY
        FOREIGN KEY (Categories_ID)
        REFERENCES CATEGORY(Categories_ID)
        ON DELETE CASCADE
);

-- ============================================================
-- 6. GAME_COPY
-- -------------------------------------------------------------
-- One physical box in the storage cabinet (e.g. CATAN-01).
-- Bookings are made against a COPY, not against a game title --
-- this is what makes the per-box timeline and the overlap
-- check work.
-- ============================================================
CREATE TABLE GAME_COPY (
    Copy_ID             VARCHAR(20) PRIMARY KEY,
    Copy_Code           VARCHAR(50) NOT NULL UNIQUE,   -- e.g. 'CATAN-01'
    Condition_Status    VARCHAR(30) NOT NULL DEFAULT 'Good'
        CHECK (Condition_Status IN ('Good', 'Fair', 'Damaged', 'Lost')),
    Copy_Numbers        INTEGER NOT NULL CHECK (Copy_Numbers > 0),
    Game_ID             VARCHAR(20) NOT NULL,
    CONSTRAINT FK_COPY_GAME
        FOREIGN KEY (Game_ID)
        REFERENCES BOARD_GAME(Game_ID)
        ON DELETE RESTRICT,
    CONSTRAINT UQ_COPY_NUMBER_PER_GAME
        UNIQUE (Game_ID, Copy_Numbers)
);

-- ============================================================
-- 7. BOOKING
-- -------------------------------------------------------------
-- Core table of the system. Holds the reservation window
-- (Start_Time - End_Time), the real return time, and the
-- lifecycle status of the loan.
--
-- Two separate foreign keys point at EMPLOYEE because the
-- employee who hands the box over and the one who takes
-- it back may be different people on different shifts.
-- ============================================================
CREATE TABLE BOOKING (
    Booking_ID          VARCHAR(20) PRIMARY KEY,
    Start_Time          TIMESTAMP NOT NULL,
    End_Time            TIMESTAMP NOT NULL,
    Actual_Return_Time  TIMESTAMP,                     -- NULL until the box comes back
    Status              VARCHAR(30) NOT NULL DEFAULT 'Reserved'
        CHECK (Status IN ('Reserved', 'In_Use', 'Returned',
                          'Overdue', 'Cancelled')),
    User_ID             VARCHAR(20) NOT NULL,
    Copy_ID             VARCHAR(20) NOT NULL,
    Checkout_By_ID      VARCHAR(20),                   -- NULL while still only a reservation
    Return_By_ID        VARCHAR(20),                   -- NULL until the box is returned

    -- BR-02: a booking slot must last at least 30 minutes
    -- and no more than 4 hours.
    CONSTRAINT CHK_BOOKING_DURATION
        CHECK (End_Time - Start_Time BETWEEN INTERVAL '30 minutes'
                                         AND INTERVAL '4 hours'),

    -- A return time can only be recorded after the loan started.
    CONSTRAINT CHK_BOOKING_RETURN_TIME
        CHECK (Actual_Return_Time IS NULL OR Actual_Return_Time >= Start_Time),

    -- BR-03: the same physical box can never be booked by two
    -- people at overlapping times. Enforced by the database
    -- itself, so two simultaneous requests cannot slip through.
    -- Returned and cancelled rows are excluded from the check.
    CONSTRAINT EXC_BOOKING_NO_OVERLAP
        EXCLUDE USING GIST (
            Copy_ID WITH =,
            TSRANGE(Start_Time, End_Time) WITH &&
        ) WHERE (Status IN ('Reserved', 'In_Use', 'Overdue')),

    CONSTRAINT FK_BOOKING_USER
        FOREIGN KEY (User_ID)
        REFERENCES USERS(User_ID)
        ON DELETE CASCADE,
    CONSTRAINT FK_BOOKING_COPY
        FOREIGN KEY (Copy_ID)
        REFERENCES GAME_COPY(Copy_ID)
        ON DELETE RESTRICT,
    CONSTRAINT FK_BOOKING_CHECKOUT_EMPLOYEE
        FOREIGN KEY (Checkout_By_ID)
        REFERENCES EMPLOYEE(Employee_ID)
        ON DELETE SET NULL,
    CONSTRAINT FK_BOOKING_RETURN_EMPLOYEE
        FOREIGN KEY (Return_By_ID)
        REFERENCES EMPLOYEE(Employee_ID)
        ON DELETE SET NULL
);

-- ============================================================
-- 8. Indexes on Foreign Keys
-- ============================================================
CREATE INDEX idx_gamecat_game          ON GAME_CATEGORY(Game_ID);
CREATE INDEX idx_gamecat_category      ON GAME_CATEGORY(Categories_ID);
CREATE INDEX idx_copy_game             ON GAME_COPY(Game_ID);
CREATE INDEX idx_booking_user          ON BOOKING(User_ID);
CREATE INDEX idx_booking_copy          ON BOOKING(Copy_ID);
CREATE INDEX idx_booking_checkout      ON BOOKING(Checkout_By_ID);
CREATE INDEX idx_booking_return        ON BOOKING(Return_By_ID);

-- Supports the Timeline View (F-02) and availability lookups.
CREATE INDEX idx_booking_copy_time     ON BOOKING(Copy_ID, Start_Time, End_Time);

-- Supports the Automated Overdue Tracker scan (F-04).
CREATE INDEX idx_booking_status_end    ON BOOKING(Status, End_Time);

-- ============================================================
-- End of Create Tables Script
-- ============================================================
