%**************************************************************************
% plot_class_demand.m
% function [             ...
% out_fig                ...
% ] = plot_class_demand( ...
%     in_demandcoord,    ...
%     in_pointcoord,     ...
%     in_T               ...
%     )
%**************************************************************************

function [             ...
out_fig                ...
] = plot_class_demand( ...
    in_demandcoord,    ...
    in_pointcoord,     ...
    in_T               ...
    )

global PROFILESTRING

legendcell = PROFILESTRING.CLASSLEGENDS;
lonstr     = PROFILESTRING.LONGITUDE;
latstr     = PROFILESTRING.LATITUDE;

out_fig = figure();
hold on

Z = 10;
h = scatter(in_demandcoord(:, 2), in_demandcoord(:, 1), Z, in_T, 'filled');

lon = in_pointcoord(:, 2);
lat = in_pointcoord(:, 1);

hd = plot(lon, lat, 'ok', 'MarkerFaceColor', 'w');

set(h,  'Tag', 'Calls');
set(hd, 'Tag', 'Demand');

xlabel(lonstr);
ylabel(latstr);
legend(hd, legendcell);

dcm_obj = datacursormode(out_fig);
set(dcm_obj, 'UpdateFcn', @point_info);

plot_map();
end
%**************************************************************************