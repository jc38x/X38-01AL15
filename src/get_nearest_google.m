%**************************************************************************
% get_nearest_google.m
% function [              ...
% out_addr                ...
% ] = get_nearest_google( ...
%     in_coord            ...
%     )
%**************************************************************************

function [              ...
out_addr                ...
] = get_nearest_google( ...
    in_coord            ...
    )

global CONFIG
global STATE

fmt      = CONFIG.LATLONFMT;
retries  = CONFIG.HTTPRETRIES;
timeout  = CONFIG.HTTPTIMEOUT;
pret     = CONFIG.GOOGLEGEOCODERETRIES;
keyindex = STATE.GOOGLEGEOCODEKEYINDEX;

N = size(in_coord, 1);
preamble = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=';
keyring = apikeyring_google();
out_addr = cell(N, 1);

for n = 1:N
lat = num2str(in_coord(n, 1), fmt);
lon = num2str(in_coord(n, 2), fmt);
latlng = [lat ',' lon];    
url = [preamble latlng];
getaddr = true;
rdretry = pret;

while (getaddr)
    key = ['key=' keyring{keyindex}];
    req = [url '&' key];
    attempt = retries;

    while (true)
        [outputjson, status] = urlread(req, 'Timeout', timeout);
        if (status), break; end
        attempt = attempt - 1;
        if (attempt > 0), continue; end
        error('Failed to retrieve geocoding data from Google servers');
    end

    response = loadjson(outputjson);
    
    switch (response.status)
    case 'OK'
        str = response.results{1}.formatted_address;
        str = regexprep(str, '["\\]', '');
        getaddr = false;
    case 'ZERO_RESULTS'
        str = '';
        getaddr = false;
    case 'OVER_QUERY_LIMIT'
        keyindex = keyindex + 1;
        if (keyindex > size(keyring, 1))
            error('Google Geocoding Api all keys used');
        end
        warning('Google Geocoding Api key change');
	case 'REQUEST_DENIED'
        if (rdretry < 1)
            error('Google Geocoding Api REQUEST_DENIED');
        end
        rdretry = rdretry - 1;
        warning('Google Geocoding request denied, retrying...');
    case 'UNKNOWN_ERROR'
        warning('Google Geocoding UNKNOWN_ERROR, retrying...');
	otherwise
        error(['Google Geocoding Api ' response.status]);
    end
end

out_addr(n) = {str};
end

STATE.GOOGLEGEOCODEKEYINDEX = keyindex;
end
%**************************************************************************