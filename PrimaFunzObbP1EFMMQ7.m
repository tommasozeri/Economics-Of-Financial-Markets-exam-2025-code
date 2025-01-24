function f = PrimaFunzObbP1EFMMQ7(x)
    % Carica i dati dal file Excel DBEXAM.xlsx, worksheet NYSEselectedD
    A = readtable('DBEXAM.xlsx', 'Sheet', 'NYSEselectedM', 'ReadRowNames', true, 'VariableNamingRule', 'preserve');

    % Converti la tabella in una matrice di numeri
    A = table2array(A);

    % Calcola i rendimenti logaritmici mensili
    n = size(A, 1);
    R = log(A(2:n, :) ./ A(1:n-1, :));

    % Calcola la matrice di covarianza
    V = cov(R);

    % Assicurati che x sia un vettore colonna
    if isrow(x)
        x = x';
    end

    % Calcola la funzione obiettivo
    f = x' * V * x;
end
