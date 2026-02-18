CREATE DATABASE IF NOT EXISTS nba;
USE nba;
DROP TABLE IF EXISTS player_stats_raw;
DROP VIEW IF EXISTS v_player_game_clean;
DROP VIEW IF EXISTS v_player_summary;
DROP VIEW IF EXISTS v_head_to_head;

CREATE TABLE player_stats_raw (
  player      VARCHAR(100) NOT NULL,   -- name of player
  team        VARCHAR(10)  NOT NULL,   -- player's team
  opponent    VARCHAR(10)  NOT NULL,   -- Opposing team
  result      VARCHAR(5)   NOT NULL,   -- W/L results
  minutes     DECIMAL(5,2) NULL,       -- Mins played

  fg          INT NULL,                -- Field goals made
  fga         INT NULL,                -- Field goal attempts
  fg_pct      DECIMAL(6,3) NULL,       -- Field goal %

  three_p     INT NULL,                -- 3Point fg
  three_pa    INT NULL,                -- 3Point  fg attempted
  three_pct   DECIMAL(6,3) NULL,       -- 3P fg %

  ft          INT NULL,                -- Free throws Made
  fta         INT NULL,                -- Free throw attempts
  ft_pct      DECIMAL(6,3) NULL,       -- Free throw %

  orb         INT NULL,                -- Offensive Rebounds
  drb         INT NULL,                -- Defensive Rebounds
  trb         INT NULL,                -- Total Rebounds
  ast         INT NULL,                -- Assists
  stl         INT NULL,                -- Steals
  blk         INT NULL,                -- Blocks
  tov         INT NULL,                -- Turnovers
  pf          INT NULL,                -- Personal Fouls
  pts         INT NULL,                -- Total Points scored

  gmsc        DECIMAL(6,2) NULL,       -- game score (summary metric)
  game_date   DATE NULL,               -- data (YYYY-MM-DD)

  INDEX idx_player_date (player, game_date),
  INDEX idx_team_date (team, game_date)
);

CREATE OR REPLACE VIEW v_player_game_clean AS 
SELECT 
  player, team, opponent, result, minutes,
  fg, fga, fg_pct,
  three_p, three_pa, three_pct,
  ft, fta, ft_pct,
  orb, drb, trb, ast, stl, blk, tov, pf, pts,
  gmsc,
  game_date,
  CASE
    WHEN (fga IS NULL OR fga = 0) AND (fta IS NULL OR fta = 0) THEN NULL
    WHEN (2 * (COALESCE(fga,0) + 0.44 * COALESCE(fta,0))) = 0 THEN NULL
    ELSE pts / (2 * (COALESCE(fga,0) + 0.44 * COALESCE(fta,0)))
  END AS ts_pct
FROM player_stats_raw;

CREATE OR REPLACE VIEW v_player_summary AS
SELECT
  player,
  COUNT(*) AS games,
  ROUND(AVG(pts), 2) AS ppg,
  ROUND(AVG(trb), 2) AS rpg,
  ROUND(AVG(ast), 2) AS apg,
  ROUND(AVG(stl), 2) AS spg,
  ROUND(AVG(blk), 2) AS bpg,
  ROUND(AVG(tov), 2) AS tpg,
  ROUND(AVG(minutes), 2) AS mpg,

  ROUND(SUM(fg) / NULLIF(SUM(fga), 0), 3) AS fg_pct,
  ROUND(SUM(three_p) / NULLIF(SUM(three_pa), 0), 3) AS three_pct,
  ROUND(SUM(ft) / NULLIF(SUM(fta), 0), 3) AS ft_pct,

  ROUND(
    SUM(pts) / NULLIF(2 * (SUM(fga) + 0.44 * SUM(fta)), 0),
    3
  ) AS ts_pct,

  ROUND(AVG(gmsc), 2) AS avg_gmsc
FROM player_stats_raw
GROUP BY player;

CREATE OR REPLACE VIEW v_head_to_head AS
SELECT *
FROM v_player_summary;
