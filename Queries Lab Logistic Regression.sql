use sakila;

-- PART 1
-- table  summary of rentals, per film_id. MAIN QUERY -- 

CREATE OR REPLACE VIEW rental_info_2 AS  -- view
with rental_info as (
SELECT -- use rented in may and times rented in may
	r.rental_id,
    r.rental_date,
    YEAR(r.rental_date),
    MONTH(r.rental_date),
    r.inventory_id,
    i.film_id,
	CASE  -- set up flag for films that were rented in may. In following step the results will be aggregated and duplicate rows removed in that process
				   WHEN MONTH(r.rental_date) = 5 AND YEAR(r.rental_date) = 2005 THEN 1 
				   ELSE 0 
			   END AS rented_may2005_flag,
    COUNT(r.rental_id) OVER (PARTITION BY i.film_id)  AS count_rented -- this will give us a rental count of each film in the seleted month. This column will not be used for the independent variable but could be used in other ways.
FROM
	rental r
JOIN
	inventory i ON r.inventory_id = i.inventory_id
WHERE
YEAR(r.rental_date) = 2005 AND MONTH(r.rental_date) = 5
ORDER BY
	count_rented DESC
    )
SELECT -- 686 rows now 1000 rows -- select
	f.film_id,
    max(ri.rented_may2005_flag) as rented_may, -- to avoid duplicates selecting 'max' from binary values in previous table
	(SELECT COUNT(i2.inventory_id)  
			FROM inventory i2 
			WHERE i2.film_id = f.film_id
			) 
			AS film_copies, -- selected to have a column with the inventory count per film as potential feature to use in the ligistical regression
    max(ri.count_rented) as times_rented_may,
	CASE
		WHEN f.film_id IN (select * from top_3_actors) then 1
        ELSE 0
	END AS top_actor_flag -- this field will show whether one of the top 3 prolific actors stars in the respective film
FROM
	rental_info ri
RIGHT JOIN
	film f ON ri.film_id = f.film_id
GROUP BY
	film_id
ORDER BY
	film_id
    ; -- long query end
    
    
-- PART 2, other views: 
-- (B) VIEW of films with top actors
CREATE VIEW top_3_actors as 
SELECT distinct(film_id) -- remove dupl.
FROM
	film_actor
WHERE actor_id IN ( 
	SELECT actor_id FROM (
				SELECT actor_id 
				FROM film_actor 
				GROUP BY actor_id 
				ORDER BY count(film_id) DESC
				LIMIT 3
				) as sub1
);

select * from top_3_actors;


-- PART 2, other views: 
-- (A) QUERY rental count 2005 06
CREATE OR REPLACE VIEW rental_count_2005_06 AS (
SELECT 
    COUNT(*) AS rental_count_2005_06,
	i.film_id,
    YEAR(r.rental_date) AS rental_year,
    MONTH(r.rental_date) AS rental_month
FROM
    rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE YEAR(r.rental_date) = 2005 and MONTH(r.rental_date) = 06
GROUP BY
    i.film_id,
    rental_year,
    rental_month
    ); -- 16044 rows
    
    
    
-- PART 3: query o be used directly in jupyter notebook

SELECT
    f.film_id,
    r.rented_may,
    r.film_copies,
    r.times_rented_may,
    r.top_actor_flag,
    f.title,
    f.release_year,
    f.language_id,
    f.length,
    f.rental_rate,
    f.rating,
    c.name as category,
	rc2.rental_count_2005_06
FROM 
	rental_info_2 r
LEFT JOIN film f on r.film_id = f.film_id
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON fc.category_id = c.category_id
LEFT jOIN rental_count_2005_06 rc2 ON f.film_id = rc2.film_id
ORDER BY
	f.film_id ASC
;











-- TEST TEST TEST






-- TEST from actor: top 3 and lower 3 actors!
select * from film_actor
order by film_id;

SELECT 
	title
FROM 
	film
WHERE 
	film_id IN (
		SELECT film_id 
		FROM film_actor
		WHERE actor_id = (
					SELECT actor_id 
					FROM film_actor 
					GROUP BY actor_id 
					ORDER BY count(film_id) DESC 
					LIMIT 1
));

-- tests

-- 200 actors
SELECT actor_id , count(film_id),
CASE 
	WHEN count(film_id) >=40 THEN 'top actor'
	WHEN count(film_id) <16 THEN 'bottom actor'
    ELSE 0
    END AS x3
FROM film_actor 
GROUP BY actor_id 
HAVING count(film_id) >=40 OR count(film_id) <16
ORDER BY count(film_id) DESC ;




    
