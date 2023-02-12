-- SQL Queries Challenge --
-- 1. How many olympics games have been held?
SELECT 
  COUNT(DISTINCT games) AS total_olympic_games
FROM `sql-trial-357612.olympics_history.athlete_events`;

-- 2. List all down Olympic games held so far
SELECT DISTINCT
  year, season,city
FROM `sql-trial-357612.olympics_history.athlete_events`
ORDER BY year;

-- 3. Mention the total number of nations who participated in each olympic game
SELECT DISTINCT
  games, 
  COUNT(DISTINCT NOC) AS total_countries
FROM `sql-trial-357612.olympics_history.athlete_events`
GROUP BY Games
ORDER BY 2;

-- 4. Which year saw the lowest and the higher number of countries participating in olympics?
WITH total_no_country AS
(
  SELECT DISTINCT
    oh.games,
    COUNT(DISTINCT nr.region) AS total_countries,
    CONCAT(games,' - ',COUNT(DISTINCT nr.region)) AS no_countries,
    ROW_NUMBER() OVER(ORDER BY COUNT(DISTINCT nr.region)) AS row_num
  FROM 
    `sql-trial-357612.olympics_history.athlete_events` oh
    JOIN
    `sql-trial-357612.olympics_history.noc_regions` nr ON oh.NOC = nr. NOC
  GROUP BY 1
)
SELECT
  t1.no_countries AS lowest_countries, t2.no_countries AS highest_countries
FROM 
  total_no_country t1, total_no_country t2
WHERE t1.row_num = 1 AND t2.row_num = 51;

-- 5. Which nations has participated in all of the olympic games
SELECT
  nr.region,
  COUNT(DISTINCT oh.games) total_participated_games
FROM 
  `sql-trial-357612.olympics_history.athlete_events`AS oh
  JOIN
  sql-trial-357612.olympics_history.noc_regions AS nr ON oh.NOC = nr.NOC
GROUP BY 1
HAVING total_participated_games = (
  SELECT 
    COUNT(DISTINCT games) AS total_olympic_games
  FROM `sql-trial-357612.olympics_history.athlete_events`
)
ORDER BY 1;

-- 6. Identify all sports which was played in all summer olympics
WITH total_games AS
(
  SELECT
    COUNT(DISTINCT Games) AS total_games
  FROM `sql-trial-357612.olympics_history.athlete_events`
  WHERE season = 'Summer'
),
no_of_games AS
(
  SELECT
    sport, count(games) AS no_of_games 
  FROM
  (
    SELECT DISTINCT
      sport, games
    FROM 
      `sql-trial-357612.olympics_history.athlete_events` ae
    WHERE season = 'Summer'
    ORDER BY games
  )
  GROUP BY 1
  ORDER BY no_of_games ASC
)
SELECT
  sport,
  no_of_games,
  total_games
FROM 
  total_games AS tg
  JOIN
  no_of_games as nog ON tg.total_games = nog.no_of_games

-- 7. Which Sports were just played only once in the olympics.
WITH t1 AS
( 
SELECT DISTINCT
  sport,
  games
FROM `sql-trial-357612.olympics_history.athlete_events`
),
t2 AS
(
  SELECT
    sport, COUNT(1) AS no_of_games
  FROM t1
  GROUP BY 1
)
SELECT
  t2.*, t1.games
FROM t2
    JOIN
     t1 ON t2.sport = t1.sport
WHERE t2.no_of_games = 1
ORDER BY t1.sport;

-- 8. Fetch the total no of sports played in each olympic games
SELECT DISTINCT
  games,
  COUNT(DISTINCT sport) AS total_sport_played
FROM `sql-trial-357612.olympics_history.athlete_events`
GROUP BY 1;

-- 9. Fetch oldest athletes to win a gold medal
WITH t1 AS
(
  SELECT
    * EXCEPT(id,height, weight,noc,season),
    DENSE_RANK() OVER(ORDER BY age DESC) rnk_age
  FROM `sql-trial-357612.olympics_history.athlete_events`
  WHERE age <> 'NA' AND medal = 'Gold'
  ORDER BY age DESC
)
SELECT
  * EXCEPT(rnk_age)
FROM t1
WHERE rnk_age = 1;

-- 10. Find the Ratio of male and female athletes participated in all olympic games.
WITH male AS
(
  SELECT
    sex,
    COUNT(sex) AS total_male
  FROM `sql-trial-357612.olympics_history.athlete_events`
  WHERE sex = 'M'
  GROUP BY 1
),
female AS
(
  SELECT
    sex,
    COUNT(sex) AS total_female
  FROM  `sql-trial-357612.olympics_history.athlete_events`
  WHERE sex = 'F'
  GROUP BY 1
)
SELECT
  CONCAT(1,' : ',
    ROUND(CAST(m.total_male AS float64)/f.total_female,2)) AS ratio
FROM male m, female f;

-- 11. Fetch the top 5 athletes who have won the most gold medals.
WITH rank_gold_medal AS
(
  SELECT DISTINCT
    name,
    team,
    COUNT(medal) AS total_gold_medals,
    DENSE_RANK() OVER(ORDER BY COUNT(medal) DESC) AS rnk_medal
  FROM `sql-trial-357612.olympics_history.athlete_events`
  WHERE medal = 'Gold'
  GROUP BY 1,2
  ORDER BY total_gold_medals DESC
)
SELECT
  name,
  team,
  total_gold_medals
FROM rank_gold_medal
WHERE rnk_medal < 6;

--12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)
WITH rank_medal AS
(
  SELECT
    name,
    team,
    COUNT(medal) AS total_medals,
    DENSE_RANK() OVER(ORDER BY COUNT(medal) DESC) rnk
  FROM `sql-trial-357612.olympics_history.athlete_events`
  WHERE medal <> 'NA'
  GROUP BY 1,2
  ORDER BY total_medals DESC
)
SELECT name, team, total_medals
FROM rank_medal
WHERE rnk < 6;

-- 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
WITH country_rank_medal AS
(
  SELECT
    nr.region,
    COUNT(oh.medal) AS total_medal,
    DENSE_RANK() OVER(ORDER BY COUNT(oh.medal) DESC) AS rnk
  FROM `sql-trial-357612.olympics_history.athlete_events` oh
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON oh.NOC = nr.NOC
  WHERE medal <> 'NA'
  GROUP BY 1
  ORDER BY total_medal DESC
)
SELECT
  region,
  total_medal,
  rnk
FROM country_rank_medal
WHERE rnk < 6;

-- 14. List down total gold, silver and bronze medals won by each country.
  SELECT
    nr.region AS country,
    SUM(CASE
          WHEN oh.medal = 'Gold' THEN 1
          ELSE 0
        END) AS gold,
    SUM(CASE
          WHEN oh.medal = 'Silver' THEN 1
          ELSE 0
        END) AS silver,
    SUM(CASE
          WHEN oh.medal = 'Bronze' THEN 1
          ELSE 0
        END) AS bronze
  FROM `sql-trial-357612.olympics_history.athlete_events` oh 
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON oh.NOC = nr.NOC
  GROUP BY country
  ORDER BY gold DESC;

-- 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
SELECT
  oh.games,
  nr.region AS country,
  SUM(CASE
        WHEN oh.medal = 'Gold' THEN 1
        ELSE 0
      END) AS gold,
  SUM(CASE
        WHEN oh.medal = 'Silver' THEN 1
        ELSE 0
      END) AS silver,
  SUM(CASE
      WHEN oh.medal = 'Bronze' THEN 1
      ELSE 0
    END) AS bronze
FROM `sql-trial-357612.olympics_history.athlete_events` oh
      INNER JOIN
      `sql-trial-357612.olympics_history.noc_regions` nr ON oh.NOC = nr.NOC
GROUP BY 1,2
ORDER BY oh.games, country;

-- 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.
WITH gold AS
(
  SELECT
    ae.games,
    nr.region AS country,
    COUNT(ae.medal) AS num_of_gold,
    FIRST_VALUE(nr.region) OVER(PARTITION BY ae.games 
        ORDER BY COUNT(ae.medal) DESC) AS country_max_gold,
    ROW_NUMBER() OVER(PARTITION BY ae.games ORDER BY COUNT(ae.medal) DESC) AS row_num
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal = 'Gold' AND ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY ae.games ASC
),
silver AS
(
  SELECT
    ae.games,
    nr.region AS country,
    COUNT(ae.medal) AS num_of_silver,
    FIRST_VALUE(nr.region) OVER(PARTITION BY ae.games 
        ORDER BY COUNT(ae.medal) DESC) AS country_max_silver,
    ROW_NUMBER() OVER(PARTITION BY ae.games ORDER BY COUNT(ae.medal) DESC) AS row_num
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal = 'Silver' AND ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY ae.games ASC
),
bronze AS
(
  SELECT
    ae.games,
    nr.region AS country,
    COUNT(ae.medal) AS num_of_bronze,
    FIRST_VALUE(nr.region) OVER(PARTITION BY ae.games 
        ORDER BY COUNT(ae.medal) DESC) AS country_max_bronze,
    ROW_NUMBER() OVER(PARTITION BY ae.games ORDER BY COUNT(ae.medal) DESC) AS row_num
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal = 'Bronze' AND ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY ae.games ASC
),
olympics AS
(
  SELECT DISTINCT
    games
  FROM `sql-trial-357612.olympics_history.athlete_event`
  ORDER BY 1
)
SELECT
  o.games,
  CONCAT(g.countrY_max_gold,' - ',g.num_of_gold) AS max_gold,
  CONCAT(s.country_max_silver,' - ',s.num_of_silver) AS max_silver,
  CONCAT(b.country_max_bronze,' - ',b.num_of_bronze) AS max_bronze
FROM olympics o
     INNER JOIN
     gold g ON o.games = g.games
     INNER JOIN
     silver s ON o.games = s.games
     INNER JOIN
     bronze b ON o.games = b.games
WHERE g.row_num = 1 AND s.row_num = 1 AND b.row_num = 1
ORDER BY o.games;

-- 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH gold AS
(
  SELECT
    ae.games,
    nr.region AS country,
    COUNT(ae.medal) AS num_of_gold,
    FIRST_VALUE(nr.region) OVER(PARTITION BY ae.games 
        ORDER BY COUNT(ae.medal) DESC) AS country_max_gold,
    ROW_NUMBER() OVER(PARTITION BY ae.games ORDER BY COUNT(ae.medal) DESC) AS row_num
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal = 'Gold' AND ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY ae.games ASC
),
silver AS
(
  SELECT
    ae.games,
    nr.region AS country,
    COUNT(ae.medal) AS num_of_silver,
    FIRST_VALUE(nr.region) OVER(PARTITION BY ae.games 
        ORDER BY COUNT(ae.medal) DESC) AS country_max_silver,
    ROW_NUMBER() OVER(PARTITION BY ae.games ORDER BY COUNT(ae.medal) DESC) AS row_num
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal = 'Silver' AND ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY ae.games ASC
),
bronze AS
(
  SELECT
    ae.games,
    nr.region AS country,
    COUNT(ae.medal) AS num_of_bronze,
    FIRST_VALUE(nr.region) OVER(PARTITION BY ae.games 
        ORDER BY COUNT(ae.medal) DESC) AS country_max_bronze,
    ROW_NUMBER() OVER(PARTITION BY ae.games ORDER BY COUNT(ae.medal) DESC) AS row_num
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal = 'Bronze' AND ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY ae.games ASC
),
total_medal AS
(
  SELECT
    ae.games,
    nr.region AS country,
    COUNT(ae.medal) AS num_of_medal,
    FIRST_VALUE(nr.region) OVER(PARTITION BY ae.games 
        ORDER BY COUNT(ae.medal) DESC) AS country_max_medal,
    ROW_NUMBER() OVER(PARTITION BY ae.games ORDER BY COUNT(ae.medal) DESC) AS row_num
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY ae.games ASC
),
olympics AS
(
  SELECT DISTINCT
    games
  FROM `sql-trial-357612.olympics_history.athlete_event`
  ORDER BY 1
)
SELECT
  o.games,
  CONCAT(g.countrY_max_gold,' - ',g.num_of_gold) AS max_gold,
  CONCAT(s.country_max_silver,' - ',s.num_of_silver) AS max_silver,
  CONCAT(b.country_max_bronze,' - ',b.num_of_bronze) AS max_bronze,
  CONCAT(t.country_max_medal,' - ',t.num_of_medal) AS max_medal
FROM olympics o
     INNER JOIN
     gold g ON o.games = g.games
     INNER JOIN
     silver s ON o.games = s.games
     INNER JOIN
     bronze b ON o.games = b.games
     INNER JOIN
     total_medal t ON o.games = t.games
WHERE g.row_num = 1 AND s.row_num = 1 AND b.row_num = 1 AND t.row_num = 1
ORDER BY o.games;

-- 18. Which countries have never won gold medal but have won silver/bronze medals?
WITH medal_each_country AS
(
  SELECT
    nr.region AS country,
    SUM(CASE
          WHEN ae.medal = 'Gold' THEN 1
          ELSE 0
        END
    ) AS num_of_gold,
    SUM(CASE
          WHEN ae.medal = 'Silver' THEN 1
          ELSE 0
        END
    ) AS num_of_silver,
    SUM(CASE
          WHEN ae.medal = 'Bronze' THEN 1
          ELSE 0
        END
   ) AS num_of_bronze
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.NOC = nr.NOC
  WHERE ae.medal <> 'NA'
  GROUP BY 1
  ORDER BY 1
)
SELECT
  *
FROM medal_each_country
WHERE num_of_gold = 0 AND (num_of_silver > 0 OR num_of_bronze > 0)
ORDER BY num_of_bronze DESC;

-- 19. In which Sport/event, India has won highest medals.
WITH india_medal AS
(
  SELECT  
    nr.region AS country,
    ae.sport,
    COUNT(ae.medal) AS total_medal,
    RANK() OVER(PARTITION BY nr.region ORDER BY COUNT(ae.medal) DESC) AS rnk
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
       INNER JOIN
       `sql-trial-357612.olympics_history.noc_regions` nr ON ae.noc = nr.NOC
  WHERE nr.region = 'India' AND ae.medal <> 'NA'
  GROUP BY 1,2
  ORDER BY total_medal DESC
)
SELECT sport, total_medal
FROM india_medal
WHERE rnk = 1;

-- 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
WITH india_games AS
(
  SELECT
    nr.region AS country,
    ae.sport,
    ae.games,
    COUNT(ae.medal) AS total_medals
  FROM `sql-trial-357612.olympics_history.athlete_event` ae
        INNER JOIN
        `sql-trial-357612.olympics_history.noc_regions` nr ON ae.noc = nr.noc
  WHERE nr.region = 'India' AND ae.sport = 'Hockey' AND ae.medal <> 'NA'
  GROUP BY 3,2,1
)
SELECT *
FROM india_games;













