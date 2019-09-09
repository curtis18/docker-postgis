#!/usr/bin/env bash

source /env-data.sh

SETUP_LOCKFILE="${ROOT_CONF}/.postgresql.conf.lock"
if [ -f "${SETUP_LOCKFILE}" ]; then
	return 0
fi

# This script will setup necessary configuration to enable replications

# Refresh configuration in case environment settings changed.
cat $CONF.template > $CONF

# This script will setup necessary configuration to optimise for PostGIS and to enable replications
cat >> $CONF <<EOF
wal_level = hot_standby
max_wal_senders = ${PG_MAX_WAL_SENDERS}
wal_keep_segments = ${PG_WAL_KEEP_SEGMENTS}
superuser_reserved_connections = 10
max_wal_size = 2GB
wal_keep_segments= 64
hot_standby = on
listen_addresses = '${IP_LIST}'
shared_buffers = 3GB
work_mem = 16MB
maintenance_work_mem = 768MB
wal_buffers = 16MB
random_page_cost = 1.1
xmloption = 'document'
effective_cache_size = 9GB
effective_io_concurrency = 300
checkpoint_completion_target = 0.7
max_worker_processes = 32
max_parallel_workers_per_gather = 16
max_parallel_workers = 32
#archive_mode=on
#archive_command = 'test ! -f ${WAL_ARCHIVE}/%f && cp -r %p ${WAL_ARCHIVE}/%f'
EOF

# Optimise PostgreSQL shared memory for PostGIS
# shmall units are pages and shmmax units are bytes(?) equivalent to the desired shared_buffer size set in setup_conf.sh - in this case 500MB
echo "kernel.shmmax=543252480" >> /etc/sysctl.conf
echo "kernel.shmall=2097152" >> /etc/sysctl.conf

# Put lock file to make sure conf was not reinitialized
touch ${SETUP_LOCKFILE}
