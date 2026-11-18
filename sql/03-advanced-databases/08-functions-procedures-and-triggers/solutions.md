# Solutions - Functions, Procedures & Triggers

## Tier 1

**1.1**
```sql
CREATE OR REPLACE FUNCTION add_numbers(n1 INTEGER, n2 INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN n1 + n2;
END;
$$ LANGUAGE plpgsql;

SELECT add_numbers(10, 7) AS result;   -- 17
```

**1.2**
```sql
CREATE OR REPLACE FUNCTION account_balance(acc_id INTEGER)
RETURNS NUMERIC AS $$
DECLARE
    acc_balance NUMERIC;
BEGIN
    SELECT balance INTO acc_balance FROM account WHERE id = acc_id;
    RETURN acc_balance;              -- NULL when no row was found
END;
$$ LANGUAGE plpgsql;
```

**1.3** `\df`, `\sf add_numbers`, `SELECT account_balance(3);`

## Tier 2

**2.1**
```sql
CREATE OR REPLACE PROCEDURE transfer_funds(from_acc INT, to_acc INT, amount NUMERIC)
AS $$
BEGIN
    UPDATE account SET balance = balance - amount WHERE id = from_acc;
    UPDATE account SET balance = balance + amount WHERE id = to_acc;
END;
$$ LANGUAGE plpgsql;

CALL transfer_funds(1, 2, 30);
```

**2.2**
```sql
CREATE OR REPLACE PROCEDURE transfer_funds(from_acc INT, to_acc INT, amount NUMERIC)
AS $$
BEGIN
    -- deduct from sender
    UPDATE account SET balance = balance - amount WHERE id = from_acc;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sender account:[%] does not exist', from_acc;
    END IF;

    -- make sure the sender still has money after the update
    IF (SELECT balance FROM account WHERE id = from_acc) < 0 THEN
        RAISE EXCEPTION 'Insufficient funds in account[%]', from_acc;
    END IF;

    -- add to receiver
    UPDATE account SET balance = balance + amount WHERE id = to_acc;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Receiver account:[%] does not exist', to_acc;
    END IF;
END;
$$ LANGUAGE plpgsql;

BEGIN; CALL transfer_funds(1, 2, 10); SELECT * FROM account; ROLLBACK;   -- undone
```

**2.3**
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_role (user_id, role)
    VALUES (NEW.id, COALESCE(NEW.signup_role, 'student'));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_app_user_created
AFTER INSERT ON app_user
FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

## Tier 3

**3.1**
```sql
CREATE OR REPLACE FUNCTION create_certificate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.progress = 100 AND NOT EXISTS (
        SELECT 1 FROM certificate
        WHERE course_id = NEW.course_id AND student_id = NEW.student_id
    ) THEN
        INSERT INTO certificate (course_id, student_id) VALUES (NEW.course_id, NEW.student_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER progress_completion_trigger
AFTER UPDATE ON course_enrollment
FOR EACH ROW
WHEN (NEW.progress = 100)
EXECUTE FUNCTION create_certificate();
```

**3.2**
```sql
CREATE OR REPLACE FUNCTION log_balance_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO account_audit (account_id, old_balance, new_balance)
    VALUES (NEW.id, OLD.balance, NEW.balance);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER account_balance_audit
AFTER UPDATE ON account
FOR EACH ROW
WHEN (OLD.balance IS DISTINCT FROM NEW.balance)
EXECUTE FUNCTION log_balance_change();
```

**3.3**
```sql
CREATE OR REPLACE FUNCTION account_history(acc_id INT)
RETURNS TABLE (changed_at TIMESTAMPTZ, old_balance NUMERIC, new_balance NUMERIC) AS $$
    SELECT a.changed_at, a.old_balance, a.new_balance
    FROM account_audit a
    WHERE a.account_id = acc_id
    ORDER BY a.changed_at, a.id;
$$ LANGUAGE sql;

SELECT * FROM account_history(1);
```
