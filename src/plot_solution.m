%**************************************************************************
% plot_solution.m
% function [         ...
% out_fig            ...
% ] = plot_solution( ...
%     in_bases,      ...
%     in_pointcoord, ...
%     in_location    ...
% 	)
%**************************************************************************

function [         ...
out_fig            ...
] = plot_solution( ...
    in_bases,      ...
    in_pointcoord, ...
    in_location    ...
	)

global PROFILESTRING

legendcell = PROFILESTRING.SOLUTIONLEGENDS;
lonstr     = PROFILESTRING.LONGITUDE;
latstr     = PROFILESTRING.LATITUDE;

out_fig = figure();
hold on

bases_lon = cell2mat(in_bases(:, 6));
bases_lat = cell2mat(in_bases(:, 5));

Z  = 10;
hb = plot(bases_lon,           bases_lat,           '.g', 'MarkerSize', Z);
hd = plot(in_pointcoord(:, 2), in_pointcoord(:, 1), '.r', 'MarkerSize', Z);

set(hb, 'Tag', 'Bases');
set(hd, 'Tag', 'Demand');

idx1 = in_location > 0.5 & in_location < 1.5;
idx2 = in_location > 1.5;
s1 = [];
s2 = [];

for k = in_bases(idx1, :).'
s1 = plot(k{6}, k{5}, 's', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'm');
set(s1, 'Tag', 'Location');
set(s1, 'UserData', [k; {1}]);
end

for k = in_bases(idx2, :).'
s2 = plot(k{6}, k{5}, 's', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'c');
set(s2, 'Tag', 'Location');
set(s2, 'UserData', [k; {2}]);
end

xlabel(lonstr);
ylabel(latstr);
legend([hb, hd, s1, s2], legendcell);

dcm_obj = datacursormode(out_fig);
set(dcm_obj, 'UpdateFcn', @point_info);

plot_map();
end
%**************************************************************************