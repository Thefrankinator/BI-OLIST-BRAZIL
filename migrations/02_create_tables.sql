USE olist_dw;
GO

-- =========================================================
-- DIMENSIONS
-- =========================================================

CREATE TABLE dim_customers (
    id              INT IDENTITY(1,1)  NOT NULL PRIMARY KEY,
    customer_id     NVARCHAR(32)        NOT NULL UNIQUE,
    customer_city   NVARCHAR(100)       NOT NULL,
    customer_state  NVARCHAR(2)         NOT NULL
);
GO

CREATE TABLE dim_seller (
    id            INT IDENTITY(1,1)  NOT NULL PRIMARY KEY,
    seller_id     NVARCHAR(32)        NOT NULL UNIQUE,
    seller_state  NVARCHAR(2)         NOT NULL
);
GO

CREATE TABLE dim_products (
    id                INT IDENTITY(1,1)  NOT NULL PRIMARY KEY,
    product_id        NVARCHAR(32)        NOT NULL UNIQUE,
    product_weight_g  INT                 NULL
);
GO

CREATE TABLE dim_date (
    date_id        INT       NOT NULL PRIMARY KEY,  -- format YYYYMMDD
    complete_date  DATE      NOT NULL,
    years          SMALLINT  NOT NULL,
    quarters       TINYINT   NOT NULL,
    months         TINYINT   NOT NULL,
    day_week       TINYINT   NOT NULL                -- 1 = lundi ... 7 = dimanche
);
GO

-- =========================================================
-- FAITS
-- =========================================================

CREATE TABLE fact_order_items (
    id                     INT IDENTITY(1,1)  NOT NULL PRIMARY KEY,
    order_id               NVARCHAR(32)        NOT NULL,
    ordered_items          INT                 NOT NULL,   -- numéro de ligne dans la commande
    product_key            INT                 NOT NULL,   -- FK -> dim_products.id
    customer_key           INT                 NOT NULL,   -- FK -> dim_customers.id
    seller_key             INT                 NOT NULL,   -- FK -> dim_seller.id
    date_order_achat_id    INT                 NOT NULL,   -- FK -> dim_date.date_id (achat)
    date_order_del_cust_id INT                 NULL,        -- FK -> dim_date.date_id (livraison, nullable)
    date_order_est_id      INT                 NOT NULL,   -- FK -> dim_date.date_id (estimée)
    total_order_items      INT                 NOT NULL,
    total_freight_value    DECIMAL(10,2)       NOT NULL,
    total_price             DECIMAL(10,2)       NOT NULL,
    delays                   INT                 NULL,

    CONSTRAINT UQ_fact_order_items UNIQUE (order_id, ordered_items),

    CONSTRAINT FK_foi_product    FOREIGN KEY (product_key)             REFERENCES dim_products(id),
    CONSTRAINT FK_foi_customer   FOREIGN KEY (customer_key)            REFERENCES dim_customers(id),
    CONSTRAINT FK_foi_seller     FOREIGN KEY (seller_key)              REFERENCES dim_seller(id),
    CONSTRAINT FK_foi_date_achat FOREIGN KEY (date_order_achat_id)     REFERENCES dim_date(date_id),
    CONSTRAINT FK_foi_date_del   FOREIGN KEY (date_order_del_cust_id)  REFERENCES dim_date(date_id),
    CONSTRAINT FK_foi_date_est   FOREIGN KEY (date_order_est_id)       REFERENCES dim_date(date_id)
);
GO


