%**************************************************************************
% load_bases_by_type.m
% function load_bases_by_type( ...
%     in_types                 ...
%     )
%**************************************************************************

function load_bases_by_type( ...
    in_types                 ...
    )

global CONFIG

fmt               = CONFIG.LATLONFMT;
googleplacestable = CONFIG.CACHEDBGOOGLEPLACESTABLE;
googlemeshtable   = CONFIG.CACHEDBGOOGLEMESHTABLE;
osmplacestable    = CONFIG.CACHEDBOSMPLACESTABLE;
osmmeshtable      = CONFIG.CACHEDBOSMMESHTABLE;
maxelem           = CONFIG.PLACESMAXELEM;
vendor            = CONFIG.PLACESVENDOR;

switch (lower(vendor))
case 'google', dbtable           = googleplacestable;
               dbmeshtable       = googlemeshtable;
               get_places_vendor = @get_places_google;
case 'osm',    dbtable           = osmplacestable;
               dbmeshtable       = osmmeshtable;
               get_places_vendor = @get_places_osm;
otherwise,     error(['Unknown vendor: ' in_vendor]);
end

% Cargar nodos de busqueda ------------------------------------------------
conn = conn_db_cache();
dtor = onCleanup(@()close(conn));

table_dirty = false;
entry_dirty = false;
types = unique(in_types);
load_req = [];
err = [];

[mesh, radius] = bases_mesh();

try
for t = types
    % Cargar bases actuales -----------------------------------------------
    if (strcmpi('base_actual', t))
        delq = ['delete from ' dbtable ' where types="|base_actual|"'];
        curs = exec(conn, delq);
        if (~isempty(curs.Message)), error(curs.Message); end
        bases = bases_fixed();
        tstr = '|base_actual|';
        for k = bases.', load_base(k{1}, k{2}, tstr, k{3}, k{4}, k{5}); end
        continue;
    end
    
    % Saltar busqueda si ya se realizo ------------------------------------
    selq = [
        'select type,time from ' dbmeshtable ' ' ...
        'where type="' t{1}                  '"' ...
    ];
    curs = exec(conn, selq);
    if (~isempty(curs.Message))
        warning(curs.Message);
    else
        data = fetch(curs);
        data = data.Data;
        if (numel(data) > 1), continue; end
    end
    
    % Obtener places ------------------------------------------------------
    time = tic();
    bases = get_places_vendor(mesh, radius, t);
    for k = bases.', load_base(k{1}, k{2}, k{3}, k{4}, k{5}, k{6}); end
    found = num2str(size(bases, 1), '%.0f');
    time = toc(time);
    time = num2str(time, '%.4f');
    
    % Marcar esta busqueda como realizada ---------------------------------
    insq = [
        'insert into ' dbmeshtable ' (type,places_found,time) ' ...
        'values ("' t{1} '",' found ',' time                ')' ...
    ];
    curs = exec(conn, insq);
    if (~isempty(curs.Message)), warning(curs.Message); end
    entry_dirty = true;
end
catch ME
    err = ME;
end

% Guardar places y optimizar tabla ----------------------------------------
if (~isempty(load_req)), load_table(); end
if (~isempty(err)), rethrow(err); end

if (table_dirty)
    optq = ['optimize table ' dbtable];
    curs = exec(conn, optq);
    if (~isempty(curs.Message)), warning(curs.Message); end
end

if (entry_dirty)
    optq = ['optimize table ' dbmeshtable];
    curs = exec(conn, optq);
    if (~isempty(curs.Message)), warning(curs.Message); end
end

%--------------------------------------------------------------------------
% function load_table()
%--------------------------------------------------------------------------

function load_table()

insq = [
    'insert ignore into ' dbtable         ' ' ...
    '(place_id,name,types,vicinity,lat,lng) ' ...
    'values '                                 ...
];

for n = load_req.'
    las = num2str(n{5}, fmt);
    los = num2str(n{6}, fmt);
    insq = [
        insq '("'                                                   ...
        n{1} '","' n{2} '","' n{3} '","' n{4} '",' las ',' los '),' ...
    ];
end

curs = exec(conn, insq(1:end-1));
if (~isempty(curs.Message)), error(curs.Message); end

load_req = [];
table_dirty = true;
end

%--------------------------------------------------------------------------
% function load_base( ...
%     in_id,          ...
%     in_name,        ...
%     in_type,        ...
%     in_vicinity,    ...
%     in_lat,         ...
%     in_lon          ...
%     )
%--------------------------------------------------------------------------

function load_base( ...
    in_id,          ...
    in_name,        ...
    in_type,        ...
    in_vicinity,    ...
    in_lat,         ...
    in_lon          ...
    )

id = regexprep(in_id, '["\\]', '');
name = regexprep(in_name, '["\\]', '');
type = regexprep(in_type, '["\\]', '');
vicinity = regexprep(in_vicinity, '["\\]', '');
load_req = [load_req; {id, name, type, vicinity, in_lat, in_lon}];
if (size(load_req, 1) >= maxelem), load_table(); end
end
end
%**************************************************************************