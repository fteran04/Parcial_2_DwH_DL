-- ============================================================
-- 4. CATÁLOGO DE CONSULTAS ANALÍTICAS - dwh_sports
-- ============================================================
-- Ejecutar dentro de la base de datos dwh_sports:
--   sudo -u postgres psql
--   \c dwh_sports

-- Consulta 1 (3%): Top 10 de atletas con mayor puntuación promedio
-- (solo atletas con nivel de membresía registrado)
SELECT
    p.first_name,
    p.last_name,
    p.membership_level,
    COUNT(f.id_event) AS total_events,
    ROUND(AVG(f.score_numeric)::numeric, 2) AS avg_score
FROM ft_player_performance f
JOIN dim_persons_performance p ON f.id_person = p.id
WHERE p.membership_level IS NOT NULL
GROUP BY p.first_name, p.last_name, p.membership_level
ORDER BY avg_score DESC
LIMIT 10;


-- Consulta 2 (5%): Rendimiento segmentado por nivel de membresía y género
SELECT
    p.membership_level,
    p.gender,
    COUNT(DISTINCT f.id_person) AS unique_athletes,
    COUNT(f.id_event) AS total_participations,
    ROUND(AVG(f.score_numeric)::numeric, 2) AS avg_score,
    ROUND(MAX(f.score_numeric)::numeric, 2) AS max_score
FROM ft_player_performance f
JOIN dim_persons_performance p ON f.id_person = p.id
GROUP BY p.membership_level, p.gender
ORDER BY p.membership_level, avg_score DESC;


-- Consulta 3 (5%): Impacto del estado del evento sobre las posiciones de juego
SELECT
    pos.abbreviation AS position_code,
    e.event_status,
    COUNT(f.id_event) AS total_events,
    ROUND(AVG(f.score_numeric)::numeric, 2) AS avg_position_score
FROM ft_player_performance f
JOIN dim_positions pos ON f.id_position = pos.id
JOIN dim_events e ON f.id_event = e.id
GROUP BY pos.abbreviation, e.event_status
HAVING COUNT(f.id_event) > 0
ORDER BY avg_position_score DESC;


-- Consulta 4 (7%): Top 3 de atletas por categoría de membresía con DENSE_RANK
WITH athlete_scores AS (
    SELECT
        p.id,
        p.first_name || ' ' || p.last_name AS full_name,
        p.membership_level,
        AVG(f.score_numeric) AS avg_score,
        DENSE_RANK() OVER (PARTITION BY p.membership_level ORDER BY AVG(f.score_numeric) DESC) AS ranking
    FROM ft_player_performance f
    JOIN dim_persons_performance p ON f.id_person = p.id
    GROUP BY p.id, p.first_name || ' ' || p.last_name, p.membership_level
)
SELECT
    membership_level,
    full_name,
    ROUND(avg_score::numeric, 2) AS avg_score,
    ranking
FROM athlete_scores
WHERE ranking <= 3
ORDER BY membership_level, ranking;


-- Consulta 5 (10%): Rendimiento individual frente al promedio de su categoría con PERCENT_RANK
WITH tier_stats AS (
    SELECT
        p.membership_level,
        AVG(f.score_numeric) AS tier_avg_score
    FROM ft_player_performance f
    JOIN dim_persons_performance p ON f.id_person = p.id
    GROUP BY p.membership_level
),
participant_performance AS (
    SELECT
        p.id,
        p.first_name || ' ' || p.last_name AS full_name,
        p.membership_level,
        COUNT(f.id_event) AS total_events,
        AVG(f.score_numeric) AS personal_avg_score
    FROM ft_player_performance f
    JOIN dim_persons_performance p ON f.id_person = p.id
    GROUP BY p.id, p.first_name || ' ' || p.last_name, p.membership_level
)
SELECT
    pp.full_name,
    pp.membership_level,
    ROUND(pp.personal_avg_score::numeric, 2) AS personal_avg_score,
    ROUND(ts.tier_avg_score::numeric, 2) AS tier_avg_score,
    ROUND((pp.personal_avg_score - ts.tier_avg_score)::numeric, 2) AS difference_vs_tier,
    CASE
        WHEN pp.personal_avg_score >= ts.tier_avg_score THEN 'Por encima del promedio'
        ELSE 'Por debajo del promedio'
    END AS performance_status,
    ROUND(PERCENT_RANK() OVER (PARTITION BY pp.membership_level ORDER BY pp.personal_avg_score)::numeric, 2) AS percentile_in_tier
FROM participant_performance pp
JOIN tier_stats ts ON pp.membership_level = ts.membership_level
ORDER BY pp.membership_level, pp.personal_avg_score DESC;
