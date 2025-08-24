WITH all_operations AS (
    SELECT
        t.id,
        p.name AS psp_name,
        pc.bin_country,
        'transaction'::text AS operation_type,
        t.status,
        t.amount
    FROM transactions t
    JOIN psp p ON t.psp_id = p.id
    JOIN payment_credentials pc ON t.payment_credentials_id = pc.id

    UNION ALL

    SELECT
        r.id,
        p.name AS psp_name,
        pc.bin_country,
        'refund'::text AS operation_type,
        'refund'::text AS status,
        r.amount
    FROM refunds r
    JOIN transactions t ON r.transaction_id = t.id
    JOIN psp p ON t.psp_id = p.id
    JOIN payment_credentials pc ON t.payment_credentials_id = pc.id

    UNION ALL

    SELECT
        c.id,
        p.name AS psp_name,
        pc.bin_country,
        'chargeback'::text AS operation_type,
        'chargeback'::text AS status,
        c.amount
    FROM chargebacks c
    JOIN transactions t ON c.transaction_id = t.id
    JOIN psp p ON t.psp_id = p.id
    JOIN payment_credentials pc ON t.payment_credentials_id = pc.id
)

SELECT
    psp_name,
    bin_country,
    operation_type,
    status,
    COUNT(*) AS transaction_count,
    ROUND(AVG(amount), 2) AS avg_amount,
    ROUND(SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END)::numeric / COUNT(*), 2) AS success_ratio,
    ROUND(SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)::numeric / COUNT(*), 2) AS failed_ratio,
    ROUND(SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END)::numeric / COUNT(*), 2) AS pending_ratio
FROM all_operations
GROUP BY psp_name, bin_country, operation_type, status
ORDER BY psp_name, bin_country, operation_type, status;
