DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

Select * From spotify;

--EDA

SELECT COUNT(*) FROM Spotify;

SELECT COUNT(DISTINCT artist) FROM spotify;

SELECT COUNT(DISTINCT album) FROM spotify;

SELECT DISTINCT album_type FROM spotify;

SELECT MAX(duration_min) FROM spotify;

SELECT MIN(duration_min) FROM spotify;

SELECT * FROM spotify
WHERE duration_min=0;

DELETE from spotify
WHERE duration_min=0;

SELECT DISTINCT channel FROM spotify;

SELECT DISTINCT most_played_on FROM spotify;

-- ----------------------------
--Data Analysis - Easy Category
-- ----------------------------

--1. Retrieve the names of all tracks that have more than 1 billion streams.

SELECT * FROM spotify
WHERE stream>1000000000;

--2. List all albums along with their respective artists.

SELECT DISTINCT album, artist 
FROM spotify;

--3. Get the total number of comments for tracks where licensed = TRUE.

SELECT SUM(comments) as Total_Comments FROM spotify
WHERE licensed=TRUE;

--4. Find all tracks that belong to the album type single.

SELECT DISTINCT track
FROM spotify
WHERE album_type='single';

--5. Count the total number of tracks by each artist.

SELECT artist, COUNT(track) as Total_tracks
FROM spotify
GROUP BY artist
ORDER BY 2 DESC;

-- ------------------------------
--Data Analysis - Medium Category
-- ------------------------------

--1. Calculate the average danceability of tracks in each album.

SELECT album, AVG(danceability) AS avg_danceability
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;

--2. Find the top 5 tracks with the highest energy values.

SELECT track, MAX(energy)
FROM spotify
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

--3. List all tracks along with their views and likes where official_video = TRUE.

SELECT track, 
	SUM(views) as Total_views, 
	SUM(likes) as Total_likes
FROM spotify
WHERE official_video=TRUE
GROUP BY 1
ORDER BY 2 DESC;

--4. For each album, calculate the total views of all associated tracks.

SELECT album,track, 
	SUM(views) as Total_views
FROM spotify
GROUP BY 1, 2
ORDER BY 3 DESC;

--5. Retrieve the track names that have been streamed on Spotify more than YouTube.

SELECT * FROM (
SELECT track,
	COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) as Streamed_on_spotify,
	COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) as Streamed_on_youtube
FROM spotify
GROUP BY 1) AS T1
WHERE
	Streamed_on_spotify > Streamed_on_youtube
	AND
	Streamed_on_youtube<>0;

-- ------------------------------
--Data Analysis - Advance Category
-- ------------------------------

--1. Find the top 3 most-viewed tracks for each artist using window functions.

WITH artist_rank
AS(
SELECT artist, track, SUM(views) as total_view,
	DENSE_RANK() OVER (PARTITION BY artist ORDER BY SUM(views) DESC) as rank
FROM spotify
GROUP BY 1,2
ORDER BY 1,3 DESC
)
SELECT * FROM artist_rank
WHERE rank<=3;

--2. Write a query to find tracks where the liveness score is above the average.

SELECT track, liveness FROM spotify
WHERE liveness>(SELECT AVG(liveness) FROM spotify)
GROUP BY 1,2
ORDER BY liveness DESC;

--3. Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.

WITH Diff_energy_values
AS(
SELECT album,
	MAX(energy) as Highest_energy_values,
	MIN(energy) as Lowest_energy_values
FROM spotify
GROUP BY 1) 

SELECT *, Highest_energy_values - Lowest_energy_values AS energy_diff 
FROM Diff_energy_values
ORDER BY 2 DESC;

--4. Find tracks where the energy-to-liveness ratio is greater than 1.2

SELECT DISTINCT track, energy/liveness as energy_liveness_ratio
FROM spotify
WHERE (energy/liveness)> 1.2
ORDER BY energy_liveness_ratio DESC ;

--5. Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.

WITH track_details
AS(
SELECT track,
	SUM(views) AS total_views,
	SUM(likes) AS total_likes
FROM spotify
GROUP BY 1)

SELECT track, total_views, total_likes,
	SUM(total_likes) OVER (ORDER BY total_views DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cumulative_sum
FROM track_details;
	
EXPLAIN ANALYZE -- Exe Time - 3.786, After creating index - 0.314
SELECT artist, track, most_played_on views FROM spotify
WHERE artist='Gorillaz'
ORDER BY stream DESC
LIMIT 5;

CREATE INDEX artist_index ON spotify(artist);
	