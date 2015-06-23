%**************************************************************************
% get_distance.m
% function [        ...
% out_table         ...
% ] = get_distance( ...
%     in_fromcoord, ...
%     in_tocoord    ...
%     )
%**************************************************************************

function [        ...
out_table         ...
] = get_distance( ...
    in_fromcoord, ...
    in_tocoord    ...
    )

global CONFIG
global DISTCACHE
global STATE

fmt             = CONFIG.LATLONFMT;
dbdistmax       = CONFIG.CACHEDBDISTPREFMAXROWS;
vendor          = CONFIG.DISTVENDOR;
googledisttable = CONFIG.CACHEDBGOOGLEDISTTABLE;
osrmdisttable   = CONFIG.CACHEDBOSRMDISTTABLE;
maxelem         = CONFIG.DISTMAXELEM;
cinfovendor     = STATE.DISTCACHEVENDOR;
cinfosize       = STATE.DISTCACHESIZE;

switch (lower(vendor))
case 'google', dbdisttable         = googledisttable;
               get_distance_vendor = @get_distance_google;
case 'osrm',   dbdisttable         = osrmdisttable;
               get_distance_vendor = @get_distance_osrm;
otherwise,     error(['Unknown vendor: ' in_vendor]);
end

% Prefetch distancias -----------------------------------------------------
conn = conn_db_cache();
dtor = onCleanup(@()close(conn));

if (~strcmpi(cinfovendor, vendor) || cinfosize ~= dbdistmax)
    DISTCACHE = [];
    STATE.DISTCACHEVENDOR = [];
    STATE.DISTCACHESIZE = [];
    warning('Prefetch buffer flush');
end

if (isempty(DISTCACHE))
    selq = ['select uid,time_value from ' dbdisttable];
    curs = exec(conn, selq);
    if (~isempty(curs.Message)), error(curs.Message); end
    
    distdata = fetch(curs, dbdistmax);
    distdata = distdata.Data;

    if (numel(distdata) < 2)
        DISTCACHE = containers.Map();
    else
        DISTCACHE = containers.Map(distdata(:, 1), distdata(:, 2));
    end

    distdata = [];
    STATE.DISTCACHEVENDOR = vendor;
    STATE.DISTCACHESIZE = dbdistmax;
end

% Generar cadenas lat,lon para los puntos origen y puntos destino ---------
N = size(in_fromcoord, 1);
fromloc = cell(N, 1);
AN = 1:N;

for n = AN
    tfromlat = num2str(in_fromcoord(n, 1), fmt);
    tfromlon = num2str(in_fromcoord(n, 2), fmt);
    fromloc(n, 1) = {[tfromlat ',' tfromlon]};
end

M = size(in_tocoord, 1);
toloc = cell(M, 1);
AM = 1:M;

for m = AM
    ttolat = num2str(in_tocoord(m, 1), fmt);
    ttolon = num2str(in_tocoord(m, 2), fmt);
    toloc(m, 1) = {[ttolat ',' ttolon]};
end

% Obtener distancias ------------------------------------------------------
out_table = -1 * ones(N, M);
req = cell(maxelem, 5);
dirty = false;
elem = 0;

for n = AN, from = fromloc{n};
for m = AM, to = toloc{m};
    uid = [from '_' to];
    elem = elem + 1;
    req(elem, :) = {uid, n, m, from, to};
    if (elem < maxelem), continue; end
    fill_table();
end
end

if (elem > 0), fill_table(); end

if (dirty)
    optq = ['optimize table ' dbdisttable];
    curs = exec(conn, optq);
    if (~isempty(curs.Message)), warning(curs.Message); end
end

%--------------------------------------------------------------------------
% function fill_table()
%--------------------------------------------------------------------------

function fill_table()
% Buscar en prefetch buffer -----------------------------------------------
hit = DISTCACHE.isKey(req(1:elem, 1));
str = req(hit, :);
for k = str.', out_table(k{2}, k{3}) = DISTCACHE(k{1}); end
rem = req(~hit, :);

if (isempty(rem)), elem = 0; return; end

% Buscar en cache ---------------------------------------------------------
selq = [
    'select uid,time_value from ' dbdisttable ' ' ...
	'where uid="' rem{1, 1}                   '"' ...
];

for k = 2:size(rem, 1), selq = [selq ' or uid="' rem{k, 1} '"']; end

curs = exec(conn, selq);
if (~isempty(curs.Message)), error(curs.Message); end

distdata = fetch(curs);
distdata = distdata.Data;

if (numel(distdata) < 2)
    map = containers.Map();
    hit = false(size(rem, 1), 1);
else    
    map = containers.Map(distdata(:, 1), distdata(:, 2));
    hit = map.isKey(rem(:, 1));
end

str = rem(hit, :);
for k = str.', out_table(k{2}, k{3}) = map(k{1}); end
rem = rem(~hit, :);

if (isempty(rem)), elem = 0; return; end

% Obtener del servidor ----------------------------------------------------
str = rem;
[~, ia, ~] = unique(rem(:, 1), 'stable');
rem = rem(ia, :);
stm = [];
err = [];

while (true)
    orig = rem(1, 4);
    sel = strcmpi(orig{1}, rem(:, 4));
    dest = rem(sel, 5);
    uids = rem(sel, 1);

    try
    row = get_distance_vendor(orig, dest);
    catch ME
    err = ME;
    warning('Failed to retrieve distance table, saving progress...');
    break;
    end

    crow = num2cell(row).';
    map = [map; containers.Map(uids, crow)];
    rem(sel, :) = [];
    stm = [stm; uids, crow];
    if (isempty(rem)), break; end
end

if (~isempty(stm))
    datainsert(conn, dbdisttable, {'uid','time_value'}, stm);

    sel = min(size(stm, 1), dbdistmax - DISTCACHE.length());
    cln = stm(1:sel, :);

    if (~isempty(cln))
        DISTCACHE = [DISTCACHE; containers.Map(cln(:, 1), cln(:, 2))];
    end

    dirty = true;
end

if (~isempty(err)), rethrow(err); end

for k = str.', out_table(k{2}, k{3}) = map(k{1}); end
elem = 0;
end
end
%**************************************************************************