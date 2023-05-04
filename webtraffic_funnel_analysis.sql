WITH first_five_pages AS (
  SELECT
    CONCAT(user_pseudo_id, "-", CAST(event_timestamp AS string)) AS sessionId,
    (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec') AS hitNumber,
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location') AS landing_page,
    LEAD((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location')) 
      OVER (PARTITION BY user_pseudo_id, event_timestamp ORDER BY (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS second_page,
    LEAD((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), 2) 
      OVER (PARTITION BY user_pseudo_id, event_timestamp ORDER BY (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS third_page,
    LEAD((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), 3) 
      OVER (PARTITION BY user_pseudo_id, event_timestamp ORDER BY (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS fourth_page,
    LEAD((SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'page_location'), 4) 
      OVER (PARTITION BY user_pseudo_id, event_timestamp ORDER BY (SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'engagement_time_msec')) AS fifth_page,
    CONCAT(traffic_source.source, " / ", traffic_source.medium) AS source_medium
  FROM
    `your-project-id.your-dataset.table-name`
  WHERE
    event_name = 'page_view'
),

FILTER AS (
  SELECT *
  FROM first_five_pages
  WHERE hitNumber = 1
  AND REGEXP_CONTAINS(source_medium, 'referral')
)
SELECT landing_page, second_page, third_page, fourth_page, fifth_page,
  COUNT(sessionId) AS Sessions,
  ROUND(COUNT(sessionId) / SUM(COUNT(sessionId)) OVER (), 2) AS Percentage_of_Sessions
FROM FILTER
GROUP BY 1, 2, 3, 4, 5
ORDER BY 6 DESC;