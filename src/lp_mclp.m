%**************************************************************************
% lp_mclp.m
% function [     ...
% out_ok,        ...
% out_bases,     ...
% out_total      ...
% ] = lp_mclp(   ...
%     in_costos, ...
% 	  in_pesos,  ...
%     in_p,      ...
%     in_r,      ...
%     in_entero  ...
%     )
%**************************************************************************

function [     ...
out_ok,        ...
out_bases,     ...
out_total      ...
] = lp_mclp(   ...
    in_costos, ...
	in_pesos,  ...
	in_p,      ...
	in_r,      ...
	in_entero  ...
    )
% Constantes --------------------------------------------------------------
db = size(in_costos, 1); % numero de bases
dd = size(in_costos, 2); % numero de puntos de demanda
cx = in_costos <= in_r;  % cobertura en r
w  = in_pesos(:).';      % peso de cada punto de demanda

% Funcion objetivo: maximizar demanda cubierta ----------------------------
% (1) numero de ambulancias en cada base
% (2) puntos de demanda cubiertos
f = [
    zeros(1, db), ... % xj (no importa) (1)
              -w  ... % yi              (2)
];

% Restricciones (desigualdades) -------------------------------------------
% (1) punto de demanda se considera cubierto con 1+ ambulancia en r
%    xj     yi
A = [-cx.', eye(dd, dd)]; % (1)
b =   zeros(dd, 1);       % (1)

% Restricciones (igualdades) ----------------------------------------------
% (1) total de ambulancias igual al total de ambulancias disponibles
%      xj           yi
Aeq = [ones(1, db), zeros(1, dd)]; % (1)
beq =  in_p;                       % (1)

% Cotas -------------------------------------------------------------------
% xj : [0, 1] maximo de ambulancias permitidas por base
% yi : [0, 1]
%      xj            yi
lb  = [zeros(1, db), zeros(1, dd)];
ub  = [ ones(1, db),  ones(1, dd)];

% Aplicar LP --------------------------------------------------------------
if (in_entero) % ILP
    [
    p_grupo, ...
    p_total, ...
    p_exit   ...
    ] = intlinprog(f, 1:numel(f), A, b, Aeq, beq, lb, ub);
else          % LP
    [
    p_grupo, ...
    p_total, ...
    p_exit   ...
    ] =    linprog(f,             A, b, Aeq, beq, lb, ub);
end

% Resultados --------------------------------------------------------------
if (p_exit < 1)
    out_ok    = false;
    out_bases = [];
    out_total = 0;
else
    out_ok    =  true;
    out_bases =  p_grupo(1:db);
    out_total = -p_total;
end
end
%**************************************************************************