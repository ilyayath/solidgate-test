WITH success_rates AS (
    SELECT 
        p.name AS psp_name,
        pc.bin_country,
        COUNT(*) AS total_transactions,
        SUM(CASE WHEN t.status = 'success' THEN 1 ELSE 0 END) AS success_transactions,
        CASE 
            WHEN COUNT(*) > 0 
            THEN SUM(CASE WHEN t.status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) 
            ELSE 0 
        END AS success_share
    FROM transactions t
    JOIN psp p ON t.psp_id = p.id
    JOIN payment_credentials pc ON t.payment_credentials_id = pc.id
    GROUP BY p.name, pc.bin_country
),
ranked_psp AS (
    SELECT 
        psp_name,
        bin_country,
        success_share,
        RANK() OVER (PARTITION BY bin_country ORDER BY success_share DESC) AS rank
    FROM success_rates
)
SELECT 
    psp_name,
    bin_country,
    ROUND(success_share, 2) AS success_share,
    rank AS ranking
FROM ranked_psp
WHERE rank <= 3
ORDER BY bin_country, rank;