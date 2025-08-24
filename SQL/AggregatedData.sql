WITH all_operations AS (

    SELECT
        t.psp_id,
        t.payment_credentials_id,
        t.status,
        t.amount * c.rate_to_usd AS amount_usd,
        'Payment' AS operation_type
    FROM transactions t
    JOIN currencies c ON t.currency_id = c.id

    UNION ALL

    SELECT
        t.psp_id,
        t.payment_credentials_id,
        'Refunded' AS status,
        r.amount * c.rate_to_usd AS amount_usd,
        'Refund' AS operation_type
    FROM refunds r
    JOIN transactions t ON r.transaction_id = t.id
    JOIN currencies c ON r.currency_id = c.id

    UNION ALL

    SELECT
        t.psp_id,
        t.payment_credentials_id,
        'Chargebacked' AS status,
        cb.amount * c.rate_to_usd AS amount_usd,
        'Chargeback' AS operation_type
    FROM chargebacks cb
    JOIN transactions t ON cb.transaction_id = t.id
    JOIN currencies c ON cb.currency_id = c.id
)
SELECT
    p.name AS psp_name,                                 
    pc.bin_country,                                     
    ao.operation_type,                                  
    COUNT(*) AS transaction_count,                     
    ROUND(AVG(ao.amount_usd), 2) AS average_amount_usd, 

    CASE WHEN ao.operation_type = 'Payment'
         THEN ROUND(SUM(CASE WHEN ao.status = 'success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
    END AS successful_pct,
    CASE WHEN ao.operation_type = 'Payment'
         THEN ROUND(SUM(CASE WHEN ao.status = 'failed' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
    END AS failed_pct,
    CASE WHEN ao.operation_type = 'Payment'
         THEN ROUND(SUM(CASE WHEN ao.status = 'pending' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
    END AS pending_pct
FROM all_operations ao
JOIN psp p ON ao.psp_id = p.id
JOIN payment_credentials pc ON ao.payment_credentials_id = pc.id
GROUP BY p.name, pc.bin_country, ao.operation_type
ORDER BY psp_name, bin_country;
