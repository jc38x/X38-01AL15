%**************************************************************************
% get_places_google.m
% function [             ...
% out_places             ...
% ] = get_places_google( ...
%     in_coord,          ...
%     in_r,              ...
%     in_types           ...
%     )
%**************************************************************************

function [             ...
out_places             ...
] = get_places_google( ...
    in_coord,          ...
    in_r,              ...
    in_types           ...
    )

global CONFIG
global STATE

fmt      = CONFIG.LATLONFMT;
retries  = CONFIG.HTTPRETRIES;
timeout  = CONFIG.HTTPTIMEOUT;
pret     = CONFIG.GOOGLEPLACESRETRIES;
ptiming  = CONFIG.GOOGLEPLACESTIMING;
keyindex = STATE.GOOGLEPLACESKEYINDEX;

N = size(in_coord, 1);
if (N ~= size(in_r, 1)), error('Incompatible number of rows'); end

tc = in_types;
types = tc{1};
for k = tc(2:end), types = [types '|' k{1}]; end

http = 'https';
preamble = '://maps.googleapis.com/maps/api/place/nearbysearch/json?';
types = ['types=' types];
keyring = apikeyring();
out_places = [];

for n = 1:N
tlat = num2str(in_coord(n, 1), fmt);
tlon = num2str(in_coord(n, 2), fmt);
tr = num2str(in_r(n, 1), '%.0f');

location = ['location=' tlat ',' tlon];
radius = ['radius=' tr];
getplaces = true;
token = [];
tokenattempt = 0;
url = [http preamble location '&' radius '&' types];

while (getplaces)
    key = ['key=' keyring{keyindex}];
    req = [url '&' key];
    attempt = retries;
    
    while (true)
        [outputjson, status] = urlread(req, 'Timeout', timeout);
        if (status), break; end
        attempt = attempt - 1;
        if (attempt > 0), continue; end
        error('Failed to retrieve places from Google servers');
    end

    response = loadjson(outputjson);
    switch (response.status)
    case 'OK'
        for r = response.results
            tstr = r{1}.types{1};
            for t = r{1}.types(2:end), tstr = [tstr '|' t{1}]; end
            tstr = ['|' tstr '|'];
            out_places = [out_places;
                         {r{1}.place_id,              ...
                          r{1}.name,                  ...
                          tstr,                       ...
                          r{1}.vicinity,              ...
                          r{1}.geometry.location.lat, ...
                          r{1}.geometry.location.lng  ...
            }
            ];
        end

        getplaces = isfield(response, 'next_page_token') && ...
                   ~isempty(response.next_page_token);

        if (getplaces)
            token = ['pagetoken=' response.next_page_token];
            url = [http preamble token];
            tokenattempt = pret;
            delay_counter(ptiming);
        end
    case 'ZERO_RESULTS'
        getplaces = false;
    case 'OVER_QUERY_LIMIT'
        keyindex = keyindex + 1;
        if (keyindex > size(keyring, 1))
            error('Google Places Api all keys used');
        end
        warning('Google Places Api key change');
	case 'INVALID_REQUEST'
        if (isempty(token) || tokenattempt < 1)
            error('Google Places Api INVALID_REQUEST');
        end
        tokenattempt = tokenattempt - 1;
        warning('Failed to get search results next page, retrying...');
        delay_counter(ptiming);
	otherwise
        error(['Google Places Api ' response.status]);
    end
end
end

STATE.GOOGLEPLACESKEYINDEX = keyindex;

if (~isempty(out_places))
    [~, ia, ~] = unique(out_places(:, 1));
    out_places = out_places(ia, :);
end
end
%**************************************************************************