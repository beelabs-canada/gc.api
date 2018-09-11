-- =================
-- = CATEGORY TABLE
---= @version 1.0
-- =================
CREATE TABLE categories ( 
    id VARCHAR(64), /* SHA256 for URL */
    lang VARCHAR(3),
    label VARCHAR(255),
    slug VARCHAR(255)
);