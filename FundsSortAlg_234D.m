% Carica i dati dal file Excel con la regola di denominazione delle variabili impostata su 'preserve'
opts = detectImportOptions('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'funds daily');
opts.VariableNamingRule = 'preserve';
funds_data = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', opts);

opts = detectImportOptions('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', 'Sheet', 'SP500indexD');
opts.VariableNamingRule = 'preserve';
benchmark_data = readtable('C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\DBEXAM.xlsx', opts);

% Converti le date in formato datetime
funds_data.DATE = datetime(funds_data.DATE, 'InputFormat', 'dd/MM/yyyy');
benchmark_data.DATE = datetime(benchmark_data.DATE, 'InputFormat', 'dd/MM/yyyy');

% Allinea i dati delle date
start_date = datetime('10/01/2020', 'InputFormat', 'dd/MM/yyyy');
end_date = datetime('10/01/2025', 'InputFormat', 'dd/MM/yyyy');
funds_data = funds_data(funds_data.DATE >= start_date & funds_data.DATE <= end_date, :);
benchmark_data = benchmark_data(benchmark_data.DATE >= start_date & benchmark_data.DATE <= end_date, :);

% Trova le date comuni
common_dates = intersect(funds_data.DATE, benchmark_data.DATE);

% Filtra i dati per le date comuni
funds_data = funds_data(ismember(funds_data.DATE, common_dates), :);
benchmark_data = benchmark_data(ismember(benchmark_data.DATE, common_dates), :);

% Calcola i rendimenti giornalieri normali
funds_returns = diff(funds_data{:, 2:end}) ./ funds_data{1:end-1, 2:end};
benchmark_returns = diff(benchmark_data{:, 2}) ./ benchmark_data{1:end-1, 2};

% Assicurati che le dimensioni delle matrici siano compatibili
if size(funds_returns, 1) ~= size(benchmark_returns, 1)
    error('Le dimensioni delle matrici dei rendimenti non corrispondono.');
end

% Calcola i beta dei titoli
num_stocks = size(funds_returns, 2);
beta = zeros(num_stocks, 1);
mean_returns = zeros(num_stocks, 1);
std_returns = zeros(num_stocks, 1);
sharpe_ratio = zeros(num_stocks, 1);
information_ratio = zeros(num_stocks, 1);
average_drawdown = zeros(num_stocks, 1);
pain_index = zeros(num_stocks, 1);
sterling_ratio = zeros(num_stocks, 1);
burke_ratio = zeros(num_stocks, 1);
jensen_alpha = zeros(num_stocks, 1);
treynor_index = zeros(num_stocks, 1);
treynor_black_ratio = zeros(num_stocks, 1);
stock_names = funds_data.Properties.VariableNames(2:end);

% Tasso privo di rischio giornaliero
risk_free_rate_daily = 0.02 / 252;

for i = 1:num_stocks
    X = [ones(size(benchmark_returns)), benchmark_returns];
    y = funds_returns(:, i);
    b = X \ y;
    beta(i) = b(2);
    mean_returns(i) = mean(funds_returns(:, i));
    std_returns(i) = std(funds_returns(:, i));
    sharpe_ratio(i) = (mean_returns(i) - risk_free_rate_daily) / std_returns(i);
    information_ratio(i) = (mean_returns(i) - mean(benchmark_returns)) / std_returns(i);

    % Calcola l'Average Drawdown
    cumulative_returns = cumprod(1 + funds_returns(:, i)) - 1;
    drawdowns = cumulative_returns - cummax(cumulative_returns);
    average_drawdown(i) = mean(drawdowns(drawdowns < 0));

    % Calcola il Pain Index
    pain_index(i) = mean(abs(drawdowns(drawdowns < 0)));

    % Calcola lo Sterling Ratio
    sterling_ratio(i) = (mean_returns(i) - risk_free_rate_daily) / abs(average_drawdown(i));

    % Calcola il Burke Ratio
    burke_ratio(i) = (mean_returns(i) - risk_free_rate_daily) / sqrt(mean(drawdowns(drawdowns < 0).^2));

    % Calcola il Jensen Alpha
    jensen_alpha(i) = mean_returns(i) - (risk_free_rate_daily + beta(i) * (mean(benchmark_returns) - risk_free_rate_daily));

    % Calcola il Treynor Index
    treynor_index(i) = (mean_returns(i) - risk_free_rate_daily) / beta(i);

    % Calcola il Treynor-Black Ratio
    treynor_black_ratio(i) = jensen_alpha(i) / beta(i);
end

% Visualizza i risultati in una tabella
results_table = table(stock_names', beta, mean_returns, std_returns, sharpe_ratio, information_ratio, ...
    average_drawdown, pain_index, sterling_ratio, burke_ratio, jensen_alpha, treynor_index, treynor_black_ratio, ...
    'VariableNames', {'Stock', 'Beta', 'Mean_Return', 'Std_Dev', 'Sharpe_Ratio', 'Information_Ratio', ...
    'Average_Drawdown', 'Pain_Index', 'Sterling_Ratio', 'Burke_Ratio', 'Jensen_Alpha', 'Treynor_Index', 'Treynor_Black_Ratio'});

disp('Beta, media dei rendimenti, deviazione standard, Sharpe Ratio, Information Ratio, Average Drawdown, Pain Index, Sterling Ratio, Burke Ratio, Jensen Alpha, Treynor Index e Treynor-Black Ratio dei titoli:');
disp(results_table);


% Calcola le medie delle metriche
mean_mean_returns = mean(mean_returns);
mean_std_returns = mean(std_returns);
mean_sharpe_ratio = mean(sharpe_ratio);
mean_information_ratio = mean(information_ratio);
mean_average_drawdown = mean(average_drawdown);
mean_pain_index = mean(pain_index);
mean_sterling_ratio = mean(sterling_ratio);
mean_burke_ratio = mean(burke_ratio);
mean_jensen_alpha = mean(jensen_alpha);
mean_treynor_index = mean(treynor_index);


% Calcola la matrice di correlazione tra i rendimenti dei titoli e il benchmark
correlation_matrix = corr(funds_returns, benchmark_returns);

% Definisci i pesi per ciascuna categoria, inclusa la correlazione
weights = struct('mean_returns', 0.05, ...
                 'std_returns', 0.05, ...
                 'sharpe_ratio', 0.025, ...
                 'information_ratio', 0.2, ...
                 'pain_index', 0.05, ...
                 'sterling_ratio', 0.05, ...
                 'burke_ratio', 0.05, ...
                 'jensen_alpha', 0.75, ...
                 'treynor_index', 0.05, ...
                 'correlation', 0.1);

% Assegna un punteggio a ciascun titolo in base ai criteri ponderati
scores = zeros(num_stocks, 1);
for i = 1:num_stocks
    score = 0;
    if mean_returns(i) > mean_mean_returns
        score = score + 5 * weights.mean_returns; % Assegna 5 punti ponderati se il rendimento medio è superiore alla media
    else
        score = score + 1 * weights.mean_returns; % Assegna 1 punto ponderato se il rendimento medio è inferiore o uguale alla media
    end
    
    if std_returns(i) < mean_std_returns
        score = score + 5 * weights.std_returns; % Assegna 5 punti ponderati se la deviazione standard è inferiore alla media
    else
        score = score + 1 * weights.std_returns; % Assegna 1 punto ponderato se la deviazione standard è superiore o uguale alla media
    end
    
    if sharpe_ratio(i) > mean_sharpe_ratio
        score = score + 5 * weights.sharpe_ratio; % Assegna 5 punti ponderati se lo Sharpe Ratio è superiore alla media
    else
        score = score + 1 * weights.sharpe_ratio; % Assegna 1 punto ponderato se lo Sharpe Ratio è inferiore o uguale alla media
    end
    
    if information_ratio(i) > mean_information_ratio
        score = score + 5 * weights.information_ratio; % Assegna 5 punti ponderati se l'Information Ratio è superiore alla media
    else
        score = score + 1 * weights.information_ratio; % Assegna 1 punto ponderato se l'Information Ratio è inferiore o uguale alla media
    end
    
    if pain_index(i) < mean_pain_index
        score = score + 5 * weights.pain_index; % Assegna 5 punti ponderati se il Pain Index è inferiore alla media
    else
        score = score + 1 * weights.pain_index; % Assegna 1 punto ponderato se il Pain Index è superiore o uguale alla media
    end
    
    if sterling_ratio(i) > mean_sterling_ratio
        score = score + 5 * weights.sterling_ratio; % Assegna 5 punti ponderati se lo Sterling Ratio è superiore alla media
    else
        score = score + 1 * weights.sterling_ratio; % Assegna 1 punto ponderato se lo Sterling Ratio è inferiore o uguale alla media
    end
    
    if burke_ratio(i) > mean_burke_ratio
        score = score + 5 * weights.burke_ratio; % Assegna 5 punti ponderati se il Burke Ratio è superiore alla media
    else
        score = score + 1 * weights.burke_ratio; % Assegna 1 punto ponderato se il Burke Ratio è inferiore o uguale alla media
    end
    
    if jensen_alpha(i) > mean_jensen_alpha
        score = score + 5 * weights.jensen_alpha; % Assegna 5 punti ponderati se il Jensen Alpha è superiore alla media
    else
        score = score + 1 * weights.jensen_alpha; % Assegna 1 punto ponderato se il Jensen Alpha è inferiore o uguale alla media
    end
    
    if treynor_index(i) > mean_treynor_index
        score = score + 5 * weights.treynor_index; % Assegna 5 punti ponderati se il Treynor Index è superiore alla media
    else
        score = score + 1 * weights.treynor_index; % Assegna 1 punto ponderato se il Treynor Index è inferiore o uguale alla media
    end
    
    % Penalizza la correlazione alta
    if correlation_matrix(i) > 0.5 % Soglia arbitraria, puoi modificarla in base alle tue esigenze
        score = score + 1 * weights.correlation; % Assegna 1 punto ponderato se la correlazione è superiore a 0.5
    else
        score = score + 5 * weights.correlation; % Assegna 5 punti ponderati se la correlazione è inferiore o uguale a 0.5
    end
    
    scores(i) = score;
end

% Aggiungi i punteggi alla tabella dei risultati
results_table.Score = scores;

% Ordina i titoli in base ai punteggi e seleziona i migliori 7
sorted_stocks = sortrows(results_table, 'Score', 'descend');
top_7_stocks = sorted_stocks(1:min(7, height(sorted_stocks)), :);

disp('I migliori 7 titoli selezionati sono:');
disp(top_7_stocks);

% Calcola i rendimenti annualizzati e le deviazioni standard annualizzate
annualized_mean_returns = mean_returns * 252;
annualized_std_returns = std_returns * sqrt(252);
annualized_sharpe_ratio = sharpe_ratio * sqrt(252);
annualized_information_ratio = information_ratio * sqrt(252);
annualized_jensen_alpha = jensen_alpha * 252;
annualized_treynor_index = treynor_index * 252;
annualized_treynor_black_ratio = treynor_black_ratio * 252;

% Visualizza i risultati annualizzati in una tabella
annualized_results_table = table(stock_names', beta, annualized_mean_returns, annualized_std_returns, annualized_sharpe_ratio, annualized_information_ratio, ...
    pain_index, sterling_ratio, burke_ratio, annualized_jensen_alpha, annualized_treynor_index, annualized_treynor_black_ratio, scores, ...
    'VariableNames', {'Stock', 'Beta', 'Annualized_Mean_Return', 'Annualized_Std_Dev', 'Annualized_Sharpe_Ratio', 'Annualized_Information_Ratio', ...
    'Pain_Index', 'Sterling_Ratio', 'Burke_Ratio', 'Annualized_Jensen_Alpha', 'Annualized_Treynor_Index', 'Annualized_Treynor_Black_Ratio', 'Score'});

disp('Beta, rendimenti annualizzati, deviazione standard annualizzata, Sharpe Ratio annualizzato, Information Ratio annualizzato, Pain Index, Sterling Ratio, Burke Ratio, Jensen Alpha annualizzato, Treynor Index annualizzato e Treynor-Black Ratio annualizzato dei titoli:');
disp(annualized_results_table);

% Ordina i titoli in base ai punteggi e seleziona i migliori 7
sorted_annualized_stocks = sortrows(annualized_results_table, 'Score', 'descend');
top_7_annualized_stocks = sorted_annualized_stocks(1:min(7, height(sorted_annualized_stocks)), :);

disp('I migliori 7 titoli annualizzati selezionati sono:');
disp(top_7_annualized_stocks);
