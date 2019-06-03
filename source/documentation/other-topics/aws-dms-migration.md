### Migrating an RDS instance with AWS DMS

This guide assumes the migration comply with the following :
 - The migration happens from a _source_ RDS to a _target_ RDS
 - The _source_ RDS is running postgresql 9.4.9 or above
 - Elevated sets of postgres credentials are available for both _source_ and _target_



#### Overview 

AWS Database Migration Service (DMS) is useful to migrate pure data from a database to another, and keep them unidirectionally in sync. 

The DMS stack is composed of a few components: 
 - A replication task : the process migrating data, complying with its configuration.
 - A replication instance : Where the replication task actually runs from.
 - A _source_ endpoint :  the object containing _source_'s credentials and host information
 - A _target_ endpoint :  the object containing _target_'s credentials and host information
 - A subnet group : it incapsulate everything.


 As mentioned aboved, DMS can only migrate data.  
  In other words, in the context of a full database migration, we  need to rely on other tools for the remaining bits. Therefore, `pg_dump`, `pg_restore` and `psql` will be used to migrate the table structure, the sequences and the contraints, foreign keys and indexes.  
 The steps including those tools will always be the same; on one side we export from source, on the other we restore them.

#### Step 0 - Pod

In order to run postgresql commands against both of those endpoints, there needs to be a place that has access to both.

This is solved by running a pod into the kubernetes cluster, on live-1, into the team's namespace. 
The migration steps outlined below have been tested from a pod running a `bitnami/postgresql` Docker image.

Regarding the network access: 
 - The _source_ RDS needs to have its `public accessibility` config turned on.
 - The RDS security group needs to be opened to the Cluster. For that, add inbound rules from the NAT gateways' IP address on the 5432 port.  
  


#### Step 1 - pre-data migration


First, to export,  we run : 

``` 
pg_dump -U source_username \
     -h source_endpoint \
     -d source_database \
     -O \
     --section=pre-data > pre-data.sql
``` 

Here, `-O` tells RDS to export the table structure without owners.
The command above stores the data in a local file.


Then to restore thi into the _target_, we use `psql`:

```
psql -U target_username \
     -h target_endpoint \
     -d target_database \
     -f pre-data.sql

```

If using a local file is problematic, those two commands can be piped together (`|`)



#### Step 2 - sequences migration

Sequences are essential for your database to know what the latest increment of the primary keys is. Sequences are hold in special tables that will not be migrated from step 1.


First, to export,  we run : 

``` 
pg_dump -U source_username \
     -h source_endpoint \
     -d source_database \
     -t '*_seq' > sequences.sql
``` 

Here, `-t '*_seq'` indicates to `pg_dump` that we only want to export the table ending in `_seq`, which are the sequences.


Then to restore thi into the _target_, we use `psql`:

```
psql -U target_username \
     -h target_endpoint \
     -d target_database \
     -f sequences.sql

```

If using a local file is problematic, those two commands can be piped together (`|`)  



#### Step 3 - DMS 

The DMS stack is build using a terraform module. 

Please refer to [this](https://github.com/ministryofjustice/cloud-platform-terraform-dms)
 repository to see the DMS module instructions:
 [https://github.com/ministryofjustice/cloud-platform-terraform-dms](https://github.com/ministryofjustice/cloud-platform-terraform-dms)


 Please also note that at this is a sensitive step, please consult with the Cloud Platform beforehand.

#### Step 4 - Post-Data

Any constraints, indexes and foreign keys are also a special kind of metadata that would not be migrated during any of the steps above. 
All of data is contained withing the `post-data` section.

The process is almost identical as Step 1 :

First, to export,  we run : 

``` 
pg_dump -U source_username \
     -h source_endpoint \
     -d source_database \
     -O \
     --section=post-data > post-data.sql
``` 


Then to restore thi into the _target_, we use `psql`:

```
psql -U target_username \
     -h target_endpoint \
     -d target_database \
     -f post-data.sql

```

If using a local file is problematic, those two commands can be piped together (`|`)

  

#### Step 5 - Data Validation (Very Important)

After a migration, **it is your team's responsibility** to ensure the data, its integrity and anything required by your application to operate properly have been preserved.

Even though the process above is handling the data and the meta-data migration, it is essentials for you to have a Data-Validation Strategy to confirm everything is in order.

The Cloud Platform team can't provide a how-to guide on data validation, as each database migrations are wildly different.