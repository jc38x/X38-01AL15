%**************************************************************************
% get_bases_by_type.m
% function [             ...
% out_bases              ...
% ] = get_bases_by_type( ...
%     in_types,          ...
%     in_ntypes          ...
%     )
%**************************************************************************

function [             ...
out_bases              ...
] = get_bases_by_type( ...
    in_types,          ...
    in_ntypes          ...
    )

global CONFIG

googletable = CONFIG.CACHEDBGOOGLEPLACESTABLE;
osmtable    = CONFIG.CACHEDBOSMPLACESTABLE;
vendor      = CONFIG.PLACESVENDOR;

switch (lower(vendor))
case 'google', dbtable = googletable;
case 'osm',    dbtable = osmtable;
otherwise,     error(['Unknown vendor: ' vendor]);
end

conn = conn_db_cache();
dtor = onCleanup(@()close(conn));

query = [
    'select'      ' ' ...
    'place_id'    ',' ...
    'name'        ',' ...
    'types'       ',' ...
    'vicinity'    ',' ...
    'lat'         ',' ...
    'lng'         ' ' ...
    'from ' dbtable   ...
];

types_str  = '';
ntypes_str = '';
    
if (numel(in_types) > 0)
    for t = in_types
        if (~isempty(types_str)), types_str = [types_str ' or ']; end
        types_str = [types_str 'types like "%|' t{1} '|%"'];
    end
    types_str = ['(' types_str ')'];
end

if (numel(in_ntypes) > 0)
    for nt = in_ntypes
        if (~isempty(ntypes_str)), ntypes_str = [ntypes_str ' and ']; end
        ntypes_str = [ntypes_str 'types not like "%|' nt{1} '|%"'];
    end
    ntypes_str = ['(' ntypes_str ')'];
end

if (~isempty(types_str) || ~isempty(ntypes_str))
    query = [query ' where '];
    if (~isempty(types_str) && ~isempty(ntypes_str))
        query = [query types_str ' and ' ntypes_str];
    else
        query = [query types_str ntypes_str];
    end
end

curs = exec(conn, query);
if (~isempty(curs.Message)), error(curs.Message); end

bases = fetch(curs);
bases = bases.Data;

if (numel(bases) < 6)
    out_bases = [];
else
    s = polygon_test(cell2mat([bases(:, 5), bases(:, 6)]));
    out_bases = bases(s, :);
end
end
%**************************************************************************