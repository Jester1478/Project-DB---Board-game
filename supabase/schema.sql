CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS public.booking CASCADE;
DROP TABLE IF EXISTS public.game_category CASCADE;
DROP TABLE IF EXISTS public.game_copy CASCADE;
DROP TABLE IF EXISTS public.board_game CASCADE;
DROP TABLE IF EXISTS public.category CASCADE;
DROP TABLE IF EXISTS public.employee CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

CREATE TABLE public.users (
    user_id     VARCHAR(20) PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    phone       VARCHAR(10)
);

CREATE TABLE public.employee (
    employee_id VARCHAR(20) PRIMARY KEY,
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    phone       VARCHAR(10)
);

CREATE TABLE public.category (
    category_id   VARCHAR(20) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE public.board_game (
    game_id        VARCHAR(50) PRIMARY KEY,
    game_name      VARCHAR(150) NOT NULL,
    description    TEXT,
    min_players    INTEGER NOT NULL CHECK (min_players >= 1),
    max_players    INTEGER NOT NULL,
    play_time_mins INTEGER NOT NULL CHECK (play_time_mins > 0),

    CONSTRAINT chk_board_game_player_range
        CHECK (max_players >= min_players)
);

CREATE TABLE public.game_category (
    game_id     VARCHAR(50) NOT NULL,
    category_id VARCHAR(20) NOT NULL,

    CONSTRAINT pk_game_category
        PRIMARY KEY (game_id, category_id),

    CONSTRAINT fk_game_category_game
        FOREIGN KEY (game_id)
        REFERENCES public.board_game(game_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_game_category_category
        FOREIGN KEY (category_id)
        REFERENCES public.category(category_id)
        ON DELETE CASCADE
);

CREATE TABLE public.game_copy (
    copy_id          VARCHAR(20) PRIMARY KEY,
    copy_code        VARCHAR(50) NOT NULL UNIQUE,
    condition_status VARCHAR(30) NOT NULL DEFAULT 'Good',
    copy_number      INTEGER NOT NULL CHECK (copy_number > 0),
    game_id          VARCHAR(50) NOT NULL,

    CONSTRAINT chk_game_copy_condition_status
        CHECK (condition_status IN ('Good', 'Fair', 'Damaged', 'Lost')),

    CONSTRAINT fk_game_copy_game
        FOREIGN KEY (game_id)
        REFERENCES public.board_game(game_id)
        ON DELETE RESTRICT,

    CONSTRAINT uq_game_copy_number_per_game
        UNIQUE (game_id, copy_number)
);

CREATE TABLE public.booking (
    booking_id         VARCHAR(20) PRIMARY KEY,
    start_time         TIMESTAMP NOT NULL,
    end_time           TIMESTAMP NOT NULL,
    actual_return_time TIMESTAMP,

    status VARCHAR(30) NOT NULL DEFAULT 'Reserved'
        CHECK (status IN (
            'Reserved',
            'In_Use',
            'Returned',
            'Overdue',
            'Cancelled'
        )),

    user_id        VARCHAR(20) NOT NULL,
    copy_id        VARCHAR(20) NOT NULL,
    checkout_by_id VARCHAR(20),
    return_by_id   VARCHAR(20),

    CONSTRAINT chk_booking_duration
        CHECK (
            end_time - start_time
            BETWEEN INTERVAL '30 minutes'
            AND INTERVAL '4 hours'
        ),

    CONSTRAINT chk_booking_return_time
        CHECK (
            actual_return_time IS NULL
            OR actual_return_time >= start_time
        ),

    CONSTRAINT exc_booking_no_overlap
        EXCLUDE USING GIST (
            copy_id WITH =,
            tsrange(start_time, end_time) WITH &&
        )
        WHERE (status IN ('Reserved', 'In_Use', 'Overdue')),

    CONSTRAINT fk_booking_user
        FOREIGN KEY (user_id)
        REFERENCES public.users(user_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_booking_copy
        FOREIGN KEY (copy_id)
        REFERENCES public.game_copy(copy_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_booking_checkout_employee
        FOREIGN KEY (checkout_by_id)
        REFERENCES public.employee(employee_id)
        ON DELETE SET NULL,

    CONSTRAINT fk_booking_return_employee
        FOREIGN KEY (return_by_id)
        REFERENCES public.employee(employee_id)
        ON DELETE SET NULL
);

CREATE INDEX idx_game_category_game
    ON public.game_category(game_id);

CREATE INDEX idx_game_category_category
    ON public.game_category(category_id);

CREATE INDEX idx_game_copy_game
    ON public.game_copy(game_id);

CREATE INDEX idx_booking_user
    ON public.booking(user_id);

CREATE INDEX idx_booking_copy
    ON public.booking(copy_id);

CREATE INDEX idx_booking_checkout
    ON public.booking(checkout_by_id);

CREATE INDEX idx_booking_return
    ON public.booking(return_by_id);

CREATE INDEX idx_booking_copy_time
    ON public.booking(copy_id, start_time, end_time);

CREATE INDEX idx_booking_status_end
    ON public.booking(status, end_time);
