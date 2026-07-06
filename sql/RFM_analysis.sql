CREATE OR REPLACE VIEW customer_rfm_segments AS
WITH analysis_date AS (
    SELECT 
        DATE_ADD(MAX(DATE(invoice_date)), INTERVAL 1 DAY) AS snapshot_date
    FROM invoices
),

rfm_base AS (
    SELECT
        i.customer_id,

        MAX(DATE(i.invoice_date)) AS last_purchase_date,

        DATEDIFF(
            ad.snapshot_date,
            MAX(DATE(i.invoice_date))
        ) AS recency_days,

        COUNT(DISTINCT i.Invoice) AS frequency,

        ROUND(SUM(i.Quantity * i.Price), 2) AS monetary

    FROM invoices as i
    CROSS JOIN analysis_date ad
    GROUP BY i.customer_id, ad.snapshot_date
),


rfm_scores AS (
    SELECT
        customer_id,
        last_purchase_date,
        recency_days,
        frequency,
        monetary,

        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,

        NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
       
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score

    FROM rfm_base
)

-- Step 4: Assign customer segments
SELECT
    customer_id,
    last_purchase_date,
    recency_days,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,

    recency_score + frequency_score + monetary_score AS total_rfm_score,
    CONCAT(recency_score, frequency_score, monetary_score) AS rfm_code,

    CASE
        WHEN recency_score >= 4 
             AND frequency_score >= 4 
             AND monetary_score >= 4
            THEN 'High-Value'

        WHEN recency_score >= 4 
             AND frequency_score >= 4
            THEN 'Loyal'

        WHEN recency_score <= 2 
             AND frequency_score >= 4
             AND monetary_score >= 3
            THEN 'At-Risk'

        WHEN recency_score <= 2 
             AND frequency_score <= 2
            THEN 'Inactive'

        WHEN recency_score >= 3 
             AND frequency_score <= 2 
             AND monetary_score >= 3
            THEN 'Opportunity'

        ELSE 'Standard Customers'
    END AS customer_segment

FROM rfm_scores;
  

