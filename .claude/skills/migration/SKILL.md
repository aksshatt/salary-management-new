---
name: migration
description: Rules for writing any database migration in this repo. Use whenever a change adds or alters a table, column, index or constraint, even if the user doesn't name the skill.
---

# Migration

## Before writing
- Check `db/schema.rb` for what already exists. Don't add a duplicate column or index.
- Include the migration in the plan from the `build` skill and wait for my ok.

## Rules
- Money: `decimal, precision: 12, scale: 2`, never `float`.
- `null: false` on every column that the model validates as present.
- Foreign keys with `foreign_key: true`, and an index on every foreign key.
- Index every column used for filtering or search (country, department, job title, status dates).
- Unique indexes that back uniqueness rules (e.g. payroll run month, employee code, one revision per employee per effective date).
- Check constraints for simple rules the DB can enforce (e.g. amounts between 0 and 1,000,000,000).
- Use `change` so it's reversible. If it can't be, write `up`/`down` and tell me why.
- No data changes mixed into schema migrations.

## Check
1. `bin/rails db:migrate`, then `bin/rails db:rollback`, then `bin/rails db:migrate` again. All must succeed.
2. Make sure `db/schema.rb` changed only as expected.
3. Add model specs that prove each constraint holds at the DB level (e.g. `insert` bypassing validations raises).
