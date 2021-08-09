/* Query 1 What is the proportion for each movie category in terms of number of dvd rent? */

SELECT c.name                                                           AS category,
       COUNT(*)                                                         AS rental_count,
       ROUND((COUNT(*) * 1.0 / (SELECT COUNT(*) FROM rental)) * 100, 2) AS rental_percent
FROM category c
         JOIN film_category fc
              ON fc.category_id = c.category_id
         JOIN film f
              ON fc.film_id = f.film_id
         JOIN inventory i
              ON i.film_id = f.film_id
         JOIN rental r
              ON i.inventory_id = r.inventory_id
GROUP BY 1
ORDER BY 2 DESC;




/* Query 2 How much of the total payments received are due to the late fees? */

WITH t1 AS (SELECT c.customer_id,
                   f.title                  AS movie,
                   f.rental_rate            AS dvd_rental_fee,
                   p.amount                 AS amount_paid,
                   p.amount - f.rental_rate AS late_fee
            FROM film f
                     JOIN inventory i
                          ON f.film_id = i.film_id
                     JOIN rental r
                          ON i.inventory_id = r.inventory_id
                     JOIN payment p
                          ON r.rental_id = p.rental_id
                     JOIN customer c
                          ON p.customer_id = c.customer_id)

SELECT SUM(dvd_rental_fee)                                      AS total_dvd_rental_fee,
       100 - ROUND((SUM(late_fee) / SUM(amount_paid) * 100), 0) AS dvd_rental_fee_percent,
       SUM(late_fee)                                            AS total_late_fee,
       ROUND((SUM(late_fee) / SUM(amount_paid) * 100), 0)       AS late_fee_percent
FROM t1;




/* Query 3 How the two stores compare in their number of rental orders during every month for all the years? */

SELECT store_id,
       year || '-' || month AS year_month,
       num_of_rentals
FROM (SELECT b.store_id,
             DATE_PART('year', r.rental_date)  AS year,
             DATE_PART('month', r.rental_date) AS month,
             COUNT(rental_id)                  AS num_of_rentals
      FROM rental r
               JOIN staff a
                    ON r.staff_id = a.staff_id
               JOIN store b
                    ON a.store_id = b.store_id
      GROUP BY 1, 2, 3) sub;




/* Query 4 For the top 10 paying customers, what is the difference across their monthly payments during 2007?
           Who paid the most difference in terms of payments? */

WITH t1 AS (SELECT c.first_name || ' ' || c.last_name AS customer,
                   p.customer_id,
                   DATE_PART('year', payment_date)    AS year,
                   DATE_PART('month', payment_date)   AS month,
                   SUM(p.amount)                      AS total_amt_per_month
            FROM customer c
                     JOIN payment p
                          ON c.customer_id = p.customer_id
            GROUP BY 1, 2, 3, 4),

     t2 AS (SELECT p.customer_id,
                   SUM(p.amount) AS total_amount
            FROM customer c
                     JOIN payment p
                          ON c.customer_id = p.customer_id
            GROUP BY 1
            ORDER BY 2 DESC
            LIMIT 10)


SELECT customer,
       year || '-' || month AS year_month,
       t1.total_amt_per_month -
       COALESCE(LAG(t1.total_amt_per_month) OVER (PARTITION BY t1.customer_id ORDER BY t1.total_amt_per_month),
                0)          AS monthly_pay_diff
FROM t1
         JOIN t2
              ON t1.customer_id = t2.customer_id
ORDER BY 1, 2;
