# rls_rails
Row Level Security for Ruby on Rails.

Row Level Security (RLS) is a feature of PostgreSQL
(see [PG Docs: About RLS](https://www.postgresql.org/docs/current/static/ddl-rowsecurity.html) and
[PG Docs: CREATE POLICY](https://www.postgresql.org/docs/current/static/sql-createpolicy.html))
that allows you to define rules to check whether SELECT, INSERT, UPDATE or
DELETEs are accessing or creating legitimate rows.

RLS gives your application a second line of defense when isolating data in 
a multi-user application. A mistake in the rapidly changing application code 
may easily leak data or introduce severe security threads. With RLS PostgreSQL
always double checks whether the data going in or out complies with the defined policies.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'rls_rails', github: 'sbiastoch/rls_rails'
```

And then execute:
```bash
$ bundle install
$ rails rls_rails:install
```

The latter command will create a migration that sets up two PostgreSQL User-Defined Functions (UDFs) that are usefull
when using policies: `current_tenant_id()` telling the current tenant_id as BIGINT and `rls_disabled` returning TRUE
when RLS was disabled by `SET rls.disable TO TRUE`, otherwise FALSE.

If you are already using RLS and have some policies within your `db/structure.sql` 
you can use `rails rls_rails:init` to populate `db/policies` with the current policies rewirtten in our own DSL. Note that 
this currently works only for simple USING and CHECK policies without any other modifiers.

## Usage
### Policy Definition
```ruby
RLS.policies_for :accounts do
  policy :my_policy do
    restrictive           # AS-part of policy, permissive is default
    on :select, :update   # FOR-part of policy, default is :all
    to :psql_user         # TO-part of policy, default is :public
    
    using <<-SQL
      -- USING-part goes here
    SQL
    
    check <<-SQL
      -- CHECK-part goes here
    SQL
  end
  
  policy :another_policy do
    # ...
  end
end
```

### Setting tenants

* `RLS.disable!` Turns off RLS (does not reset the current tenant)
* `RLS.enable!` Turns on RLS
* `RLS.set_tenant(tenant)` Sets the current tenant
* `RLS.disable_for_block { ... }` Disable RLS for the given block
* `RLS.set_tenant_for_block(tenant) { ... }` Run a block as a given tenant
* `RLS.run_per_tenant { |tenant| ... }` Run a block once for each existing tenant
* `RLS.enabled?` Returns true if RLS is not manually disabled
* `RLS.disabled?` Returns true if RLS is manually disabled
* `RLS.status` Returns the current status of RLS: `{tenant_id: <current_tenant_id>, disable_rls: <rls_disabled>}`
* `RLS.reset!` Resets the current RLS setting (tenant_id + rls_disabled)
* `RLS.current_tenant` Returns the object of the current tenant
* `RLS.current_tenant_id` Returns the id of the current tenant


By default all policies can be "disabled" by setting `rls.disable` to true. 
If you wish to prevent this behaviour you can do 
`RLS.policies_for :table, disableable: false do ...`


### Shorthands
There are some shorthands you can use to define a policy that follows a common pattern:

#### Use `tenant_id` to check whether a row is accessible by the current tenant
```ruby
RLS.policies_for :users do
  using_tenant
end
```

#### Allow access if a a relation via belongs_to is accessible
```ruby
RLS.policies_for :posts do
  using_relation :topic
end
```

#### Allow access if _all_ of the given relations are accessible
```ruby
RLS.policies_for :abbonements do
  using_relations :user, :topic                    # foreign keys are guessed
  using_relations user: User, topic: Topic         # Explicit relation classes, FK is obtained via `table_name`
  using_relations user: :user_id, topic: :topic_id # explicit foreign keys
end
```

#### Allow access if there is a join partner in the other table with the current tenant id
```ruby
RLS.policies_for :abbonements do
  using_table :level_memberships, match: :level_id # primary key = foreign key
  using_table :level_memberships, primary_key: :level_id, foreign_key: :level_id, tenant_id: :tenant_id
end
```

## Enabling and disabling RLS
By default, the owner of a table is not affected by RLS. As migrations create tables, it will
also be owner of the table, rendering RLS useless when not maintaining multiple 
database-users and connection. This is cumbersome, therefore RLS is forced so that the owner
is affected as well by the policies and RLS is controlled by an session-variable.
Two PostgreSQL  functions are created to handle RLS: `current_tenant_id()` which 
returns the id of the current  tenant set by `SET rls.tenant_id = 42;` or `NULL` if unset.
The other function is `rls_disabled()` that returns `TRUE` if `SET c2.rls_disabled = TRUE` 
is set. If unset or set to `FALSE`, it returns `FALSE`. These variables are set on a 
connection level.


## Recursive policies
If a policy requires a direct or indirect self-join, you cannot use native RLS.
Self-referential (ie. "recursive") policies are not possible.

The standard alternate approach (that was used to simulate RLS before PostgreSQL 9.5) 
is to use an  automatically updateable view 
([PG Docs: Updateable Views](https://www.postgresql.org/docs/current/static/sql-createview.html#SQL-CREATEVIEW-UPDATABLE-VIEWS)
) that filters out those rows that are not permissible to view for the given tenant. 
By `WITH CHECK CASCADE` on the view it is enforced that no rows are modified that does 
not meet the view-conditions. The `security_barrier` flag tells PostgreSQL, that it has to
take special measures to prevent a malicious function leaking data while filtering. For more
information about `security_barrier` see 
[PG Docs: Rules and Privileges](https://www.postgresql.org/docs/current/static/rules-privileges.html).

If you wondering if there are currently any tables without policies, you can check by
`SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND NOT rowsecurity`.


## Future Work

To further secure RLS it is possible to use a 
[signing mechanism](https://blog.2ndquadrant.com/application-users-vs-row-level-security),
which mitigates attacks via SQL-injections. Currently, the attacker could disable RLS by a 
SQL injection and query all data. If the session variables for RLS are signed, the 
attacker needs also access to a secret on another system.

## License
Development of this gem was funded by [suus](https://suus.io). 
Strongly inspired by [scenic](https://github.com/scenic-views/scenic) which is a very good companion to rls_rails!

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
