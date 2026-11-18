# 04 · Exercise 2: Tick Trade Marketplace

> Maps to **Database Design & Implementation → Section 5: Exercise 2**
> (open-ended design from a brief, entities and attributes, constraints, CHECK and ENUM, one-to-one, one-to-many, many-to-many, implementing and testing a full schema)

The course's open-ended exercise: design the database for **Tick Trade**, a
platform where people buy and sell products. You start from an empty database
and a product brief, decide the entities, attributes, relationships and
constraints, and implement them. Any design that respects the brief passes: the
grader checks the rules, not your exact SQL, by inserting rows that must be
accepted and rows that must be rejected.

## How to use this set

Open it in the Academy: run `./academy.sh` from the repo root (Windows:
`academy.cmd`), pick **Database Design & Implementation → Exercise 2: Tick Trade
Marketplace** and press `enter`. You land in `psql`, connected to the empty
`ticktrade` database where you build the whole design. Run each query, then save it
with `\w 3.4.sql` (use the question's number). `:questions` shows the questions
again, `:check` grades your work, and `exit` takes you back with your progress
saved. Press `r` in the Academy for a fresh start.

---

## The brief

Tick Trade lets **users** list **products** for sale and buy other people's
products. A product has a name, a description, a price, pictures (**multiple
images**), a **Stripe ID**, a **status** (a draft isn't visible yet; a *listing* is
a product with status `LISTED`) and a **stock level**. Users can **star** products
and leave **reviews**. Every purchase is kept as an **order**, which gives each
user a transaction history (what they bought, and through their products, what
they sold), and every order can have an **invoice**.

## Rules for your design

- Use the **table names** given in each task (the app's code expects them). Name
  the columns as you like, except the ones a task names: the grader finds your
  foreign keys by what they reference, so `seller_id`, `user_id` or
  `application_user_id` are all fine.
- Every table has a **primary key** (`BIGSERIAL`, identity or `UUID`, your call),
  and every relationship is a real **foreign key**.
- Extra columns (`description`, `created_at`, `updated_at`...) are welcome. If you
  add a required column that has a `CHECK`, give it a `DEFAULT` too: the grader
  inserts test rows (in a transaction it rolls back) and fills required columns it
  doesn't know with simple values (text, `1`, `now()`).

## Tier 1 - Users and products *(hint: list each product's attributes, then ask which ones can never be missing or wrong)*

**1.1 (drill)** Sketch the ERD in [diagrams.net](https://app.diagrams.net): the
seven entities below, their attributes, and the crow's-foot cardinality of every
relationship, read in both directions.

**1.2 (graded)** Create `application_user`. Each user has an `email` that is
required and **unique**.

**1.3 (graded)** Create `product`. Every product is sold by exactly **one user**
(a user can sell many products). Required: `name`, `price` (never negative),
`stock_level` (never negative) and `status`, which can only be `'DRAFT'`,
`'LISTED'` or `'ARCHIVED'` (a `CHECK` or an `ENUM` type). `stripe_id` is
**unique**: two products never share one.

## Tier 2 - Images, stars and reviews *(hint: one-to-many or many-to-many? and can the same pair happen twice?)*

**2.1 (graded)** Create `product_image`: a product has zero or many images, each
image belongs to exactly one product, and its URL is required (a `NOT NULL` text
column).

**2.2 (graded)** Create `product_star`: a user can star many products and a
product can be starred by many users, but a user stars a given product **only
once**.

**2.3 (graded)** Create `product_review`: a user reviews a product with a
`rating` that is required and between **1 and 5**. A user can review a given
product **only once** (the review text is optional).

## Tier 3 - Buying and selling *(goal only)*

**3.1 (graded)** Create `product_order`: a user (the buyer) buys a product. Both
are required, `quantity` is required and must be **more than 0**, and the same
buyer can buy the same product **again** later (each purchase is a new order).

**3.2 (graded)** Create `invoice`: **one-to-one** with `product_order`. Every
invoice belongs to exactly one order, and an order has **at most one** invoice.

**3.3 (graded)** Add the data. Users `ama@ticktrade.io`, `kofi@ticktrade.io` and
`zola@ticktrade.io`. Ama sells two `LISTED` products: **Mechanical Keyboard**
(price `89.99`, stock `5`, with **two** images) and **USB-C Hub** (price `34.50`,
stock `10`). Kofi stars the keyboard, buys **1** keyboard and **2** hubs (two
orders) and reviews the keyboard with rating **5**. Zola buys **1** hub. Every
order has an invoice.

**3.4 (graded)** Kofi's purchase history: the `name` and `price` of each product
Kofi bought, with the order's `quantity`, one row per order. Find Kofi by email.
Save it with `\w 3.4.sql`.

## Self-check questions

1. Which of your tables are link tables, and why does `product_order` have its
   own id instead of a composite key of buyer and product?
2. How does a seller see what they sold, when `product_order` only references the
   buyer?
3. Why put `price >= 0` and the status values in the database instead of only in
   the backend code?
4. What makes `invoice` one-to-one with `product_order` rather than one-to-many?
5. If an order doesn't store the price that was paid, what goes wrong in the
   transaction history when a seller changes the product's price?
