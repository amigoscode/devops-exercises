# Solutions - Exercise 2: Tick Trade Marketplace

Solutions may vary - this one follows the course's (UUID keys, ENUM types,
`TIMESTAMPTZ`), extended with the brief's images, stars, reviews and invoices. A
design with `BIGSERIAL` ids, `CHECK` instead of `ENUM`, or other column names
passes just the same. Run it in `psql` (the Academy connects you to the `ticktrade` database).
`gen_random_uuid()` is built into PostgreSQL 13+; the course's `uuid-ossp`
extension works too.

## Tier 1 - Users and products

**1.1** Drill: `application_user` *one and only one* → `product` *zero or many*
(sells); `product` *one and only one* → `product_image` *zero or many*;
`application_user` and `product` *one and only one* → `product_star`,
`product_review`, `product_order` *zero or many*; `product_order` *one and only
one* → `invoice` *zero or one*.

**1.2**
```sql
CREATE TABLE IF NOT EXISTS application_user (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL DEFAULT '',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**1.3**
```sql
CREATE TYPE product_status AS ENUM ('DRAFT', 'LISTED', 'ARCHIVED');

CREATE TABLE IF NOT EXISTS product (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_user_id UUID NOT NULL REFERENCES application_user (id),   -- the seller
    name                TEXT NOT NULL CHECK (char_length(name) > 1),
    description         TEXT,
    price               NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    stock_level         INT NOT NULL DEFAULT 0 CHECK (stock_level >= 0),
    stripe_id           TEXT UNIQUE,
    status              product_status NOT NULL DEFAULT 'DRAFT',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

## Tier 2 - Images, stars and reviews

**2.1** One-to-many:
```sql
CREATE TABLE IF NOT EXISTS product_image (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES product (id),
    url        TEXT NOT NULL,
    position   INT NOT NULL DEFAULT 0
);
```

**2.2** Many-to-many link table, composite key:
```sql
CREATE TABLE IF NOT EXISTS product_star (
    application_user_id UUID NOT NULL REFERENCES application_user (id),
    product_id          UUID NOT NULL REFERENCES product (id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (application_user_id, product_id)
);
```

**2.3** Its own id plus a unique pair (both styles are fine):
```sql
CREATE TABLE IF NOT EXISTS product_review (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_user_id UUID NOT NULL REFERENCES application_user (id),
    product_id          UUID NOT NULL REFERENCES product (id),
    rating              INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    body                TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (application_user_id, product_id)
);
```

## Tier 3 - Buying and selling

**3.1** Its own id: the same buyer can order the same product again.
```sql
CREATE TYPE payment_status AS ENUM ('PENDING', 'COMPLETED', 'FAILED');

CREATE TABLE IF NOT EXISTS product_order (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_user_id UUID NOT NULL REFERENCES application_user (id),   -- the buyer
    product_id          UUID NOT NULL REFERENCES product (id),
    quantity            INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    total_amount        NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
    payment_status      payment_status NOT NULL DEFAULT 'PENDING',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**3.2** One-to-one: a NOT NULL **and UNIQUE** foreign key (or make it the primary key).
```sql
CREATE TABLE IF NOT EXISTS invoice (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_order_id UUID NOT NULL UNIQUE REFERENCES product_order (id),
    issued_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**3.3** Look the ids up with sub-selects instead of copying UUIDs around:
```sql
INSERT INTO application_user (email) VALUES
  ('ama@ticktrade.io'), ('kofi@ticktrade.io'), ('zola@ticktrade.io');

INSERT INTO product (application_user_id, name, price, stock_level, stripe_id, status)
SELECT id, 'Mechanical Keyboard', 89.99, 5, 'prod_kb001', 'LISTED' FROM application_user WHERE email = 'ama@ticktrade.io';
INSERT INTO product (application_user_id, name, price, stock_level, stripe_id, status)
SELECT id, 'USB-C Hub', 34.50, 10, 'prod_hub001', 'LISTED' FROM application_user WHERE email = 'ama@ticktrade.io';

INSERT INTO product_image (product_id, url, position)
SELECT id, 'https://img.ticktrade.io/kb-' || n || '.jpg', n
FROM product, generate_series(1, 2) AS n WHERE name = 'Mechanical Keyboard';

INSERT INTO product_star (application_user_id, product_id)
SELECT u.id, p.id FROM application_user u, product p
WHERE u.email = 'kofi@ticktrade.io' AND p.name = 'Mechanical Keyboard';

INSERT INTO product_review (application_user_id, product_id, rating, body)
SELECT u.id, p.id, 5, 'Great keys!' FROM application_user u, product p
WHERE u.email = 'kofi@ticktrade.io' AND p.name = 'Mechanical Keyboard';

INSERT INTO product_order (application_user_id, product_id, quantity, total_amount)
SELECT u.id, p.id, o.qty, o.qty * p.price
FROM (VALUES ('kofi@ticktrade.io', 'Mechanical Keyboard', 1),
             ('kofi@ticktrade.io', 'USB-C Hub', 2),
             ('zola@ticktrade.io', 'USB-C Hub', 1)) AS o (email, product, qty)
JOIN application_user u ON u.email = o.email
JOIN product p ON p.name = o.product;

INSERT INTO invoice (product_order_id) SELECT id FROM product_order;
```

**3.4**
```sql
SELECT p.name, p.price, o.quantity
FROM product_order o
JOIN product p ON p.id = o.product_id
JOIN application_user u ON u.id = o.application_user_id
WHERE u.email = 'kofi@ticktrade.io';
```
then `\w 3.4.sql`.
