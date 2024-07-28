-- Retrieve information of user activity showing up more than once in activity
SELECT uid , COUNT(*) AS activity_count
FROM activity
GROUP BY uid
ORDER BY activity_count DESC


-- Joining users and activity table to track users that made purchase
 SELECT id ,COALESCE(spent,0)
 FROM users AS u
 LEFT JOIN activity AS a
 	ON 	u.id = a.uid; 



--Retrieve the start date and end dates of the experiment 
SELECT MAX(join_dt) , MIN (join_dt)
FROM groups;

-- Retrieve counts on all the total users involved in the experiment. Answer : Total number of users involved in the A/B test = 48943
SELECT COUNT(id) AS total_users 
FROM users; 

-- Retrieve the information of how many users were in either the control(A) : Answer : 24343
SELECT COUNT("group") AS control_count_A
FROM groups
WHERE "group" = 'A';


-- Retrieve the information of how many users were in the treatment group(B) : Answer : 24600
SELECT COUNT("group") AS treatment_count_B
FROM groups
WHERE "group" = 'B';

SELECT "group", COUNT (*)
FROM groups
GROUP BY "group";

--  Conversion rate of all the users. NOTE : '2022-04-06' represents null dates values : Conversion rate = 4.28
WITH cte_user_purchases AS (
SELECT id,COALESCE(spent,0) AS amount_spent,COALESCE(dt,'2022-04-06') AS date_purchased,"group" AS test_group
FROM users AS u 
LEFT JOIN activity AS a 
	ON u.id = a.uid
LEFT JOIN groups as g
	ON u.id = g.uid
),
cte_user_converted AS (
  SELECT id,SUM(amount_spent) AS total_amount_spent,
  CASE WHEN SUM(amount_spent) > 0 THEN 1
  ELSE 0
  END AS user_converted
  FROM cte_user_purchases
  GROUP BY id
  )
  
SELECT ROUND(AVG(user_converted)*100,2)
FROM cte_user_converted;
--ORDER BY user_converted DESC


--Retrieve all information for all users from either control group or treatment group . Conversion rate of control group(A): 3.92 & treatment group : 4.63
WITH cte_user_purchase AS (
  SELECT id, "group", COALESCE(spent,0) AS amount_spent
  FROM users as u 
  LEFT JOIN groups AS g 
  	ON u.id = g.uid
  LEFT JOIN activity as a
  	ON u.id =a.uid
  ),
  cte_user_converted AS (
    SELECT id, "group", SUM(amount_spent),
    CASE WHEN SUM(amount_spent) > 0 THEN 1 
    ELSE 0
    END AS user_converted 
    FROM cte_user_purchase
    GROUP BY id,"group" 
  )
  SELECT "group", ROUND(AVG(user_converted)*100,2) 
  FROM cte_user_converted
  GROUP BY "group";
  
  -- Retrieve information on the average amount spent per user for the control groups and treatment groups including non-converted users 
  WITH cte_user_purchase AS (
  SELECT id, "group", COALESCE(spent,0) AS amount_spent
  FROM users as u 
  LEFT JOIN groups AS g 
  	ON u.id = g.uid
  LEFT JOIN activity as a
  	ON u.id =a.uid
  ),
  cte_user_converted AS (
    SELECT id, "group", SUM(amount_spent),
    CASE WHEN SUM(amount_spent) > 0 THEN 1 
    ELSE 0
    END AS user_converted 
    FROM cte_user_purchase
    GROUP BY id,"group" 
  )
  SELECT id,"group", ROUND(AVG(user_converted)*100,2) AS average_user_conversion,ROUND(AVG(user_converted),2) AS average_per_user
  FROM cte_user_converted
  GROUP BY id,"group"
  --ORDER BY round DESC;
  
  -- Trial and Error --
  SELECT "group", COALESCE(ROUND(AVG(spent),2),0) average_amount_spent
  FROM users as u 
  LEFT JOIN groups AS g 
  	ON u.id = g.uid
  LEFT JOIN activity as a
  	ON u.id =a.uid
  WHERE "group" = 'A'
  	OR "group" = 'B'
 GROUP BY "group"                              
 ORDER BY average_amount_spent DESC;                              
 
 
 -- Extracting the analysis dataset 
WITH cte_purchase_group AS (
SELECT a.uid,COUNT(a.uid) AS activity_count,id,COALESCE(country,'AAA') AS country,COALESCE(gender,'X') AS gender,COALESCE(g.device,'W') AS device,"group",COALESCE(ROUND(AVG(spent),2),0) AS spent
FROM users as u
INNER JOIN groups as g
	ON u.id = g.uid
LEFT JOIN activity as a 
 ON g.uid = a.uid
--WHERE spent > 0
GROUP BY "group",a.uid,u.id,g.device
),
cte_converted_group AS (
  SELECT id,country,activity_count,"group",spent,device,gender,
  CASE WHEN "group" = 'A' THEN 'control_group'
  	WHEN "group" = 'B' THEN 'treatment_group'
  	ELSE 'non-participant' END AS test_group
  FROM cte_purchase_group
  )
  SELECT id,activity_count,"group",country,gender,device,spent
  FROM cte_converted_group
  GROUP BY id,activity_count,"group",spent,device,gender,country,test_group
  ORDER BY "group" ASC;
 
 -- Grouping amount spent between the two groups 

SELECT u.id AS id,COALESCE(u.country,'AAA') AS country,COALESCE(u.gender,'X') AS gender,COALESCE(g.device,'W') AS device,g.group AS "group",SUM(COALESCE(spent,0)) AS spent,
CASE WHEN COALESCE(SUM(a.spent), 0) > 0 THEN 1 ELSE 0 END AS conversion_status
FROM users as u
INNER JOIN groups as g
	ON u.id = g.uid
LEFT JOIN activity as a 
 ON u.id = a.uid
GROUP BY "group",id,g.device,country,gender
ORDER BY "group" ASC;
