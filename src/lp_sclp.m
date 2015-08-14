%**************************************************************************
% lp_sclp.m
% function [     ...
% out_ok,        ...
% out_bases,     ...
% out_total      ...
% ] = lp_sclp(   ...
%     in_costos, ...
%	  in_r,      ...
%	  in_entero  ...
%     )
%**************************************************************************

function [     ...
out_ok,        ...
out_bases,     ...
out_total      ...
] = lp_sclp(   ...
    in_costos, ...
	in_r,      ...
	in_entero  ...
    )
% Constantes --------------------------------------------------------------
db = size(in_costos, 1); % numero de bases
dd = size(in_costos, 2); % numero de puntos de demanda
cx = in_costos <= in_r;  % cobertura en r

% Funcion objetivo: minimizar numero de ambulancias -----------------------
% (1) numero de ambulancias en cada base
f = ones(1, db); % xj (1)

% Restricciones (desigualdades) -------------------------------------------
% (1) todos los puntos de demanda cubiertos
%    xj
A = -(cx.');      % (1)
b = -ones(dd, 1); % (1)

% Cotas -------------------------------------------------------------------
% xj : [0, 1] maximo de ambulancias permitidas por base
%    xj
lb = zeros(1, db);
ub =  ones(1, db);

% Aplicar LP --------------------------------------------------------------
if (in_entero) % ILP
    [
    p_grupo, ...
    p_total, ...
    p_exit   ...
    ] = intlinprog(f, 1:numel(f), A, b, [], [], lb, ub);
else % LP
    [
    p_grupo, ...
    p_total, ...
    p_exit   ...
    ] =    linprog(f,             A, b, [], [], lb, ub);
end

% Resultados --------------------------------------------------------------
if (p_exit < 1)
    out_ok    = false;
    out_bases = [];
    out_total = 0;
else
    out_ok    = true;
    out_bases = p_grupo;
    out_total = p_total;
end
end
%**************************************************************************