%**************************************************************************
% conn_db_cache.m
% function [ ...
% out_conn   ...
% ] = conn_db_cache()
%**************************************************************************

function [ ...
out_conn   ...
] = conn_db_cache()

global CONFIG

dbuser = CONFIG.CACHEDBUSER;
dbpass = CONFIG.CACHEDBPASSWORD;
dbhost = CONFIG.CACHEDBHOST;
dbport = CONFIG.CACHEDBPORT;
dbname = CONFIG.CACHEDBNAME;

out_conn = conn_mysql(dbhost, dbport, dbname, dbuser, dbpass);
end
%**************************************************************************