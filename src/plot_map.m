%**************************************************************************
% plot_map.m
% function     ...
% plot_map(    ...
%     varargin ...
%     )
%**************************************************************************

function     ...
plot_map(    ...
    varargin ...
    )

global CONFIG;

vendor = CONFIG.MAPVENDOR;

switch (lower(vendor))
case 'google', plot_google_map(varargin{:});
case 'osm',    plot_osm_map(varargin{:});
otherwise,     error(['Unknown vendor: ' vendor]);
end
end
%**************************************************************************