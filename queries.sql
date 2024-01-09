SELECT category.name AS category_name, COUNT(film.film_id) AS film_count
FROM category
LEFT JOIN film_category ON category.category_id = film_category.category_id
LEFT JOIN film ON film_category.film_id = film.film_id
GROUP BY category.name
ORDER BY film_count DESC;

SELECT actor.actor_id, actor.first_name, actor.last_name, COUNT(rental.rental_id) as rental_count
FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id
JOIN film ON film_actor.film_id = film.film_id
JOIN inventory ON film.film_id = inventory.film_id
JOIN rental ON inventory.inventory_id = rental.inventory_id
GROUP BY actor.actor_id
ORDER BY rental_count DESC
LIMIT 10;

SELECT category.name AS category_name, SUM(payment.amount) AS total_payment
FROM category
JOIN film_category ON category.category_id = film_category.category_id
JOIN film ON film_category.film_id = film.film_id
JOIN inventory ON film.film_id = inventory.film_id
JOIN rental ON inventory.inventory_id = rental.inventory_id
JOIN payment ON rental.rental_id = payment.rental_id
GROUP BY category.name
ORDER BY total_payment DESC
LIMIT 1;

SELECT film.title
FROM film
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory
    WHERE inventory.film_id = film.film_id
)

WITH ActorFilmCounts AS (
    SELECT
        actor.actor_id,
        actor.first_name,
        actor.last_name,
        COUNT(DISTINCT film_actor.film_id) AS film_count
    FROM actor
    JOIN film_actor ON actor.actor_id = film_actor.actor_id
    JOIN film_category ON film_actor.film_id = film_category.film_id
    JOIN category ON film_category.category_id = category.category_id
    WHERE category.name = 'Children'
    GROUP BY actor.actor_id, actor.first_name, actor.last_name
)

SELECT actor_id, first_name, last_name, film_count
FROM ActorFilmCounts
WHERE film_count IN (SELECT film_count FROM ActorFilmCounts ORDER BY film_count DESC LIMIT 3);

SELECT
    address.city_id,
    city.city,
    COUNT(CASE WHEN customer.active = 1 THEN 1 END) AS active_customers,
    COUNT(CASE WHEN customer.active = 0 THEN 1 END) AS inactive_customers
FROM address
JOIN customer ON address.address_id = customer.address_id
JOIN city ON address.city_id = city.city_id
GROUP BY address.city_id, city.city
ORDER BY inactive_customers DESC;

WITH CategoryRent AS (
    SELECT
        c.name AS category_name,
        SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600) AS total_rent_hours
    FROM
        category c
    JOIN
        film_category fc ON fc.category_id = c.category_id
    JOIN
        inventory i ON i.film_id = fc.film_id
    JOIN
        rental r ON r.inventory_id = i.inventory_id
    JOIN
        customer c2 ON c2.customer_id = r.customer_id
    JOIN
        address a ON a.address_id = c2.address_id
    JOIN
        city c3 ON c3.city_id = a.city_id AND c3.city LIKE 'a%'
    GROUP BY
        c.name
    ORDER BY
        total_rent_hours DESC
    LIMIT 1
), CategoryRentWithHyphen AS (
    SELECT
        c.name AS category_name,
        SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600) AS total_rent_hours
    FROM
        category c
    JOIN
        film_category fc ON fc.category_id = c.category_id
    JOIN
        inventory i ON i.film_id = fc.film_id
    JOIN
        rental r ON r.inventory_id = i.inventory_id
    JOIN
        customer c2 ON c2.customer_id = r.customer_id
    JOIN
        address a ON a.address_id = c2.address_id
    JOIN
        city c3 ON c3.city_id = a.city_id AND c3.city LIKE '%-%'
    GROUP BY
        c.name
    ORDER BY
        total_rent_hours DESC
    LIMIT 1
)
SELECT
    category_name,
    total_rent_hours
FROM
    CategoryRent
UNION
SELECT
    category_name,
    total_rent_hours
FROM
    CategoryRentWithHyphen
ORDER BY
    total_rent_hours DESC;
