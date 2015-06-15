%**************************************************************************
% get_places_osm.m
% function [          ...
% out_places          ...
% ] = get_places_osm( ...
%     ~,              ...
%     ~,              ...
%     in_types        ...
%     )
%**************************************************************************

function [          ...
out_places          ...
] = get_places_osm( ...
    ~,              ...
    ~,              ...
    in_types        ...
    )

global CONFIG

fmt     = CONFIG.LATLONFMT;
dbuser  = CONFIG.OSMDBUSER;
dbpass  = CONFIG.OSMDBPASS;
dbhost  = CONFIG.OSMDBHOST;
dbport  = CONFIG.OSMDBPORT;
dbname  = CONFIG.OSMDBNAME;
dbtable = CONFIG.OSMDBPLACESTABLE;

driver = 'org.postgresql.Driver';
dburl = ['jdbc:postgresql://' dbhost ':' dbport '/' dbname];
conn = database(dbname, dbuser, dbpass, driver, dburl);
dtor = onCleanup(@()close(conn));

if (~isempty(conn.Message)), error(conn.Message); end

out_places = [];

for type = in_types
selq = [
    'select name,amenity,ST_X(way),ST_Y(way) from ' dbtable ' ' ...
	'where (amenity like ''' type{1} ''' '                      ...
	'or amenity like ''%;'   type{1} ''' '                      ...
	'or amenity like ''%;'   type{1} ';%'' '                    ...
	'or amenity like '''     type{1} ';%'') '                   ...
    'and name is not NULL;'                                     ...
];

curs = exec(conn, selq);
if (~isempty(curs.Message)), error(curs.Message); end

data = fetch(curs);
data = data.Data;
if (numel(data) < 4), continue; end

[lon, lat] = meters2latlon(cell2mat(data(:, 3)), cell2mat(data(:, 4)));
lon = num2cell(lon);
lat = num2cell(lat);
id  = [];

for k = 1:size(lat, 1)
    id = [id; {[num2str(lat{k}, fmt) ',' num2str(lon{k}, fmt)]}]; 
end

tstr = regexprep(data(:, 2), '\s*;\s*', '|');
tstr = regexprep(tstr,       '\s*$',    '|', 'emptymatch');
tstr = regexprep(tstr,       '^\s*',    '|', 'emptymatch');

fill = regexprep(data(:, 1), '.*', '-', 'emptymatch');

data = [id, data(:, 1), tstr, fill, lat, lon];
out_places = [out_places; data];
end
end

%--------------------------------------------------------------------------
% function [ ...
% out_lon,   ...
% out_lat    ...
% ] = meters2latlon( ...
%     in_x,          ...
%     in_y           ...
%     )
%--------------------------------------------------------------------------

function [ ...
out_lon,   ...
out_lat    ...
] = meters2latlon( ...
    in_x,          ...
    in_y           ...
    )

% Converts XY point from Spherical Mercator EPSG:900913
% to lat/lon in WGS84 Datum
originShift = 2 * pi * 6378137 / 2.0; % 20037508.342789244
out_lon = (in_x ./ originShift) * 180;
out_lat = (in_y ./ originShift) * 180;
out_lat = 180 / pi * (2 * atan(exp(out_lat * pi / 180)) - pi / 2);
end
%**************************************************************************