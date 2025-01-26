% Carica i dati dal file Excel
filename = 'C:\Users\Tomma\MATLAB Drive\EFM EXAM 2025\PortfolioCombinations_24.xlsx';
opts = detectImportOptions(filename, 'Sheet', 'nyse statisticsD');
opts.VariableNamingRule = 'preserve';
nasdaqStatistics = readtable(filename, opts);

% Definisci i pesi personalizzati per ciascun tipo di portafoglio
pesi = struct(...
    'MinRisk', 0.05, ...          % Peso per MinRisk
    'MaxRet_MinRisk', 0.3, ...  % Peso per MaxRet MinRisk
    'HRP', 0.1, ...             % Peso per HRP
    'BL', 0.15, ...              % Peso per BL
    'GMVP', 0.05, ...            % Peso per GMVP
    'Sharpe', 0.35 ...           % Peso per Sharpe
);

% Mappatura dei nomi dei portafogli ai nomi validi per i campi della struttura
% Nota: I nomi nella mappatura devono corrispondere esattamente ai nomi nel file Excel.
mappaturaNomi = containers.Map(...
    {'MinRisk', 'MaxRet_MinRisk', 'HRP', 'BL', 'GMVP', 'Sharpe'}, ...
    {'MinRisk', 'MaxRet_MinRisk', 'HRP', 'BL', 'GMVP', 'Sharpe'} ...
);

% Estrai i nomi dei portafogli e le statistiche
nomiPortafogli = nasdaqStatistics{:, 1};  % Prima colonna: nomi dei portafogli
statistiche = nasdaqStatistics{:, 2:end}; % Restanti colonne: statistiche

% Stampa i nomi dei portafogli per verificare la corrispondenza
disp('Nomi dei portafogli:');
disp(nomiPortafogli);

% Inizializza il vettore delle statistiche combinate
statisticheCombinazione = zeros(1, size(statistiche, 2));

% Calcola la combinazione lineare
for i = 1:length(nomiPortafogli)
    nomePortafoglio = nomiPortafogli{i};
    
    % Verifica se il nome del portafoglio è presente nella mappatura
    if isKey(mappaturaNomi, nomePortafoglio)
        nomeValido = mappaturaNomi(nomePortafoglio);  % Ottieni il nome valido per il campo
        peso = pesi.(nomeValido);  % Ottieni il peso corrispondente
        statisticheCombinazione = statisticheCombinazione + peso * statistiche(i, :);
    else
        warning('Portafoglio "%s" non trovato nella mappatura. Verifica il nome.', nomePortafoglio);
    end
end

% Aggiungi il portafoglio combinato alla lista dei portafogli
nomiPortafogli{end+1} = 'Combinazione';
statistiche = [statistiche; statisticheCombinazione];

% Estrai media e deviazione standard (Mean e Stdev) per il plot
media = statistiche(:, 1);  % Prima colonna: Mean
deviazioneStandard = statistiche(:, 2);  % Seconda colonna: Stdev

% Plot del piano media-varianza
figure;
hold on;
grid on;

% Plot dei portafogli
scatter(deviazioneStandard(1:end-1), media(1:end-1), 100, 'filled', 'b'); % Portafogli esistenti
text(deviazioneStandard(1:end-1), media(1:end-1), nomiPortafogli(1:end-1), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right'); % Etichette

% Evidenzia il portafoglio combinato
scatter(deviazioneStandard(end), media(end), 150, 'r', 'filled'); % Portafoglio combinato in rosso
text(deviazioneStandard(end), media(end), nomiPortafogli(end), ...
    'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right', 'Color', 'red'); % Etichetta

% Aggiungi titoli e legenda
xlabel('Deviazione Standard (Rischio)');
ylabel('Media (Rendimento Atteso)');
title('Piano Media-Varianza');
legend('Portafogli', 'Portafoglio Combinato', 'Location', 'best');

hold off;

% Stampa le statistiche del portafoglio di combinazione
disp('Statistiche del portafoglio di combinazione:');
disp(array2table(statisticheCombinazione, ...
    'VariableNames', nasdaqStatistics.Properties.VariableNames(2:end), ...
    'RowNames', {'Combinazione'}));