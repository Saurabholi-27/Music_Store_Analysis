/* Who is the senior most employee based on job title?  */

select employee_id , first_name , last_name , levels From employee
Order by levels Desc
Limit 1


/* Which countries has the most invoice */

Select billing_country , Count(billing_country) As total_invoice 
From invoice
Group by billing_country
Order by total_invoice Desc


/* What are top 3 values of total invoice? */

Select invoice_id , total From invoice
Order by total Desc
Limit 3

/* Which city has the best customer? We would like to throw a promotional Music Festival in the city 
   we made the most money. Write a query that returns one city that has the most highest sum of invoice 
   totals.Return both the city name and the sum of all invoice totals. */

Select Sum(total) As invoice_total , billing_city 
From invoice 
Group by billing_city
Order by invoice_total Desc
Limit 1


/* Who is the best customer? The customer who has spent the most moneny will be declared as the best 
   customer. Write a query that returns the person who has spent the most money. */
   
Select customer.customer_id,first_name , last_name, Sum(total) As invoice_total From customer
Join invoice
On customer.customer_id = invoice.customer_id
Group by customer.customer_id
Order by invoice_total Desc
Limit 1


/* Write query to return the email, first name, last name and genre of all Rock Music listeners.
   Return your list ordered alphabetically by email starting with A */
 
Select Distinct email, first_name, last_name 
From customer
Join invoice On customer.customer_id = invoice.customer_id
Join invoice_line On invoice.invoice_id = invoice_line.invoice_id
Where track_id In(
	Select track_id From track
	Join genre
	On track.genre_id = genre.genre_id
	Where genre.name Like 'Rock'
)
Order by email


/* Let's invite the artist who have written the most rock music in our dataset. Write a query that
   returns the Artist name and the total track count of the top 10 rock bands. */
   
SELECT artist.name , COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id
ORDER BY number_of_songs DESC
LIMIT 10

/* Return all the tracks names that have a song length longer than the average song length. Return
   the name and milliseconds for each track. Order by the song length wit the longest songs list first  */
  
SELECT name, milliseconds 
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track)
ORDER BY milliseconds DESC


/* Find how much amount spent by each customer on artist? Write a query to return customer name, artist
   name and total spent  */
   
WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.name AS artist_name,
	SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name,
SUM(il.unit_price*il.quantity) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC


/* We want to find out the most popular music genre for each country (We determine the most popular genre 
   with the highest amount of purchases)  */

-- Method 1
WITH popular_genre AS
(
	SELECT COUNT(invoice_line.quantity) AS purchase, customer.country, genre.name, genre.genre_id,
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo
	FROM invoice_line
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

-- Method 2
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.*
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number


/* Write a query that determines the customer that has spent the most on music for each country. 
   Write a query that returns the country along with the top customer and how much they spent. 
   For countries where the top amount spent is shared, provide all customers who spent this amount */
   
-- Method 1
WITH Customer_with_country AS (
		SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
		ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC, 5 DESC)
SELECT * FROM Customer_with_Country WHERE RowNo <= 1

--Method 2
WITH RECURSIVE
	customer_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,SUM(total) AS total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 1,5 DESC),
		
	country_max_spending AS(
		SELECT billing_country,MAX(total_spending) AS max_spending
		FROM customer_with_Country
		GROUP BY billing_country)
		
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.customer_id
FROM customer_with_country cc
JOIN country_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1